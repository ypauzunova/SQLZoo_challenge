---- Guest House Hard Problems
---- Schema & Tasks Link: https://sqlzoo.net/wiki/Guest_House

--- 11. Coincidence. Have two guests with the same surname ever stayed in the hotel on the evening? Show the last name and both first names. Do not include duplicates.


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