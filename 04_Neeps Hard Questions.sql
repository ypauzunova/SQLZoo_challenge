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




--- 12. Produce a table showing the utilisation rate and the occupancy level 
---     for all rooms with a capacity more than 60.

	
-- Definitions:                  
-- Utilisation rate = (total hours used during the semester) / (total available hours in semester)
--     				where total available hours in semester (900) = weeks per semester (15) * days per week (5) * hours per day (12) 
-- Occupancy level = (duration-weighted average number of students per event) / (room capacity)

	
-- Step 1: Calculate total available hours in semester
with semester_weeks as (
	select count(distinct id) as weeks_per_semester from week
)

, week_days as (
	select count(distinct dow) as days_per_week from event
)
	
-- Assume all rooms have the same daily span - select max 
, day_hours as (
	select max(hours_per_day) as max_hours_per_day 
	from (
		select 
			room, 
			max(tod + duration) - min(tod) as hours_per_day
		from event
		group by room
	) as hours_room
) 

, availability as (
	select
		*, 
		cw.weeks_per_semester * cd.days_per_week * ch.max_hours_per_day as  semester_hours
	from semester_weeks cw join week_days cd join day_hours ch
)

-- Step 2: Build timetable of all distinct event occurrences, 
--         including duration and actual seats occupancy
, events_timetable as (
	select 
		e.id, 
		e.room, 
		o.week, 
		e.dow, 
		e.tod, 
		e.duration,   
		sum(s.sze) as room_occupancy 
	from event e 
		join attends a on e.id = a.event
		join student s on a.student = s.id
		join occurs o on e.id = o.event
	group by e.room, o.week, e.dow, e.tod, e.duration, e.id
)

-- Step 3: For each room with capacity > 60, calculate:
--         - Utilisation rate = total duration / semester availability
--         - Occupancy level  = duration-weighted avg occupancy / capacity
, summary as (
	select 
		room, 
		capacity, 
		sum(duration) / semester_hours as utilisation_rate,
		(sum(room_occupancy * duration) / sum(duration))/ max(capacity) as occupancy_level
	from events_timetable e 
		cross join availability
		join room on e.room = room.id
	where capacity > 60
	group by room, capacity 
)

-- Step 4: Return final summary table
select * from summary
