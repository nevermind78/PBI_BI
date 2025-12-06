-- Script d'analyse YTD (Year-To-Date) et YoY (Year-Over-Year)
-- Calculs temporels avancés pour Business Intelligence

USE Formation_DWH;
GO

-- ============================================
-- 1. CRÉATION DE LA TABLE DE FAITS VENTES
-- ============================================
PRINT 'Création de la table de faits Ventes...';

IF OBJECT_ID('Fact_Ventes', 'U') IS NOT NULL
    DROP TABLE Fact_Ventes;

CREATE TABLE Fact_Ventes (
    VenteKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Clés étrangères
    DateKey INT NOT NULL,
    ProduitKey INT NOT NULL,
    ClientKey INT NOT NULL,
    RegionKey INT NOT NULL,
    
    -- Mesures
    Quantite INT NOT NULL,
    PrixUnitaire DECIMAL(10,2) NOT NULL,
    MontantHT DECIMAL(10,2) NOT NULL,
    MontantTTC DECIMAL(10,2) NOT NULL,
    CoutUnitaire DECIMAL(10,2),
    MargeUnitaire DECIMAL(10,2) AS (PrixUnitaire - CoutUnitaire),
    
    -- Informations transaction
    NumeroTicket VARCHAR(50),
    ModePaiement VARCHAR(20),
    
    -- Métadonnées
    DateChargement DATETIME DEFAULT GETDATE(),
    
    -- Contraintes
    CONSTRAINT FK_Ventes_Date FOREIGN KEY (DateKey) 
        REFERENCES Dim_Date(DateKey),
    CONSTRAINT FK_Ventes_Produit FOREIGN KEY (ProduitKey) 
        REFERENCES Dim_Produit(ProduitKey),
    CONSTRAINT FK_Ventes_Region FOREIGN KEY (RegionKey) 
        REFERENCES Dim_Region(RegionKey)
);

-- Index pour performances
CREATE INDEX IX_Fact_Ventes_Date ON Fact_Ventes(DateKey);
CREATE INDEX IX_Fact_Ventes_Produit ON Fact_Ventes(ProduitKey);
CREATE INDEX IX_Fact_Ventes_Region ON Fact_Ventes(RegionKey);
CREATE INDEX IX_Fact_Ventes_DateProduit ON Fact_Ventes(DateKey, ProduitKey);

-- ============================================
-- 2. PEUPLEMENT AVEC DONNÉES DE TEST
-- ============================================
PRINT 'Peuplement avec des données de test (2023-2024)...';

-- Insertion de données de vente pour 2023 et 2024
-- Note: Dans un cas réel, ces données viendraient d'un ETL

DECLARE @DateCourante DATE = '2023-01-01';
DECLARE @Fin2024 DATE = '2024-12-31';
DECLARE @Compteur INT = 0;

