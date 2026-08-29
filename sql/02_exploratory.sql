/* ============================================================
   PART 2: EXPLORATORY QUERIES
   Basic business understanding before advanced analysis
   All queries run against clean_transactions (see 01_data_cleaning.sql)
   ============================================================ */

-- Total revenue
SELECT ROUND(SUM(quantity * unit_price), 2) AS total_revenue
FROM clean_transactions;
-- Result: ~$19,287,250

-- Revenue by country
SELECT
    country,
    ROUND(SUM(quantity * unit_price), 2) AS revenue,
    COUNT(DISTINCT invoice_no) AS num_orders
FROM clean_transactions
GROUP BY country
ORDER BY revenue DESC
LIMIT 10;
-- Result: UK dominates with ~85% of total revenue

-- Top-selling products by revenue (not just units sold)
SELECT
    stock_code,
    description,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(quantity * unit_price), 2) AS revenue
FROM clean_transactions
GROUP BY stock_code, description
ORDER BY revenue DESC
LIMIT 10;

-- Monthly sales trend
SELECT
    DATE_TRUNC('month', invoice_date) AS sales_month,
    ROUND(SUM(quantity * unit_price), 2) AS revenue,
    COUNT(DISTINCT invoice_no) AS num_orders,
    COUNT(DISTINCT customer_id) AS num_customers
FROM clean_transactions
GROUP BY sales_month
ORDER BY sales_month;
-- Finding: strong seasonal pattern, revenue climbs Sep-Nov each year
-- (gift/ornament retailer — holiday buildup)

-- Active customers per month (excluding partial Dec 2011)
SELECT
    DATE_TRUNC('month', invoice_date) AS sales_month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM clean_transactions
WHERE invoice_date < '2011-12-01'
GROUP BY sales_month
ORDER BY sales_month;
