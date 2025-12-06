-- Script d'implémentation SCD Type 2
-- Gestion des changements lents dans les dimensions

USE Formation_DWH;
GO

-- ============================================
-- 1. CRÉATION DE LA TABLE DE STAGING
-- ============================================
IF OBJECT_ID('Staging_Client', 'U') IS NOT NULL
    DROP TABLE Staging_Client;

CREATE TABLE Staging_Client (
    ClientID VARCHAR(20) NOT NULL,
    Nom VARCHAR(100) NOT NULL,
    Prenom VARCHAR(100) NOT NULL,
    Email VARCHAR(255),
    Telephone VARCHAR(20),
    Adresse VARCHAR(255),
    CodePostal VARCHAR(10),
    Ville VARCHAR(100),
    Region VARCHAR(100),
    Pays VARCHAR(50) DEFAULT 'France',
    DateMiseAJour DATETIME DEFAULT GETDATE(),
    
    -- Hash pour détection de changements
    HashKey AS CAST(
        HASHBYTES('SHA2_256',
            COALESCE(Nom, '') + '|' + 
            COALESCE(Prenom, '') + '|' + 
            COALESCE(Email, '') + '|' + 
            COALESCE(Ville, '') + '|' + 
            COALESCE(Region, '') + '|' + 
            COALESCE(Pays, '')
        ) AS BINARY(32)
    ) PERSISTED
);

-- ============================================
-- 2. CRÉATION DE LA DIMENSION CLIENT SCD TYPE 2
-- ============================================
IF OBJECT_ID('Dim_Client_SCD2', 'U') IS NOT NULL
    DROP TABLE Dim_Client_SCD2;

CREATE TABLE Dim_Client_SCD2 (
    ClientKey INT IDENTITY(1,1) PRIMARY KEY,
    ClientID VARCHAR(20) NOT NULL,          -- Clé naturelle
    Nom VARCHAR(100) NOT NULL,
    Prenom VARCHAR(100) NOT NULL,
    Email VARCHAR(255),
    Telephone VARCHAR(20),
    Adresse VARCHAR(255),
    CodePostal VARCHAR(10),
    Ville VARCHAR(100),
    Region VARCHAR(100),
    Pays VARCHAR(50) DEFAULT 'France',
    
    -- Colonnes de gestion SCD Type 2
    DateDebut DATE NOT NULL,                -- Début de validité
    DateFin DATE NOT NULL,                  -- Fin de validité
    VersionActive BIT NOT NULL DEFAULT 1,   -- Version courante
    DateChargement DATETIME DEFAULT GETDATE(),
    
    -- Hash pour détection de changements
    HashKey BINARY(32) NOT NULL,
    
    -- Pour retrouver l'historique
    VersionNumber INT DEFAULT 1,
    ClientKeyPrecedent INT NULL
);

-- Index pour performances
CREATE INDEX IX_Dim_Client_SCD2_ClientID 
ON Dim_Client_SCD2(ClientID, VersionActive);

CREATE INDEX IX_Dim_Client_SCD2_Dates 
ON Dim_Client_SCD2(DateDebut, DateFin);

CREATE INDEX IX_Dim_Client_SCD2_Hash 
ON Dim_Client_SCD2(HashKey);

-- ============================================
-- 3. PROCÉDURE DE MISE À JOUR SCD TYPE 2
-- ============================================
IF OBJECT_ID('Update_Dim_Client_SCD2', 'P') IS NOT NULL
    DROP PROCEDURE Update_Dim_Client_SCD2;
GO

