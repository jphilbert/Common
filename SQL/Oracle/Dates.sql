-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Simple Date Manipulations
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select
-- Today
    sysdate as today,
-- First of Month
    trunc(sysdate, 'month') as first_of_month,
-- First of Year
    trunc(sysdate, 'year') as first_of_year,
-- Last of Month
    last_day(sysdate) as last_of_month,
-- Extract 
    extract(day from sysdate) as dd,
    extract(month from sysdate) as mm,
    extract(year from sysdate) as yyyy,
-- Days in Month
    add_months(trunc(sysdate, 'month'), 1) -
    trunc(sysdate, 'month') as days_in_month,
    last_day(sysdate) - trunc(sysdate, 'month') as days_in_month_bad
from
    dual;

select
    add_months( to_date('29-feb-2000'), 12),
    add_months(to_date('1-jan-2000'), 12) - to_date('1-jan-2000') as days_year
from
    dual;
