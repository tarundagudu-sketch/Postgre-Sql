
-- AMAZON BRAZIL DATA ANALYSIS
-- THE WHOLE ANALYSIS IS DIVIDED INTO 3 PARTS

/*creating tables and importing data from csv file*/

CREATE TABLE amazon_analysis.customers (
    customer_id            VARCHAR PRIMARY KEY,
    customer_unique_id     VARCHAR,
    customer_zip_code_prefix INTEGER
);

select*from amazon_analysis.customers; --99441 rows

CREATE TABLE amazon_analysis.orders (
    order_id                      VARCHAR PRIMARY KEY,
    customer_id                   VARCHAR,
    order_status                  VARCHAR,
    order_purchase_timestamp      TIMESTAMP,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);
select*from amazon_analysis.orders;--99441 rows

CREATE TABLE amazon_analysis.order_items (
    order_id            VARCHAR,
    order_item_id       INTEGER,
    product_id          VARCHAR,
    seller_id           VARCHAR,
    shipping_limit_date TIMESTAMP,
    price               NUMERIC,
    freight_value       NUMERIC
);
select* from amazon_analysis.order_items;--112650 rows

CREATE TABLE amazon_analysis.product (
    product_id                VARCHAR PRIMARY KEY,
    product_category_name     VARCHAR,
    product_name_lenght       INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty        INTEGER,
    product_weight_g          INTEGER,
    product_length_cm         INTEGER,
    product_height_cm         INTEGER,
    product_width_cm          INTEGER
);
select*from amazon_analysis.product;--32951 rows

CREATE TABLE amazon_analysis.seller (
    seller_id              VARCHAR PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city            VARCHAR,
    seller_state           VARCHAR
);

ALTER TABLE amazon_analysis.seller
DROP COLUMN seller_city,
DROP COLUMN seller_state;

select* from amazon_analysis.seller;--3095 rows

CREATE TABLE amazon_analysis.payments (
    order_id               VARCHAR,
    payment_sequential     INTEGER,
    payment_type           VARCHAR,
    payment_installments   INTEGER,
    payment_value          NUMERIC
);
select* from amazon_analysis.payments;--103886 rows


/*ANALYSIS- I*/
/*question-1 To simplify its financial reports, Amazon India needs to standardize payment values.
Round the average payment values to integer (no decimal) for each payment type and display the results sorted in ascending order*/

select payment_type,
      round( Avg(payment_value),0) AS rounded_average_payment
from amazon_analysis.payments
group by payment_type
order by  rounded_average_payment asc;

/*question-2 To refine its payment strategy, Amazon India wants to know the distribution of orders by payment type.
Calculate the percentage of total orders for each payment type, rounded to one decimal place, and display them in descending order */

select payment_type,
       round(count(*)*100/sum(count(*))over(),1) as percentage_orders
from amazon_analysis.payments
group by payment_type 
order by percentage_orders desc;

/*question 3-Amazon India seeks to create targeted promotions for products within specific price ranges.
Identify all products priced between 100 and 500 BRL that contain the word 'Smart' in their name. 
Display these products, sorted by price in descending order.*/


select o.product_id,
       round(o.price,0)As price
FROM amazon_analysis.order_items o
JOIN amazon_analysis.product p 
ON o.product_id=p.product_id
where o.price between 100 and 500
AND p.product_category_name like '%smart%'
order by o.price desc;

/*question-4 To identify seasonal sales patterns, Amazon India needs to focus on the most successful months.
Determine the top 3 months with the highest total sales value, rounded to the nearest integer.*/

select to_char( order_purchase_timestamp,'month') as month,
       round(sum(oi.price), 0) as total_sales 
from amazon_analysis.orders o
join amazon_analysis.order_items oi
on o.order_id =oi.order_id
group by to_char(order_purchase_timestamp,'month')
order by total_sales desc
limit 3;

