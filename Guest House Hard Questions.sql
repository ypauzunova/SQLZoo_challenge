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



