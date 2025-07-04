--Creating four dimension and two fact tables
CREATE TABLE dim_customers (
customer_id INT PRIMARY KEY,
customer_name varchar(700),
city varchar(700)
);

CREATE TABLE dim_date (
date DATE PRIMARY KEY,
mmyy DATE,
week_no TEXT
);

CREATE TABLE dim_products (
product_name VARCHAR(700),
product_id INT PRIMARY KEY,
category TEXT
);

CREATE TABLE dim_targets_orders 
(
customer_id INT PRIMARY KEY,
ontime_target_percent INT,
infull_target_percent INT,
otif_target_percent INT
);

CREATE TABLE fact_order_lines (
    order_id VARCHAR,
    order_placement_date_original VARCHAR,
    customer_id INT,
    product_id INT,
    order_qty INT,
    agreed_delivery_date_original VARCHAR,
    actual_delivery_date_original VARCHAR,
    delivery_qty INT,
    in_full INT, 
    on_time INT,
    on_time_in_full INT
);

CREATE TABLE fact_orders_aggregate (
order_id VARCHAR PRIMARY KEY,
customer_id INT,
order_placement_date DATE,
on_time INT,
in_full INT,
otif INT
);

--Alter fact_order_lines to add parsed date columns
ALTER TABLE fact_order_lines
ADD COLUMN order_placement_date DATE;

ALTER TABLE fact_order_lines
ADD COLUMN agreed_delivery_date DATE;

ALTER TABLE fact_order_lines
ADD COLUMN actual_delivery_date DATE;

--Update the parsed date columns to 'date' data type
UPDATE fact_order_lines
SET order_placement_date = TO_DATE(order_placement_date_original, 'FMDay, FMMonth DD, YYYY');

UPDATE fact_order_lines
SET agreed_delivery_date = TO_DATE(agreed_delivery_date_original, 'FMDay, FMMonth DD, YYYY');

UPDATE fact_order_lines
SET actual_delivery_date = TO_DATE(actual_delivery_date_original, 'FMDay, FMMonth DD, YYYY');

--Final visual metrics
--View for kpi_summary_by_month
CREATE OR REPLACE VIEW kpi_summary_by_month AS
SELECT
    -- Use order_placement_date for OT/IF/OTIF KPIs
    DATE_TRUNC('month', f.order_placement_date)::DATE AS order_month,  

    -- OTIF-related metrics (based on when the order was placed)
    ROUND(SUM(f.on_time)::DECIMAL / NULLIF(COUNT(f.order_id), 0), 4) AS on_time_percent,
    ROUND(SUM(f.in_full)::DECIMAL / NULLIF(COUNT(f.order_id), 0), 4) AS in_full_percent,
    ROUND(SUM(f.otif)::DECIMAL / NULLIF(COUNT(f.order_id), 0), 4) AS otif_percent,

    -- Use actual_delivery_date for fill rate metrics
    ROUND(SUM(CASE WHEN l.actual_delivery_date IS NOT NULL 
                THEN l.delivery_qty 
                ELSE 0 
              END)::DECIMAL 
          / NULLIF(SUM(CASE 
                         WHEN l.actual_delivery_date IS NOT NULL 
                         THEN l.order_qty 
                         ELSE 0 
                       END), 0), 4) AS vofr_percent,

    ROUND(SUM(CASE 
                WHEN l.actual_delivery_date IS NOT NULL 
                     AND l.delivery_qty = l.order_qty 
                THEN 1 
                ELSE 0 
              END)::DECIMAL 
          / NULLIF(COUNT(CASE 
                           WHEN l.actual_delivery_date IS NOT NULL 
                           THEN 1 
                         END), 0), 4) AS lifr_percent,

    -- Target values as decimals
    ROUND(AVG(t.ontime_target_percent) / 100.0, 4) AS avg_ontime_target,
    ROUND(AVG(t.infull_target_percent) / 100.0, 4) AS avg_infull_target,
    ROUND(AVG(t.otif_target_percent) / 100.0, 4) AS avg_otif_target

