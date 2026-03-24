-- Create views for dashboard

CREATE VIEW vw_daily_kpis AS
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

CREATE VIEW vw_customer_ltv AS
SELECT
    c.customer_id,
    c.name,
    SUM(oi.qty * oi.unit_price) AS ltv
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'paid'
GROUP BY c.customer_id, c.name
ORDER BY ltv DESC;