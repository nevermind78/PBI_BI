USE TechnoRetail_BI;
GO


-- Insertion des dates COMPLÈTES (2023-2024)
INSERT INTO DIM_Date (DateKey, FullDate, Year, Quarter, Month, MonthName, DayOfWeek, IsWeekend)
VALUES 
-- 2023
(20230101, '2023-01-01', 2023, 1, 1, 'January', 'Sunday', 1),
(20230102, '2023-01-02', 2023, 1, 1, 'January', 'Monday', 0),
(20230115, '2023-01-15', 2023, 1, 1, 'January', 'Sunday', 1),
(20230201, '2023-02-01', 2023, 1, 2, 'February', 'Wednesday', 0),
(20230301, '2023-03-01', 2023, 1, 3, 'March', 'Wednesday', 0),
(20230615, '2023-06-15', 2023, 2, 6, 'June', 'Thursday', 0),
(20230901, '2023-09-01', 2023, 3, 9, 'September', 'Friday', 0),
(20231231, '2023-12-31', 2023, 4, 12, 'December', 'Sunday', 1),
-- 2024
(20240101, '2024-01-01', 2024, 1, 1, 'January', 'Monday', 0),
(20240115, '2024-01-15', 2024, 1, 1, 'January', 'Monday', 0),
(20240201, '2024-02-01', 2024, 1, 2, 'February', 'Thursday', 0),
(20240301, '2024-03-01', 2024, 1, 3, 'March', 'Friday', 0),
(20240615, '2024-06-15', 2024, 2, 6, 'June', 'Saturday', 1),
(20240901, '2024-09-01', 2024, 3, 9, 'September', 'Sunday', 1),
(20241231, '2024-12-31', 2024, 4, 12, 'December', 'Tuesday', 0);

-- Insertion des canaux (mêmes données)
INSERT INTO DIM_Channel (ChannelName, ChannelType)
VALUES 
('Store', 'Physical'),
('Web', 'Digital'),
('Mobile', 'Digital');

-- Insertion des produits (mêmes données)
INSERT INTO DIM_Product (ProductSKU, ProductName, Category, SubCategory, Brand, UnitPrice, CostPrice)
VALUES
('SM-G990', 'Smartphone Galaxy', 'Electronics', 'Phones', 'Samsung', 899.99, 650.00),
('IP-14-128', 'iPhone 14 128GB', 'Electronics', 'Phones', 'Apple', 989.99, 750.00),
('TV-LG-55', 'TV LG 55" 4K', 'Electronics', 'TV & Video', 'LG', 699.99, 520.00),
('LAP-DEL-XPS', 'Laptop Dell XPS', 'Computing', 'Laptops', 'Dell', 1299.99, 980.00),
('TAB-S7', 'Tablet S7', 'Electronics', 'Tablets', 'Samsung', 499.99, 380.00);

-- Insertion des magasins (mêmes données)
INSERT INTO DIM_Store (StoreID, StoreName, Region, City, SurfaceArea, OpeningDate)
VALUES
('PAR01', 'Paris Centre', 'Ile-de-France', 'Paris', 450, '2020-03-15'),
('LYO01', 'Lyon Part-Dieu', 'Auvergne-Rhone-Alpes', 'Lyon', 380, '2019-06-10'),
('MAR01', 'Marseille Vieux Port', 'Provence-Alpes-Cote d''Azur', 'Marseille', 320, '2021-01-20'),
('BOR01', 'Bordeaux Centre', 'Nouvelle-Aquitaine', 'Bordeaux', 300, '2022-05-05');

-- Insertion des clients (mêmes données)
INSERT INTO DIM_Customer (CustomerID, CustomerName, Email, Region, City, Segment, RegistrationDate)
VALUES
('CUST001', 'Marie Dubois', 'marie.dubois@email.com', 'Ile-de-France', 'Paris', 'Premium', '2022-01-15'),
('CUST002', 'Pierre Martin', 'pierre.martin@email.com', 'Auvergne-Rhone-Alpes', 'Lyon', 'Standard', '2023-03-20'),
('CUST003', 'Sophie Bernard', 'sophie.bernard@email.com', 'Provence-Alpes-Cote d''Azur', 'Marseille', 'Premium', '2021-11-08'),
('CUST004', 'Lucas Petit', 'lucas.petit@email.com', 'Nouvelle-Aquitaine', 'Bordeaux', 'Standard', '2023-07-12');

-- Insertion des ventes ÉTENDUES (2023 et 2024)
INSERT INTO FACT_Sales (DateKey, ProductKey, CustomerKey, StoreKey, ChannelKey, Quantity, UnitPrice, SalesAmount, CostAmount, DiscountPercent, TransactionID)
VALUES
-- Ventes 2023
(20230101, 1, 1, 1, 1, 2, 899.99, 1799.98, 1300.00, 5.0, 'TXN001'),
(20230102, 2, 2, 2, 1, 1, 989.99, 989.99, 750.00, 0.0, 'TXN002'),
(20230115, 3, 3, 3, 2, 1, 699.99, 699.99, 520.00, 10.0, 'TXN003'),
(20230201, 4, 4, 4, 3, 1, 1299.99, 1299.99, 980.00, 0.0, 'TXN004'),
(20230615, 1, 1, 1, 1, 1, 899.99, 899.99, 650.00, 5.0, 'TXN005'),
(20230901, 2, 2, 2, 2, 2, 989.99, 1979.98, 1500.00, 0.0, 'TXN006'),
-- Ventes 2024
(20240101, 1, 1, 1, 1, 3, 899.99, 2699.97, 1950.00, 8.0, 'TXN007'),
(20240115, 3, 3, 3, 2, 2, 699.99, 1399.98, 1040.00, 0.0, 'TXN008'),
(20240201, 4, 4, 4, 3, 1, 1299.99, 1299.99, 980.00, 10.0, 'TXN009'),
(20240301, 2, 2, 2, 1, 1, 989.99, 989.99, 750.00, 0.0, 'TXN010'),
(20240615, 1, 1, 1, 2, 2, 899.99, 1799.98, 1300.00, 5.0, 'TXN011'),
(20240901, 3, 3, 3, 1, 1, 699.99, 699.99, 520.00, 0.0, 'TXN012');

-- Insertion des stocks MIS À JOUR
INSERT INTO FACT_Stock (DateKey, ProductKey, StoreKey, QuantityInStock, MinStockLevel, MaxStockLevel)
VALUES
-- Stocks 2023
(20230101, 1, 1, 20, 5, 50),
(20230101, 2, 1, 15, 3, 30),
(20230615, 1, 1, 8, 5, 50),
(20230615, 2, 1, 12, 3, 30),
-- Stocks 2024
(20240101, 1, 1, 15, 5, 50),
(20240101, 2, 1, 8, 3, 30),
(20240101, 3, 1, 12, 4, 40),
(20240101, 1, 2, 10, 5, 35),
(20240101, 2, 2, 6, 3, 25),
(20240615, 1, 1, 3, 5, 50),  -- Stock faible
(20240615, 2, 1, 15, 3, 30);