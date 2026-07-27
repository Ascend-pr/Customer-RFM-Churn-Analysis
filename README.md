# Customer Retention & RFM Segmentation Analysis (PostgreSQL)

PostgreSQL project segmenting customers by RFM (Recency, Frequency, Monetary) and analyzing cohort retention to identify revenue at risk and pinpoint where customers churn — built from raw transactions to business recommendations using CTEs, window functions, and views.

## Business Problem

A retail business has 800 customers and thousands of transactions over 24 months. Revenue looks healthy at a glance, but leadership has no visibility into who is about to stop buying, or how much revenue is quietly at risk. This project answers that using SQL alone — no BI tool, no pre-labeled churn flag — going from raw transactions to a segmented, dollar-quantified action list.

## Dataset

- Synthetic transaction data, generated directly in PostgreSQL with a **fixed random seed** so results are reproducible on every run
- 800 customers, 7,089 orders, across a 24-month period (Jan 2023–Dec 2024)
- Four engineered behavioral archetypes: loyal, at-risk, churned, new (200 customers each, used only to generate realistic patterns — not referenced during analysis)
- Includes a ~3% rate of cancelled orders, explicitly filtered out before scoring

## Schema

- `customers (customer_id, customer_name, country, signup_date)`
- `transactions (invoice_no, customer_id, invoice_date, stock_code, quantity, unit_price, is_cancelled)`

## What the SQL Does

1. **`01_schema.sql`** — table and index design
2. **`02_generate_data.sql`** — synthetic data generation with `generate_series` and engineered behavioral cohorts, seeded for reproducibility
3. **`03_rfm_analysis.sql`** — cleaning view → customer-level Recency/Frequency/Monetary → `NTILE(5)` window-function scoring → segment labeling (Champion, At Risk, Lost, etc.)
4. **`04_cohort_retention.sql`** — first-purchase cohort assignment, month-offset calculation, and a self-referencing retention curve (% of each signup cohort still active N months later)

Runs top to bottom with no manual setup beyond creating the database.

**Core techniques used:** common table expressions, views, `NTILE()` window functions, `DATE_TRUNC`, self-joins for cohort offsetting, conditional aggregation.

## Key Findings

*(numbers below are the actual output of running these scripts as-is — reproducible by anyone who clones this repo)*

**1. Revenue is heavily concentrated.**
The "Champion" segment (195 customers, averaging 4 days since last order) drives **51.7% of total revenue ($563,380)**. That's a healthy core, but it means the business has very little cushion if even a fraction of that group disengages.

**2. 29% of revenue sits with customers already going quiet.**
"At Risk" and "At Risk (High Value)" segments — 292 customers combined — represent **29.0% of total revenue (~$316,469)**. These aren't low-value customers: their average order count (6.3–9.8) is close to Champions. They're lapsing, not disengaging entirely.

**3. There's a retention cliff right after the first purchase month.**
Across cohorts, activity starts at 100% in month 0 and drops to roughly 33–48% by month 1, then fluctuates in that band rather than continuing to decay. This consistent, sharp drop — rather than a gradual decline — points to something structural in the post-purchase experience (onboarding, follow-up timing, or second-purchase incentive), not random attrition.

| Segment | Customers | Avg Days Since Last Order | Avg Orders | Total Revenue | % of Revenue |
|---|---|---|---|---|---|
| Champion | 195 | 4 | 17.9 | $563,380.25 | 51.7% |
| At Risk | 247 | 222 | 6.3 | $240,812.02 | 22.1% |
| Needs Attention | 182 | 53 | 6.3 | $169,022.13 | 15.5% |
| At Risk (High Value) | 45 | 85 | 9.8 | $75,657.16 | 6.9% |
| New / Low Engagement | 96 | 5 | 1.9 | $29,238.28 | 2.7% |
| Promising | 25 | 4 | 3.0 | $11,559.27 | 1.1% |
| Lost | 1 | 389 | 3.0 | $644.89 | 0.1% |

Full segment output: [`rfm_segment_summary.csv`](rfm_segment_summary.csv)
Full cohort-by-cohort retention curve: [`cohort_retention.csv`](cohort_retention.csv)

## Recommendation

- **Prioritize win-back outreach to "At Risk (High Value)" first** — 45 customers, $75.7K in revenue, still ordering close to Champion frequency (9.8 avg orders) despite an 85-day average gap. Highest expected return per customer contacted.
- **Investigate the month-0 → month-1 drop-off.** The pattern is consistent enough across cohorts to suggest a fixable structural gap — most likely around onboarding or the timing of a second-purchase incentive — rather than coincidence.
- **Deprioritize "Lost."** Only 1 customer, $644.89, 389 days dormant. Not worth campaign spend.

## Reproducibility

`02_generate_data.sql` calls `SELECT setseed(0.42);` before generating any random data. This means anyone who clones this repo and runs the four scripts in order will get the **exact same** customers, transactions, and downstream findings shown above — not just a similar-looking dataset.

## Stack

PostgreSQL 16. No external libraries — pure SQL from raw transactions to business recommendation.

## Author

Promise Odufuwa (Ascend)
Data Analyst
