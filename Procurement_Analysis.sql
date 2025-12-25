-- Supplier Delivery Performance (On-Time vs Delayed)
-- Which suppliers consistently fail delivery timelines?
WITH delivery_metrics AS (
    SELECT
        Supplier,
        COUNT(*) AS total_orders,
        SUM(
            CASE 
                WHEN Delivery_Date <= DATE_ADD(Order_Date, INTERVAL 7 DAY)
                THEN 1 
                ELSE 0 
            END
        ) AS on_time_orders
    FROM `procurement kpi analysis dataset`
    WHERE Order_Status = 'Delivered'
    GROUP BY Supplier
)
SELECT
    Supplier,
    total_orders,
    on_time_orders,
    ROUND((on_time_orders * 100.0) / total_orders, 2) AS on_time_percentage
FROM delivery_metrics
ORDER BY on_time_percentage DESC;


--  Average Delivery Delay by Supplier
-- Who causes operational bottlenecks due to late deliveries?
SELECT
    Supplier,
    ROUND(AVG(EXTRACT(DAY FROM (Delivery_Date - Order_Date))), 2) AS avg_delay_days
FROM `procurement kpi analysis dataset`
WHERE Delivery_Date > Order_Date
GROUP BY Supplier
ORDER BY avg_delay_days DESC;

-- Defect Rate Analysis per Supplier
-- Which suppliers are hurting quality KPIs?
SELECT
    Supplier,
    SUM(Defective_Units) AS total_defects,
    SUM(Quantity) AS total_quantity,
    ROUND(SUM(Defective_Units) * 100.0 / NULLIF(SUM(Quantity), 0), 2) AS defect_rate_percentage
FROM `procurement kpi analysis dataset`
GROUP BY Supplier
ORDER BY defect_rate_percentage DESC;

-- Supplier Cost Savings via Negotiation
-- Which suppliers deliver the highest negotiated savings?
SELECT
    Supplier,
    ROUND(SUM((Unit_Price - Negotiated_Price) * Quantity), 2) AS total_cost_savings
FROM `procurement kpi analysis dataset`
GROUP BY Supplier
ORDER BY total_cost_savings DESC;

-- Monthly Procurement Spend Trend
-- How is procurement spending evolving over time?

SELECT
    DATE_FORMAT(Order_Date, '%Y-%m') AS month,
    ROUND(SUM(Negotiated_Price * Quantity), 2) AS total_spend
FROM `procurement kpi analysis dataset`
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY month;



-- Top 3 Suppliers per Item Category (Spend-Based)
-- Who dominates supply in each category?
WITH supplier_spend AS (
    SELECT
        Item_Category,
        Supplier,
        SUM(Negotiated_Price * Quantity) AS category_spend
    FROM `procurement kpi analysis dataset`
    GROUP BY Item_Category, Supplier
)
SELECT *
FROM (
    SELECT
        *,
        RANK() OVER (PARTITION BY Item_Category ORDER BY category_spend DESC) AS rank_in_category
    FROM supplier_spend
) ranked
WHERE rank_in_category <= 3;


-- Compliance Risk Assessment
-- Which suppliers pose regulatory or contract risks?
SELECT
    Supplier,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN Compliance = 'No' THEN 1 ELSE 0 END) AS non_compliant_orders,
    ROUND(SUM(CASE WHEN Compliance = 'No' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS non_compliance_rate
FROM `procurement kpi analysis dataset`
GROUP BY Supplier
ORDER BY non_compliance_rate DESC;

-- High-Impact Defective Orders (Pareto Logic)
-- Which orders cause the most quality damage?

SELECT
    PO_ID,
    Supplier,
    Defective_Units,
    Quantity,
    ROUND(Defective_Units * 100.0 / Quantity, 2) AS defect_percentage
FROM `procurement kpi analysis dataset`
WHERE Defective_Units > 0
ORDER BY defect_percentage DESC;

-- Supplier Performance Scorecard
-- Single KPI view combining quality, delivery, and cost.

SELECT
    Supplier,
    ROUND(AVG(EXTRACT(DAY FROM (Delivery_Date - Order_Date))),2) AS avg_delivery_days,
    ROUND(SUM(Defective_Units) * 100.0 / SUM(Quantity),2) AS defect_rate,
    ROUND(SUM((Unit_Price - Negotiated_Price) * Quantity),2) AS cost_savings
FROM `procurement kpi analysis dataset`
WHERE Order_Status = 'Delivered'
GROUP BY Supplier;


-- Repeat Supplier Dependency Analysis
-- Are we over-dependent on certain suppliers?
SELECT
    Supplier,
    COUNT(DISTINCT PO_ID) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS order_share_percentage
FROM `procurement kpi analysis dataset`
GROUP BY Supplier
ORDER BY order_share_percentage DESC;
