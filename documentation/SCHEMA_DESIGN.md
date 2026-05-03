# Schema Design Documentation

## 🎯 Overview

This document provides detailed documentation of the ABC Electronics Data Warehouse dimensional model, including design rationale, business rules, and implementation details.

---

## 📊 Dimensional Model Type

**Schema Type:** Galaxy Schema (Fact Constellation)

**Justification:**
- Multiple business processes require separate fact tables
- Shared (conformed) dimensions across fact tables enable consistent analysis
- Supports both transaction-level and snapshot-level analysis

---

## 🔑 Grain Definitions

### Fact Table 1: Fact_PurchaseOrder_Sent
**Grain:** One row per product per purchase order sent to supplier

**Business Meaning:** Captures the initial ordering activity - what was requested from suppliers

**Update Frequency:** Insert only (append-only)

**Example:**
- PO-2024-001: Samsung TV, 50 units ordered from Samsung Electronics UK on Dec 1, 2024

---

### Fact Table 2: Fact_PurchaseOrder_Received
**Grain:** One row per product per purchase order received from supplier

**Business Meaning:** Captures delivery fulfillment - what was actually received vs. ordered

**Update Frequency:** Insert only (append-only)

**Example:**
- PO-2024-001: Samsung TV, 50 ordered, 48 received, 2 damaged, 0 days delay

---

### Fact Table 3: Fact_Stock_Levels
**Grain:** One row per product per location per day (periodic snapshot)

**Business Meaning:** Daily snapshot of inventory position at each location

**Update Frequency:** Daily insert (one snapshot per day)

**Example:**
- Dec 3, 2024: Samsung TV at Warehouse A - Opening 17, Received 48, Sold 10, Damaged -2, Closing 53

---

## 📐 Dimension Tables

### 1. Dim_Date (Calendar Dimension)

**Type:** Standard date dimension

**SCD Type:** Not applicable (dates are immutable)

**Key Attributes:**

| Attribute | Type | Purpose |
|-----------|------|---------|
| DateKey | INT (PK) | Surrogate key (format: YYYYMMDD) |
| FullDate | DATE | Actual calendar date |
| DayOfWeek | VARCHAR(10) | Monday, Tuesday, etc. |
| WeekOfYear | INT | ISO week number (1-53) |
| Month | INT | Month number (1-12) |
| MonthName | VARCHAR(10) | January, February, etc. |
| Quarter | INT | Quarter (1-4) |
| Year | INT | Year (2024, 2025, etc.) |
| IsWeekend | BIT | TRUE for Sat/Sun |

**Business Rules:**
- DateKey uses integer format YYYYMMDD for performance (e.g., 20241201)
- Populated for 10 years past and 5 years future
- Fiscal year = Calendar year (Jan-Dec)

**Hierarchies:**
```
Day → Week → Month → Quarter → Year
Day → Month → Year
```

---

### 2. Dim_Product (Product Dimension)

**Type:** SCD Type 2 (Slowly Changing Dimension)

**SCD Type Justification:**
- Price changes need to be tracked historically
- Product specifications may change over time
- Business requires historical accuracy for profitability analysis

**Key Attributes:**

| Attribute | Type | SCD Tracking |
|-----------|------|--------------|
| ProductKey | INT (PK) | Surrogate key |
| ProductID | VARCHAR(50) | Business key (natural key) |
| ProductName | VARCHAR(255) | Type 2 tracked |
| ProductType | VARCHAR(100) | Type 2 tracked |
| Brand | VARCHAR(100) | Type 2 tracked |
| Category | VARCHAR(100) | Type 2 tracked |
| UnitPrice | DECIMAL(10,2) | **Type 2 tracked** |
| ReorderLevel | INT | Type 1 (overwrite) |
| CurrentStockLevel | INT | Type 1 (overwrite) |
| EffectiveDate | DATE | SCD metadata |
| ExpiryDate | DATE | SCD metadata |
| IsCurrent | BIT | SCD metadata (TRUE/FALSE) |

**SCD Type 2 Example:**

| ProductKey | ProductID | ProductName | UnitPrice | EffectiveDate | ExpiryDate | IsCurrent |
|------------|-----------|-------------|-----------|---------------|------------|-----------|
| 1 | PROD001 | Samsung 55" TV | 899.99 | 2024-01-01 | 2024-06-30 | FALSE |
| 2 | PROD001 | Samsung 55" TV | 849.99 | 2024-07-01 | NULL | TRUE |

**Business Rules:**
- New surrogate key created when price changes
- Historical records have ExpiryDate populated
- Current record has IsCurrent = TRUE and ExpiryDate = NULL
- Only one current version per ProductID

---

### 3. Dim_Supplier (Supplier Dimension)

