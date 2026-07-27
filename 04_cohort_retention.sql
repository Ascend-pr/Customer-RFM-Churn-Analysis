-- ============================================================
-- CUSTOMER RETENTION & RFM SEGMENTATION ANALYSIS
-- 04: COHORT RETENTION ANALYSIS
-- Run after 01_schema.sql, 02_generate_data.sql, and 03_rfm_analysis.sql
--
-- Groups customers by their FIRST PURCHASE month, then tracks
-- what % of each cohort is still buying N months later.
-- ============================================================

-- STEP 1: First purchase month per customer
DROP VIEW IF EXISTS customer_first_purchase;
CREATE VIEW customer_first_purchase AS
SELECT
    customer_id,
    DATE_TRUNC('month', MIN(invoice_date))::date AS cohort_month
FROM clean_transactions
GROUP BY customer_id;

-- STEP 2: Activity month per customer (every distinct month they bought something)
DROP VIEW IF EXISTS customer_activity_months;
CREATE VIEW customer_activity_months AS
SELECT DISTINCT
    customer_id,
    DATE_TRUNC('month', invoice_date)::date AS activity_month
FROM clean_transactions;

-- STEP 3: Join activity to cohort, compute month offset (months since first purchase)
DROP VIEW IF EXISTS cohort_activity;
CREATE VIEW cohort_activity AS
SELECT
    fp.cohort_month,
    fp.customer_id,
    am.activity_month,
    -- month offset = number of calendar months between cohort and activity
    (EXTRACT(YEAR FROM am.activity_month) - EXTRACT(YEAR FROM fp.cohort_month)) * 12
        + (EXTRACT(MONTH FROM am.activity_month) - EXTRACT(MONTH FROM fp.cohort_month)) AS month_offset
FROM customer_first_purchase fp
JOIN customer_activity_months am ON am.customer_id = fp.customer_id;

-- STEP 4: Cohort size (customers per cohort)
DROP VIEW IF EXISTS cohort_size;
CREATE VIEW cohort_size AS
SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_customers
FROM customer_first_purchase
GROUP BY cohort_month;

-- STEP 5: Retention table - % of cohort still active at each month offset
DROP VIEW IF EXISTS cohort_retention;
CREATE VIEW cohort_retention AS
SELECT
    ca.cohort_month,
    cs.cohort_customers,
    ca.month_offset,
    COUNT(DISTINCT ca.customer_id) AS active_customers,
    ROUND(100.0 * COUNT(DISTINCT ca.customer_id) / cs.cohort_customers, 1) AS retention_pct
FROM cohort_activity ca
JOIN cohort_size cs ON cs.cohort_month = ca.cohort_month
GROUP BY ca.cohort_month, cs.cohort_customers, ca.month_offset
ORDER BY ca.cohort_month, ca.month_offset;

-- Preview: retention curve for the first few cohorts, month 0 through 6
SELECT cohort_month, cohort_customers, month_offset, active_customers, retention_pct
FROM cohort_retention
WHERE month_offset BETWEEN 0 AND 6
ORDER BY cohort_month, month_offset
LIMIT 40;