FROM fact_orders_aggregate f
JOIN fact_order_lines l ON f.order_id = l.order_id
JOIN dim_targets_orders t ON f.customer_id = t.customer_id
WHERE f.order_placement_date IS NOT NULL
GROUP BY DATE_TRUNC('month', f.order_placement_date)
ORDER BY order_month;


--View for customer_summary_metrics
CREATE OR REPLACE VIEW customer_summary_metrics AS
SELECT
    c.customer_id,
    c.customer_name,

    -- Metrics in decimal format (4 decimal places)
    ROUND(SUM(foa.on_time)::DECIMAL / NULLIF(COUNT(foa.order_id), 0), 4) AS on_time_ratio,
    ROUND(SUM(foa.in_full)::DECIMAL / NULLIF(COUNT(foa.order_id), 0), 4) AS in_full_ratio,
    ROUND(SUM(foa.otif)::DECIMAL / NULLIF(COUNT(foa.order_id), 0), 4) AS otif_ratio,

    ROUND(SUM(fol.delivery_qty)::DECIMAL / NULLIF(SUM(fol.order_qty), 0), 4) AS vofr_ratio,
    ROUND(SUM(CASE WHEN fol.delivery_qty = fol.order_qty THEN 1 ELSE 0 END)::DECIMAL / NULLIF(COUNT(*), 0), 4) AS lifr_ratio,

    -- Target values converted from % to decimals
    ROUND(t.ontime_target_percent / 100.0, 4) AS on_time_target_ratio,
    ROUND(t.infull_target_percent / 100.0, 4) AS in_full_target_ratio,
    ROUND(t.otif_target_percent / 100.0, 4) AS otif_target_ratio

FROM fact_orders_aggregate foa
JOIN dim_customers c ON foa.customer_id = c.customer_id
JOIN fact_order_lines fol ON foa.order_id = fol.order_id
LEFT JOIN dim_targets_orders t ON c.customer_id = t.customer_id

WHERE foa.order_placement_date IS NOT NULL

GROUP BY 
    c.customer_id, 
    c.customer_name,
    t.ontime_target_percent, 
    t.infull_target_percent, 
    t.otif_target_percent

ORDER BY c.customer_id;

--View for product_metrics_by_date
CREATE OR REPLACE VIEW product_metrics_by_date AS
SELECT
    p.product_id,
    d.product_name,

    -- Properly cast date (no time zone) for sorting in Power BI
    DATE_TRUNC('month', p.actual_delivery_date)::DATE AS delivery_month_date,

    -- Display-friendly month label for sparkline axis
    TO_CHAR(p.actual_delivery_date, 'Mon-YYYY') AS delivery_month,

    -- Volume Fill Rate
    ROUND(
        SUM(p.delivery_qty)::DECIMAL 
        / NULLIF(SUM(p.order_qty), 0), 
        4
    ) AS volume_fill_rate,

    -- Line Fill Rate
    ROUND(
        SUM(CASE WHEN p.delivery_qty = p.order_qty THEN 1 ELSE 0 END)::DECIMAL
        / NULLIF(COUNT(*), 0), 
        4
    ) AS line_fill_rate

FROM fact_order_lines p
JOIN dim_products d ON p.product_id = d.product_id
WHERE p.actual_delivery_date IS NOT NULL
GROUP BY 
    p.product_id, 
    d.product_name,
    DATE_TRUNC('month', p.actual_delivery_date),
    TO_CHAR(p.actual_delivery_date, 'Mon-YYYY');

--View for metric performance by month
CREATE OR REPLACE VIEW metric_performance_by_month AS
SELECT
    DATE_TRUNC('month', f.order_placement_date)::DATE AS month_date,
    'On Time %' AS metric_name,
    ROUND(SUM(f.on_time)::DECIMAL / COUNT(f.order_id) * 100, 2) AS metric_value,
    ROUND(AVG(t.ontime_target_percent), 2) AS target_value

FROM fact_orders_aggregate f
JOIN dim_targets_orders t ON f.customer_id = t.customer_id
WHERE f.order_placement_date IS NOT NULL
GROUP BY DATE_TRUNC('month', f.order_placement_date)

UNION ALL

