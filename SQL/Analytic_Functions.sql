-- Taken from: http://www.orafaq.com/node/55

SELECT deptno,
    COUNT(*) DEPT_COUNT
FROM emp
WHERE deptno IN (20, 30)
GROUP BY deptno;

-- DEPTNO                 DEPT_COUNT             
-- ---------------------- ---------------------- 
-- 20                     5                      
-- 30                     6                      

-- 2 rows selected


SELECT empno, deptno, 
    COUNT(*) OVER (PARTITION BY 
        deptno) DEPT_COUNT
FROM emp
WHERE deptno IN (20, 30);

-- EMPNO     DEPTNO DEPT_COUNT
-- ---------- ---------- ----------
-- 7369         20          5
-- 7566         20          5
-- 7788         20          5
-- 7902         20          5
-- 7876         20          5
-- 7499         30          6
-- 7900         30          6
-- 7844         30          6
-- 7698         30          6
-- 7654         30          6
-- 7521         30          6

-- 11 rows selected.


SELECT empno, deptno, hiredate,
    ROW_NUMBER( ) OVER (PARTITION BY
        deptno ORDER BY hiredate
        NULLS LAST) SRLNO
FROM emp
WHERE deptno IN (10, 20)
ORDER BY deptno, SRLNO;

-- EMPNO  DEPTNO HIREDATE       SRLNO
-- ------ ------- --------- ----------
-- 7782      10 09-JUN-81          1
-- 7839      10 17-NOV-81          2
-- 7934      10 23-JAN-82          3
-- 7369      20 17-DEC-80          1
-- 7566      20 02-APR-81          2
-- 7902      20 03-DEC-81          3
-- 7788      20 09-DEC-82          4
-- 7876      20 12-JAN-83          5

-- 8 rows selected.

SELECT deptno, empno, sal,
    LEAD(sal, 1, 0) OVER (PARTITION BY dept ORDER BY sal DESC NULLS LAST) NEXT_LOWER_SAL,
    LAG(sal, 1, 0) OVER (PARTITION BY dept ORDER BY sal DESC NULLS LAST) PREV_HIGHER_SAL
FROM emp
WHERE deptno IN (10, 20)
ORDER BY deptno, sal DESC;

-- DEPTNO  EMPNO   SAL NEXT_LOWER_SAL PREV_HIGHER_SAL
-- ------- ------ ----- -------------- ---------------
-- 10   7839  5000           2450               0
-- 10   7782  2450           1300            5000
-- 10   7934  1300              0            2450
-- 20   7788  3000           3000               0
-- 20   7902  3000           2975            3000
-- 20   7566  2975           1100            3000
-- 20   7876  1100            800            2975
-- 20   7369   800              0            1100

-- 8 rows selected.



-- How many days after the first hire of each department were the next
-- employees hired?

SELECT empno, deptno, -- hiredate ?
    FIRST_VALUE(hiredate)
    OVER (PARTITION BY deptno ORDER BY hiredate) DAY_GAP
FROM emp
WHERE deptno IN (20, 30)
ORDER BY deptno, DAY_GAP;

-- EMPNO     DEPTNO    DAY_GAP
-- ---------- ---------- ----------
-- 7369         20          0
-- 7566         20        106
-- 7902         20        351
-- 7788         20        722
-- 7876         20        756
-- 7499         30          0
-- 7521         30          2
-- 7698         30         70
-- 7844         30        200
-- 7654         30        220
-- 7900         30        286

-- 11 rows selected.

-- How each employee's salary compare with the average salary of the first
-- year hires of their department?

SELECT empno, deptno, TO_CHAR(hiredate,'YYYY') HIRE_YR, sal,
    TRUNC(
        AVG(sal) KEEP (DENSE_RANK FIRST
        ORDER BY TO_CHAR(hiredate,'YYYY') )
        OVER (PARTITION BY deptno)
        ) AVG_SAL_YR1_HIRE
