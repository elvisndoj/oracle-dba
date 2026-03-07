#!/bin/bash

###########################
# author:Elvis Ndoj
# 2026-03-07
# v.1.0
##########################

sql_scripts_path="../sql"


tablespace_usage(){
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "Tablespace Usage of Instance: $ORACLE_SID"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	set echo off;
	sqlplus -s "/ as sysdba" <<EOF
	@$sql_scripts_path/tablespace_usage.sql
	
EOF
}
tablespace_usage
