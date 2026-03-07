#!/bin/bash

####################
#		   #	
# author:Elvis Ndoj#
# 2026-03-07	   #
# v.1.0		   #	
# Oracle DB	   #	
####################
#
# This script is created to provide a quick overview of Oracle Instances (single instances) installed in the system.
#

SID=( $(cat /etc/oratab | grep -E "\b:" | grep -v "^#" | cut -d: -f1) )
OH=( $(cat /etc/oratab | grep -E "\b:" | grep -v "^#" | cut -d: -f2) )

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
#echo "-----------------------------------------------------------"
#echo -e "--- DB Instance: $ORACLE_SID"
#echo -e "--- DB Status: $instancestatus"
#echo -e "--- DB Home: $ORACLE_HOME"
#echo "-----------------------------------------------------------"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo -e " DB Instance: $ORACLE_SID"
echo -e " DB Status: $instancestatus"
echo -e " DB Home: $ORACLE_HOME"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

alias $i="set_ora_env $i";
unset ORACLE_SID;
unset ORACLE_HOME;
done;
