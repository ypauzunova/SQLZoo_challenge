---- AdventureWorks Hard Questions
---- Schema & Tasks Link: https://sqlzoo.net/wiki/AdventureWorks


--- 11. For every customer with a 'Main Office' in Dallas show AddressLine1 
--- of the 'Main Office' and AddressLine1 of the 'Shipping' address - 
--- if there is no shipping address leave it blank. Use one row per customer.

-- Step 1: Select AddressLine1 of the 'Main Office' 
-- for customers with a 'Main Office' in Dallas 
with TargetCustomersMO as (
	select 
		ca.CustomerID, 
		a.AddressLine1 as AddressLine1_mo
	from CustomerAddress ca join Address a 
		on ca.AddressID = a.AddressID
	where ca.AddressType = 'Main Office' and a.City = 'Dallas'
),

-- Step 2: Select AddressLine1 of the 'Shipping' address 
-- for customers with a 'Main Office' in Dallas
TargetCustomersSH as (
	select 
		ca.CustomerID, 
		a.AddressLine1 as AddressLine1_sh
	from CustomerAddress ca join Address a 
		on ca.AddressID = a.AddressID
	where ca.AddressType = 'Shipping' 
	and ca.CustomerID in (select CustomerID from TargetCustomersMO)
)

-- Step 3: Display the result 
select 
	mo.CustomerID, 
	mo.AddressLine1_mo, 
	sh.AddressLine1_sh
from TargetCustomersMO mo left join TargetCustomersSH sh
	on mo.CustomerID = sh.CustomerID









