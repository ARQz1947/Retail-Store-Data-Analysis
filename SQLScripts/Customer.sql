--Don't use Canada

------------ Total new customers (Each Year) ----------------------
-- CTE covers the issue when a customer has one order in a year and second order in another year --------------------

WITH CustomerFirstOrder AS (
	SELECT Customer_ID, MIN(Order_Date) Order_Date
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Customer_ID

),

NewCustomers AS (
	SELECT COUNT(Customer_ID) New_Customers, YEAR(Order_Date) Order_Year
	FROM CustomerFirstOrder
	GROUP BY YEAR(Order_Date)

)

SELECT nc1.Order_Year, nc1.New_Customers,
	--growth formula: ((new customers count(this year) - new customer count(previous year)) / new customer count(previous year)) * 100
	CASE 
		WHEN nc1.New_Customers <> 0 THEN 
		CAST(
				(
					(
						(CAST((nc1.New_Customers) AS DECIMAL(10,2)) - CAST((nc2.New_Customers) AS DECIMAL(10,2))) / CAST((nc2.New_Customers)As DECIMAL(10,2))
					) * 100
				) AS DECIMAL(10,2)
			)
	END New_Customer_Growth
FROM NewCustomers nc1 
LEFT JOIN NewCustomers nc2 ON nc1.Order_Year = nc2.Order_Year+1 --adding one year(+1) to compare current year with previous year 
ORDER BY nc1.Order_Year ASC;

----------------- Repeating customers per year --------------------
-- All customers who purchased more than once in a year --------------------
-- Not including customers who did their second purchase 
-- other than the year they purchase for the first time----------------

WITH CustomerOrders AS(
	SELECT MIN(Order_Date) First_Order, MAX(Order_Date) Last_Order, Customer_ID
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Customer_ID

), --first & last order of each customer

RepeatingCustomers AS (
	SELECT COUNT(Customer_ID) Repeating_Customers, YEAR(First_Order) Order_Year
	FROM CustomerOrders
	WHERE First_Order <> Last_Order --removing customers with only one order per year 
	GROUP BY YEAR(First_Order)

)

SELECT rc1.Order_Year, rc1.Repeating_Customers,
	CASE --growth formula: ((repeat customers count(this year) - repeat customer count(previous year)) / repeat customer count(previous year)) * 100
		WHEN rc1.Repeating_Customers <> 0 THEN 
		CAST(
				(
					(
						(CAST((rc1.Repeating_Customers)AS DECIMAL(10,2)) - CAST((rc2.Repeating_Customers)AS DECIMAL(10,2))) / CAST((rc2.Repeating_Customers)As DECIMAL(10,2))
					) * 100
				) AS DECIMAL(10,2)
			)
	END Repeating_Customer_Growth
FROM RepeatingCustomers rc1
LEFT JOIN RepeatingCustomers rc2 ON rc1.Order_Year = rc2.Order_Year+1 --adding one year(+1) to compare current year with previous year
ORDER BY rc1.Order_Year

-------------------- Customer with most sales per year --------------------

WITH TopCustomers AS(
	SELECT Customer_ID, Customer_Name, 
		COUNT(DISTINCT Order_ID) Total_Orders, 
		SUM(Sales_Discounted) Total_Sales,
		RANK() OVER (PARTITION BY YEAR(Order_date) ORDER BY SUM(Sales_Discounted) DESC) Sales_Rank,
		YEAR(Order_date) Order_Year
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Customer_ID, Customer_Name, YEAR(Order_date)
)

SELECT Order_Year, Customer_ID, Customer_Name, Total_Sales
FROM TopCustomers
WHERE Sales_Rank < 2
