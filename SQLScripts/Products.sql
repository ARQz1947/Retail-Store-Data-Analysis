--Don't use Canada

----- New products per category in each year -----

WITH Product_Year AS(
	SELECT Category, Product_Name 
		,YEAR(MIN(Order_Date)) Product_Year --first order of a product
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	Group by Category, Product_Name
),

Yearly_New_Products AS(

	SELECT Category, Product_Year, COUNT(*) New_Products
	FROM Product_Year
	GROUP BY Category, Product_Year
) --count of new products for each category per year

SELECT Category, Product_Year, New_Products
	,CAST(
			(
				(CAST(New_Products AS DECIMAL(7,2)) / 
					CAST(SUM(New_Products) OVER(PARTITION BY Category) AS DECIMAL(7,2)) --total products per category, using SUM to add new product count per year 
				) * 100
			) AS DECIMAL (7,2)
		  ) 'New_Products(%)' --percentage of total products per catergy per year
FROM Yearly_New_Products
ORDER BY Category, Product_Year

------- Products sales & sost per category --------------

SELECT Category, Product_Name 
	,Cost_Per_Item_derived
	,SUM(Sales_Discounted) Total_Sales
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Category, Product_Name, Cost_Per_Item_derived
ORDER BY Category, Cost_Per_Item_derived

-------------- Differnece of each product cost from 
-------------- max. product cost per category ------------------

WITH Product_Sales AS (
    SELECT 
        Category
        ,Product_Name
        ,CAST((AVG(Cost_Per_Item_derived)) AS DECIMAL(10,2)) Product_Avg_Cost
    FROM RetailStore
    WHERE Country_Region = 'United States' --to only include USA orders
    GROUP BY Category, Product_Name
)
SELECT 
    Category
    ,Product_Name
    ,Product_Avg_Cost
    ,CAST(
			AVG(Product_Avg_Cost) OVER (PARTITION BY Category)	-- Getting average of product average cost per category (values will be same for a category) 
			AS DECIMAL(10,2)
		) Avg_Product_Cost_per_Category			
    ,MAX(Product_Avg_Cost) OVER (PARTITION BY Category) AS Max_Product_Cost_per_Category -- Getting max of product average cost per category (values will be same for a category)
    ,Product_Avg_Cost - MAX(Product_Avg_Cost) OVER (PARTITION BY Category) AS Diff_From_Max -- Getting how far the product value lies from the max product average cost within a category
FROM Product_Sales
ORDER BY Category, Product_Avg_Cost;

----------- Products per category -------

SELECT Category 
	,COUNT(Distinct Product_Name) Total_Products
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Category
ORDER BY Total_Products DESC

---------- Sales & profits --------------

WITH Category_Sales AS (
	SELECT Category
		,CAST(SUM(Sales_Discounted) AS DECIMAL (10,2)) Sales
		,CAST((SUM(SUM(Sales_Discounted)) OVER ()) AS DECIMAL (15,2)) Total_Sales --total sales in the data set
		,CAST(SUM(Profit_Discounted) AS DECIMAL (15,2)) Profit
		,CAST((SUM(SUM(Profit_Discounted)) OVER ()) AS DECIMAL (15,2)) Total_Profit --total profits in the data set
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Category
)

SELECT Category 
	,CAST(((Sales/Total_Sales)*100) AS DECIMAL(10,2)) Sales_Contribution
	,CAST(((Profit/Total_Profit)*100) AS DECIMAL(10,2)) Profit_Contribution
FROM Category_Sales;

------- Orders, quantities & discounts --------
 
SELECT Category
	,COUNT(Order_ID) Total_Orders
	,SUM(Quantity) Total_Quantity
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Category
ORDER BY Category

--------- Sales share by product in each category --------------

SELECT Category, Product_Name 
		,CAST((Max(Order_Date)) AS Date) Last_Order
		,CASE --when first and last order for a product is in the same month then months active will be 1 else we'll have the number of months
			WHEN DATEDIFF (MONTH, MIN(Order_Date), MAX(Order_date)) = 0
			THEN 1
			ELSE DATEDIFF (MONTH, MIN(Order_Date), MAX(Order_date))
		END Months_Active --for how many months the product received orders
		,CASE 
			WHEN DATEDIFF (MONTH, MIN(Order_Date), (SELECT MAX (Order_Date) FROM RetailStore)) = 0 --(SELECT MAX (Order_Date) FROM RetailStore) gets date of latest order in the business
			THEN 1															
			ELSE DATEDIFF (MONTH, MIN(Order_Date), (SELECT MAX (Order_Date) FROM RetailStore))
		END Age_Months --how old is the product from its first order till the latest order of the business
		,CASE 
			WHEN DATEDIFF (MONTH, MIN(order_Date), (SELECT MAX (Order_Date) FROM RetailStore)) <= 12 
			THEN 'New' 
			ELSE 'Old' 
		END Product_Age --product age indicator depending upon a specific threshold count of months since it's first order 
		,SUM(Sales_Discounted) Product_Sales
		,SUM(SUM(Sales_Discounted)) OVER (PARTITION BY Category) Category_Sales --total sales per category
