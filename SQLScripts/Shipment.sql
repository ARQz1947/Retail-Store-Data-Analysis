--Don't use Canada

---------------- Preferred shipment mode by area ---------------------

WITH ShipMode AS (
	SELECT Region,
		COUNT(DISTINCT Order_ID) Total_Orders,
		--count orders per each ship mode
		COUNT(DISTINCT(CASE WHEN Ship_Mode = 'First Class' THEN Order_ID END)) As First_Class, 
		COUNT(DISTINCT(CASE WHEN Ship_Mode = 'Same Day' THEN Order_ID END)) As Same_Day,
		COUNT(DISTINCT(CASE WHEN Ship_Mode = 'Standard Class' THEN Order_ID END)) As Standard_Class,
		COUNT(DISTINCT(CASE WHEN Ship_Mode = 'Second Class' THEN Order_ID END)) As Second_Class,
		YEAR(Order_Date) Order_Year
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Region, YEAR(Order_Date)
)

SELECT Region, Order_Year, Total_Orders, First_Class, Same_Day, Standard_Class, Second_Class,
	CASE 
        WHEN First_Class >= Same_Day AND First_Class >= Standard_Class AND First_Class >= Second_Class THEN 'FC'
        WHEN Same_Day >= First_Class AND Same_Day >= Standard_Class AND Same_Day >= Second_Class THEN 'SD'
        WHEN Standard_Class >= First_Class AND Standard_Class >= Same_Day AND Standard_Class >= Second_Class THEN 'STC'
        WHEN Second_Class >= First_Class AND Second_Class >= Same_Day AND Second_Class >= Standard_Class THEN 'SD'
    END Preferred_Ship_Mode
FROM ShipMode
ORDER BY Order_Year;

--------- Same day shipment status per year -------------------------

WITH ShipStatus AS (
	SELECT YEAR(Order_Date) Order_Year, Ship_Status,
			COUNT(DISTINCT Order_ID) Total_Orders
	FROM RetailStore
	WHERE Country_Region = 'United States' AND Ship_Mode = 'Same Day'
	GROUP BY YEAR(Order_Date), Ship_Status
)

SELECT Order_Year, Total_Orders, Ship_Status
FROM ShipStatus;

--------- Early Shipment per year -------------------------

WITH ShipStatus AS (
	SELECT YEAR(Order_Date) Order_Year,
		COUNT(DISTINCT(CASE WHEN Ship_Status = 'Shipped Early' THEN Order_ID END)) Shipped_Early,
		COUNT(DISTINCT Order_ID) Total_Orders
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY YEAR(Order_Date)
)

SELECT Order_Year, Total_Orders, Shipped_Early,
	CAST(
			(
				(CAST(Shipped_Early AS DECIMAL (10,2))/CAST(Total_Orders AS DECIMAL (10,2)))*100 --Rate formula (CASTing counts to decimal to have decimal outcome after division)
			) AS DECIMAL (10,2) 
		) Early_Shipment_Rate 
FROM ShipStatus
ORDER BY Early_Shipment_Rate DESC;

--------- Early Shipment per Ship mode -------------------------

WITH ShipStatus AS (
	SELECT Ship_Mode,
		COUNT(DISTINCT(CASE WHEN Ship_Status = 'Shipped Early' THEN Order_ID END)) Shipped_Early,
		COUNT(DISTINCT Order_ID) Total_Orders
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Ship_Mode
)

SELECT Total_Orders, Shipped_Early, Ship_Mode
FROM ShipStatus
where Shipped_Early > 0 --to filter shipping modes with no early shipments 

--------- Late Shipment per year -------------------------

WITH ShipStatus AS (
	SELECT YEAR(Order_Date) Order_Year,
		COUNT(DISTINCT(CASE WHEN Ship_Status in ('Shipped On Time', 'Shipped Early') THEN Order_ID END)) Shipped_On_Time,
		COUNT(DISTINCT(CASE WHEN Ship_Status = 'Shipped Late' THEN Order_ID END)) Shipped_Late,
		COUNT(DISTINCT Order_ID) Total_Orders
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY YEAR(Order_Date)
)

SELECT Order_Year, Total_Orders, Shipped_On_Time, Shipped_Late,
	CAST(
			(
				(CAST(Shipped_Late AS DECIMAL(10,2))/CAST(Total_Orders AS DECIMAL(10,2)))*100 --Rate formula (CASTing counts to decimal to have decimal outcome after division)
			) AS DECIMAL(10,2)
		) Late_Shipment_Rate
FROM ShipStatus
ORDER BY Late_Shipment_Rate DESC;

------------- Late Shipment per quarter ------------------