CREATE PROCEDURE Update_Dim_Client_SCD2
    @DateChargement DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Utiliser la date courante si non spécifiée
    IF @DateChargement IS NULL
        SET @DateChargement = CAST(GETDATE() AS DATE);
    
    DECLARE @DateFinValidite DATE = '9999-12-31';
    DECLARE @LignesTouchees INT = 0;
    
    PRINT 'Début de la mise à jour SCD Type 2 - ' + CONVERT(VARCHAR, GETDATE(), 120);
    
    -- ============================================
    -- ÉTAPE 1 : DÉSACTIVER LES ENREGISTREMENTS MODIFIÉS
    -- ============================================
    PRINT 'Étape 1 : Fermeture des enregistrements modifiés...';
    
    UPDATE target
    SET 
        DateFin = DATEADD(DAY, -1, @DateChargement),
        VersionActive = 0,
        DateChargement = GETDATE()
    FROM Dim_Client_SCD2 target
    INNER JOIN Staging_Client source 
        ON target.ClientID = source.ClientID
    WHERE target.VersionActive = 1
      AND target.HashKey <> source.HashKey;
    
    SET @LignesTouchees = @@ROWCOUNT;
    PRINT '   ' + CAST(@LignesTouchees AS VARCHAR) + ' enregistrement(s) fermé(s).';
    
    -- ============================================
    -- ÉTAPE 2 : INSÉRER LES NOUVELLES VERSIONS
    -- ============================================
    PRINT 'Étape 2 : Insertion des nouvelles versions...';
    
    INSERT INTO Dim_Client_SCD2 (
        ClientID, Nom, Prenom, Email, Telephone, 
        Adresse, CodePostal, Ville, Region, Pays,
        DateDebut, DateFin, VersionActive, 
        HashKey, VersionNumber, ClientKeyPrecedent
    )
    SELECT 
        source.ClientID,
        source.Nom,
        source.Prenom,
        source.Email,
        source.Telephone,
        source.Adresse,
        source.CodePostal,
        source.Ville,
        source.Region,
        source.Pays,
        @DateChargement AS DateDebut,
        @DateFinValidite AS DateFin,
        1 AS VersionActive,
        source.HashKey,
        -- Numéro de version incrémenté
        ISNULL(target.VersionNumber, 0) + 1 AS VersionNumber,
        -- Référence à la version précédente
        target.ClientKey AS ClientKeyPrecedent
    FROM Staging_Client source
    LEFT JOIN Dim_Client_SCD2 target 
        ON source.ClientID = target.ClientID 
        AND target.VersionActive = 1
    WHERE target.HashKey <> source.HashKey 
       OR target.ClientKey IS NULL; -- Nouveaux clients
    
    SET @LignesTouchees = @@ROWCOUNT;
    PRINT '   ' + CAST(@LignesTouchees AS VARCHAR) + ' nouvelle(s) version(s) insérée(s).';
    
    -- ============================================
    -- ÉTAPE 3 : INSÉRER LES NOUVEAUX CLIENTS
    -- ============================================
    PRINT 'Étape 3 : Insertion des nouveaux clients...';
    
    INSERT INTO Dim_Client_SCD2 (
        ClientID, Nom, Prenom, Email, Telephone, 
        Adresse, CodePostal, Ville, Region, Pays,
        DateDebut, DateFin, VersionActive, 
        HashKey, VersionNumber
    )
    SELECT 
        source.ClientID,
        source.Nom,
        source.Prenom,
        source.Email,
        source.Telephone,
        source.Adresse,
        source.CodePostal,
        source.Ville,
        source.Region,
        source.Pays,
        @DateChargement AS DateDebut,
        @DateFinValidite AS DateFin,
        1 AS VersionActive,
        source.HashKey,
        1 AS VersionNumber
    FROM Staging_Client source
    WHERE NOT EXISTS (
        SELECT 1 
        FROM Dim_Client_SCD2 target 
        WHERE target.ClientID = source.ClientID
    );
    
    SET @LignesTouchees = @@ROWCOUNT;
    PRINT '   ' + CAST(@LignesTouchees AS VARCHAR) + ' nouveau(x) client(s) inséré(s).';
    
    -- ============================================
    -- ÉTAPE 4 : RAPPORT FINAL
    -- ============================================
    PRINT 'Étape 4 : Génération du rapport...';
    
    SELECT 
        'Rapport SCD Type 2' AS Rapport,
        @DateChargement AS DateChargement,
        (SELECT COUNT(*) FROM Dim_Client_SCD2 WHERE VersionActive = 1) AS ClientsActifs,
        (SELECT COUNT(*) FROM Dim_Client_SCD2) AS TotalVersions,
        (SELECT COUNT(DISTINCT ClientID) FROM Dim_Client_SCD2) AS ClientsDistincts;
    
    PRINT 'Mise à jour SCD Type 2 terminée avec succès.';
