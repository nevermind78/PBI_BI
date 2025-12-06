-- Script de création de hiérarchies
-- Pour les dimensions Produit, Région et Date

USE Formation_DWH;
GO

-- ============================================
-- 1. HIÉRARCHIE PRODUIT
-- ============================================
PRINT 'Création de la hiérarchie Produit...';

IF OBJECT_ID('Dim_Produit', 'U') IS NOT NULL
    DROP TABLE Dim_Produit;

CREATE TABLE Dim_Produit (
    ProduitKey INT IDENTITY(1,1) PRIMARY KEY,
    ProduitID VARCHAR(50) NOT NULL UNIQUE,
    NomProduit VARCHAR(200) NOT NULL,
    Description VARCHAR(500),
    
    -- Hiérarchie: Département > Catégorie > SousCatégorie > Produit
    Departement VARCHAR(100) NOT NULL,
    Categorie VARCHAR(100) NOT NULL,
    SousCategorie VARCHAR(100) NOT NULL,
    
    -- Attributs supplémentaires
    Marque VARCHAR(100),
    PrixUnitaire DECIMAL(10,2) NOT NULL,
    CoutUnitaire DECIMAL(10,2),
    UniteMesure VARCHAR(20),
    CodeEAN VARCHAR(13),
    EstActif BIT DEFAULT 1,
    
    -- Gestion SCD Type 2 (simplifiée)
    DateDebut DATE NOT NULL DEFAULT '1900-01-01',
    DateFin DATE NOT NULL DEFAULT '9999-12-31',
    VersionActive BIT DEFAULT 1,
    
    -- Pour navigation hiérarchique
    NiveauHierarchique INT NOT NULL DEFAULT 4,
    CheminHierarchique VARCHAR(500) NULL
);

-- Remplissage avec des données exemple
INSERT INTO Dim_Produit (
    ProduitID, NomProduit, Description, 
    Departement, Categorie, SousCategorie,
    Marque, PrixUnitaire, CoutUnitaire, UniteMesure,
    DateDebut, CheminHierarchique, NiveauHierarchique
) VALUES
-- Électronique
('P001', 'Smartphone X200', 'Smartphone haut de gamme 128GB',
 'Électronique', 'Téléphones', 'Smartphones',
 'TechCorp', 299.99, 180.00, 'Unité', '2024-01-01',
 'Électronique|Téléphones|Smartphones|Smartphone X200', 4),

('P002', 'Tablette Pro 10', 'Tablette 10 pouces avec stylet',
 'Électronique', 'Tablettes', 'Tablettes 10"',
 'TechCorp', 499.99, 320.00, 'Unité', '2024-01-01',
 'Électronique|Tablettes|Tablettes 10"|Tablette Pro 10', 4),

('P003', 'Casque Audio Bluetooth', 'Casque sans fil réduction bruit',
 'Électronique', 'Accessoires', 'Casques Audio',
 'SoundTech', 79.99, 45.00, 'Unité', '2024-01-01',
 'Électronique|Accessoires|Casques Audio|Casque Audio Bluetooth', 4),

-- Informatique
('P004', 'Souris Gaming RGB', 'Souris gaming 16000 DPI RGB',
 'Informatique', 'Périphériques', 'Souris',
 'GameGear', 49.99, 25.00, 'Unité', '2024-01-01',
 'Informatique|Périphériques|Souris|Souris Gaming RGB', 4),

('P005', 'Clavier Mécanique', 'Clavier mécanique rétroéclairé',
 'Informatique', 'Périphériques', 'Claviers',
 'GameGear', 89.99, 50.00, 'Unité', '2024-01-01',
 'Informatique|Périphériques|Claviers|Clavier Mécanique', 4),

('P006', 'Écran 24" 4K', 'Écran LCD 24 pouces 4K UHD',
 'Informatique', 'Moniteurs', '24 pouces',
 'DisplayPro', 249.99, 150.00, 'Unité', '2024-01-01',
 'Informatique|Moniteurs|24 pouces|Écran 24" 4K', 4),

-- Électroménager
('P007', 'Machine à café', 'Machine à café automatique',
 'Électroménager', 'Cuisine', 'Machine à café',
 'HomeTech', 199.99, 120.00, 'Unité', '2024-01-01',
 'Électroménager|Cuisine|Machine à café|Machine à café', 4),

('P008', 'Aspirateur Robot', 'Aspirateur robot intelligent',
 'Électroménager', 'Nettoyage', 'Aspirateurs',
 'CleanBot', 299.99, 180.00, 'Unité', '2024-01-01',
 'Électroménager|Nettoyage|Aspirateurs|Aspirateur Robot', 4);

