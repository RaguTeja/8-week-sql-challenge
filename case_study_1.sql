CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),

  ('B', '2021-01-09');

Select *
From members
Select *
From menu
Select *
From Sales

-- SOLUTIONS


select * from dannys_diner.sales limit 5;
select * from dannys_diner.menu limit 5;
select * from dannys_diner.members limit 5;


--- 1. What is the total amount each customer spent at the restaurant?

---sales                      menu

---customer id
---product id          ----> product id
---                          price
---


with customer_spendings as (
select s.customer_id as cust_id ,s.product_id as prod_id, m.price as cost from 
dannys_diner.sales as s inner join dannys_diner.menu as m
ON
s.product_id=m.product_id
)
select cust_id,sum(cost) as total_spendings from customer_spendings
group by cust_id
order by cust_id;


SELECT sales.customer_id as cust_id,SUM(menu.price)
from dannys_diner.sales
INNER JOIN 
dannys_diner.menu
ON sales.product_id=menu.product_id
group by cust_id;


SELECT
  sales.customer_id,
  SUM(menu.price) AS total_sales
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
ON sales.product_id=menu.product_id
GROUP BY
  sales.customer_id;
  
  
  
--- How many days has each customer visited the restaurant?

---sales              

---customer id
---order_date
---product id          

select customer_id,count( DISTINCT order_date) as number_of_days_visited from dannys_diner.sales
group by customer_id;

--- What was the first item from the menu purchased by each customer?

---sales                      menu               members

---customer id                                    cust_id
---product id          ----> product id           joined_date  
---                          price
---order_date



---A   product_name
---B   product_name

with cte_table as(
select customer_id,product_name,
RANK() over (partition by customer_id order by order_date) AS seq
from dannys_diner.sales as s
inner join
dannys_diner.menu as m
ON s.product_id=m.product_id
)
select DISTINCT customer_id,product_name from cte_table 
where seq=1;

# MAIN QEURY
WITH ordered_sales AS (
  SELECT
    sales.customer_id,
    -- does this look right?
    RANK() OVER (
      PARTITION BY sales.customer_id
      ORDER BY sales.order_date
    ) AS order_rank,
    menu.product_name
  FROM dannys_diner.sales
  INNER JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
)
SELECT DISTINCT
  customer_id,
  product_name
FROM ordered_sales
-- what about this?
WHERE order_rank = 1;



--- What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name as prod_name,count(*) as freq
from dannys_diner.sales as s
INNER JOIN
dannys_diner.menu as m
ON s.product_id=m.product_id
group by prod_name
order by freq desc
limit 1;

# MAIN QEURY
SELECT
  menu.product_name,
  COUNT(sales.*) AS total_purchases
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
  ON
sales.product_id=menu.product_id
group by product_name
ORDER BY total_purchases DESC
LIMIT 1;

--- A product_name freq
--- B product_name freq


--- What is the most purchased item on the menu and how many times was it purchased by each customer?

with freq_purchase as(
select product_id,count(*) as purchase_freq
from dannys_diner.sales
group by product_id
order by purchase_freq desc
limit 1
)
select customer_id,product_id,count(*)
from dannys_diner.sales 
where product_id in (select product_id from freq_purchase)
group by customer_id,product_id;



---Which i    tem was the most popular for each customer?

--- customer_id   product_name
--- cistomer_id   product_name

# MAIN QEURY
with cte_table as (
select s.customer_id as cust,m.product_name as prod,count(*) as freq
---RANK() OVER (PARTITION BY cust order by freq) as _rank
from 
dannys_diner.sales as s
INNER JOIN
dannys_diner.menu as m
ON s.product_id=m.product_id
group by cust,prod
),
cte_table1 as( 
select cust,prod,freq,
RANK() OVER (PARTITION BY cust order by freq desc) as _rank
from cte_table
)
select cust,prod,freq from cte_table1
where _rank=1;

# MAIN QEURY
with cte_table as (
select s.customer_id as cust,m.product_name as prod,count(*) as freq,
RANK() OVER (PARTITION BY s.customer_id order by count(*) desc) as _rank
from 
dannys_diner.sales as s
INNER JOIN
dannys_diner.menu as m
ON s.product_id=m.product_id
group by cust,prod
)
select cust,prod,freq from cte_table
where _rank=1;




--- most purchased product and how many times purchased by each customer 
# PRACTICE
with most_purchased_product as (
select product_id,count(*) as freq
from dannys_diner.sales
group by product_id
order by freq desc
limit 1),

# MAIN QEURY
customerwise_purchases as(
select customer_id,product_id,count(*) as prod_freq
from dannys_diner.sales where product_id in (select product_id from most_purchased_product)
group by 1,2)

select customerwise_purchases.customer_id,menu.product_name,prod_freq
from customerwise_purchases
inner join
dannys_diner.menu
ON customerwise_purchases.product_id=menu.product_id



--- Which item was purchased first by the customer?

# PRACTICE
with ordered_table as (
select customer_id,product_id,
RANK() OVER (PARTITION BY customer_id order by order_date) as _rank
from dannys_diner.sales
)
select DISTINCT customer_id,product_id from ordered_table
where _rank=1;


