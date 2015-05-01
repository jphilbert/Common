CREATE TABLE pivot_test (
        id            NUMBER,
        customer_id   NUMBER,
        product_code  VARCHAR2(5),
        product_code2 VARCHAR2(5),
        quantity      NUMBER
        );

INSERT INTO pivot_test VALUES (1, 1, 'A', 'X', 10);
INSERT INTO pivot_test VALUES (2, 1, 'B', 'X', 20);
INSERT INTO pivot_test VALUES (3, 1, 'C', 'X', 30);
INSERT INTO pivot_test VALUES (4, 2, 'A', 'X', 40);
INSERT INTO pivot_test VALUES (5, 2, 'C', 'X', 50);
INSERT INTO pivot_test VALUES (6, 3, 'A', 'X', 60);
INSERT INTO pivot_test VALUES (7, 3, 'B', 'X', 70);
INSERT INTO pivot_test VALUES (8, 3, 'C', 'X', 80);
INSERT INTO pivot_test VALUES (9, 3, 'D', 'X', 90);
INSERT INTO pivot_test VALUES (10, 4,'A', 'X', 100);
INSERT INTO pivot_test VALUES (1, 1, 'A', 'Y', 10);
INSERT INTO pivot_test VALUES (2, 1, 'B', 'Y', 20);
INSERT INTO pivot_test VALUES (3, 1, 'C', 'Y', 30);
INSERT INTO pivot_test VALUES (4, 2, 'A', 'Y', 40);
INSERT INTO pivot_test VALUES (5, 2, 'C', 'Y', 50);
INSERT INTO pivot_test VALUES (6, 3, 'A', 'Y', 60);
INSERT INTO pivot_test VALUES (7, 3, 'B', 'Y', 70);
INSERT INTO pivot_test VALUES (8, 3, 'C', 'Y', 80);
INSERT INTO pivot_test VALUES (9, 3, 'D', 'Y', 90);
INSERT INTO pivot_test VALUES (10, 4,'A', 'Y', 100);

select * from pivot_test;

SELECT *
FROM (
    SELECT product_code, quantity
    FROM   pivot_test)
    PIVOT  (
	SUM(quantity) AS sum_quantity
	FOR (product_code) IN ('A' AS a, 'B' AS b, 'C' AS c));

-- Break out Customer ID
SELECT *
FROM (
    SELECT customer_id, product_code, quantity
    FROM   pivot_test)
    PIVOT  (
	sum(quantity) AS sum_quantity
	FOR (product_code) IN ('A' AS a, 'B' AS b, 'C' AS c))
ORDER BY customer_id;

-- Combine two columns
SELECT *
FROM (
    SELECT customer_id, product_code || product_code2 as p_c, quantity
    FROM   pivot_test)
    PIVOT  (
        sum(quantity) AS sum_quantity
        FOR (p_c) IN ('AX' AS ax, 'BX' AS bx, 'CX' AS cx,
            'AY' AS ay, 'CY' AS cy))
ORDER BY customer_id;

drop table pivot_test;