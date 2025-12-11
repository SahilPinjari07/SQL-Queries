-- final_task3_solution.sql
-- Task 3: SQL for Data Analysis (MySQL dialect)
-- Generated for submission. Contains schema setup (sample rows), indexes, views, and analysis queries.
-- Note: adjust file paths / CSV import for full dataset import if needed.

-- 0) Safety drops (use with caution)
DROP VIEW IF EXISTS vw_monthly_revenue;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS data;

-- 1) Create main data table (matches your spreadsheet columns)
CREATE TABLE `data` (
  `InvoiceNo` VARCHAR(50),
  `StockCode` VARCHAR(50),
  `Description` VARCHAR(255),
  `Quantity` INT,
  `InvoiceDate` DATETIME,
  `UnitPrice` DECIMAL(18,4),
  `CustomerID` BIGINT,
  `Country` VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- NOTE: The sample INSERTs for first 1000 rows were included in the earlier mysql file.
-- If you imported the CSV instead, skip the INSERTs here. For validation, we assume data is loaded.

-- 2) Create helper dimension tables (from data) to demonstrate JOINS
-- Create products table from distinct products
CREATE TABLE IF NOT EXISTS products AS
SELECT DISTINCT StockCode AS product_code,
       Description AS product_description
FROM data;

-- Create customers table from distinct customers
CREATE TABLE IF NOT EXISTS customers AS
SELECT DISTINCT CustomerID AS customer_id,
       Country AS country
FROM data;

-- 3) Indexes to optimize queries
CREATE INDEX idx_data_invoicedate ON data (InvoiceDate);
CREATE INDEX idx_data_stockcode ON data (StockCode);
CREATE INDEX idx_data_customerid ON data (CustomerID);

-- 4) Views for analysis
CREATE OR REPLACE VIEW vw_monthly_revenue AS
SELECT DATE_FORMAT(InvoiceDate, '%Y-%m-01') AS month_start,
       SUM(Quantity * UnitPrice) AS revenue,
       COUNT(DISTINCT InvoiceNo) AS orders_count
FROM data
WHERE InvoiceNo NOT LIKE 'C%'
GROUP BY month_start;

-- 5) Analysis queries (examples required by the task)
-- 5.1 Basic SELECT + WHERE + ORDER BY: recent non-cancelled invoices
SELECT InvoiceNo, InvoiceDate, CustomerID, Country, SUM(Quantity * UnitPrice) AS invoice_total
FROM data
WHERE InvoiceNo NOT LIKE 'C%'
GROUP BY InvoiceNo, InvoiceDate, CustomerID, Country
ORDER BY InvoiceDate DESC
LIMIT 20;

-- 5.2 Aggregation: Total revenue (excluding cancelled invoices)
SELECT SUM(Quantity * UnitPrice) AS total_revenue
FROM data
WHERE InvoiceNo NOT LIKE 'C%';

-- 5.3 Average revenue per user (ARPU)
SELECT ROUND(SUM(Quantity * UnitPrice) / NULLIF(COUNT(DISTINCT CustomerID),0),2) AS avg_revenue_per_user
FROM data
WHERE InvoiceNo NOT LIKE 'C%';

-- 5.4 Revenue by country (GROUP BY + ORDER BY)
SELECT Country, SUM(Quantity * UnitPrice) AS revenue, COUNT(DISTINCT InvoiceNo) AS orders_count
FROM data
WHERE InvoiceNo NOT LIKE 'C%'
GROUP BY Country
ORDER BY revenue DESC;

-- 5.5 Top N products by revenue (GROUP BY + LIMIT)
SELECT d.StockCode, p.product_description, SUM(d.Quantity * d.UnitPrice) AS revenue, SUM(d.Quantity) AS units_sold
FROM data d
LEFT JOIN products p ON d.StockCode = p.product_code
WHERE d.InvoiceNo NOT LIKE 'C%'
GROUP BY d.StockCode, p.product_description
ORDER BY revenue DESC
LIMIT 10;

-- 5.6 JOIN examples (INNER, LEFT, RIGHT)
-- INNER JOIN: customers with orders and their spend
SELECT c.customer_id, c.country, SUM(d.Quantity * d.UnitPrice) AS lifetime_spend
FROM customers c
INNER JOIN data d ON c.customer_id = d.CustomerID
WHERE d.InvoiceNo NOT LIKE 'C%'
GROUP BY c.customer_id, c.country
ORDER BY lifetime_spend DESC
LIMIT 20;

-- LEFT JOIN: all products and revenue (include products with zero revenue)
SELECT p.product_code, p.product_description, COALESCE(SUM(d.Quantity * d.UnitPrice),0) AS revenue
FROM products p
LEFT JOIN data d ON p.product_code = d.StockCode AND d.InvoiceNo NOT LIKE 'C%'
GROUP BY p.product_code, p.product_description
ORDER BY revenue DESC
LIMIT 20;

