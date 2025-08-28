---- Dressmaker Hard Questions
---- Link: https://sqlzoo.net/wiki/Dressmaker_hard


--- 2. It is decided to review the materials stock. 
---    How much did each material contribute to turnover in 2002?

-- Assumptions: 
--   - Each material is uniquely defined by (fabric, colour, pattern) = material_no.  
--   - Turnover is approximated using material cost (since no sales price or margin data is available).

select 
	m.fabric
	, m.colour
	, m.pattern
	, round(sum(q.quantity * m.cost ), 2) as material_cost
from order_line ol join quantities q
	on ol.ol_style = q.style_q
	and ol.ol_size = q.size_q
join material m
	on ol.ol_material = m.material_no
group by m.fabric, m.colour, m.pattern




--- 3. An order for shorts has just been placed 
---    and the work is to be distributed amongst the workforce, 
---    and we wish to know how busy the shorts makers are. 
---    For each of the workers who have experience of making shorts 
---    show the number of hours work that she is currently committed to, 
---    assuming a meagre wage of £4.50 per hour

-- Assumptions:  
--   - If finish_date is populated, the order is complete.  
--   - Current commitments are therefore identified by finish_date IS NULL.

-- Limitations:  
--   - No information on work in progress is available, so all budgeted hours are counted as outstanding.  
--   - In practice, true current commitments would likely be lower, depending on progress made.  
--   - This means relative workload distribution across makers may also differ in reality. 

-- Step 1: Prepare a reusable dataset with relevant features. 
with for_reuse as (
	select 
		cnst.maker
		, g.description
		, g.labour_cost
		
		-- flag current commitments
		, case when cnst.finish_date is null then 1 else 0 end as curr_comm_flag
		
		-- add synthetic ID for joining 
		, row_number() over() as order_line_id
		
	from construction cnst join order_line ol 
		on ol.order_ref = cnst.order_ref
		and ol.line_no = cnst.line_ref
	join garment g
		on ol.ol_style = g.style_no 

)

-- Step 2: Calculate current workload (in hours) for those experienced with shorts.
select distinct 
	rs_e.maker as maker_id
	, dm.d_name as maker_name
	
	-- hours = (labour_cost * curr_comm_flag) ÷ £4.50 (wage per hour), applied to current commitments
	, round(sum(rs_hcc.labour_cost * rs_hcc.curr_comm_flag / 4.5),1) as hours_curr_comm

from for_reuse rs_e 

	-- left join to keep all experienced even with no current comitments
	left join for_reuse rs_hcc on rs_e.order_line_id = rs_hcc.order_line_id

	-- join names for presentation 
	join dressmaker dm on rs_e.maker = dm.d_no

-- restrict to workers with shorts-making experience 
where rs_e.maker in (
	select distinct e.maker 
	from for_reuse e 
	where e.description = 'Shorts'
	)
group by 1,2
order by 1




