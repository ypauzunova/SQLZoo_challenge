---- Helpdesk Hard Questions 
---- Schema & Tasks Link: https://sqlzoo.net/wiki/Help_Desk

--- 11. Show the manager and number of calls received for each hour of the day on 2017-08-12


-- Step 1: Get shift details for the target date
with shift_details as (
	select 
		s.Shift_date, 
		s.Shift_type, 
		s.Manager, 
		t.Start_time, 
		t.End_time
	from Shift as s 
	inner join Shift_type as t 
		on s.Shift_type = t.Shift_type
	where date(Shift_date) = '2017-08-12'
)

-- Step 2: Count calls per manager by hour
select 
	sd.Manager, 
	DATE_FORMAT(i.call_date, '%Y-%m-%d %H') as Hr, 
	count(*) as cc
from Issue as i 
inner join shift_details as sd
	on time(i.call_date) >= sd.Start_time 
	and time(i.call_date) < sd.End_time
where date(Call_date) = '2017-08-12'
group by 1, 2
order by Hr

