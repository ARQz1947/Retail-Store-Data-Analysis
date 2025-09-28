--Don't use Canada

---------- Top 3 months with most profits per year ----------------------

With MonthlyProfitRank AS(
	SELECT YEAR(Order_Date) Order_Year, MONTH(Order_Date) Order_Month, 
		CAST((SUM(Profit_Discounted))AS DECIMAL (10,2)) Total_Profit,
		RANK() OVER (PARTITION BY YEAR(order_Date) ORDER BY SUM(Profit_Discounted) DESC) Profit_Rank
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY YEAR(Order_Date), MONTH(Order_Date)
)

SELECT Order_Year, Order_Month, Total_Profit, Profit_Rank
FROM MonthlyProfitRank
WHERE Profit_Rank <= 3
ORDER BY Order_Year, Profit_Rank

---------------- Top 3 months with most sales per year ------------------------

With MonthlySalesRank AS(

	SELECT YEAR(Order_Date) Order_Year, MONTH(Order_Date) Order_Month, 
		CAST((SUM(Sales_Discounted))AS DECIMAL (10,2)) Total_Sales,
		RANK() OVER (PARTITION BY YEAR(Order_Date) ORDER BY SUM(Sales_Discounted) DESC) Sales_Rank
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY YEAR(Order_Date), MONTH(Order_Date)
)

SELECT Order_Year, Order_Month, Total_Sales, Sales_Rank
FROM MonthlySalesRank
WHERE Sales_Rank <= 3
ORDER BY Order_Year, Sales_Rank

--------------- Top 3 months with most orders & discounted orders per year  ------------------------

With MonthlyOrderRank AS(
	SELECT YEAR(Order_Date) Order_Year, MONTH(Order_Date) Order_Month, 
		COUNT(Order_ID) Total_Orders,
		SUM(CASE WHEN Discount_rate > 0 THEN 1 END) Discounted_Orders,
		RANK() OVER (PARTITION BY YEAR(Order_Date) ORDER BY COUNT(Order_Id) DESC) Order_Rank
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY YEAR(Order_Date), MONTH(Order_Date)
)

SELECT Order_Year, Order_Month, Total_Orders, Order_Rank, Discounted_Orders,
	RANK() OVER (Order by Discounted_Orders DESC) Discounted_Order_Rank
FROM MonthlyOrderRank
WHERE Order_Rank <= 3
ORDER BY Order_Year, Order_Rank

------------- Region ranks with profits per year  ----------

SELECT YEAR(Order_Date) Order_Year, Region, 
	CAST(SUM(Profit_Discounted) AS DECIMAL(10,2)) Total_Profit,
	RANK () OVER (PARTITION BY YEAR(Order_Date) ORDER BY SUM(Profit_Discounted) DESC) Profit_Rank
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY YEAR(Order_Date), Region
ORDER BY Order_Year, Profit_Rank ASC

--------------- Average order value(AOV) ranks per year -------------------

WITH OrderValue AS (
	SELECT YEAR(Order_Date) Order_Year, Order_ID, 
		CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Order_Value	
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Order_ID, YEAR(Order_Date)
)

SELECT Order_Year, 
	CAST(AVG(Order_Value) AS DECIMAL(10,2)) Avg_Order_Value,
	RANK () OVER (ORDER BY AVG(Order_Value) DESC) AOV_Rank
FROM OrderValue
GROUP BY Order_Year
ORDER BY AOV_Rank

