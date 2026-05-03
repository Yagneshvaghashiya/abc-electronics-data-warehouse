-- ============================================================================
-- ABC Electronics - Stock Analysis with Apache Pig
-- ============================================================================
-- Purpose: Analyze stock levels and identify understock situations
-- Author: Yagnesh Vaghashiya (25002034)
-- Date: May 2026
-- ============================================================================

-- Load stock levels data from HDFS
stock_data = LOAD '/user/hive/warehouse/abc_dw/fact_stock_levels/Fact_Stock_Levels.csv' 
    USING PigStorage(',') 
    AS (
        stock_level_key:int,
        date_key:int,
        product_key:int,
        location_key:int,
        opening_stock:int,
        stock_received:int,
        stock_sold:int,
        stock_adjustment:int,
        closing_stock:int,
        minimum_stock_level:int,
        stock_value:double,
        is_understock:int,
        is_overstock:int
    );

-- Load product dimension
products = LOAD '/user/hive/warehouse/abc_dw/dim_product/Dim_Product.csv'
    USING PigStorage(',')
    AS (
        product_key:int,
        product_id:chararray,
        product_name:chararray,
        product_type:chararray,
        brand:chararray,
        category:chararray,
        unit_price:double,
        reorder_level:int,
        current_stock:int,
        effective_date:chararray,
        expiry_date:chararray,
        is_current:int
    );

-- ============================================================================
-- ANALYSIS 1: Identify Understock Situations
-- ============================================================================

-- Filter understock records
understock_records = FILTER stock_data BY is_understock == 1;

-- Join with product information
understock_with_product = JOIN understock_records BY product_key, 
                               products BY product_key;

-- Select relevant fields
understock_summary = FOREACH understock_with_product GENERATE
    understock_records::date_key AS date_key,
    products::product_name AS product_name,
    products::brand AS brand,
    understock_records::closing_stock AS closing_stock,
    understock_records::minimum_stock_level AS min_level,
    (understock_records::minimum_stock_level - understock_records::closing_stock) AS shortage;

-- Group by product
by_product = GROUP understock_summary BY (product_name, brand);

-- Calculate understock frequency
understock_frequency = FOREACH by_product GENERATE
    FLATTEN(group) AS (product_name, brand),
    COUNT(understock_summary) AS understock_days,
    AVG(understock_summary.shortage) AS avg_shortage;

-- Sort by frequency (descending)
sorted_understock = ORDER understock_frequency BY understock_days DESC;

-- Store results
STORE sorted_understock INTO '/user/output/understock_analysis'
    USING PigStorage(',');

-- Display top 10
top_understock = LIMIT sorted_understock 10;
DUMP top_understock;

-- ============================================================================
-- ANALYSIS 2: Stock Turnover by Brand
-- ============================================================================

-- Join stock data with products
stock_with_product = JOIN stock_data BY product_key, products BY product_key;

-- Calculate turnover metrics
turnover_data = FOREACH stock_with_product GENERATE
    products::brand AS brand,
    stock_data::stock_sold AS units_sold,
    stock_data::stock_value AS inventory_value;

-- Group by brand
by_brand = GROUP turnover_data BY brand;

-- Calculate brand-level metrics
brand_metrics = FOREACH by_brand GENERATE
    group AS brand,
    SUM(turnover_data.units_sold) AS total_units_sold,
    AVG(turnover_data.inventory_value) AS avg_inventory_value,
    (double)SUM(turnover_data.units_sold) / AVG(turnover_data.inventory_value) AS turnover_ratio;

-- Sort by turnover ratio
sorted_brands = ORDER brand_metrics BY turnover_ratio DESC;

-- Store results
STORE sorted_brands INTO '/user/output/brand_turnover'
    USING PigStorage(',');

-- ============================================================================
-- ANALYSIS 3: Daily Stock Movement Summary
-- ============================================================================

-- Group by date
by_date = GROUP stock_data BY date_key;

-- Calculate daily aggregates
daily_summary = FOREACH by_date GENERATE
    group AS date_key,
    SUM(stock_data.opening_stock) AS total_opening,
    SUM(stock_data.stock_received) AS total_received,
    SUM(stock_data.stock_sold) AS total_sold,
    SUM(stock_data.stock_adjustment) AS total_adjustments,
    SUM(stock_data.closing_stock) AS total_closing,
    SUM(stock_data.stock_value) AS total_value;

-- Sort by date
sorted_daily = ORDER daily_summary BY date_key;

-- Store results
STORE sorted_daily INTO '/user/output/daily_stock_summary'
    USING PigStorage(',');

-- ============================================================================
-- ANALYSIS 4: Overstock Items
-- ============================================================================

-- Filter overstock records
overstock_records = FILTER stock_data BY is_overstock == 1;

-- Join with products
overstock_with_product = JOIN overstock_records BY product_key,
                              products BY product_key;

-- Calculate overstock severity
overstock_analysis = FOREACH overstock_with_product GENERATE
    products::product_name AS product_name,
    products::brand AS brand,
    products::category AS category,
    overstock_records::closing_stock AS current_stock,
    products::reorder_level AS reorder_level,
    (overstock_records::closing_stock - products::reorder_level) AS excess_units,
    (overstock_records::stock_value) AS tied_capital;

-- Group by product
by_product_overstock = GROUP overstock_analysis BY (product_name, brand, category);

-- Aggregate overstock metrics
overstock_summary = FOREACH by_product_overstock GENERATE
    FLATTEN(group) AS (product_name, brand, category),
    COUNT(overstock_analysis) AS overstock_days,
    AVG(overstock_analysis.excess_units) AS avg_excess,
    SUM(overstock_analysis.tied_capital) AS total_tied_capital;

-- Sort by tied capital
sorted_overstock = ORDER overstock_summary BY total_tied_capital DESC;

-- Store results
STORE sorted_overstock INTO '/user/output/overstock_analysis'
    USING PigStorage(',');

-- Display top 10
top_overstock = LIMIT sorted_overstock 10;
DUMP top_overstock;

-- ============================================================================
-- ANALYSIS 5: Stock Health Score
-- ============================================================================

-- Calculate stock health for each record
stock_health = FOREACH stock_data GENERATE
    date_key,
    product_key,
    location_key,
    closing_stock,
    minimum_stock_level,
    (
        CASE 
            WHEN is_understock == 1 THEN 'CRITICAL'
            WHEN closing_stock < (minimum_stock_level * 1.5) THEN 'LOW'
            WHEN is_overstock == 1 THEN 'EXCESS'
            WHEN closing_stock > (minimum_stock_level * 3) THEN 'HIGH'
            ELSE 'NORMAL'
        END
    ) AS stock_status;

-- Group by status
by_status = GROUP stock_health BY stock_status;

-- Count by status
status_summary = FOREACH by_status GENERATE
    group AS status,
    COUNT(stock_health) AS record_count;

-- Sort by count
sorted_status = ORDER status_summary BY record_count DESC;

-- Display summary
DUMP sorted_status;

-- Store results
STORE sorted_status INTO '/user/output/stock_health_summary'
    USING PigStorage(',');

-- ============================================================================
-- End of Script
-- ============================================================================
-- Output files created:
-- 1. /user/output/understock_analysis - Products with frequent understocking
-- 2. /user/output/brand_turnover - Stock turnover by brand
-- 3. /user/output/daily_stock_summary - Daily aggregated stock movements
-- 4. /user/output/overstock_analysis - Products with excess inventory
-- 5. /user/output/stock_health_summary - Overall stock health distribution
-- ============================================================================
