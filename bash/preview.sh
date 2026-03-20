#!/bin/bash

####################
#	
# author:Elvis Ndoj
#
# v.1.1 (2026-03-09)
# v.1.0 (2026-03-07)		
####################
#
# This script is created to provide a quick overview of Oracle Instances (single instances) installed in the system.
#

SID=( $(cat /etc/oratab | grep -E "\b:" | grep -v "^#" | cut -d: -f1) )
OH=( $(cat /etc/oratab | grep -E "\b:" | grep -v "^#" | cut -d: -f2) )


sql_scripts_path="/home/oracle/oracle-dba/sql"
shell_scripts_path="/home/oracle/oracle-dba/bash"

for i in ${SID[@]}
do

set_ora_env(){
unset ORACLE_SID;
unset ORACLE_HOME;
export ORACLE_SID=$1
export ORACLE_HOME=$(cat /etc/oratab | grep "$ORACLE_SID" | grep -E "\b:" | grep -v "^#" | cut -d: -f2)
export PATH="$ORACLE_HOME/bin:$PATH"
export LD_LIBRARY_PATH=/usr/lib:/usr/lib64:/usr/local/lib:/usr/local/lib64:$ORACLE_HOME/lib
}

set_ora_env $i
 
status(){
sqlplus -s "/ as sysdba" <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET echo OFF;
SET HEADING OFF;
select status from v\$instance;
exit
EOF
}

instancestatus="$(status | tr -d '\n')"
rc=$?

if [ $rc -ne 0 ] || [[ "$instancestatus" == *ERROR* || -z "$instancestatus" ]]; then
instancestatus="down"
else
	if [[ "$instancestatus" == "OPEN" ]];
	then instancestatus="up"
	elif [[ "$instancestatus" == "STARTED" ]]
	then instancestatus="started (nomount)"
	elif [[ "$instancestatus" == "MOUNTED" ]]
        then instancestatus="mounted"
	else $instancestatus
	fi
fi

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo -e " DB Instance:\t $ORACLE_SID"
echo -e " DB Status:\t $instancestatus"
echo -e " DB Home:\t $ORACLE_HOME"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
alias $i="set_ora_env $i";
unset ORACLE_SID;
unset ORACLE_HOME;
done;

#v1.1.1

listeners=( $(ps -ef | grep -i "tnslsnr" | grep -v "grep" | awk -F " " '{ print $9":"$8}') )

if [ ! $(echo ${#listeners[@]}) -eq 0 ];
then
 for listener in ${listeners[@]}
 do
 listener_alias=$(echo $listener | cut -d: -f1)
 listener_status="up"
 listener_det=$(echo $listener | cut -d: -f2)
 echo -e " listener ($listener_alias):\t\t $listener_status\t $listener_det"
 done;
 echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
else
 listener_alias=""
 listener_status="down"
 listener_det=""
 echo -e " listener ($listener_alias):\t $listener_status\t $listener_det"
 echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi;
