-- TASK 23: SQL WINDOW FUNCTIONS INTRO
-- Dataset: Northwind / Northwind-style database
-- SQL: MySQL 8+ / PostgreSQL-compatible window-function syntax
-- Tables: Customers, Orders, Order_Details, Products

-- Q1: Number orders for each customer
SELECT CustomerID, OrderID, OrderDate,
ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate, OrderID) AS Order_Number
FROM Orders
ORDER BY CustomerID, OrderDate, OrderID;

-- Q2: Number products by descending price
SELECT ProductID, ProductName, UnitPrice,
ROW_NUMBER() OVER (ORDER BY UnitPrice DESC) AS Price_Position
FROM Products
ORDER BY UnitPrice DESC;

-- Q3: Rank products by price
SELECT ProductID, ProductName, UnitPrice,
RANK() OVER (ORDER BY UnitPrice DESC) AS Price_Rank
FROM Products
ORDER BY Price_Rank, ProductID;

-- Q4: Dense-rank products by price
SELECT ProductID, ProductName, UnitPrice,
DENSE_RANK() OVER (ORDER BY UnitPrice DESC) AS Dense_Price_Rank
FROM Products
ORDER BY Dense_Price_Rank, ProductID;

-- Q5: Compare ROW_NUMBER, RANK and DENSE_RANK
SELECT ProductID, ProductName, UnitPrice,
ROW_NUMBER() OVER (ORDER BY UnitPrice DESC) AS Row_Num,
RANK() OVER (ORDER BY UnitPrice DESC) AS Rank_Num,
DENSE_RANK() OVER (ORDER BY UnitPrice DESC) AS Dense_Rank_Num
FROM Products
ORDER BY UnitPrice DESC, ProductID;

-- Q6: Rank products within each category
SELECT CategoryID, ProductID, ProductName, UnitPrice,
RANK() OVER (PARTITION BY CategoryID ORDER BY UnitPrice DESC) AS Category_Price_Rank
FROM Products
ORDER BY CategoryID, Category_Price_Rank, ProductID;

-- Q7: Top 3 products by price in each category
WITH RankedProducts AS (
    SELECT CategoryID, ProductID, ProductName, UnitPrice,
    RANK() OVER (PARTITION BY CategoryID ORDER BY UnitPrice DESC) AS rnk
    FROM Products
)
SELECT *
FROM RankedProducts
WHERE rnk <= 3
ORDER BY CategoryID, rnk, ProductID;

-- Q8: Previous order date for each customer
SELECT CustomerID, OrderID, OrderDate,
LAG(OrderDate) OVER (
    PARTITION BY CustomerID ORDER BY OrderDate, OrderID
) AS Previous_Order_Date
FROM Orders
ORDER BY CustomerID, OrderDate, OrderID;

-- Q9: Days since previous order (MySQL)
WITH PreviousOrders AS (
    SELECT CustomerID, OrderID, OrderDate,
    LAG(OrderDate) OVER (
        PARTITION BY CustomerID ORDER BY OrderDate, OrderID
    ) AS Previous_Order_Date
    FROM Orders
)
SELECT CustomerID, OrderID, OrderDate, Previous_Order_Date,
DATEDIFF(OrderDate, Previous_Order_Date) AS Days_Since_Previous_Order
FROM PreviousOrders
ORDER BY CustomerID, OrderDate, OrderID;

-- Q10: Current order value vs previous order value
WITH OrderTotals AS (
    SELECT o.OrderID, o.CustomerID, o.OrderDate,
    SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS Order_Value
    FROM Orders o
    JOIN Order_Details od ON o.OrderID = od.OrderID
    GROUP BY o.OrderID, o.CustomerID, o.OrderDate
),
PreviousValues AS (
    SELECT *,
    LAG(Order_Value) OVER (
        PARTITION BY CustomerID ORDER BY OrderDate, OrderID
    ) AS Previous_Order_Value
    FROM OrderTotals
)
SELECT CustomerID, OrderID, OrderDate,
ROUND(Order_Value, 2) AS Order_Value,
ROUND(Previous_Order_Value, 2) AS Previous_Order_Value,
ROUND(Order_Value - Previous_Order_Value, 2) AS Change_From_Previous
FROM PreviousValues
ORDER BY CustomerID, OrderDate, OrderID;

-- Q11: Rank customers by total sales
WITH CustomerSales AS (
    SELECT o.CustomerID,
    SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS Total_Sales
    FROM Orders o
    JOIN Order_Details od ON o.OrderID = od.OrderID
    GROUP BY o.CustomerID
)
SELECT CustomerID, ROUND(Total_Sales, 2) AS Total_Sales,
RANK() OVER (ORDER BY Total_Sales DESC) AS Sales_Rank
FROM CustomerSales
ORDER BY Sales_Rank, CustomerID;

-- Q12: Monthly sales trend using LAG
WITH MonthlySales AS (
    SELECT EXTRACT(YEAR FROM o.OrderDate) AS Sales_Year,
    EXTRACT(MONTH FROM o.OrderDate) AS Sales_Month,
    SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS Monthly_Sales
    FROM Orders o
    JOIN Order_Details od ON o.OrderID = od.OrderID
    GROUP BY EXTRACT(YEAR FROM o.OrderDate), EXTRACT(MONTH FROM o.OrderDate)
),
Trend AS (
    SELECT *,
    LAG(Monthly_Sales) OVER (ORDER BY Sales_Year, Sales_Month) AS Previous_Month_Sales
    FROM MonthlySales
)
SELECT Sales_Year, Sales_Month,
ROUND(Monthly_Sales, 2) AS Monthly_Sales,
ROUND(Previous_Month_Sales, 2) AS Previous_Month_Sales,
ROUND(Monthly_Sales - Previous_Month_Sales, 2) AS MoM_Change
FROM Trend
ORDER BY Sales_Year, Sales_Month;
