set linesize 300
COL session_id HEAD 'Sid' FORM 9999
COL object_name HEAD "Table|Locked" FORM a10
COL oracle_username HEAD "Oracle|Username" FORM a10 TRUNCATE
COL os_user_name HEAD "OS|Username" FORM a10 TRUNCATE
COL process HEAD "Client|Process|ID" FORM 99999999
COL mode_held FORM a15

  SELECT lo.session_id,
         s.SERIAL#,
         lo.oracle_username,
         lo.os_user_name,
         lo.process,
         do.object_name,
         DECODE (lo.locked_mode,
                 0, 'None',
                 1, 'Null',
                 2, 'Row Share (SS)',
                 3, 'Row Excl (SX)',
                 4, 'Share',
                 5, 'Share Row Excl (SSX)',
                 6, 'Exclusive',
                 TO_CHAR (lo.locked_mode))    mode_held
    FROM v$locked_object lo, dba_objects do, v$session s
   WHERE lo.object_id = do.object_id AND lo.session_id = s.sid
ORDER BY 1, 5
/
