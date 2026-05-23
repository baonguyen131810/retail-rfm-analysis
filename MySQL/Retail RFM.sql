-- =========================================================================
-- I. data cleaning
-- =========================================================================
-- import data from source, checking for all null value
-- using 1/4/2021 or quarter 2 of 2021 as the analysis date since last date on data is in 2/2021
-- 1. SALES
select *
  from sales
 where order_number is null 
    or line_item is null 
    or order_date is null 
    or delivery_date is null
    or product_key is null
    or customer_key is null
    or store_key is null
    or quantity is null
;

-- multible rows with null delivery_date, in-store order, no need to clean these column, can add a column to classify order
-- Add order_type column to make in-store vs online
-- order and delivery date is also format wrrong
-- assuming online order is place by customers in their country, use to analyse online/in-store order

drop table if exists cleaned_sales;
create table cleaned_sales as 
select s.order_number,
       s.line_item,
       str_to_date(s.order_date, '%Y-%m-%d') AS order_date,
       str_to_date(s.delivery_date, '%Y-%m-%d') AS delivery_date,
       s.customer_key,
       s.store_key,
       s.product_key,
       s.quantity,
    case 
      when s.store_key = 0 then 'Online'
      else 'In-store'
    end as order_type,
       c.country,
    case
         when month(s.order_date) <= 3  then str_to_date(concat(year(s.order_date), '-01-01'), '%Y-%m-%d')
         when month(s.order_date) <= 6  then str_to_date(concat(year(s.order_date), '-04-01'), '%Y-%m-%d')
         when month(s.order_date) <= 9  then str_to_date(concat(year(s.order_date), '-07-01'), '%Y-%m-%d')
         else str_to_date(concat(year(s.order_date), '-10-01'), '%Y-%m-%d')
    end as order_quarter
  from sales s
  left join customers c on c.customer_key = s.customer_key
;

-- Validate the delivery_date
select * 
  from cleaned_sales s
 where (s.store_key = 0 and s.delivery_date is null) -- online order with no delivery_date
    or (s.store_key <> 0 and s.delivery_date is not null) -- in-store order with delivery_date
;
-- no wrong records


-- sanity check: delivery date < order date error
select order_number, line_item, order_date, delivery_date
  from cleaned_sales
 where delivery_date < order_date
;
-- no records 

-- valid quantity
select * 
  from cleaned_sales s 
 where s.quantity <= 0
;
-- no records
-- checking mismatched foregin key (id or key that is not recorded)
select 'orphaned product_key' as issue, count(*) as count
  from cleaned_sales cs
 where not exists (select 1 from products p where p.product_key = cs.product_key)
 union all
select 'orphaned customer_key' as issue, count(*) as count
  from cleaned_sales cs
 where not exists (select 1 from customers c where c.customer_key = cs.customer_key)
 union all
select 'orphaned store_key' as issue, count(*) as count
  from cleaned_sales cs
 where not exists (select 1 from stores s where s.store_key = cs.store_key)
;
-- duplicate check (order_number, line_item)
select order_number, line_item, COUNT(*) AS dup_rows
  from cleaned_sales
 group by 1, 2
having dup_rows > 1
;
-- No duplicates found.

-- 2. CUSTOMERS
select *
  from customers
 where customer_key is null 
    or gender is null
    or name is null
    or country is null 
    or state is null
    or state_code is null
    or city is null
    or zip_code is null
    or continent is null
    or birthday is null
;

-- birthday sanity check
select count(*)
from customers c
where str_to_date(birthday, '%d/%m/%Y') > '2021-03-31'
-- no records

-- customers with no order should be excluded since there are no behaviours to analyzed and segments
-- state code is null for napoli, italy does have provice code 'na' for napoli, update the table
-- exclude unnecessary personal identifiers for the analysis
-- re-format birthday and calculate age and age_group for better segmentation
drop table if exists cleaned_cus;
create table cleaned_cus as
select *,
       case 
       	 when c.age < 18 then 'under 18'
	     when c.age between 18 and 24 then '18-24'
	     when c.age between 25 and 34 then '25-34'
	     when c.age between 35 and 44 then '35-44'
	     when c.age between 45 and 54 then '45-54'
	     else '55+'
       end as age_group  
  from (select customer_key, 
               gender, 
               country,
               case 
                 when state = 'Napoli' then 'NA'
                 else state_code
               end as state_code,
               city,
               timestampdiff(year, str_to_date(birthday, '%d/%m/%Y'), '2021-03-31') as age
          from customers) c
;

-- duplicate
select customer_key, count(*) AS dup_rows
  from cleaned_cus
 group by 1
having dup_rows > 1
;
-- no duplicate 

-- valid data check 
select customer_key, age
  from cleaned_cus
 where age < 0 OR age > 100
;


-- 3. PRODUCTS
select *
  from products
 where
       product_key is null
    or product_name is null
    or brand is null
    or color is null
    or unit_cost_usd is null
    or unit_price_usd is null
    or subcategory is null
    or subcategory_key is null
    or category_key is null
    or category is null
 ;
