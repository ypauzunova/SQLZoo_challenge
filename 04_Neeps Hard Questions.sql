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




--- 13. A one hour staff meeting is to be held between 09:00 and 17:00. 
---     Events which clash are to be cancelled. 
---     Identify the hour which will result in the least disruption.


-- Assumptions & Definitions: 
--   - The meeting recurs weekly at the same day and time.  
--   - It can be scheduled on any day of the week.  
--   - 'Least disruption' is defined as the smallest number of academic hours lost.  
--   - If multiple options tie on hours, choose the slot with fewer affected events. 

 
-- Step 1: Generate all possible 1-hour start times between 09:00 and 17:00.
 with recursive all_slots_day as (
	select 9 as slot_start
    union all
    select slot_start + 1
    from all_slots_day
    where slot_start < 16
)

-- Step 2: List all possible 1-hour slots for each week and day of the semester 
, slots_per_semester as (
	select distinct w.id as week, e.dow, s.slot_start
	from week w
		cross join event e
		cross join all_slots_day s
)

-- Step 3: Build timetable of all distinct event occurrences and assign an ID 
, event_occurence_full as (
	select 
		e.id, 
		t.staff, 
		o.week, 
		e.dow, 
		e.tod, 
		e.duration,
		row_number() over(
			order by t.staff, o.week, e.dow, e.tod, e.duration
		) as event_occurence_id
	from event e 
		join teaches t on e.id = t.event
		join occurs o on e.id = o.event
)

-- Step 4: Split 2-hour events into two 1-hour slots, add 1h slot start time 
, slots_scheduled as (
	select * , tod as slot_start 
	from event_occurence_full
	
	union all
	
	select * , tod + 1 as slot_start 
	from event_occurence_full
	where duration = 2
)

-- Step 5: Count clashes per slot: both total events and total academic hours affected.   
, clash_counts as (
	select  
		a.dow, 
		a.slot_start, 
		count(duration) as clash_events, 
		coalesce (sum(duration),0) clash_hours
	from slots_per_semester a left join slots_scheduled s
		on a.week = s.week 
		and a.dow = s.dow 
		and a.slot_start = s.slot_start
	group by a.dow, a.slot_start
)

-- Step 6: Return the slot causing minimal diruption 
select * 
from clash_counts
order by clash_hours, clash_events
fetch next 1 row with ties

-- Answer: Schedule the staff meeting at 12pm each Friday




--- 14. Find all clashes - include the events which clash and the staff, 
---     student or rooms that they have in common.

--- Assumption: 
---             1) Events may have multiple staff members.

--- TO DO: 		Add logic to cover parent IDs for rooms and student groups.


-- Step 1: Build a timetable of all event occurences during the semester and assign id.
with details as (
	select 
		a.event, 
		o.week, 
		e.dow, 
		e.tod 								as tod_start, 
		e.tod + duration 					as tod_end, 
		t.staff 							as staff_id, 
		a.student 							as stud_id, 
		st.parent 							as stud_parent_id, 
		r.id 								as room_id, 
		r.parent 							as room_parent_id,
		-- occurence_id used to ensure no self-joins 
		row_number() over(order by event)	as occurence_id

	from event e 
		join occurs o 						on e.id = o.event
		join teaches t 						on e.id = t.event
		join staff sf 						on t.staff = sf.id
		join attends a 						on e.id = a.event
		join student st 					on a.student = st.id 
		join room r 						on e.room = r.id
)

-- Step 2: Identify clashes on staff, room, or student.
select 
	d1.week
	, d1.dow
	, d1.tod_start 						as tod_start1
	, d1.tod_end 						as tod_end1
	, d2.tod_start 						as tod_start2
	, d2.tod_end 						as tod_end2
	, d1.occurence_id 					as occurence_id1
	, d2.occurence_id 					as occurence_id2
	, d1.event 							as event1
	, d2.event 							as event2
	, d1.staff_id 						as staff_id1
	, d2.staff_id 						as staff_id2
	, d1.stud_id 						as stud_id1
	, d2.stud_id 						as stud_id2
	, d1.stud_parent_id 				as stud_parent_id1
	, d2.stud_parent_id 				as stud_parent_id2
	, d1.room_id 						as room_id1
	, d2.room_id 						as room_id2
	, d1.room_parent_id 				as room_parent_id1
	, d2.room_parent_id 				as room_parent_id2
	
from details d1 join details d2  
    
	-- Avoid self-joins  
	on d1.occurence_id > d2.occurence_id 
	
	-- Must be in the same week and day
	and d1.week = d2.week 
	and d1.dow = d2.dow 
	
	-- Times overlap
	and (
		d2.tod_start >= d1.tod_start and d2.tod_start < d1.tod_end
		or 
		d2.tod_end > d1.tod_start and d2.tod_end <= d1.tod_end
	)

	-- Clash occurs if one of the following holds:
    and (

		-- Staff double-booked (same staff, different event)
		d1.staff_id = d2.staff_id and d1.event != d2.event

		-- Rooms double-booked 
		or (d1.room_id = d2.room_id and d1.event != d2.event)
		
		-- Student double-booked 
		or (d1.stud_id = d2.stud_id and d1.event != d2.event)

	)

order by d1.week, d1.dow, d1.tod_start, d2.tod_start, d1.occurence_id




--- 15. Produce a timetable for a group of full time students for week 1

	
-- Approach:  
--   - Select the cohort with the largest total academic hours in the semester, assuming it is full-time.  
--   - If multiple cohorts tie, select the one that comes first alphabetically. 
	

-- Step 1: Normalise the attends table to the lowest-level cohort (student.id)  
--         so that each attendance is mapped consistently.  
--         In effect, we 'explode' parent-level cohorts into their individual students.
with attends_clean as (
	select 
		a.student, 
		a.event, 
		s.id, 
		s.parent, 
		coalesce (s.id, a.student) as cohort
	from attends a left join student s 
		on a.student = s.parent
)

-- Step 2: Build a semester-wide timetable for all cohorts
, timetable_all as (
	select 
		ac.cohort, 
		o.week, 
		e.dow, 
		e.tod, 
		ac.event, 
		e.kind, 
		e.duration, 
		e.room
	from event e join occurs o
		on e.id = o.event
	join attends_clean ac
		on e.id = ac.event 
)

-- Step 3: Identify the full-time cohort  
, ft_cohort as (
	select 
		cohort, 
		sum(duration) as hours_semester
	from timetable_all
	group by cohort
	order by hours_semester desc, cohort
	limit 1
)

-- Step 4: Return the timetable for the identified full-time cohort in week 1
select *
from timetable_all 
where cohort = (select cohort from ft_cohort) 
	and week = 1
order by 
	field(dow, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), 
	tod