/*question-5 Amazon India is interested in product categories with significant price variations.
Find categories where the difference between the maximum and minimum product prices is greater than 500 BRL.*/

select p.product_category_name,round(max(o.price)-min(o.price),0) as price_difference
from amazon_analysis.order_items o
join amazon_analysis.product p 
on p.product_id=o.product_id
WHERE p.product_category_name IS NOT NULL
group by product_category_name
having max(o.price)-min(o.price)>500
order by price_difference desc ;

/*question-6 To enhance the customer experience, Amazon India wants to find which 
payment types have the most consistent transaction amounts. Identify the payment types
with the least variance in transaction amounts, sorting by the smallest standard deviation first.*/

select payment_type,
round(stddev(payment_value),2) as std_deviation
from amazon_analysis.payments
where payment_type!='not_defined'
group by payment_type
order by std_deviation asc;	

/*question-7 Amazon India wants to identify products that may have incomplete name 
in order to fix it from their end. Retrieve the list of products where the product category 
name is missing or contains only a single character.
Output: product_id, product_category_name */

select product_id,product_category_name 
from amazon_analysis.product
where product_category_name is null or length(product_category_name)<=1

/*ANALYSIS-2*/
/*question-1 Amazon India wants to understand which payment types are 
most popular across different order value segments (e.g., low, medium, high)
. Segment order values into three ranges: orders less than 200 BRL, 
between 200 and 1000 BRL, and over 1000 BRL. Calculate the count of each payment
type within these ranges and display the results in descending order of count
Output: order_value_segment, payment_type, count.*/

select 
	   case when payment_value <200 then 'low'
       when payment_value between 200 and 1000 then 'medium'
       else 'high'
       end as order_value_segment,
       payment_type,
       count(payment_value) as count
from amazon_analysis.payments
group by order_value_segment,payment_type
order by count desc;
--select * from  amazon_analysis.payments

/*wuestion-2 Amazon India wants to analyse the price range and average price for each product category.
Calculate the minimum, maximum, and average price for each category, and list them in descending order by the average price.
Output: product_category_name, min_price, max_price, avg_price */
SELECT p.product_category_name,
       MIN(o.price) as min_price,
	   MAX(o.price) as max_price,
	   round(AVG(o.price),2) as avg_price
FROM amazon_analysis.product p 
JOIN amazon_analysis.order_items o
ON p.product_id=o.product_id
GROUP BY product_category_name
ORDER BY avg_price desc;

/* question-3 Amazon India wants to identify the customers who have placed multiple orders over time.
Find all customers with more than one order, and display their customer unique IDs 
along with the total number of orders they have placed.
Output: customer_unique_id, total_orders*/

select c.customer_unique_id,count(o.order_id) as total_orders
from amazon_analysis.customers c
join amazon_analysis.orders o
on c.customer_id=o.customer_id
group by c.customer_unique_id
having count(o.order_id)>1
order by total_orders desc;

       
/*question-4 Amazon India wants to categorize customers into different types 
('New – order qty. = 1' ;  'Returning' –order qty. 2 to 4;  'Loyal' – order qty. >4) 
based on their purchase history. Use a temporary table to define these categories and
join it with the customers table to update and display the customer types.
Output: customer_unique_id, customer_type*/

with new_cte as(
select customer_id,count(order_id) as total_orders,
case when count(order_id)=1 then 'new'
when count(order_id) between 2 and 4 then'returning'
else 'loyal'
end as customer_type	
from amazon_analysis.orders
group by customer_id
)
select c.customer_unique_id,n.customer_type 
from new_cte n 
join amazon_analysis.customers c
on c.customer_id=n.customer_id;

/*question-5 Amazon India wants to know which product categories generate the most revenue. 
Use joins between the tables to calculate the total revenue for each product category. Display the top 5 categories.
Output: product_category_name, total_revenue.*/

select p.product_category_name,sum(o.price) as total_revenue
from amazon_analysis.product p
join amazon_analysis.order_items o 
on p.product_id=o.product_id
group by p.product_category_name
order by total_revenue desc
limit 5;

