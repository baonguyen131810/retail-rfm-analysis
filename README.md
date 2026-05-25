# Retail Customer Segmentation — RFM Analysis

## Business Context
A global electronics retailer operating across 8 countries, spanning both 
online and in-store channels, with 15,266 registered customers and 26,326 
distinct orders recorded from 2016 to February 2021.

The business grew steadily from 2016 to 2019, peaking at ~$18.3M in revenue. 
Then in 2020, revenue collapsed to ~$9.3M — a 49.1% drop in a single year, 
coinciding with Covid-19 disrupting physical retail globally.

This raised a critical question: if the business wants to recover, which 
customers should it prioritize and how? The goal of this project is to identify 
distinct customer groups based on purchasing behaviour to support targeted 
marketing and retention strategies.

## Overview
To answer that, this project segments 11,887 customers that has ordered using RFM analysis,
using behavior-based approach to score each customer on three metrics:

- **Recency** — how recently they purchased
- **Frequency** — how often they purchase relative to their tenure
- **Monetary** — how much they have spent in total
- **Active Span** — quarters between first and last order, extra supporting
                    metrics to distinguish tuely new customers.

All metrics is computed quarterly, scores were computed in MySQL using quintile-based scoring, with an exception of Recency due heavily skewed ditribution, affecting the business logic to segment customer. Customers were then grouped into 8 segments based on their combined RFM profile.

A cohort retention analysis was also built to track how well the business retains 
customers quarter-over-quarter from their first purchase, giving an extra layer 
into customer loyalty beyond just segmentation.

The full pipeline runs from raw CSV → MySQL cleaning and processing → Power BI 
dashboard with DAX measures.

## Key Findings

## Key Findings

**Overview**
- Order count declined from 2019 while AOV remained stable — customer loss, not reduced spending, is the primary driver of revenue decline.
- Online revenue share is minimal across all markets — significantly underutilized relative to in-store.
- Returning customers held up better than new customers in 2020 — retention base proved more resilient than acquisition during the pandemic.

**Demographics**
- 55+ accounts for 46% of customers and 46% of revenue — volume-driven, not higher spending, as AOV is consistent across age groups.
- Gender split is nearly equal across both revenue and customer count — no meaningful difference.
- 18-24 is the smallest group but AOV is comparable to older groups — long-term loyalty potential if acquisition is prioritized.

**Market**
- US: 5,706 customers, $29.87M revenue, return rate 58.69% — highest loyalty in the system.
- Australia: only 780 customers, $2.71M, return rate 33.16% — lowest loyalty but AOV higher than US ($2,291 vs $2,100).
- Online/In-store ratio ranges 1:3.6–4.4 across all markets — universal dependence on physical stores.
- Revenue mix stable over time — US consistently ~54%, no market emerged as an alternative growth driver.

**Product**
- Computers: 7,459 customers, $2,587 avg spend per customer — leads in both volume and value.
- Music/Movies & Audio Books: highest profit margin (57.14% vs Computers 54.54%) but avg spend only $531 per customer — high-margin, underutilized.
- Computers and Cell phones lead unit sales (44,151 and 31,477 respectively).
- Revenue mix largely stable except Home Appliances (declined from 29% to ~8%) and Computers (grew from 21% to ~43% through the pandemic). Games and Toys consistently negligible (<2%).

**Segmentation**
- Loyal Customers: 3,241 customers, $24.58M (44% of total revenue) — volume-driven, highest priority to protect.
- Must Keep: only 135 customers but avg spending $11,001 — highest in the system, greatest recovery ROI.
- Promising: 561 customers, AOV $4,443 — higher than both Champions ($2,569) and Must Keep ($2,320). Conversion is the priority.
- At Risk: 1,163 customers, $8M revenue, avg order value $2,536 — high-value customers actively slipping.
- Hibernating: 3,135 customers, $9.1M — 2nd largest segment and 2nd highest revenue, all inactive. Poor retention has already cost significant revenue potential.

**Retention**
- ~90-92% of customers do not return within 1–8 quarters — systemic retention failure across all cohort years.
- Retention improved year over year, peaking in 2018-2019 (avg 11-13%), before collapsing to ~3% in 2020 due to the pandemic.
- Retention improves within cohorts over time — avg rises from 7.75% at Q1 to 10.27% at Q8, suggesting customers who do return become more loyal.
- Segment-level retention varies significantly — Champions peaked in 2019 but experienced the steepest decline in 2020.

---

## Strategy

**PROTECT — Champions and Loyal Customers**
- Exclusive offers and early product access to maintain engagement.
- Recency-based alerts every 2 quarters — proactive outreach before they slip.
- Prioritize US market and 55+ demographic across both segments.
- Leverage Computers (high demand, high revenue) and Music/Movies & Audio Books (stable revenue, highest margin) as key offer categories.

**WIN BACK — At Risk and Must Keep**
- At Risk: optimal outreach window is 2–4 quarters after last purchase (7–13% retention rate). Introduce new products or relevant category offers to re-engage.
- Must Keep: small group, high value — personalize outreach, leverage online channel, and offer loyalty program invitations. Female sub-segment shows higher order frequency despite lower count — worth targeting specifically.

**REACTIVATE — Hibernating**
- Use online channel to reach dormant customers.
- Lead with Music/Movies and Cameras as entry points — highest profit margins reduce reactivation cost.
- Customers who became Hibernating within 1–4 quarters still have meaningful return probability — prioritize this sub-group with personalized discounts and new product introductions.

**DEVELOP — New, Promising and Potential Loyal**
- New and Promising: engage within the first year while retention rate is still stable. Regular email or SMS touchpoints about loyalty programs — prioritize retention over revenue extraction.
- Potential Loyal: large group with moderate spend — loyalty programs and targeted offers to encourage repeat purchases and increase share of wallet.
- Online channel: expand utilization to broaden reach, particularly for the 18–34 demographic with the strongest long-term growth potential.

## Tools
- **MySQL** — data cleaning, RFM scoring, cohort retention analysis
- **Power BI** — dashboard and DAX measures
