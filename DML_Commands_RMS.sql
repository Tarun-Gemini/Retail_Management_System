/*Rank the customers based on
1a.) Total purchasing they have done in terms of amount in desc order using RANK and DENKSE RANK */

SELECT Customer_Id, TotalAmountPaid,
RANK() OVER(ORDER BY TotalAmountPaid DESC) AS _RANK,
DENSE_RANK() OVER(ORDER BY TotalAmountPaid DESC) AS DenseRank
FROM (SELECT Customer_Id, SUM(Amount_Paid) AS TotalAmountPaid FROM ProductSalesFact
		GROUP BY Customer_Id) AS T;


/* Total quantities they have purchased by descending order
check if the final ranking is the same or not. */

SELECT Customer_Id, TotalQuantityPurchased,
RANK() OVER(ORDER BY TotalQuantityPurchased DESC) AS _Rank,
DENSE_RANK() OVER(ORDER BY TotalQuantityPurchased DESC) AS DenseRank
FROM (SELECT Customer_Id,
      SUM(Quantity) AS TotalQuantityPurchased
      FROM ProductSalesFact 
      GROUP BY Customer_Id) AS T;


/* Identify the top 1 ranking product/s within each product category by their:
Apply proper ranking mechanism in this question.
2a.) Price. */

SELECT *
FROM
(
SELECT Product_Id, Price, Category_Id,
DENSE_RANK() OVER(PARTITION BY Category_Id ORDER BY Price DESC) AS _rank
FROM ProductDim) AS T
WHERE _rank = 1;

/* 2b.) Number of days they are in inventory from the current date. */

SELECT * FROM
(SELECT Product_Id, DATEDIFF(day,GETDATE(),In_Inventory) AS TotalDays, Category_Id,
DENSE_RANK() OVER(PARTITION BY Category_Id ORDER BY DATEDIFF(day,GETDATE(),In_Inventory) DESC) AS _Rank
FROM ProductDim) AS T
WHERE _Rank = 1;

/* 2c.) Rank the complaints that are not resolved by their number of days in top to bottom order. Categorize the results by the Complaint Name.*/

SELECT Complaint_Id, DATEDIFF(day,Complaint_Date,GETDATE()) AS DaysDue, Complaint_Name,
DENSE_RANK() OVER(PARTITION BY Complaint_Name ORDER BY DATEDIFF(day,Complaint_Date,GETDATE()) DESC) AS _rank
FROM Complaints
WHERE Resolved = 'Not Resolved';


/* Compare the total purchase by amount that happened for each Usage type on a week by week basis. 
Remove records where we have null values on past or future values. Compare the earnings and calculate the profit or loss compared to last week. */

SELECT *,
TotalPurchase - Past AS RevenueFromLastWeek
FROM
(
SELECT *,
LAG(TotalPurchase) OVER(PARTITION BY Cust_Usage ORDER BY _week) AS Past,
LEAD(TotalPurchase) OVER(PARTITION BY Cust_Usage ORDER BY _week) AS Future
FROM (SELECT Cust_Usage,
     DATEPART(WEEK, DateofPurchase) as _week,
     SUM(Amount_Paid) AS TotalPurchase
     FROM ProductSalesFact
     GROUP BY Cust_Usage, DATEPART(WEEK, DateofPurchase)) AS T) AS T
     WHERE Past IS NOT NULL AND Future IS NOT NULL;


/* Compare the total number of complaints resolved on a week by week basis [include only past values]. 
What comment can you make based on the results? */

SELECT *,
LAG(TotalComplaints) OVER(PARTITION BY Resolved ORDER BY _week) AS Past
FROM (SELECT Resolved,
     DATEPART(WEEK, Complaint_Date) as _week,
     COUNT(*) AS TotalComplaints
     FROM Complaints
     GROUP BY Resolved, DATEPART(WEEK, Complaint_Date)) AS T;



/* Get the number of customers that you witness week-by-week
on your platform for each usage type including past and future values */

SELECT *,
LAG(TotalCustomers) OVER (PARTITION BY Cust_Usage ORDER BY _week) AS Past,
LEAD(TotalCustomers) OVER (PARTITION BY Cust_Usage ORDER BY _week) AS Future
FROM (SELECT Cust_Usage,
		DATEPART(WEEK, DateofPurchase) AS _week,
		count(*) AS TotalCustomers
		FROM ProductSalesFact
		GROUP BY Cust_Usage, DATEPART(WEEK, DateofPurchase)) AS T;



