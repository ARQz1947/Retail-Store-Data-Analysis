--Don't use Canada

--------------- Monthly avg. discount and total profits per year per sub-category ---------------------------

SELECT DISTINCT YEAR(Order_Date) Order_Year, 
	MONTH(Order_Date) Order_Month,
	Category,
	Sub_Category, 
	CAST((Avg(Discount_rate)) AS DECIMAL(5,2)) Avg_Discount, 
	CAST(SUM(Profit_Discounted) AS DECIMAL(10,2)) Total_Profit
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY YEAR(Order_Date), MONTH(Order_Date), Category, Sub_Category
ORDER BY Sub_Category, Category, Order_Year, Order_Month

------------------ Count of discounted and non-discounted order by months & years ---------------

SELECT YEAR(Order_Date) Order_Year, Month(Order_date) Order_Month,
    COUNT(DISTINCT CASE WHEN discount_rate = 0 THEN Order_ID END) No_Discount_Orders,
    COUNT(DISTINCT CASE WHEN discount_rate > 0 THEN Order_ID END) Discount_Orders
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Month(Order_Date), Year(Order_Date)
ORDER BY Order_Year ASC, Order_Month

------------ Total orders (discount and non-discount) per category and year ----------- 

SELECT YEAR(Order_Date) Order_Year, Category,
    COUNT(DISTINCT CASE WHEN Discount_rate = 0 THEN Order_ID END) No_Discount_Orders,
    COUNT(DISTINCT CASE WHEN Discount_rate > 0 THEN Order_ID END) Discount_Orders
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Category, YEAR(Order_Date)
ORDER BY Category, Order_Year

---------- Total orders per discount rate by category --------------

SELECT Category, Discount_rate, COUNT(DISTINCT Order_ID) Total_Orders
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Category, Discount_rate
ORDER BY Category, Discount_rate

----------------------------------------
/*
SELECT sc.Sub_Category, dr.Discount_Rate
FROM (
    SELECT DISTINCT Sub_Category 
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
) sc
JOIN (
    SELECT DISTINCT Sub_Category, Discount_Rate 
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
) dr
    ON sc.Sub_Category = dr.Sub_Category
ORDER BY sc.Sub_Category, dr.Discount_Rate;
*/