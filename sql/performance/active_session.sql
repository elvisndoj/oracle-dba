SET ECHO OFF
SET LINESIZE 95
SET HEAD ON
SET FEEDBACK ON
COL sid HEAD "Sid" FORM 9999 TRUNC
COL serial# FORM 99999 TRUNC HEAD "Ser#"
COL username FORM a8 TRUNC
COL osuser FORM a7 TRUNC
COL machine FORM a20 TRUNC HEAD "Client|Machine"
COL program FORM a15 TRUNC HEAD "Client|Program"
COL login FORM a11
COL "last call" FORM 9999999 TRUNC HEAD "Last Call|In Secs"
COL status FORM a6 TRUNC

  SELECT sid,
         serial#,
         SUBSTR (username, 1, 10)                  username,
         SUBSTR (osuser, 1, 10)                    osuser,
         SUBSTR (program || module, 1, 15)         program,
         SUBSTR (machine, 1, 22)                   machine,
         TO_CHAR (logon_time, 'ddMon hh24:mi')     login,
         last_call_et                              "last call",
         status
    FROM gv$session
   WHERE status = 'ACTIVE'
ORDER BY 1;
