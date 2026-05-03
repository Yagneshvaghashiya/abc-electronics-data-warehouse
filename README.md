# ABC Electronics Data Warehouse & Big Data Pipeline

## 🎯 Project Overview

Enterprise-scale data warehouse implementation for ABC Electronics, integrating traditional SQL Server dimensional modeling with modern Hadoop/HDFS big data processing. This project demonstrates end-to-end data warehousing capabilities including star schema design, ETL processes, and distributed computing for inventory management analytics.

**Student:** Yagnesh Vaghashiya  
**Course:** Data Warehousing and Big Data  
**Institution:** London Metropolitan University  
**Supervisor:** Dr. Cheima Ali Bensaad  
**Academic Period:** 2025-2026

---

## 📊 Business Problem

ABC Electronics needed a centralized analytical platform to:
- Track purchase orders across multiple suppliers
- Monitor stock levels across warehouse locations
- Analyze supplier performance and delivery reliability
- Identify understock/overstock situations
- Support data-driven decision-making for inventory optimization

**Solution:** Hybrid data warehouse combining SQL Server (OLAP) and Hadoop (Big Data processing)

---

## 🏗️ Architecture Overview

### **Dimensional Model:** Star Schema / Galaxy Schema

```
┌─────────────────────────────────────────────┐
│        ABC Electronics Data Warehouse        │
├─────────────────────────────────────────────┤
│                                              │
│  ┌──────────────┐     ┌──────────────┐     │
│  │  Dim_Date    │────▶│ Fact_PO_Sent │     │
│  └──────────────┘     └──────────────┘     │
│                              ▲               │
│  ┌──────────────┐            │               │
│  │ Dim_Product  │────────────┤               │
│  └──────────────┘            │               │
│                              │               │
│  ┌──────────────┐     ┌──────────────┐     │
│  │ Dim_Supplier │────▶│Fact_PO_Recv'd│     │
│  └──────────────┘     └──────────────┘     │
│                              ▲               │
│  ┌──────────────┐            │               │
│  │ Dim_Location │────────────┤               │
│  └──────────────┘            │               │
│                       ┌──────────────┐       │
│                       │ Fact_Stock   │       │
│                       │   _Levels    │       │
│                       └──────────────┘       │
└─────────────────────────────────────────────┘
```

### **Big Data Pipeline:**

```
SQL Server → BACPAC Export → HDFS Migration → Hive/Pig Processing
```

---

## 📁 Project Structure

```
abc-electronics-data-warehouse/
├── sql-scripts/                    # SQL implementation
│   ├── SQLQuery.sql               # Complete DDL + DML + Queries
│   ├── 01_create_database.sql     # Database creation
│   ├── 02_create_dimensions.sql   # Dimension tables
│   ├── 03_create_facts.sql        # Fact tables
│   ├── 04_add_constraints.sql     # Foreign keys
│   └── 05_analytical_queries.sql  # Business queries
├── database/                       # Database files
│   └── task3.bacpac               # Full database backup
├── hadoop-implementation/          # Big Data components
│   ├── hive_setup.md              # Hive configuration
│   ├── pig_scripts/               # Apache Pig scripts
│   └── hdfs_migration.md          # HDFS data loading
├── reports/                        # Academic documentation
│   └── 25002034_CS7079_Case_Study_Report.pdf
├── documentation/                  # Additional docs
│   ├── SCHEMA_DESIGN.md           # Dimensional model docs
│   └── BUSINESS_REQUIREMENTS.md   # Requirements analysis
├── README.md                       # This file
├── requirements.txt                # Python dependencies
└── LICENSE                         # MIT License
```

---

## 🔑 Key Features

### ✅ **Dimensional Modeling**
- **Star Schema Design** with 4 dimensions, 3 fact tables
- **Slowly Changing Dimensions (SCD Type 2)** for Product & Supplier
- **Conformed Dimensions** shared across fact tables
- **Grain definition** at transaction/daily snapshot level

### ✅ **Database Implementation**
- **Microsoft SQL Server** relational database
- **Primary & Foreign Key** constraints for referential integrity
- **Surrogate keys** for dimension management
- **Date dimension** with calendar hierarchies