-- Index pour la hiérarchie
CREATE INDEX IX_Dim_Produit_Hierarchie 
ON Dim_Produit(Departement, Categorie, SousCategorie);

CREATE INDEX IX_Dim_Produit_Chemin 
ON Dim_Produit(CheminHierarchique);

-- ============================================
-- 2. HIÉRARCHIE RÉGION
-- ============================================
PRINT 'Création de la hiérarchie Région...';

IF OBJECT_ID('Dim_Region', 'U') IS NOT NULL
    DROP TABLE Dim_Region;

CREATE TABLE Dim_Region (
    RegionKey INT IDENTITY(1,1) PRIMARY KEY,
    MagasinID VARCHAR(20) NOT NULL UNIQUE,
    NomMagasin VARCHAR(100) NOT NULL,
    
    -- Hiérarchie: Pays > Région > Ville > Magasin
    Pays VARCHAR(50) NOT NULL,
    Region VARCHAR(100) NOT NULL,
    Ville VARCHAR(100) NOT NULL,
    
    -- Attributs supplémentaires
    Adresse VARCHAR(255),
    CodePostal VARCHAR(10),
    Telephone VARCHAR(20),
    Email VARCHAR(255),
    SurfaceM2 DECIMAL(10,2),
    DateOuverture DATE,
    EstActif BIT DEFAULT 1,
    
    -- Pour navigation hiérarchique
    NiveauHierarchique INT NOT NULL DEFAULT 4,
    CheminHierarchique VARCHAR(500) NULL,
    Longitude DECIMAL(9,6),
    Latitude DECIMAL(9,6)
);

-- Remplissage avec des données exemple (France)
INSERT INTO Dim_Region (
    MagasinID, NomMagasin, Pays, Region, Ville,
    Adresse, CodePostal, SurfaceM2, DateOuverture,
    CheminHierarchique, NiveauHierarchique
) VALUES
-- Île-de-France
('M01', 'Paris Centre', 'France', 'Île-de-France', 'Paris',
 '123 Rue de Rivoli', '75001', 350.5, '2020-03-15',
 'France|Île-de-France|Paris|Paris Centre', 4),

('M02', 'Paris Montparnasse', 'France', 'Île-de-France', 'Paris',
 '45 Avenue du Maine', '75014', 280.0, '2021-06-10',
 'France|Île-de-France|Paris|Paris Montparnasse', 4),

('M03', 'Lyon Part-Dieu', 'France', 'Auvergne-Rhône-Alpes', 'Lyon',
 '17 Rue de la République', '69002', 420.0, '2019-11-20',
 'France|Auvergne-Rhône-Alpes|Lyon|Lyon Part-Dieu', 4),

('M04', 'Lyon Bellecour', 'France', 'Auvergne-Rhône-Alpes', 'Lyon',
 '22 Place Bellecour', '69002', 310.5, '2022-02-28',
 'France|Auvergne-Rhône-Alpes|Lyon|Lyon Bellecour', 4),

('M05', 'Marseille Vieux Port', 'France', 'Provence-Alpes-Côte d''Azur', 'Marseille',
 '8 Quai du Port', '13001', 380.0, '2020-09-05',
 'France|Provence-Alpes-Côte d''Azur|Marseille|Marseille Vieux Port', 4),

('M06', 'Toulouse Capitole', 'France', 'Occitanie', 'Toulouse',
 '15 Place du Capitole', '31000', 295.5, '2021-04-12',
 'France|Occitanie|Toulouse|Toulouse Capitole', 4),

('M07', 'Lille Grand Place', 'France', 'Hauts-de-France', 'Lille',
 '10 Place du Général de Gaulle', '59000', 265.0, '2022-08-30',
 'France|Hauts-de-France|Lille|Lille Grand Place', 4),

('M08', 'Bordeaux Quinconces', 'France', 'Nouvelle-Aquitaine', 'Bordeaux',
 '25 Cours du 30 Juillet', '33000', 340.0, '2023-01-15',
 'France|Nouvelle-Aquitaine|Bordeaux|Bordeaux Quinconces', 4);

-- Index pour la hiérarchie
CREATE INDEX IX_Dim_Region_Hierarchie 
ON Dim_Region(Pays, Region, Ville);

CREATE INDEX IX_Dim_Region_Chemin 
ON Dim_Region(CheminHierarchique);

-- ============================================
-- 3. HIÉRARCHIE DATE (COMPLÉMENTAIRE)
-- ============================================
PRINT 'Création des colonnes hiérarchiques pour Date...';

