CREATE VIEW fact_orders AS
WITH
orders_price AS (SELECT order_id,SUM(price +freight_value) AS total_value
FROM order_items
GROUP BY order_id),
main_seller AS (
SELECT order_id,seller_id
FROM(SELECT order_id,seller_id,ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY price DESC) AS rn FROM order_items) AS t
WHERE rn = 1)
SELECT o.order_id,o.customer_id,ms.seller_id,CAST(o.order_purchase_timestamp AS DATE) AS order_date,
DATEDIFF(DAY,o.order_estimated_delivery_date,order_delivered_customer_date) AS delay_days,
CASE WHEN o.order_estimated_delivery_date<o.order_delivered_customer_date THEN 1 ELSE 0 END AS is_late,
DATEDIFF(DAY,o.order_approved_at,o.order_delivered_carrier_date) AS seller_processing_days,
DATEDIFF(DAY,o.order_delivered_carrier_date,o.order_delivered_customer_date)AS shipping_days,
DATEDIFF(DAY,o.order_purchase_timestamp,o.order_estimated_delivery_date) AS promised_days,
op.total_value,
r.review_score

FROM orders o
JOIN orders_price op ON  o.order_id=op.order_id
JOIN main_seller ms ON o.order_id =ms.order_id
LEFT JOIN order_reviews r ON o.order_id=r.order_id
WHERE o.order_status = 'delivered';


SELECT COUNT(*) AS n_rows, COUNT(DISTINCT order_id) AS n_orders
FROM fact_orders;

SELECT COUNT(*) AS orphan_customers
FROM fact_orders f
LEFT JOIN customers c ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS orphan_sellers
FROM fact_orders f
LEFT JOIN sellers s ON f.seller_id = s.seller_id
WHERE s.seller_id IS NULL;




SELECT
    CASE
        WHEN delay_days <= 0             THEN '0. Dung/som han'
        WHEN delay_days BETWEEN 1 AND 3  THEN '1. Tre 1-3'
        WHEN delay_days BETWEEN 4 AND 7  THEN '2. Tre 4-7'
        WHEN delay_days BETWEEN 8 AND 15 THEN '3. Tre 8-15'
        ELSE '4. Tre >15'
    END AS delay_bucket,
    COUNT(*)                          AS n_orders,
    AVG(CAST(review_score AS FLOAT))  AS avg_score,
    CAST(SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) AS FLOAT)
        / COUNT(*)                    AS pct_low_score
FROM fact_orders
WHERE review_score IS NOT NULL
GROUP BY
    CASE
        WHEN delay_days <= 0             THEN '0. Dung/som han'
        WHEN delay_days BETWEEN 1 AND 3  THEN '1. Tre 1-3'
        WHEN delay_days BETWEEN 4 AND 7  THEN '2. Tre 4-7'
        WHEN delay_days BETWEEN 8 AND 15 THEN '3. Tre 8-15'
        ELSE '4. Tre >15'
    END;



	SELECT
    is_late,
    COUNT(*)                           AS n_orders,
    AVG(CAST(seller_processing_days AS FLOAT))   AS avg_seller_phase,
    AVG(CAST(shipping_days AS FLOAT))  AS avg_carrier_phase
FROM fact_orders
GROUP BY is_late;




WITH route_stats AS (
    SELECT
        s.seller_state + '->' + c.customer_state AS route,
        COUNT(*)                                 AS n_orders,
        SUM(f.is_late)                           AS late_orders,   -- so don tre tuyet doi
        CAST(SUM(f.is_late) AS FLOAT)/COUNT(*)   AS late_rate,     -- ty le tre
        AVG(CAST(f.delay_days AS FLOAT))         AS avg_delay
    FROM fact_orders f
    JOIN sellers   s ON f.seller_id   = s.seller_id
    JOIN customers c ON f.customer_id = c.customer_id
    GROUP BY s.seller_state + '->' + c.customer_state
)
SELECT
    route,
    n_orders,
    late_orders,
    late_rate,
    avg_delay,
    RANK() OVER (ORDER BY late_rate   DESC) AS rank_by_rate,    -- hang theo ty le
    RANK() OVER (ORDER BY late_orders DESC) AS rank_by_volume   -- hang theo so don tre
FROM route_stats
WHERE n_orders >= 30          -- loc tuyen hiem tranh sai lech thong ke
ORDER BY late_orders DESC;    -- mac dinh xep theo SO DON TRE (goc hanh dong duoc)
















SELECT
    s.seller_state + '->' + c.customer_state AS route,
    COUNT(*)                                          AS n_orders,
    AVG(CAST(f.promised_days AS FLOAT))               AS avg_promised,
    AVG(CAST(f.delay_days AS FLOAT))                  AS avg_delay,
    AVG(CAST(-f.delay_days AS FLOAT))                 AS avg_buffer   -- ngay giao som hon hua
FROM fact_orders f
JOIN sellers   s ON f.seller_id   = s.seller_id
JOIN customers c ON f.customer_id = c.customer_id
GROUP BY s.seller_state + '->' + c.customer_state
HAVING COUNT(*) >= 30
ORDER BY avg_buffer DESC;     -- tuyen hua THUA nhieu nhat len dau\



SELECT
    s.seller_state + '->' + c.customer_state AS route,
    COUNT(*)                          AS n_bad_orders,
    SUM(f.total_value)                AS revenue_at_risk,
    AVG(CAST(f.review_score AS FLOAT)) AS avg_score
FROM fact_orders f
JOIN sellers   s ON f.seller_id   = s.seller_id
JOIN customers c ON f.customer_id = c.customer_id
WHERE f.is_late = 1 AND f.review_score <= 2
GROUP BY s.seller_state + '->' + c.customer_state
ORDER BY revenue_at_risk DESC;


