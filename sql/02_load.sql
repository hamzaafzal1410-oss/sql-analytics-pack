-- 02_load.sql
-- Load CSV files into Postgres tables.

-- Run this file from a SQL client connected to the containerized DB.
-- These absolute paths assume docker-compose mounts project to /workspace.

COPY customers (customer_id, name, city, signup_date)
FROM '/workspace/data/customers.csv'
WITH (FORMAT csv, HEADER true);

COPY orders (order_id, customer_id, order_date, channel, status)
FROM '/workspace/data/orders.csv'
WITH (FORMAT csv, HEADER true);

COPY order_items (order_id, sku, category, qty, unit_price)
FROM '/workspace/data/order_items.csv'
WITH (FORMAT csv, HEADER true);
