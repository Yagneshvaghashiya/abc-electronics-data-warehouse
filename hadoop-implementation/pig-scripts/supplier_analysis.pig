-- ============================================================================
-- ABC Electronics - Supplier Performance Analysis with Apache Pig
-- ============================================================================
-- Purpose: Analyze supplier performance, delivery accuracy, and quality
-- Author: Yagnesh Vaghashiya (25002034)
-- Date: May 2026
-- ============================================================================

-- Load purchase order received data
po_received = LOAD '/user/hive/warehouse/abc_dw/fact_po_received/Fact_PO_Received.csv'
    USING PigStorage(',')
    AS (
        po_received_key:int,
        date_key:int,
        product_key:int,
        supplier_key:int,
        location_key:int,
        purchase_order_id:chararray,
        ordered_quantity:int,
        received_quantity:int,
        damaged_quantity:int,
        unit_price:double,
        total_value:double,
        delivery_delay:int
    );

-- Load supplier dimension
suppliers = LOAD '/user/hive/warehouse/abc_dw/dim_supplier/Dim_Supplier.csv'
    USING PigStorage(',')
    AS (
        supplier_key:int,
        supplier_id:chararray,
        supplier_name:chararray,
        contact_person:chararray,
        phone_number:chararray,
        email:chararray,
        address:chararray,
        city:chararray,
        country:chararray,
        effective_date:chararray,
        expiry_date:chararray,
        is_current:int
    );

-- ============================================================================
-- ANALYSIS 1: Supplier Delivery Performance
-- ============================================================================

-- Join with supplier information
po_with_supplier = JOIN po_received BY supplier_key, suppliers BY supplier_key;

-- Calculate delivery metrics
delivery_metrics = FOREACH po_with_supplier GENERATE
    suppliers::supplier_name AS supplier_name,
    suppliers::country AS country,
    po_received::ordered_quantity AS ordered_qty,
    po_received::received_quantity AS received_qty,
    po_received::damaged_quantity AS damaged_qty,
    po_received::delivery_delay AS delay_days,
    po_received::total_value AS order_value,
    (po_received::delivery_delay <= 0 ? 1 : 0) AS on_time_flag,
    ((double)po_received::received_quantity / po_received::ordered_quantity) AS fill_rate,
    ((double)po_received::damaged_quantity / po_received::received_quantity) AS damage_rate;

-- Group by supplier
by_supplier = GROUP delivery_metrics BY (supplier_name, country);

-- Calculate supplier-level KPIs
supplier_performance = FOREACH by_supplier GENERATE
    FLATTEN(group) AS (supplier_name, country),
    COUNT(delivery_metrics) AS total_orders,
    SUM(delivery_metrics.order_value) AS total_revenue,
    AVG(delivery_metrics.fill_rate) * 100 AS avg_fill_rate_pct,
    AVG(delivery_metrics.damage_rate) * 100 AS avg_damage_rate_pct,
    (double)SUM(delivery_metrics.on_time_flag) / COUNT(delivery_metrics) * 100 AS on_time_delivery_pct,
    AVG(delivery_metrics.delay_days) AS avg_delay_days;

-- Sort by on-time delivery (best performers first)
sorted_suppliers = ORDER supplier_performance BY on_time_delivery_pct DESC;

-- Store results
STORE sorted_suppliers INTO '/user/output/supplier_performance'
    USING PigStorage(',');

-- Display top 10 suppliers
top_suppliers = LIMIT sorted_suppliers 10;
DUMP top_suppliers;

-- ============================================================================
-- ANALYSIS 2: Quality Issues by Supplier
-- ============================================================================

-- Filter orders with damaged goods
damaged_orders = FILTER po_received BY damaged_quantity > 0;

-- Join with suppliers
damaged_with_supplier = JOIN damaged_orders BY supplier_key, suppliers BY supplier_key;

-- Calculate damage metrics
damage_analysis = FOREACH damaged_with_supplier GENERATE
    suppliers::supplier_name AS supplier_name,
    damaged_orders::purchase_order_id AS po_id,
    damaged_orders::ordered_quantity AS ordered,
    damaged_orders::damaged_quantity AS damaged,
    ((double)damaged_orders::damaged_quantity / damaged_orders::ordered_quantity * 100) AS damage_pct,
    (damaged_orders::damaged_quantity * damaged_orders::unit_price) AS financial_loss;

-- Group by supplier
by_supplier_damage = GROUP damage_analysis BY supplier_name;

-- Aggregate damage statistics
damage_summary = FOREACH by_supplier_damage GENERATE
    group AS supplier_name,
    COUNT(damage_analysis) AS damaged_order_count,
    SUM(damage_analysis.damaged) AS total_damaged_units,
    AVG(damage_analysis.damage_pct) AS avg_damage_pct,
    SUM(damage_analysis.financial_loss) AS total_financial_loss;

-- Sort by financial loss (worst first)
sorted_damage = ORDER damage_summary BY total_financial_loss DESC;

