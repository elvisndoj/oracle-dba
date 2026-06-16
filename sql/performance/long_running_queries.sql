SELECT sid,
       inst_id,
       opname,
       totalwork,
       sofar,
       start_time,
       time_remaining
  FROM gv$session_longops
 WHERE totalwork <> sofar
/

