
with
-- Get Range of data
min_max as (
select
    age,
    min(age) over () as min,
    max(age) over () as max
from
    member_demographic),
-- Bin Into Buckets
buckets as (
select
    min,
    max,
    width_bucket(age, min, max, 10) as bucket
from
    min_max),
-- Count the buckets
hist as (
select
    bucket,
    (bucket - 1) * max(max-min) / 10 + max(min) as low, -- Inclusive 
    bucket * max(max-min) / 10 + max(min) as high,	-- Exclusive
    count(*) as cnt
from
    buckets
group by
    bucket
order by
    bucket)
select
    bucket,
    low,
    high,
    cnt,
    round(cnt / sum(cnt) over () * 100, 3) as pct
from
    hist
;