-- Store results
STORE sorted_damage INTO '/user/output/supplier_quality_issues'
    USING PigStorage(',');

-- ============================================================================
-- ANALYSIS 3: Late Deliveries Analysis
-- ============================================================================

-- Filter late deliveries
late_deliveries = FILTER po_received BY delivery_delay > 0;

-- Join with supplier info
late_with_supplier = JOIN late_deliveries BY supplier_key, suppliers BY supplier_key;

-- Extract delay information
late_analysis = FOREACH late_with_supplier GENERATE
    suppliers::supplier_name AS supplier_name,
    late_deliveries::purchase_order_id AS po_id,
    late_deliveries::delivery_delay AS days_late,
    late_deliveries::total_value AS order_value;

-- Group by supplier
by_supplier_late = GROUP late_analysis BY supplier_name;

-- Calculate late delivery metrics
late_summary = FOREACH by_supplier_late GENERATE
    group AS supplier_name,
    COUNT(late_analysis) AS late_order_count,
    AVG(late_analysis.days_late) AS avg_days_late,
    MAX(late_analysis.days_late) AS max_days_late,
    SUM(late_analysis.order_value) AS value_of_late_orders;

-- Sort by late order count
sorted_late = ORDER late_summary BY late_order_count DESC;

-- Store results
STORE sorted_late INTO '/user/output/late_deliveries_by_supplier'
    USING PigStorage(',');

-- ============================================================================
-- ANALYSIS 4: Supplier Reliability Score
-- ============================================================================

-- Calculate comprehensive reliability score
reliability_data = FOREACH po_with_supplier GENERATE
    suppliers::supplier_name AS supplier_name,
    -- On-time delivery (40% weight)
    (po_received::delivery_delay <= 0 ? 40 : 0) AS on_time_score,
    -- Fill rate (30% weight)
    ((double)po_received::received_quantity / po_received::ordered_quantity * 30) AS fill_rate_score,
    -- Quality (30% weight)
    ((double)(po_received::received_quantity - po_received::damaged_quantity) / po_received::received_quantity * 30) AS quality_score;

-- Group by supplier
by_supplier_reliability = GROUP reliability_data BY supplier_name;

-- Calculate overall reliability score
supplier_reliability = FOREACH by_supplier_reliability GENERATE
    group AS supplier_name,
    AVG(reliability_data.on_time_score) + 
    AVG(reliability_data.fill_rate_score) + 
    AVG(reliability_data.quality_score) AS reliability_score,
    (
        CASE
            WHEN (AVG(reliability_data.on_time_score) + AVG(reliability_data.fill_rate_score) + AVG(reliability_data.quality_score)) >= 90 THEN 'EXCELLENT'
            WHEN (AVG(reliability_data.on_time_score) + AVG(reliability_data.fill_rate_score) + AVG(reliability_data.quality_score)) >= 75 THEN 'GOOD'
            WHEN (AVG(reliability_data.on_time_score) + AVG(reliability_data.fill_rate_score) + AVG(reliability_data.quality_score)) >= 60 THEN 'FAIR'
            ELSE 'POOR'
        END
    ) AS reliability_grade;

-- Sort by score
sorted_reliability = ORDER supplier_reliability BY reliability_score DESC;

-- Store results
STORE sorted_reliability INTO '/user/output/supplier_reliability_scores'
    USING PigStorage(',');

-- Display all reliability scores
DUMP sorted_reliability;

-- ============================================================================
-- ANALYSIS 5: Country-wise Supplier Analysis
-- ============================================================================

-- Join data
po_supplier_country = JOIN po_received BY supplier_key, suppliers BY supplier_key;

-- Group by country
by_country = GROUP po_supplier_country BY suppliers::country;

-- Calculate country-level metrics
country_metrics = FOREACH by_country GENERATE
    group AS country,
    COUNT(po_supplier_country) AS total_orders,
    SUM(po_supplier_country::po_received::total_value) AS total_value,
    AVG(po_supplier_country::po_received::delivery_delay) AS avg_delivery_delay,
    (double)SUM(po_supplier_country::po_received::damaged_quantity) / 
     SUM(po_supplier_country::po_received::received_quantity) * 100 AS damage_rate_pct;

-- Sort by total value
sorted_countries = ORDER country_metrics BY total_value DESC;

-- Store results
STORE sorted_countries INTO '/user/output/supplier_country_analysis'
    USING PigStorage(',');

-- Display country summary
DUMP sorted_countries;

-- ============================================================================
-- End of Script
-- ============================================================================
-- Output files created:
-- 1. /user/output/supplier_performance - Overall supplier KPIs
-- 2. /user/output/supplier_quality_issues - Quality problems by supplier
-- 3. /user/output/late_deliveries_by_supplier - Late delivery analysis
-- 4. /user/output/supplier_reliability_scores - Reliability scoring
-- 5. /user/output/supplier_country_analysis - Country-wise metrics
-- ============================================================================
