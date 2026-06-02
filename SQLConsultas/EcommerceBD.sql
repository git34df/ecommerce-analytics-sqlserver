use EcommerceDB;
-- C01 Lista todos los clientes con membership_tier = 'Platinum' que tengan churned = 0, 
-- mostrando customer_id, country, total_spend_usd y days_since_last_purchase. Ordena por total_spend_usd descendente.
select customer_id,country,total_spend_usd,days_since_last_purchase from dim_customers
where membership_tier = 'Platinum' and churned = 0 
order by total_spend_usd desc

/* C02. Muestra el conteo de clientes por membership_tier y el promedio de total_spend_usd por tier. 
Ordena de mayor a menor gasto promedio.*/
select membership_tier,count(*) as total_tier_category, format(AVG(total_spend_usd),'N0','es-ES') as avg_gasto from dim_customers 
group by membership_tier
order by avg_gasto;

/*C03. ¿Cuántas órdenes hay por order_status? Muestra también el porcentaje que representa cada estado sobre el total.*/
with total_orders as (
select order_status, count(*) as total_order_status from fact_orders
group by order_status 
),
pct_status_orders as (
select
order_status,
total_order_status,
(total_order_status * 100) / sum(total_order_status) over() as pct_total_orders 
from total_orders
)
select * from pct_status_orders
order by pct_total_orders desc

/*C04. Lista los 10 productos de dim_products con mayor avg_price, mostrando product_name, category y avg_price.*/
select TOP 10 product_name,category,avg_price from dim_products
order by avg_price desc

/*C05. ¿Cuántos clientes hay por country? Muestra solo los países con más de 200 clientes, ordenados descendentemente.*/
select country, count(*) as total_customers_country from dim_customers
group by country
having count(*) > 200
order by total_customers_country desc

/*C06. Calcula el total de total_amount_usd, el promedio y la cantidad de órdenes por category. Ordena por revenue total descendente.*/
select category, round(sum(total_amount_usd),2) as total_ingresos, 
round(avg(total_amount_usd),2) as avg_total_ingresos, 
count(order_id) as total_ordenes from 
fact_orders 
group by category
order by total_ingresos desc

/*C07. Muestra la cantidad de órdenes y el total_amount_usd promedio por payment_method. 
¿Qué método genera el ticket promedio más alto?*/
select payment_method, count(order_id) as total_orders, round(avg(total_amount_usd),2) as avg_total_amount from fact_orders
group by payment_method 
order by avg_total_amount desc

/*C08. Lista los clientes con returns_made > 5 y churned = 0. Muestra customer_id, membership_tier, total_orders y returns_made.*/
select customer_id,membership_tier,total_orders,returns_made from dim_customers
where returns_made > 5 and churned=0

/*C09. Usando fact_orders y dim_customers, calcula el revenue total (total_amount_usd) por membership_tier. 
Incluye también el porcentaje que aporta cada tier al revenue global.*/
with revenue_global as (
select dc.membership_tier, sum(fo.total_amount_usd) as total_amount from fact_orders as fo
inner join dim_customers as dc on fo.customer_id=dc.customer_id
group by dc.membership_tier
),
pct_revenue_global as (
select
membership_tier,
total_amount,
(total_amount*100) / sum(total_amount) over() as pct_revenue 
from revenue_global
)
select 
membership_tier,
total_amount,
pct_revenue
from pct_revenue_global
order by pct_revenue desc;

/*C10. Calcula la tasa de devolución por category: (órdenes con returned = 1 / total órdenes) * 100. Ordena de mayor a menor tasa.*/
SELECT 
    category,
    SUM(CASE WHEN returned = 1 THEN 1 ELSE 0 END) AS total_orders_returned,
    COUNT(*) AS total_ordenes,
    round((SUM(CASE WHEN returned = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)),2) AS pct_returned_orders
FROM fact_orders
GROUP BY category
ORDER BY pct_returned_orders DESC;

