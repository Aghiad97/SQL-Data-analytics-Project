/*
============================================================================
Customer Report:
============================================================================
Purpose:
- This report consolidates key customer metrics and behaviors
Highlights:
1. Gathers essential fields such as names, ages, and transaction details.
2. Segments customers into categories (VIP, Regular, New) and age groups.
3. Aggregates customer-level metrics:
- total orders
- total sales.
- total quantity purchased
- total products
lifespan (in months)
4. Calculates valuable KPIs:
- recency (months since last order)
- average order value
- average monthly spend
==============================================================================
*/
CREATE VIEW gold.customer_report AS 
WITH base_query AS(
/*----------------------------------------------------------------------------
BASE QUERY:
Retrieves core columns from the tables.
------------------------------------------------------------------------------*/
SELECT 
s.order_number,
s.product_key,
s.order_date,
s.sales_amount,
s.quantity, 
c.customer_key,
c.customer_number,
CONCAT(c.first_name ,' ', c.last_name) AS customer_name,
DATEDIFF(YEAR, c.birth_date, GETDATE()) AS customer_age
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c ON s.customer_key = c.customer_key
)
,customer_aggregation AS (
/*----------------------------------------------------------------------------
2- Customer Aggregation: summarize key Metrics At Customer Level.
------------------------------------------------------------------------------*/
SELECT 
customer_key,
customer_number,
customer_name,
customer_age,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
COUNT(quantity) AS total_quantity,
MAX(order_date) AS last_order_date,
DATEDIFF(MONTH,MIN(order_date), MAX(order_date)) AS life_span
FROM base_query
GROUP BY 
customer_key,
customer_number,
customer_name,
customer_age
)

SELECT 
customer_key,
customer_number,
customer_name,
customer_age,
CASE WHEN customer_age < 20 THEN 'Under 20'
     WHEN customer_age BETWEEN 20 AND 29 THEN '20-29'
     WHEN customer_age BETWEEN 30 AND 39 THEN '30-39'
     WHEN customer_age BETWEEN 40 AND 49 THEN '40-49'
     ELSE 'Over 50'
END AS age_group,
CASE WHEN life_span >= 12 AND total_sales > 5000 THEN 'VIP'
     WHEN life_span >= 12 AND total_sales <= 5000 THEN 'Regular'
     ELSE 'New'
END AS Customer_Segment,
total_orders,
total_sales,
total_quantity,
last_order_date,
DATEDIFF(MONTH,last_order_date, GETDATE()) AS racency, -- last order
life_span,
-- Calculate the average values(AOV)
CASE WHEN total_orders = 0 THEN 0
     ELSE total_sales / total_orders 
END AS Avg_order_value,
-- Calculate the average monthly spends

CASE WHEN life_span = 0 THEN total_sales
     ELSE total_sales / life_span 
     END AS Avg_monthly_spends
FROM customer_aggregation
