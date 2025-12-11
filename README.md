# SQL-Queries

## 📝 Objective  
Use SQL queries to extract, clean, manipulate, and analyze structured data from a relational database.

---

## 🛠 Tools Used  
- **MySQL** (primary)  
- PostgreSQL / SQLite (optional)

---

## 📁 Dataset  
**File:** `data.csv.xlsx`  
**Rows:**   
**Columns:**
- InvoiceNo  
- StockCode  
- Description  
- Quantity  
- InvoiceDate  
- UnitPrice  
- CustomerID  
- Country  

> The first **1,000 rows** were used to generate sample SQL inserts.  
> Full dataset can be imported using CSV + `LOAD DATA INFILE`.

---

## 📦 Files Included  
- **final_task3_solution.sql** — Complete SQL task solution  
- **generated_from_spreadsheet_mysql.sql** — MySQL schema + sample rows  
- **data.csv.xlsx** — Original dataset  
- **README.md** — Documentation (this file)

---

# ✅ Task Deliverables  

### ✔ 1. SQL Queries (Required as per Task Instructions)
Included inside **final_task3_solution.sql**:

#### 🔹 SELECT, WHERE, ORDER BY, GROUP BY  
Filtering, sorting, grouping.

#### 🔹 JOINS  
- INNER JOIN  
- LEFT JOIN  
- RIGHT JOIN  

#### 🔹 Subqueries  
Nested queries for advanced filtering & calculations.

#### 🔹 Aggregate Functions  
SUM, AVG, COUNT, revenue metrics.

#### 🔹 Views  
- `vw_monthly_revenue` — Monthly revenue summary view.

#### 🔹 Index Optimization  
Indexes created on:
- InvoiceDate  
- StockCode  
- CustomerID  
- Country  

---