/*C11. Encuentra los clientes que han comprado en más de 3 categorías distintas. 
Muestra customer_id, cantidad de categorías únicas y su total_spend_usd de dim_customers.*/
select fo.customer_id, COUNT(DISTINCT fo.category) as total_categorias, dc.total_spend_usd
FROM fact_orders fo
JOIN dim_customers dc ON fo.customer_id = dc.customer_id
GROUP BY fo.customer_id, dc.total_spend_usd
HAVING COUNT(DISTINCT fo.category) > 3
order by total_spend_usd desc

/*C12. Usando dim_calendario, muestra el revenue total por year y quarter. Identifica qué quarter fue el más rentable históricamente.*/
with revenue_total as (
select 
dc.year as año, 
dc.quarter as trimestre, 
sum(fo.total_amount_usd) as total_revenue 
from fact_orders as fo
inner join dim_calendario as dc on fo.order_date=dc.date
group by dc.year,dc.quarter
),
rank_trimestres as(
select
año,
trimestre,
total_revenue,
Dense_Rank() OVER(order by total_revenue desc) as rank_trimestre
from revenue_total
)
select
año,
trimestre,
total_revenue,
rank_trimestre
from rank_trimestres
order by rank_trimestre asc

/*C13. Calcula el promedio de delivery_days por category y por order_status = 'Delivered'. 
¿Qué categoría tiene entregas más lentas?*/
select category, avg(delivery_days) as avg_delivery_days from fact_orders 
where order_status='Delivered'
group by category
order by avg_delivery_days desc

/*C14. Identifica los clientes cuyo avg_order_value_usd en fact_orders (calculado desde las órdenes reales) 
difiere en más de $20 respecto al valor registrado en dim_customers. 
Usa un JOIN entre ambas tablas.*/
select fo.customer_id,
avg(fo.total_amount_usd) as avg_amount_orders, 
dc.avg_order_value_usd,
ABS(AVG(fo.total_amount_usd) - dc.avg_order_value_usd) as diferencia_usd
from fact_orders as fo
inner join dim_customers as dc on fo.customer_id = dc.customer_id
group by fo.customer_id,dc.avg_order_value_usd
having ABS(AVG(fo.total_amount_usd) - dc.avg_order_value_usd) > 20
order by diferencia_usd desc

/*C15. Muestra el revenue mensual de agg_monthly_revenue junto con la variación porcentual respecto al mes anterior. Usa LAG().*/
with revenue_mensual as (
select
year as año,
month as mes,
revenue_usd as revenue
from agg_monthly_revenue
group by year,month,revenue_usd
),
variacion_porcentual as (
select
año,
mes,
revenue,
lag(revenue) over(Partition by año order by año,mes)  as revenue_mes_anterior,
((revenue - lag(revenue) over(Partition by año order by año,mes))/lag(revenue) over( Partition by año order by año,mes)) * 100  variacion_mensual
from revenue_mensual
)
select
año,
mes,
revenue,
revenue_mes_anterior,
format(variacion_mensual,'N2','es-ES') as variacion_mensual
from variacion_porcentual
order by año,mes

/*C16. Calcula el discount_amount_usd total entregado por category y el ratio de descuento sobre el subtotal 
(discount_amount_usd / subtotal_usd * 100). 
¿Qué categoría recibe más descuento relativo?*/
select category, round(sum(discount_amount_usd),2) as total_discount,
round((sum(discount_amount_usd) / sum(subtotal_usd))*100,2)  as ratio_descuento
from fact_orders
group by category
order by total_discount desc;

/*C17. Lista los 5 productos con mayor tasa de devolución (returned = 1) calculada desde fact_orders. 
Muestra product_name, category, total órdenes, órdenes devueltas y tasa de devolución.*/
with productos_returned as (
select
product_name as product,
category,
count(*) as total_ordenes,
SUM(CASE WHEN returned = 1 THEN 1 ELSE 0 END) AS total_orders_returned
from fact_orders
group by product_name,category
),
tasa_devolucion as (
select
product,
category,
total_ordenes,
total_orders_returned,
(total_orders_returned * 100.0 / total_ordenes) as tasa_returned
from productos_returned
)
select
product,
category,
total_ordenes,
total_orders_returned,
format(tasa_returned,'N2','es-ES') as tasa_devolucion
from tasa_devolucion;

