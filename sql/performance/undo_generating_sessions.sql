SELECT a.sid,
       a.serial#,
       a.username,
       b.used_urec     used_undo_record,
       b.used_ublk     used_undo_blocks
  FROM v$session a, v$transaction b
 WHERE a.saddr = b.ses_addr;
