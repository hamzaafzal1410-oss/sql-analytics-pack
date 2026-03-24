-- Create schema for retail sales analytics

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    signup_date DATE NOT NULL
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date DATE NOT NULL,
    channel VARCHAR(10) NOT NULL CHECK (channel IN ('web', 'store')),
    status VARCHAR(10) NOT NULL CHECK (status IN ('paid', 'refunded'))
);

CREATE TABLE order_items (
    order_id INTEGER NOT NULL REFERENCES orders(order_id),
    sku VARCHAR(20) NOT NULL,
    category VARCHAR(50) NOT NULL,
    qty INTEGER NOT NULL CHECK (qty > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price > 0)
);