/*C18. Usando ROW_NUMBER(), rankea los clientes dentro de cada country por total_spend_usd. Muestra el top 3 por país.*/
with rank_customers_country as (
select
customer_id,
country,
total_spend_usd,
ROW_NUMBER() OVER(Partition by country order by total_spend_usd desc) as rank_country 
from dim_customers
)
select *from rank_customers_country where rank_country <=3

/*C19. Construye un análisis de cohortes: agrupa los clientes por el año de registration_date 
y calcula cuántos están activos (churned = 0) vs churned (churned = 1) en cada cohorte. 
Incluye la tasa de churn por cohorte*/
with cohorte_churned as (
select
year(registration_date) as año_registro,
SUM(CASE WHEN churned = 1 THEN 1 ELSE 0 END) as churn,
SUM(CASE WHEN churned = 0 THEN 1 ELSE 0 END) as no_churn,
count(*) total_clientes
from dim_customers
group by year(registration_date)
)
select año_registro,
churn,
no_churn,
total_clientes,
format((churn * 100.0 / total_clientes),'N2','es-ES') as tasa_churn
from cohorte_churned
order by año_registro asc;

/*C20. Usando CTEs encadenadas, calcula el Customer Lifetime Value (CLV) aproximado por cliente: total_spend_usd / años_desde_registro. 
Clasifica en segmentos: Alto (>$500/año), Medio ($100–$500), Bajo (<$100).*/
WITH CLV as (
select
customer_id,
total_spend_usd as total_gastos,
NULLIF(datediff(year,registration_date,getdate()),0) as año_registro
from dim_customers
group by customer_id,total_spend_usd,registration_date
),
segmento_clv as (
select
customer_id,
total_gastos,
año_registro,
total_gastos/año_registro as clv_anual
from CLV
)
select
customer_id,
total_gastos,
año_registro,
round(clv_anual,2) as clv_anual,
case 
  when clv_anual > 500 then 'alto'
  when clv_anual <=500 and clv_anual >=100 then 'medio'
  else 'bajo'
  end as segmento_clv_customers
from segmento_clv
where clv_anual is not null;

/*C21. Usando LEAD() y LAG() sobre agg_monthly_revenue, calcula para cada mes: revenue actual, mes anterior, mes siguiente y la diferencia con ambos. 
Identifica los meses con mayor caída respecto al mes anterior.*/
with revenue_lead_lag as (
SELECT
    year                                    AS año,
    month                                   AS mes,
    revenue_usd,
    LAG(revenue_usd)  OVER (ORDER BY year, month) AS revenue_mes_anterior,
    LEAD(revenue_usd) OVER (ORDER BY year, month) AS revenue_mes_siguiente,
    revenue_usd - LAG(revenue_usd)  OVER (ORDER BY year, month) AS dif_mes_anterior,
    revenue_usd - LEAD(revenue_usd) OVER (ORDER BY year, month) AS dif_mes_siguiente
FROM agg_monthly_revenue
)
select
año,
mes,
revenue_usd,
revenue_mes_anterior,
revenue_mes_siguiente,
dif_mes_anterior,
dif_mes_siguiente,
case
  when dif_mes_anterior < 0 then 'caida critica'
  when dif_mes_anterior > 0 and dif_mes_anterior <=3000 then 'crecimiento moderado'
  else 'crecimiento exponencial'
  end as segmento_crecimiento
from revenue_lead_lag;
  
/*C22. Construye un PIVOT que muestre el revenue total por category (filas) y 
por year (columnas: 2020, 2021, 2022, 2023, 2024, 2025). Usa PIVOT de SQL Server.*/
with revenue_year as (
select
category,
year,
total_amount_usd
from fact_orders as fo
join dim_calendario as dc on fo.order_date=dc.date
)
select * 
from revenue_year 
pivot ( 
sum(total_amount_usd)
for year in ([2020],[2021],[2022],[2023],[2024],[2025])
) as pivot_table

