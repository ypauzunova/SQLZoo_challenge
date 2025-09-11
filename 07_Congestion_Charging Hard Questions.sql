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




--- 5. Anomalous daily permits. Daily permits should not be issued for non-charging days. 
---    Find a way to represent charging days. Identify the anomalous daily permits.

-- Approach:
--   - Charging policy is not explicitly defined in the database.
--   - Use weekday frequency patterns of permits and camera images to infer charging days.
--   - Assume customers are less likely to purchase long-term permits on non-charging days.

-- Step 1: add weekday feature for easier grouping (0 = Monday ... 6 = Sunday in MySQL)
with permit_wd as (
	select 
		*
		, weekday(sDate) as wd
	from permit
)

-- Step 2: count Daily permits issued by weekday
, daily_permit_wd_cc as (
	select 
		wd
		, count(*) as daily_pc
	from permit_wd
	where chargeType = 'Daily'
	group by 1
	order by 1
)

-- Step 3: count all permits (any type) by weekday
, any_permit_wd_cc as (
	select 
		wd
		, count(*) as any_pc
	from permit_wd
	group by 1
	order by 1
)

-- Step 4: count camera images taken by weekday (sanity check against permit activity)
, image_wd_cc as (
	select 
		weekday(whn)
		, count(* ) camera_shot_cc
	from image
	group by 1
)

-- Observations:
--   - Daily permits: wd=4 none issued; wd=3 2 issued; wd=5 2 issued
--   - Any permits:  wd=4 none issued; wd=3 2 issued; wd=5 5 issued
--   - Likely non-charging days: wd=3 & wd=4 (Thursday and Friday)
--   - Camera table includes wd=6 records, which does not contradict permit data

-- Step 5: identify anomalous Daily permits (issued on non-charging days)
select *
from permit_wd
where wd in (3,4) and chargeType = 'Daily'





--- 6. Issuing fines: Vehicles using the zone during the charge period, 
---    on charging days must be issued with fine notices unless they have 
---    a permit covering that day. List the name and address of such culprits, 
---    give the camera and the date and time of the first offence.

-- Assumption: 
--    - All image timestamps fall within the overall scheme’s charging period.
--    - Any camera registration counts as use of the zone (i.e. a potential breach). 

-- Step 1: derive permit end dates by charge type
with permits_days as (
	select 
		reg
		, sDate
		, case 
			when p.chargeType = 'Daily' then sDate + interval 1 day
			when p.chargeType = 'Weekly' then sDate + interval 1 week
			when p.chargeType = 'Monthly' then sDate + interval 1 month
			when p.chargeType = 'Annual' then sDate + interval 1 year
			else null
		end as eDate
	from permit p
)

-- Step 2: label each image event as authorised/unauthorised (authorised = falls within a permit window)
, authorised as (
	select 
		i.camera
		, i.whn
		, i.reg
		, pd.sDate
		, pd.eDate
		,case when i.whn between pd.sDate and pd.eDate then 1 else 0 end as auth
	from image i left join permits_days pd 
	on i.reg = pd.reg
)

-- Step 3: keep only unauthorised usage events (no valid permit at the event time)
, unauthorised as (
	select 
		i.camera
		, i.whn
		, i.reg
	from image i join authorised a
		on i.camera = a.camera 
		and i.whn = a.whn
		and i.reg = a.reg
	where a.auth = 0
)

-- Step 4: identify each keeper’s earliest unauthorised event
, rank_offence as (
	select 
		k.name
		, k.address
		, un.camera
		, un.whn  
		, rank() over(partition by k.id order by un.whn asc) as offence_rank
	from unauthorised un join vehicle v
		on un.reg = v.id
	join keeper k 
		on v.keeper = k.id
)

-- Step 5: output culprits (first offence only), sorted alphabetically
select 
	name
	, address
	, camera
	, whn 		as first_offence_dt
from rank_offence
where offence_rank = 1
order by 1
