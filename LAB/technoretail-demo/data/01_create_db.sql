-- Création de la base de données TechnoRetail
CREATE DATABASE TechnoRetail_BI;
GO

USE TechnoRetail_BI;
GO

-- Table Dimension Date
CREATE TABLE DIM_Date (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    DayOfWeek VARCHAR(20) NOT NULL,
    IsWeekend BIT NOT NULL,
    IsHoliday BIT NOT NULL DEFAULT 0
);

-- Table Dimension Produit
CREATE TABLE DIM_Product (
    ProductKey INT PRIMARY KEY IDENTITY(1,1),
    ProductSKU VARCHAR(50) NOT NULL,
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    SubCategory VARCHAR(50) NOT NULL,
    Brand VARCHAR(50) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CostPrice DECIMAL(10,2) NOT NULL
);

-- Table Dimension Client
CREATE TABLE DIM_Customer (
    CustomerKey INT PRIMARY KEY IDENTITY(1,1),
    CustomerID VARCHAR(20) NOT NULL,
    CustomerName VARCHAR(100) NOT NULL,
    Email VARCHAR(100),
    Region VARCHAR(50) NOT NULL,
    City VARCHAR(50) NOT NULL,
    Segment VARCHAR(30) NOT NULL,
    RegistrationDate DATE NOT NULL
);

-- Table Dimension Magasin
CREATE TABLE DIM_Store (
    StoreKey INT PRIMARY KEY IDENTITY(1,1),
    StoreID VARCHAR(10) NOT NULL,
    StoreName VARCHAR(100) NOT NULL,
    Region VARCHAR(50) NOT NULL,
    City VARCHAR(50) NOT NULL,
    SurfaceArea INT,
    OpeningDate DATE NOT NULL
);

-- Table Dimension Canal
CREATE TABLE DIM_Channel (
    ChannelKey INT PRIMARY KEY IDENTITY(1,1),
    ChannelName VARCHAR(20) NOT NULL,
    ChannelType VARCHAR(30) NOT NULL
);

-- Table de Faits Ventes
CREATE TABLE FACT_Sales (
    SalesKey BIGINT PRIMARY KEY IDENTITY(1,1),
    DateKey INT NOT NULL,
    ProductKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    StoreKey INT NOT NULL,
    ChannelKey INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    SalesAmount DECIMAL(10,2) NOT NULL,
    CostAmount DECIMAL(10,2) NOT NULL,
    DiscountPercent DECIMAL(5,2) DEFAULT 0,
    TransactionID VARCHAR(50) NOT NULL,
    
    FOREIGN KEY (DateKey) REFERENCES DIM_Date(DateKey),
    FOREIGN KEY (ProductKey) REFERENCES DIM_Product(ProductKey),
    FOREIGN KEY (CustomerKey) REFERENCES DIM_Customer(CustomerKey),
    FOREIGN KEY (StoreKey) REFERENCES DIM_Store(StoreKey),
    FOREIGN KEY (ChannelKey) REFERENCES DIM_Channel(ChannelKey)
);

-- Table de Stocks
CREATE TABLE FACT_Stock (
    StockKey BIGINT PRIMARY KEY IDENTITY(1,1),
    DateKey INT NOT NULL,
    ProductKey INT NOT NULL,
    StoreKey INT NOT NULL,
    QuantityInStock INT NOT NULL,
    MinStockLevel INT NOT NULL,
    MaxStockLevel INT NOT NULL,
    
    FOREIGN KEY (DateKey) REFERENCES DIM_Date(DateKey),
    FOREIGN KEY (ProductKey) REFERENCES DIM_Product(ProductKey),
    FOREIGN KEY (StoreKey) REFERENCES DIM_Store(StoreKey)
);

-- Index pour optimiser les performances
CREATE INDEX IX_FACT_Sales_Date ON FACT_Sales(DateKey);
CREATE INDEX IX_FACT_Sales_Product ON FACT_Sales(ProductKey);
CREATE INDEX IX_FACT_Sales_Customer ON FACT_Sales(CustomerKey);
CREATE INDEX IX_FACT_Sales_Store ON FACT_Sales(StoreKey);
CREATE INDEX IX_FACT_Stock_Date_Product ON FACT_Stock(DateKey, ProductKey);