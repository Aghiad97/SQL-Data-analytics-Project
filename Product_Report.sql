/*
==========================================================================================
Product Report
==========================================================================================
Purpose:
- This report consolidates key product metrics and behaviors.
Highlights:
1. Gathers essential fields such as product name, category, subcategory, and cost.
Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
3. Aggregates product-level metrics:
- total orders
- total sales
- total quantity sold
- total customers (unique)
- lifespan (in months)
4. Calculates valuable KPIs:
- recency (months since last sale)
- average order revenue (AOR)
- average monthly revenue
==========================================================================================
*/
CREATE VIEW gold.product_report AS 
WITH base_query AS (
/*-----------------------------------------------------------------
BASE QUERY: Retrive the core columns from fact_sales, and dim_producs
------------------------------------------------------------------*/
SELECT
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.product_cost,
f.order_number,
f.customer_key,
f.order_date,
f.quantity,
f.sales_amount
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
),
product_aggregation AS(
/*-----------------------------------------------------------------
PRODUCT LEVEL AGGREGATION:
------------------------------------------------------------------*/
SELECT 
product_key,
product_name,
category,
subcategory,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(product_cost) AS total_cost,
COUNT(order_number) AS total_orders,
MAX(order_date) AS last_order,
DATEDIFF(MONTH,MIN(order_date), MAX(order_date)) AS life_span,
count(quantity) AS total_quantity,
SUM(sales_amount) AS total_sales,
ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity,0)),1) AS avg_selling_price
FROM base_query
GROUP BY 
product_key,
product_name,
category,
subcategory,
product_cost
)

SELECT 
product_key,
product_name,
category,
subcategory,
total_customers,
total_cost,
total_orders
last_order,
life_span,
total_quantity,
total_sales,
CASE WHEN total_sales > 50000 THEN 'High-Performers'
     WHEN total_sales >= 10000 THEN 'Mid-Range'
     ELSE 'Low-Performers'
END AS product_performance,
-- CALCUATE THE RACENCY
DATEDIFF(MONTH, last_order, GETDATE()) AS racency,
avg_selling_price,
-- CALCULATE AVERAGE ORDER VALUE:
CASE WHEN total_orders = 0 THEN 0
     ELSE total_sales / total_orders
END AS average_order_value,
-- CALCULATE AVERAGE MONTHLY VALUE
CASE WHEN life_span = 0 THEN total_sales
     ELSE total_sales / life_span
END AS average_monthly_value
FROM product_aggregation