FROM emp
WHERE deptno IN (20, 10)
ORDER BY deptno, empno, HIRE_YR;

-- EMPNO     DEPTNO HIRE        SAL AVG_SAL_YR1_HIRE
-- ---------- ---------- ---- ---------- ----------------
-- 7782         10 1981       2450             3725
-- 7839         10 1981       5000             3725
-- 7934         10 1982       1300             3725
-- 7369         20 1980        800              800
-- 7566         20 1981       2975              800
-- 7788         20 1982       3000              800
-- 7876         20 1983       1100              800
-- 7902         20 1981       3000              800

-- 8 rows selected.




-- The query below has no apparent real life description (except 
-- column FROM_PU_C) but is remarkable in illustrating the various windowing
-- clause by a COUNT(*) function.
 
SELECT empno, deptno, TO_CHAR(hiredate, 'YYYY') YEAR,
    COUNT(*) OVER (PARTITION BY TO_CHAR(hiredate, 'YYYY')
    ORDER BY hiredate ROWS BETWEEN 3 PRECEDING AND 1 FOLLOWING) FROM_P3_TO_F1,
    COUNT(*) OVER (PARTITION BY TO_CHAR(hiredate, 'YYYY')
    ORDER BY hiredate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) FROM_PU_TO_C,
    COUNT(*) OVER (PARTITION BY TO_CHAR(hiredate, 'YYYY')
    ORDER BY hiredate ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) FROM_P2_TO_P1,
    COUNT(*) OVER (PARTITION BY TO_CHAR(hiredate, 'YYYY')
    ORDER BY hiredate ROWS BETWEEN 1 FOLLOWING AND 3 FOLLOWING) FROM_F1_TO_F3
FROM emp
    ORDEDR BY hiredate;

-- EMPNO  DEPTNO YEAR FROM_P3_TO_F1 FROM_PU_TO_C FROM_P2_TO_P1 FROM_F1_TO_F3
-- ------ ------- ---- ------------- ------------ ------------- -----------
-- 7369      20 1980             1            1             0             0
-- 7499      30 1981             2            1             0             3
-- 7521      30 1981             3            2             1             3
-- 7566      20 1981             4            3             2             3
-- 7698      30 1981             5            4             3             3
-- 7782      10 1981             5            5             3             3
-- 7844      30 1981             5            6             3             3
-- 7654      30 1981             5            7             3             3
-- 7839      10 1981             5            8             3             2
-- 7900      30 1981             5            9             3             1
-- 7902      20 1981             4           10             3             0
-- 7934      10 1982             2            1             0             1
-- 7788      20 1982             2            2             1             0
-- 7876      20 1983             1            1             0             0

-- 14 rows selected.




-- For each employee give the count of employees getting half more that their
-- salary and also the count of employees in the departments 20 and 30 getting
-- half less than their salary.
 
SELECT deptno, empno, sal,
    Count(*) OVER (PARTITION BY deptno ORDER BY sal RANGE
        BETWEEN UNBOUNDED PRECEDING AND (sal/2) PRECEDING) CNT_LT_HALF,
    COUNT(*) OVER (PARTITION BY deptno ORDER BY sal RANGE
        BETWEEN (sal/2) FOLLOWING AND UNBOUNDED FOLLOWING) CNT_MT_HALF
FROM emp
WHERE deptno IN (20, 30)
ORDER BY deptno, sal

-- DEPTNO  EMPNO   SAL CNT_LT_HALF CNT_MT_HALF
-- ------- ------ ----- ----------- -----------
-- 20   7369   800           0           3
-- 20   7876  1100           0           3
-- 20   7566  2975           2           0
-- 20   7788  3000           2           0
-- 20   7902  3000           2           0
-- 30   7900   950           0           3
-- 30   7521  1250           0           1
-- 30   7654  1250           0           1
-- 30   7844  1500           0           1
-- 30   7499  1600           0           1
-- 30   7698  2850           3           0

-- 11 rows selected.