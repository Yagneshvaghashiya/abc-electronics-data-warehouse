-- 3.1 Create the Data Warehouse Database
CREATE DATABASE ABC_Electronics_DW;
GO

-- Use the database
USE ABC_Electronics_DW;
GO


-- 3.2 – CREATE DIMENSION TABLES
-- Verify database creation
SELECT name, database_id, create_date 
FROM sys.databases 
WHERE name = 'ABC_Electronics_DW';
GO

CREATE TABLE Dim_Date (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    DayOfWeek VARCHAR(10),
    DayOfMonth INT,
    DayOfYear INT,
    WeekOfYear INT,
    Month INT,
    MonthName VARCHAR(10),
    Quarter INT,
    Year INT,
    IsWeekend BIT
);
GO


CREATE TABLE Dim_Product (
    ProductKey INT PRIMARY KEY IDENTITY(1,1),
    ProductID VARCHAR(50) NOT NULL,
    ProductName VARCHAR(255) NOT NULL,
    ProductType VARCHAR(100),
    Brand VARCHAR(100),
    Category VARCHAR(100),
    UnitPrice DECIMAL(10,2),
    ReorderLevel INT,
    CurrentStockLevel INT,
    EffectiveDate DATE,
    ExpiryDate DATE,
    IsCurrent BIT DEFAULT 1
);
GO



CREATE TABLE Dim_Supplier (
    SupplierKey INT PRIMARY KEY IDENTITY(1,1),
    SupplierID VARCHAR(50) NOT NULL,
    SupplierName VARCHAR(255) NOT NULL,
    ContactPerson VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Email VARCHAR(100),
    Address VARCHAR(255),
    City VARCHAR(100),
    Country VARCHAR(100),
    EffectiveDate DATE,
    ExpiryDate DATE,
    IsCurrent BIT DEFAULT 1
);
GO


CREATE TABLE Dim_Location (
    LocationKey INT PRIMARY KEY IDENTITY(1,1),
    LocationID VARCHAR(50) NOT NULL,
    LocationName VARCHAR(100) NOT NULL,
    LocationType VARCHAR(50),
    Capacity INT,
    WarehouseSection VARCHAR(50),
    City VARCHAR(100)
);
GO



--3.3 
CREATE TABLE Fact_PurchaseOrder_Sent (
    PO_SentKey INT PRIMARY KEY IDENTITY(1,1),
    DateKey INT NOT NULL,
    ProductKey INT NOT NULL,
    SupplierKey INT NOT NULL,
    PurchaseOrderID VARCHAR(50) NOT NULL,
    OrderedQuantity INT NOT NULL,
    UnitPrice DECIMAL(10,2),
    OrderValue DECIMAL(12,2),
    ExpectedDeliveryDays INT
);
GO



CREATE TABLE Fact_PurchaseOrder_Received (
    PO_ReceivedKey INT PRIMARY KEY IDENTITY(1,1),
    DateKey INT NOT NULL,
    ProductKey INT NOT NULL,
    SupplierKey INT NOT NULL,
    LocationKey INT NOT NULL,
    PurchaseOrderID VARCHAR(50) NOT NULL,
    OrderedQuantity INT NOT NULL,
    ReceivedQuantity INT NOT NULL,
    DamagedQuantity INT DEFAULT 0,
    UnitPrice DECIMAL(10,2),
    TotalValue DECIMAL(12,2),
    DeliveryDelay INT
);
GO


CREATE TABLE Fact_Stock_Levels (
    StockLevelKey INT PRIMARY KEY IDENTITY(1,1),
    DateKey INT NOT NULL,
    ProductKey INT NOT NULL,
    LocationKey INT NOT NULL,
    OpeningStock INT NOT NULL,
    StockReceived INT DEFAULT 0,
    StockSold INT DEFAULT 0,
    StockAdjustment INT DEFAULT 0,
    ClosingStock INT NOT NULL,
    MinimumStockLevel INT,
    StockValue DECIMAL(12,2),
    IsUnderstock BIT,
    IsOverstock BIT
);
GO


-- 3.4 – ADD PRIMARY KEY + FOREIGN KEY CONSTRAINTS

ALTER TABLE Fact_PurchaseOrder_Sent
ADD CONSTRAINT FK_POSent_Date 
    FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey);

ALTER TABLE Fact_PurchaseOrder_Sent
ADD CONSTRAINT FK_POSent_Product 
    FOREIGN KEY (ProductKey) REFERENCES Dim_Product(ProductKey);

