# SQL Analytics Pack (Postgres) — Retail Sales Ops Dashboard Queries

This project demonstrates advanced SQL analytics for a retail sales dashboard using PostgreSQL. It includes schema creation, data loading, complex queries with joins, CTEs, window functions, and performance optimization.

## Dataset

Sample data includes:
- `customers.csv`: 50 customers with signup details
- `orders.csv`: 80 orders with channel and status
- `order_items.csv`: 80 order items with product details

## How to Run

1. Start PostgreSQL with Docker:
   ```bash
   docker compose up -d
   ```

2. Connect to the database (host: localhost, port: 5432, db: retail, user: user, pass: pass)

3. Run the SQL scripts in order:
   - `01_schema.sql` - Create tables
   - `02_load.sql` - Load data
   - `03_analytics.sql` - Run queries
   - `04_views.sql` - Create views

## Queries Implemented

- **Q1**: Daily revenue and order counts (paid orders only)
- **Q2**: Revenue by channel with percentage share
- **Q3**: Top 5 customers by Lifetime Value (LTV)
- **Q4**: Customer repeat purchase rate
- **Q5**: Product category revenue ranking
- **Q6**: Customer activity periods (first/last order, days active)
- **Q7**: 7-day moving average of daily revenue
- **Q8**: Refund rates by sales channel
- **Q9**: Average basket size and order value
- **Q10**: Customer cohort analysis (month 0 revenue)

## Screenshots

### Q1: Daily Revenue and Orders
![Q1 Daily KPIs](screenshots/q1_daily_kpis.png)

### Q5: Category Revenue Ranking
![Q5 Category Ranking](screenshots/q5_category_ranking.png)

### Q7: 7-Day Moving Average
![Q7 Moving Average](screenshots/q7_moving_average.png)

## What This Demonstrates

- **Joins**: Multi-table joins for complex aggregations
- **CTEs**: Common Table Expressions for readable subqueries
- **Window Functions**: RANK(), AVG() OVER() for advanced analytics
- **Performance**: Index creation and EXPLAIN ANALYZE for optimization
- **Views**: Pre-computed views for dashboard efficiency