/* Select only the first and last record across each category in the above question. */

SELECT *,
FIRST_VALUE(TotalCustomers) OVER(PARTITION BY Cust_Usage 
		ORDER BY _week RANGE BETWEEN UNBOUNDED PRECEDING AND
		UNBOUNDED FOLLOWING) AS firstvalue,
LAST_VALUE(TotalCustomers) OVER(PARTITION BY Cust_Usage 
		ORDER BY _week RANGE BETWEEN UNBOUNDED PRECEDING AND
		UNBOUNDED FOLLOWING) AS lastvalue
FROM(SELECT Cust_Usage,
		DATEPART(WEEK, DateofPurchase) AS _week,
		COUNT(*) AS TotalCustomers
		FROM ProductSalesFact
		GROUP BY Cust_Usage, DATEPART(WEEK, DateofPurchase)) AS T;


/* Divide the household customer into 3 segments: highPurchase, mediumPurchase and lowPurchase based on 
ranking of customers by their total purchase amount (first 25% in low, 25 to 75 medium and > 75% high) */

SELECT *,
CASE
WHEN _rank < 0.25 THEN 'Lowpurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'Mediumpurchase'
ELSE 'Highpurchase'
END AS PurchasePower
FROM
(SELECT *, PERCENT_RANK() OVER(ORDER BY TotalPurchase) AS _rank
FROM (SELECT Customer_Id, Cust_Usage,
		SUM(Amount_Paid) AS TotalPurchase
		FROM ProductSalesFact
		GROUP BY Customer_Id, Cust_Usage) AS T
WHERE Cust_Usage = 'Household') AS T;


/* Find the Number of customers in each of the categories of derived household customers */

SELECT *,
CASE
WHEN _rank < 0.25 THEN 'Lowpurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'Mediumpurchase'
ELSE 'Highpurchase'
END AS PurchasePower
FROM
(
SELECT *,
PERCENT_RANK() OVER(ORDER BY TotalPurchase) AS _rank
FROM (SELECT Customer_Id, Cust_Usage,
	SUM(Amount_Paid) AS TotalPurchase
	FROM ProductSalesFact
	GROUP BY Customer_Id, Cust_Usage) AS T
WHERE Cust_Usage = 'Household') AS T;

/* Total purchase within each household category in terms of Quantity they purchased */

SELECT CASE 
WHEN _rank < 0.25 THEN 'lowPurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'medicumPurchase'
ELSE 'highPurchase'
END AS PurchasePower,
COUNT(*) AS TotalCustomersBySegment
FROM
(
SELECT *,
PERCENT_RANK() OVER(ORDER BY TotalPurchase) AS _rank
FROM (SELECT Customer_Id, Cust_Usage, 
      SUM(Amount_Paid) AS TotalPurchase
      FROM ProductSalesFact 
      GROUP BY Customer_Id, Cust_Usage) AS T
WHERE Cust_Usage = 'Household') AS T
GROUP BY
CASE 
WHEN _rank < 0.25 THEN 'lowPurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'medicumPurchase'
ELSE 'highPurchase'
END;


/*Total purchase within each household category in terms of Total Purchase amount. */

SELECT
CASE 
WHEN _rank < 0.25 THEN 'lowPurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'medicumPurchase'
ELSE 'highPurchase'
END AS PurchasePower,
SUM(TotalPurchase) AS TotalPurchaseBySegment,
SUM(TotalQuantity) AS TotalQuantityBySegment
FROM
(
SELECT *,
PERCENT_RANK() OVER(ORDER BY TotalPurchase) AS _rank
FROM (SELECT Customer_Id, Cust_Usage, 
      SUM(Amount_Paid) AS TotalPurchase,
      SUM(Quantity) AS TotalQuantity
      FROM ProductSalesFact 
      GROUP BY Customer_Id, Cust_Usage) AS T
WHERE Cust_Usage = 'Household') AS T
GROUP BY 
CASE 
WHEN _rank < 0.25 THEN 'lowPurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'medicumPurchase'
ELSE 'highPurchase'
END;

/* Sort the household customers by their amount paid while 
industrial customer to the discounts they have been offered. */

SELECT PS.*, 
PD.Discount 
FROM ProductSalesFact AS PS 
JOIN ProductDim AS PD 
ON PS.Product_Id = PD.Product_Id 
ORDER BY 
CASE  
WHEN Cust_Usage = 'Household' THEN Amount_Paid 
ELSE Discount END;


