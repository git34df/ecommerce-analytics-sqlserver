from sqlalchemy import create_engine
import pandas as pd
import os
from config import DB_SERVER, DATA_PATH 

ruta = DATA_PATH

customers_clean = pd.read_csv(os.path.join(ruta, 'Dim_Customers.csv'))
orders_clean    = pd.read_csv(os.path.join(ruta, 'Fact_Orders.csv'))
dim_products    = pd.read_csv(os.path.join(ruta, 'dim_products.csv'))
dim_calendario  = pd.read_csv(os.path.join(ruta, 'Dim_Calendario.csv'))
monthly_revenue = pd.read_csv(os.path.join(ruta, 'monthly.csv'))

engine = create_engine(
    f'mssql+pyodbc://{DB_SERVER}'
    '?driver=ODBC+Driver+17+for+SQL+Server'
    '&trusted_connection=yes'
    '&TrustServerCertificate=yes'
)

tablas = {
    'dim_customers':       customers_clean,
    'dim_products':        dim_products,
    'dim_calendario':      dim_calendario,
    'fact_orders':         orders_clean,
    'agg_monthly_revenue': monthly_revenue,
}

with engine.connect() as conn:
    for nombre, df in tablas.items():
        df.to_sql(nombre, con=conn, if_exists='replace', index=False, schema='dbo')
        conn.commit()
        print(f"✅ {nombre} cargada — {len(df):,} filas")

print("\n🎯 Carga completa exitosa")
