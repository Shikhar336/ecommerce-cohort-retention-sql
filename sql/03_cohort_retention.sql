/* ============================================================
   PART 3: COHORT RETENTION ANALYSIS
   Q1: When do customers stop coming back?
   Q2: Is retention improving or worsening over time?
   ============================================================ */

-- Step 1: Assign each customer to a cohort (month of their first purchase)
WITH customer_cohort AS (
    SELECT
        customer_id,
        MIN(DATE_TRUNC('month', invoice_date)) AS cohort_month
    FROM clean_transactions
    GROUP BY customer_id
)
SELECT * FROM customer_cohort;
-- Result: 5,864 unique customers assigned to cohorts

-- Step 2-4: Full retention matrix (long format), with retention %
WITH customer_cohort AS (
    SELECT
        customer_id,
        MIN(DATE_TRUNC('month', invoice_date)) AS cohort_month
    FROM clean_transactions
    GROUP BY customer_id
),
cohort_data AS (
    SELECT
        t.customer_id,
        cc.cohort_month,
        DATE_TRUNC('month', t.invoice_date) AS purchase_month
    FROM clean_transactions t
    JOIN customer_cohort cc ON t.customer_id = cc.customer_id
    WHERE t.invoice_date < '2011-12-01'
),
cohort_counts AS (
    SELECT
        cohort_month,
        (EXTRACT(YEAR FROM purchase_month) - EXTRACT(YEAR FROM cohort_month)) * 12 +
        (EXTRACT(MONTH FROM purchase_month) - EXTRACT(MONTH FROM cohort_month)) AS months_since_first_purchase,
        COUNT(DISTINCT customer_id) AS num_customers
    FROM cohort_data
    GROUP BY cohort_month, purchase_month
),
cohort_size AS (
    SELECT cohort_month, num_customers AS total_customers
    FROM cohort_counts
    WHERE months_since_first_purchase = 0
)
SELECT
    cc.cohort_month,
    cc.months_since_first_purchase,
    cc.num_customers,
    cs.total_customers,
    ROUND(100.0 * cc.num_customers / cs.total_customers, 1) AS retention_pct
FROM cohort_counts cc
JOIN cohort_size cs ON cc.cohort_month = cs.cohort_month
ORDER BY cc.cohort_month, cc.months_since_first_purchase;
-- Finding: sharp drop in month 1 across virtually every cohort
-- (e.g. Dec 2009: 100% -> 35.3%; Jun 2010: 100% -> 17.6%)

-- Step 5 (Q2): Month-1 retention trend across cohorts, over time
WITH customer_cohort AS (
    SELECT
        customer_id,
        MIN(DATE_TRUNC('month', invoice_date)) AS cohort_month
    FROM clean_transactions
    GROUP BY customer_id
),
cohort_data AS (
    SELECT
        t.customer_id,
        cc.cohort_month,
        DATE_TRUNC('month', t.invoice_date) AS purchase_month
    FROM clean_transactions t
    JOIN customer_cohort cc ON t.customer_id = cc.customer_id
    WHERE t.invoice_date < '2011-12-01'
),
cohort_counts AS (
    SELECT
        cohort_month,
        (EXTRACT(YEAR FROM purchase_month) - EXTRACT(YEAR FROM cohort_month)) * 12 +
        (EXTRACT(MONTH FROM purchase_month) - EXTRACT(MONTH FROM cohort_month)) AS months_since_first_purchase,
        COUNT(DISTINCT customer_id) AS num_customers
    FROM cohort_data
    GROUP BY cohort_month, purchase_month
),
cohort_size AS (
    SELECT cohort_month, num_customers AS total_customers
    FROM cohort_counts
    WHERE months_since_first_purchase = 0
)
SELECT
    cc.cohort_month,
    cs.total_customers AS cohort_size,
    ROUND(100.0 * cc.num_customers / cs.total_customers, 1) AS month1_retention_pct
FROM cohort_counts cc
JOIN cohort_size cs ON cc.cohort_month = cs.cohort_month
WHERE cc.months_since_first_purchase = 1
ORDER BY cc.cohort_month;
-- Finding: retention worsened through 2010 (bottomed at 9.2% in Dec 2010),
-- then recovered through 2011 (up to 31.7% by Oct 2011)

-- Step 6: Wide-format cohort retention matrix (for README / heatmap)
WITH customer_cohort AS (
    SELECT
        customer_id,
        MIN(DATE_TRUNC('month', invoice_date)) AS cohort_month
    FROM clean_transactions
    GROUP BY customer_id
),
cohort_data AS (
    SELECT
        t.customer_id,
        cc.cohort_month,
        DATE_TRUNC('month', t.invoice_date) AS purchase_month
    FROM clean_transactions t
    JOIN customer_cohort cc ON t.customer_id = cc.customer_id
    WHERE t.invoice_date < '2011-12-01'
),
cohort_counts AS (
    SELECT
        cohort_month,
        (EXTRACT(YEAR FROM purchase_month) - EXTRACT(YEAR FROM cohort_month)) * 12 +
        (EXTRACT(MONTH FROM purchase_month) - EXTRACT(MONTH FROM cohort_month)) AS months_since_first_purchase,
        COUNT(DISTINCT customer_id) AS num_customers
    FROM cohort_data
    GROUP BY cohort_month, purchase_month
),
cohort_size AS (
    SELECT cohort_month, num_customers AS total_customers
    FROM cohort_counts
    WHERE months_since_first_purchase = 0
)
SELECT
    cc.cohort_month,
    cs.total_customers AS cohort_size,
    ROUND(100.0 * MAX(CASE WHEN months_since_first_purchase = 0 THEN num_customers END) / cs.total_customers, 1) AS m0,
    ROUND(100.0 * MAX(CASE WHEN months_since_first_purchase = 1 THEN num_customers END) / cs.total_customers, 1) AS m1,
    ROUND(100.0 * MAX(CASE WHEN months_since_first_purchase = 2 THEN num_customers END) / cs.total_customers, 1) AS m2,
    ROUND(100.0 * MAX(CASE WHEN months_since_first_purchase = 3 THEN num_customers END) / cs.total_customers, 1) AS m3,
    ROUND(100.0 * MAX(CASE WHEN months_since_first_purchase = 4 THEN num_customers END) / cs.total_customers, 1) AS m4,
    ROUND(100.0 * MAX(CASE WHEN months_since_first_purchase = 5 THEN num_customers END) / cs.total_customers, 1) AS m5,
    ROUND(100.0 * MAX(CASE WHEN months_since_first_purchase = 6 THEN num_customers END) / cs.total_customers, 1) AS m6
FROM cohort_counts cc
JOIN cohort_size cs ON cc.cohort_month = cs.cohort_month
GROUP BY cc.cohort_month, cs.total_customers
ORDER BY cc.cohort_month;
