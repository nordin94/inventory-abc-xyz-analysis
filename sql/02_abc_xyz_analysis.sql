-- 02_abc_xyz_analysis.sql
-- PostgreSQL. ABC (revenue) and XYZ (demand variability) classification with window functions and CTEs.
-- Same results as the Excel workbook and the Power BI dashboard.

-- 1. Ranking by revenue
SELECT stock_code, description, revenue,
       RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM products
ORDER BY revenue_rank
LIMIT 10;
-- 22423 REGENCY CAKESTAND 3 TIER is #1 with £164,762.19

-- 2. Cumulative share of revenue (the ABC curve)
--    ROWS BETWEEN ... is written explicitly so that products with equal revenue are added one at a time.
SELECT stock_code, description, revenue,
       ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC, stock_code
                                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
             / SUM(revenue) OVER (), 2) AS cum_pct
FROM products
ORDER BY revenue DESC, stock_code;
-- 1.69 % -> 2.71 % -> 3.72 % ...

-- 3. ABC class: A = first 80 % of revenue, B = next 15 %, C = last 5 %
WITH ranked AS (
    SELECT stock_code, revenue,
           SUM(revenue) OVER (ORDER BY revenue DESC, stock_code
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
           / SUM(revenue) OVER () AS cum_share
    FROM products
)
SELECT CASE WHEN cum_share <= 0.80 THEN 'A'
            WHEN cum_share <= 0.95 THEN 'B'
            ELSE 'C' END AS abc_class,
       COUNT(*) AS products,
       ROUND(SUM(revenue), 2) AS revenue
FROM ranked
GROUP BY abc_class
ORDER BY abc_class;
-- A 834 products (80.0 %) | B 963 (15.0 %) | C 2,008 (5.0 %)

-- 4. XYZ class: coefficient of variation of monthly units over 12 months
--    Months with no sales have no row, so AVG(units) would ignore them and make demand look stable.
--    Dividing by 12.0 counts those months as zero. Variance = mean of squares - square of the mean.
WITH stats AS (
    SELECT stock_code,
           SUM(units) / 12.0 AS mean_units,
           SUM(units * units) / 12.0 AS mean_sq
    FROM monthly_sales
    GROUP BY stock_code
)
SELECT CASE WHEN mean_units <= 0 THEN 'Z'
            WHEN SQRT(mean_sq - mean_units * mean_units) / mean_units <= 0.5 THEN 'X'
            WHEN SQRT(mean_sq - mean_units * mean_units) / mean_units <= 1 THEN 'Y'
            ELSE 'Z' END AS xyz_class,
       COUNT(*) AS products
FROM stats
GROUP BY xyz_class
ORDER BY xyz_class;
-- X 363 | Y 1,068 | Z 2,372

-- 5. ABC x XYZ matrix
WITH ranked AS (
    SELECT stock_code,
           SUM(revenue) OVER (ORDER BY revenue DESC, stock_code
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
           / SUM(revenue) OVER () AS cum_share
    FROM products
),
abc AS (
    SELECT stock_code,
           CASE WHEN cum_share <= 0.80 THEN 'A' WHEN cum_share <= 0.95 THEN 'B' ELSE 'C' END AS abc_class
    FROM ranked
),
stats AS (
    SELECT stock_code, SUM(units) / 12.0 AS m, SUM(units * units) / 12.0 AS m2
    FROM monthly_sales
    GROUP BY stock_code
),
xyz AS (
    SELECT stock_code,
           CASE WHEN m <= 0 THEN 'Z'
                WHEN SQRT(m2 - m * m) / m <= 0.5 THEN 'X'
                WHEN SQRT(m2 - m * m) / m <= 1 THEN 'Y'
                ELSE 'Z' END AS xyz_class
    FROM stats
)
SELECT abc.abc_class || xyz.xyz_class AS class,
       COUNT(*) AS products
FROM abc
JOIN xyz ON xyz.stock_code = abc.stock_code
GROUP BY class
ORDER BY class;
-- AX 229 | AY 317 | AZ 288 | BX 112 | BY 362 | BZ 489 | CX 22 | CY 389 | CZ 1,595
-- 3,803 products: the 2 products first sold in December 2011 have no complete month and no XYZ class.
