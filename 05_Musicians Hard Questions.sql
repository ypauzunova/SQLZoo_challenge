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
