/* List Agg Function */

with a as (
select
    count(*) over (partition by master_member_id, begin_date) as cnt,
    master_member_id,
    begin_date,
    lob
from
    membership),
b as (
select
    master_member_id,
    begin_date,
    listagg(lob, ', ') within group (order by lob) as des
from
    a
where
    cnt > 1
group by
    master_member_id,
    begin_date
    )
select
    *
from
    b
where rownum < 10;