#MAIN QUERY
with ordered_table as (
select s.customer_id,m.product_name,
RANK() OVER (PARTITION BY customer_id order by order_date) as _rank
from dannys_diner.sales as s
INNER JOIN 
dannys_diner.menu as m
ON s.product_id=m.product_id
)
select DISTINCT customer_id,product_name from ordered_table
where _rank=1;


--- Which item was purchased first by the customer after they became a member?

select * from dannys_diner.members;

with cte_table as (
select s.customer_id as cust_id,s.order_date  as dates,me.product_name as prod_name,
RANK() OVER (PARTITION BY s.customer_id order by s.order_date) as _rank
from dannys_diner.sales as s
INNER JOIN 
dannys_diner.members as m
ON s.customer_id=m.customer_id
INNER JOIN 
dannys_diner.menu as me
ON s.product_id=me.product_id
WHERE s.order_date>=m.join_date
)
select cust_id,dates,prod_name from cte_table where _rank=1;


select * from dannys_diner.members;


--- Which item was purchased just before the customer became a member?
with cte_table as(
select s.customer_id,s.order_date,me.product_name,
RANK() over (partition by s.customer_id order by order_date desc) as _rank
from dannys_diner.sales as s
INNER JOIN
dannys_diner.members as m
ON s.customer_id=m.customer_id
INNER JOIN 
dannys_diner.menu as me
ON s.product_id=me.product_id
WHERE s.order_date<m.join_date
)
select customer_id,order_date,product_name
from cte_table
where
_rank=1
order by product_name;



---What is the total items and amount spent for each member before they became a member?

select s.customer_id as cust_id,count(DISTINCT s.product_id) as tot_items,SUM(m.price) as tot_price from
dannys_diner.sales as s
INNER JOIN
dannys_diner.menu as m
ON s.product_id=m.product_id
INNER JOIN
dannys_diner.members as me
ON s.customer_id=me.customer_id
where s.order_date<me.join_date
group by s.customer_id;




---If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id,
SUM(CASE
WHEN m.product_name='sushi'
THEN (m.price)*20
else
(m.price)*10
end)
as tot_points
FROM 
dannys_diner.sales as s
INNER JOIN
dannys_diner.menu as m
ON s.product_id=m.product_id
group by 1;



--- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select s.customer_id as cust_id,
SUM(
CASE WHEN s.order_date BETWEEN m.join_date and m.join_date+6 OR me.product_name='sushi'
THEN
20*me.price
ELSE 
10*me.price
END
)
as tot_points
from 
dannys_diner.sales as s
INNER JOIN
dannys_diner.members as m
ON s.customer_id=m.customer_id
INNER JOIN
dannys_diner.menu as me
ON s.product_id=me.product_id
WHERE s.order_date>='2021-01-01' and s.order_date<='2021-01-31'
group by 1;


---Recreate the following table output using the available data:

DROP TABLE if EXISTS SUMMARY;
CREATE TEMP TABLE SUMMARY AS
select s.customer_id as cust_id,s.order_date as dates,m.product_name as prod_name,
m.price as prod_price,
CASE WHEN me.customer_id is NOT NULL AND s.order_date>=me.join_date 
THEN 'Y'
ELSE
'N'
END
AS mem
from 
dannys_diner.sales AS s
INNER JOIN
dannys_diner.menu AS m
ON s.product_id=m.product_id
LEFT JOIN
dannys_diner.members as me
ON s.customer_id=me.customer_id
ORDER BY cust_id,dates,prod_name;

select * from SUMMARY;



---Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

# PRACTICE
select s.customer_id,s.order_date,
m.product_name,m.price,
CASE WHEN s.customer_id IS NOT NULL and s.order_date>=me.join_date
THEN
'Y'
ELSE
'N'
END
AS mem,
CASE WHEN s.order_date<me.join_date or me.customer_id is NULL
THEN NULL
ELSE
RANK() OVER (PARTITION BY s.customer_id order by s.order_date)
END
as ranking
from 
dannys_diner.sales AS s
INNER JOIN
dannys_diner.menu AS m
ON s.product_id=m.product_id
LEFT JOIN
dannys_diner.members as me
ON s.customer_id=me.customer_id
ORDER BY 1,2,3




# MAIN QUERY
with cte_table as(
select s.customer_id as cust_id,s.order_date as od,me.join_date as jd,
m.product_name as prod_name,m.price as prod_price,
CASE WHEN s.customer_id IS NOT NULL and s.order_date>=me.join_date
THEN
'Y'
ELSE
'N'
END
AS mem
from 
dannys_diner.sales AS s
INNER JOIN
dannys_diner.menu AS m
ON s.product_id=m.product_id
LEFT JOIN
dannys_diner.members as me
ON s.customer_id=me.customer_id
)
select cust_id,od,prod_name,prod_price,mem,
CASE WHEN mem='N' OR od<jd 
THEN NULL 
ELSE
RANK() OVER (PARTITION BY cust_id,mem order by od)
END
AS ranking
from cte_table;

