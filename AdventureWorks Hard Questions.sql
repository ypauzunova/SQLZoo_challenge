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




--- 13. Show the best selling item by value.

--- Definition of value: SUM(OrderQty * UnitPrice) across all orders
--- Granularity: ProductID (each distinct product)
--- Join note: LEFT JOIN to account solely for ProductIDs present in SalesOrderDetail
--- 		   (It does NOT include products with no sales)
select 
	sod.ProductID, 
	p.Name, 
	sum(sod.OrderQty * sod.UnitPrice) as Value
from SalesOrderDetail sod left join Product p
	on sod.ProductID = p.ProductID
group by 1,2
order by 3 desc
fetch next 1 rows with ties




--- 14. Show how many orders are in the following ranges (in $):
--- 	0-  99
--- 	100- 999
---  	1000-9999
--- 	10000-

-- Definition of Total Value: subtotal + tax + freight for each order

-- Step 1: Create SalesOrderID ¬ TotalValue pairs  
with order_value as (
	select 
		SalesOrderID, 
	coalesce(SubTotal,0) + coalesce(TaxAmt,0) + coalesce(Freight,0) as TotalValue 
	from SalesOrderHeader
), 

-- Step 2: Assign a range_label to each order ensuring no gaps 
--		   (e.g., values between 99 and 100 are included in the '0-  99' range) 
value_range as (
	select * ,
		case 
			when TotalValue >= 0 and TotalValue < 100 then '0-  99'
			when TotalValue >= 100 and TotalValue < 1000 then '100- 999'
			when TotalValue >= 1000 and TotalValue < 10000 then '1000-9999'
			else '10000-'
		end as range_label
	from order_value
)

-- Step 3: Summarise by range: number of orders and total value 
select 
	range_label as 'RANGE', 
	count(*) as 'Num Orders', 
	sum(TotalValue) as 'Total Value'
from value_range
group by 1




---15. Identify the three most important cities. Show the break down of top level product category against city.

-- Analyse by BillToAddressID (BillTo and ShipTo may differ; we use BillTo)
-- 'Importance' = gross line revenue =  sod.OrderQty * sod.UnitPrice (ignores discounts/tax/freight)

-- Step 1: Get a datailed breakdown on SalesOrderDetail level by City and top level product category with subtotals by City and City and Category 
with CityCatSubtotal as (
	select 
		a.City, 
		pc.Name,
		sum(sod.OrderQty * sod.UnitPrice) over(partition by a.City) as SalesCity,
		sum(sod.OrderQty * sod.UnitPrice) over(partition by a.City, pc.Name) as SalesCityCat
	from SalesOrderHeader soh left join Address a
		on soh.BillToAddressID = a.AddressID
	left join SalesOrderDetail sod 
		on soh.SalesOrderID = sod.SalesOrderID
	left join Product p 
		on sod.ProductID = p.ProductID
	left join ProductCategory pc
		on p.ProductCategoryID = pc.ProductCategoryID
),

-- Step 2: Top 3 cities by total sales (ties allowed/deterministic tie-break) 
MostImportantCities as (
	select distinct 
		City, 
		SalesCity 
	from CityCatSubtotal
	order by SalesCity desc
	fetch next 3 rows with ties
)

-- Step 3: Get the final breakdown
select distinct
	City,
	Name as ProductCategoryName,
	SalesCityCat as Sales
from CityCatSubtotal
where City in (select City from MostImportantCities)
order by City, Sales desc