### ✅ **Big Data Integration**
- **Hadoop HDFS** distributed storage
- **Apache Hive** for SQL-like querying
- **Apache Pig** for ETL transformations
- **BACPAC export** for database portability

### ✅ **Analytical Capabilities**
- Stock level monitoring (daily snapshots)
- Supplier performance analysis
- Purchase order tracking (sent vs. received)
- Understock/overstock detection
- Brand-wise inventory valuation

---

## 📊 Schema Details

### **Dimension Tables**

#### 1. **Dim_Date** (Time Dimension)
```sql
DateKey INT PRIMARY KEY          -- 20241201
FullDate DATE                    -- 2024-12-01
DayOfWeek VARCHAR(10)            -- Monday
WeekOfYear INT                   -- 48
Month INT, MonthName VARCHAR(10) -- 12, December
Quarter INT                      -- 4
Year INT                         -- 2024
IsWeekend BIT                    -- 0 or 1
```

**Purpose:** Calendar-based analysis, time hierarchies

---

#### 2. **Dim_Product** (Product Dimension - SCD Type 2)
```sql
ProductKey INT IDENTITY          -- Surrogate key
ProductID VARCHAR(50)            -- Business key
ProductName VARCHAR(255)         -- Samsung 55" QLED TV
ProductType VARCHAR(100)         -- Television
Brand VARCHAR(100)               -- Samsung
Category VARCHAR(100)            -- TVs
UnitPrice DECIMAL(10,2)          -- 899.99
ReorderLevel INT                 -- 10
CurrentStockLevel INT            -- 25
EffectiveDate DATE               -- SCD tracking
ExpiryDate DATE                  -- SCD tracking
IsCurrent BIT                    -- Active version flag
```

**Purpose:** Product analysis, price history tracking

---

#### 3. **Dim_Supplier** (Supplier Dimension - SCD Type 2)
```sql
SupplierKey INT IDENTITY         -- Surrogate key
SupplierID VARCHAR(50)           -- Business key
SupplierName VARCHAR(255)        -- Samsung Electronics UK
ContactPerson VARCHAR(100)       
PhoneNumber, Email               
Address, City, Country           
EffectiveDate DATE               -- SCD tracking
ExpiryDate DATE                  
IsCurrent BIT                    
```

**Purpose:** Supplier performance, contact management

---

#### 4. **Dim_Location** (Warehouse Location)
```sql
LocationKey INT IDENTITY         
LocationID VARCHAR(50)           
LocationName VARCHAR(100)        -- Main Warehouse - Section A
LocationType VARCHAR(50)         -- Warehouse
Capacity INT                     -- 5000
WarehouseSection VARCHAR(50)     -- A
City VARCHAR(100)                -- London
```

**Purpose:** Geographic analysis, capacity planning

---

### **Fact Tables**

#### 1. **Fact_PurchaseOrder_Sent** (Transaction Fact)
```sql
PO_SentKey INT IDENTITY          -- Surrogate key
DateKey INT FK                   -- When ordered
ProductKey INT FK                -- What ordered
SupplierKey INT FK               -- From whom
PurchaseOrderID VARCHAR(50)      -- PO-2024-001
OrderedQuantity INT              -- 50 units
UnitPrice DECIMAL                -- 899.99
OrderValue DECIMAL               -- 44,999.50
ExpectedDeliveryDays INT         -- 7 days
```

**Grain:** One record per product per purchase order sent

---

#### 2. **Fact_PurchaseOrder_Received** (Transaction Fact)
```sql
PO_ReceivedKey INT IDENTITY      
DateKey INT FK                   -- When received
ProductKey INT FK                
SupplierKey INT FK               
LocationKey INT FK               -- Where received
PurchaseOrderID VARCHAR(50)      
OrderedQuantity INT              -- 50
ReceivedQuantity INT             -- 48 (actual)
DamagedQuantity INT              -- 2 (quality issues)
UnitPrice DECIMAL                
TotalValue DECIMAL               
DeliveryDelay INT                -- 0 (on time) or +/- days
```

