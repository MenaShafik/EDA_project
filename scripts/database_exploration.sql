select *
from INFORMATION_SCHEMA.TABLES

-----------------------------------
select *
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'dim_customers'


--------------------------------------------
select distinct category_name,subcategory,product_name
from
gold.dim_products

----------------------------------------------------
select min(order_date) first_date,
	   max(order_date) last_date,
	   DATEDIFF(year,MIN(order_date),max(order_date)) as range_year
from gold.fact_sales

select MAX(BDATE),
DATEDIFF(YEAR,MAX(BDATE),GETDATE())
from gold.dim_customers


SELECT SUM(sales_amount)
FROM gold.fact_sales

select count(quantity)
from gold.fact_sales

select avg(price)
from gold.fact_sales

select gender,
count(customer_key) as total_customer
from gold.dim_customers
group by gender
order by total_customer desc


select pd.category_name,
SUM(sls.sales_amount) as total_sales
from gold.fact_sales as sls
left join gold.dim_products as pd
on pd.product_key = sls.product_key
group by pd.category_name
order by total_sales desc





select 
YEAR(order_date) as order_date,
sum(sales_amount),
COUNT(distinct customer_key) as total_customer,
count(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by YEAR(order_date)
order by sum(sales_amount) desc






select datedi(MONTH,order_date) AS order_date,
sum(sales_amount)
from gold.fact_sales
group by DATETRUNC(MONTH,order_date)


------------------------------------



WITH YEARLY_PRODUCT_SALES AS(
SELECT YEAR(F.order_date) AS order_YEAR,
P.product_name,
SUM(F.sales_amount) AS CURRENT_SALES
FROM gold.fact_sales AS F
LEFT JOIN gold.dim_products AS P
ON P.product_key  = F.product_key
WHERE order_date IS NOT NULL
GROUP BY YEAR(F.order_date),P.product_name
)

SELECT order_YEAR,
product_name,
CURRENT_SALES,
AVG(CURRENT_SALES)OVER(PARTITION BY product_name) AS AVG_SALES,
CURRENT_SALES - AVG(CURRENT_SALES)OVER(PARTITION BY product_name) AS PERFORMENCE_SALES,
CASE WHEN CURRENT_SALES - AVG(CURRENT_SALES)OVER(PARTITION BY product_name) > 0 THEN 'Above average'
	 WHEN CURRENT_SALES - AVG(CURRENT_SALES)OVER(PARTITION BY product_name) < 0 THEN 'below average'
else 'average'
end as flag
FROM YEARLY_PRODUCT_SALES
ORDER BY product_name,order_YEAR


with category_sales as
(
select p.category,
SUM(f.sales_amount) as total_sales
from gold.fact_sales f
left join gold.dim_products p
on f.product_key = p.product_key
group by p.category
)
select category,
total_sales,
CONCAT(ROUND(CAST(total_sales as float) * 100 / SUM(total_sales)over(),1),' %') as overall_sales
from category_sales


-----------------------------
with seg as (
select product_key,
product_name,
cost,
case when cost < 100 then 'below 100'
 when cost between 100 and 500 then '100-500'
 when cost between 500 and 1000 then '500-1000'
 else 'above 1000'
 end as cost_range
from gold.dim_products
)

select cost_range,
COUNT(product_key) as total_p
from seg
group by cost_range

----------------------
with spend as (
select c.customer_key,
SUM(f.sales_amount) AS sales_total,
min(order_date) as first_order,
min(order_date) as last_order,
DATEDIFF(month,min(order_date),min(order_date)) as lifespan
from gold.fact_sales f
left join gold.dim_customers c
on f.customer_key = c.customer_key
group by c.customer_key
order by DATEDIFF(month,min(order_date),min(order_date)) desc
)
select customer_key,
case when lifespan >= 12 and sales_total > 5000 then 'VIP'
WHEN lifespan >= 12 and sales_total <= 5000 then 'regular'
else 'new'
end customer_seg
from spend

with base_query as(
select f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,c.customer_number,
c.first_name,
c.last_name,
CONCAT(c.first_name,' ',c.last_name) as customer_name,
c.birthdate,
DATEDIFF(YEAR,c.birthdate,GETDATE()) as age
from gold.fact_sales f
left join gold.dim_customers c
on f.customer_key = c.customer_key
where order_date is not null
),
customer_aggregation as (
select 
customer_key,
customer_number,
customer_name,
age,
COUNT(sales_amount) as total_sales,
sum(quantity) as total_quantity,
count(distinct product_key) as total_products,
max(order_date) as last_order_date,
DATEDIFF(month,min(order_date),max(order_date)) as lifespan
from base_query
group by customer_key,
customer_number,
customer_name,
age
)
select customer_key,
customer_number,
customer_name,
age,
case when age < 20  then  'under 20 '
	when age between 20 and 29 then '20-29'
	when age between 30 and 39 then '30-39'
	when age between 40 and 49 then '40-49'
	else '50 and above'
	end as age_group,
case when lifespan >= 12 and total_sales > 5000 then 'VIP'
	 WHEN lifespan >= 12 and total_sales <= 5000 then 'regular'
else 'new'
end customer_segtotal_orders,
total_sales,
total_quantity,
total_products,
DATEDIFF(month,last_order_date,GETDATE()) as recancy,

last_order_date,
lifespan
from customer_aggregation