WITH ShipStatus AS (
	SELECT Region,
		COUNT(DISTINCT(CASE WHEN Ship_Status in ('Shipped On Time', 'Shipped Early') THEN Order_ID END)) Shipped_On_Time,
		COUNT(DISTINCT(CASE WHEN Ship_Status = 'Shipped Late' THEN Order_ID END)) Shipped_Late,
		COUNT(DISTINCT Order_ID) Total_Orders,
		YEAR(Order_Date) Order_Year,
		DatePart(QUARTER, Order_Date) Order_Qtr
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Region, YEAR(Order_Date), DatePart(QUARTER, Order_Date)
)

SELECT Region, Order_Year, Order_Qtr, Total_Orders, Shipped_On_Time, Shipped_Late,
	CAST(
			(
				(CAST(Shipped_Late AS DECIMAL(5,2))/CAST(Total_Orders AS DECIMAL(5,2)))*100 --Rate formula (CASTing counts to decimal to have decimal outcome after division)
			) AS DECIMAL(5,2)
		) Late_Shipment_Rate,
	CASE	
		WHEN CAST(
					(
						(CAST(Shipped_Late AS DECIMAL(5,2))/CAST(Total_Orders AS DECIMAL(5,2)))*100
					) AS DECIMAL(5,2)
				  ) < 20 
		THEN 'Low'
		WHEN CAST(
					(
						(CAST(Shipped_Late AS DECIMAL(5,2))/CAST(Total_Orders AS DECIMAL(5,2)))*100
					) AS DECIMAL(5,2)
				  ) < 40 
		THEN 'Medium'
		ELSE 'High'
	END Late_Shipment_Risk
FROM ShipStatus
ORDER BY Order_Year, Region, Late_Shipment_Rate;

--------------Late ship percentage by each ship mode-------------------

SELECT YEAR(Order_Date) Order_Year,
	COUNT(DISTINCT(CASE WHEN Ship_Mode = 'First Class' THEN Order_ID END)) First_Class_Orders,
	COUNT(DISTINCT(CASE WHEN Ship_Status = 'Shipped Late' AND Ship_Mode = 'First Class' THEN Order_ID END)) First_Class_Late,
	COUNT(DISTINCT(CASE WHEN Ship_Mode = 'Same Day' THEN Order_ID END)) Same_Day_Orders,
	COUNT(DISTINCT(CASE WHEN Ship_Status = 'Shipped Late' AND Ship_Mode = 'Same Day' THEN Order_ID END)) Same_Day_Late,
	COUNT(DISTINCT(CASE WHEN Ship_Mode = 'Standard Class' THEN Order_ID END)) Standard_Class_Orders,
	COUNT(DISTINCT(CASE WHEN Ship_Status = 'Shipped Late' AND Ship_Mode = 'Standard Class' THEN Order_ID END)) Standard_Class_Late,
	COUNT(DISTINCT(CASE WHEN Ship_Mode = 'Second Class' THEN Order_ID END)) Second_Class_Orders,
	COUNT(DISTINCT(CASE WHEN Ship_Status = 'Shipped Late' AND Ship_Mode = 'Second Class' THEN Order_ID END)) Second_Class_Late
INTO #LateShipCount --using temp table to store results
FROM RetailStore
GROUP BY YEAR(Order_Date)

SELECT Order_Year, 
	CAST((CAST((First_Class_Late) AS DECIMAL(10,2))/CAST((First_Class_Orders)AS DECIMAL(10,2))*100)AS DECIMAL(5,2)) 'First_Class_Late(%)',  
	CAST((CAST((Same_Day_Late) AS DECIMAL(10,2))/CAST((Same_Day_Orders)AS DECIMAL(10,2))*100)AS DECIMAL(5,2)) 'Same_Day_Late(%)',
	CAST((CAST((Standard_Class_Late) AS DECIMAL(10,2))/CAST((Standard_Class_Orders)AS DECIMAL(10,2))*100)AS DECIMAL(5,2)) 'Standard_Class_Late(%)',
	CAST((CAST((Second_Class_Late) AS DECIMAL(10,2))/CAST((Second_Class_Orders)AS DECIMAL(10,2))*100)AS DECIMAL(5,2)) 'Second_Class_Late(%)'
FROM #LateShipCount
ORDER BY Order_Year 

-------------------- Percentage of on-time shipment per Area (Reciprocal to Query 01) ---------------------

