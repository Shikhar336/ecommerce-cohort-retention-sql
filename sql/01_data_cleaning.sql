/* ============================================================
   PART 1: DATA LOADING & VALIDATION
   E-commerce Customer Retention & Cohort Analysis
   Dataset: Online Retail II (UCI Machine Learning Repository)
   ============================================================ */

-- Step 1: Create the raw table
CREATE TABLE retail_transactions (
    invoice_no      VARCHAR(20),
    stock_code      VARCHAR(20),
    description     VARCHAR(255),
    quantity        INTEGER,
    invoice_date    TIMESTAMP,
    unit_price      NUMERIC(10,2),
    customer_id     INTEGER,
    country         VARCHAR(50)
);

-- Step 2: Import 2009-2010 and 2010-2011 CSV exports via pgAdmin
-- (Import/Export Data tool -> CSV, Header ON, Encoding WIN1252)

-- Step 3: Convert invoice_date from ambiguous DD-MM-YYYY text to real TIMESTAMP
ALTER TABLE retail_transactions
ALTER COLUMN invoice_date TYPE TIMESTAMP
USING TO_TIMESTAMP(invoice_date, 'DD-MM-YYYY HH24:MI');

-- Step 4: Validation queries — measure the scale of data quality issues

-- Cancelled orders (Invoice starts with "C")
SELECT COUNT(*) FROM retail_transactions WHERE invoice_no LIKE 'C%';
-- Result: 19,494

-- Missing Customer ID
SELECT COUNT(*) FROM retail_transactions WHERE customer_id IS NULL;
-- Result: 243,007 (22.8%)

-- Negative quantity (returns)
SELECT COUNT(*) FROM retail_transactions WHERE quantity < 0;
-- Result: 22,950

-- Non-product "charge" rows (postage, bank fees, manual entries, etc.)
SELECT stock_code, COUNT(*)
FROM retail_transactions
WHERE stock_code IN ('POST', 'BANK', 'M', 'D', 'DOT', 'C2', 'CRUK')
GROUP BY stock_code
ORDER BY COUNT(*) DESC;
-- Result: 5,464 rows total across these codes

-- Exact duplicate transaction rows
SELECT invoice_no, stock_code, customer_id, invoice_date, quantity, COUNT(*)
FROM retail_transactions
GROUP BY invoice_no, stock_code, customer_id, invoice_date, quantity
HAVING COUNT(*) > 1;
-- Result: 33,091 duplicate groups

-- Step 5: Build a non-destructive clean VIEW on top of the raw table
-- (raw data is never deleted — this view is the single source of truth
--  for every later part of the analysis)
CREATE OR REPLACE VIEW clean_transactions AS
SELECT invoice_no, stock_code, description, quantity, invoice_date,
       unit_price, customer_id, country
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY invoice_no, stock_code, customer_id, invoice_date, quantity
               ORDER BY invoice_no
           ) AS row_num
    FROM retail_transactions
    WHERE invoice_no NOT LIKE 'C%'
      AND customer_id IS NOT NULL
      AND quantity > 0
      AND stock_code NOT IN ('POST', 'BANK', 'M', 'D', 'DOT', 'C2', 'CRUK')
) sub
WHERE row_num = 1;

SELECT COUNT(*) FROM clean_transactions;
-- Result: 776,724 clean rows (from 1,067,371 raw rows)

-- Step 6: Confirm exact date range / find data completeness issues
SELECT MIN(invoice_date), MAX(invoice_date) FROM clean_transactions;
-- Result: 2009-12-01 07:45:00 to 2011-12-09 12:50:00
-- NOTE: December 2011 is a PARTIAL month (data cuts off on the 9th).
-- All monthly trend / cohort queries in later parts filter this out
-- with: WHERE invoice_date < '2011-12-01'

-- Step 7: Performance — add indexes on join/filter columns
-- (dropped join query time from ~40s to ~13s on the ~750k-row dataset)
CREATE INDEX idx_customer_id ON retail_transactions(customer_id);
CREATE INDEX idx_invoice_date ON retail_transactions(invoice_date);