**Grain:** One record per product per purchase order received

**Key Metrics:**
- Delivery accuracy: `ReceivedQuantity / OrderedQuantity`
- Damage rate: `DamagedQuantity / ReceivedQuantity`
- On-time delivery: `DeliveryDelay <= 0`

---

#### 3. **Fact_Stock_Levels** (Periodic Snapshot Fact)
```sql
StockLevelKey INT IDENTITY       
DateKey INT FK                   -- Daily snapshot
ProductKey INT FK                
LocationKey INT FK               
OpeningStock INT                 -- 25 (start of day)
StockReceived INT                -- 48 (deliveries)
StockSold INT                    -- 10 (sales)
StockAdjustment INT              -- -2 (damaged/write-off)
ClosingStock INT                 -- 61 (end of day)
MinimumStockLevel INT            -- 10 (reorder point)
StockValue DECIMAL               -- 61 × 899.99
IsUnderstock BIT                 -- Below minimum?
IsOverstock BIT                  -- Excess inventory?
```

**Grain:** One record per product per location per day

**Formula:**
```
ClosingStock = OpeningStock + StockReceived - StockSold + StockAdjustment
```

---

## 🛠️ Technologies Used

### **Database & Warehousing**
- **Microsoft SQL Server** - RDBMS
- **T-SQL** - Query language
- **SSMS (SQL Server Management Studio)** - Database IDE
- **BACPAC** - Database export/import format

### **Big Data Stack**
- **Apache Hadoop 3.x** - Distributed computing framework
- **HDFS (Hadoop Distributed File System)** - Distributed storage
- **Apache Hive 3.1.2** - SQL-on-Hadoop query engine
- **Apache Pig 0.16** - ETL scripting language
- **Ubuntu (GCP VM)** - Linux environment

### **Development & Documentation**
- **SQL** - DDL, DML, DQL
- **Markdown** - Documentation
- **Git/GitHub** - Version control

---

## 🚀 Getting Started

### **Prerequisites**

**For SQL Server Implementation:**
- SQL Server 2019+ or SQL Server Express
- SQL Server Management Studio (SSMS)
- Windows or Linux with SQL Server support

**For Hadoop Implementation:**
- Java JDK 8+
- Hadoop 3.x configured
- Hive 3.1+
- Apache Pig 0.16+
- Linux environment (Ubuntu recommended)

---

### **Installation & Setup**

#### **Option 1: Restore from BACPAC (Fastest)**

```bash
# 1. Download the BACPAC file
git clone https://github.com/YOUR_USERNAME/abc-electronics-data-warehouse.git
cd abc-electronics-data-warehouse/database

# 2. Open SSMS
# 3. Right-click "Databases" → "Import Data-tier Application"
# 4. Select task3.bacpac
# 5. Database name: ABC_Electronics_DW
# 6. Click "Import"
```

**Result:** Full database with schema + sample data loaded instantly!

---

#### **Option 2: Run SQL Scripts (Step-by-Step)**

```sql
-- 1. Create database
CREATE DATABASE ABC_Electronics_DW;
GO

-- 2. Run scripts in order
-- (See sql-scripts/SQLQuery.sql for complete implementation)

-- 3. Verify installation
USE ABC_Electronics_DW;
SELECT * FROM INFORMATION_SCHEMA.TABLES;
```

---

### **Running Analytical Queries**

```sql
-- Example 1: Daily Stock Movements
SELECT 
    d.FullDate,
    p.ProductName,
    l.LocationName,
    f.OpeningStock,
    f.StockReceived,
    f.StockSold,
    f.ClosingStock
FROM Fact_Stock_Levels f
JOIN Dim_Date d ON f.DateKey = d.DateKey
JOIN Dim_Product p ON f.ProductKey = p.ProductKey
JOIN Dim_Location l ON f.LocationKey = l.LocationKey
ORDER BY d.FullDate, p.ProductName;
```

