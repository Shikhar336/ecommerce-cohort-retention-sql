/* ============================================================
   PART 4: CUSTOMER LIFETIME VALUE (CLV) BY COHORT
   Q3: Which cohorts generate the most value — fairly compared?
   ============================================================ */

WITH customer_cohort AS (
    SELECT
        customer_id,
        MIN(DATE_TRUNC('month', invoice_date)) AS cohort_month
    FROM clean_transactions
    GROUP BY customer_id
),
customer_revenue AS (
    SELECT
        t.customer_id,
        cc.cohort_month,
        SUM(t.quantity * t.unit_price) AS total_spent
    FROM clean_transactions t
    JOIN customer_cohort cc ON t.customer_id = cc.customer_id
    WHERE t.invoice_date < '2011-12-01'
    GROUP BY t.customer_id, cc.cohort_month
),
cohort_clv AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size,
        ROUND(SUM(total_spent), 2) AS total_cohort_revenue,
        ROUND(AVG(total_spent), 2) AS avg_clv_per_customer
    FROM customer_revenue
    GROUP BY cohort_month
),
cohort_with_months AS (
    SELECT
        *,
        (EXTRACT(YEAR FROM DATE '2011-12-01') - EXTRACT(YEAR FROM cohort_month)) * 12
        + (EXTRACT(MONTH FROM DATE '2011-12-01') - EXTRACT(MONTH FROM cohort_month)) AS months_active
    FROM cohort_clv
)
SELECT
    cohort_month,
    cohort_size,
    total_cohort_revenue,
    avg_clv_per_customer,
    months_active,
    ROUND(avg_clv_per_customer / NULLIF(months_active, 0), 2) AS clv_per_month_active
FROM cohort_with_months
ORDER BY cohort_month;

/* Finding: naive avg_clv_per_customer heavily favors older cohorts simply
   because they've had more time to accumulate spend (e.g. Dec 2009:
   ₹8,644.98 total). Once corrected to a per-month-active rate, several
   late-2011 cohorts (e.g. Oct 2011: ₹296.47/month) are competitive with
   or exceed most of 2010's cohorts — consistent with the retention
   recovery found in Part 3.

   Dec 2009 cohort alone contributes ~43% of all-time revenue (₹8.23M
   of ₹19.3M total) — expected given it's the largest, oldest cohort. */