INTO #Prod_Sales
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Category, Product_Name

SELECT Category, Product_Name, Last_Order, Months_Active, Product_Age
	,CAST((Product_Sales/Category_Sales) AS DECIMAL (10,5)) 'Sales_Share(%)' --CASTing to 5 decimal places because some sales share are very small
FROM #Prod_Sales					
ORDER BY Category, 'Sales_Share(%)' DESC

------ Profits share by product in each category --------------

WITH Product_Share AS (
	SELECT Category, Product_Name 
		,CAST((Max(Order_Date)) AS Date) Last_Order
		,CASE --when first and last order for a product is in the same month then months active will be 1 else we'll have the number of months
			WHEN DATEDIFF (MONTH, MIN(Order_Date), MAX(Order_date)) = 0 
			THEN 1
			ELSE DATEDIFF (MONTH, MIN(Order_Date), MAX(Order_date))
		END Months_Active --for how many months the product received orders
		,CASE 
			WHEN DATEDIFF (MONTH, MIN(Order_Date), (SELECT MAX (Order_Date) FROM RetailStore)) <=12 --(SELECT MAX (Order_Date) FROM RetailStore) gets date of latest order in the business
			THEN 'New' 
			ELSE 'Old' 
		END Product_Age --product age indicator depending upon a specific threshold count of months since it's first order
		,SUM(Profit_Discounted) Product_Profits
		,SUM(SUM(Profit_Discounted)) OVER (PARTITION BY Category) Category_Profits --total profits per category
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Category, Product_Name
)

SELECT Category, Product_Name, Last_Order, Months_Active, Product_Age
	,CAST((Product_Profits/Category_Profits) AS DECIMAL (10,5)) Profits_Share --CASTing to 5 decimal places because some sales share are very small
FROM Product_Share
ORDER BY Category, Profits_Share DESC

----- Product Lifecycle (Sales) --------------

	---- YoY growth

WITH TotalSales AS (
	
	SELECT 
		YEAR(Order_Date) Order_Year
		,Product_Name
		,CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Total_Sales
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY YEAR(Order_Date), Product_Name
),

Product_Growth AS(
	SELECT 
		curr.Order_Year AS Order_Year
		,curr.Product_Name
		,curr.Total_Sales AS Current_Year_Sales
		,prev.Total_Sales AS Previous_Year_Sales
		,CASE 
			WHEN prev.Total_Sales IS NULL THEN NULL --to prevent division by 0
			ELSE CAST(((curr.Total_Sales - prev.Total_Sales) / prev.Total_Sales) AS DECIMAL(10,2) ) --sales growth rate formula: (current year sales - previous year sales)/previous year sales
		END YoY_Sales_Growth
	FROM TotalSales curr
	LEFT JOIN TotalSales prev
		ON curr.Product_Name = prev.Product_Name 
			AND curr.Order_Year = prev.Order_Year + 1 --to compare current year with actual previous year
)

SELECT pg.Order_Year, rs.Category, rs.Product_Name
		,CAST((MIN(rs.Order_Date)) AS Date) First_Order --CASTing to exclude time part of the date
		,CAST((MAX(rs.Order_Date)) AS Date) Last_Order --CASTing to exclude time part of the date
		,CASE --when first and last order for a product is in the same month then months active will be 1 else we'll have the number of months
			WHEN DATEDIFF (MONTH, MIN(Order_Date), MAX(Order_date)) = 0 
			THEN 1
			ELSE DATEDIFF (MONTH, MIN(Order_Date), MAX(Order_date))
		END Months_Active --for how many months the product received orders
		,CASE 
			WHEN DATEDIFF (MONTH, MIN(Order_Date), (SELECT MAX (Order_Date) FROM RetailStore)) = 0 --(SELECT MAX (Order_Date) FROM RetailStore) gets date of latest order in the business
			THEN 1															
			ELSE DATEDIFF (MONTH, MIN(Order_Date), (SELECT MAX (Order_Date) FROM RetailStore))
		END Age_Months --how old is the product from its first order till the latest order of the business
		,CASE 
			WHEN DATEDIFF (MONTH, MIN(Order_Date), (SELECT MAX (Order_Date) FROM RetailStore)) <=12 --(SELECT MAX (Order_Date) FROM RetailStore) gets date of latest order in the business
			THEN 'New' 
			ELSE 'Old' 
		END Product_Age --product age indicator depending upon a specific threshold count of months since it's first order
		,pg.Current_Year_Sales
		,pg.Previous_Year_Sales
		,pg.YoY_Sales_Growth
