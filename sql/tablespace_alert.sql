
SET FEEDBACK OFF
SET PAGESIZE 70
SET LINESIZE 2000
SET HEAD ON
COLUMN Tablespace FORMAT a25 HEADING 'Tablespace Name'
COLUMN autoextensible FORMAT a11 HEADING 'AutoExtend'
COLUMN files_in_tablespace FORMAT 999 HEADING 'Files'
COLUMN total_tablespace_space FORMAT 99999999 HEADING 'TotalSpace'
COLUMN total_used_space FORMAT 99999999 HEADING 'UsedSpace'
COLUMN total_tablespace_free_space FORMAT 99999999 HEADING 'FreeSpace'
COLUMN total_used_pct FORMAT 9999 HEADING '%Used'
COLUMN total_free_pct FORMAT 9999 HEADING '%Free'
COLUMN max_size_of_tablespace FORMAT 9999999999 HEADING 'ExtendUpto(MB)'
COLUMN total_auto_used_pct FORMAT 99999 HEADING 'Max%Used'
COLUMN total_auto_free_pct FORMAT 99999 HEADING 'Max%Free'
COLUMN totalbytesfromextendupto FORMAT 99999 HEADING 'Used%FromMax'

WITH
    tbs_auto
    AS
        (SELECT DISTINCT tablespace_name, autoextensible
           FROM dba_data_files
          WHERE autoextensible = 'YES'),
    files
    AS
        (  SELECT tablespace_name,
                  COUNT (*)                     tbs_files,
                  SUM (BYTES / 1024 / 1024)     total_tbs_bytes
             FROM dba_data_files
         GROUP BY tablespace_name),
    fragments
    AS
        (  SELECT tablespace_name,
                  COUNT (*)                     tbs_fragments,
                  SUM (BYTES) / 1024 / 1024     total_tbs_free_bytes,
                  MAX (BYTES) / 1024 / 1024     max_free_chunk_bytes
             FROM dba_free_space
         GROUP BY tablespace_name),
    AUTOEXTEND
    AS
        (  SELECT tablespace_name, SUM (size_to_grow) total_growth_tbs
             FROM (  SELECT tablespace_name,
                            SUM (maxbytes) / 1024 / 1024     size_to_grow
                       FROM dba_data_files
                      WHERE autoextensible = 'YES'
                   GROUP BY tablespace_name
                   UNION
                     SELECT tablespace_name,
                            SUM (BYTES) / 1024 / 1024     size_to_grow
                       FROM dba_data_files
                      WHERE autoextensible = 'NO'
                   GROUP BY tablespace_name)
         GROUP BY tablespace_name)
  SELECT c.instance_name,
         a.tablespace_name
             Tablespace,
         CASE tbs_auto.autoextensible WHEN 'YES' THEN 'YES' ELSE 'NO' END
             AS autoextensible,
         files.tbs_files
             files_in_tablespace,
         files.total_tbs_bytes
             total_tablespace_space,
         (files.total_tbs_bytes - fragments.total_tbs_free_bytes)
             total_used_space,
         fragments.total_tbs_free_bytes
             total_tablespace_free_space,
         ROUND (
             (  (  (files.total_tbs_bytes - fragments.total_tbs_free_bytes)
                 / files.total_tbs_bytes)
              * 100))
             total_used_pct,
         ROUND (
             ((fragments.total_tbs_free_bytes / files.total_tbs_bytes) * 100))
             total_free_pct,
         ROUND (
             (  (  (files.total_tbs_bytes - fragments.total_tbs_free_bytes)
                 / autoextend.total_growth_tbs)
              * 100),
             2)
             AS totalbytesfromextendupto,
         autoextend.total_growth_tbs
             AS max_size_of_tablespace
    FROM dba_tablespaces a,
         v$instance     c,
         files,
         fragments,
         AUTOEXTEND,
         tbs_auto
   WHERE     a.tablespace_name = files.tablespace_name
         AND a.tablespace_name = fragments.tablespace_name
         AND a.tablespace_name = AUTOEXTEND.tablespace_name
         AND a.tablespace_name = tbs_auto.tablespace_name(+)
         --Check 'total_used_space' against 'max_size_of_tablespace' (total tbs size (32gb for small tbs))
         AND   ((  (files.total_tbs_bytes - fragments.total_tbs_free_bytes)
                 / autoextend.total_growth_tbs))
             * 100 >
             85
         --Check against %Free
         AND (fragments.total_tbs_free_bytes / files.total_tbs_bytes) * 100 <
             15
ORDER BY total_free_pct;
