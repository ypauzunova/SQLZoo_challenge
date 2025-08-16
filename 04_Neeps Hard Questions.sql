---- Neeps (University Timetables) Hard Questions
---- Schema & Tasks Link: https://sqlzoo.net/wiki/Neeps


--- 11. co.CHt is to be given all the teaching that co.ACg currently does. Identify those events which will clash.

-- Step 1: Build a timetable of all events for the two teachers during the semester.
--         For each event, capture start time (tod_start) and calculate end time (tod_end).
with staff_timetable as (
	select 
		t.staff, 
		o.event, 
		o.week, 
		e.dow, 
		e.tod as tod_start, e.duration,
		e.tod + duration AS tod_end
	from teaches t 
		join event e on t.event = e.id
		join occurs o on e.id = o.event
	where staff in ('co.CHt', 'co.ACg')
)


-- Step 2: Detect clashes by pairing events from different staff.
--         A clash exists if:
--           - Both events are in the same week and day, AND
--           - One event starts or ends within the time range of the other.
select 
	st1.week, 
	st1.dow, 
	st1.event as event1, 
	st1.tod_start as tod1, 
	st1.duration as duration1, 
	st2.event as event2, 
	st2.tod_start as tod2, 
	st2.duration as duration2
from staff_timetable st1 join staff_timetable st2
	on st1.staff > st2.staff 
	and st1.week = st2.week 
	and st1.dow = st2.dow 
	and (
		st2.tod_start >= st1.tod_start and st2.tod_start < st1.tod_end
		or 
		st2.tod_end > st1.tod_start and st2.tod_end <= st1.tod_end
	)
order by st1.week, st1.dow, st1.tod_start, st1.duration, st2.tod_start