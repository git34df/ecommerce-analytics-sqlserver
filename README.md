# Ecommerce Analytics — SQL Server & Power BI

Análisis end-to-end de una tienda ecommerce: desde la carga
de datos con Python hasta un dashboard ejecutivo en Power BI,
pasando por consultas analíticas avanzadas en SQL Server.

---

## Stack

![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=flat&logo=python&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL_Server-2022-CC2927?style=flat&logo=microsoftsqlserver&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-Dashboard-F2C811?style=flat&logo=powerbi&logoColor=black)
![Pandas](https://img.shields.io/badge/Pandas-ETL-150458?style=flat&logo=pandas&logoColor=white)

---

## Objetivo

Construir un pipeline analítico completo que permita responder
preguntas de negocio sobre ventas, retención de clientes y
rentabilidad, usando SQL Server como motor de análisis y
Power BI como capa de visualización.

---

## Arquitectura del proyecto
CSV (fuente) → Python ETL → SQL Server → Consultas analíticas → Power BI



## Contenido

| Carpeta | Descripción |
|---|---|
| `data/` | Datasets CSV: clientes, órdenes, productos, calendario |
| `sql/` | Script de carga ETL y consultas analíticas |
| `dashboard/` | Capturas de las 3 páginas del reporte |

---

## Modelo de datos

| Tabla | Tipo | Descripción |
|---|---|---|
| `fact_orders` | Fact | Transacciones de ventas |
| `dim_customers` | Dimensión | Datos de clientes |
| `dim_products` | Dimensión | Catálogo de productos |
| `dim_calendario` | Dimensión | Tabla de fechas |
| `agg_monthly_revenue` | Agregada | Revenue mensual precalculado |

---

## Consultas destacadas

### Variación YoY (Year over Year)
Comparativa de revenue entre el año actual y el anterior,
calculando el crecimiento porcentual por período para
identificar tendencias de largo plazo.
→ `sql/queries.sql`

### Análisis RFM (Recency, Frequency, Monetary)
Segmentación de clientes en base a tres métricas:
cuándo fue su última compra, con qué frecuencia compran
y cuánto dinero han generado. Permite identificar
clientes VIP, en riesgo y recuperables.
→ `sql/queries.sql`

### CLV (Customer Lifetime Value)
Estimación del valor total que un cliente genera
a lo largo de su relación con el negocio,
combinando frecuencia de compra, ticket promedio
y período activo.
→ `sql/queries.sql`

---

## Dashboard Power BI

### Página 1 — Vista Ejecutiva General
KPIs principales: revenue total, número de órdenes,
ticket promedio y clientes activos. Diseñada para
decisiones rápidas de alto nivel.

### Página 2 — Tendencias de Tiempo
Evolución mensual del revenue con comparativa YoY.
Identifica estacionalidad, picos de venta y
caídas en períodos específicos.

### Página 3 — Comportamiento de Cliente
Segmentación RFM, CLV por segmento y análisis
de retención. Responde quiénes son los mejores
clientes y cuáles están en riesgo de abandono.

---

## Cómo ejecutar el ETL

```bash
# 1. Instalar dependencias
pip install pandas sqlalchemy pyodbc

# 2. Configurar credenciales
cp config.example.py config.py
# Editar config.py con tu servidor SQL Server

# 3. Ejecutar carga
python sql/etl_load.py
```

> Requiere SQL Server con Windows Authentication
> y ODBC Driver 17 for SQL Server instalado.

---

## Autor

**Diego Torres Andrade**
Estudiante de Ingeniería de Sistemas — UPN Lima
Orientado a Data Analytics & Business Intelligence

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Conectar-0A66C2?style=flat&logo=linkedin)](https://linkedin.com/in/tu-usuario)
[![Portfolio](https://img.shields.io/badge/Portfolio-Ver_más-1a1a2e?style=flat)](https://tu-portfolio.vercel.app)
