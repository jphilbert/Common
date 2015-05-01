-------------------------------------------------------------------------------
-- Suppose you have something like this:
-- ICD_DIAG    MI_FLAG    CHF_FLAG    PVD_FLAG    CVD_FLAG   DEMEN_FLAG
--   093.0         0        0        1        0        0
--   362.34        0        0        0        1        0
--   290.0         0        0        0        0        1
--   290.1         0        0        0        0        1
--   290.10        0        0        0        0        1
--   290.2         0        0        0        0        1
--   290.41        0        0        0        0        1
--   290.20        0        0        0        0        1
--   290.21        0        0        0        0        1	-------------------------------------------------------------------------------

select icd_diagnosis_id, variable_name, variable_value
from
    cci_table UNPIVOT INCLUDE NULLS (
	variable_value
	FOR( variable_name ) IN (
	    MI_FLAG as 'MI_FLAG',
            CHF_FLAG as 'CHF_FLAG',
            PVD_FLAG as 'PVD_FLAG',
            CVD_FLAG as 'CVD_FLAG',
            DEMEN_FLAG as 'DEMEN_FLAG',
            COPD_FLAG as 'COPD_FLAG',
            RHEU_FLAG as 'RHEU_FLAG',
            PUD_FLAG as 'PUD_FLAG',
            MLIV_FLAG as 'MLIV_FLAG',
            DM_NOCOMP_FLAG as 'DM_NOCOMP_FLAG',
            DM_COMP_FLAG as 'DM_COMP_FLAG',
            PLEG_FLAG as 'PLEG_FLAG',
            RD_FLAG as 'RD_FLAG',
            MALIG_FLAG as 'MALIG_FLAG',
            SLIV_FLAG as 'SLIV_FLAG',
            TUMOR_FLAG as 'TUMOR_FLAG',
            HIV_FLAG as 'HIV_FLAG'
	    )
	)
where
    variable_value > 0
    and
    rownum < 10
order by
    icd_diagnosis_id,
    variable_name;

-- ...would yield this:
-- ICD_DIAG    VARIABLE_NAME            VARIABLE_VALUE
-- 070.23      MLIV_FLAG                1
-- 070.32      MLIV_FLAG                1
-- 140         MALIG_FLAG               1
-- 140.0       MALIG_FLAG               1
-- 140.4       MALIG_FLAG               1
-- 140.6       MALIG_FLAG               1
-- 140.9       MALIG_FLAG               1
-- 141.2       MALIG_FLAG               1
-- 143.0       MALIG_FLAG    		1


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Another Example
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CREATE TABLE unpivot_test (
        id              NUMBER,
        customer_id     NUMBER,
        product_code_a  NUMBER,
        product_code_b  NUMBER,
        product_code_c  NUMBER,
        product_code_d  NUMBER
        );

INSERT INTO unpivot_test VALUES (1, 101, 10, 20, 30, NULL);
INSERT INTO unpivot_test VALUES (2, 102, 40, NULL, 50, NULL);
INSERT INTO unpivot_test VALUES (3, 103, 60, 70, 80, 90);
INSERT INTO unpivot_test VALUES (4, 104, 100, NULL, NULL, NULL);

SELECT *
FROM   unpivot_test
    UNPIVOT (quantity FOR product_code IN (product_code_a AS 'A', product_code_b AS 'B', product_code_c AS 'C', product_code_d AS 'D'));

SELECT *
FROM   unpivot_test
    UNPIVOT INCLUDE NULLS (quantity FOR product_code IN (product_code_a AS 'A', product_code_b AS 'B', product_code_c AS 'C', product_code_d AS 'D'));


drop table unpivot_test;