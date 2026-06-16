
SET LINES 2000
SET PAGES 1000
COL sid FOR 99999
COL name FOR a09
COL username FOR a14
COL PROGRAM FOR a21
COL MODULE FOR a25

  SELECT s.sid,
         sn.SERIAL#,
         n.name,
         ROUND (VALUE / 1024 / 1024, 2)     redo_mb,
         sn.username,
         sn.status,
         SUBSTR (sn.program, 1, 21)         "program",
         sn.TYPE,
         sn.module,
         sn.sql_id
    FROM v$sesstat s
         JOIN v$statname n ON n.statistic# = s.statistic#
         JOIN v$session sn ON sn.sid = s.sid
   WHERE n.name LIKE 'redo size' AND s.VALUE != 0
ORDER BY redo_mb DESC;
