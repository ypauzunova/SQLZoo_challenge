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




--- 12. For each order show the SalesOrderID and SubTotal calculated three ways:
--- A) From the SalesOrderHeader
--- B) Sum of OrderQty*UnitPrice
--- C) Sum of OrderQty*ListPrice

-- Join SalesOrderHeader (primary key: SalesOrderID) to related order details and product data
-- Using LEFT JOIN to ensure orders appear even if matching detail or product rows are missing
-- Do not use COALESCE — leaving NULLs helps highlight missing data for reconciliation
select distinct 
	soh.SalesOrderID, 
	soh.SubTotal as SubTotal_A, 
	sum(sod.OrderQty * sod.UnitPrice) over(partition by soh.SalesOrderID) as SubTotal_B,
	sum(sod.OrderQty * p.ListPrice) over(partition by soh.SalesOrderID) as SubTotal_C
from SalesOrderHeader soh left join SalesOrderDetail sod
	on soh.SalesOrderID = sod.SalesOrderID
left join Product p 
	on sod.ProductID = p.ProductID