SELECT Region, YEAR(Order_Date) Order_Year,
	COUNT(DISTINCT Order_ID) Total_Orders,
    COUNT(DISTINCT CASE WHEN Ship_Status IN ('Shipped On Time', 'Shipped Early') THEN Order_ID END) Shipped_On_Time,
    COUNT(DISTINCT CASE WHEN Ship_Status = 'Shipped Late' THEN Order_ID END) Shipped_Late,
	(COUNT(DISTINCT CASE WHEN Ship_Status IN ('Shipped On Time', 'Shipped Early') THEN Order_ID END) * 100 / COUNT(DISTINCT Order_ID)) Percentage_on_Time
FROM RetailStore
GROUP BY Region, YEAR(Order_Date)
ORDER BY Order_Year, Percentage_on_Time DESC;

-------------- Late shipment by category -------------------

WITH ShipStatus AS (
	SELECT Category, Sub_Category,
		COUNT(DISTINCT(CASE WHEN Ship_Status in ('Shipped On Time', 'Shipped Early') THEN Order_ID END)) Shipped_On_Time,
		COUNT(DISTINCT(CASE WHEN Ship_Status = 'Shipped Late' THEN Order_ID END)) Shipped_Late,
		COUNT(DISTINCT Order_ID) Total_Orders,
		YEAR(Order_Date) Order_Year
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Category, Sub_Category, YEAR(Order_Date)
)

SELECT Category, Sub_Category, Order_Year, Total_Orders, Shipped_On_Time, Shipped_Late,
	CAST(
			(
				(CAST(Shipped_Late AS DECIMAL(5,2))/CAST(Total_Orders AS DECIMAL(5,2)))*100
			) AS DECIMAL(5,2)
		) Late_Shipment_Rate,
	CASE	
		WHEN CAST(((CAST(Shipped_Late AS DECIMAL(5,2))/CAST(Total_Orders AS DECIMAL(5,2)))*100) AS DECIMAL(5,2)) < 10 THEN 'Low'
		WHEN CAST(((CAST(Shipped_Late AS DECIMAL(5,2))/CAST(Total_Orders AS DECIMAL(5,2)))*100) AS DECIMAL(5,2)) < 30 THEN 'Medium'
		ELSE 'High'
	END Late_Shipment_Risk
FROM ShipStatus
ORDER BY Order_Year, Late_Shipment_Rate;

------------------ Late shipment by region --------------------

WITH ShipStatus AS (
	SELECT Region,
		COUNT(DISTINCT(CASE WHEN Ship_Status in ('Shipped On Time', 'Shipped Early') THEN Order_ID END)) Shipped_On_Time,
		COUNT(DISTINCT(CASE WHEN Ship_Status = 'Shipped Late' THEN Order_ID END)) Shipped_Late,
		COUNT(DISTINCT Order_ID) Total_Orders,
		YEAR(Order_Date) Order_Year
	FROM RetailStore
	WHERE Country_Region = 'United States' --to only include USA orders
	GROUP BY Region, YEAR(Order_Date)
)

SELECT Region, Order_Year, Total_Orders, Shipped_On_Time, Shipped_Late,
	CAST(
			(
				(CAST(Shipped_Late AS DECIMAL(5,2))/CAST(Total_Orders AS DECIMAL(5,2)))*100
			) AS DECIMAL(5,2)
		) Late_Shipment_Rate,
	CASE	
		WHEN CAST(((CAST(Shipped_Late AS DECIMAL (5,2))/CAST(Total_Orders AS DECIMAL(5,2)))*100) AS DECIMAL(5,2)) < 10 THEN 'Low'
		WHEN CAST(((CAST(Shipped_Late AS DECIMAL (5,2))/CAST(Total_Orders AS DECIMAL(5,2)))*100) AS DECIMAL(5,2)) < 30 THEN 'Medium'
		ELSE 'High'
	END Late_Shipment_Risk
FROM ShipStatus
ORDER BY Order_Year, Late_Shipment_Rate;

--------------- All shipping methods with products count -----------------

SELECT Ship_Mode, Category, Sub_Category, COUNT(DISTINCT Order_ID)
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Ship_Mode, Category, Sub_Category
ORDER BY Ship_Mode

------------- Shipping method sales & profits ----------------

SELECT Ship_Mode, COUNT(DISTINCT Order_ID) Total_Orders, 
	CAST(SUM(Sales_Discounted) AS DECIMAL(10,2)) Total_Sales, 
	CAST(SUM(Profit_Discounted) AS DECIMAL(10,2)) Total_Profit,
	RANK() OVER (ORDER BY SUM(Sales_Discounted) DESC) Sales_Rank,
	RANK() OVER (ORDER BY SUM(Profit_Discounted) DESC) Profit_Rank
FROM RetailStore
WHERE Country_Region = 'United States' --to only include USA orders
GROUP BY Ship_Mode
ORDER BY Sales_Rank, Profit_Rank