-- Boucle pour générer des ventes sur 2 ans
WHILE @DateCourante <= @Fin2024
BEGIN
    -- Générer entre 5 et 15 ventes par jour
    DECLARE @VentesParJour INT = 5 + ABS(CHECKSUM(NEWID())) % 11;
    DECLARE @VenteIndex INT = 1;
    
    WHILE @VenteIndex <= @VentesParJour
    BEGIN
        -- Données aléatoires pour la démonstration
        DECLARE @ProduitKey INT = 1 + ABS(CHECKSUM(NEWID())) % 8;
        DECLARE @RegionKey INT = 1 + ABS(CHECKSUM(NEWID())) % 8;
        DECLARE @Quantite INT = 1 + ABS(CHECKSUM(NEWID())) % 5;
        
        -- Récupérer le prix unitaire depuis Dim_Produit
        DECLARE @PrixUnitaire DECIMAL(10,2);
        DECLARE @CoutUnitaire DECIMAL(10,2);
        
        SELECT 
            @PrixUnitaire = PrixUnitaire,
            @CoutUnitaire = CoutUnitaire
        FROM Dim_Produit 
        WHERE ProduitKey = @ProduitKey;
        
        -- Calculer les montants
        DECLARE @MontantHT DECIMAL(10,2) = @PrixUnitaire * @Quantite;
        DECLARE @MontantTTC DECIMAL(10,2) = @MontantHT * 1.20; -- TVA 20%
        
        -- Récupérer la DateKey
        DECLARE @DateKey INT = CONVERT(INT, CONVERT(VARCHAR, @DateCourante, 112));
        
        -- S'assurer que la date existe dans Dim_Date
        IF EXISTS (SELECT 1 FROM Dim_Date WHERE DateKey = @DateKey)
        BEGIN
            INSERT INTO Fact_Ventes (
                DateKey, ProduitKey, ClientKey, RegionKey,
                Quantite, PrixUnitaire, MontantHT, MontantTTC, CoutUnitaire,
                NumeroTicket, ModePaiement
            ) VALUES (
                @DateKey,
                @ProduitKey,
                1 + ABS(CHECKSUM(NEWID())) % 1000, -- Client aléatoire
                @RegionKey,
                @Quantite,
                @PrixUnitaire,
                @MontantHT,
                @MontantTTC,
                @CoutUnitaire,
                'TICKET-' + CAST(@Compteur AS VARCHAR),
                CASE WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN 'Carte' 
                     WHEN ABS(CHECKSUM(NEWID())) % 3 = 1 THEN 'Espèces' 
                     ELSE 'Virement' END
            );
            
            SET @Compteur = @Compteur + 1;
        END
        
        SET @VenteIndex = @VenteIndex + 1;
    END
    
    SET @DateCourante = DATEADD(DAY, 1, @DateCourante);
END

PRINT CAST(@Compteur AS VARCHAR) + ' ventes générées.';

-- ============================================
-- 3. CALCULS YTD (YEAR-TO-DATE)
-- ============================================
PRINT '=== CALCULS YTD (YEAR-TO-DATE) ===';

-- 3.1 Vue YTD de base
IF OBJECT_ID('vw_Ventes_YTD', 'V') IS NOT NULL
    DROP VIEW vw_Ventes_YTD;
GO