```sql
-- Example 2: Supplier Performance (Monthly)
SELECT 
    s.SupplierName,
    d.Month,
    d.Year,
    COUNT(r.PO_ReceivedKey) AS TotalOrders,
    SUM(r.ReceivedQuantity) AS TotalUnits,
    SUM(r.TotalValue) AS Revenue,
    AVG(r.DeliveryDelay) AS AvgDelay
FROM Fact_PurchaseOrder_Received r
JOIN Dim_Supplier s ON r.SupplierKey = s.SupplierKey
JOIN Dim_Date d ON r.DateKey = d.DateKey
GROUP BY s.SupplierName, d.Month, d.Year;
```

```sql
-- Example 3: Understock/Overstock Detection
SELECT 
    p.ProductName,
    l.LocationName,
    f.ClosingStock,
    f.MinimumStockLevel,
    CASE 
        WHEN f.IsUnderstock = 1 THEN 'UNDER-STOCK ⚠️'
        WHEN f.IsOverstock = 1 THEN 'OVER-STOCK 📦'
        ELSE 'NORMAL ✅'
    END AS StockStatus
FROM Fact_Stock_Levels f
JOIN Dim_Product p ON f.ProductKey = p.ProductKey
JOIN Dim_Location l ON f.LocationKey = l.LocationKey
WHERE f.IsUnderstock = 1 OR f.IsOverstock = 1;
```

---

## 📊 Sample Data Insights

### **Purchase Orders Summary:**
- **PO-2024-001:** Samsung TV - 50 ordered, 48 received, 2 damaged ❌
- **PO-2024-002:** Sony Headphones - 100 ordered, 100 received, delivered 2 days early ✅

### **Stock Movement Example:**
```
Product: Samsung 55" QLED TV
Location: Main Warehouse - Section A

Dec 1: Opening 25 → Sold 3 → Closing 22
Dec 2: Opening 22 → Sold 5 → Closing 17
Dec 3: Opening 17 → Received 48 → Sold 10 → Damaged -2 → Closing 53 (OVERSTOCK!)
```

---

## 🌐 Big Data Pipeline

### **Data Migration to HDFS**

```bash
# 1. Export data from SQL Server to CSV
sqlcmd -S localhost -d ABC_Electronics_DW -Q "SELECT * FROM Fact_Stock_Levels" -o stock_levels.csv -s "," -W

# 2. Copy to HDFS
hdfs dfs -put stock_levels.csv /user/hive/warehouse/abc_dw/

# 3. Create Hive external table
CREATE EXTERNAL TABLE stock_levels_ext (
    StockLevelKey INT,
    DateKey INT,
    ProductKey INT,
    LocationKey INT,
    OpeningStock INT,
    StockReceived INT,
    StockSold INT,
    ClosingStock INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION '/user/hive/warehouse/abc_dw/';
```

### **Apache Pig ETL Example**

```pig
-- Load stock data
stock_data = LOAD '/user/hive/warehouse/abc_dw/stock_levels.csv' 
    USING PigStorage(',') 
    AS (date_key:int, product_key:int, closing_stock:int);

-- Filter understock situations
understock = FILTER stock_data BY closing_stock < 10;

-- Group by product
by_product = GROUP understock BY product_key;

-- Count understock days per product
understock_summary = FOREACH by_product GENERATE 
    group AS product_key, 
    COUNT(understock) AS understock_days;

-- Store results
STORE understock_summary INTO '/user/output/understock_report';
```

---

## 📈 Business Intelligence Capabilities

### **Key Performance Indicators (KPIs)**

1. **Inventory Turnover**
   - `Total Stock Sold / Average Inventory`

2. **Fill Rate**
   - `(Received Quantity / Ordered Quantity) × 100%`

3. **Supplier On-Time Delivery**
   - `% of orders with DeliveryDelay <= 0`

4. **Stock Accuracy**
   - `(1 - Damaged Quantity / Received Quantity) × 100%`

5. **Understock Days**
   - `COUNT of days where ClosingStock < MinimumStockLevel`

---

## 🎓 Academic Contributions

### **Dimensional Modeling Principles Applied:**