INTO #YoY_Growth --storing data in temp table
FROM RetailStore rs
INNER JOIN Product_Growth pg ON rs.Product_Name = pg.Product_Name
WHERE pg.Order_Year = 2024
GROUP BY pg.Order_Year, rs.Category, rs.Product_Name, pg.Current_Year_Sales, pg.Previous_Year_Sales, pg.YoY_Sales_Growth
--ORDER BY Product_Name DESC

	---- Sales share for new products

SELECT Category, Product_Name, Last_Order, Months_Active, Age_Months, Product_Age
	,CAST((Product_Sales/Category_Sales) AS DECIMAL (15,5)) Sales_Share --CASTing to 5 decimal places because some sales share are very small
INTO #Sales_Share --storing data in temp table
FROM #Prod_Sales;
--ORDER BY Category, Sales_Share DESC

	------- Combined collection from YoY and Sales Share 'Product lifecucle stage'

WITH YoY_SalesShare AS (
	SELECT ss.Category
		,ss.Product_Name
		,ss.Months_Active
		,ss.Age_Months
		,ss.Product_Age
		,Sales_Share AS Total_Sales_Share
		,yg.Current_Year_Sales
		,yg.Previous_Year_Sales
		,YoY_Sales_Growth						 
	FROM #Sales_Share ss
	LEFT JOIN #YoY_Growth yg ON ss.Product_Name = yg.Product_Name
)

SELECT *
	,CASE --categorizing each product per business rules
		WHEN Age_Months <= 12 THEN 'Introduction'
		WHEN Age_Months > 12 AND YoY_Sales_Growth > 0.2 THEN 'Growth'
		WHEN Age_Months > 24 AND Previous_Year_Sales IS NULL AND Current_Year_Sales > 0 THEN 'Reactivated'
		WHEN Age_Months > 24 AND Previous_Year_Sales IS NULL AND Current_Year_Sales IS NULL THEN 'Discontinued'
		WHEN Age_Months > 24 AND YoY_Sales_Growth BETWEEN -0.05 AND 0.05 THEN 'Maturity'
		WHEN Age_Months > 24 AND YoY_Sales_Growth < -0.05 THEN 'Decline'
		ELSE 'Unclassified'		
	END Product_Lifecycle_Stage
FROM YoY_SalesShare
ORDER BY Category, Product_Name

------------- New & Old Products ---------------

WITH Prod_Age AS(
	SELECT Category, Product_Name
		,CASE 
			WHEN DATEDIFF (MONTH, MIN(Order_Date), (SELECT MAX (Order_Date) FROM RetailStore)) <=12 --(SELECT MAX (Order_Date) FROM RetailStore) gets date of latest order in the business
			THEN 'New' 
			ELSE 'Old' 
		END Product_Age --product age indicator depending upon a specific threshold count of months since it's first order
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Category, Product_Name
)

SELECT Category, Product_Age, COUNT(Product_Age) Total_Products
FROM Prod_Age
GROUP BY Category, Product_Age
ORDER BY Category, Total_Products

----------------Total orders per product ------------------
 
SELECT YEAR(Order_Date) Order_Year, Product_Name 
	,COUNT(DISTINCT Order_ID) Total_Orders
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY YEAR(Order_Date), Product_Name
ORDER BY Product_Name, Total_Orders DESC, Order_Year

---------- Product Summary --------------

SELECT Category, Product_Name
	,CASE 
		WHEN DATEDIFF (MONTH, MIN(Order_Date), (SELECT MAX (Order_Date) FROM RetailStore)) <=12 --(SELECT MAX (Order_Date) FROM RetailStore) gets date of latest order in the business
		THEN 'New' 
		ELSE 'Old' 
	END Product_Age --product age indicator depending upon a specific threshold count of months since it's first order
	,CASE --when first and last order for a product is in the same month then months active will be 1 else we'll have the number of months
		WHEN DATEDIFF (MONTH, MIN(Order_Date), MAX(Order_date)) = 0 
		THEN 1
		ELSE DATEDIFF (MONTH, MIN(Order_Date), MAX(Order_date))
	END Months_Active --for how many months the product received orders
	,SUM(Profit_Discounted) Total_Profit 
	,SUM(Sales_Discounted) Total_Sales
	,SUM(Quantity) Total_Quantity
	,COUNT(DISTINCT Order_Id) Total_Orders
	,RANK() OVER (ORDER BY SUM(DISTINCT Sales_Discounted) DESC) Sales_Rank
	,RANK() OVER (ORDER BY SUM(DISTINCT Profit_Discounted) DESC) Profit_Rank
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Category, Product_Name
ORDER BY Sales_Rank