-- RIGHT JOIN example (MySQL supports RIGHT JOIN) - customers that appear only in data (same as INNER in this context)
SELECT d.CustomerID, SUM(d.Quantity * d.UnitPrice) AS spend
FROM data d
RIGHT JOIN customers c ON d.CustomerID = c.customer_id
WHERE d.InvoiceNo NOT LIKE 'C%'
GROUP BY d.CustomerID
ORDER BY spend DESC
LIMIT 20;

-- 5.7 Subquery example: products priced above category average (we don't have category column; this shows structure)
-- Example of correlated subquery: find StockCodes whose average unit price is above overall average unit price
SELECT StockCode, AVG(UnitPrice) AS avg_price
FROM data
GROUP BY StockCode
HAVING AVG(UnitPrice) > (SELECT AVG(UnitPrice) FROM data WHERE InvoiceNo NOT LIKE 'C%')
ORDER BY avg_price DESC
LIMIT 20;

-- 5.8 HAVING vs WHERE demonstration:
-- WHERE filters rows before grouping; HAVING filters groups after aggregation
SELECT StockCode, SUM(Quantity * UnitPrice) AS revenue
FROM data
WHERE InvoiceNo NOT LIKE 'C%'
GROUP BY StockCode
HAVING revenue > 1000
ORDER BY revenue DESC
LIMIT 10;

-- 5.9 Users with repeat purchases (repeat purchase rate)
WITH user_order_counts AS (
  SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS orders_count
  FROM data
  WHERE InvoiceNo NOT LIKE 'C%'
  GROUP BY CustomerID
)
SELECT SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) AS repeat_purchase_rate
FROM user_order_counts;

-- 5.10 Lifetime value per customer (LTV) — subquery + join
SELECT c.customer_id, c.country,
       COALESCE(t.lifetime_value,0) AS lifetime_value,
       COALESCE(t.orders_count,0) AS orders_count
FROM customers c
LEFT JOIN (
  SELECT CustomerID, SUM(Quantity * UnitPrice) AS lifetime_value, COUNT(DISTINCT InvoiceNo) AS orders_count
  FROM data
  WHERE InvoiceNo NOT LIKE 'C%'
  GROUP BY CustomerID
) t ON c.customer_id = t.CustomerID
ORDER BY lifetime_value DESC
LIMIT 50;

-- 5.11 Data cleaning examples: handle NULLs and bad data
-- Replace missing descriptions and filter negative quantities/prices
SELECT COALESCE(Description,'Unknown') AS description_clean, COUNT(*) AS cnt
FROM data
GROUP BY description_clean
ORDER BY cnt DESC
LIMIT 10;

SELECT * FROM data WHERE Quantity > 0 AND UnitPrice >= 0 LIMIT 20;

-- 6) Performance tips (index usage) - examples of creating additional indexes
CREATE INDEX idx_data_country ON data (Country);
CREATE INDEX idx_data_invoice_no ON data (InvoiceNo(20));

-- 7) Example: materialized-like table for monthly revenue (MySQL doesn't support materialized views directly)
DROP TABLE IF EXISTS mv_monthly_revenue;
CREATE TABLE mv_monthly_revenue AS
SELECT * FROM vw_monthly_revenue;

-- 8) Export sample results for screenshots (example queries to run and screenshot)
-- Run these in MySQL Workbench or CLI and take screenshots for deliverables:
-- a) SELECT InvoiceNo, InvoiceDate, CustomerID, SUM(Quantity*UnitPrice) FROM data WHERE InvoiceNo NOT LIKE 'C%' GROUP BY InvoiceNo LIMIT 10;
-- b) SELECT * FROM vw_monthly_revenue LIMIT 12;
-- c) SELECT StockCode, SUM(Quantity*UnitPrice) AS revenue FROM data WHERE InvoiceNo NOT LIKE 'C%' GROUP BY StockCode ORDER BY revenue DESC LIMIT 10;

-- 9) Answers to Interview Questions (as SQL comments)
/*
1) WHERE vs HAVING:
   - WHERE filters rows before aggregation.
   - HAVING filters groups after aggregation.
   Example above demonstrates both.

2) Types of joins:
   - INNER JOIN, LEFT JOIN, RIGHT JOIN, CROSS JOIN.
   Examples included above.

3) Average revenue per user:
   - See ARPU query (5.3) which divides total revenue by distinct customers.

4) Subqueries:
   - A query nested inside another query. Example in 5.7 and 5.10.

5) How to optimize a query:
   - Add indexes on filter/group/order columns, avoid SELECT *, use aggregated summaries, use materialized tables for heavy aggregations, examine EXPLAIN PLAN.

6) What is a view:
   - A saved query. See vw_monthly_revenue.

7) Handling NULLs:
   - Use COALESCE, IS NULL checks, and data cleaning steps.
*/

-- End of file