/*ANALYSIS-3*/
/*question-1 The marketing team wants to compare the total sales between different seasons.
Use a subquery to calculate total sales for each season (Spring, Summer, Autumn, Winter) 
based on order purchase dates, and display the results. Spring is in the months of March, April and May. 
Summer is from June to August and Autumn is between September and November and rest months are Winter. 
Output: season, total_sales*/

select season,sum(total_sales) as total_sales
from(
select oi.price as total_sales,
       case when extract(month from o.order_purchase_timestamp) in (3,4,5) then 'spring'
            when extract(month from o.order_purchase_timestamp) in (6,7,8) then 'summer'
            when extract(month from o.order_purchase_timestamp) in (9,10,11) then 'autumn'
	        else 'winter'
end as season
from amazon_analysis.orders o
join amazon_analysis.order_items oi on o.order_id=oi.order_id
) as sub
group by season
order by total_sales desc;

--select * from amazon_analysis.order_items

SELECT season, ROUND(SUM(total_sales)::numeric, 2) AS total_sales
FROM (
    SELECT 
        oi.price + oi.freight_value AS total_sales,  -- ← ADD freight here
        CASE 
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (3,4,5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (6,7,8) THEN 'Summer'
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (9,10,11) THEN 'Autumn'
            ELSE 'Winter'
        END AS season
    FROM amazon_analysis.orders o
    JOIN amazon_analysis.order_items oi ON o.order_id = oi.order_id
) AS sub
GROUP BY season
ORDER BY total_sales DESC;
/*question-2 The inventory team is interested in identifying products that have 
sales volumes above the overall average. Write a query that uses a subquery to filter products 
with a total quantity sold above the average quantity.

Output: product_id, total_quantity_sold*/

select product_id,count(*) as total_quantity_sold
from amazon_analysis.order_items
group by product_id
having count(*) >
(
select avg(total_quantity) 
from
(
select count(*) as total_quantity
from amazon_analysis.order_items
group by product_id
) as product_total
)
order by total_quantity_sold desc;


/*question-3 To understand seasonal sales patterns, the finance team is analysing
the monthly revenue trends over the past year (year 2018). Run a query to calculate 
total revenue generated each month and identify periods of peak and low sales. 
Export the data to Excel and create a graph to visually represent revenue changes across the months. 

Output: month, total_revenue*/

select round(sum(oi.price),0) as revenue,
       EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month
from amazon_analysis.order_items oi
join amazon_analysis.orders o
on oi.order_id= o.order_id
where o.order_purchase_timestamp between '2018-01-01' and '2018-12-31' 
group by month
order by month asc;


/*question-4 A loyalty program is being designed  for Amazon India. 
Create a segmentation based on purchase frequency: ‘Occasional’ for customers with 1-2 orders, 
‘Regular’ for 3-5 orders, and ‘Loyal’ for more than 5 orders. Use a CTE to classify customers
and their count and generate a chart in Excel to show the proportion of each segment.

Output: customer_type, count.*/

with customer_segments as (
select o.customer_id,
       count(o.order_id) as total_orders,
	   case
	   when count( o.order_id) between 1 and 2 then 'occasional'
       when count( o.order_id) between 3 and 5 then 'regular'
	   else 'loyal'
	 end as customer_type 
from amazon_analysis.orders o
group by o.customer_id
)
select customer_type,
       count(*)as count from customer_segments 
group by customer_type
order by count desc;

/*question-5 Amazon wants to identify high-value customers to target for an exclusive rewards program.
You are required to rank customers based on their average order value (avg_order_value) to find the top 20 customers.

Output: customer_id, avg_order_value, and customer_rank.*/
with cte as(
select 
      o.customer_id,round(avg(oi.price),0) as avg_order_value
from amazon_analysis.orders o 
join amazon_analysis.order_items oi
on oi.order_id= o.order_id
group by o.customer_id
)
select customer_id,avg_order_value,
       rank() over (order by avg_order_value desc) as customer_rank
from cte
order by customer_rank asc
limit 20;

/*question-6 Amazon wants to analyze sales growth trends for its key products over their lifecycle.
Calculate monthly cumulative sales for each product from the date of its first sale. 
Use a recursive CTE to compute the cumulative sales (total_sales) for each product month by month.

Output: product_id, sale_month, and total_sales*/

WITH RECURSIVE monthly_data AS (
    SELECT 
        oi.product_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS sale_month,
        SUM(oi.price) AS monthly_sales
    FROM amazon_analysis.order_items oi
    JOIN amazon_analysis.orders o 
    ON oi.order_id = o.order_id
    GROUP BY oi.product_id, 
             DATE_TRUNC('month', o.order_purchase_timestamp)
),
first_months AS (
    -- separately find first month per product
    -- no confusion 
    SELECT 
        product_id,
        MIN(sale_month) AS first_month
    FROM monthly_data
    GROUP BY product_id
),
cumulative AS (
    -- BASE CASE: start from first month only
    SELECT 
        md.product_id,
        md.sale_month,
        md.monthly_sales,
        md.monthly_sales AS total_sales
    FROM monthly_data md
    JOIN first_months fm 
    ON md.product_id = fm.product_id
    AND md.sale_month = fm.first_month
    
    UNION ALL
    
    -- RECURSIVE CASE: keep adding next month
    SELECT 
        md.product_id,
        md.sale_month,
        md.monthly_sales,
        ROUND((c.total_sales + md.monthly_sales)::numeric, 2)
    FROM monthly_data md
    JOIN cumulative c 
    ON md.product_id = c.product_id
    AND md.sale_month = c.sale_month + INTERVAL '1 month'
)
SELECT 
    product_id,
    date(sale_month) as sale_month,
    total_sales
FROM cumulative
ORDER BY product_id, sale_month asc;

--using cte

WITH monthly_sales AS (
    SELECT 
        oi.product_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS sale_month,
        SUM(oi.price) AS monthly_total
    FROM amazon_analysis.order_items oi
    JOIN amazon_analysis.orders o USING (order_id)
    GROUP BY oi.product_id, sale_month
)
SELECT 
    product_id,
    TO_CHAR(sale_month, 'YYYY-MM') AS sale_month,
    ROUND(SUM(monthly_total) OVER(
        PARTITION BY product_id
        ORDER BY sale_month
    )::numeric, 2) AS total_sales
FROM monthly_sales
ORDER BY product_id, sale_month asc;
/*question-7 To understand how different payment methods affect monthly sales growth, 
Amazon wants to compute the total sales for each payment method and calculate the month-over-month growth rate
for the past year (year 2018). Write query to first calculate total monthly sales for each payment method, 
then compute the percentage change from the previous month.

Output: payment_type, sale_month, monthly_total, monthly_change.*/

WITH monthly_sales AS (
    SELECT 
        payment_type,
        DATE_TRUNC('month', order_purchase_timestamp) AS sale_month,
        ROUND(SUM(payment_value)::numeric, 2) AS monthly_total
    FROM amazon_analysis.payments
    JOIN amazon_analysis.orders 
    USING (order_id)
    WHERE EXTRACT(YEAR FROM order_purchase_timestamp) = 2018
    GROUP BY payment_type, sale_month
)
SELECT 
    payment_type,
    TO_CHAR(sale_month, 'YYYY-MM') AS sale_month,
    monthly_total,
    ROUND((monthly_total - LAG(monthly_total) OVER(
        PARTITION BY payment_type ORDER BY sale_month
    )) * 100.0 / NULLIF(LAG(monthly_total) OVER(
        PARTITION BY payment_type ORDER BY sale_month
    ), 0), 2) AS monthly_change
FROM monthly_sales
ORDER BY payment_type, sale_month;








