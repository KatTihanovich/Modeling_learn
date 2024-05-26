-- 1. Create the following staging tables:
CREATE TABLE staging_orders AS
SELECT * FROM salesorder WHERE 1=0;

CREATE TABLE staging_order_details AS
SELECT * FROM orderdetail WHERE 1=0;

CREATE TABLE staging_products AS
SELECT * FROM product WHERE 1=0;

CREATE TABLE staging_customers AS
SELECT * FROM customer WHERE 1=0;

CREATE TABLE staging_employees AS
SELECT * FROM employee WHERE 1=0;

CREATE TABLE staging_categories AS
SELECT * FROM category WHERE 1=0;

CREATE TABLE staging_shippers AS
SELECT * FROM shipper WHERE 1=0;

CREATE TABLE staging_suppliers AS
SELECT * FROM supplier WHERE 1=0;

-- 2. Use the proposed set of dimension tables and their respective columns and the table FactSales.
CREATE TABLE DimDate (
    DateID SERIAL PRIMARY KEY,
    Date DATE,
    Day INT,
    Month INT,
    Year INT,
    Quarter INT,
    WeekOfYear INT
);

CREATE TABLE DimCustomer (
    CustomerID SERIAL PRIMARY KEY,
    CompanyName VARCHAR(255),
    ContactName VARCHAR(255),
    ContactTitle VARCHAR(255),
    Address VARCHAR(255),
    City VARCHAR(255),
    Region VARCHAR(255),
    PostalCode VARCHAR(10),
    Country VARCHAR(255),
    Phone VARCHAR(20)
);

CREATE TABLE DimProduct (
    ProductID SERIAL PRIMARY KEY,
    ProductName VARCHAR(255),
    SupplierID INT,
    CategoryID INT,
    QuantityPerUnit VARCHAR(255),
    UnitPrice DECIMAL(10, 2),
    UnitsInStock INT
);

CREATE TABLE DimEmployee (
    EmployeeID SERIAL PRIMARY KEY,
    LastName VARCHAR(255),
    FirstName VARCHAR(255),
    Title VARCHAR(255),
    BirthDate DATE,
    HireDate DATE,
    Address VARCHAR(255),
    City VARCHAR(255),
    Region VARCHAR(255),
    PostalCode VARCHAR(10),
    Country VARCHAR(255),
    HomePhone VARCHAR(20),
    Extension VARCHAR(10)
);

CREATE TABLE DimCategory (
    CategoryID SERIAL PRIMARY KEY,
    CategoryName VARCHAR(255),
    Description TEXT
);

CREATE TABLE DimShipper (
    ShipperID SERIAL PRIMARY KEY,
    CompanyName VARCHAR(255),
    Phone VARCHAR(20)
);

CREATE TABLE DimSupplier (
    SupplierID SERIAL PRIMARY KEY,
    CompanyName VARCHAR(255),
    ContactName VARCHAR(255),
    ContactTitle VARCHAR(255),
    Address VARCHAR(255),
    City VARCHAR(255),
    Region VARCHAR(255),
    PostalCode VARCHAR(10),
    Country VARCHAR(255),
    Phone VARCHAR(20)
);

CREATE TABLE FactSales (
    SalesID SERIAL PRIMARY KEY,
    DateID INT,
    CustomerID INT,
    ProductID INT,
    EmployeeID INT,
    CategoryID INT,
    ShipperID INT,
    SupplierID INT,
    QuantitySold INT,
    UnitPrice DECIMAL(10, 2),
    Discount DECIMAL(10, 2),
    TotalAmount DECIMAL(10, 2),
    TaxAmount DECIMAL(10, 2),
    FOREIGN KEY (DateID) REFERENCES DimDate(DateID),
    FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID),
    FOREIGN KEY (EmployeeID) REFERENCES DimEmployee(EmployeeID),
    FOREIGN KEY (CategoryID) REFERENCES DimCategory(CategoryID),
    FOREIGN KEY (ShipperID) REFERENCES DimShipper(ShipperID),
    FOREIGN KEY (SupplierID) REFERENCES DimSupplier(SupplierID)
);