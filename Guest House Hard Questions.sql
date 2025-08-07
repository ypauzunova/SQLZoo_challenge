---- Guest House Hard Problems
---- Schema & Tasks Link: https://sqlzoo.net/wiki/Guest_House

--- 11. Coincidence. Have two guests with the same surname ever stayed in the hotel on the evening?
--- Show the last name and both first names. Do not include duplicates.


-- Step 1: Get booking details essential for further analysis 
with bookings_data as (
	select 
		b.booking_date as check_in, 
		b.booking_date + interval b.nights day as check_out, 
		g.last_name, g.first_name
	from booking b join guest g
		on b.guest_id = g.id
)

-- Step 2: Identify unique pairs of guests sharing a surname whose stays overlap on at least one night 
select distinct 
	bd1.last_name, 
	bd1.first_name, 
	bd2.first_name 
from bookings_data bd1 join bookings_data bd2

	-- surnames match
	on bd1.last_name = bd2.last_name
	-- bd1 checked in before bd2 checked out
	and bd1.check_in < bd2.check_out
	-- bd1 hasn't checked out before bd2 checked in
	and bd1.check_out > bd2.check_in
	-- avoid duplicates 
	and bd1.first_name < bd2.first_name
	

order by bd1.last_name




--- 12. Check out per floor. The first digit of the room number indicates the floor – 
--- e.g. room 201 is on the 2nd floor. For each day of the week beginning 2016-11-14 show 
--- how many rooms are being vacated that day by floor number. Show all days in the correct order. 

-- Step 1: Generate 7 consecutive analysis dates starting from 2016-11-14
with recursive analysis_dates as (
	select date ('2016-11-14') as dt
	union all
	select dt + interval 1 day
	from analysis_dates
	where dt < date('2016-11-14') + interval 6 day
)

-- Step 2: Count checkouts per floor for each analysis date  
select
	booking_date + interval nights day as check_out, 
	-- Count rooms on 1st floor (room numbers starting with 1)
	sum(case when left(room_no, 1) = 1 then 1 else 0 end ) as 1st,
	-- Count rooms on 2nd floor (room numbers starting with 2)
	sum(case when left(room_no, 1) = 2 then 1 else 0 end ) as 2nd,
	-- Count rooms on 3rd floor (room numbers starting with 3)
	sum(case when left(room_no, 1) = 3 then 1 else 0 end ) as 3rd

from booking
group by check_out
having check_out in (select dt from analysis_dates)
order by check_out




--- 13. Free rooms? List the rooms that are free on the day 25th Nov 2016.

-- Step 1: Identify rooms that are occupied on 2016-11-25
with rooms_occupied as (
	select 
		room_no, 
		booking_date, 
		nights,
		case 
			when date('2016-11-25') >= booking_date and date('2016-11-25') < date(booking_date) + interval nights day then 1
			else 0
		end as occupied
	from booking
	having occupied = 1
)

-- Step 2: Get free rooms (not occupied)
select id 
from room
where id not in (select room_no from rooms_occupied)




--- 14. Single room for three nights required. A customer wants a single room for three consecutive nights. Find the first available date in December 2016.

-- Step 1: Identify gaps between bookings for single rooms
-- Use left join to include rooms that have never been booked (if any)
with single_room_bookings_with_gaps as (
	select 
		room_no,
		booking_date as check_in,		
		booking_date + interval nights day as check_out,
		lead(booking_date, 1) over(partition by room_no order by check_out) as next_check_in
	from room r left join booking b 
		on r.id = b.room_no 
	where room_type = 'single'
),

-- Step 2: Filter available dates from Dec 1 onwards
-- Assign '2016-12-01' as available_from for: (1) spare capacity already available before Dec 1, or (2) rooms never booked
available_from_dec_1_onwards as (
	select  
		room_no,
		case 
			when 
				check_out <= date('2016-12-01') 
				or check_out is null
			then date('2016-12-01')
			else check_out
		end as available_from,
		next_check_in 

	from single_room_bookings_with_gaps
	where next_check_in is null or next_check_in > '2016-12-01'
),

-- Step 3: Calculate number of available nights between check-out and next check-in  
-- If no next_check_in (i.e. open-ended availability), assume the room is free for more than 3 nights, e.g. 100
-- Remove cases where no availability between bookings
available_stays_with_length as(
	select 
		room_no,
		available_from,
		next_check_in,
		coalesce(
			datediff(next_check_in, available_from), 100
		) as available_nights
	from available_from_dec_1_onwards
	having available_nights > 0
)

-- Step 4: Get earliest available start date and room number(s) for a single room with ≥ 3 consecutive nights available in Dec
select 
	room_no, 
	available_from
from available_stays_with_length 
where available_nights >= 3
order by available_from asc
fetch next 1 row with ties