-- no null value 
-- Duplicate check
select product_key, count(*) AS dup_rows
  from products
 group by 1
having dup_rows > 1
;
-- No duplicates
-- price/cost logic (investigate if cost >= price, or 0 cost/price)
select product_key, product_name, unit_cost_usd, unit_price_usd
  from products
 where unit_cost_usd >= unit_price_usd
    or unit_price_usd = 0
    or unit_cost_usd  = 0
;

drop table if exists cleaned_product;
create table cleaned_product as
select product_key,
       brand,
       color,
       unit_cost_usd as cost,
       unit_price_usd as price, 
       unit_price_usd - unit_cost_usd as profit,
       subcategory,
       category
  from products;

-- 4. STORES
select *
from stores
where
      store_key is null
   or country is null 
   or state is null
   or open_date is null
   or square_meters is null
;
-- online store have null square_meters, valid data
-- duplicate check
select store_key, COUNT(*) AS dup_rows
  from stores
 group by 1
having dup_rows > 1
;
-- No duplicates.

-- =========================================================================
-- II. Create new tables for customer segmentations
-- =========================================================================
-- 1. Revenue table
drop table if exists revenue;
create table revenue as -- money earned from each line_item from each order
select s.customer_key,
       s.order_number,
       s.country,
       s.line_item,
       s.order_date,
       s.order_type,
       s.product_key, 
       p.price, 
       p.cost,
       s.quantity, 
       (price * s.quantity) as revenue_usd,
       (cost * s.quantity) as cost_usd,
       (profit * s.quantity) as profit_usd
  from cleaned_sales s 
  left join cleaned_product p on p.product_key = s.product_key
;

select customer_key, timestampdiff(month,max(cs.order_date),'2021-04-01')
  from cleaned_sales cs
 where cs.customer_key = 301

-- 2. RFM features: recency, frequency and monetary.
drop table if exists cus_rfm;
create table cus_rfm as
select s.customer_key, 
      floor(timestampdiff(month,max(s.order_quarter),'2021-04-01') /3) recency,
      round(
            (count(distinct s.order_number)/(floor(timestampdiff(month,min(s.order_quarter),'2021-04-01') /3) ))
            ,2) frequency,
      sum(r.revenue_usd) monetary_usd,
      floor(timestampdiff(month, min(s.order_quarter), max(s.order_quarter)) / 3) as active_span
 from cleaned_sales s 
 join revenue r 
   on s.order_number = r.order_number
  and s.line_item = r.line_item
group by 1
;

-- 3. quintile scoring
drop table if exists iqr;
create table iqr as -- segment each new features into 5 quatiles 
select c.customer_key, recency r, frequency f, monetary_usd m,
      ntile(5) over (order by recency desc) as iqr_r, -- split into 5 equal quatiles in descending order by counting (smaller r = more recent = better)
      ntile(5) over (order by frequency asc) as iqr_f, -- split into 5 equal quatiles in ascending order by counting
      ntile(5) over (order by monetary_usd asc) as iqr_m -- split into 5 equal quatiles in ascending order by counting 
from cus_rfm c
;

-- 4. Quartile boundary values for descriptive statistic
drop table if exists iqr_bounds;
create table iqr_bounds -- creating table with set column 1st 
(
ntiles int,
r int,
f decimal(10,2),
m decimal(10,2)
)
;

insert into iqr_bounds (ntiles) values
(0),(1),(2),(3),(4),(5); -- add value for ntiles, 0 for starting value, the rest represents each quatiles

update iqr_bounds ib -- update the table by getting each features' boundaries in a window functions' result from table iqr 
join (
      select 0 as ntiles, max(r) r 
      from iqr 
      union all
      select iqr_r, min(r) 
      from iqr 
      group by iqr_r
     ) 
  as rb on rb.ntiles = ib.ntiles
join (
      select 0 as ntiles, min(f) f 
      from iqr
      union all
      select iqr_f, max(f) 
      from iqr  
      group by iqr_f
     ) 
  as fb on fb.ntiles  = ib.ntiles
join (
      select 0 as ntiles, min(m) m 
      from iqr
      union all
      select iqr_m, max(m) 
      from iqr 
      group by iqr_m
      ) 
  as mb on mb.ntiles = ib.ntiles 
set ib.r = rb.r,
    ib.f = fb.f,
    ib.m = mb.m
;
-- inspections
select * from iqr_bounds ib;

-- using fixed thresholds instead of ntile() because of skewed recency distribution
-- using fixed thresholds helps ensure each score reflects a meaningful business reality
-- 1-2 quarters (within last 6 months) = truly recent   
-- 3-6 quarters (6 months to 1.5 year) = cooling of
-- 7-10 quarters (1.5 to 2.5 years) = disengage
-- 11-14 quarters (2.5 to 3.5 years) = at risk
-- 15+ quarters (3+ years) = dormant

-- 5. RFM scoring 
drop table if exists points; 
create table points as
select
  c.customer_key, c.recency, c.frequency,c.monetary_usd, 
  cc.gender, cc.country, -- for filtering and analyzing
  case    
    when c.recency <= 2  then 5    
    when c.recency <= 6  then 4    
    when c.recency <= 10  then 3   
    when c.recency <= 14 then 2   
    else 1
