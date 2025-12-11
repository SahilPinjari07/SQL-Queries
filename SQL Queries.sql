
DROP VIEW IF EXISTS vw_monthly_revenue;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS data;

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


CREATE TABLE IF NOT EXISTS products AS
SELECT DISTINCT StockCode AS product_code,
       Description AS product_description
FROM data;


CREATE TABLE IF NOT EXISTS customers AS
SELECT DISTINCT CustomerID AS customer_id,
       Country AS country
FROM data;


CREATE INDEX idx_data_invoicedate ON data (InvoiceDate);
CREATE INDEX idx_data_stockcode ON data (StockCode);
CREATE INDEX idx_data_customerid ON data (CustomerID);


CREATE OR REPLACE VIEW vw_monthly_revenue AS
SELECT DATE_FORMAT(InvoiceDate, '%Y-%m-01') AS month_start,
       SUM(Quantity * UnitPrice) AS revenue,
       COUNT(DISTINCT InvoiceNo) AS orders_count
FROM data
WHERE InvoiceNo NOT LIKE 'C%'
GROUP BY month_start;


SELECT InvoiceNo, InvoiceDate, CustomerID, Country, SUM(Quantity * UnitPrice) AS invoice_total
FROM data
WHERE InvoiceNo NOT LIKE 'C%'
GROUP BY InvoiceNo, InvoiceDate, CustomerID, Country
ORDER BY InvoiceDate DESC
LIMIT 20;


SELECT SUM(Quantity * UnitPrice) AS total_revenue
FROM data
WHERE InvoiceNo NOT LIKE 'C%';


SELECT ROUND(SUM(Quantity * UnitPrice) / NULLIF(COUNT(DISTINCT CustomerID),0),2) AS avg_revenue_per_user
FROM data
WHERE InvoiceNo NOT LIKE 'C%';


SELECT Country, SUM(Quantity * UnitPrice) AS revenue, COUNT(DISTINCT InvoiceNo) AS orders_count
FROM data
WHERE InvoiceNo NOT LIKE 'C%'
GROUP BY Country
ORDER BY revenue DESC;


SELECT d.StockCode, p.product_description, SUM(d.Quantity * d.UnitPrice) AS revenue, SUM(d.Quantity) AS units_sold
FROM data d
LEFT JOIN products p ON d.StockCode = p.product_code
WHERE d.InvoiceNo NOT LIKE 'C%'
GROUP BY d.StockCode, p.product_description
ORDER BY revenue DESC
LIMIT 10;


SELECT c.customer_id, c.country, SUM(d.Quantity * d.UnitPrice) AS lifetime_spend
FROM customers c
INNER JOIN data d ON c.customer_id = d.CustomerID
WHERE d.InvoiceNo NOT LIKE 'C%'
GROUP BY c.customer_id, c.country
ORDER BY lifetime_spend DESC
LIMIT 20;


SELECT p.product_code, p.product_description, COALESCE(SUM(d.Quantity * d.UnitPrice),0) AS revenue
FROM products p
LEFT JOIN data d ON p.product_code = d.StockCode AND d.InvoiceNo NOT LIKE 'C%'
GROUP BY p.product_code, p.product_description
ORDER BY revenue DESC
LIMIT 20;


SELECT d.CustomerID, SUM(d.Quantity * d.UnitPrice) AS spend
FROM data d
RIGHT JOIN customers c ON d.CustomerID = c.customer_id
WHERE d.InvoiceNo NOT LIKE 'C%'
GROUP BY d.CustomerID
ORDER BY spend DESC
LIMIT 20;


SELECT StockCode, AVG(UnitPrice) AS avg_price
FROM data
GROUP BY StockCode
HAVING AVG(UnitPrice) > (SELECT AVG(UnitPrice) FROM data WHERE InvoiceNo NOT LIKE 'C%')
ORDER BY avg_price DESC
LIMIT 20;


SELECT StockCode, SUM(Quantity * UnitPrice) AS revenue
FROM data
WHERE InvoiceNo NOT LIKE 'C%'
GROUP BY StockCode
HAVING revenue > 1000
ORDER BY revenue DESC
LIMIT 10;


WITH user_order_counts AS (
  SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS orders_count
  FROM data
  WHERE InvoiceNo NOT LIKE 'C%'
  GROUP BY CustomerID
)
SELECT SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) AS repeat_purchase_rate
FROM user_order_counts;


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


SELECT COALESCE(Description,'Unknown') AS description_clean, COUNT(*) AS cnt
FROM data
GROUP BY description_clean
ORDER BY cnt DESC
LIMIT 10;

SELECT * FROM data WHERE Quantity > 0 AND UnitPrice >= 0 LIMIT 20;

CREATE INDEX idx_data_country ON data (Country);
CREATE INDEX idx_data_invoice_no ON data (InvoiceNo(20));


DROP TABLE IF EXISTS mv_monthly_revenue;
CREATE TABLE mv_monthly_revenue AS
SELECT * FROM vw_monthly_revenue;

