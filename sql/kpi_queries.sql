-- Mục đích: Tính các KPI chính của dự án
USE olist_ecommerce;


-- tính tỉ lệ giao hàng trễ (Late delivery rate)
WITH
delivery_orders AS(
	SELECT 
	order_id,order_delivered_customer_date,order_estimated_delivery_date
	FROM orders
	WHERE order_status='delivered'
		AND order_delivered_customer_date is not NULL 
		AND order_estimated_delivery_date is not NULL
		)
SELECT COUNT(*) AS total_delivered,
	SUM(CASE WHEN order_delivered_customer_date>order_estimated_delivery_date THEN 1 ELSE 0 END) AS total_late,
	SUM(CASE WHEN order_delivered_customer_date>order_estimated_delivery_date THEN 1 ELSE 0 END)*1.0/COUNT(*) AS Late_delivery_rate
	FROM delivery_orders;

-- Tính số ngày giao trung bình từ ngày đặt hàng đến ngày khách nhận, chỉ tính delivered orders
WITH
deliveried_orders AS
(SELECT order_id,order_delivered_customer_date,order_purchase_timestamp 
	FROM orders 
	WHERE order_status = 'delivered'
		AND order_delivered_customer_date is not NULL
        AND order_purchase_timestamp is not NULL)
SELECT AVG(DATEDIFF(DAY,order_purchase_timestamp,order_delivered_customer_date)) AS average_delivery_date
FROM deliveried_orders

-- hoặc 
SELECT AVG(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)) AS average_delivery_days
FROM orders
WHERE order_status = 'delivered' AND order_delivered_customer_date is not NULL;


--Tính điểm đánh giá trung bình
SELECT AVG(review_score) AS Average_rv_score
FROM order_reviews
WHERE review_score is not NULL


-- Tính tổng doanh thu của tất cả các items
SELECT SUM(price) AS item_revenue
FROM order_items;



-- Tính tỉ lệ khách hàng mua lại
WITH
purchase_count AS (
		SELECT customer_unique_id,COUNT(*) AS total_purchases
		FROM customers
		GROUP BY customer_unique_id),
repeat_customers AS(
		SELECT COUNT(*) AS repeat_count
		FROM purchase_count
		WHERE total_purchases >1),
total_customers AS (
		SELECT COUNT(*) AS total_count FROM purchase_count)

SELECT repeat_count*1.0/total_count AS repeat_customer_rate
FROM repeat_customers CROSS JOIN total_customers;
