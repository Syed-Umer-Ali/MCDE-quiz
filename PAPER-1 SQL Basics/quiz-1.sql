-- Section 1 (JOINS)
-- task 1 
select 
    so.order_id,
    sc.first_name + ' ' + sc.last_name as customer_name,
    ss.store_name,
    st.first_name + ' ' + st.last_name as staff_name
from sales.orders as so
join sales.customers as sc
on so.customer_id = sc.customer_id
join sales.stores as ss 
on so.store_id = ss.store_id
join sales.staffs as st
on so.staff_id = st.staff_id
order by so.order_id asc

-- task 2
select 
    pp.product_name,
    pb.brand_name,
    pc.category_name
from production.products as pp
left join production.brands as pb
on pp.brand_id = pb.brand_id
left join production.categories as pc
on pp.category_id = pc.category_id
order by pp.product_id asc

--task 3
select 
    sc.customer_id,
    sc.first_name + ' ' + sc.last_name as customer_name,
    sc.city,
    sc.email
from sales.customers as sc
left join sales.orders as so
on sc.customer_id = so.customer_id
where so.order_id is null
order by sc.customer_id asc

-- Section 2 ( GROUP BY ) 
--task 4
select 
    ss.store_name,
    sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_revenue 
from sales.stores as ss
join sales.orders as so 
on ss.store_id = so.store_id
join sales.order_items as oi
on so.order_id = oi.order_id
group by ss.store_name
order by total_revenue desc


--task 5
select 
    pb.brand_id,
    count(pp.product_id) as total_products,
    avg(pp.list_price) as avg_price,
    max(pp.list_price) as max_price
from production.brands as pb
join production.products as pp
on pb.brand_id= pp.brand_id
group by pb.brand_id


--task 6 
select
    year(o.order_date) as order_year,
    month(o.order_date) as order_month,
    count(distinct o.order_id) as total_orders,
    sum(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
from sales.orders as o
join sales.order_items as oi
on o.order_id = oi.order_id
where year(o.order_date) = 2017
group by year(o.order_date) , month(o.order_date)
order by order_month asc

-- Section 3 (Subqueries)
--task 7
select 
    p1.product_name,
    p1.category_id,
    p1.list_price
from production.products  p1
where p1.list_price > (
    select
        AVG(p2.list_price) as avg_price 
    from production.products p2
    where p2.category_id = p1.category_id
)
order by p1.category_id asc

--task 8 
SELECT
    c.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    COUNT(o.order_id) AS order_count
FROM sales.customers AS c
JOIN sales.orders AS o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(o.order_id) > (
    SELECT AVG(t.order_count * 1.0)
    FROM (
        SELECT COUNT(*) AS order_count
        FROM sales.orders
        GROUP BY customer_id
    ) AS t
)
ORDER BY order_count DESC;

-- Section 4 
-- task 9
WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.first_name + ' ' + c.last_name AS customer_name,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spend
    FROM sales.customers AS c
    JOIN sales.orders      AS o  ON c.customer_id = o.customer_id
    JOIN sales.order_items AS oi ON o.order_id    = oi.order_id
    GROUP BY c.customer_id, c.first_name, c.last_name
),
customer_label AS (
    SELECT
        customer_id,
        customer_name,
        total_spend,
        RANK() OVER (ORDER BY total_spend DESC) AS spend_rank,
        CASE
            WHEN total_spend > AVG(total_spend) OVER () THEN 'High'
            ELSE 'Regular'
        END AS spend_label
    FROM customer_spend
)
SELECT TOP 10
    customer_id,
    customer_name,
    total_spend,
    spend_rank,
    spend_label
FROM customer_label
ORDER BY spend_rank;


-- task 10
WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category_id,
        SUM(oi.quantity) AS total_sold
    FROM production.products AS p
    JOIN sales.order_items   AS oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name, p.category_id
),
ranked_products AS (
    SELECT
        product_id,
        product_name,
        category_id,
        total_sold,
        RANK() OVER (
            PARTITION BY category_id
            ORDER BY total_sold DESC
        ) AS sales_rank
    FROM product_sales
),
stock_totals AS (
    SELECT
        product_id,
        SUM(quantity) AS total_stock
    FROM production.stocks
    GROUP BY product_id
)
SELECT
    c.category_name,
    r.product_name,
    r.total_sold,
    COALESCE(st.total_stock, 0) AS stock_available
FROM ranked_products AS r
JOIN production.categories AS c  ON r.category_id = c.category_id
LEFT JOIN stock_totals     AS st ON r.product_id  = st.product_id
WHERE r.sales_rank = 1
ORDER BY c.category_name;