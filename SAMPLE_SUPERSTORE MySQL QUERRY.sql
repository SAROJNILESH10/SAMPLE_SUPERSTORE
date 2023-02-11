use sample_superstore;    --- Database Name

-- 1) Which is the most loss making category in the East region?

WITH most_loss AS
(
SELECT category, profit,
	RANK() OVER(ORDER BY profit) AS RNK
FROM orders
WHERE region = 'East'
)
SELECT category, profit as max_lost
FROM most_loss
WHERE RNK = 1;

-- 2) Give me the top 3 product ids by most returns?

WITH most_return AS
(
SELECT ret.orderID, ord.`Product ID` AS ProductID
FROM returns AS ret
INNER JOIN orders AS ord
ON ret.orderID = ord.`Order ID`
ORDER BY 2 
)
SELECT ProductID, max_return
FROM
(
SELECT ProductID, COUNT(ProductID) AS max_return,
	DENSE_RANK() OVER(ORDER BY COUNT(ProductID) DESC) AS RNK
FROM most_return
GROUP BY 1
ORDER BY 2 DESC
) T1
WHERE RNK BETWEEN 1 AND 3;


-- 3) In which city the most number of returns are being recorded?


WITH postal_code AS
(
SELECT distinct ret.orderID, ord.`Postal Code` as PostalCode
FROM returns AS ret
INNER JOIN orders AS ord
ON ret.orderID = ord.`Order ID`
), 
max_return as
(
SELECT PostalCode, max_post
FROM
(
SELECT PostalCode, COUNT(PostalCode) AS max_post,
	DENSE_RANK() OVER(ORDER BY COUNT(PostalCode) DESC) AS RNK
FROM postal_code
GROUP BY 1
ORDER BY 2 DESC
) T1
WHERE RNK = 1
)
SELECT City
FROM
(
SELECT mr.PostalCode AS PinCode, loc.City AS City
FROM max_return AS mr
INNER JOIN location AS loc
ON mr.PostalCode = loc.`Postal Code`
) T2;


-- 4) Find the relationship between days between order date , ship date and profit?


WITH profit_wrt_days AS
(SELECT `Order Date`, `Ship Date`, DATEDIFF( `Ship Date`,`Order Date`) AS days_bet_order_and_shipping, Profit,
	ROUND(SUM(Profit) OVER(PARTITION BY DATEDIFF( `Ship Date`,`Order Date`) ORDER BY DATEDIFF( `Ship Date`,`Order Date`) DESC ),2) AS Profit_over_days
FROM Orders
ORDER BY 3 DESC
)
SELECT DISTINCT days_bet_order_and_shipping, Profit_over_days
FROM profit_wrt_days;


-- 5) Find the region wise profits for all the regions and give the output of the most profitable region. 

SELECT Region, ROUND(SUM(Profit),2) AS Profit
FROM Orders
GROUP BY 1;

WITH MAX_PROFIT AS
(
SELECT Region, ROUND(SUM(Profit),2) AS Profit,
	RANK() OVER(ORDER BY ROUND(SUM(Profit),2) DESC) AS RNK
FROM Orders
GROUP BY 1
)
SELECT REGION
FROM MAX_PROFIT
WHERE RNK = 1;

-- 6) Which month observe the highest number of orders placed and return placed for each year?

-- Most orders

WITH max_order AS
(
SELECT YEAR(`ORDER DATE`) AS ORDER_YEAR, MONTH(`ORDER DATE`) AS ORDER_MONTH, COUNT(`ORDER DATE`) AS ORDER_PLACED
FROM Orders
GROUP BY 1,2
ORDER BY 1
)
SELECT ORDER_YEAR, ORDER_MONTH, ORDER_PLACED
FROM
(
SELECT ORDER_YEAR, ORDER_MONTH, ORDER_PLACED,
	RANK() OVER(ORDER BY ORDER_PLACED) AS MAX_ORDER_OF_THE_YEAR
FROM max_order
)T4
WHERE MAX_ORDER_OF_THE_YEAR = 1;


-- 6.B) Which month observe the highest number of orders return placed for each year ?

