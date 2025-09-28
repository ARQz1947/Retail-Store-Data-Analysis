--Don't use Canada

----------- Profit growth rate ------------------

WITH TotalProfit AS (
	SELECT 
		YEAR(Order_Date) AS Order_Year,
		CAST(SUM(Profit_Discounted) AS DECIMAL(10,2)) Total_Profit
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY YEAR(Order_Date)
)

SELECT 
	curr.Order_Year,
	curr.Total_Profit,
	CASE 
		WHEN prev.Total_Profit IS NULL THEN NULL
		WHEN prev.Total_Profit = 0 THEN 100  --growth rate will be 100% when there are no products sold in the previous year
		ELSE CAST(((curr.Total_Profit - prev.Total_Profit) / prev.Total_Profit) * 100 AS DECIMAL(10,2)) --profit growth rate formula
	END AS Profit_Growth_Rate_Percent
FROM TotalProfit curr
LEFT JOIN TotalProfit prev
	ON curr.Order_Year = prev.Order_Year + 1 --to compare current year with actual previous year
ORDER BY curr.Order_Year

---------- Monthly profits -------------------

SELECT YEAR(Order_Date) Order_Year, MONTH(Order_Date) Order_Month,
		CAST(SUM(Profit_Discounted) AS DECIMAL(10,2)) Total_Profit
INTO #MonthlyProfits --storing data in temp table
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY YEAR(Order_Date), MONTH(Order_Date)

SELECT * 
FROM #MonthlyProfits 
ORDER BY Order_Year, Total_Profit DESC

-------- Monthly profits compared to discounted orders count ------

SELECT Year(Order_Date) Order_Year, Month(Order_date) Order_Month,
	CASE 
      WHEN Discount_rate > 0 THEN 'Discount'
	  ELSE 'No Discount'
     END Discount, --count of orders with and without discounts
	 COUNT(Order_id) Total_Orders,
	 SUM(Profit_Discounted) Total_Profit
INTO #TotalDiscountedOrders --storing data in temp table
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Month(Order_Date), Year(Order_Date),
	CASE 
      WHEN Discount_rate > 0 THEN 'Discount'
	  ELSE 'No Discount'
     END
ORDER BY Order_Year ASC, Total_Profit DESC

SELECT mp.Order_Year, mp.Order_Month, 
	mp.Total_Profit, Total_Orders, Discount 
FROM #MonthlyProfits mp
INNER JOIN #TotalDiscountedOrders tdo ON mp.Order_Month = tdo.Order_Month 
	AND mp.Order_Year = tdo.Order_Year
ORDER BY mp.Order_Year ASC, mp.Total_Profit DESC

---------------- Profit share across regions ----------------------

SELECT Region,
		CAST(SUM(Profit_Discounted) AS DECIMAL(10,2)) Total_Profit,
		CAST(
				(
					CAST(SUM(Profit_Discounted) AS DECIMAL(10,2)) / --numerator is regional profits
						CAST((SELECT SUM(Profit_Discounted) FROM RetailStore WHERE Country_Region = 'United States') AS DECIMAL(10,2)) * 100 --denominator is overall profit of USA
				)
				AS DECIMAL(10,2)
			) Profit_Share
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Region
ORDER BY Total_Profit DESC

---------- Quarterly profits per region per year ------------------------

SELECT YEAR(Order_Date) Order_Year, 
	DATEPART(Quarter, Order_Date) 'Quarter', Region,
	CAST(SUM(Profit_Discounted) AS DECIMAL(10,2)) Total_Profits		 
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Region, YEAR(Order_Date), DATEPART(Quarter, Order_Date)
ORDER BY Order_Year, 'Quarter', Total_Profits

---------------- Profit across sub-categories ----------------------

SELECT Sub_Category,
		CAST(SUM(Profit_Discounted) AS DECIMAL(10,2)) Total_Profits
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Sub_Category
ORDER BY Total_Profits DESC

---------------- Top 5 sub-categories by yearly sales & profits ------------------

WITH RankingSubCats AS(
	SELECT 	YEAR(Order_Date) Order_Year, 
			Category, Sub_Category,
			CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Total_Sales,
			RANK() OVER (PARTITION BY YEAR(Order_Date) ORDER BY SUM(Sales_Discounted) DESC ) Sales_Rank,
			CAST(SUM(Profit_Discounted) AS DECIMAL(15,2)) Total_Profits,
			RANK() OVER (PARTITION BY YEAR(Order_Date) ORDER BY SUM(Profit_Discounted) DESC ) Profit_Rank
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders                 
	GROUP BY Category, Sub_Category, YEAR(Order_Date)

)

SELECT *
FROM RankingSubCats
WHERE Sales_Rank <= 5
ORDER BY Order_Year, Sales_Rank 

------------------- Average profit for discounted and non-discounted orders -----------------------------

SELECT 
    CASE 
        WHEN Discount_rate = 0 THEN 'No Discount'
        ELSE 'Discounted'
    END Discount_Type,
    CAST((AVG(Profit_Discounted)) AS DECIMAL(10,2)) Avg_Profit,
    COUNT(DISTINCT Order_ID) AS Order_Count
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY 
    CASE 
        WHEN Discount_rate = 0 THEN 'No Discount'
        ELSE 'Discounted'
    END
