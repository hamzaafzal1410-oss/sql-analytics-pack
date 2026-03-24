-- Analytics queries for retail sales dashboard

-- Q1: Daily revenue + orders count (only paid)
SELECT
    order_date,
    COUNT(*) AS orders_count,
    SUM(total) AS revenue
FROM (
    SELECT
        o.order_id,
        o.order_date,
        SUM(oi.qty * oi.unit_price) AS total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'paid'
    GROUP BY o.order_id, o.order_date
) t
GROUP BY order_date
ORDER BY order_date;

-- Q2: Revenue by channel + % share
WITH channel_rev AS (
    SELECT
        o.channel,
        SUM(oi.qty * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'paid'
    GROUP BY o.channel
),
total_rev AS (
    SELECT SUM(revenue) AS total FROM channel_rev
)
SELECT
    cr.channel,
    cr.revenue,
    ROUND(100.0 * cr.revenue / tr.total, 2) AS pct_share
FROM channel_rev cr, total_rev tr
ORDER BY cr.revenue DESC;

-- Q3: Top 5 customers by LTV (sum paid)
SELECT
    c.customer_id,
    c.name,
    SUM(oi.qty * oi.unit_price) AS ltv
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'paid'
GROUP BY c.customer_id, c.name
ORDER BY ltv DESC
LIMIT 5;

-- Q4: Repeat rate: customers with ≥2 paid orders / total
WITH paid_customers AS (
    SELECT
        customer_id,
        COUNT(*) AS order_count
    FROM orders
    WHERE status = 'paid'
    GROUP BY customer_id
)
SELECT
    ROUND(100.0 * COUNT(CASE WHEN order_count >= 2 THEN 1 END) / COUNT(*), 2) AS repeat_rate
FROM paid_customers;

-- Q5: Category revenue ranking (DENSE_RANK)
SELECT
    category,
    SUM(oi.qty * oi.unit_price) AS revenue,
    DENSE_RANK() OVER (ORDER BY SUM(oi.qty * oi.unit_price) DESC) AS rank
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'paid'
GROUP BY category
ORDER BY rank;

-- Q6: For each customer: first_order_date, last_order_date, days_active (CTE)
WITH customer_orders AS (
    SELECT
        c.customer_id,
        c.name,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'paid'
    GROUP BY c.customer_id, c.name
)
SELECT
    customer_id,
    name,
    first_order_date,
    last_order_date,
    last_order_date - first_order_date AS days_active
FROM customer_orders
ORDER BY customer_id;

-- Q7: 7-day moving average of daily revenue (window)
WITH daily_revenue AS (
    SELECT
        order_date,
        SUM(total) AS revenue
    FROM (
        SELECT
            o.order_id,
            o.order_date,
            SUM(oi.qty * oi.unit_price) AS total
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.status = 'paid'
        GROUP BY o.order_id, o.order_date
    ) t
    GROUP BY order_date
)
SELECT
    order_date,
    revenue,
    ROUND(AVG(revenue) OVER (ORDER BY order_date ROWS 6 PRECEDING), 2) AS ma7
FROM daily_revenue
ORDER BY order_date;

-- Q8: Refund rate by channel (refunded / total)
SELECT
    channel,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = 'refunded' THEN 1 ELSE 0 END) AS refunded_orders,
    ROUND(100.0 * SUM(CASE WHEN status = 'refunded' THEN 1 ELSE 0 END) / COUNT(*), 2) AS refund_rate
FROM orders
GROUP BY channel
ORDER BY channel;

-- Q9: Basket size distribution: avg items/order, avg order value
SELECT
    ROUND(AVG(item_count), 2) AS avg_items_per_order,
    ROUND(AVG(order_value), 2) AS avg_order_value
FROM (
    SELECT
        o.order_id,
        COUNT(oi.*) AS item_count,
        SUM(oi.qty * oi.unit_price) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'paid'
    GROUP BY o.order_id
) t;

-- Q10: Cohort: signup_month → month_0 revenue (simple cohort)
WITH cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', signup_date) AS signup_month
    FROM customers
),
cohort_revenue AS (
    SELECT
        c.signup_month,
        DATE_TRUNC('month', o.order_date) AS order_month,
        SUM(oi.qty * oi.unit_price) AS revenue
    FROM cohorts c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'paid'
    GROUP BY c.signup_month, DATE_TRUNC('month', o.order_date)
)
SELECT
    signup_month,
    COALESCE(SUM(CASE WHEN order_month = signup_month THEN revenue END), 0) AS month_0_revenue
FROM cohort_revenue
GROUP BY signup_month
ORDER BY signup_month;

-- Add indexes for Q1
CREATE INDEX idx_orders_date_status ON orders(order_date, status);

-- EXPLAIN ANALYZE for Q1 (run after index)
EXPLAIN ANALYZE
SELECT
    order_date,
    COUNT(*) AS orders_count,
    SUM(total) AS revenue
FROM (
    SELECT
        o.order_id,
        o.order_date,
        SUM(oi.qty * oi.unit_price) AS total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'paid'
    GROUP BY o.order_id, o.order_date
) t
GROUP BY order_date
ORDER BY order_date;