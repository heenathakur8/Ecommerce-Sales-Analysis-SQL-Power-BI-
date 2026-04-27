use ecommerce_proj;
-- revenue generated --
select Round(sum(total_amount),2) as Completed_Orders_Revenue ,
count(order_id) as No_of_Completed_Orders
from orders
where order_status = "completed";

-- amount lost as returned or cancelled --
select round(sum(total_amount),2) as Returned_OR_Cancelled ,
count(order_id) as No_of_returned_cancelled_orders
from orders
where order_status in ('cancelled','returned');

-- revenue trend --
use ecommerce_proj;
SELECT 
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    round(Sum(total_amount),2) AS Revenue
FROM orders
where order_status = 'Completed'
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY year, revenue;

-- top 3 months with highest revenue each year --
SELECT year, month, Revenue
FROM (
    SELECT 
        YEAR(order_date) AS year,
        MONTH(order_date) AS month,
        round(sum(total_amount),2) as revenue,
        
        ROW_NUMBER() OVER (
            PARTITION BY YEAR(order_date)
            ORDER BY sum(total_amount) DESC
        ) AS rn
    FROM orders
    where order_status = "completed" 
    GROUP BY YEAR(order_date), MONTH(order_date)
) ranked
WHERE rn <= 3
ORDER BY year, revenue DESC;


select round(sum(o.total_amount),2) as revenue ,p.category  from orders as o
Left Join order_items as oi
on oi.order_id = o.order_id
Left Join products as p
on oi.product_id = p.product_id
where o.order_status = "completed"
group by p.category
order by revenue desc;

-- category wise revenue top 3 --
select sum(o.quantity) No_of_orders ,p.category from order_items as o
left join products as p
on o.product_id=p.product_id
Group by p.category 
order by no_of_orders desc
limit 3;

-- top 3 category with most returned orders--
select sum(o.quantity) No_of_orders_returned ,p.category from order_items as o
left join products as p
on o.product_id=p.product_id
left join orders as orr
on orr.order_id=o.order_id
where orr.order_status like "ca%"
Group by p.category 
order by no_of_orders_returned desc
limit 3;


-- AOV --
WITH order_values AS (
    SELECT 
        order_id,
        SUM(total_amount) AS order_value
    FROM orders
    WHERE order_status = 'completed'
    GROUP BY order_id
)
SELECT 
    round(AVG(order_value),2) AS net_AOV
FROM order_values;


-- order frequency --
SELECT 
   round( COUNT(DISTINCT order_id) * 1.0 / COUNT(DISTINCT user_id),2) AS order_frequency
FROM orders;

-- views --
CREATE VIEW sales_detailed AS
SELECT 
    o.order_id,
    o.user_id,
    u.name AS customer_name,
    o.order_date,
    oi.product_id,
    p.product_name,
    p.category,
    oi.quantity,
    oi.item_price ,
    (oi.quantity * oi.item_price) AS total_price
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN users u ON o.user_id = u.user_id;


CREATE OR REPLACE VIEW sales_detailed AS
SELECT 
    o.order_id,
    o.user_id,
    u.name AS customer_name,
    u.city,
    o.order_date,
    o.order_status,
    oi.product_id,
    p.product_name,
    p.category,
    oi.quantity,
    oi.item_price AS item_price,
    (oi.quantity * oi.item_price) AS total_price
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id
JOIN users u 
    ON o.user_id = u.user_id;

-- sales summary aggregation --
CREATE VIEW sales_summary AS
SELECT 
    order_id,
    user_id,
    SUM(quantity * item_price) AS order_value
FROM order_items
GROUP BY order_id, user_id;

-- perfromance of product --
CREATE VIEW product_performance AS
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity) AS total_sold,
    SUM(oi.quantity * oi.item_price) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category;

-- customer innsights --
CREATE VIEW customer_insights AS
SELECT 
    u.user_id,
    u.name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * oi.item_price) AS total_spent
FROM users u
JOIN orders o ON u.user_id = o.user_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY u.user_id, u.name;

-- review summary--
CREATE VIEW review_summary AS
SELECT 
    p.product_id,
    p.product_name,
    AVG(r.rating) AS avg_rating,
    COUNT(r.review_id) AS total_reviews
FROM reviews r
JOIN products p ON r.product_id = p.product_id
GROUP BY p.product_id, p.product_name;

-- category performance --
CREATE VIEW category_performance AS
SELECT 
    p.category,
    SUM(oi.quantity) AS total_sold,
    SUM(oi.quantity * oi.item_price) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category;

-- user activity --
CREATE VIEW user_activity AS
SELECT 
    user_id,
    event_type,
    COUNT(*) AS event_count
FROM events
GROUP BY user_id, event_type;

-- sales trend--
CREATE VIEW sales_trend AS
SELECT 
    DATE(o.order_date) AS order_date,
    SUM(oi.quantity * oi.item_price) AS daily_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY DATE(o.order_date);