#!/bin/bash

ORATAB=/etc/oratab
ORIG_PATH=$PATH

sql_scripts_path="/home/oracle/oracle-dba/sql"
shell_scripts_path="/home/oracle/oracle-dba/bash"

# =========================================================
# INVENTORY (FROM ORACLE INVENTORY XML)
# =========================================================
get_oracle_homes() {
  local inv_loc=$(awk -F= '/inventory_loc/ {print $2}' /etc/oraInst.loc)
  local xml="$inv_loc/ContentsXML/inventory.xml"

  awk -F'"' '
    /HOME NAME/ {
      for (i=1; i<=NF; i++) {
        if ($i ~ /NAME=/) name=$(i+1)
        if ($i ~ /LOC=/)  loc=$(i+1)
      }
      if (name && loc)
        print name "|" loc
    }
  ' "$xml" | sort -r
}

# =========================================================
# STATUS CHECK (FIXED LOGIC)
# =========================================================
get_db_status() {
  local sid=$1
  local home=$2

  # ---------------- ASM / GRID ----------------
  if [[ "$sid" == +ASM* ]]; then
    if ps -ef | grep -q "[a]sm_pmon_"; then
      echo "UP"
    else
      echo "DOWN"
    fi
    return
  fi

  # ---------------- HARD RULE ----------------
  # no pmon => DOWN
  if ! ps -ef | grep -q "[p]mon_${sid}"; then
    echo "DOWN"
    return
  fi

  # ---------------- SQL CHECK ----------------
  export ORACLE_SID="$sid"
  export ORACLE_HOME="$home"
  export PATH=$ORACLE_HOME/bin:$ORIG_PATH

  inst=$(sqlplus -s / as sysdba <<EOF
set heading off feedback off pages 0 verify off echo off termout off
select status from v\$instance;
exit
EOF
)

  inst=$(echo "$inst" | tr -d '[:space:]')

  case "$inst" in
    OPEN)    echo "UP" ;;
    MOUNTED) echo "MOUNTED" ;;
    STARTED) echo "STARTED (NOMOUNT)" ;;
    *)       echo "UNKNOWN" ;;
  esac
}

# =========================================================
# DB DETAILS (ONLY IF OPEN)
# =========================================================
show_db_details() {

inst=$(sqlplus -s / as sysdba <<EOF
set heading off feedback off pages 0 verify off echo off termout off
select status from v\$instance;
exit
EOF
)

inst=$(echo "$inst" | tr -d '[:space:]')

[[ "$inst" != "OPEN" ]] && return

sqlplus -s / as sysdba <<EOF
set pages 0 feedback off heading off verify off echo off lines 200

select '-------------------------------------------' from dual;

select 'db_unique_name          = '||db_unique_name from v\$database;
select 'database_role           = '||database_role from v\$database;
select 'log_mode                = '||log_mode from v\$database;
select 'open_mode               = '||open_mode from v\$database;
select 'flashback_on            = '||flashback_on from v\$database;
select 'switchover_status       = '||switchover_status from v\$database;
select 'dataguard_broker        = '||value from v\$parameter where name='dg_broker_start';
select 'force_logging           = '||force_logging from v\$database;

select '-------------------------------------------' from dual;

exit
EOF
}

# =========================================================
# ASM DETAILS
# =========================================================
show_asm_details() {

sqlplus -s / as sysasm <<EOF
set lines 200 pages 100 feedback off

select name,
       state,
       total_mb,
       free_mb,
       round((free_mb/total_mb)*100,2) pct_free
from v\$asm_diskgroup;

exit
EOF
}