-- Ajout de colonnes pour navigation hiérarchique
ALTER TABLE Dim_Date
ADD 
    CheminHierarchique_Temps AS 
        CAST(Year AS VARCHAR) + '|' + 
        QuarterName + '|' + 
        MonthName + '|' + 
        CONVERT(VARCHAR, DayOfMonth) PERSISTED,
    
    NiveauHierarchique_Temps AS 4 PERSISTED;

-- ============================================
-- 4. VUES HIÉRARCHIQUES
-- ============================================

-- Vue pour la hiérarchie Produit
IF OBJECT_ID('vw_Hierarchie_Produit', 'V') IS NOT NULL
    DROP VIEW vw_Hierarchie_Produit;
GO

CREATE VIEW vw_Hierarchie_Produit AS
SELECT 
    'Département' AS Niveau,
    Departement AS Valeur,
    COUNT(DISTINCT ProduitKey) AS NombreProduits,
    AVG(PrixUnitaire) AS PrixMoyen,
    SUM(CASE WHEN EstActif = 1 THEN 1 ELSE 0 END) AS ProduitsActifs
FROM Dim_Produit
GROUP BY Departement

UNION ALL

SELECT 
    'Catégorie' AS Niveau,
    Categorie AS Valeur,
    COUNT(DISTINCT ProduitKey) AS NombreProduits,
    AVG(PrixUnitaire) AS PrixMoyen,
    SUM(CASE WHEN EstActif = 1 THEN 1 ELSE 0 END) AS ProduitsActifs
FROM Dim_Produit
GROUP BY Categorie

UNION ALL

SELECT 
    'Sous-catégorie' AS Niveau,
    SousCategorie AS Valeur,
    COUNT(DISTINCT ProduitKey) AS NombreProduits,
    AVG(PrixUnitaire) AS PrixMoyen,
    SUM(CASE WHEN EstActif = 1 THEN 1 ELSE 0 END) AS ProduitsActifs
FROM Dim_Produit
GROUP BY SousCategorie

UNION ALL

SELECT 
    'Produit' AS Niveau,
    NomProduit AS Valeur,
    1 AS NombreProduits,
    PrixUnitaire AS PrixMoyen,
    CASE WHEN EstActif = 1 THEN 1 ELSE 0 END AS ProduitsActifs
FROM Dim_Produit;
GO

-- Vue pour la hiérarchie Région
IF OBJECT_ID('vw_Hierarchie_Region', 'V') IS NOT NULL
    DROP VIEW vw_Hierarchie_Region;
GO

CREATE VIEW vw_Hierarchie_Region AS
SELECT 
    'Pays' AS Niveau,
    Pays AS Valeur,
    COUNT(DISTINCT RegionKey) AS NombreMagasins,
    SUM(SurfaceM2) AS SurfaceTotale,
    MIN(DateOuverture) AS PremiereOuverture
FROM Dim_Region
GROUP BY Pays

UNION ALL

SELECT 
    'Région' AS Niveau,
    Region AS Valeur,
    COUNT(DISTINCT RegionKey) AS NombreMagasins,
    SUM(SurfaceM2) AS SurfaceTotale,
    MIN(DateOuverture) AS PremiereOuverture
FROM Dim_Region
GROUP BY Region

UNION ALL

SELECT 
    'Ville' AS Niveau,
    Ville AS Valeur,
    COUNT(DISTINCT RegionKey) AS NombreMagasins,
    SUM(SurfaceM2) AS SurfaceTotale,
    MIN(DateOuverture) AS PremiereOuverture
FROM Dim_Region
GROUP BY Ville

UNION ALL

SELECT 
    'Magasin' AS Niveau,
    NomMagasin AS Valeur,
    1 AS NombreMagasins,
    SurfaceM2 AS SurfaceTotale,
    DateOuverture AS PremiereOuverture
FROM Dim_Region;
GO

-- ============================================
-- 5. REQUÊTES DE DÉMONSTRATION
-- ============================================
PRINT '=== REQUÊTES DE DÉMONSTRATION DES HIÉRARCHIES ===';

PRINT '1. Navigation hiérarchique Produit (drill-down):';
SELECT 
    Departement,
    Categorie,
    SousCategorie,
    NomProduit,
    PrixUnitaire,
    COUNT(*) OVER (PARTITION BY Departement, Categorie) AS ProduitsParCategorie,
    AVG(PrixUnitaire) OVER (PARTITION BY Departement) AS PrixMoyenDepartement
FROM Dim_Produit
WHERE EstActif = 1
ORDER BY Departement, Categorie, SousCategorie, NomProduit;

