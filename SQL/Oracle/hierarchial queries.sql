drop table hier2;
create table hier2
    (
        parent  number,
        child   number,
	c	varchar2(5)
        );
insert into hier2 values(null,1,'a');
insert into hier2 values(1,2,'b');
insert into hier2 values(2,3,'c');
-- insert into hier2 values(3,1);
insert into hier2 values(2,4,'d');
insert into hier2 values(4,5,'e');
insert into hier2 values(null,10,'A');
insert into hier2 values(10,12,'B');
insert into hier2 values(12,13,'C');




select * from hier2;


select
    parent,
    cast(rpad(' ',2*(level - 1))|| '|-' || child as varchar2(10)) as child
from
    hier2
    start with parent is null
    connect by nocycle prior child = parent;



    with parent (root, child, parent, c, lvl) as (
    select
        child as root,
	child as child,
	parent as parent,
	c,
        1 as lvl
    from
	hier2
    where
	parent is null
    union all
    select
        p.root as root,
        e.child as child,
        e.parent as parent,
	e.c,
        p.lvl + 1 as lvl
    from
	hier2 e
        join
	parent p on p.child = e.parent
        )
select
    *
from
    parent
order by
    root, parent;



select
    root,
    max(id) keep (dense_rank last order by lvl, id)
from parent
group by root;