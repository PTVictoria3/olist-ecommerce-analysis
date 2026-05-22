-- Mục đích: Kiểm tra cấu trúc dữ liệu của các bảng chính

USE olist_ecommerce;

-- orders: kiểm tra order_id có bị trùng không
-- Kết quả: 99,441 = 99,441 -> không có duplicate
SELECT COUNT(*) AS count_all, COUNT(DISTINCT order_id) AS count_distinct
FROM orders;

-- order_items: 1 order có bao nhiêu item?
-- Kết quả: 9,803 orders có >1 item -> 1 order có thể có nhiều item
SELECT order_id, COUNT(order_item_id) AS total_items    
FROM order_items 
GROUP BY order_id
HAVING COUNT(order_item_id) > 1;

-- order_items: 1 order_item_id xuất hiện trong bao nhiêu order?
-- Kết quả: order_item_id chỉ là số thứ tự trong order, không phải ID unique toàn bảng
SELECT order_item_id, COUNT(DISTINCT order_id) AS total_orders
FROM order_items
GROUP BY order_item_id
HAVING COUNT(DISTINCT order_id) > 1;

-- order_reviews: 1 order có thể có nhiều hơn 1 review không?
-- Kết quả: 547 orders có >1 review   -> 1 order có thể có nhiều review 
SELECT order_id, COUNT(review_id) AS total_reviews    
FROM order_reviews
GROUP BY order_id
HAVING COUNT(review_id) > 1;

-- order_payments: 1 order có thể có nhiều hơn 1 payment không?
-- Kết quả: 2,961 orders có >1 payment -> 1 order có thể có nhiều payment 
SELECT order_id, COUNT(payment_type) AS total_types   
FROM order_payments
GROUP BY order_id
HAVING COUNT(payment_type) > 1;

-- customers: so sánh customer_id vs customer_unique_id
-- Kết quả: customer_id = 99,441 (bằng số order) -> không dùng cho repeat customer 
--customer_unique_id = 96,096 -> số khách hàng thật (1 khách hàng có thể mua nhiều lần, nhưng chỉ có 1 customer_unique_id)
SELECT 
COUNT(DISTINCT customer_id) AS total_customer_id,
COUNT(DISTINCT customer_unique_id) AS total_unique_customer
FROM customers;

-- customers: khách hàng nào đã mua nhiều hơn 1 lần?
-- Kết quả: 2,997 khách hàng mua >1 lần  
SELECT customer_unique_id, COUNT(*) AS total_purchases
FROM customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;


-- products: kiểm tra product_id có bị trùng không
SELECT product_id, COUNT(*) AS total_rows
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- category_translation: kiểm tra category name có bị trùng không
SELECT product_category_name, COUNT(*) AS total_rows
FROM category_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;

-- 1 order có bao nhiêu customer_id?
SELECT order_id, COUNT(customer_id) AS total_customers
FROM orders
GROUP BY order_id
HAVING COUNT(customer_id) > 1;