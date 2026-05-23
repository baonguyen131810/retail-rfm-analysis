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

**Revenue is concentrated in a small active base**
Loyal Customers represent ~28% of the customer base 
but generate ~44% of total revenue ($24.6M). Losing even a small portion of 
this group has outsized revenue impact. Regular recency monitoring and 
proactive outreach every 2 quarters is critical to protect this base.

**A large dormant base represents recoverable value**
Hibernating customers make up the 2nd largest segment (3,135 customers) with 
$9.1M in historical spend — all currently inactive. Must Keep (135 customers) 
is smaller but carries the highest average spend alongside Champions, making 
it the highest ROI recovery target despite its size.

**The business cannot retain new customers**
92% of new customers do not return in their first quarter. Average 1-quarter 
retention is only 7.75% — meaning the business continuously acquires customers 
it cannot keep. This is a structural retention failure that predates 2020 and 
exists across all cohort years, not just a pandemic effect.

**At Risk customers have a recoverable but time-sensitive window**
At Risk customers show only 2.82% retention in quarter 1 but rise to 7–11% 
from quarters 2–4. This means immediate outreach is ineffective — the optimal 
intervention window is 2–4 quarters after last purchase, before they slide 
permanently into Hibernating.

**Online is critically underutilized**
Online revenue accounts for a small fraction of total revenue. Given that 
physical retail was the primary victim of the 2020 decline, online represents 
the most actionable channel for both customer acquisition and retention — 
particularly for younger demographics and markets like Australia where new 
customer proportion is highest.

**Market resilience varies significantly**
Australia and Italy suffered the steepest customer losses in 2020 across both 
new and returning customers — highest priority for win-back campaigns. France 
showed the most resilience with the smallest decline in returning customers 
(-10%), though its small customer base limits the conclusion. US dominates 
volume and loyalty — protecting this market is non-negotiable.

**Product margin opportunity is underutilized**
Computers leads revenue at $19.3M but carries only average profit margin (~54%). 
Music, Movies & Audio Books and Cameras carry the highest margins (~57%) but 
generate significantly lower revenue — high-margin categories that remain 
underutilized relative to their potential.

## Tools
- **MySQL** — data cleaning, RFM scoring, cohort retention analysis
- **Power BI** — dashboard and DAX measures
