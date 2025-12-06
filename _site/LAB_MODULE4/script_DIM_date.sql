-- Script de création de la dimension Date
-- Génère les dates de 2020 à 2030

USE Formation_DWH;
GO

-- Création de la table Dim_Date
IF OBJECT_ID('Dim_Date', 'U') IS NOT NULL
    DROP TABLE Dim_Date;

CREATE TABLE Dim_Date (
    DateKey INT PRIMARY KEY,
    DateFull DATE NOT NULL UNIQUE,
    DayOfWeek INT NOT NULL,
    DayName VARCHAR(20) NOT NULL,
    DayOfMonth INT NOT NULL,
    DayOfYear INT NOT NULL,
    WeekOfYear INT NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    Quarter INT NOT NULL,
    QuarterName VARCHAR(10) NOT NULL,
    Year INT NOT NULL,
    IsWeekend BIT NOT NULL DEFAULT 0,
    IsHoliday BIT NOT NULL DEFAULT 0,
    HolidayName VARCHAR(50) NULL,
    
    -- Colonnes pour analyse fiscale
    FiscalMonth INT NULL,
    FiscalQuarter INT NULL,
    FiscalYear INT NULL,
    FiscalYearName VARCHAR(20) NULL,
    
    -- Flags pour analyses courantes
    IsFirstDayOfMonth BIT NOT NULL DEFAULT 0,
    IsLastDayOfMonth BIT NOT NULL DEFAULT 0,
    IsFirstDayOfYear BIT NOT NULL DEFAULT 0,
    IsLastDayOfYear BIT NOT NULL DEFAULT 0,
    
    -- Pour les calculs YTD
    DayNumberInYear INT NOT NULL,
    WeekNumberInYear INT NOT NULL
);

-- Index pour améliorer les performances
CREATE INDEX IX_Dim_Date_Year ON Dim_Date(Year);
CREATE INDEX IX_Dim_Date_YearMonth ON Dim_Date(Year, Month);
CREATE INDEX IX_Dim_Date_DateFull ON Dim_Date(DateFull);
CREATE INDEX IX_Dim_Date_Quarter ON Dim_Date(Quarter, Year);

-- Procédure de remplissage
DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate DATE = '2030-12-31';
DECLARE @CurrentDate DATE = @StartDate;

-- Table temporaire pour jours fériés français (exemples)
DECLARE @Holidays TABLE (
    HolidayDate DATE,
    HolidayName VARCHAR(50)
);

INSERT INTO @Holidays VALUES
('2024-01-01', 'Nouvel An'),
('2024-04-01', 'Lundi de Pâques'),
('2024-05-01', 'Fête du Travail'),
('2024-05-08', 'Victoire 1945'),
('2024-05-09', 'Ascension'),
('2024-05-20', 'Lundi de Pentecôte'),
('2024-07-14', 'Fête Nationale'),
('2024-08-15', 'Assomption'),
('2024-11-01', 'Toussaint'),
('2024-11-11', 'Armistice 1918'),
('2024-12-25', 'Noël');

-- Utilisation d'une CTE récursive pour générer toutes les dates
WITH DateCTE AS (
    SELECT 
        @StartDate AS DateValue,
        1 AS Level
    UNION ALL
    SELECT 
        DATEADD(DAY, 1, DateValue),
        Level + 1
    FROM DateCTE
    WHERE DateValue < @EndDate
)
INSERT INTO Dim_Date (
    DateKey, DateFull, DayOfWeek, DayName, DayOfMonth, 
    DayOfYear, WeekOfYear, Month, MonthName, Quarter, 
    QuarterName, Year, IsWeekend, IsHoliday, HolidayName,
    IsFirstDayOfMonth, IsLastDayOfMonth,
    IsFirstDayOfYear, IsLastDayOfYear,
    DayNumberInYear, WeekNumberInYear
)
SELECT
    -- DateKey au format YYYYMMDD
    CONVERT(INT, CONVERT(VARCHAR, DateValue, 112)) AS DateKey,
    DateValue AS DateFull,
    
    -- Informations jour
    DATEPART(WEEKDAY, DateValue) AS DayOfWeek,
    DATENAME(WEEKDAY, DateValue) AS DayName,
    DATEPART(DAY, DateValue) AS DayOfMonth,
    DATEPART(DAYOFYEAR, DateValue) AS DayOfYear,
    
    -- Informations semaine
    DATEPART(WEEK, DateValue) AS WeekOfYear,
    
    -- Informations mois
    DATEPART(MONTH, DateValue) AS Month,
    DATENAME(MONTH, DateValue) AS MonthName,
    
    -- Informations trimestre
    DATEPART(QUARTER, DateValue) AS Quarter,
    'T' + CAST(DATEPART(QUARTER, DateValue) AS VARCHAR) AS QuarterName,
    
    -- Année
    DATEPART(YEAR, DateValue) AS Year,
    
    -- Flags spéciaux
    CASE WHEN DATEPART(WEEKDAY, DateValue) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
    
    -- Jours fériés
    CASE WHEN h.HolidayDate IS NOT NULL THEN 1 ELSE 0 END AS IsHoliday,
    h.HolidayName,
    
    -- Flags temporels
    CASE WHEN DAY(DateValue) = 1 THEN 1 ELSE 0 END AS IsFirstDayOfMonth,
    CASE WHEN DateValue = EOMONTH(DateValue) THEN 1 ELSE 0 END AS IsLastDayOfMonth,
    CASE WHEN DateValue = DATEFROMPARTS(YEAR(DateValue), 1, 1) THEN 1 ELSE 0 END AS IsFirstDayOfYear,
    CASE WHEN DateValue = DATEFROMPARTS(YEAR(DateValue), 12, 31) THEN 1 ELSE 0 END AS IsLastDayOfYear,
    
    -- Pour calculs YTD
    DATEPART(DAYOFYEAR, DateValue) AS DayNumberInYear,
    DATEPART(WEEK, DateValue) AS WeekNumberInYear
    
FROM DateCTE d
LEFT JOIN @Holidays h ON d.DateValue = h.HolidayDate
OPTION (MAXRECURSION 0);

-- Mettre à jour l'année fiscale (exemple: année fiscale débutant en avril)
UPDATE Dim_Date 
SET 
    FiscalYear = CASE WHEN Month >= 4 THEN Year ELSE Year - 1 END,
    FiscalYearName = 'FY ' + 
        CASE 
            WHEN Month >= 4 THEN CAST(Year AS VARCHAR) 
            ELSE CAST(Year - 1 AS VARCHAR) 
        END,
    FiscalQuarter = CASE 
        WHEN Month BETWEEN 4 AND 6 THEN 1
        WHEN Month BETWEEN 7 AND 9 THEN 2
        WHEN Month BETWEEN 10 AND 12 THEN 3
        WHEN Month BETWEEN 1 AND 3 THEN 4
    END,
    FiscalMonth = CASE 
        WHEN Month >= 4 THEN Month - 3
        ELSE Month + 9
    END;

-- Vérification
SELECT TOP 10 * FROM Dim_Date ORDER BY DateFull;
SELECT 
    MIN(DateFull) AS DateMin, 
    MAX(DateFull) AS DateMax, 
    COUNT(*) AS TotalDays 
FROM Dim_Date;

PRINT 'Dimension Date créée avec succès.';