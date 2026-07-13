--tạo view fact_orders để lưu trữ thông tin về các đơn hàng đã được giao, bao gồm thông tin về khách hàng, người bán, ngày đặt hàng, số ngày trễ, tổng giá trị đơn hàng và điểm đánh giá.
--Mỗi dòng trong fact_orders đại diện cho một đơn hàng đã được giao
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

---kiểm tra số lượng dòng trong fact_orders và số lượng đơn hàng duy nhất
SELECT COUNT(*) AS n_rows, COUNT(DISTINCT order_id) AS n_orders
FROM fact_orders;



--kiểm tra số lượng khách hàng không có trong bảng customers
SELECT COUNT(*) AS orphan_customers
FROM fact_orders f
LEFT JOIN customers c ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


---kiểm tra số lượng người bán không có trong bảng sellers
SELECT COUNT(*) AS orphan_sellers
FROM fact_orders f
LEFT JOIN sellers s ON f.seller_id = s.seller_id
WHERE s.seller_id IS NULL;