end as r,
   case  
	when c.frequency > (select f from iqr_bounds where ntiles = 4) then 5
    when c.frequency > (select f from iqr_bounds where ntiles = 3) then 4
    when c.frequency > (select f from iqr_bounds where ntiles = 2) then 3
    when c.frequency > (select f from iqr_bounds where ntiles = 1) then 2
    else 1
  end as  f,
  case 
	when c.monetary_usd > (select m from iqr_bounds where ntiles = 4) then 5
    when c.monetary_usd > (select m from iqr_bounds where ntiles = 3) then 4
    when c.monetary_usd > (select m from iqr_bounds where ntiles = 2) then 3
    when c.monetary_usd > (select m from iqr_bounds where ntiles = 1) then 2
    else 1
  end as m
  from cus_rfm c
  left join cleaned_cus cc on cc.customer_key = c.customer_key
;
drop table if exists rfm_point;
create table rfm_point as
select p.customer_key, concat(r,f,m) as rfm
  from points p
 ;

-- 6. segmentation
-- 125 combination divide in 8 groups
-- Champion: best in all 3 
-- Loyal Customers: consistent but not top spender
-- New Customers: very recent, no history, low spend
-- Promising: quite recent, no history but decent spend
-- Potential Loyal: recent, relatively frequent, decent spending
-- Must Keep: high value but hasn't been active, proven long history
-- At Risk: good value customer, fading with meaningful purchase history
-- Hibernating: dormant, low value or short history 
drop view if exists segmentation;
create view segmentation as 
select p.customer_key, rfm,
      case
	    when r=5 and f>=4 and m>=4 then 'Champions' 
        when r>=4 and f>=3 and m >=3 then 'Loyal Customers' 
        when r>=4 and f>=2 then 'Potential Loyal'
        when c.active_span=0 and m>=3 and r>=3 then 'Promising'
        when c.active_span=0 and r>=3 then 'New Customers' 
        when r in (2,3) and f >= 4 and m>=4 and c.active_span >=8 then 'Must Keep' 
        when r in (2,3) and m>=3 and c.active_span >=4 then 'At Risk'
        else 'Hibernating' 
      end as segment
from points p
join cus_rfm c on c.customer_key = p.customer_key
join rfm_point rp on rp.customer_key = p.customer_key
;

select s.segment  , count(*)
  from segmentation s 
 group by s.segment
 

-- =========================================================================
-- III. cohort for retention rate
-- =========================================================================
-- each customers' 1st order quarter
drop table if exists firstquarter;
create table firstquarter as
select 
    customer_key,
    min(order_quarter) as first_quarter
  from cleaned_sales
 group by customer_key
;

-- quarters until next order
drop table if exists backquarter;
create table backquarter as
select 
    q.customer_key,
    q.first_quarter,
    s.order_quarter,
    floor(timestampdiff(month, q.first_quarter, date_format(s.order_quarter, '%Y-%m-01')) / 3) as qrter_back_count
from firstquarter q
join cleaned_sales s on q.customer_key = s.customer_key
group by 1, 2, 3
;

-- add in segment for analyzing
drop table if exists back_seg;
create table back_seg as
select b.*, s.segment 
  from backquarter b 
  join segmentation s on s.customer_key =b.customer_key 
;

-- number of customers coming back after x quarters from their 1st order month
drop table if exists cus_count;
create table cus_count as
 select
    first_quarter,
    qrter_back_count,
    segment,
    count(distinct customer_key) as customers
  from back_seg
 group by 1, 2
order by 1, 2
;

drop view if exists retention_rate;
create view retention_rate as
select c1.first_quarter, 
       c1.qrter_back_count,
       c1.segment,
       c1.customers, 
       c2.customers as initial_count,
       round(100.0 * c1.customers / c2.customers, 2) as retention_rate
  from cus_count c1
  join cus_count c2 on c1.first_quarter = c2.first_quarter               
                  and c2.qrter_back_count = 0 
                  and c1.qrter_back_count <> 0
  group by 1,2,3
  order by 1,2
;

-- counting new vs returning customer by month (grouping at monthly level, those orderd multiple times in same month count as 1, reduce granular)
drop table if exists returnee;
create table returnee as
select cs.customer_key, date_format(cs.order_date, '%Y-%m-01') order_month,  
    case 
    	when date_format(cs.order_date, '%Y-%m-01') = f.first_month then 'New'
    	else 'Return'
    end as 'type',
    cs.order_number,
    cs.country
  from cleaned_sales cs 
  left join (select s.customer_key, date_format(min(s.order_date), '%Y-%m-01') first_month
               from cleaned_sales s
              group by 1
            ) f on f.customer_key = cs.customer_key 
  group by 1,2; -- 1 customer, 1 unique order months

-- double check result
select r.customer_key
  from returnee r 
 where r.`type` = 'new'
 group by 1 
having count(r.`type` ) = 2
-- no worng record 


 
  