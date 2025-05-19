-- TEMPORAL & PERFORMANCE ANALYSIS
-- Project: Sales Dataset
-- Author: [Aghiad Daghestani]

USE DataWarehouse;
-- Section 1: Monthly Trend Analysis
-- Analyze total sales, total customers, and quantity sold on a monthly basis

SELECT
    DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
ORDER BY month;


-- Section 2: Cumulative Analysis
-- Calculate monthly totals along with running total and moving average of sales

SELECT 
    order_date,
    total_sales,
    SUM(total_sales) OVER(PARTITION BY MONTH(order_date) ORDER BY order_date) AS running_total_sales,
    AVG(avg_sales) OVER(PARTITION BY MONTH(order_date) ORDER BY order_date) AS moving_avg_sales
FROM (
    SELECT 
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS order_date,
        SUM(sales_amount) AS total_sales,
        AVG(sales_amount) AS avg_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
) t;


-- Section 3: Performance Comparison
-- Compare product sales against their historical average and previous year's performance

WITH Yearly_products_sales AS (
    SELECT 
        YEAR(s.order_date) AS order_year,
        p.product_name,
        SUM(s.sales_amount) AS current_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p ON s.product_key = p.product_key
    WHERE order_date IS NOT NULL 
    GROUP BY YEAR(s.order_date), p.product_name
)
SELECT 
    order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER(PARTITION BY product_name) AS yearly_avg,
    current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS avg_diff,
    CASE 
        WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'increase'
        WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'decrease'
        ELSE 'average'
    END AS performance_vs_avg,
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS yoy_difference,
    CASE 
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'increase'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'decrease'
        ELSE 'no_change'
    END AS yoy_trend
FROM Yearly_products_sales
ORDER BY product_name, order_year;


-- Section 4: Part-to-Whole Analysis
-- Determine the percentage contribution of each category to total sales

WITH sales_by_category AS (
    SELECT 
        category,
        SUM(sales_amount) AS total_cat_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products d ON f.product_key = d.product_key
    GROUP BY category
)
SELECT 
    category,
    total_cat_sales,
    SUM(total_cat_sales) OVER() AS total_sales,
    CONCAT(ROUND(CAST(total_cat_sales AS FLOAT) / SUM(total_cat_sales) OVER() * 100, 2), '%') AS percentage_contribution
FROM sales_by_category
ORDER BY percentage_contribution DESC;


-- Section 5: Data Segmentation
-- A. Segment products by cost ranges

WITH product_segments AS (
    SELECT 
        product_key,
        product_name,
        product_cost,
        CASE 
            WHEN product_cost < 100 THEN 'Below_100'
            WHEN product_cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN product_cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above_1000'
        END AS cost_range
    FROM gold.dim_products
)
SELECT 
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments 
GROUP BY cost_range
ORDER BY total_products DESC;


-- B. Segment customers based on purchase behavior

-- Criteria:
-- - VIP: ≥12 months of history & >€5,000 spending
-- - Regular: ≥12 months & ≤€5,000 spending
-- - New: <12 months of activity

WITH customer_spending AS (
    SELECT 
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(f.order_date) AS first_order,
        MAX(f.order_date) AS last_order,
        DATEDIFF(MONTH, MIN(f.order_date), MAX(f.order_date)) AS life_span
    FROM gold.fact_sales f 
    LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
),
customer_segments AS (
    SELECT 
        customer_key,
        total_spending,
        life_span,
        CASE 
            WHEN total_spending > 5000 AND life_span >= 12 THEN 'VIP'
            WHEN total_spending <= 5000 AND life_span >= 12 THEN 'Regular'
            ELSE 'New'
        END AS customer_type
    FROM customer_spending
)
SELECT 
    customer_type,
    COUNT(customer_key) AS total_customers
FROM customer_segments
GROUP BY customer_type
ORDER BY total_customers DESC;
