-- 6. After loading data into the fact and dimension tables, you should validate the data to ensure it is accurate and complete. 
SELECT 'DimDate' AS Table_Name, COUNT(*) AS Record_Count FROM DimDate
UNION ALL
SELECT 'DimCustomer', COUNT(*) FROM DimCustomer
UNION ALL
SELECT 'DimProduct', COUNT(*) FROM DimProduct
UNION ALL
SELECT 'DimEmployee', COUNT(*) FROM DimEmployee
UNION ALL
SELECT 'DimCategory', COUNT(*) FROM DimCategory
UNION ALL
SELECT 'DimShipper', COUNT(*) FROM DimShipper
UNION ALL
SELECT 'DimSupplier', COUNT(*) FROM DimSupplier
UNION ALL
SELECT 'FactSales', COUNT(*) FROM FactSales
UNION ALL
SELECT 'staging_customers', COUNT(*) FROM staging_customers
UNION ALL
SELECT 'staging_products', COUNT(*) FROM staging_products
UNION ALL
SELECT 'staging_categories', COUNT(*) FROM staging_categories
UNION ALL
SELECT 'staging_employees', COUNT(*) FROM staging_employees
UNION ALL
SELECT 'staging_shippers', COUNT(*) FROM staging_shippers
UNION ALL
SELECT 'staging_suppliers', COUNT(*) FROM staging_suppliers
UNION ALL
SELECT 'staging_order_details', COUNT(*) FROM staging_order_details
UNION ALL
SELECT 'staging_orders_unique_orderdates', COUNT(DISTINCT orderdate) FROM staging_orders;

SELECT COUNT(*) AS wrong_data_counter 
FROM FactSales 
WHERE DateID NOT IN (SELECT DateID FROM DimDate)
   OR CustomerID NOT IN (SELECT CustomerID FROM DimCustomer)
   OR ProductID NOT IN (SELECT ProductID FROM DimProduct)
   OR EmployeeID NOT IN (SELECT EmployeeID FROM DimEmployee)
   OR CategoryID NOT IN (SELECT CategoryID FROM DimCategory)
   OR ShipperID NOT IN (SELECT ShipperID FROM DimShipper)
   OR SupplierID NOT IN (SELECT SupplierID FROM DimSupplier);
   
   