/*C23. Usando una subconsulta correlacionada, encuentra para cada cliente el monto de su orden más reciente y la categoría de esa orden. 
Muestra customer_id, membership_tier, fecha de última orden, monto y categoría.*/
select dc.customer_id,membership_tier,category,order_date,total_amount_usd from fact_orders as fo
inner join dim_customers as dc on fo.customer_id=dc.customer_id
where fo.order_date = (
select max(order_date) 
from fact_orders as fo2
where fo2.customer_id=fo.customer_id
)
/*C24. Segmenta los clientes en cuartiles RFM usando NTILE(4) sobre days_since_last_purchase (Recencia), 
total_orders (Frecuencia) y total_spend_usd (Monetario). 
Asigna un score RFM total sumando los 3 cuartiles y clasifica: score 10–12 = VIP, 7–9 = Leal, 4–6 = En riesgo, 3 = Perdido.*/
WITH recencia AS (
    SELECT
        customer_id,
        days_since_last_purchase AS ultima_compra
    FROM dim_customers
),

frecuencia AS (
    SELECT
        customer_id,
        COUNT(*) AS total_ordenes
    FROM fact_orders
    GROUP BY customer_id
),

monetario AS (
    SELECT
        customer_id,
        SUM(total_amount_usd) AS total_spend
    FROM fact_orders
    GROUP BY customer_id
),

rfm_base AS (
    SELECT
        r.customer_id,
        r.ultima_compra,
        f.total_ordenes,
        m.total_spend
    FROM recencia  AS r
    INNER JOIN frecuencia AS f ON r.customer_id = f.customer_id
    INNER JOIN monetario  AS m ON r.customer_id = m.customer_id
),

rfm_scores AS (
    SELECT
        customer_id,
        ultima_compra,
        total_ordenes,
        total_spend,

        CASE
            WHEN PERCENT_RANK() OVER (ORDER BY ultima_compra ASC)  <= 0.25 THEN 4
            WHEN PERCENT_RANK() OVER (ORDER BY ultima_compra ASC)  <= 0.50 THEN 3
            WHEN PERCENT_RANK() OVER (ORDER BY ultima_compra ASC)  <= 0.75 THEN 2
            ELSE 1
        END AS r_score,

        CASE
            WHEN PERCENT_RANK() OVER (ORDER BY total_ordenes DESC) <= 0.25 THEN 4
            WHEN PERCENT_RANK() OVER (ORDER BY total_ordenes DESC) <= 0.50 THEN 3
            WHEN PERCENT_RANK() OVER (ORDER BY total_ordenes DESC) <= 0.75 THEN 2
            ELSE 1
        END AS f_score,

        CASE
            WHEN PERCENT_RANK() OVER (ORDER BY total_spend DESC)   <= 0.25 THEN 4
            WHEN PERCENT_RANK() OVER (ORDER BY total_spend DESC)   <= 0.50 THEN 3
            WHEN PERCENT_RANK() OVER (ORDER BY total_spend DESC)   <= 0.75 THEN 2
            ELSE 1
        END AS m_score

    FROM rfm_base
),

rfm_total AS (
    SELECT *,
        (r_score + f_score + m_score) AS total_score
    FROM rfm_scores
)

SELECT
    *,
    CASE
        WHEN total_score >= 10 THEN 'VIP'       
        WHEN total_score >= 7  THEN 'Leal'      
        WHEN total_score >= 5  THEN 'En riesgo' 
        ELSE                        'Perdido'   
    END AS segmento_cliente
FROM rfm_total
ORDER BY total_score DESC;

/*C25. Usando CTEs y RANK(), identifica el producto más vendido (por revenue) dentro de cada categoría por año. 
Muestra solo el rank 1 por categoría/año — el "producto estrella" de cada período.*/
with revenue_category_year as (
select
dc.year as año,
fo.category,
fo.product_name as producto,
sum(fo.total_amount_usd) as revenue
from fact_orders as fo
inner join dim_calendario as dc on fo.order_date=dc.date
group by dc.year,fo.category,fo.product_name
),
rank_category as (
select
año,
category,
producto,
revenue,
rank() over(Partition by año,category order by revenue desc) as rank_producto 
from revenue_category_year
)
select * from rank_category
where rank_producto = 1 