SELECT
    DATE_TRUNC('month', f.order_placement_date)::DATE AS month_date,
    'In Full %' AS metric_name,
    ROUND(SUM(f.in_full)::DECIMAL / COUNT(f.order_id) * 100, 2),
    ROUND(AVG(t.infull_target_percent), 2)
FROM fact_orders_aggregate f
JOIN dim_targets_orders t ON f.customer_id = t.customer_id
WHERE f.order_placement_date IS NOT NULL
GROUP BY DATE_TRUNC('month', f.order_placement_date)

UNION ALL

SELECT
    DATE_TRUNC('month', f.order_placement_date)::DATE AS month_date,
    'OTIF %' AS metric_name,
    ROUND(SUM(f.otif)::DECIMAL / COUNT(f.order_id) * 100, 2),
    ROUND(AVG(t.otif_target_percent), 2)
FROM fact_orders_aggregate f
JOIN dim_targets_orders t ON f.customer_id = t.customer_id
WHERE f.order_placement_date IS NOT NULL
GROUP BY DATE_TRUNC('month', f.order_placement_date)

UNION ALL

SELECT
    DATE_TRUNC('month', l.actual_delivery_date)::DATE AS month_date,
    'Volume Fill Rate %' AS metric_name,
    ROUND(SUM(l.delivery_qty)::DECIMAL / NULLIF(SUM(l.order_qty), 0) * 100, 2),
    NULL  -- No target defined
FROM fact_order_lines l
WHERE l.actual_delivery_date IS NOT NULL
GROUP BY DATE_TRUNC('month', l.actual_delivery_date)

UNION ALL

SELECT
    DATE_TRUNC('month', l.actual_delivery_date)::DATE AS month_date,
    'Line Fill Rate %' AS metric_name,
    ROUND(
        SUM(CASE WHEN l.delivery_qty = l.order_qty THEN 1 ELSE 0 END)::DECIMAL
        / COUNT(*) * 100, 2
    ),
    NULL  -- No target defined
FROM fact_order_lines l
WHERE l.actual_delivery_date IS NOT NULL
GROUP BY DATE_TRUNC('month', l.actual_delivery_date);

--View for City-level metrics
CREATE OR REPLACE VIEW city_level_performance AS
SELECT
    c.city,
    
    -- Actual performance metrics (as decimals)
    ROUND(SUM(f.on_time)::DECIMAL / NULLIF(COUNT(f.order_id), 0), 4) AS ot_percent,
    ROUND(SUM(f.in_full)::DECIMAL / NULLIF(COUNT(f.order_id), 0), 4) AS if_percent,
    ROUND(SUM(f.otif)::DECIMAL / NULLIF(COUNT(f.order_id), 0), 4) AS otif_percent,
    
    -- Average target metrics (converted from % to decimals)
    ROUND(AVG(t.ontime_target_percent) / 100.0, 4) AS ot_target,
    ROUND(AVG(t.infull_target_percent) / 100.0, 4) AS if_target,
    ROUND(AVG(t.otif_target_percent) / 100.0, 4) AS otif_target

FROM fact_orders_aggregate f
JOIN dim_customers c ON f.customer_id = c.customer_id
JOIN dim_targets_orders t ON f.customer_id = t.customer_id

WHERE f.order_placement_date IS NOT NULL

GROUP BY c.city
ORDER BY c.city;


--View for product_order_delay_summary
CREATE OR REPLACE VIEW product_order_delay_summary AS
SELECT
    p.product_name,
    CASE
        WHEN l.actual_delivery_date <= l.order_placement_date THEN 'On Time'
        WHEN l.actual_delivery_date <= l.order_placement_date + INTERVAL '2 days' THEN '0-2 Days Late'
        WHEN l.actual_delivery_date <= l.order_placement_date + INTERVAL '5 days' THEN '3-5 Days Late'
        ELSE '>5 Days Late'
    END AS delay_period,
    SUM(l.order_qty) AS total_order_qty
FROM fact_order_lines l
JOIN dim_products p ON l.product_id = p.product_id
WHERE l.order_placement_date IS NOT NULL
  AND l.actual_delivery_date IS NOT NULL
GROUP BY p.product_name, delay_period
ORDER BY p.product_name;


	