--Business Report Queries   
--1
--Display average sales (total amount, net amount, tax; number of transactions), the rolling average for three months (January–February; January–February–March; February–March–April) per day (specifying the month and date range) across all product categories (selected category, list of categories) in geographical sections (regions, countries, states), in gender sections (men, women), by age group (0–18, 19–28, 28–45, 45–60, 60+), by income (0–20000, 20001–40000, 40001–60000, 60001–80000, 80001-100000). This involves querying the FactSales and DimDate tables.
WITH SalesData AS (
    SELECT
        fs.DateID,
        fs.CustomerID,
        fs.ProductID,
        SUM(fs.TotalAmount) AS TotalAmount,
        SUM(fs.TaxAmount) AS Tax,
		SUM(fs.TotalAmount - fs.TaxAmount) AS NetAmount,
        COUNT(*) AS NumTransactions
    FROM
        FactSales fs
    JOIN
        DimDate d ON fs.DateID = d.DateID
    JOIN
        DimProduct p ON fs.ProductID = p.ProductID
    JOIN
        DimCustomer c ON fs.CustomerID = c.CustomerID
    WHERE
        d.Date BETWEEN '2006-01-01' AND '2006-12-31'
    GROUP BY
        fs.DateID, fs.CustomerID, fs.ProductID
)
SELECT
    EXTRACT(YEAR FROM d.Date) AS Year,
    EXTRACT(MONTH FROM d.Date) AS Month,
    EXTRACT(DAY FROM d.Date) AS Day,
    cat.CategoryName,
    c.Region,
    c.Country,
    AVG(sd.TotalAmount) AS AvgTotalAmount,
    AVG(sd.NetAmount) AS AvgNetAmount,
    AVG(sd.Tax) AS AvgTax,
    AVG(sd.NumTransactions) AS AvgNumTransactions,
    AVG(AVG(sd.TotalAmount)) OVER (
        PARTITION BY cat.CategoryName, c.Region, c.Country
        ORDER BY d.Date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS RollingAvgTotalAmount
FROM
    SalesData sd
JOIN
    DimDate d ON sd.DateID = d.DateID
JOIN
    DimProduct p ON sd.ProductID = p.ProductID
JOIN
    DimCategory cat USING(CategoryId)
JOIN
    DimCustomer c ON sd.CustomerID = c.CustomerID
GROUP BY
    EXTRACT(YEAR FROM d.Date), EXTRACT(MONTH FROM d.Date), EXTRACT(DAY FROM d.Date), d.Date, cat.CategoryName, c.Region, c.Country
ORDER BY
    EXTRACT(YEAR FROM d.Date), EXTRACT(MONTH FROM d.Date), EXTRACT(DAY FROM d.Date), d.Date, cat.CategoryName, c.Region, c.Country;
	
--2	
--Display the top (worst) five products by number of transactions, total sales, and tax (add category section). This involves querying the FactSales table.
SELECT
    P.ProductName,
    C.CategoryName,
    COUNT(*) AS NumberOfTransactions,
    SUM(FS.QuantitySold * FS.UnitPrice) AS TotalSales,
    SUM(FS.TaxAmount) AS TotalTax
FROM FactSales FS
JOIN DimProduct P ON FS.ProductID = P.ProductID
JOIN DimCategory C ON P.CategoryID = C.CategoryID
GROUP BY
    P.ProductName,
    C.CategoryName
ORDER BY
    NumberOfTransactions DESC,
    TotalSales DESC,
    TotalTax DESC
LIMIT 5;

--3
--Display the top (worst) five customers by number of transactions and purchase amount (add gender section, region, country, product categories, age group). This involves querying the FactSales table.
SELECT 
    c.CustomerID,
    c.CompanyName,
    c.Region,
    c.Country,
    COUNT(*) AS NumTransactions,
    SUM(fs.TotalAmount) AS PurchaseAmount
FROM 
    FactSales fs
JOIN 
    DimCustomer c ON fs.CustomerID = c.CustomerID
JOIN 
    DimProduct p ON fs.ProductID = p.ProductID
JOIN 
    DimCategory cat ON p.CategoryID = cat.CategoryID
GROUP BY 
    c.CustomerID,
    c.CompanyName,
    c.Region,
    c.Country
ORDER BY 
    NumTransactions ASC,
    PurchaseAmount ASC
LIMIT 5;

--4
--Display a sales chart (with the total amount of sales and the quantity of items sold) for the first week of each month. This involves querying the FactSales and DimDate tables.
SELECT 
    Month,
    SUM(TotalAmount) AS TotalSalesAmount,
    SUM(QuantitySold) AS TotalQuantitySold
FROM  FactSales
JOIN DimDate ON FactSales.DateID = DimDate.DateID
WHERE Day BETWEEN 1 AND 7
GROUP BY Month
ORDER BY Month;

--5
--Display a weekly sales report (with monthly totals) by product category (period: one year). This involves querying the FactSales, DimDate, and DimProduct tables.
SELECT 
    DP.CategoryID,
    DC.CategoryName,
    EXTRACT(WEEK FROM DD.Date) AS Week,
    EXTRACT(MONTH FROM DD.Date) AS Month,
    SUM(FS.QuantitySold) AS WeeklyQuantitySold,
    SUM(FS.TotalAmount) AS WeeklyTotalAmount,
    SUM(SUM(FS.TotalAmount)) OVER (PARTITION BY EXTRACT(MONTH FROM DD.Date)) AS MonthlyTotalAmount
FROM FactSales FS
JOIN DimDate DD ON FS.DateID = DD.DateID
JOIN DimProduct DP ON FS.ProductID = DP.ProductID
JOIN  DimCategory DC ON DP.CategoryID = DC.CategoryID
GROUP BY 
	DP.CategoryID, 
	DC.CategoryName, 
	EXTRACT(WEEK FROM DD.Date), 
	EXTRACT(MONTH FROM DD.Date)
ORDER BY 
    EXTRACT(MONTH FROM DD.Date), 
	EXTRACT(WEEK FROM DD.Date), 
	DP.CategoryID;

--6
--Display the median monthly sales value by product category and country. This involves querying the FactSales, DimProduct, and DimCustomer tables and requires a more complex query or a custom function to calculate the median.
SELECT
	EXTRACT(month FROM d.Date) AS Month,
    p.CategoryID AS productcategory,
    c.Country,
    FLOOR(AVG(fs.TotalAmount)) AS MonthlySales
FROM FactSales fs
JOIN DimProduct p ON fs.ProductID = p.ProductID
JOIN DimCustomer c ON fs.CustomerID = c.CustomerID
JOIN DimDate d ON fs.DateID = d.DateID
GROUP BY
	EXTRACT(month FROM d.Date),
    p.CategoryID,
    c.Country
ORDER BY Month ASC;

--7
--Display sales rankings by product category (with the best-selling categories at the top). This involves querying the FactSales and DimProduct tables.
SELECT
    p.CategoryID,
    cat.CategoryName,
    SUM(fs.TotalAmount) AS TotalSalesAmount
FROM
    FactSales fs
JOIN
    DimProduct p ON fs.ProductID = p.ProductID
JOIN
    DimCategory cat ON p.CategoryID = cat.CategoryID
GROUP BY
    p.CategoryID, cat.CategoryName
ORDER BY
    TotalSalesAmount DESC;