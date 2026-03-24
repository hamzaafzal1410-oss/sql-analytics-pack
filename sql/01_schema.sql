-- 01_schema.sql
-- Create schema objects for retail sales analytics.

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name TEXT NOT NULL,
    city TEXT NOT NULL,
    signup_date DATE NOT NULL
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    order_date DATE NOT NULL,
    channel TEXT NOT NULL CHECK (channel IN ('web', 'store')),
    status TEXT NOT NULL CHECK (status IN ('paid', 'refunded'))
);

CREATE TABLE order_items (
    order_id INT NOT NULL REFERENCES orders(order_id),
    sku TEXT NOT NULL,
    category TEXT NOT NULL,
    qty INT NOT NULL CHECK (qty > 0),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price > 0),
    PRIMARY KEY (order_id, sku)
);
