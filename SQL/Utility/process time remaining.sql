-- taken from: http://www.gplivna.eu/papers/v$session_longops.htm#_Toc155540263
-- this important parts are elapsed_time and time_remaining
-- note: without USERNAME... it won't give you other sessions

select * from 
	(
    select substr(opname,1,15) AS OPNAME, START_TIME,
	to_char(elapsed_seconds/60,'999.9') AS DONE_MIN,
	to_char(time_remaining/60,'999.9') AS LEFT_MIN
    from v$session_longops
    where USERNAME = user
    order by start_time desc
	)
where rownum <=1;
