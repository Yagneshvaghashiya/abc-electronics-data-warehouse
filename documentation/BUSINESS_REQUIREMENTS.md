# Business Requirements Document

## 📋 Executive Summary

**Project:** ABC Electronics Data Warehouse  
**Business Unit:** Operations & Supply Chain  
**Project Sponsor:** Supply Chain Director  
**Date:** May 2026  
**Status:** Implementation Complete

---

## 🎯 Business Problem Statement

ABC Electronics faces challenges in:

1. **Inventory Management:** Frequent stockouts and overstock situations
2. **Supplier Performance:** Lack of visibility into delivery reliability and quality
3. **Decision Making:** Slow access to integrated operational data
4. **Cost Control:** Difficulty tracking procurement costs and inventory holding costs
5. **Reporting:** Manual, time-consuming report generation from multiple systems

**Impact:**
- Lost sales due to stockouts: ~5% revenue
- Excess inventory carrying costs: ~12% of inventory value
- Manual reporting effort: 40+ hours/week
- Delayed business decisions: 3-5 day lag

---

## 💼 Business Objectives

### Primary Objectives

1. **Reduce Stockouts by 50%**
   - Metric: % of days with understock situations
   - Target: From 10% to 5% of product-location-day combinations
   - Timeline: 6 months

2. **Improve Supplier On-Time Delivery to 95%**
   - Metric: % of orders delivered on or before expected date
   - Current: 78%
   - Target: 95%
   - Timeline: 12 months

3. **Reduce Inventory Holding Costs by 15%**
   - Metric: Average inventory value
   - Current: £2.5M
   - Target: £2.125M
   - Timeline: 12 months

4. **Automate 80% of Operational Reports**
   - Metric: Hours spent on manual reporting
   - Current: 40 hours/week
   - Target: 8 hours/week
   - Timeline: 3 months

### Secondary Objectives

- Improve inventory turnover ratio
- Reduce damaged goods from suppliers
- Optimize warehouse space utilization
- Enable data-driven procurement decisions

---

## 👥 Key Stakeholders

| Stakeholder | Role | Primary Interest |
|-------------|------|------------------|
| Operations Director | Executive Sponsor | ROI, strategic decisions |
| Supply Chain Manager | Primary User | Supplier performance, procurement |
| Warehouse Manager | Primary User | Stock levels, location utilization |
| Finance Controller | Secondary User | Inventory valuation, costs |
| Procurement Team | Primary Users | Purchase order tracking |
| IT Director | Technical Sponsor | System integration, data quality |

---

## 📊 Business Questions to Answer

### Inventory Management Questions

1. **Stock Health**
   - Which products are currently understocked?
   - Which products have excess inventory?
   - What is the current stock value by location?
   - What is the inventory turnover rate by product category?

2. **Stock Movement**
   - What are daily/weekly/monthly stock movements?
   - Which products have the highest sales velocity?
   - What is the average days of inventory by product?
   - How much stock was received vs. sold this week?

3. **Capacity Planning**
   - What is the warehouse utilization by location?
   - Which locations are nearing capacity?
   - How much storage space is available?

### Supplier Performance Questions

4. **Delivery Performance**
   - What is the on-time delivery rate by supplier?
   - Which suppliers consistently deliver late?
   - What is the average delivery delay by supplier?
   - How many orders were delivered early/on-time/late?

5. **Quality & Accuracy**
   - What is the fill rate (received vs. ordered) by supplier?
   - What is the damage rate by supplier?
   - Which suppliers have the most quality issues?
   - What is the financial loss due to damaged goods?

6. **Supplier Comparison**
   - Which suppliers offer the best overall performance?
   - How do suppliers compare within each product category?
   - What is the total spend by supplier?

### Purchase Order Analysis Questions

7. **Order Tracking**
   - How many purchase orders are currently outstanding?
   - What is the status of today's expected deliveries?
   - Which orders have discrepancies (variance between ordered and received)?
   - What is the average order value by supplier?

