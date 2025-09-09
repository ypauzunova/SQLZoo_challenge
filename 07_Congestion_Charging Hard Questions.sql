---- Congestion Charging Hard Questions
---- Schema & Tasks Link: https://sqlzoo.net/wiki/Congestion_Charging


--- 2. There are four types of permit. The most popular type means that 
---    this type has been issued the highest number of times. 
---    Find out the most popular type, together with the total number of permits issued.


select 
	chargeType 	as permit_type, 
	count(*) 	as times_issued
from permit 
group by chargeType
order by 2 desc
fetch next 1 row with ties 




--- 3. For each of the vehicles caught by camera 19 - show the registration, 
---    the earliest time at camera 19 and the time and camera at which it left the zone.


-- Approach
--  - 'Left the zone' = the next sighting at any camera with camera.perim = 'OUT'.
--    We ignore any movements between cameras within the same perimeter (null, i.e. INTERNAL)
--    or movement from INTERNAL to IN.


-- Step 1: Build a reusable view of all sightings with camera attributes.
with for_reuse as (
	select 
	i.* 
	, c.*
from camera c left join image i
	on i.camera = c.id
)

-- Step 2: Vehicles captured by camera 19 and their earliest timestamp there.
, t1 as (
	select 
		reg 		as registration
		, min(whn) 	as time_at_19
from for_reuse 
where camera = 19
group by reg
) 


-- Step 3: All events where a vehicle is recorded at an 'OUT' perimeter camera.
, t2 as (
	select 
		reg 		as registration
		, whn
from for_reuse 
where perim = 'OUT'
) 

-- Step 4: For each vehicle from t1, find the next 'OUT' event after time_at_19,
--         and include the camera of that exit event.
select 
	r.*
	, i.camera 
from (
	select 
		t1.registration
		, t1.time_at_19
		, min(t2.whn) 		as time_left
	from t1 left join t2
		on t1.registration = t2.registration
		and t1.time_at_19 < t2.whn
	group by 1,2
) r 
left join image i 
	on r.time_left = i.whn
	and r.registration = i.reg




--- 4) For all 19 cameras - show the position as IN, OUT or INTERNAL 
---    and the busiest hour for that camera.

-- Approach: 
--    - If multiple hour bins tie for the maximum traffic for a given camera return multiple rows
--    - Cameras with no traffic will show NULL for hour_bin

-- Step 1: Count sightings per camera-hour.
with traffic_per_hour as (
	select distinct 
		id
		,position
		,hour_bin 
		,count(*) over(partition by id, hour_bin) as trafic
	from (
		select 
			c.id
			, coalesce(c.perim, 'INTERNAL') 	as position
			, i.whn, date_format(i.whn, '%H') 	as hour_bin
		from camera c 
		-- left join to keep cameras with zero images 
		left join image i 
			on c.id = i.camera
	) a
)
-- Step 2: Rank hourbins by traffic per camera and keep the busiest.  
select 
	id
	, position
	, hour_bin
from (

	select 
		id
		, position
		, hour_bin
		, trafic
		-- rank to account for ties 
		, rank() over(partition by id  order by trafic desc) as bin_rank
	from traffic_per_hour 

) b
where bin_rank = 1
order by 1