PRINT '2. Agrégation par niveau hiérarchique (roll-up):';
WITH Aggregations AS (
    SELECT 
        'Pays' AS Niveau, Pays AS Groupe, COUNT(*) AS NombreMagasins
    FROM Dim_Region GROUP BY Pays
    UNION ALL
    SELECT 
        'Région' AS Niveau, Region AS Groupe, COUNT(*) AS NombreMagasins
    FROM Dim_Region GROUP BY Region
    UNION ALL
    SELECT 
        'Ville' AS Niveau, Ville AS Groupe, COUNT(*) AS NombreMagasins
    FROM Dim_Region GROUP BY Ville
)
SELECT * FROM Aggregations ORDER BY Niveau, Groupe;

PRINT '3. Drill-down régional avec indicateurs:';
SELECT 
    r.Pays,
    r.Region,
    r.Ville,
    r.NomMagasin,
    r.SurfaceM2,
    -- Calculs hiérarchiques
    SUM(r.SurfaceM2) OVER (PARTITION BY r.Region) AS SurfaceRegion,
    COUNT(r.RegionKey) OVER (PARTITION BY r.Ville) AS MagasinsVille,
    r.SurfaceM2 * 100.0 / SUM(r.SurfaceM2) OVER (PARTITION BY r.Ville) AS PourcentageSurfaceVille
FROM Dim_Region r
WHERE r.EstActif = 1
ORDER BY r.Pays, r.Region, r.Ville, r.NomMagasin;

PRINT '4. Requête avec GROUPING SETS pour analyse multi-niveaux:';
SELECT 
    CASE 
        WHEN GROUPING(p.Departement) = 1 THEN 'TOTAL'
        ELSE COALESCE(p.Departement, 'Inconnu')
    END AS Departement,
    CASE 
        WHEN GROUPING(p.Categorie) = 1 AND GROUPING(p.Departement) = 0 THEN 'SOUS-TOTAL'
        ELSE COALESCE(p.Categorie, 'Inconnu')
    END AS Categorie,
    COUNT(*) AS NombreProduits,
    AVG(p.PrixUnitaire) AS PrixMoyen,
    MIN(p.PrixUnitaire) AS PrixMin,
    MAX(p.PrixUnitaire) AS PrixMax
FROM Dim_Produit p
WHERE p.EstActif = 1
GROUP BY GROUPING SETS (
    (p.Departement, p.Categorie),  -- Niveau détaillé
    (p.Departement),               -- Sous-total par département
    ()                             -- Total général
)
ORDER BY 
    GROUPING(p.Departement),
    GROUPING(p.Categorie),
    p.Departement,
    p.Categorie;

-- ============================================
-- 6. FONCTION POUR EXTRACTION DE NIVEAU HIÉRARCHIQUE
-- ============================================
IF OBJECT_ID('GetNiveauHierarchique', 'FN') IS NOT NULL
    DROP FUNCTION GetNiveauHierarchique;
GO

CREATE FUNCTION GetNiveauHierarchique (
    @CheminHierarchique VARCHAR(500),
    @Niveau INT
)
RETURNS VARCHAR(100)
AS
BEGIN
    DECLARE @Result VARCHAR(100);
    
    -- Sépare le chemin hiérarchique (format: "N1|N2|N3|N4")
    DECLARE @Separator CHAR(1) = '|';
    
    -- Table pour stocker les éléments séparés
    DECLARE @Elements TABLE (
        ID INT IDENTITY(1,1),
        Element VARCHAR(100)
    );
    
    -- Insertion des éléments séparés
    INSERT INTO @Elements (Element)
    SELECT value
    FROM STRING_SPLIT(@CheminHierarchique, @Separator);
    
    -- Récupération de l'élément au niveau demandé
    SELECT @Result = Element
    FROM @Elements
    WHERE ID = @Niveau;
    
    RETURN @Result;
END;
GO

-- Test de la fonction
PRINT 'Test de la fonction GetNiveauHierarchique:';
SELECT 
    CheminHierarchique,
    dbo.GetNiveauHierarchique(CheminHierarchique, 1) AS Niveau1,
    dbo.GetNiveauHierarchique(CheminHierarchique, 2) AS Niveau2,
    dbo.GetNiveauHierarchique(CheminHierarchique, 3) AS Niveau3,
    dbo.GetNiveauHierarchique(CheminHierarchique, 4) AS Niveau4
FROM Dim_Produit
WHERE ProduitID IN ('P001', 'P004');

PRINT 'Script de création des hiérarchies exécuté avec succès.';