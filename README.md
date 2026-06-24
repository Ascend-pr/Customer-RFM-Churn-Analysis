# Customer-RFM-Churn-Analysis
PostgreSQL project segmenting customers by RFM (Recency, Frequency, Monetary) and analyzing cohort retention to identify revenue at risk and pinpoint where customers churn, built from raw transactions to business recommendations using CTEs, window functions, and views.
# Customer RFM & Churn Analysis

PostgreSQL project segmenting customers by RFM (Recency, Frequency, Monetary) and analyzing cohort retention to identify revenue at risk and pinpoint where customers churn, built from raw transactions to business recommendations using CTEs, window functions, and views.

## Business Problem

A retail business has hundreds of customers and thousands of transactions across two years of sales history. Revenue looks healthy on the surface, but leadership has no visibility into who is about to stop buying, or how much revenue is quietly at risk. This project answers that using SQL alone, going from raw transaction data to a segmented, dollar-quantified list of where to act first.

## Dataset

- Synthetic transaction data generated directly in PostgreSQL
- 800 customers, ~7,170 orders, across a 24-month period
- Four engineered behavioral patterns: loyal, at-risk, churned, and new
- Includes a 3% rate of cancelled orders, explicitly filtered out before scoring

## What the SQL Does

- Table and index design
- Synthetic data generation
- RFM scoring using window functions
- Cohort retention analysis using self-referencing joins

Runs top to bottom as a single SQL file with no manual setup beyond creating the database.

**Core techniques used:** common table expressions, views, NTILE window functions, DATE_TRUNC, self-joins for cohort offsetting.

## Key Findings

- **Revenue is heavily concentrated.** The top customer segment drives just over half of all revenue, leaving little cushion if even a portion of that group disengages.
- **Nearly 30% of total revenue sits with customers already going quiet.** These aren't low-value customers, their order frequency is close to the top segment. They're lapsing, not disengaging entirely.
- **Every customer cohort shows the same drop-off pattern** right after the first purchase month, then flattens out. This consistency points to a structural gap in the post-purchase experience, not random attrition.

## Recommendation

- Prioritize win-back outreach to the high-value at-risk segment first
- Investigate what happens (or fails to happen) between a customer's first and second purchase, since the drop-off is too consistent across cohorts to be coincidental
- Deprioritize low-value, long-dormant customers — potential return doesn't justify campaign spend

## Author

Promise Odufuwa
Data Analyst