CREATE VIEW vw_Ventes_YTD AS
WITH VentesJournalieres AS (
    SELECT 
        d.DateKey,
        d.DateFull,
        d.Year,
        d.Month,
        d.MonthName,
        d.DayOfYear,
        SUM(v.MontantHT) AS CA_Journalier,
        SUM(v.Quantite) AS Quantite_Journaliere,
        COUNT(DISTINCT v.VenteKey) AS Transactions_Journalieres
    FROM Fact_Ventes v
    JOIN Dim_Date d ON v.DateKey = d.DateKey
    GROUP BY d.DateKey, d.DateFull, d.Year, d.Month, d.MonthName, d.DayOfYear
)
SELECT
    DateFull,
    Year,
    Month,
    MonthName,
    DayOfYear,
    CA_Journalier,
    Quantite_Journaliere,
    Transactions_Journalieres,
    -- Cumul YTD
    SUM(CA_Journalier) OVER (
        PARTITION BY Year 
        ORDER BY DateFull 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CA_YTD,
    SUM(Quantite_Journaliere) OVER (
        PARTITION BY Year 
        ORDER BY DateFull 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Quantite_YTD,
    -- Objectif YTD (exemple: objectif annuel / 365 * jour de l'année)
    (1000000.0 / 365.0 * DayOfYear) AS Objectif_YTD,
    -- Pourcentage de réalisation
    CASE 
        WHEN (1000000.0 / 365.0 * DayOfYear) > 0 
        THEN (SUM(CA_Journalier) OVER (
                PARTITION BY Year 
                ORDER BY DateFull 
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
              ) / (1000000.0 / 365.0 * DayOfYear)) * 100 
        ELSE NULL 
    END AS Realisation_YTD_Percent
FROM VentesJournalieres;
GO

-- Test de la vue YTD
PRINT 'Vue YTD - Derniers 5 jours de 2024:';
SELECT TOP 5 * 
FROM vw_Ventes_YTD 
WHERE Year = 2024 
ORDER BY DateFull DESC;

-- ============================================
-- 4. CALCULS YOY (YEAR-OVER-YEAR)
-- ============================================
PRINT '=== CALCULS YOY (YEAR-OVER-YEAR) ===';

-- 4.1 Vue YoY de base
IF OBJECT_ID('vw_Ventes_YoY', 'V') IS NOT NULL
    DROP VIEW vw_Ventes_YoY;
GO

CREATE VIEW vw_Ventes_YoY AS
WITH VentesMensuelles AS (
    SELECT 
        d.Year,
        d.Month,
        d.MonthName,
        SUM(v.MontantHT) AS CA_Mensuel,
        SUM(v.Quantite) AS Quantite_Mensuelle,
        COUNT(DISTINCT v.VenteKey) AS Transactions_Mensuelles,
        COUNT(DISTINCT v.ClientKey) AS Clients_Uniques
    FROM Fact_Ventes v
    JOIN Dim_Date d ON v.DateKey = d.DateKey
    GROUP BY d.Year, d.Month, d.MonthName
),
YoYComparison AS (
    SELECT
        Year,
        Month,
        MonthName,
        CA_Mensuel,
        Quantite_Mensuelle,
        Transactions_Mensuelles,
        Clients_Uniques,
        -- Valeurs de l'année précédente (même mois)
        LAG(CA_Mensuel, 12) OVER (ORDER BY Year, Month) AS CA_Mensuel_N_1,
        LAG(Quantite_Mensuelle, 12) OVER (ORDER BY Year, Month) AS Quantite_Mensuelle_N_1,
        LAG(Transactions_Mensuelles, 12) OVER (ORDER BY Year, Month) AS Transactions_Mensuelles_N_1,
        -- Cumul YTD
        SUM(CA_Mensuel) OVER (PARTITION BY Year ORDER BY Month) AS CA_YTD,
        SUM(Quantite_Mensuelle) OVER (PARTITION BY Year ORDER BY Month) AS Quantite_YTD,
        -- Cumul YTD année précédente (même mois)
        SUM(CA_Mensuel) OVER (PARTITION BY Year ORDER BY Month) - CA_Mensuel 
            + ISNULL(LAG(CA_Mensuel, 12) OVER (ORDER BY Year, Month), 0) AS CA_YTD_N_1_Estime
    FROM VentesMensuelles
)
SELECT
    Year,
    Month,
    MonthName,
    CA_Mensuel,
    Quantite_Mensuelle,
    Transactions_Mensuelles,
    Clients_Uniques,
    CA_Mensuel_N_1,
    Quantite_Mensuelle_N_1,
    CA_YTD,
    CA_YTD_N_1_Estime,
    -- Évolution mensuelle YoY
    CASE 
        WHEN CA_Mensuel_N_1 > 0 
        THEN (CA_Mensuel - CA_Mensuel_N_1) / CA_Mensuel_N_1 * 100 
        ELSE NULL 
    END AS Evolution_Mensuelle_YoY_Percent,
    -- Évolution YTD YoY
    CASE 
        WHEN CA_YTD_N_1_Estime > 0 
        THEN (CA_YTD - CA_YTD_N_1_Estime) / CA_YTD_N_1_Estime * 100 
        ELSE NULL 
    END AS Evolution_YTD_YoY_Percent,
    -- Variation absolue
    CA_Mensuel - CA_Mensuel_N_1 AS Delta_CA_Mensuel,
    CA_YTD - CA_YTD_N_1_Estime AS Delta_CA_YTD
FROM YoYComparison
WHERE Year >= 2023;
GO

-- Test de la vue YoY
PRINT 'Vue YoY - Comparaison 2023 vs 2024:';
SELECT * 
FROM vw_Ventes_YoY 
WHERE Year IN (2023, 2024) 
ORDER BY Year, Month;

-- ============================================
-- 5. ANALYSE YTD/YOY AVANCÉE PAR CATÉGORIE
-- ============================================
PRINT '=== ANALYSE YTD/YOY PAR CATÉGORIE ===';

-- 5.1 Vue détaillée par catégorie
IF OBJECT_ID('vw_Ventes_YTD_YoY_Detail', 'V') IS NOT NULL
    DROP VIEW vw_Ventes_YTD_YoY_Detail;
GO

CREATE VIEW vw_Ventes_YTD_YoY_Detail AS
WITH VentesMensuellesDetail AS (
    SELECT 
        d.Year,
        d.Month,
        p.Categorie,
        p.Departement,
        SUM(v.MontantHT) AS CA_Mensuel,
        SUM(v.Quantite) AS Quantite_Mensuelle,
        COUNT(DISTINCT v.VenteKey) AS Transactions
    FROM Fact_Ventes v
    JOIN Dim_Date d ON v.DateKey = d.DateKey
    JOIN Dim_Produit p ON v.ProduitKey = p.ProduitKey
    GROUP BY d.Year, d.Month, p.Categorie, p.Departement
),
AvecYTD AS (
    SELECT
        Year,
        Month,
        Categorie,
        Departement,
        CA_Mensuel,
        Quantite_Mensuelle,
        Transactions,
        -- Cumul YTD par catégorie
        SUM(CA_Mensuel) OVER (
            PARTITION BY Year, Categorie 
            ORDER BY Month 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CA_YTD_Categorie,
        -- Cumul YTD total
        SUM(CA_Mensuel) OVER (
            PARTITION BY Year 
            ORDER BY Month 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CA_YTD_Total
    FROM VentesMensuellesDetail
),
AvecYoY AS (
    SELECT
        *,
        -- CA même mois année précédente
        LAG(CA_Mensuel, 12) OVER (
            PARTITION BY Categorie 
            ORDER BY Year, Month
        ) AS CA_Mensuel_N_1,
        -- CA YTD année précédente
        LAG(CA_YTD_Categorie, 12) OVER (
            PARTITION BY Categorie 
            ORDER BY Year, Month
        ) AS CA_YTD_Categorie_N_1
    FROM AvecYTD
)
SELECT
    Year,
    Month,
    Categorie,
    Departement,
    CA_Mensuel,
    Quantite_Mensuelle,
    Transactions,
    CA_YTD_Categorie,
    CA_YTD_Total,
    CA_Mensuel_N_1,
    CA_YTD_Categorie_N_1,
    -- Évolutions
    CASE 
        WHEN CA_Mensuel_N_1 > 0 
        THEN (CA_Mensuel - CA_Mensuel_N_1) / CA_Mensuel_N_1 * 100 
        ELSE NULL 
    END AS Evolution_Mensuelle_YoY_Percent,
    CASE 
        WHEN CA_YTD_Categorie_N_1 > 0 
        THEN (CA_YTD_Categorie - CA_YTD_Categorie_N_1) / CA_YTD_Categorie_N_1 * 100 
        ELSE NULL 
    END AS Evolution_YTD_YoY_Percent,
    -- Contribution au total
    CA_Mensuel * 100.0 / NULLIF(CA_YTD_Total, 0) AS Contribution_Mensuelle_Percent,
    CA_YTD_Categorie * 100.0 / NULLIF(CA_YTD_Total, 0) AS Contribution_YTD_Percent
FROM AvecYoY
WHERE Year >= 2023;
GO

-- Test de la vue détaillée
PRINT 'Vue détaillée - Top catégories 2024:';
SELECT TOP 10 *
FROM vw_Ventes_YTD_YoY_Detail 
WHERE Year = 2024 AND Month = 12
ORDER BY CA_Mensuel DESC;

-- ============================================
-- 6. FONCTIONS UTILITAIRES POUR YTD/YOY
-- ============================================

-- 6.1 Fonction pour calculer YTD jusqu'à une date donnée
IF OBJECT_ID('fn_Calculate_YTD', 'FN') IS NOT NULL
    DROP FUNCTION fn_Calculate_YTD;
GO

CREATE FUNCTION fn_Calculate_YTD (
    @Year INT,
    @AsOfDate DATE = NULL
)
RETURNS TABLE
AS
RETURN (
    WITH DateRange AS (
        SELECT 
            DateKey,
            DateFull,
            Year,
            DayOfYear
        FROM Dim_Date
        WHERE Year = @Year
          AND (@AsOfDate IS NULL OR DateFull <= @AsOfDate)
    )
    SELECT
        @Year AS Year,
        MAX(dr.DateFull) AS DateFinPeriode,
        MIN(dr.DateFull) AS DateDebutAnnee,
        COUNT(DISTINCT dr.DateKey) AS JoursDansPeriode,
        SUM(v.MontantHT) AS CA_YTD,
        SUM(v.Quantite) AS Quantite_YTD,
        COUNT(DISTINCT v.VenteKey) AS Transactions_YTD,
        COUNT(DISTINCT v.ClientKey) AS Clients_YTD
    FROM Fact_Ventes v
    JOIN DateRange dr ON v.DateKey = dr.DateKey
);
GO

-- 6.2 Fonction pour calculer YoY pour un mois donné
IF OBJECT_ID('fn_Calculate_YoY_Month', 'FN') IS NOT NULL
    DROP FUNCTION fn_Calculate_YoY_Month;
GO

CREATE FUNCTION fn_Calculate_YoY_Month (
    @Year INT,
    @Month INT
)
RETURNS TABLE
AS
RETURN (
    WITH CurrentMonth AS (
        SELECT 
            Year,
            Month,
            SUM(MontantHT) AS CA_Mois,
            SUM(Quantite) AS Quantite_Mois
        FROM Fact_Ventes v
        JOIN Dim_Date d ON v.DateKey = d.DateKey
        WHERE d.Year = @Year AND d.Month = @Month
        GROUP BY d.Year, d.Month
    ),
    PreviousYearMonth AS (
        SELECT 
            Year,
            Month,
            SUM(MontantHT) AS CA_Mois_N_1,
            SUM(Quantite) AS Quantite_Mois_N_1
        FROM Fact_Ventes v
        JOIN Dim_Date d ON v.DateKey = d.DateKey
        WHERE d.Year = @Year - 1 AND d.Month = @Month
        GROUP BY d.Year, d.Month
    )
    SELECT
        cm.Year AS Annee_Actuelle,
        cm.Month AS Mois,
        cm.CA_Mois,
        cm.Quantite_Mois,
        pym.CA_Mois_N_1,
        pym.Quantite_Mois_N_1,
        CASE 
            WHEN pym.CA_Mois_N_1 > 0 
            THEN (cm.CA_Mois - pym.CA_Mois_N_1) / pym.CA_Mois_N_1 * 100 
            ELSE NULL 
        END AS Evolution_YoY_Percent,
        cm.CA_Mois - pym.CA_Mois_N_1 AS Delta_CA
    FROM CurrentMonth cm
    LEFT JOIN PreviousYearMonth pym ON cm.Month = pym.Month
);
GO

-- ============================================
-- 7. REQUÊTES DE DÉMONSTRATION
-- ============================================
PRINT '=== REQUÊTES DE DÉMONSTRATION YTD/YOY ===';

PRINT '1. YTD au 30 juin 2024:';
SELECT * FROM fn_Calculate_YTD(2024, '2024-06-30');

PRINT '2. YoY pour décembre 2024 vs décembre 2023:';
SELECT * FROM fn_Calculate_YoY_Month(2024, 12);

PRINT '3. Tableau de bord complet YTD/YoY:';
SELECT 
    d.Year,
    d.Month,
    d.MonthName,
    SUM(v.MontantHT) AS CA_Mensuel,
    -- YTD
    SUM(SUM(v.MontantHT)) OVER (
        PARTITION BY d.Year 
        ORDER BY d.Month 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CA_YTD,
    -- YoY
    LAG(SUM(v.MontantHT), 12) OVER (ORDER BY d.Year, d.Month) AS CA_Meme_Mois_Annee_Precedente,
    -- Évolution
    CASE 
        WHEN LAG(SUM(v.MontantHT), 12) OVER (ORDER BY d.Year, d.Month) > 0
        THEN (SUM(v.MontantHT) - LAG(SUM(v.MontantHT), 12) OVER (ORDER BY d.Year, d.Month)) 
             / LAG(SUM(v.MontantHT), 12) OVER (ORDER BY d.Year, d.Month) * 100
        ELSE NULL
    END AS Evolution_YoY_Percent,
    -- Objectif YTD (exemple: 1M€ par an)
    (1000000.0 / 12.0 * d.Month) AS Objectif_YTD,
    -- Réalisation
    CASE 
        WHEN (1000000.0 / 12.0 * d.Month) > 0
        THEN SUM(SUM(v.MontantHT)) OVER (
                PARTITION BY d.Year 
                ORDER BY d.Month 
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
             ) / (1000000.0 / 12.0 * d.Month) * 100
        ELSE NULL
    END AS Realisation_YTD_Percent
FROM Fact_Ventes v
JOIN Dim_Date d ON v.DateKey = d.DateKey
WHERE d.Year >= 2023
GROUP BY d.Year, d.Month, d.MonthName
ORDER BY d.Year, d.Month;

PRINT '4. Analyse YTD/YoY par région:';
WITH RegionalYTD AS (
    SELECT 
        r.Region,
        d.Year,
        d.Month,
        SUM(v.MontantHT) AS CA_Mensuel,
        SUM(SUM(v.MontantHT)) OVER (
            PARTITION BY r.Region, d.Year 
            ORDER BY d.Month 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CA_YTD_Region
    FROM Fact_Ventes v
    JOIN Dim_Date d ON v.DateKey = d.DateKey
    JOIN Dim_Region r ON v.RegionKey = r.RegionKey
    GROUP BY r.Region, d.Year, d.Month
),
RegionalYoY AS (
    SELECT
        *,
        LAG(CA_Mensuel, 12) OVER (
            PARTITION BY Region 
            ORDER BY Year, Month
        ) AS CA_Mensuel_N_1,
        LAG(CA_YTD_Region, 12) OVER (
            PARTITION BY Region 
            ORDER BY Year, Month
        ) AS CA_YTD_Region_N_1
    FROM RegionalYTD
)
SELECT
    Region,
    Year,
    Month,
    CA_Mensuel,
    CA_YTD_Region,
    CA_Mensuel_N_1,
    CA_YTD_Region_N_1,
    CASE 
        WHEN CA_Mensuel_N_1 > 0 
        THEN (CA_Mensuel - CA_Mensuel_N_1) / CA_Mensuel_N_1 * 100 
        ELSE NULL 
    END AS Evolution_Mensuelle_YoY_Percent,
    CASE 
        WHEN CA_YTD_Region_N_1 > 0 
        THEN (CA_YTD_Region - CA_YTD_Region_N_1) / CA_YTD_Region_N_1 * 100 
        ELSE NULL 
    END AS Evolution_YTD_YoY_Percent
FROM RegionalYoY
WHERE Year = 2024
ORDER BY Region, Year, Month;

-- ============================================
-- 8. PROCÉDURE DE RAPPORT MENSUEL YTD/YOY
-- ============================================
IF OBJECT_ID('Generate_YTD_YoY_Report', 'P') IS NOT NULL
    DROP PROCEDURE Generate_YTD_YoY_Report;
GO

CREATE PROCEDURE Generate_YTD_YoY_Report
    @Year INT,
    @Month INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=== RAPPORT YTD/YOY - Année ' + CAST(@Year AS VARCHAR) + ' ===';
    
    -- Si mois non spécifié, utiliser le dernier mois disponible
    IF @Month IS NULL
    BEGIN
        SELECT TOP 1 @Month = Month
        FROM Fact_Ventes v
        JOIN Dim_Date d ON v.DateKey = d.DateKey
        WHERE d.Year = @Year
        ORDER BY d.DateFull DESC;
    END
    
    PRINT 'Mois analysé: ' + CAST(@Month AS VARCHAR);
    
    -- 1. Vue d'ensemble
    PRINT CHAR(10) + '1. VUE D''ENSEMBLE:';
    SELECT
        @Year AS Annee,
        @Month AS Mois,
        COUNT(DISTINCT v.VenteKey) AS Total_Ventes,
        SUM(v.MontantHT) AS CA_Total_Mois,
        SUM(v.Quantite) AS Quantite_Total_Mois,
        COUNT(DISTINCT v.ClientKey) AS Clients_Uniques_Mois,
        -- YTD
        SUM(SUM(v.MontantHT)) OVER (
            PARTITION BY d.Year 
            ORDER BY d.Month 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CA_YTD,
        -- YoY
        LAG(SUM(v.MontantHT), 12) OVER (ORDER BY d.Year, d.Month) AS CA_Mois_Precedent
    FROM Fact_Ventes v
    JOIN Dim_Date d ON v.DateKey = d.DateKey
    WHERE d.Year = @Year AND d.Month = @Month
    GROUP BY d.Year, d.Month;
    
    -- 2. Top catégories
    PRINT CHAR(10) + '2. TOP CATÉGORIES DU MOIS:';
    SELECT TOP 5
        p.Categorie,
        p.Departement,
        SUM(v.MontantHT) AS CA_Mois,
        SUM(v.Quantite) AS Quantite_Mois,
        COUNT(DISTINCT v.VenteKey) AS Transactions,
        RANK() OVER (ORDER BY SUM(v.MontantHT) DESC) AS Rang_CA
    FROM Fact_Ventes v
    JOIN Dim_Date d ON v.DateKey = d.DateKey
    JOIN Dim_Produit p ON v.ProduitKey = p.ProduitKey
    WHERE d.Year = @Year AND d.Month = @Month
    GROUP BY p.Categorie, p.Departement
    ORDER BY CA_Mois DESC;
    
    -- 3. Performance par région
    PRINT CHAR(10) + '3. PERFORMANCE PAR RÉGION:';
    SELECT
        r.Region,
        r.Ville,
        COUNT(DISTINCT r.MagasinID) AS Nombre_Magasins,
        SUM(v.MontantHT) AS CA_Mois,
        SUM(v.Quantite) AS Quantite_Mois,
        -- Contribution au total
        SUM(v.MontantHT) * 100.0 / (
            SELECT SUM(MontantHT) 
            FROM Fact_Ventes v2
            JOIN Dim_Date d2 ON v2.DateKey = d2.DateKey
            WHERE d2.Year = @Year AND d2.Month = @Month
        ) AS Pourcentage_Contribution
    FROM Fact_Ventes v
    JOIN Dim_Date d ON v.DateKey = d.DateKey
    JOIN Dim_Region r ON v.RegionKey = r.RegionKey
    WHERE d.Year = @Year AND d.Month = @Month
    GROUP BY r.Region, r.Ville
    ORDER BY CA_Mois DESC;
    
    -- 4. Évolution YoY par catégorie
    PRINT CHAR(10) + '4. ÉVOLUTION YOY PAR CATÉGORIE:';
    WITH CurrentMonth AS (
        SELECT 
            p.Categorie,
            SUM(v.MontantHT) AS CA_Mois
        FROM Fact_Ventes v
        JOIN Dim_Date d ON v.DateKey = d.DateKey
        JOIN Dim_Produit p ON v.ProduitKey = p.ProduitKey
        WHERE d.Year = @Year AND d.Month = @Month
        GROUP BY p.Categorie
    ),
    PreviousYear AS (
        SELECT 
            p.Categorie,
            SUM(v.MontantHT) AS CA_Mois_N_1
        FROM Fact_Ventes v
        JOIN Dim_Date d ON v.DateKey = d.DateKey
        JOIN Dim_Produit p ON v.ProduitKey = p.ProduitKey
        WHERE d.Year = @Year - 1 AND d.Month = @Month
        GROUP BY p.Categorie
    )
    SELECT
        COALESCE(cm.Categorie, py.Categorie) AS Categorie,
        cm.CA_Mois,
        py.CA_Mois_N_1,
        CASE 
            WHEN py.CA_Mois_N_1 > 0 
            THEN (cm.CA_Mois - py.CA_Mois_N_1) / py.CA_Mois_N_1 * 100 
            ELSE NULL 
        END AS Evolution_YoY_Percent,
        cm.CA_Mois - py.CA_Mois_N_1 AS Delta_CA
    FROM CurrentMonth cm
    FULL OUTER JOIN PreviousYear py ON cm.Categorie = py.Categorie
    ORDER BY COALESCE(cm.CA_Mois, 0) DESC;
END;
GO

-- Test de la procédure
PRINT 'Test de la procédure de rapport:';
EXEC Generate_YTD_YoY_Report @Year = 2024, @Month = 12;

PRINT CHAR(10) + 'Script YTD/YoY exécuté avec succès.';