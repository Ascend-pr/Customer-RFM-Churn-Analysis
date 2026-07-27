-- ============================================================
-- CUSTOMER RETENTION & RFM SEGMENTATION ANALYSIS
-- 03: RFM ANALYSIS
-- Run after 01_schema.sql and 02_generate_data.sql
-- "Today" reference date = 2024-12-31 (last day of the synthetic window)
-- ============================================================

-- STEP 1: Clean transaction base (exclude cancellations, build line revenue)
DROP VIEW IF EXISTS clean_transactions;
CREATE VIEW clean_transactions AS
SELECT
    invoice_no,
    customer_id,
    invoice_date,
    quantity,
    unit_price,
    quantity * unit_price AS line_revenue
FROM transactions
WHERE is_cancelled = FALSE
  AND quantity > 0;

-- STEP 2: Customer-level RFM base metrics
DROP VIEW IF EXISTS customer_rfm_base;
CREATE VIEW customer_rfm_base AS
SELECT
    c.customer_id,
    c.customer_name,
    c.country,
    DATE '2024-12-31' - MAX(ct.invoice_date) AS recency_days,
    COUNT(DISTINCT ct.invoice_no) AS frequency,
    COALESCE(SUM(ct.line_revenue), 0) AS monetary
FROM customers c
LEFT JOIN clean_transactions ct ON ct.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.country;

-- STEP 3: RFM scoring using NTILE window functions (1=worst, 5=best)
-- Note: recency is reversed (lower days = better score = higher ntile)
DROP VIEW IF EXISTS customer_rfm_scored;
CREATE VIEW customer_rfm_scored AS
SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,   -- fewer days = higher score
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
FROM customer_rfm_base
WHERE frequency > 0;  -- exclude customers with zero valid orders (e.g. all cancelled)

-- STEP 4: Combine into segment code + human label
DROP VIEW IF EXISTS customer_rfm_final;
CREATE VIEW customer_rfm_final AS
SELECT
    *,
    CONCAT(r_score, f_score, m_score) AS rfm_code,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
        WHEN r_score >= 4 AND f_score BETWEEN 2 AND 3 THEN 'Promising'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'At Risk (High Value)'
        WHEN r_score <= 2 AND f_score BETWEEN 2 AND 3 THEN 'At Risk'
        WHEN r_score = 1 AND f_score <= 2 THEN 'Lost'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New / Low Engagement'
        ELSE 'Needs Attention'
    END AS segment_label
FROM customer_rfm_scored;

-- Preview: segment summary (count of customers, revenue contribution, avg recency)
SELECT
    segment_label,
    COUNT(*) AS customers,
    ROUND(AVG(recency_days), 0) AS avg_days_since_last_order,
    ROUND(AVG(frequency), 1) AS avg_orders,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_of_total_revenue
FROM customer_rfm_final
GROUP BY segment_label
ORDER BY total_revenue DESC;
