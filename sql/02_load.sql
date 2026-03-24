-- Load data from CSV files

COPY customers FROM '/data/customers.csv' WITH CSV HEADER;
COPY orders FROM '/data/orders.csv' WITH CSV HEADER;
COPY order_items FROM '/data/order_items.csv' WITH CSV HEADER;