-- this is only shown to work in SQLPlus 
--		(NOT NOT NOT TOAD)
-- I implement this with two .sql script files

-- FILE_1.sql - this file does the work and yours
--		will likely be much longer
-- note: &1 and &2 are the first and second input 
--		variables, respectively
GRANT SELECT ON &1 TO &2;

-- FILE_2.sql - this file just repeats file 1 for
-- 		different table_name/schema combos
-- 		not: the 'at' symbol runs a file 
@"C:\Path_to_File\FILE_1.sql" TABLE1_NAME ZERNIGUEHC
@"C:\Path_to_File\FILE_1.sql" TABLE2_NAME ZERNIGUEHC

-- once connected in SQLPlus:
-- from command prompt, SQL> , run:
@FILE_2.sql 

-- This is a trivial example, but gets the point across
-- SQLPlus will substitute variables BEFORE sending
-- 		code to Oracle server, this allows Oracle
--		calls to be 'hard coded', instead of having
--		the Oracle server keeping track of the variables