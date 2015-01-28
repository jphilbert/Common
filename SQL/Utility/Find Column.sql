-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Finds a Column in Any Table
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select
    table_name,
    column_name
from
    all_tab_columns
where
    column_name like upper('%physician%');