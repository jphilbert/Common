-- in short, you execute:
--	EXPLAIN PLAN FOR <query>;
-- then
--      select * from table(dbms_xplan.display);

-- Example
    explain plan for (
    select
	count(*),
	count(distinct provider_id)
    from
	provider
	);
select * from table(dbms_xplan.display);

select
    count(*),
    count(distinct provider_id)
from
    provider;


-- This will break out pertinent information for complex queries into COST -
-- SIZE - TIME
select plan_table_output
from table(dbms_xplan.display('plan_table',null,'basic +cost'))
union all
select plan_table_output
from table(dbms_xplan.display('plan_table',null,'basic +bytes +rows'))
union all
select plan_table_output from
    table(dbms_xplan.display('plan_table',null,'typical -cost -bytes -rows -partition -parallel +PREDICATE +note'));

-- If you wish to do a custom format of the plan you can use:
--	BASIC: Displays the minimum information in the plan—the operation ID,
--	the operation name and its option.

--	TYPICAL: This is the default. Displays the most relevant information in
--	the plan (operation id, name and option, #rows, #bytes and optimizer
--	cost). Pruning, parallel and predicate information are only displayed
--	when applicable. Excludes only PROJECTION, ALIAS and REMOTE SQL
--	information(see below).

--	SERIAL: Like TYPICAL except that the parallel information is not
--	displayed, even if the plan executes in parallel.

--	ALL: Maximum user level. Includes information displayed with the
--	TYPICAL level with additional information (PROJECTION, ALIAS and
--	information about REMOTE SQL if the operation is distributed). 

-- With the additional flags (+/-)
-- ROWS - if relevant, shows the number of rows estimated by the optimizer
-- BYTES - if relevant, shows the number of bytes estimated by the optimizer
-- COST - if relevant, shows optimizer cost information
-- PARTITION - if relevant, shows partition pruning information
-- PARALLEL - if relevant, shows PX information (distribution method and table
--	queue information) 
-- PREDICATE - if relevant, shows the predicate section
-- PROJECTION -if relevant, shows the projection section
-- ALIAS - if relevant, shows the "Query Block Name / Object Alias" section
-- REMOTE - if relevant, shows the information for distributed query (for
--	example, remote from serial distribution and remote SQL) 
-- NOTE - if relevant, shows the note section of the explain plan