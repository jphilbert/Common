-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- TABLE INSPECTION.SQL
--   PL/SQL script for summarizing tables.
-- .
-- AUTHOR:	John P. Hilbert
-- CREATED:	2013-01-30
-- MODIFIED:	2013-02-07
-- .  
-- SUMMARY - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--   This semi-automated script to pull some summary statistics for a table.
--   It does the following:
--	- Lists all column names, data types, character lengths, and null-able
--	  flag from a table
--	- Either counts distinct values (for boolean or character types) or
--	  lists the range for each column
--	- Counts the frequency of distinct values (for small number of distinct
--	  values [default 200])
-- .
--   This information is saved as two CSV files in a user defined path.
-- .
--   The variables required to be set are:
--	- THIS_PATH	- Path to save output
--	- THIS_TABLE	- table to query
--   Optional variables
--	- COUNT_BY	- column to count distinct values [* by default]
--	- MAX_VALUE	- max number of discrete value within column to count
--			  [200 by default]
-- .
-- REVISIONS - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--   - Automated script
-- .
-- REQUIRE - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--   - None
-- .
-- OUTPUT - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--   Be sure to set the THIS_PATH variable
--   - summary - info.csv		  
--   - summary - value count.csv
-- .
-- TO DO - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--   - 
-- .
-- EXAMPLES  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--   - None
-- .
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    prompt ++++++++++ Starting TABLE INSPECTION.SQL ++++++++++;

    def this_path = 'C:\'

    def this_table = 'SERVICE_LOCATION'

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Describe Table
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
create table this_table_info as
select
    table_name,
    column_name,                    
    cast(data_type as varchar2(15)) as data_type,
    char_length,
    nullable
from
    all_tab_columns
where
    table_name = '&this_table'
order by
    column_id;
		

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Summary of Columns - Distinct Count or Range
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
create table summary_count(
        column_name VARCHAR2(30),
        min VARCHAR2(30),
        max VARCHAR2(30));
    DECLARE
    TYPE t_tableList IS TABLE OF this_table_info%ROWTYPE;
    vTable t_tableList;
    BEGIN
-- .
-- Set the table info for collection
SELECT * BULK COLLECT INTO vTable FROM this_table_info;
-- .
    FOR i IN vTable.FIRST .. vTable.LAST LOOP
    BEGIN
    if vTable(i).data_type like '%CHAR%' or vTable(i).data_type = 'BOOLEAN'
    then
    EXECUTE IMMEDIATE    
    'insert into SUMMARY_COUNT select '''|| vTable(i).column_name ||
    ''', ''<COUNT>'', count(distinct ' || vTable(i).column_name ||
    ') from ' || vTable(1).table_name;
    else
    EXECUTE IMMEDIATE
    'insert into SUMMARY_COUNT select ''' || vTable(i).column_name ||
    ''', min('|| vTable(i).column_name ||'), max('||
    vTable(i).column_name ||') from ' || vTable(1).table_name;
    end if;
    end;
    END LOOP;
    END;
    /


create table table_info as
select * from this_table_info natural join summary_count;
drop table summary_count;
drop table this_table_info;



-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Discrete Columns - List Values
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
create table summary_value_count(
        column_name VARCHAR2(30),
        value VARCHAR2(60),
        cnt numeric(10));
    DECLARE
    TYPE t_tableList IS TABLE OF table_info%ROWTYPE;
    vTable t_tableList;
-- If you want to count by a specific column you can change it here
    count_by constant varchar2(100) := '*';
-- Max discrete values to filter counting of a column 
    max_values constant numeric := 200;
    BEGIN
-- .
-- Set the table info for collection
SELECT * BULK COLLECT INTO vTable FROM table_info
WHERE data_type like '%CHAR%' or data_type = 'BOOLEAN';
-- .
    FOR i IN vTable.FIRST .. vTable.LAST LOOP
    if vTable(i).max < max_values
    then
    EXECUTE IMMEDIATE    
    'insert into summary_value_count SELECT distinct '''||
    vTable(i).column_name || ''', ' || vTable(i).column_name ||
    ', count(' || count_by || ') FROM ' || vTable(1).table_name ||
    ' GROUP BY ' || vTable(i).column_name;
    end if;
    END LOOP;
    END;
    /



-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Output
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    host sqluldr table_info "&this_path\summary - info.csv"
drop table table_info;
    host sqluldr summary_value_count "&this_path\summary - value count.csv"
drop table summary_value_count;