-- ============================================================
-- CUSTOMER RETENTION & RFM SEGMENTATION ANALYSIS
-- 02: SYNTHETIC DATA GENERATION
-- Run after 01_schema.sql
--
-- SETSEED fixes PostgreSQL's random() generator so this script
-- produces the SAME data every time it's run. Without this, every
-- run generates different transactions, and any findings reported
-- in the README would not be reproducible by someone re-running
-- this script.
-- ============================================================

SELECT setseed(0.42);

-- Reference "today" for this dataset = 2024-12-31
-- Window of activity: 2023-01-01 to 2024-12-31 (24 months)

-- 800 customers, split into 4 behavioral archetypes:
--   loyal     (25%): frequent, recent, high spend
--   at_risk   (25%): used to buy a lot, gone quiet last 60-150 days
--   churned   (25%): active early on, nothing in 200+ days
--   new       (25%): signed up in last 90 days, few orders so far

INSERT INTO customers (customer_name, country, signup_date, customer_segment)
SELECT
    'Customer_' || g,
    (ARRAY['Nigeria','Ghana','Kenya','South Africa','UK','USA'])[1 + floor(random()*6)::int],
    CASE
        WHEN g % 4 = 3 THEN '2024-12-31'::date - (random()*89)::int  -- new
        ELSE '2023-01-01'::date + (random()*365)::int                -- older cohorts
    END,
    (ARRAY['loyal','at_risk','churned','new'])[1 + (g % 4)]
FROM generate_series(1, 800) AS g;

-- Transactions per archetype
-- LOYAL: 15-30 orders, spread evenly through to recent days (0-30 days ago)
INSERT INTO transactions (customer_id, invoice_date, stock_code, description, quantity, unit_price)
SELECT
    c.customer_id,
    '2024-12-31'::date - (random() * CASE
        WHEN d.n <= 5 THEN 30      -- recent orders
        ELSE 700
    END)::int,
    'SKU' || (1000 + floor(random()*200)::int),
    (ARRAY['Wireless Mouse','Office Chair','Notebook Set','Desk Lamp','USB Cable','Backpack','Water Bottle','Headphones','Phone Case','Power Bank'])[1 + floor(random()*10)::int],
    1 + floor(random()*5)::int,
    round((5 + random()*95)::numeric, 2)
FROM customers c
CROSS JOIN generate_series(1, 22) AS d(n)
WHERE c.customer_segment = 'loyal'
  AND random() < 0.85;

-- AT_RISK: 8-15 orders, but ALL more than 60 days ago, clustered 60-150 days back
INSERT INTO transactions (customer_id, invoice_date, stock_code, description, quantity, unit_price)
SELECT
    c.customer_id,
    '2024-12-31'::date - (60 + random()*90)::int,
    'SKU' || (1000 + floor(random()*200)::int),
    (ARRAY['Wireless Mouse','Office Chair','Notebook Set','Desk Lamp','USB Cable','Backpack','Water Bottle','Headphones','Phone Case','Power Bank'])[1 + floor(random()*10)::int],
    1 + floor(random()*5)::int,
    round((5 + random()*95)::numeric, 2)
FROM customers c
CROSS JOIN generate_series(1, 12) AS d(n)
WHERE c.customer_segment = 'at_risk'
  AND random() < 0.75;

-- CHURNED: 5-12 orders, ALL more than 200 days ago (early in the window only)
INSERT INTO transactions (customer_id, invoice_date, stock_code, description, quantity, unit_price)
SELECT
    c.customer_id,
    '2024-12-31'::date - (200 + random()*450)::int,
    'SKU' || (1000 + floor(random()*200)::int),
    (ARRAY['Wireless Mouse','Office Chair','Notebook Set','Desk Lamp','USB Cable','Backpack','Water Bottle','Headphones','Phone Case','Power Bank'])[1 + floor(random()*10)::int],
    1 + floor(random()*5)::int,
    round((5 + random()*95)::numeric, 2)
FROM customers c
CROSS JOIN generate_series(1, 9) AS d(n)
WHERE c.customer_segment = 'churned'
  AND random() < 0.70;

-- NEW: 1-4 orders, all within their short tenure (since signup, max 89 days ago)
INSERT INTO transactions (customer_id, invoice_date, stock_code, description, quantity, unit_price)
SELECT
    c.customer_id,
    c.signup_date + (random() * GREATEST(1, '2024-12-31'::date - c.signup_date))::int,
    'SKU' || (1000 + floor(random()*200)::int),
    (ARRAY['Wireless Mouse','Office Chair','Notebook Set','Desk Lamp','USB Cable','Backpack','Water Bottle','Headphones','Phone Case','Power Bank'])[1 + floor(random()*10)::int],
    1 + floor(random()*5)::int,
    round((5 + random()*95)::numeric, 2)
FROM customers c
CROSS JOIN generate_series(1, 3) AS d(n)
WHERE c.customer_segment = 'new'
  AND random() < 0.65;

-- Sprinkle in some cancelled orders (real datasets always have these — tests the cleaning step)
UPDATE transactions
SET is_cancelled = TRUE,
    quantity = -1 * quantity
WHERE random() < 0.03;

-- Quick sanity check
SELECT customer_segment, count(DISTINCT c.customer_id) AS customers, count(t.invoice_no) AS orders
FROM customers c
LEFT JOIN transactions t ON t.customer_id = c.customer_id
GROUP BY customer_segment
ORDER BY customer_segment;
