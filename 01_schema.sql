-- ============================================================
-- CUSTOMER RETENTION & RFM SEGMENTATION ANALYSIS
-- 01: SCHEMA
-- Run in PostgreSQL (psql or pgAdmin query tool)
-- ============================================================

DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id      SERIAL PRIMARY KEY,
    customer_name    VARCHAR(100),
    country           VARCHAR(50),
    signup_date       DATE,
    customer_segment  VARCHAR(20)  -- 'loyal','at_risk','churned','new' — used only to GENERATE data, not for analysis
);

CREATE TABLE transactions (
    invoice_no    SERIAL PRIMARY KEY,
    customer_id   INT REFERENCES customers(customer_id),
    invoice_date  DATE,
    stock_code    VARCHAR(20),
    description   VARCHAR(100),
    quantity      INT,
    unit_price    NUMERIC(10,2),
    is_cancelled  BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_trans_customer ON transactions(customer_id);
CREATE INDEX idx_trans_date ON transactions(invoice_date);
