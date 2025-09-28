--Don't use Canada

----------- Annual sales by year ----------------

WITH TotalSales AS(
	SELECT YEAR(Order_Date) Order_Year,
		CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Total_Sales
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY YEAR(Order_Date)
)

SELECT *
FROM TotalSales ORDER BY Total_Sales DESC

------- Top 5 sub-categories by sales -----------

SELECT Top 5 Category, Sub_Category, 
	CAST(SUM(Sales_Discounted)AS DECIMAL(10,2)) Total_Sales, 
	COUNT(Order_ID) Total_Orders
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Sub_Category, Category
ORDER BY Total_Sales DESC;

------- Bottom 5 Sub-Categories by Sales -----------

WITH BottomSales AS (
	SELECT Category, Sub_Category, 
		CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Total_Sales, 
		COUNT(Order_ID) Total_Orders
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Sub_Category, Category
)

SELECT TOP 5 Category, Sub_Category, Total_Orders, Total_sales
FROM BottomSales
ORDER BY Total_Sales ASC;

------------ Sales & profit ranks -------------------------

SELECT Category, Sub_Category,
	COUNT(DISTINCT Order_ID) Total_Orders,
	CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Total_Sales, -- CAST with 2 decimal places to limit decimal points in data 
	SUM(Profit_Discounted) Total_Profits, 
	DENSE_RANK () OVER (ORDER BY SUM(Sales_Discounted) DESC) Sales_Rank, -- Dense rank, to never skip next rank in the row 
	DENSE_RANK () OVER (ORDER BY SUM(profit_discounted) DESC) Profit_Rank,
	DENSE_RANK () OVER (ORDER BY COUNT(Order_Id) DESC) Order_Rank
INTO #SubCategory_Rank --using temp table to store results
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Sub_Category, Category

SELECT * FROM #SubCategory_Rank
ORDER BY Sales_Rank

---------- Sales by region and year -------------------

SELECT Region, YEAR(Order_Date) Order_Year,
	CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Total_Sales
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Region, YEAR(Order_Date)
ORDER BY Total_Sales DESC, Order_Year ASC

---------- Sales per year -------------------

SELECT YEAR(Order_Date) Order_Year, 
	CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Total_Sales
FROM RetailStore
GROUP BY YEAR(order_date)
ORDER BY Order_Year desc

---------- Sales per month -------

SELECT YEAR(Order_Date) Order_Year, 
	MONTH(Order_Date) Order_Month,
	CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Total_Sales
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY YEAR(Order_Date), MONTH(Order_Date)
ORDER BY Order_Year, Total_Sales desc

------------------ Sales by region ----------------------

WITH TotalSales AS(
	SELECT CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Total_Sales
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders

)

SELECT Region, 
	CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Sales,
	CASE --To calculate sales percentage for each region
		WHEN Region = 'West' THEN (SUM(Sales_Discounted)/Total_Sales)*100 -- Formula to calculate sales percentage
		WHEN Region = 'East' THEN (SUM(Sales_Discounted)/Total_Sales)*100
		WHEN Region = 'Central' THEN (SUM(Sales_Discounted)/Total_Sales)*100
		WHEN Region = 'South' THEN (SUM(Sales_Discounted)/Total_Sales)*100
	END 'Sales(%)'
FROM RetailStore, TotalSales --data table and CTE
WHERE Country_Region = 'United States' --to only include USA orders, adding filter here as well because we are refering to original data source
GROUP BY Region
ORDER BY Sales DESC

------------ Sales contribution(%) by region ------------------

WITH RegionalSales AS(
	SELECT Region,
		CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Regional_Sales
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Region

)

SELECT regs.Region, Regional_Sales,
		
		CASE -- Dividing each region sales by total sales (available in the data)
			WHEN regs.Region = 'West' THEN CAST(((Regional_Sales/SUM(Sales_Discounted))*100) AS DECIMAL(10,2))
			WHEN regs.Region = 'East' THEN CAST(((Regional_Sales/SUM(Sales_Discounted))*100) AS DECIMAL(10,2))
			WHEN regs.Region = 'Central' THEN CAST(((Regional_Sales/SUM(Sales_Discounted))*100) AS DECIMAL(10,2))
			WHEN regs.Region = 'South' THEN CAST(((Regional_Sales/SUM(Sales_Discounted))*100) AS DECIMAL(10,2))
		END 'Sales(%)'
FROM RetailStore rs, RegionalSales regs
WHERE Country_Region = 'United States' --to only include USA orders, adding filter here as well because we are refering to original data source
GROUP BY regs.Region, Regional_Sales
ORDER BY 'Sales(%)' DESC
