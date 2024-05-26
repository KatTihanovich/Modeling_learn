-- Load Data Into Staging, Transformation, and Star Schema
-- 1. For each source table in the northwind_pg database, you need to create a corresponding staging table and load data into it. 
INSERT INTO staging_orders 
SELECT * FROM SalesOrder;

INSERT INTO staging_order_details 
SELECT * FROM OrderDetail;

INSERT INTO staging_products 
SELECT * FROM Product;

INSERT INTO staging_customers 
SELECT * FROM Customer;

INSERT INTO staging_employees 
SELECT * FROM Employee;

INSERT INTO staging_categories 
SELECT * FROM Category;

INSERT INTO staging_shippers 
SELECT * FROM Shipper;

INSERT INTO staging_suppliers 
SELECT * FROM Supplier;

--- 3. Transform the data from the staging tables and load it into the respective dimension tables
INSERT INTO DimProduct (ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit, UnitPrice, UnitsInStock)
SELECT ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit, UnitPrice, UnitsInStock
FROM staging_products;

INSERT INTO DimCustomer (CustomerID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone) 
SELECT custid, companyname, contactname, contacttitle, address, city, region, postalcode, country, phone 
FROM staging_customers;

INSERT INTO DimCategory (CategoryID, CategoryName, Description)
SELECT categoryid, categoryname, description
FROM staging_categories;

INSERT INTO DimEmployee (EmployeeID, LastName, FirstName, Title, BirthDate, HireDate, Address, City, Region, PostalCode, Country, HomePhone, Extension)
SELECT empid, lastname, firstname, title, birthdate, hiredate, address, city, region, postalcode, country, phone, extension
FROM staging_employees;

INSERT INTO DimShipper (ShipperID, CompanyName, Phone)
SELECT shipperid, companyname, phone
FROM staging_shippers;

INSERT INTO DimSupplier (SupplierID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone)
SELECT supplierid, companyname, contactname, contacttitle, address, city, region, postalcode, country, phone
FROM staging_suppliers;

INSERT INTO DimDate (Date, Day, Month, Year, Quarter, WeekOfYear)
SELECT
    DISTINCT DATE(orderdate) AS Date,
    EXTRACT(DAY FROM DATE(orderdate)) AS Day,
    EXTRACT(MONTH FROM DATE(orderdate)) AS Month,
    EXTRACT(YEAR FROM DATE(orderdate)) AS Year,
    EXTRACT(QUARTER FROM DATE(orderdate)) AS Quarter,
    EXTRACT(WEEK FROM DATE(orderdate)) AS WeekOfYear
FROM
    staging_orders;
	
-- 5. Load data  into the fact table
INSERT INTO FactSales (DateID, CustomerID, ProductID, EmployeeID, CategoryID, ShipperID, SupplierID, QuantitySold, UnitPrice, Discount, TotalAmount, TaxAmount) 
SELECT
    d.DateID,   
    c.custid,  
    p.ProductID,  
    e.empid,  
    cat.CategoryID,  
    s.ShipperID,  
    sup.SupplierID, 
    od.qty, 
    od.UnitPrice, 
    od.Discount,    
    (od.qty * od.UnitPrice - od.Discount) AS TotalAmount,
    (od.qty * od.UnitPrice - od.Discount) * 0.1 AS TaxAmount     
FROM staging_order_details od 
JOIN staging_orders o ON od.OrderID = o.OrderID 
JOIN staging_customers c ON o.custid = c.custid::varchar 
JOIN staging_products p ON od.ProductID = p.ProductID  
LEFT JOIN staging_employees e ON o.empid = e.empid  
LEFT JOIN staging_categories cat ON p.CategoryID = cat.CategoryID 
LEFT JOIN staging_shippers s ON o.shipperid = s.ShipperID  
LEFT JOIN staging_suppliers sup ON p.SupplierID = sup.SupplierID
LEFT JOIN DimDate d ON o.orderdate = d.Date;