**Type:** SCD Type 2

**SCD Type Justification:**
- Contact information changes need to be tracked
- Historical accuracy for supplier performance analysis
- Legal/audit requirements for supplier relationship history

**Key Attributes:**

| Attribute | Type | SCD Tracking |
|-----------|------|--------------|
| SupplierKey | INT (PK) | Surrogate key |
| SupplierID | VARCHAR(50) | Business key |
| SupplierName | VARCHAR(255) | Type 2 tracked |
| ContactPerson | VARCHAR(100) | Type 2 tracked |
| PhoneNumber | VARCHAR(20) | Type 2 tracked |
| Email | VARCHAR(100) | Type 2 tracked |
| Address | VARCHAR(255) | Type 2 tracked |
| City | VARCHAR(100) | Type 2 tracked |
| Country | VARCHAR(100) | Type 2 tracked |
| EffectiveDate | DATE | SCD metadata |
| ExpiryDate | DATE | SCD metadata |
| IsCurrent | BIT | SCD metadata |

**Business Rules:**
- New version created when contact details change
- Supplier name changes trigger new version
- Location changes trigger new version

---

### 4. Dim_Location (Warehouse Location Dimension)

**Type:** SCD Type 1 (Overwrite)

**SCD Type Justification:**
- Location attributes change infrequently
- Historical location details not required for analysis
- Capacity updates are current-value only

**Key Attributes:**

| Attribute | Type | Notes |
|-----------|------|-------|
| LocationKey | INT (PK) | Surrogate key |
| LocationID | VARCHAR(50) | Business key |
| LocationName | VARCHAR(100) | Warehouse name + section |
| LocationType | VARCHAR(50) | Warehouse, Store, etc. |
| Capacity | INT | Maximum units capacity |
| WarehouseSection | VARCHAR(50) | A, B, C, etc. |
| City | VARCHAR(100) | Geographic location |

**Business Rules:**
- Capacity updates overwrite previous value
- No historical tracking required

---

## 📈 Fact Table Measures

### Fact_PurchaseOrder_Sent Measures

| Measure | Type | Aggregation | Business Meaning |
|---------|------|-------------|------------------|
| OrderedQuantity | INT | SUM | Units requested from supplier |
| UnitPrice | DECIMAL(10,2) | AVG | Price per unit at order time |
| OrderValue | DECIMAL(12,2) | SUM | Total value of order |
| ExpectedDeliveryDays | INT | AVG | Lead time expectation |

**Calculated Metrics:**
- Average Order Size = SUM(OrderedQuantity) / COUNT(*)
- Total Procurement Spend = SUM(OrderValue)

---

### Fact_PurchaseOrder_Received Measures

| Measure | Type | Aggregation | Business Meaning |
|---------|------|-------------|------------------|
| OrderedQuantity | INT | SUM | What was ordered |
| ReceivedQuantity | INT | SUM | What was actually received |
| DamagedQuantity | INT | SUM | Damaged/defective units |
| UnitPrice | DECIMAL(10,2) | AVG | Price per unit |
| TotalValue | DECIMAL(12,2) | SUM | Actual value received |
| DeliveryDelay | INT | AVG | Days late (+) or early (-) |

**Calculated Metrics:**
- Fill Rate = ReceivedQuantity / OrderedQuantity * 100
- Damage Rate = DamagedQuantity / ReceivedQuantity * 100
- On-Time Delivery % = COUNT(DeliveryDelay <= 0) / COUNT(*) * 100

---

### Fact_Stock_Levels Measures

| Measure | Type | Aggregation | Business Meaning |
|---------|------|-------------|------------------|
| OpeningStock | INT | SUM | Stock at start of day |
| StockReceived | INT | SUM | Units added during day |
| StockSold | INT | SUM | Units sold during day |
| StockAdjustment | INT | SUM | Adjustments (damage/loss) |
| ClosingStock | INT | SUM | Stock at end of day |
| MinimumStockLevel | INT | MIN | Reorder point threshold |
| StockValue | DECIMAL(12,2) | SUM | Inventory value |
| IsUnderstock | BIT | SUM | Understock flag |
| IsOverstock | BIT | SUM | Overstock flag |

**Business Rule (Stock Balance):**
```
ClosingStock = OpeningStock + StockReceived - StockSold + StockAdjustment
```

**Calculated Metrics:**
- Inventory Turnover = StockSold / AVG(ClosingStock)
- Days of Inventory = AVG(ClosingStock) / (StockSold / Days)
- Stock Accuracy = (1 - ABS(StockAdjustment) / ClosingStock) * 100

---

## 🔗 Referential Integrity

### Foreign Key Relationships

