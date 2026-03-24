-- 04_views.sql
-- Reusable views for dashboarding.

DROP VIEW IF EXISTS vw_daily_kpis;
DROP VIEW IF EXISTS vw_customer_ltv;

CREATE VIEW vw_daily_kpis AS
SELECT
    o.order_date,
    COUNT(DISTINCT o.order_id) FILTER (WHERE o.status = 'paid') AS paid_orders,
    ROUND(
        SUM(
            CASE WHEN o.status = 'paid' THEN oi.qty * oi.unit_price ELSE 0 END
        ),
        2
    ) AS paid_revenue,
    COUNT(DISTINCT o.order_id) FILTER (WHERE o.status = 'refunded') AS refunded_orders
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_date
ORDER BY o.order_date;

CREATE VIEW vw_customer_ltv AS
SELECT
    c.customer_id,
    c.name,
    c.city,
    ROUND(
        COALESCE(
            SUM(CASE WHEN o.status = 'paid' THEN oi.qty * oi.unit_price END),
            0
        ),
        2
    ) AS ltv
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.name, c.city;
