-- ============================================================================
-- ABC Electronics - Hive Analytical Queries
-- ============================================================================
-- Purpose: Advanced analytical queries for business intelligence
-- Author: Yagnesh Vaghashiya (25002034)
-- Date: May 2026
-- ============================================================================

USE abc_electronics_dw;

-- ============================================================================
-- QUERY 1: Monthly Stock Turnover by Product Category
-- ============================================================================

SELECT 
    p.category,
    SUBSTR(CAST(d.FullDate AS STRING), 1, 7) AS year_month,
    SUM(f.stock_sold) AS total_units_sold,
    AVG(f.closing_stock) AS avg_inventory,
    ROUND(SUM(f.stock_sold) / AVG(f.closing_stock), 2) AS turnover_ratio
FROM fact_stock_levels f
JOIN dim_date d ON f.DateKey = d.DateKey
JOIN dim_product p ON f.ProductKey = p.ProductKey
GROUP BY p.category, SUBSTR(CAST(d.FullDate AS STRING), 1, 7)
ORDER BY year_month, turnover_ratio DESC;

-- ============================================================================
-- QUERY 2: Supplier Performance Dashboard Metrics
-- ============================================================================

SELECT 
    s.SupplierName,
    s.Country,
    COUNT(DISTINCT r.PurchaseOrderID) AS total_orders,
    SUM(r.TotalValue) AS total_revenue,
    ROUND(AVG(CAST(r.ReceivedQuantity AS DOUBLE) / r.OrderedQuantity) * 100, 2) AS avg_fill_rate_pct,
    ROUND(SUM(CASE WHEN r.DeliveryDelay <= 0 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS on_time_pct,
    ROUND(AVG(r.DeliveryDelay), 1) AS avg_delay_days,
    ROUND(SUM(r.DamagedQuantity) / SUM(r.ReceivedQuantity) * 100, 2) AS damage_rate_pct
FROM fact_po_received r
JOIN dim_supplier s ON r.SupplierKey = s.SupplierKey
WHERE s.IsCurrent = TRUE
GROUP BY s.SupplierName, s.Country
ORDER BY total_revenue DESC;

-- ============================================================================
-- QUERY 3: Inventory Health by Location and Product
-- ============================================================================

SELECT 
    l.LocationName,
    l.City,
    p.ProductName,
    p.Brand,
    f.ClosingStock,
    f.MinimumStockLevel,
    f.StockValue,
    CASE 
        WHEN f.IsUnderstock = TRUE THEN 'UNDERSTOCK - URGENT'
        WHEN f.ClosingStock < (f.MinimumStockLevel * 1.5) THEN 'LOW - REORDER SOON'
        WHEN f.IsOverstock = TRUE THEN 'OVERSTOCK - REDUCE'
        WHEN f.ClosingStock > (f.MinimumStockLevel * 3) THEN 'HIGH - REVIEW'
        ELSE 'NORMAL'
    END AS stock_status,
    CASE 
        WHEN f.IsUnderstock = TRUE THEN (f.MinimumStockLevel - f.ClosingStock)
        WHEN f.IsOverstock = TRUE THEN (f.ClosingStock - f.MinimumStockLevel * 2)
        ELSE 0
    END AS action_units
FROM fact_stock_levels f
JOIN dim_location l ON f.LocationKey = l.LocationKey
JOIN dim_product p ON f.ProductKey = p.ProductKey
JOIN dim_date d ON f.DateKey = d.DateKey
WHERE d.FullDate = (SELECT MAX(FullDate) FROM dim_date)  -- Latest date only
  AND (f.IsUnderstock = TRUE OR f.IsOverstock = TRUE)
ORDER BY 
    CASE 
        WHEN f.IsUnderstock = TRUE THEN 1 
        WHEN f.IsOverstock = TRUE THEN 2 
        ELSE 3 
    END,
    f.StockValue DESC;

-- ============================================================================
-- QUERY 4: Product Profitability Analysis
-- ============================================================================

SELECT 
    p.Brand,
    p.Category,
    p.ProductName,
    COUNT(DISTINCT f.DateKey) AS days_in_stock,
    SUM(f.StockSold) AS total_units_sold,
    AVG(f.ClosingStock) AS avg_inventory_level,
    SUM(f.StockSold * p.UnitPrice) AS total_revenue,
    ROUND(SUM(f.StockSold) / AVG(f.ClosingStock), 2) AS inventory_turnover,
    ROUND(AVG(f.StockValue), 2) AS avg_capital_tied
FROM fact_stock_levels f
JOIN dim_product p ON f.ProductKey = p.ProductKey
WHERE p.IsCurrent = TRUE
GROUP BY p.Brand, p.Category, p.ProductName, p.UnitPrice
HAVING SUM(f.StockSold) > 0
ORDER BY total_revenue DESC
LIMIT 20;

-- ============================================================================
-- QUERY 5: Purchase Order Accuracy and Discrepancies
-- ============================================================================

SELECT 
    sent.PurchaseOrderID,
    s.SupplierName,
    p.ProductName,
    sent.OrderedQuantity AS qty_ordered,
    recv.ReceivedQuantity AS qty_received,
    recv.DamagedQuantity AS qty_damaged,
    (recv.ReceivedQuantity - sent.OrderedQuantity) AS qty_variance,
    ROUND((CAST(recv.ReceivedQuantity AS DOUBLE) / sent.OrderedQuantity - 1) * 100, 2) AS variance_pct,
    sent.OrderValue AS expected_value,
    recv.TotalValue AS actual_value,
    (recv.TotalValue - sent.OrderValue) AS value_difference,
    recv.DeliveryDelay AS delay_days,
    CASE 
        WHEN recv.ReceivedQuantity < sent.OrderedQuantity THEN 'SHORT DELIVERY'
        WHEN recv.ReceivedQuantity > sent.OrderedQuantity THEN 'OVER DELIVERY'
        WHEN recv.DamagedQuantity > 0 THEN 'QUALITY ISSUE'
        WHEN recv.DeliveryDelay > 0 THEN 'LATE DELIVERY'
        ELSE 'PERFECT ORDER'
    END AS order_status
FROM fact_po_sent sent
JOIN fact_po_received recv ON sent.PurchaseOrderID = recv.PurchaseOrderID
JOIN dim_supplier s ON recv.SupplierKey = s.SupplierKey
JOIN dim_product p ON recv.ProductKey = p.ProductKey
WHERE recv.ReceivedQuantity != sent.OrderedQuantity 
   OR recv.DamagedQuantity > 0
   OR recv.DeliveryDelay != 0
ORDER BY ABS(value_difference) DESC;

-- ============================================================================
-- QUERY 6: Weekly Stock Movement Trends
-- ============================================================================

SELECT 
    d.Year,
    d.WeekOfYear,
    MIN(d.FullDate) AS week_start,
    MAX(d.FullDate) AS week_end,
    SUM(f.OpeningStock) AS week_opening_stock,
    SUM(f.StockReceived) AS week_received,
    SUM(f.StockSold) AS week_sold,
    SUM(f.StockAdjustment) AS week_adjustments,
    SUM(f.ClosingStock) AS week_closing_stock,
    SUM(f.StockValue) AS week_inventory_value,
    ROUND(SUM(f.StockSold) / AVG(f.ClosingStock), 2) AS week_turnover
FROM fact_stock_levels f
JOIN dim_date d ON f.DateKey = d.DateKey
GROUP BY d.Year, d.WeekOfYear
ORDER BY d.Year, d.WeekOfYear;

-- ============================================================================
-- QUERY 7: Supplier Comparison by Product Category
-- ============================================================================

SELECT 
    p.Category,
    s.SupplierName,
    COUNT(DISTINCT r.PurchaseOrderID) AS order_count,
    SUM(r.OrderedQuantity) AS total_ordered,
    SUM(r.ReceivedQuantity) AS total_received,
    SUM(r.DamagedQuantity) AS total_damaged,
    ROUND(AVG(CAST(r.ReceivedQuantity AS DOUBLE) / r.OrderedQuantity) * 100, 2) AS fill_rate,
    ROUND(SUM(r.DamagedQuantity) / SUM(r.ReceivedQuantity) * 100, 2) AS damage_rate,
    AVG(r.DeliveryDelay) AS avg_delay,
    SUM(r.TotalValue) AS total_spend
FROM fact_po_received r
JOIN dim_supplier s ON r.SupplierKey = s.SupplierKey
JOIN dim_product p ON r.ProductKey = p.ProductKey
GROUP BY p.Category, s.SupplierName
ORDER BY p.Category, total_spend DESC;

-- ============================================================================
-- QUERY 8: Location Capacity Utilization
-- ============================================================================

SELECT 
    l.LocationName,
    l.City,
    l.WarehouseSection,
    l.Capacity AS max_capacity,
    SUM(f.ClosingStock) AS current_stock,
    ROUND(SUM(f.ClosingStock) / l.Capacity * 100, 2) AS utilization_pct,
    (l.Capacity - SUM(f.ClosingStock)) AS available_capacity,
    CASE 
        WHEN SUM(f.ClosingStock) / l.Capacity > 0.9 THEN 'CRITICAL - OVER 90%'
        WHEN SUM(f.ClosingStock) / l.Capacity > 0.75 THEN 'HIGH - OVER 75%'
        WHEN SUM(f.ClosingStock) / l.Capacity > 0.5 THEN 'MODERATE'
        ELSE 'LOW UTILIZATION'
    END AS capacity_status
FROM fact_stock_levels f
JOIN dim_location l ON f.LocationKey = l.LocationKey
JOIN dim_date d ON f.DateKey = d.DateKey
WHERE d.FullDate = (SELECT MAX(FullDate) FROM dim_date)
GROUP BY l.LocationName, l.City, l.WarehouseSection, l.Capacity
ORDER BY utilization_pct DESC;

-- ============================================================================
-- QUERY 9: Product Lifecycle Analysis (SCD Type 2)
-- ============================================================================

SELECT 
    p.ProductID,
    p.ProductName,
    p.Brand,
    p.UnitPrice,
    p.EffectiveDate AS price_effective_from,
    p.ExpiryDate AS price_effective_to,
    CASE 
        WHEN p.IsCurrent = TRUE THEN 'CURRENT'
        ELSE 'HISTORICAL'
    END AS version_status,
    LAG(p.UnitPrice) OVER (PARTITION BY p.ProductID ORDER BY p.EffectiveDate) AS previous_price,
    ROUND((p.UnitPrice - LAG(p.UnitPrice) OVER (PARTITION BY p.ProductID ORDER BY p.EffectiveDate)) / 
          LAG(p.UnitPrice) OVER (PARTITION BY p.ProductID ORDER BY p.EffectiveDate) * 100, 2) AS price_change_pct
FROM dim_product p
ORDER BY p.ProductID, p.EffectiveDate;

-- ============================================================================
-- QUERY 10: ABC Analysis (Inventory Classification)
-- ============================================================================

WITH product_value AS (
    SELECT 
        p.ProductName,
        p.Brand,
        p.Category,
        SUM(f.ClosingStock * p.UnitPrice) AS total_inventory_value,
        SUM(f.StockSold * p.UnitPrice) AS total_sales_value
    FROM fact_stock_levels f
    JOIN dim_product p ON f.ProductKey = p.ProductKey
    WHERE p.IsCurrent = TRUE
    GROUP BY p.ProductName, p.Brand, p.Category
),
ranked_products AS (
    SELECT 
        *,
        SUM(total_inventory_value) OVER () AS grand_total_inv_value,
        SUM(total_sales_value) OVER () AS grand_total_sales_value,
        PERCENT_RANK() OVER (ORDER BY total_sales_value DESC) AS sales_percentile
    FROM product_value
)
SELECT 
    ProductName,
    Brand,
    Category,
    total_inventory_value,
    total_sales_value,
    ROUND(total_inventory_value / grand_total_inv_value * 100, 2) AS pct_of_inventory,
    ROUND(total_sales_value / grand_total_sales_value * 100, 2) AS pct_of_sales,
    CASE 
        WHEN sales_percentile <= 0.20 THEN 'A - HIGH VALUE (Top 20%)'
        WHEN sales_percentile <= 0.50 THEN 'B - MEDIUM VALUE (20-50%)'
        ELSE 'C - LOW VALUE (Bottom 50%)'
    END AS abc_classification
FROM ranked_products
ORDER BY total_sales_value DESC;

-- ============================================================================
-- End of Queries
-- ============================================================================
-- These queries provide comprehensive analytical capabilities for:
-- 1. Stock turnover monitoring
-- 2. Supplier performance evaluation
-- 3. Inventory health assessment
-- 4. Profitability analysis
-- 5. Order accuracy tracking
-- 6. Trend analysis
-- 7. Comparative analysis
-- 8. Capacity planning
-- 9. Price history tracking
-- 10. ABC inventory classification
-- ============================================================================