WITH return_order AS
(
SELECT distinct `ORDER ID`, YEAR(`ORDER DATE`) AS RETURN_YEAR, MONTH(`ORDER DATE`) AS RETURN_MONTH
FROM Orders AS ord
INNER JOIN returns AS ret
ON ord.`ORDER ID` = ret.OrderID
ORDER BY 2 ASC, 3 ASC
)
SELECT RETURN_MONTH, RETURN_YEAR, RETURN_ORDER_PER_MONTH AS MAX_RETURN_ORDER
FROM
(
SELECT RETURN_MONTH, RETURN_YEAR, COUNT(RETURN_MONTH) AS RETURN_ORDER_PER_MONTH,
	RANK() OVER(ORDER BY COUNT(RETURN_MONTH) DESC) AS RNK
FROM return_order
GROUP BY 1,2
) T3
WHERE RNK = 1;


-- Calculate percentage change in sales for the entire dataset? X axis should be year_month Y axis percent change
-- Find out if any sales pattern exists for all the region?

WITH pct_change AS
(
SELECT YEAR(`Order Date`) * 100 + MONTH(`Order Date`) as YearMonth, YEAR(`Order Date`) AS 'YEAR', Region, ROUND(SUM(Sales), 2) AS sales,
	LEAD(ROUND(SUM(Sales), 2)) OVER(ORDER BY ROUND(SUM(Sales), 2)) AS LED
FROM orders
GROUP BY 1,2,3
ORDER BY 3,1)

SELECT YearMonth, region, sales , Round(((LEAD(Sales) OVER(ORDER BY region) - sales)/ sales) * 100, 2) AS PercentageChange
FROM pct_change;

-- Top and bottom selling product for each region

SELECT Region, `Product Name`, ProductSales AS Top_selling_product
FROM (
SELECT Region, `Product Name`, COUNT(`Product Name`) AS ProductSales,
	RANK() OVER(PARTITION BY Region ORDER BY COUNT(`Product Name`) DESC) AS RNK
FROM orders
GROUP BY 1,2
) T5
WHERE RNK = 1;

SELECT Region, `Product Name`, ProductSales AS less_selling_product
FROM (
SELECT Region, `Product Name`, COUNT(`Product Name`) AS ProductSales,
	RANK() OVER(PARTITION BY Region ORDER BY COUNT(`Product Name`) ASC) AS RNK
FROM orders
GROUP BY 1,2
) T5
WHERE RNK = 1
ORDER BY 2;

-- Why are returns initiated? Are there any specific characteristics for all the returns? 
-- Hint: Find return across all categories to observe any pattern

WITH returned_order AS(
SELECT distinct `Order ID` as Returned_Order, Region, Category
FROM orders AS ord
INNER JOIN returns AS ret
ON ord.`Order ID` = ret.OrderID)

SELECT CATEGORY, COUNT(CATEGORY)
FROM returned_order
GROUP BY 1
ORDER BY 2 DESC;

-- Create a table having two columns ( date and sales),
 -- Date should start with the min date of data and end at max date - in between we need all the dates 
 -- If date is available show sales for that date else show date and NA as sales
 
with date_calendar as
(
select * from 
(select adddate('1970-01-01',t4*10000 + t3*1000 + t2*100 + t1*10 + t0) gen_date from
 (select 0 t0 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t0,
 (select 0 t1 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t1,
 (select 0 t2 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t2,
 (select 0 t3 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t3,
 (select 0 t4 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t4) v
where gen_date between '2014-01-03' and '2017-12-30'
order by gen_date asc )
, common_date as
(
select distinct dc.gen_date as gen_date, date(ord.`Order Date`) as orderdate
from date_calendar as dc
left join orders as ord
on dc.gen_date = date(ord.`Order Date`)
), sales_date AS
(
select distinct cd.gen_date AS G_DATE, cd.orderdate as order_date, round(sum(ord.Sales), 2) as sum_of_sales
from common_date as cd
left join orders as ord
on cd.gen_date = ord.`Order date`
group by 1,2
order by 1
)
SELECT G_DATE, IF(sum_of_sales is not null, sum_of_sales, "NA") as sales
FROM sales_date;
 


