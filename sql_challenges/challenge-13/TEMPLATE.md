
### `sql_challenges/challenge-01/README.md`

```md
# SQL Challenge 01 – Index Usage

## Problem
Given a table with 10M rows, improve query performance.

## Schema
```sql
CREATE TABLE orders (
  id BIGINT PRIMARY KEY,
  customer_id BIGINT,
  created_at TIMESTAMP,
  status TEXT
);

── sql_challenges/
│   ├── challenge-01/
│   │   ├── README.md
│   │   ├── solution.sql
│   │   └── notes.md
│   ├── challenge-02/
│   │   └── README.md