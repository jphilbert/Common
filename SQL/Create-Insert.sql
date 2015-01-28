CREATE TABLE temp (
	x NUMERIC,
	y NUMERIC);

INSERT INTO temp
    (x, y)
    VALUES
    (1, 2);

INSERT ALL
INTO temp VALUES (3, 6)
INTO temp VALUES (3, 7)
INTO temp VALUES (3, 4)
SELECT * FROM dual;

DROP TABLE temp;

CREATE TABLE temp (
        x NUMERIC,
        y DATE);

INSERT INTO temp
    (x, y)
    VALUES
    (1, TO_DATE('2011/01/28', 'YYYY/MM/DD'));
