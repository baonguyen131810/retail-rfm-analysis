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

Scores were computed in MySQL using quartile-based scoring, with an additional 
tier added for the top 10% of spenders to isolate the highest-value group. 
Customers were then grouped into 8 segments based on their combined RFM profile.

A cohort retention analysis was also built to track how well the business retains 
customers month-over-month from their first purchase, giving an extra layer 
into customer loyalty beyond just segmentation.

The full pipeline runs from raw CSV → MySQL cleaning and processing → Power BI 
dashboard with DAX measures.

## Key Findings

**Revenue is dangerously concentrated**
Whale and VIP customers combined represent only 25% of the customer base but 
generate ~49% of total revenue (~$27.4M) - Top priority - have regular inactivity
alarm to reachout. Losing even a small group of this segment can cost the company immensely.

**A large dormant base represents recoverable value**
34.7% of all customers (4,121 people) are Hibernated — inactive for an average 
of 35 months but with $11.3M in historical spend, the highest of all segment. 
special offers, new drops introduction and other engagement stategy are needed 
before they are permanently lost.

**The business is bleeding new customers without realizing it**
97% of new customers do not return in their first month. Month-1 retention 
averages only 3.21%, which means the business is continuously 
acquiring customers it cannot keep — a growth model that does not compound.

**At Risk customers have a narrow recovery window**
Customers in the At Risk segment were previously frequent buyers who have since 
slowed down. Retention data shows they are most responsive within 6 months of 
their last order. Beyond that window, recovery drops sharply. Hence, it will be
best to leverage that time before they slide into hibernation.

**Online is underutilized**
Online channel accounts for only ~20% of revenue ($11.4M vs $44.4M in-store) 
despite identical profit margins (~55%). Given that physical retail was the 
prime victim during the 2020 decline, online could be the way to save and 
grow the business.