8. **Cost Analysis**
   - What is the total procurement spend by category?
   - How have unit prices changed over time?
   - What is the cost impact of damaged goods?
   - What is the opportunity cost of stockouts?

---

## 📈 Key Performance Indicators (KPIs)

### Inventory KPIs

| KPI | Formula | Target | Reporting Frequency |
|-----|---------|--------|---------------------|
| Inventory Turnover | Cost of Goods Sold / Avg Inventory | > 8x/year | Monthly |
| Days of Inventory | Avg Inventory / (Sales / 365) | < 45 days | Weekly |
| Stockout Rate | Understock Days / Total Days | < 5% | Daily |
| Overstock Rate | Overstock Days / Total Days | < 10% | Weekly |
| Stock Accuracy | (1 - Adjustments / Stock) × 100 | > 98% | Monthly |

### Supplier KPIs

| KPI | Formula | Target | Reporting Frequency |
|-----|---------|--------|---------------------|
| On-Time Delivery | Orders On Time / Total Orders × 100 | > 95% | Weekly |
| Fill Rate | Received / Ordered × 100 | > 98% | Weekly |
| Damage Rate | Damaged / Received × 100 | < 2% | Monthly |
| Lead Time Variance | Actual Days - Expected Days | ±1 day | Monthly |
| Supplier Quality Score | Composite score (0-100) | > 80 | Monthly |

### Operational KPIs

| KPI | Formula | Target | Reporting Frequency |
|-----|---------|--------|---------------------|
| Warehouse Utilization | Current Stock / Capacity × 100 | 70-85% | Weekly |
| Order Accuracy | Perfect Orders / Total Orders | > 95% | Weekly |
| Average Order Value | Total Order Value / Order Count | Track trend | Monthly |
| Procurement Cycle Time | Order to Receipt (days) | < 10 days | Monthly |

---

## 📋 Functional Requirements

### FR-1: Stock Level Monitoring

**Requirement:** The system must track daily stock levels for each product at each location.

**Details:**
- Capture opening stock, receipts, sales, adjustments, closing stock
- Calculate stock value based on current unit price
- Flag understock and overstock situations
- Support historical trend analysis

**Acceptance Criteria:**
- Daily snapshots captured for all active products
- Stock balance equation holds: Closing = Opening + Received - Sold + Adjustment
- Understock/overstock flags accurate based on minimum level thresholds

---

### FR-2: Purchase Order Tracking

**Requirement:** Track purchase orders from creation through receipt.

**Details:**
- Record orders sent to suppliers (expected quantity, value, delivery date)
- Record orders received (actual quantity, damaged units, delivery date)
- Calculate variances and performance metrics
- Link sent and received orders

**Acceptance Criteria:**
- All PO transactions captured
- Variance reporting available (ordered vs. received)
- Delivery delay calculated correctly
- Damaged goods tracked separately

---

### FR-3: Supplier Performance Analysis

**Requirement:** Provide comprehensive supplier performance metrics.

**Details:**
- On-time delivery percentage
- Fill rate (order accuracy)
- Quality metrics (damage rate)
- Lead time analysis
- Supplier comparison capabilities

**Acceptance Criteria:**
- Metrics calculated automatically from transaction data
- Suppliers can be ranked by performance
- Historical trends available
- Drill-down by product category supported

---

### FR-4: Reporting & Analytics

**Requirement:** Generate automated reports and support ad-hoc analysis.

**Details:**
- Standard daily/weekly/monthly reports
- Customizable dashboards
- Drill-down capabilities
- Export to Excel/PDF
- Email distribution of scheduled reports

**Acceptance Criteria:**
- Reports refresh automatically with new data
- Users can filter and customize views
- Response time < 5 seconds for standard reports
- Export functionality works for all reports

---

### FR-5: Historical Data Management

**Requirement:** Maintain historical data for trend analysis and compliance.

**Details:**
- Minimum 3 years of historical data
- Track product price changes over time
- Track supplier contact changes
- Support year-over-year comparisons

**Acceptance Criteria:**
- Historical data retrievable for 3+ years
- Price history maintained via SCD Type 2
- Historical accuracy maintained (no retroactive changes)

