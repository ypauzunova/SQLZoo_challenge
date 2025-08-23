---- Musicians Hard Questions
---- Schema & Tasks Link: https://sqlzoo.net/wiki/Musicians



--- 11. List the name and town of birth of any performer born in the same city as James First.

select 
	distinct m.m_name as performer_name, 
	p.place_town as town_of_birth
from performer pfmr left join musician m 
	on m.m_no = pfmr.perf_is
left join place p
	on m.born_in = p.place_no
left join musician jf
	on jf.m_name = 'James First'
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
