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


