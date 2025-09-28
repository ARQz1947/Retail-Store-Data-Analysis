--Don't use Canada

------------ Unique orders per year -------------------

SELECT YEAR(Order_Date) Order_Year, Region, 
	COUNT(DISTINCT Order_ID) Total_Orders
INTO #UniqueOrders
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY YEAR(Order_Date), Region

SELECT *
FROM #UniqueOrders
ORDER BY Order_Year, Total_Orders DESC

---------- Regions rank w.r.t total orders per year -------------------

SELECT YEAR(Order_Date) Order_Year, Region, COUNT(DISTINCT Order_Id) Total_Orders,
		RANK () OVER (PARTITION BY YEAR(Order_Date) ORDER BY COUNT(DISTINCT Order_Id) DESC) Orders_Rank 
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY YEAR(Order_Date), Region 
ORDER BY Order_Year, Orders_Rank

------ Total orders with and wihtout discounts per region each year ------

WITH OrderDiscountStatus AS (
    SELECT 
        Order_ID, Year(Order_Date) Order_Year, Region,
        MAX(CASE WHEN Discount_Rate > 0 THEN 1 ELSE 0 END) Is_Discounted --orders with discount are being flagged as 1 and non-discounted are flagged as 0
    FROM RetailStore
    WHERE Country_Region = 'United States' --to only include USA orders
    GROUP BY Order_ID, Year(Order_Date), Region
)

SELECT Order_Year, COUNT(Is_Discounted) Total_Orders, Region, Is_Discounted 
FROM OrderDiscountStatus
GROUP BY Is_Discounted, Order_Year, Region
ORDER BY Order_Year, Total_Orders DESC

------------- Yearly avg. order value (AOV) per region - Rank --------------------

WITH OrderValue AS(
	SELECT YEAR(Order_Date) Order_Year, Region, State_Province, Order_ID, 
			CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Order_Value	
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Order_ID, YEAR(Order_Date), State_Province, Region
)

SELECT Order_Year, Region, CAST(AVG(Order_Value) AS DECIMAL(10,2)) Avg_Order_Value,
		RANK () OVER (PARTITION BY Order_Year ORDER BY AVG(Order_Value) DESC) AOV_Rank
FROM OrderValue
GROUP BY Order_Year, Region
ORDER BY Order_Year, Region

--------------- Top 3 months with most orders & discounted orders per year ------------------------

With MonthlyOrderRank AS(

	SELECT YEAR(Order_Date) Order_Year, MONTH(Order_Date) Order_Month, 
			COUNT(Order_ID) Total_Orders,
			SUM(CASE WHEN Discount_rate > 0 THEN 1 END) Discounted_Orders,
			RANK() OVER (PARTITION BY YEAR(Order_Date) ORDER BY COUNT(Order_Id) DESC) Order_Rank
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY YEAR(Order_Date), MONTH(Order_Date)
)

SELECT Order_Year, Order_Month, Total_Orders, Order_Rank, Discounted_Orders
FROM MonthlyOrderRank
WHERE Order_Rank <= 3
ORDER BY Order_Year, Order_Rank