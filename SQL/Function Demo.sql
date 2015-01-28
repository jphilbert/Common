-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- This is the table used for some examples
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
drop TABLE emp;
CREATE TABLE emp (
        name            VARCHAR2(10),
        salary          NUMBER,
        comm            NUMBER,
        tot_comp        NUMBER
        );
INSERT INTO emp VALUES ('Larry', 1000, 50, 0);
INSERT INTO emp VALUES ('Curly', 200, 5, 0);
INSERT INTO emp VALUES ('Moe', 10000, 1000, 0);


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- FUNCTION
-- A simple function that adds two columns together and multiplies by 24
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CREATE OR REPLACE FUNCTION emp_comp (
        p_sal           NUMBER,
        p_comm          NUMBER )
    RETURN NUMBER
    IS
    BEGIN
    RETURN (p_sal + NVL(p_comm, 0)) * 24;
    END emp_comp;
    /

-- EXAMPLE
select
    name    ,
    salary  ,
    comm    ,
    tot_comp,
    emp_comp(salary, comm)
from
    emp;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- PROCEDURE
-- Applies the previous function to a single row in the created table and
-- UPDATES
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CREATE OR REPLACE PROCEDURE update_comp(p_name IN VARCHAR) AS
    BEGIN
UPDATE emp SET tot_comp = emp_comp(salary, comm)
WHERE name = p_name;
    END update_comp;
    /

-- EXAMPLE
    CALL update_comp('Curly');

SELECT * FROM emp;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Lists User Errors
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select * from SYS.USER_ERRORS;

-- or just the last one

select *
from SYS.USER_ERRORS
WHERE rownum = 1
ORDER BY rownum DESC;



-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Show all user functions & procedures
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SELECT
    owner,
    object_name,
    object_type,
    status
FROM
    ALL_OBJECTS
WHERE
    OBJECT_TYPE
    IN ('FUNCTION','PROCEDURE') and
    owner = user;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Remove the functions / procedures
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
drop procedure UPDATE_COMP ;
drop function EMP_COMP    ;