END;
GO

-- ============================================
-- 4. VUE POUR CONSULTER LES CLIENTS COURANTS
-- ============================================
IF OBJECT_ID('vw_Clients_Actuels', 'V') IS NOT NULL
    DROP VIEW vw_Clients_Actuels;
GO

CREATE VIEW vw_Clients_Actuels AS
SELECT 
    ClientKey,
    ClientID,
    Nom,
    Prenom,
    Email,
    Telephone,
    Ville,
    Region,
    Pays,
    DateDebut,
    DateFin,
    VersionNumber
FROM Dim_Client_SCD2
WHERE VersionActive = 1;
GO

-- ============================================
-- 5. VUE POUR CONSULTER L'HISTORIQUE COMPLET
-- ============================================
IF OBJECT_ID('vw_Clients_Historique', 'V') IS NOT NULL
    DROP VIEW vw_Clients_Historique;
GO

CREATE VIEW vw_Clients_Historique AS
SELECT 
    c1.ClientKey,
    c1.ClientID,
    c1.Nom,
    c1.Prenom,
    c1.Ville,
    c1.Region,
    c1.DateDebut,
    c1.DateFin,
    c1.VersionNumber,
    c1.VersionActive,
    -- Changement détecté
    CASE 
        WHEN c2.ClientKey IS NULL THEN 'Création initiale'
        WHEN c1.Ville <> c2.Ville THEN 'Changement de ville'
        WHEN c1.Region <> c2.Region THEN 'Changement de région'
        ELSE 'Autre modification'
    END AS TypeChangement
FROM Dim_Client_SCD2 c1
LEFT JOIN Dim_Client_SCD2 c2 
    ON c1.ClientKeyPrecedent = c2.ClientKey;
GO

-- ============================================
-- 6. DONNÉES DE TEST
-- ============================================
PRINT 'Insertion de données de test...';

-- Premier chargement
INSERT INTO Staging_Client (ClientID, Nom, Prenom, Email, Ville, Region) VALUES
('C1001', 'Dupont', 'Jean', 'jean.dupont@mail.com', 'Paris', 'Île-de-France'),
('C1002', 'Martin', 'Sophie', 'sophie.martin@mail.com', 'Lyon', 'Auvergne-Rhône-Alpes'),
('C1003', 'Bernard', 'Pierre', 'pierre.bernard@mail.com', 'Marseille', 'Provence-Alpes-Côte d''Azur');

EXEC Update_Dim_Client_SCD2 '2024-01-01';

-- Deuxième chargement (avec modifications)
DELETE FROM Staging_Client;
INSERT INTO Staging_Client (ClientID, Nom, Prenom, Email, Ville, Region) VALUES
('C1001', 'Dupont', 'Jean', 'jean.dupont@mail.com', 'Lyon', 'Auvergne-Rhône-Alpes'), -- Changement ville
('C1002', 'Martin', 'Sophie', 'sophie.martin@mail.com', 'Lyon', 'Auvergne-Rhône-Alpes'),
('C1003', 'Bernard', 'Pierre', 'pierre.bernard@mail.com', 'Marseille', 'Provence-Alpes-Côte d''Azur'),
('C1004', 'Petit', 'Marie', 'marie.petit@mail.com', 'Toulouse', 'Occitanie'); -- Nouveau client

EXEC Update_Dim_Client_SCD2 '2024-06-01';

-- ============================================
-- 7. REQUÊTES DE VÉRIFICATION
-- ============================================
PRINT '=== VÉRIFICATIONS ===';

PRINT '1. Clients actuels:';
SELECT * FROM vw_Clients_Actuels ORDER BY ClientID;

PRINT CHAR(10) + '2. Historique complet:';
SELECT * FROM vw_Clients_Historique ORDER BY ClientID, DateDebut;

PRINT CHAR(10) + '3. Statistiques:';
SELECT 
    ClientID,
    COUNT(*) AS NombreVersions,
    MIN(DateDebut) AS PremiereVersion,
    MAX(DateDebut) AS DerniereVersion
FROM Dim_Client_SCD2
GROUP BY ClientID
ORDER BY ClientID;

PRINT CHAR(10) + 'Script SCD Type 2 exécuté avec succès.';