ALTER TABLE Fact_PurchaseOrder_Sent
ADD CONSTRAINT FK_POSent_Supplier 
    FOREIGN KEY (SupplierKey) REFERENCES Dim_Supplier(SupplierKey);
GO



ALTER TABLE Fact_PurchaseOrder_Received
ADD CONSTRAINT FK_POReceived_Date 
    FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey);

ALTER TABLE Fact_PurchaseOrder_Received
ADD CONSTRAINT FK_POReceived_Product 
    FOREIGN KEY (ProductKey) REFERENCES Dim_Product(ProductKey);

ALTER TABLE Fact_PurchaseOrder_Received
ADD CONSTRAINT FK_POReceived_Supplier 
    FOREIGN KEY (SupplierKey) REFERENCES Dim_Supplier(SupplierKey);

ALTER TABLE Fact_PurchaseOrder_Received
ADD CONSTRAINT FK_POReceived_Location 
    FOREIGN KEY (LocationKey) REFERENCES Dim_Location(LocationKey);
GO


ALTER TABLE Fact_Stock_Levels
ADD CONSTRAINT FK_StockLevel_Date 
    FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey);

ALTER TABLE Fact_Stock_Levels
ADD CONSTRAINT FK_StockLevel_Product 
    FOREIGN KEY (ProductKey) REFERENCES Dim_Product(ProductKey);

ALTER TABLE Fact_Stock_Levels
ADD CONSTRAINT FK_StockLevel_Location 
    FOREIGN KEY (LocationKey) REFERENCES Dim_Location(LocationKey);
GO



--3.5 – IMPLEMENTATION & TESTING
INSERT INTO Dim_Date 
(DateKey, FullDate, DayOfWeek, DayOfMonth, DayOfYear, WeekOfYear, Month, MonthName, Quarter, Year, IsWeekend)
VALUES 
(20241201, '2024-12-01', 'Sunday', 1, 336, 48, 12, 'December', 4, 2024, 1),
(20241202, '2024-12-02', 'Monday', 2, 337, 49, 12, 'December', 4, 2024, 0),
(20241203, '2024-12-03', 'Tuesday', 3, 338, 49, 12, 'December', 4, 2024, 0);
GO

INSERT INTO Dim_Supplier (SupplierID, SupplierName, ContactPerson, PhoneNumber, Email, City, Country, EffectiveDate, IsCurrent)
VALUES 
('SUP001', 'Samsung Electronics UK', 'John Smith', '+44-20-1234-5678', 
 'john.smith@samsung.uk', 'London', 'UK', '2024-01-01', 1),
('SUP002', 'Sony UK Limited', 'Jane Doe', '+44-20-8765-4321', 
 'jane.doe@sony.uk', 'London', 'UK', '2024-01-01', 1);
GO


INSERT INTO Dim_Product (ProductID, ProductName, ProductType, Brand, Category, UnitPrice, ReorderLevel, CurrentStockLevel, EffectiveDate, IsCurrent)
VALUES 
('PROD001', 'Samsung 55" QLED TV', 'Television', 'Samsung', 'TVs', 899.99, 10, 25, '2024-01-01', 1),
('PROD002', 'Sony WH-1000XM5 Headphones', 'Headphones', 'Sony', 'Audio', 349.99, 20, 45, '2024-01-01', 1);
GO


INSERT INTO Dim_Location (LocationID, LocationName, LocationType, Capacity, WarehouseSection, City)
VALUES 
('LOC001', 'Main Warehouse - Section A', 'Warehouse', 5000, 'A', 'London'),
('LOC002', 'Main Warehouse - Section B', 'Warehouse', 3000, 'B', 'London');
GO


INSERT INTO Fact_PurchaseOrder_Sent 
(DateKey, ProductKey, SupplierKey, PurchaseOrderID, OrderedQuantity, UnitPrice, OrderValue, ExpectedDeliveryDays)
VALUES 
(20241201, 1, 1, 'PO-2024-001', 50, 899.99, 44999.50, 7),
(20241202, 2, 2, 'PO-2024-002', 100, 349.99, 34999.00, 5);
GO