✅ **Kimball Methodology** - Star schema, conformed dimensions  
✅ **Grain Definition** - Transaction & periodic snapshot facts  
✅ **SCD Type 2** - Historical tracking for products & suppliers  
✅ **Surrogate Keys** - System-generated IDs for flexibility  
✅ **Date Dimension** - Calendar hierarchies (day → week → month → quarter → year)  
✅ **Fact Table Types** - Transaction facts + snapshot facts  

### **Big Data Best Practices:**

✅ **HDFS Distribution** - Fault-tolerant distributed storage  
✅ **Hive Partitioning** - Query performance optimization  
✅ **Pig Latin ETL** - Flexible data transformations  
✅ **External Tables** - Schema-on-read for flexibility  

---

## 📚 References

1. Rudniy, A. (2022). Data Warehouse Design for Big Data in Academia. *Computers, Materials & Continua*, 71(1).

2. Harby, A.A. & Zulkernine, F. (2022). From Data Warehouse to Lakehouse: A Comparative Review. *IEEE Big Data Conference*.

3. Nambiar, A. & Mundra, D. (2022). An Overview of Data Warehouse and Data Lake in Modern Enterprise Data Management. *Big Data and Cognitive Computing*, 6(4), 132.

4. Köppen, V., Saake, G. & Sattler, K.U. (2021). *Data Warehouse Technologien*. BoD–Books on Demand.

*Full references in academic report PDF*

---

## 💡 Future Enhancements

### **Short-Term (Next 3 months):**
- [ ] Add customer sales dimension
- [ ] Implement real-time streaming with Kafka
- [ ] Create Power BI dashboard
- [ ] Add data quality checks

### **Medium-Term (6-12 months):**
- [ ] Machine learning for demand forecasting
- [ ] Integrate with cloud (Azure Synapse Analytics)
- [ ] Automated ETL with Apache Airflow
- [ ] Predictive analytics for stock optimization

### **Long-Term (1+ years):**
- [ ] Real-time inventory updates
- [ ] IoT sensor integration
- [ ] Advanced analytics with Spark
- [ ] Data lake architecture (Delta Lake)

---

## 🆘 Troubleshooting

### **Issue 1: BACPAC Import Fails**

**Error:** "Version incompatibility"

**Solution:**
- Ensure SQL Server version matches (2019+)
- Update SSMS to latest version
- Check BACPAC file integrity

---

### **Issue 2: Foreign Key Violation**

**Error:** "FK constraint failed"

**Solution:**
```sql
-- Disable constraints temporarily
ALTER TABLE Fact_PurchaseOrder_Sent NOCHECK CONSTRAINT ALL;
-- Insert data
-- Re-enable constraints
ALTER TABLE Fact_PurchaseOrder_Sent CHECK CONSTRAINT ALL;
```

---

### **Issue 3: Hadoop Connection Errors**

**Solution:**
```bash
# Check Hadoop services
jps

# Restart if needed
stop-all.sh
start-all.sh

# Verify HDFS
hdfs dfs -ls /
```

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

**Data:** Synthetic sample data for educational purposes.

---

## 📞 Contact

**Yagnesh Vaghashiya**  
Maild id: yagneshvaghashiya602@gmail.com
Mobile Number: +44 7887 172884
**Supervisor:** Dr. Cheima Ali Bensaad

---

## 🌟 Acknowledgments

- **Dr. Cheima Ali Bensaad** - Course supervision and guidance
- **London Metropolitan University** - Academic support
- **Apache Software Foundation** - Hadoop ecosystem
- **Microsoft** - SQL Server platform

---

## 📊 Repository Statistics

![SQL](https://img.shields.io/badge/SQL-T--SQL-blue.svg)
![Hadoop](https://img.shields.io/badge/Hadoop-3.x-yellow.svg)
![Hive](https://img.shields.io/badge/Hive-3.1-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Status](https://img.shields.io/badge/Status-Complete-success.svg)

---

**Last Updated:** May 2026  
**Project Status:** ✅ Complete and Submitted

---

*This project demonstrates practical application of data warehousing principles and big data technologies to solve real-world inventory management challenges.*
