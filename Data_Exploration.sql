USE DataWarehouse;
-- DATA EXPLORATION SQL SCRIPT
-- Project: EDA for Sales Dataset
-- Purpose: Explore dimensions, measures, and generate key business insights
-- Author: [Aghiad Dagestani]

-- Step 1: Explore Schema

-- List all tables in the database
SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- Inspect columns in the customer dimension table
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';


-- Step 2: Explore Dimensions

-- List unique customer countries
SELECT DISTINCT country FROM gold.dim_customers;

-- List available product categories and subcategories
SELECT DISTINCT category, subcategory, product_name
FROM gold.dim_Products
ORDER BY category, subcategory, product_name;


-- Step 3: Explore Date Dimensions

-- Identify sales date range
SELECT 
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM gold.fact_sales;

-- Calculate number of years covered in sales data
SELECT 
    DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) AS order_range_years
FROM gold.fact_sales;

-- Determine age range of customers
SELECT 
    MIN(birth_date) AS oldest_customer_birthdate,
    DATEDIFF(YEAR, MIN(birth_date), GETDATE()) AS oldest_age,
    MAX(birth_date) AS youngest_customer_birthdate,
    DATEDIFF(YEAR, MAX(birth_date), GETDATE()) AS youngest_age
FROM gold.dim_customers;


-- Step 4: Explore Measures

-- Total sales revenue
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales;

-- Total quantity of items sold
SELECT SUM(quantity) AS total_quantity FROM gold.fact_sales;

-- Average selling price
SELECT AVG(price) AS average_price FROM gold.fact_sales;

-- Total number of orders
SELECT COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales;

-- Total number of unique products
SELECT COUNT(DISTINCT product_key) AS total_products FROM gold.dim_products;

-- Total number of customers
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers;

-- Total number of customers who made a purchase
SELECT COUNT(DISTINCT customer_key) AS purchasing_customers FROM gold.fact_sales;


-- Step 5: Summary of Key Metrics

SELECT 'Total Sales' AS metric, SUM(sales_amount) AS value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(DISTINCT product_key) FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(DISTINCT customer_key) FROM gold.fact_sales;


-- Step 6: Customer and Product Analysis

-- Customer distribution by country
SELECT country, COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Customer distribution by gender
SELECT gender, COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Product count per category
SELECT category, COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- Average product cost per category
SELECT category, AVG(product_cost) AS average_cost
FROM gold.dim_products
GROUP BY category
ORDER BY average_cost DESC;

-- Total revenue per product category
SELECT 
    p.category,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Revenue generated per customer
SELECT 
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f 
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC;

-- Distribution of sold items by country
SELECT 
    c.country,
    SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f 
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;


-- Step 7: Ranking & Performance Analysis

-- Top 5 products by revenue
SELECT TOP(5)
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- Bottom 5 products by revenue
SELECT TOP(5)
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC;

-- Top 5 subcategories by revenue
SELECT TOP(5)
    p.subcategory,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
GROUP BY p.subcategory
ORDER BY total_revenue DESC;
