# SQL Analytics Pack (Postgres)

Retail Sales Ops Dashboard-style SQL project using a small synthetic dataset.

## Project Structure

```
sql-analytics-pack/
  data/
    customers.csv
    orders.csv
    order_items.csv
  sql/
    01_schema.sql
    02_load.sql
    03_analytics.sql
    04_views.sql
  docker-compose.yml
  README.md
  screenshots/
  results/   (optional exports)
```

## Tech

- PostgreSQL 16 (Docker)
- SQL for analytics modeling (joins, CTEs, windows, ranking)

## How to Run

1) Start Postgres:

```bash
docker compose up -d
```

2) Connect from DBeaver (or `psql`) with:

- Host: `localhost`
- Port: `5432`
- Database: `retail_analytics`
- User: `analyst`
- Password: `analyst123`

3) Run SQL scripts in this order:

```sql
\i /workspace/sql/01_schema.sql
\i /workspace/sql/02_load.sql
\i /workspace/sql/03_analytics.sql
\i /workspace/sql/04_views.sql
```

If using DBeaver, open each file and execute sequentially.

## Implemented Analytics Queries

- Q1: Daily revenue + order count (paid only)
- Q2: Revenue by channel + percentage share
- Q3: Top 5 customers by LTV
- Q4: Repeat rate (`>=2` paid orders / total customers with paid orders)
- Q5: Category revenue ranking (`DENSE_RANK`)
- Q6: Customer first/last order + `days_active` (CTE)
- Q7: 7-day moving average of daily revenue (window function)
- Q8: Refund rate by channel
- Q9: Basket metrics (avg items/order, avg order value)
- Q10: Cohort month_0 revenue by signup month
- Indexes + `EXPLAIN ANALYZE` for Q1 before/after index creation

## Screenshots (DBeaver)

Add screenshots here after running queries:

- `screenshots/q1_daily_kpis.png`
- `screenshots/q5_category_ranking.png`
- `screenshots/q7_moving_average.png`

## Optional Results Exports

You can export result grids from DBeaver to:

- `results/q1_daily_kpis.csv`
- `results/q5_category_ranking.csv`
- `results/q7_moving_average.csv`

## What This Demonstrates

- **Joins:** combining transactional orders and line-item detail with customer dimensions
- **CTEs:** modular query construction for repeat rates, cohorts, and customer lifecycle metrics
- **Window functions:** moving averages and dense ranking for operational trends and category performance