---- Product with recent first orders ----

SELECT Product_Name
	,CAST((MIN(Order_Date)) AS Date) First_Order 
	,DATEDIFF(MM, MIN(Order_Date), (SELECT MAX(Order_Date) FROM RetailStore)) Month_Since_First_Order
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Product_Name
HAVING DATEDIFF(MM, MIN(Order_Date), 
						(SELECT MAX(Order_Date) FROM RetailStore)) <= 12 --products which have first order within 12 months of the last order of the business

---- New products per year ----

WITH ProductOrders AS (
	SELECT Product_Name
		 ,YEAR(MIN(Order_Date)) First_Order_Year
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Product_Name
)

SELECT First_Order_Year, COUNT(DISTINCT Product_Name) Total_Orders
FROM ProductOrders
GROUP BY First_Order_Year
Order by First_Order_Year

----------- Products appearing in pair ----------------

SELECT YEAR(p1.Order_Date) Order_Year
    ,p1.Product_Name Product_1
    ,p2.Product_Name Product_2
    ,COUNT(DISTINCT p1.Order_ID) Pair_Count
FROM RetailStore p1
JOIN RetailStore p2 
    ON p1.Order_ID = p2.Order_ID
   AND p1.Product_Name < p2.Product_Name --avoid duplicates like (product01, product02) and (product02, product01)
WHERE p1.Country_Region = 'United States' --to only include USA orders
GROUP BY YEAR(p1.Order_Date), p1.Product_Name, p2.Product_Name
HAVING COUNT(DISTINCT p1.Order_ID) > 1 -- products pair which appear more than once together in an order
ORDER BY Product_1

-------------- Top 5 products with most quantities sold in a year ---------------------------

WITH QuantityRanked AS (
    SELECT YEAR(Order_Date) Order_Year, Category, Sub_Category
        ,SUM(Quantity) Total_Quantity
        ,RANK() OVER (PARTITION BY YEAR(Order_Date) ORDER BY SUM(Quantity) DESC) Quantity_Rank
    FROM RetailStore
    WHERE Country_Region = 'United States' --to only include USA orders
    GROUP BY YEAR(Order_Date), Category, Sub_Category
)
SELECT *
FROM QuantityRanked
WHERE Quantity_Rank <= 5
ORDER BY Order_Year, Quantity_Rank;

-------------- Sales & profits ranks per sub-category --------------------

With ProductSalesProfit AS (
	SELECT Category, Sub_Category
		,SUM(Sales_Discounted) Total_Sales
		,SUM(Profit_Discounted) Total_Profit
		,RANK() OVER (ORDER BY SUM(Sales_Discounted) DESC) Sales_Rank
		,RANK() OVER (ORDER BY SUM(Profit_Discounted) DESC) Profit_Rank
	FROM RetailStore				  
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Category, Sub_Category
)

SELECT *
FROM ProductSalesProfit

---------- Pareto --------------

SELECT Product_Name
		,CASE 
			WHEN DATEDIFF (MONTH, MIN(Order_Date), (SELECT MAX (Order_Date) FROM RetailStore)) <=12 --(SELECT MAX (Order_Date) FROM RetailStore) gets date of latest order in the business
			THEN 'New' 
			ELSE 'Old' 
		END Product_Age --product age indicator depending upon a specific threshold count of months since it's first order
		,SUM(Sales_Discounted) Total_Sales
		,CAST(
				(
					(
						SUM(Sales_Discounted) / 
							(SELECT SUM(Sales_Discounted) 
								FROM RetailStore 
								WHERE Country_Region = 'United States') --division by total sales for USA
					) * 100
				
				) AS DECIMAL(10,2)
			) Sales_Share
FROM RetailStore				   
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Product_Name
ORDER BY Sales_Share DESC

------------- Percentage difference in profit of top product to the second product in rank -----------------

SELECT TOP 2 Product_Name, 
			SUM(Profit_Discounted) Profit,
			RANK () OVER (ORDER BY SUM(Profit_Discounted) DESC) Profit_Rank
INTO #TopProfits --storing data in temp table
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Product_Name;

SELECT tp1.Product_Name,
		tp1.Profit,
		tp2.Product_Name,
		tp2.Profit,
		CAST(((tp1.Profit - tp2.Profit) / tp2.Profit)*100 as DECIMAL(7,2)) Profit_Difference_Percentage
FROM #TopProfits tp1
JOIN #TopProfits tp2 ON tp1.Profit_Rank = 1 AND tp2.Profit_Rank = 2
