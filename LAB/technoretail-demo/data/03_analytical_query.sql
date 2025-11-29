USE TechnoRetail_BI;
GO

-- 1. KPI : Chiffre d'Affaires par Mois et Canal
SELECT 
    d.Year,
    d.Month,
    d.MonthName,
    c.ChannelName,
    SUM(fs.SalesAmount) AS TotalSales,
    SUM(fs.Quantity) AS TotalQuantity,
    COUNT(DISTINCT fs.TransactionID) AS NumberOfTransactions
FROM FACT_Sales fs
JOIN DIM_Date d ON fs.DateKey = d.DateKey
JOIN DIM_Channel c ON fs.ChannelKey = c.ChannelKey
GROUP BY d.Year, d.Month, d.MonthName, c.ChannelName
ORDER BY d.Year, d.Month, c.ChannelName;

-- 2. KPI : Performance des Produits par Catégorie
SELECT 
    p.Category,
    p.SubCategory,
    p.Brand,
    COUNT(fs.SalesKey) AS SalesCount,
    SUM(fs.SalesAmount) AS TotalRevenue,
    SUM(fs.SalesAmount - fs.CostAmount) AS TotalMargin,
    AVG(fs.SalesAmount - fs.CostAmount) AS AvgMarginPerUnit
FROM FACT_Sales fs
JOIN DIM_Product p ON fs.ProductKey = p.ProductKey
GROUP BY p.Category, p.SubCategory, p.Brand
ORDER BY TotalRevenue DESC;

-- 3. KPI : Analyse des Stocks et Ruptures
SELECT 
    s.StoreName,
    s.City,
    p.ProductName,
    st.QuantityInStock,
    st.MinStockLevel,
    st.MaxStockLevel,
    CASE 
        WHEN st.QuantityInStock = 0 THEN 'RUPTURE'
        WHEN st.QuantityInStock <= st.MinStockLevel THEN 'STOCK FAIBLE'
        ELSE 'STOCK OK'
    END AS StockStatus
FROM FACT_Stock st
JOIN DIM_Store s ON st.StoreKey = s.StoreKey
JOIN DIM_Product p ON st.ProductKey = p.ProductKey
JOIN DIM_Date d ON st.DateKey = d.DateKey
WHERE d.FullDate = '2024-06-15'
ORDER BY StockStatus, s.StoreName;

-- 4. KPI : Analyse Client (RFM Simplifié)
WITH CustomerRFM AS (
    SELECT 
        c.CustomerKey,
        c.CustomerName,
        c.Segment,
        MAX(d.FullDate) AS LastPurchaseDate,
        DATEDIFF(DAY, MAX(d.FullDate), GETDATE()) AS Recency,
        COUNT(fs.SalesKey) AS Frequency,
        SUM(fs.SalesAmount) AS Monetary
    FROM FACT_Sales fs
    JOIN DIM_Customer c ON fs.CustomerKey = c.CustomerKey
    JOIN DIM_Date d ON fs.DateKey = d.DateKey
    GROUP BY c.CustomerKey, c.CustomerName, c.Segment
)
SELECT 
    CustomerName,
    Segment,
    LastPurchaseDate,
    Recency,
    Frequency,
    Monetary,
    CASE 
        WHEN Recency <= 30 THEN 'ACTIF'
        WHEN Recency <= 90 THEN 'MOYEN'
        ELSE 'INACTIF'
    END AS RecencySegment,
    CASE 
        WHEN Monetary > 2000 THEN 'HAUTE VALEUR'
        WHEN Monetary > 1000 THEN 'MOYENNE VALEUR'
        ELSE 'FAIBLE VALEUR'
    END AS ValueSegment
FROM CustomerRFM
ORDER BY Monetary DESC;

-- 5. KPI : Performance des Magasins
SELECT 
    s.StoreName,
    s.Region,
    s.City,
    COUNT(fs.SalesKey) AS TotalSales,
    SUM(fs.SalesAmount) AS TotalRevenue,
    SUM(fs.SalesAmount - fs.CostAmount) AS TotalMargin,
    AVG(fs.SalesAmount) AS AvgTransactionValue,
    COUNT(DISTINCT fs.CustomerKey) AS UniqueCustomers
FROM FACT_Sales fs
JOIN DIM_Store s ON fs.StoreKey = s.StoreKey
GROUP BY s.StoreName, s.Region, s.City
ORDER BY TotalRevenue DESC;