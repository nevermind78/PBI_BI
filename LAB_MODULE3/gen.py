import pandas as pd
import os

# 1. Créer le dossier
dossier = "LAB_MODULE3/Ventes 2024"
os.makedirs(dossier, exist_ok=True)

# 2. Données de base
produits = ['P001', 'P002', 'P003']
noms = ['Smartphone', 'Tablette', 'Casque']
prix = [299, 499, 79]

# 3. Créer 12 fichiers (un par mois)
for mois in range(1, 13):
    # Nom du fichier
    fichier = f"{dossier}/Ventes_{mois:02d}_2024.xlsx"
    
    # Créer quelques lignes de données
    donnees = []
    for i in range(10):  # 10 ventes par mois
        produit_idx = i % 3
        donnees.append({
            'Date': f'2024-{mois:02d}-{i+1:02d}',
            'ProduitID': produits[produit_idx],
            'Quantite': (i % 3) + 1,
            'Prix': prix[produit_idx]
        })
    
    # Sauvegarder en Excel
    pd.DataFrame(donnees).to_excel(fichier, index=False)
    print(f"Créé: {fichier}")

print(f"\n✓ 12 fichiers créés dans: {dossier}")