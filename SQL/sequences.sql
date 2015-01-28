-------------------------------------------------------------------------------
-- SEQUENCES.SQL
--   Sandbox for SQL SEQUENCES
-- -
-- AUTHOR:	John P. Hilbert
-- CREATED:	2012-01-09
-- MODIFIED:	2012-01-09
-- -  
-- SUMMARY:
--   
-- -
-- REQUIRE:
--	- 
-- -
-- TO DO:
--   
-- -  -------------------------------------------------------------------------------

CREATE TABLE day_of_year(
        days           NUMBER(3));

CREATE SEQUENCE seq_inc_by_one;

-- Repeat
INSERT INTO day_of_year VALUES (seq_inc_by_one.NEXTVAL);

select * from day_of_year;

DROP TABLE day_of_year;

DROP SEQUENCE seq_inc_by_one;