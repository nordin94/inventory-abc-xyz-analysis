-- 01_create_tables.sql
-- PostgreSQL. Loads the two cleaned tables produced by the Power Query steps.
-- Run from the repo root:  psql -d <your_database> -f sql/01_create_tables.sql

DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS monthly_sales;

CREATE TABLE products (
    stock_code   TEXT PRIMARY KEY,
    description  TEXT,
    revenue      NUMERIC(12, 2) NOT NULL,   -- net revenue: sales minus returns, in GBP
    units        INTEGER NOT NULL
);

CREATE TABLE monthly_sales (
    stock_code  TEXT    NOT NULL,
    month       DATE    NOT NULL,           -- first day of the month, Dec 2010 to Nov 2011
    units       INTEGER NOT NULL,
    PRIMARY KEY (stock_code, month)
);

\copy products      FROM 'data/products_clean.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy monthly_sales FROM 'data/monthly_sales.csv'  WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Checks before any analysis
SELECT COUNT(*) AS products, SUM(revenue) AS total_revenue FROM products;  -- 3805 | 9752690.93
SELECT COUNT(*) AS product_months FROM monthly_sales;                     -- 31108 (months with no sales have no row)
