
WITH
    tmpusage
    AS
        (  SELECT a.tablespace_name
                      tablespace,
                  d.TEMP_TOTAL_MB,
                  SUM (a.used_blocks * d.block_size) / 1024 / 1024
                      TEMP_USED_MB,
                    d.TEMP_TOTAL_MB
                  - SUM (a.used_blocks * d.block_size) / 1024 / 1024
                      TEMP_FREE_MB
             FROM v$sort_segment a,
                  (  SELECT b.name,
                            c.block_size,
                            SUM (c.bytes) / 1024 / 1024     TEMP_TOTAL_MB
                       FROM v$tablespace b, v$tempfile c
                      WHERE b.ts# = c.ts#
                   GROUP BY b.name, c.block_size) d
            WHERE a.tablespace_name = d.name
         GROUP BY a.tablespace_name, d.TEMP_TOTAL_MB),
    tmpgrowth
    AS
        (  SELECT tablespace_name, SUM (size_to_grow) total_growth_tbs
             FROM (  SELECT tablespace_name,
                            ROUND (SUM (maxbytes) / 1024 / 1024)     size_to_grow
                       FROM DBA_TEMP_FILES
                      WHERE autoextensible = 'YES'
                   GROUP BY tablespace_name
                   UNION
                     SELECT tablespace_name,
                            ROUND (SUM (BYTES) / 1024 / 1024)     size_to_grow
                       FROM DBA_TEMP_FILES
                      WHERE autoextensible = 'NO'
                   GROUP BY tablespace_name)
            WHERE tablespace_name LIKE 'TEMP%'
         GROUP BY tablespace_name)
SELECT tu.*, tg.total_growth_tbs AS total_growth_tbs_MB
  FROM tmpusage  tu
       INNER JOIN tmpgrowth tg ON tu.tablespace = tg.tablespace_name;
