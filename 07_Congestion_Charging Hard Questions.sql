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
