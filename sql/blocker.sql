SET FEED OFF
SET PAGESIZE 200
SET LINES 299
COL event FOR a31

SELECT s.inst_id,
       s.blocking_session,
       s.sid,
       s.serial#,
       s.seconds_in_wait,
       s.event
  FROM gv$session s
 WHERE blocking_session IS NOT NULL AND s.seconds_in_wait > 10;
