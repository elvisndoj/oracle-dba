SELECT a.tablespace_name,
       SIZE_MB,
       USAGE_MB,
       (SIZE_MB - USAGE_MB)     FREE_MB,
       d.SIZE_TO_GROW_MB
  FROM (  SELECT SUM (bytes) / 1024 / 1024 SIZE_MB, b.tablespace_name
            FROM dba_data_files a, dba_tablespaces b
           WHERE a.tablespace_name = b.tablespace_name AND b.contents = 'UNDO'
        GROUP BY b.tablespace_name) a,
       (  SELECT c.tablespace_name, SUM (bytes) / 1024 / 1024 USAGE_MB
            FROM DBA_UNDO_EXTENTS c
           WHERE status <> 'EXPIRED'
        GROUP BY c.tablespace_name) b,
       (  SELECT ROUND (SUM (maxbytes) / 1024 / 1024)     size_to_grow_mb,
                 b.tablespace_name
            FROM dba_data_files a, dba_tablespaces b
           WHERE a.tablespace_name = b.tablespace_name AND b.contents = 'UNDO'
        GROUP BY b.tablespace_name) d
 WHERE     a.tablespace_name = b.tablespace_name
       AND a.tablespace_name = d.TABLESPACE_NAME
/
