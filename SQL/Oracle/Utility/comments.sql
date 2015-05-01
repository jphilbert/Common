-- Note: below are table comments, however comments may be added to a column
-- simply by substituting TABLE by COLUMN

-- Delete a comment
    comment on table MEMBERSHIP is ' ';

-- Add a comment
    comment on table MEMBERSHIP is 'Test2';

-- View comments
select
    table_name,
    cast(COMMENTS as varchar2(20)) as comments
from
    user_tab_comments;