```
Fact_PurchaseOrder_Sent
├── DateKey → Dim_Date.DateKey
├── ProductKey → Dim_Product.ProductKey
└── SupplierKey → Dim_Supplier.SupplierKey

Fact_PurchaseOrder_Received
├── DateKey → Dim_Date.DateKey
├── ProductKey → Dim_Product.ProductKey
├── SupplierKey → Dim_Supplier.SupplierKey
└── LocationKey → Dim_Location.LocationKey

Fact_Stock_Levels
├── DateKey → Dim_Date.DateKey
├── ProductKey → Dim_Product.ProductKey
└── LocationKey → Dim_Location.LocationKey
```

**Enforcement:**
- All foreign keys enforced via constraints
- No orphan records allowed
- Dimension records must exist before fact insert

---

## 📊 Conformed Dimensions

**Shared Across Fact Tables:**

| Dimension | Used By | Benefit |
|-----------|---------|---------|
| Dim_Date | All 3 fact tables | Time-consistent analysis |
| Dim_Product | All 3 fact tables | Product-consistent metrics |
| Dim_Supplier | PO Sent, PO Received | Supplier consistency |
| Dim_Location | PO Received, Stock Levels | Location consistency |

**Example Benefit:**
Query across fact tables with consistent product and date definitions:
```sql
-- Total ordered vs. total sold for a product
SELECT 
    p.ProductName,
    SUM(sent.OrderedQuantity) as TotalOrdered,
    SUM(stock.StockSold) as TotalSold
FROM Dim_Product p  -- CONFORMED
JOIN Fact_PO_Sent sent ON p.ProductKey = sent.ProductKey
JOIN Fact_Stock_Levels stock ON p.ProductKey = stock.ProductKey
GROUP BY p.ProductName;
```

---

## 🎯 Design Principles Applied

### 1. **Kimball Methodology**
✅ Bus matrix defines conformed dimensions  
✅ Star schema for query performance  
✅ Grain clearly defined for each fact  

### 2. **Dimensional Modeling Best Practices**
✅ Surrogate keys for all dimensions  
✅ SCD Type 2 for historical tracking where needed  
✅ Fact tables store measurements only  
✅ Dimensions store descriptive context  

### 3. **Performance Optimization**
✅ Integer date keys for fast joins  
✅ Denormalized dimensions (no snowflaking)  
✅ Indexed foreign keys  

### 4. **Scalability**
✅ Partitioning ready (by date)  
✅ Supports incremental loads  
✅ Fact tables append-only  

---

## 📏 Data Quality Rules

### Dimension Data Quality

**Dim_Product:**
- ProductID must be unique per current version
- UnitPrice must be > 0
- ReorderLevel must be >= 0
- Only one IsCurrent = TRUE per ProductID

**Dim_Supplier:**
- SupplierID must be unique per current version
- Email must be valid format
- Phone must be valid format

**Dim_Date:**
- Complete date coverage (no gaps)
- DateKey = CAST(YEAR * 10000 + MONTH * 100 + DAY AS INT)

### Fact Data Quality

**All Fact Tables:**
- No NULL in foreign keys
- All foreign keys must exist in dimensions
- Numeric measures must be >= 0 (except adjustments)

**Fact_Stock_Levels:**
- Stock balance equation must hold
- ClosingStock = OpeningStock + Received - Sold + Adjustment

**Fact_PO_Received:**
- ReceivedQuantity <= OrderedQuantity + tolerance (10%)
- DamagedQuantity <= ReceivedQuantity

---

## 🔄 ETL Considerations

### Load Sequence

1. **Dimension Tables** (in order):
   - Dim_Date (one-time bulk load)
   - Dim_Location (infrequent updates)
   - Dim_Supplier (SCD Type 2 processing)
   - Dim_Product (SCD Type 2 processing)

2. **Fact Tables**:
   - Fact_PurchaseOrder_Sent (after order placement)
   - Fact_PurchaseOrder_Received (after delivery)
   - Fact_Stock_Levels (end-of-day snapshot)

### Change Data Capture (CDC)

**For SCD Type 2:**
```
IF product price changes:
  1. Set current record ExpiryDate = CURRENT_DATE - 1
  2. Set current record IsCurrent = FALSE
  3. Insert new record with new price
  4. Set new record EffectiveDate = CURRENT_DATE
  5. Set new record IsCurrent = TRUE
```

---

## 📚 References

- Kimball, R. & Ross, M. (2013). *The Data Warehouse Toolkit* (3rd ed.)
- Inmon, W. H. (2005). *Building the Data Warehouse*
- Moss, L. T. & Atre, S. (2003). *Business Intelligence Roadmap*

---

**Document Version:** 1.0  
**Last Updated:** May 2026  
**Author:** Yagnesh Vaghashiya (25002034)
