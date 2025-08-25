---- Musicians Hard Questions
---- Schema & Tasks Link: https://sqlzoo.net/wiki/Musicians



--- 11. List the name and town of birth of any performer born in the same city as James First.

select 
	distinct m.m_name 		as performer_name, 
	p.place_town 			as town_of_birth
from performer pfmr 
	left join musician m 	on m.m_no 		= pfmr.perf_is
	left join place p 		on m.born_in 	= p.place_no
	left join musician jf 	on jf.m_name 	= 'James First'
where m.born_in = jf.born_in
	and m.m_name != 'James First' 




--- 12. Create a list showing for EVERY musician born in Britain 
---     the number of compositions and the number of instruments played.

-- left join to list EVERY musician (incl. with zero-counts)
select 
	m.m_name as musician
	, count(distinct cc.cmpn_no) as compositions_num
	, count(distinct pfmr.instrument) as instruments_num

from musician m 
left join place p 			on m.born_in 		= p.place_no
left join composer cmpr 	on m.m_no 			= cmpr.comp_is
left join has_composed cc 	on cmpr.comp_no 	= cc.cmpr_no
left join performer pfmr 	on m.m_no 			= pfmr.perf_is

where p.place_country in ('England', 'Scotland')
group by m.m_name

order by 1




--- 13. Give the band name, conductor and contact of the bands 
---     performing at the most recent concert in the Royal Albert Hall.

select 
	b.band_name 		as band_name
	, m_cb.m_name 		as conductor_name
	, m_bc.m_name 		as band_contact_name

-- Join two instances of musician table to get conductor and contact names
from concert c
left join performance pfmc 		on pfmc.performed_in 	= c.concert_no
left join band b 				on b.band_no 			= pfmc.gave
left join musician m_cb 		on m_cb.m_no 			= pfmc.conducted_by
left join musician m_bc 		on m_bc.m_no 			= b.band_contact
where c.concert_venue = 'Royal Albert Hall'

-- Return all records related to the most recent concert
order by c.con_date desc
fetch next 1 row with ties




--- 14. Give a list of musicians associated with Glasgow. 
---     Include the name of the musician 
---     and the nature of the association - one or more of 
---     - 'LIVES_IN', 
---     - 'BORN_IN', 
---     - 'PERFORMED_IN' 
---     - AND 'IN_BAND_IN'.

-- Build a table with four binary columns (0/1)  
-- Each column indicates the presence of an association.
select * from (
	select distinct 
		m.m_name as musician_name
		-- Musician lives in Glasgow
		, case when p_li.place_town = 'Glasgow' then 1 else 0 end as 'LIVES_IN'
		-- Musician was born in Glasgow
		, case when p_bi.place_town = 'Glasgow' then 1 else 0 end as 'BORN_IN'
		-- Musician has performed at least once in Glasgow
		, max(case when p_pi.place_town = 'Glasgow' then 1 else 0 end) over (partition by m.m_no) as 'PERFORMED_IN'
		-- Musician is a member of a band based in Glasgow
		, max(case when p_bh.place_town = 'Glasgow' then 1 else 0 end) over (partition by m.m_no) as 'IN_BAND_IN'
	from musician m 
	left join performer pfmr 		on m.m_no 				= pfmr.perf_is
	left join plays_in pb 			on pfmr.perf_no 		= pb.player
	left join band b 				on pb.band_id 			= b.band_no
	left join performance pfmc 		on b.band_no 			= pfmc.gave
	left join concert c 			on pfmc.performed_in 	= c.concert_no
	
	-- Join to place table for each type of association
	left join place p_li 			on p_li.place_no 		= m.living_in
	left join place p_bi 			on p_bi.place_no 		= m.born_in
	left join place p_pi 			on p_pi.place_no 		= c.concert_in
	left join place p_bh 			on p_bh.place_no 		= b.band_home
) x 

-- Keep only musicians associated with Glasgow by at least one criterion
where (LIVES_IN + BORN_IN + PERFORMED_IN + IN_BAND_IN) > 0