INSERT INTO Fact_PurchaseOrder_Received 
(DateKey, ProductKey, SupplierKey, LocationKey, PurchaseOrderID, OrderedQuantity, ReceivedQuantity, DamagedQuantity, UnitPrice, TotalValue, DeliveryDelay)
VALUES 
(20241203, 1, 1, 1, 'PO-2024-001', 50, 48, 2, 899.99, 43199.52, 0),
(20241203, 2, 2, 2, 'PO-2024-002', 100, 100, 0, 349.99, 34999.00, -2);
GO


INSERT INTO Fact_Stock_Levels 
(DateKey, ProductKey, LocationKey, OpeningStock, StockReceived, StockSold, StockAdjustment, ClosingStock, MinimumStockLevel, StockValue, IsUnderstock, IsOverstock)
VALUES 
(20241201, 1, 1, 25, 0, 3, 0, 22, 10, 19799.78, 0, 0),
(20241202, 1, 1, 22, 0, 5, 0, 17, 10, 15299.83, 0, 0),
(20241203, 1, 1, 17, 48, 10, -2, 53, 10, 47699.47, 0, 1);
GO

--3.6


SELECT * FROM Dim_Date;
SELECT * FROM Dim_Product;
SELECT * FROM Dim_Supplier;
SELECT * FROM Dim_Location;
GO


SELECT * FROM Fact_PurchaseOrder_Sent;
SELECT * FROM Fact_PurchaseOrder_Received;
SELECT * FROM Fact_Stock_Levels;
GO


SELECT * FROM INFORMATION_SCHEMA.TABLES;
GO

SELECT 
    fk.name AS ForeignKey_Name, 
    tp.name AS Parent_Table,
    tr.name AS Referenced_Table
FROM sys.foreign_keys fk
JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id;
GO




SELECT 
    d.FullDate,
    p.ProductName,
    l.LocationName,
    f.OpeningStock,
    f.StockReceived,
    f.StockSold,
    f.StockAdjustment,
    f.ClosingStock
FROM Fact_Stock_Levels f
JOIN Dim_Date d ON f.DateKey = d.DateKey
JOIN Dim_Product p ON f.ProductKey = p.ProductKey
JOIN Dim_Location l ON f.LocationKey = l.LocationKey
ORDER BY d.FullDate, p.ProductName;



SELECT 
    s.SupplierName,
    d.Month,
    d.Year,
    COUNT(r.PO_ReceivedKey) AS TotalOrdersReceived,
    SUM(r.ReceivedQuantity) AS TotalUnitsReceived,
    SUM(r.TotalValue) AS TotalValueReceived
FROM Fact_PurchaseOrder_Received r
JOIN Dim_Date d ON r.DateKey = d.DateKey
JOIN Dim_Supplier s ON r.SupplierKey = s.SupplierKey
GROUP BY s.SupplierName, d.Month, d.Year
ORDER BY d.Year, d.Month, s.SupplierName;




SELECT 
    p.Brand,
    SUM(f.ClosingStock) AS TotalClosingStock,
    SUM(f.StockValue) AS TotalStockValue
FROM Fact_Stock_Levels f
JOIN Dim_Product p ON f.ProductKey = p.ProductKey
GROUP BY p.Brand
ORDER BY TotalClosingStock DESC;


SELECT
    d.FullDate,
    d.WeekOfYear,
    d.Year,
    COUNT(DISTINCT s.PurchaseOrderID) AS SentOrders,
    COUNT(DISTINCT r.PurchaseOrderID) AS ReceivedOrders
FROM Dim_Date d
LEFT JOIN Fact_PurchaseOrder_Sent s ON d.DateKey = s.DateKey
LEFT JOIN Fact_PurchaseOrder_Received r ON d.DateKey = r.DateKey
GROUP BY d.FullDate, d.WeekOfYear, d.Year
ORDER BY d.FullDate;



SELECT 
    d.FullDate,
    p.ProductName,
    l.LocationName,
    f.ClosingStock,
    f.MinimumStockLevel,
    CASE 
        WHEN f.IsUnderstock = 1 THEN 'UNDER-STOCK'
        WHEN f.IsOverstock = 1 THEN 'OVER-STOCK'
        ELSE 'NORMAL'
    END AS StockStatus
FROM Fact_Stock_Levels f
JOIN Dim_Date d ON f.DateKey = d.DateKey
JOIN Dim_Product p ON f.ProductKey = p.ProductKey
JOIN Dim_Location l ON f.LocationKey = l.LocationKey
WHERE f.IsUnderstock = 1 OR f.IsOverstock = 1
ORDER BY d.FullDate, p.ProductName;
