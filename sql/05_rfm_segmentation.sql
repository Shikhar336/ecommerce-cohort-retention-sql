/* ============================================================
   PART 5: RFM SEGMENTATION
   Q4: Which customers should the business prioritize?
   ============================================================ */

-- Step 1-2: Raw R/F/M values + 1-5 scores via NTILE()
WITH customer_rfm_raw AS (
    SELECT
        customer_id,
        (DATE '2011-12-01' - MAX(invoice_date)::date) AS recency_days,
        COUNT(DISTINCT invoice_no) AS frequency,
        ROUND(SUM(quantity * unit_price), 2) AS monetary
    FROM clean_transactions
    WHERE invoice_date < '2011-12-01'
    GROUP BY customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        -- Recency: fewer days since last purchase = better, so DESC to make
        -- the most-recent customers land in the top (5) bucket
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM customer_rfm_raw
)
SELECT * FROM rfm_scored;

-- Step 3: Combine scores into segment labels + revenue contribution per segment
WITH customer_rfm_raw AS (
    SELECT
        customer_id,
        (DATE '2011-12-01' - MAX(invoice_date)::date) AS recency_days,
        COUNT(DISTINCT invoice_no) AS frequency,
        ROUND(SUM(quantity * unit_price), 2) AS monetary
    FROM clean_transactions
    WHERE invoice_date < '2011-12-01'
    GROUP BY customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM customer_rfm_raw
),
rfm_segmented AS (
    SELECT
        customer_id,
        monetary,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost / Hibernating'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
            ELSE 'Needs Attention'
        END AS segment
    FROM rfm_scored
)
SELECT
    segment,
    COUNT(*) AS num_customers,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_of_total_revenue
FROM rfm_segmented
GROUP BY segment
ORDER BY total_revenue DESC;

/* Finding: Champions (~22% of customers) generate 68.8% of total revenue.
   Lost/Hibernating + New Customers combined (~30% of customers) generate
   only ~3.1% of revenue. Segment sizes are well-balanced (no single
   segment dominates headcount), validating the chosen scoring thresholds. */