---

## 🔧 Technical Requirements

### TR-1: Data Integration

**Sources:**
- ERP System (Purchase Orders)
- Warehouse Management System (Stock Levels)
- Supplier Portal (Delivery Confirmations)

**Frequency:**
- Real-time: Purchase order creation
- Daily batch: Stock level snapshots (end of day)
- Event-driven: Goods receipt transactions

---

### TR-2: Data Quality

**Requirements:**
- 100% referential integrity
- No duplicate records
- All required fields populated
- Data validation at load time
- Error logging and alerting

---

### TR-3: Performance

**Requirements:**
- Query response < 5 seconds (95th percentile)
- Nightly ETL completion within 2-hour window
- Support for 10 concurrent users
- 99.5% system availability during business hours

---

### TR-4: Security

**Requirements:**
- Role-based access control
- Audit trail of data changes
- Data encryption in transit and at rest
- Compliance with GDPR

---

## 📊 Reporting Requirements

### Daily Reports

1. **Stock Status Report**
   - Current understock/overstock situations
   - Products requiring immediate reorder
   - Critical stock alerts

2. **Delivery Status Report**
   - Expected deliveries for the day
   - Late deliveries
   - Quality issues from recent receipts

### Weekly Reports

3. **Supplier Performance Scorecard**
   - On-time delivery rates
   - Quality metrics
   - Fill rates
   - Top/bottom performers

4. **Inventory Movement Summary**
   - Total stock received
   - Total stock sold
   - Net inventory change
   - Turnover ratios

### Monthly Reports

5. **Inventory Valuation Report**
   - Stock value by product category
   - Stock value by location
   - Month-over-month changes
   - Slow-moving inventory identification

6. **Procurement Analysis**
   - Total spend by supplier
   - Total spend by category
   - Order count and average order value
   - Price trend analysis

---

## 💰 Expected Benefits

### Quantifiable Benefits

1. **Revenue Protection:** £500K/year
   - Reduced stockouts = fewer lost sales

2. **Cost Reduction:** £300K/year
   - Reduced excess inventory carrying costs
   - Optimized procurement decisions

3. **Efficiency Gains:** £120K/year
   - Automated reporting (32 hours/week × £60/hour × 52 weeks)

4. **Quality Improvement:** £50K/year
   - Better supplier selection = fewer damaged goods

**Total Annual Benefit:** £970K

### Qualitative Benefits

- Improved customer satisfaction (better product availability)
- Faster, data-driven decision making
- Better supplier relationships (objective performance data)
- Improved warehouse efficiency
- Regulatory compliance (better audit trail)

---

## 📅 Success Criteria

The project will be considered successful when:

✅ All 3 fact tables operational with daily data loads  
✅ All 4 dimension tables populated and maintained  
✅ 10 standard reports automated and scheduled  
✅ User training completed (20+ users trained)  
✅ Data quality > 99.5% accuracy  
✅ Query performance targets met  
✅ Stakeholder sign-off received  

---

## 🚀 Implementation Phases

### Phase 1: Foundation (Complete)
- ✅ Dimensional model design
- ✅ SQL Server database implementation
- ✅ Initial data population
- ✅ Data quality validation

### Phase 2: Big Data Integration (Complete)
- ✅ Hadoop/HDFS setup
- ✅ Hive table creation
- ✅ Data migration to distributed environment
- ✅ Pig scripts for ETL

### Phase 3: Reporting & Analytics (Future)
- Power BI dashboard development
- Standard report creation
- User training
- Production deployment

### Phase 4: Optimization (Future)
- Performance tuning
- Advanced analytics (predictive models)
- Real-time integration
- Mobile access

---

## 📞 Contact Information

**Project Team:**
- **Student:** Yagnesh Vaghashiya (25002034)
- **Supervisor:** Dr. Cheima Ali Bensaad
- **Institution:** London Metropolitan University
- **Course:** CS7079 Data Warehousing and Big Data

---

**Document Version:** 1.0  
**Last Updated:** May 2026
