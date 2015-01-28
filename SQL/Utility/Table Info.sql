-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Lists Space, Number of Rows, Creation Date of each Table of Owner
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SELECT
    table_name,
    sum(bytes)/(1024*1024) AS table_size_mb,
    sum(NUM_ROWS) as number_rows,
    max(created) as created
FROM
    user_extents
    JOIN
    all_tables
    ON segment_name = table_name
    join
    all_objects
    on table_name = object_name
WHERE
    segment_type = 'TABLE'
    AND
    all_tables.owner = user
GROUP BY
    table_name
order by
    sum(bytes) desc
    ;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Lists Used / Max amount in MB
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SELECT
    tablespace_name,
    bytes / 1024 / 1024 as used_in_mb,
    max_bytes / 1024 / 1024 as max_in_mb
FROM
    USER_TS_QUOTAS;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Function for getting Table Size
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CREATE OR REPLACE FUNCTION get_table_size
    (t_table_name VARCHAR2)RETURN NUMBER IS
    l_size NUMBER;
    BEGIN
SELECT sum(bytes)/(1024*1024)
INTO l_size
FROM user_extents
WHERE segment_type='TABLE'
    AND segment_name = t_table_name;
    RETURN l_size;
    EXCEPTION
    WHEN OTHERS THEN
    RETURN NULL;
    END;


