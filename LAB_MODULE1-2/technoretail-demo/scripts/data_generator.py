import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Configuration
np.random.seed(42)
n_transactions = 1000

# Données de base
products = [
    {'sku': 'SM-G990', 'name': 'Smartphone Galaxy', 'category': 'Électronique', 'subcategory': 'Téléphonie', 'brand': 'Samsung', 'price': 899.99, 'cost': 650.00},
    {'sku': 'IP-14-128', 'name': 'iPhone 14 128GB', 'category': 'Électronique', 'subcategory': 'Téléphonie', 'brand': 'Apple', 'price': 989.99, 'cost': 750.00},
    {'sku': 'TV-LG-55', 'name': 'TV LG 55" 4K', 'category': 'Électronique', 'subcategory': 'TV & Vidéo', 'brand': 'LG', 'price': 699.99, 'cost': 520.00},
    {'sku': 'LAP-DEL-XPS', 'name': 'Laptop Dell XPS', 'category': 'Informatique', 'subcategory': 'Ordinateurs', 'brand': 'Dell', 'price': 1299.99, 'cost': 980.00},
    {'sku': 'TAB-S7', 'name': 'Tablette S7', 'category': 'Électronique', 'subcategory': 'Tablettes', 'brand': 'Samsung', 'price': 499.99, 'cost': 380.00}
]

stores = [
    {'id': 'PAR01', 'name': 'Paris Centre', 'region': 'Île-de-France', 'city': 'Paris'},
    {'id': 'LYO01', 'name': 'Lyon Part-Dieu', 'region': 'Auvergne-Rhône-Alpes', 'city': 'Lyon'},
    {'id': 'MAR01', 'name': 'Marseille Vieux Port', 'region': 'Provence-Alpes-Côte d\'Azur', 'city': 'Marseille'},
    {'id': 'BOR01', 'name': 'Bordeaux Centre', 'region': 'Nouvelle-Aquitaine', 'city': 'Bordeaux'}
]

channels = ['Magasin', 'Web', 'Mobile']

# Génération des transactions
transactions = []
start_date = datetime(2023, 1, 1)
end_date = datetime(2024, 6, 30)

for i in range(n_transactions):
    product = random.choice(products)
    store = random.choice(stores)
    channel = random.choice(channels)
    date = start_date + timedelta(days=random.randint(0, (end_date - start_date).days))
    
    quantity = random.randint(1, 3)
    discount = random.choice([0, 0, 0, 5, 10, 15])  # Probabilités différentes
    sales_amount = product['price'] * quantity * (1 - discount/100)
    cost_amount = product['cost'] * quantity
    
    transactions.append({
        'transaction_id': f'TXN{1000 + i}',
        'date': date.strftime('%Y-%m-%d'),
        'product_sku': product['sku'],
        'product_name': product['name'],
        'category': product['category'],
        'brand': product['brand'],
        'store_id': store['id'],
        'store_name': store['name'],
        'region': store['region'],
        'channel': channel,
        'quantity': quantity,
        'unit_price': product['price'],
        'sales_amount': round(sales_amount, 2),
        'cost_amount': round(cost_amount, 2),
        'discount_percent': discount
    })

# Création du DataFrame
df = pd.DataFrame(transactions)
df.to_csv('C:/Users/abdal/OneDrive/Bureau/PBI_BI/LAB/technoretail-demo/data/technoretail_sales.csv', index=False, encoding='utf-8')
print(f"Fichier généré avec {len(df)} transactions")