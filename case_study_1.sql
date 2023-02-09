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


SELECT * FROM dannys_diner.members;
SELECT * FROM dannys_diner.sales;
SELECT * FROM dannys_diner.menu;


--- 1. What is the total amount each customer spent at the restaurant?

SELECT sales.customer_id, SUM(menu.price) FROM
dannys_diner.sales AS sales
LEFT JOIN
dannys_diner.menu AS menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id


--- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) FROM
dannys_diner.sales 
GROUP BY customer_id;


--- 3. What was the first item from the menu purchased by each customer?

with customer_first_order AS (
SELECT s.customer_id, s.order_date, 
MIN(s.order_date) OVER (PARTITION BY S.customer_id) AS first_order_date,
m.product_name 
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
ON s.product_id = m.product_id 
)
SELECT  DISTINCT customer_id, product_name FROM customer_first_order
WHERE order_date = first_order_date;

-------------------------------------------- or ---------------------------------------
with customer_first_order AS (
SELECT s.customer_id, s.order_date, 
RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_rank,
m.product_name 
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
ON s.product_id = m.product_id 
)
SELECT  DISTINCT customer_id, product_name FROM customer_first_order WHERE order_rank = 1;



--- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?


select m.product_name, count(*) as freq_orders from dannys_diner.sales s
INNER JOIN
dannys_diner.menu m
ON s.product_id = m.product_id
group by 1
order by 2 desc limit 1




--- 5. Which item was the most popular for each customer?

with products_freq as (
SELECT s.customer_id,m.product_name, count(*) as freq_orders
FROM dannys_diner.sales as s
INNER JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
group by s.customer_id,m.product_name
),
products_freq_rank as (
SELECT customer_id,product_name,freq_orders,
RANK() OVER (PARTITION BY customer_id ORDER BY freq_orders desc) as purchase_rank
FROM products_freq 
)
SELECT customer_id,product_name,freq_orders FROM products_freq_rank where purchase_rank=1

-------------------------------or---------------------------------------------------------------

with products_freq as (
SELECT s.customer_id,m.product_name, count(*) as freq_orders,
RANK() OVER (PARTITION BY customer_id ORDER BY count(*) desc) as purchase_rank
FROM dannys_diner.sales as s
INNER JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
group by s.customer_id,m.product_name
)
SELECT customer_id,product_name,freq_orders FROM products_freq where purchase_rank=1


--- 6. Which item was purchased first by the customer after they became a member?

WITH customer_purchases as (
SELECT s.customer_id,s.order_date,mem.join_date,m.product_name,
RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as purchase_rank
FROM dannys_diner.sales s
INNER JOIN
dannys_diner.menu m
ON m.product_id = s.product_id
INNER JOIN
dannys_diner.members mem
ON mem.customer_id = s.customer_id
WHERE s.order_date>=mem.join_date
)
SELECT customer_id,order_date,product_name FROM customer_purchases
where purchase_rank = 1;


--- 7. Which item was purchased just before the customer became a member?

WITH customer_purchases as (
SELECT s.customer_id,s.order_date,mem.join_date,m.product_name,
RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date desc) as purchase_rank
FROM dannys_diner.sales s
INNER JOIN
dannys_diner.menu m
ON m.product_id = s.product_id
INNER JOIN
dannys_diner.members mem
ON mem.customer_id = s.customer_id
WHERE s.order_date<mem.join_date
)
SELECT customer_id,order_date,product_name FROM customer_purchases
where purchase_rank = 1;



--- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, count(DISTINCT S.product_id) as total_items,
sum(m.price) as amount_spent
FROM dannys_diner.sales s
INNER JOIN
dannys_diner.menu m
ON m.product_id = s.product_id
INNER JOIN
dannys_diner.members mem
ON mem.customer_id = s.customer_id
WHERE s.order_date<mem.join_date
group by s.customer_id



--- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id,
SUM(
CASE WHEN m.product_name='sushi' THEN
2*10*m.price
ELSE
10*m.price 
end) as points
FROM dannys_diner.sales s
INNER JOIN
dannys_diner.menu m
ON m.product_id = s.product_id
group by s.customer_id


--- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id,
SUM(
CASE WHEN s.order_date BETWEEN (mem.join_date) AND (mem.join_date::date + 6) THEN
2*10*m.price
WHEN m.product_name = 'sushi' THEN
2*10*m.price
ELSE
10*m.price
end) as points
FROM dannys_diner.sales s
INNER JOIN
dannys_diner.menu m
ON m.product_id = s.product_id
INNER JOIN
dannys_diner.members mem
ON mem.customer_id = s.customer_id
where s.order_date>='2021-01-01'::Date and s.order_date<='2021-01-31'::Date 
group by s.customer_id


--- Recreating the table by joining all tables.

DROP TABLE IF EXISTS SUMMARY; 
CREATE TEMP TABLE SUMMARY AS (
SELECT s.customer_id,s.order_date,m.product_name,m.price,
CASE WHEN s.order_date < mem.join_date or mem.customer_id is NULL THEN
'N'
ELSE
'Y'
END
AS member
FROM dannys_diner.sales s
INNER JOIN
dannys_diner.menu m
ON m.product_id = s.product_id
LEFT JOIN
dannys_diner.members mem
ON mem.customer_id = s.customer_id
ORDER BY s.customer_id, s.order_date
);

SELECT * FROM SUMMARY;


--- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

SELECT *,
CASE WHEN member='N' THEN
null
else
RANK() OVER (PARTITION BY customer_id,member order by order_date) 
end
as Ranking
FROM SUMMARY;