# =========================================================
# SET ENVIRONMENT / COMMAND ENTRY
# =========================================================
setora() {

input="$1"

# ---------------- SID MODE ----------------
entry=$(grep -v '^#' $ORATAB | grep "^${input}:")

if [[ -n "$entry" ]]; then
  export ORACLE_SID=$(echo $entry | cut -d: -f1)
  export ORACLE_HOME=$(echo $entry | cut -d: -f2)
  export PATH=$ORACLE_HOME/bin:$ORIG_PATH

  echo "✔ SID: $ORACLE_SID"
  echo "✔ HOME: $ORACLE_HOME"

  status=$(get_db_status "$ORACLE_SID" "$ORACLE_HOME")
  echo "STATUS: $status"

  if [[ "$ORACLE_SID" == +ASM* ]]; then
    show_asm_details
  else
    show_db_details
  fi

  return
fi

# ---------------- HOME MODE ----------------
while IFS="|" read -r name home
do
  if [[ "$input" == "$name" ]]; then

    unset ORACLE_SID
    unset TWO_TASK

    export ORACLE_HOME="$home"
    export PATH=$ORACLE_HOME/bin:$ORIG_PATH

    echo "✔ HOME: $ORACLE_HOME"
    echo "✔ SID unset"

    return
  fi
done < <(get_oracle_homes)

echo "❌ Unknown: $input"
}

# =========================================================
# FUNCTION ALIASES
# =========================================================
create_functions() {

while IFS="|" read -r name home
do
  [[ -z "$name" ]] && continue
  eval "$name() { setora \"$name\"; }"
done < <(get_oracle_homes)

while IFS=: read -r sid home rest
do
  [[ -z "$sid" || "$sid" == \#* ]] && continue
  eval "$sid() { setora $sid; }"
done < $ORATAB
}

# =========================================================
# OVERVIEW TABLE
# =========================================================
oracle_overview() {

printf "\n"
printf "%-25s %-20s %-20s %s\n" "COMPONENT" "SID" "STATUS" "ORACLE_HOME"
printf "%-25s %-20s %-20s %s\n" "-------------------------" "---------------" "------------" "------------------------------"

while IFS="|" read -r comp home
do
  [[ -z "$comp" || -z "$home" ]] && continue

  type="rdbms"
  [[ "$home" == *grid* ]] && type="grid"

  if [[ "$type" == "grid" ]]; then
    status=$(get_db_status "+ASM" "$home")
    printf "%-25s %-20s %-20s %s\n" "$comp (grid)" "+ASM" "$status" "$home"
    continue
  fi

  sids=$(awk -F: -v h="$home" '$2==h {print $1}' $ORATAB)

  if [[ -z "$sids" ]]; then
    printf "%-25s %-20s %-20s %s\n" "$comp (rdbms)" "-" "-" "$home"
  else
    for sid in $sids
    do
      status=$(get_db_status "$sid" "$home")
      printf "%-25s %-20s %-20s %s\n" "$comp (rdbms)" "$sid" "$status" "$home"
    done
  fi

done < <(get_oracle_homes)

# ---------------- LISTENER ----------------
if [[ -z $(ps -ef | grep '[t]nslsnr') ]]
then
  printf "%-25s %-20s %-20s %s\n" "listener (LISTENER)" "-" "DOWN" "-"
else
ps -ef | grep '[t]nslsnr' | while read -r line
do
  #home=$(echo "$line" | awk '{print $8}' | sed 's#/bin/tnslsnr##')
  home=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i ~ /tnslsnr/) print $i}')
  home=${home%/bin/tnslsnr}
  printf "%-25s %-20s %-20s %s\n" "listener (LISTENER)" "-" "UP" "$home"
done
fi

# ---------------- OHAS ----------------

if pgrep -f ohasd.bin >/dev/null; then

  home=$(ps -ef | awk '
    /ohasd.bin/ && !/awk/ {
      for(i=1;i<=NF;i++) {
        if($i ~ /ohasd.bin/) {
          print $i
          exit
        }
      }
    }')

  home=${home%/bin/ohasd.bin}

  printf "%-25s %-20s %-20s %s\n" "ohasd.bin" "-" "UP" "$home"
  echo ""
fi
}
# =========================================================
# AUTO LOAD WHEN SOURCED
# =========================================================
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  create_functions
  oracle_overview
fi
