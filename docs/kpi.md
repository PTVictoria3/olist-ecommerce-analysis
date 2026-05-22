# KPI Dictionary

## Project
E-commerce Delivery & Customer  Analysis

---

## 1. Late Delivery Rate
**Định nghĩa:** Tỷ lệ đơn hàng giao trễ so với ngày dự kiến.
**Công thức:** COUNT(đơn trễ) / COUNT(tổng đơn đã giao)
**Điều kiện trễ:** order_delivered_customer_date > order_estimated_delivery_date
**Lưu ý:** Chỉ tính đơn có trạng thái 'delivered' và có đầy đủ ngày giao thực tế + ngày dự kiến
**Kết quả:** 8.1%

---

## 2. Average Delivery Days
**Định nghĩa:** Số ngày trung bình từ khi đặt hàng đến khi khách nhận hàng.
**Công thức:** AVG(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date))
**Lưu ý:** Chỉ tính đơn đã giao thành công
**Kết quả:** 12 ngày

---

## 3. Average Review Score
**Định nghĩa:** Điểm đánh giá trung bình của khách hàng trên thang 1-5.
**Công thức:** AVG(review_score)
**Kết quả:** 4/5

---

## 4. Item Revenue
**Định nghĩa:** Tổng doanh thu từ giá bán sản phẩm.
**Công thức:** SUM(price) từ bảng order_items
**Lưu ý:** Không dùng payment_value cho phân tích theo category
**Kết quả:** ~13.6M BRL

---

## 5. Repeat Customer Rate
**Định nghĩa:** Tỷ lệ khách hàng quay lại mua nhiều hơn 1 lần.
**Công thức:** COUNT(khách mua > 1 lần) / COUNT(tổng khách hàng)
**Lưu ý:** Dùng customer_unique_id, không dùng customer_id
**Kết quả:** 3.1%