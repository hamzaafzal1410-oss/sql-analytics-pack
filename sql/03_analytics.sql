-- 03_analytics.sql
-- Retail Sales Ops Dashboard queries.

-- Q1: Daily revenue + orders count (only paid)
SELECT
    o.order_date,
    COUNT(DISTINCT o.order_id) AS orders_count,
    ROUND(SUM(oi.qty * oi.unit_price), 2) AS daily_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'paid'
GROUP BY o.order_date
ORDER BY o.order_date;

-- Q2: Revenue by channel + % share
WITH channel_revenue AS (
    SELECT
        o.channel,
        SUM(oi.qty * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'paid'
    GROUP BY o.channel
)
SELECT
    channel,
    ROUND(revenue, 2) AS revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS revenue_share_pct
FROM channel_revenue
ORDER BY revenue DESC;

-- Q3: Top 5 customers by LTV (sum paid)
SELECT
    c.customer_id,
    c.name,
    ROUND(SUM(oi.qty * oi.unit_price), 2) AS ltv
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'paid'
GROUP BY c.customer_id, c.name
ORDER BY ltv DESC
LIMIT 5;

-- Q4: Repeat rate: customers with >=2 paid orders / total
WITH paid_order_counts AS (
    SELECT
        customer_id,
        COUNT(*) AS paid_orders
    FROM orders
    WHERE status = 'paid'
    GROUP BY customer_id
)
SELECT
    ROUND(
        COUNT(*) FILTER (WHERE paid_orders >= 2)::NUMERIC
        / NULLIF(COUNT(*), 0),
        4
    ) AS repeat_rate
FROM paid_order_counts;

-- Q5: Category revenue ranking (DENSE_RANK)
SELECT
    oi.category,
    ROUND(SUM(oi.qty * oi.unit_price), 2) AS category_revenue,
    DENSE_RANK() OVER (
        ORDER BY SUM(oi.qty * oi.unit_price) DESC
    ) AS revenue_rank
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'paid'
GROUP BY oi.category
ORDER BY revenue_rank, oi.category;

-- Q6: For each customer: first_order_date, last_order_date, days_active (CTE)
WITH customer_orders AS (
    SELECT
        c.customer_id,
        c.name,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.name
)
SELECT
    customer_id,
    name,
    first_order_date,
    last_order_date,
    CASE
        WHEN first_order_date IS NULL THEN 0
        ELSE (last_order_date - first_order_date)
    END AS days_active
FROM customer_orders
ORDER BY customer_id;

-- Q7: 7-day moving average of daily revenue (window)
WITH daily_revenue AS (
    SELECT
        o.order_date,
        SUM(oi.qty * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'paid'
    GROUP BY o.order_date
)
SELECT
    order_date,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY order_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_7d
FROM daily_revenue
ORDER BY order_date;

-- Q8: Refund rate by channel (refunded / total)
SELECT
    channel,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'refunded')::NUMERIC
        / NULLIF(COUNT(*), 0),
        4
    ) AS refund_rate
FROM orders
GROUP BY channel
ORDER BY channel;

-- Q9: Basket size distribution: avg items/order, avg order value
WITH order_metrics AS (
    SELECT
        o.order_id,
        SUM(oi.qty) AS total_items,
        SUM(oi.qty * oi.unit_price) AS order_value
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'paid'
    GROUP BY o.order_id
)
SELECT
    ROUND(AVG(total_items), 2) AS avg_items_per_order,
    ROUND(AVG(order_value), 2) AS avg_order_value
FROM order_metrics;

-- Q10: Cohort: signup_month -> month_0 revenue (simple cohort)
WITH customer_cohort AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', signup_date)::DATE AS signup_month
    FROM customers
),
month0_orders AS (
    SELECT
        c.signup_month,
        o.order_id
    FROM customer_cohort c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.status = 'paid'
      AND DATE_TRUNC('month', o.order_date)::DATE = c.signup_month
)
SELECT
    m.signup_month,
    ROUND(SUM(oi.qty * oi.unit_price), 2) AS month_0_revenue
FROM month0_orders m
JOIN order_items oi ON oi.order_id = m.order_id
GROUP BY m.signup_month
ORDER BY m.signup_month;

-- ------------------------------------------------------------
-- Index tuning + EXPLAIN ANALYZE for Q1 (before and after)
-- ------------------------------------------------------------

-- Ensure "before" run does not use previous custom indexes.
DROP INDEX IF EXISTS idx_orders_status_order_date;
DROP INDEX IF EXISTS idx_order_items_order_id;
DROP INDEX IF EXISTS idx_orders_channel_status;
DROP INDEX IF EXISTS idx_orders_customer_status_date;
DROP INDEX IF EXISTS idx_customers_signup_month;

-- Q1 execution plan BEFORE indexes
EXPLAIN ANALYZE
SELECT
    o.order_date,
    COUNT(DISTINCT o.order_id) AS orders_count,
    SUM(oi.qty * oi.unit_price) AS daily_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'paid'
GROUP BY o.order_date
ORDER BY o.order_date;

-- Add indexes used by dashboard patterns.
CREATE INDEX IF NOT EXISTS idx_orders_status_order_date
    ON orders (status, order_date);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON order_items (order_id);

CREATE INDEX IF NOT EXISTS idx_orders_channel_status
    ON orders (channel, status);

CREATE INDEX IF NOT EXISTS idx_orders_customer_status_date
    ON orders (customer_id, status, order_date);

CREATE INDEX IF NOT EXISTS idx_customers_signup_month
    ON customers (signup_date);

-- Q1 execution plan AFTER indexes
EXPLAIN ANALYZE
SELECT
    o.order_date,
    COUNT(DISTINCT o.order_id) AS orders_count,
    SUM(oi.qty * oi.unit_price) AS daily_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'paid'
GROUP BY o.order_date
ORDER BY o.order_date;
