-- =========================================================================
-- I. data cleaning
-- =========================================================================
-- import data from source, checking for all null value
-- using 31/3/2021 as the analysis date since last date on data is in 2/2021
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
       c.country
  from sales s
  left join customers c on s.customer_key = c.customer_key
;
CREATE INDEX idx_sales_customer ON sales(customer_key);
CREATE INDEX idx_customers_customer ON customers(customer_key);
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

-- 2. RFM features: recency, frequency and monetary.
drop table if exists cus_rfm;
create table cus_rfm as
select s.customer_key, timestampdiff(month,max(s.order_date),'2021-03-31') recency,
      round(
            (count(distinct s.order_number)/timestampdiff(month,min(s.order_date),'2021-03-31'))
            ,2) frequency,
      sum(r.revenue_usd) monetary_usd,
      count(distinct s.order_number) total_order
 from cleaned_sales s 
 join revenue r 
   on s.order_number = r.order_number
  and s.line_item = r.line_item
group by 1
;

-- 3. Quartile scoring
drop table if exists iqr;
create table iqr as -- segment each new features into 4 quatiles 
select c.customer_key, recency r, frequency f, monetary_usd m,
      ntile(4) over (order by recency desc) as iqr_r, -- split into 4 equal quatiles in descending order by counting (smaller r = more recent = better)
      ntile(4) over (order by frequency asc) as iqr_f, -- split into 4 equal quatiles in ascending order by counting
      ntile(4) over (order by monetary_usd asc) as iqr_m -- split into 4 equal quatiles in ascending order by counting 
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
(0),(1),(2),(3),(4); -- add value for ntiles, 0 for starting value, the rest represents each quatiles

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
-- tile 4 of f and m seems to have a much bigger gap to tile 3, compare to the gaps between other tiles
-- signal skewed distribution especially for monetary 



-- 5. RFM scoring 
-- for monetary tile 4, spilt in quantile 90 to distinguish the big spender (whale)
-- First, compute some data point in tile 4 of monetary
select quantile, min(m), max(m)
  from (select c.monetary_usd m,
               ntile(10) over (order by monetary_usd) as 'quantile'
          from cus_rfm c 
       ) q
 where quantile >= 8 
 group by quantile
;

-- the jump from group 9 and 10 is way more significant => 9 (or 90% quantile) will be the splitting point
-- max(m) of 9 is $11059.96
-- segement each features by their q1, q2 and q3 from iqr_bounds and other boundaries
-- add customer lifetime value for visual later
drop table if exists points; 
create table points as
select
  c.customer_key, c.recency, c.frequency,c.monetary_usd, 
  cc.gender, cc.country, -- for filtering and analyzing
  case    
    when c.recency >= (select r from iqr_bounds where ntiles = 1) then 1 
    when c.recency >= (select r from iqr_bounds where ntiles = 2) then 2
    when c.recency >= (select r from iqr_bounds where ntiles = 3) then 3
    else 4
  end as r,
   case  
    when c.frequency > (select f from iqr_bounds where ntiles = 3) then 4
    when c.frequency > (select f from iqr_bounds where ntiles = 2) then 3
    when c.frequency > (select f from iqr_bounds where ntiles = 1) then 2
    else 1
  end as  f,
  case 
	when c.monetary_usd > 11059.96 then 5
    when c.monetary_usd > (select m from iqr_bounds where ntiles = 3) then 4
    when c.monetary_usd > (select m from iqr_bounds where ntiles = 2) then 3
    when c.monetary_usd > (select m from iqr_bounds where ntiles = 1) then 2
    else 1
  end as m
  from cus_rfm c
  left join cleaned_cus cc on cc.customer_key = c.customer_key
;
-- comnine the points as a rfm code for segmentation
drop table if exists rfm_point;
create table rfm_point as
select p.customer_key, concat(r,f,m) rfm
from points p
;

-- 6. segmentation
-- divide by reasonable point conditioning
-- all 80 segments: 
-- Whale(r>=3, f>= 3, m=5): Very recent, frequent, top 10% of spenders. Most valuable.
-- VIP(r>=3, f>= 3, m=3-4): Very recent, frequent, high spend (not top 10%).
-- Big Spender(r>=3, f<= 2, m=5): Recent, infrequent, but top-10% spend. Likely occasional big-ticket.
-- Loyal(r>=3, decent f,m): Consistent, reliable buyers with decent spend.
-- Potential(r>=3, moderate f,m): Recently active, showing loyalty signals — needs a nudge.
-- New Customer(r = 4, f,m in {1,2}): Bought very recently, not enough history to classify yet.
-- At Risk(r=2, f>=3): Was buying frequently or spending heavily, now slowing.
-- Lapsing(r=2, f<=2, m>=3): low/Medium recency, low frequency, historically solid spend.
-- Hibernated (r=1 or r=2 with low f,m): Long inactive. Broad reactivation campaign territory.


drop view if exists segmentation;
create view segmentation as 
select customer_key, rfm,
      case
        when rfm in ('335','345','435','445') then 'Whale'
        when rfm in ('334','343','344','434','443','444') then 'VIP'
        when rfm in ('315','325','415','425') then 'Big Spender'
        when rfm in ('323','324','332','333','342',
                     '423','424','432','433','442') then 'Loyal Customer'
        when rfm in ('311','312','313','314',
                      '321','322','331','341',
                      '413','414','431','441') then 'Potential Loyal'
        when rfm in ('411','412','421','422') then 'New Customer'
        when rfm in ('231','232','233','234','235',
                     '241','242','243','244','245') then 'At Risk'
        when rfm in ('213','214','215',
                      '223','224','225') then 'Lapsing'
        when rfm in ('111','112','113','114','115',
                     '121','122','123','124','125',
                     '131','132','133','134','135',
                     '141','142','143','144','145',
                     '211','212','221','222') then 'Hibernated'
        else 'Uncategorized'
       end as segment
from rfm_point
;

-- =========================================================================
-- III. cohort for retention rate
-- =========================================================================
-- each customers' 1st order month
drop table if exists firstmonth;
create table firstmonth as
select 
    customer_key,
    date_format(min(order_date), '%Y-%m-01') as first_month
  from cleaned_sales
 group by customer_key
;

-- months until next order
drop table if exists backmonth;
create table backmonth as
select 
    m.customer_key,
    m.first_month,
    date_format(s.order_date, '%Y-%m-01') as order_month,
    timestampdiff(month, m.first_month, date_format(s.order_date, '%Y-%m-01')) as month_back_count
from firstmonth m
join cleaned_sales s on m.customer_key = s.customer_key
group by 1, 2, 3
;

-- number of customers coming back after x months from their 1st order month
drop table if exists cus_count;
create table cus_count as
select
    first_month,
    month_back_count,
    count(distinct customer_key) as customers
from backmonth m
group by 1, 2
order by 1, 2
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
    cs.country, cs.order_type
  from cleaned_sales cs 
  left join firstmonth f on f.customer_key = cs.customer_key 
  group by 1,2, f.first_month; -- 1 customer, unique start month and unique order months

-- double check result
select r.customer_key
  from returnee r 
 where r.`type` = 'new'
 group by 1 
having count(r.`type` ) = 2
-- no worng record 


 
  