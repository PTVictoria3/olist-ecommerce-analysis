# Olist E-commerce — Trải nghiệm giao hàng thực sự tốt đến đâu?

Phân tích ~95.000 đơn hàng đã giao của sàn Olist (Brazil, 2016–2018) để trả lời một câu hỏi nền:
**"Trải nghiệm giao hàng thực sự tốt đến đâu, ai đang chịu thiệt, và chi phí ẩn nằm ở đâu?"**

**Công cụ:** Python (pandas) → SQL Server (T-SQL) → Power BI

📊 **[Xem dashboard (file .pbix)](ĐẶT-LINK-PBIX-TẠI-ĐÂY)** <!-- 🔗 LINK 1: link tới file .pbix trong repo, hoặc link Power BI Service nếu có publish -->

---

## ⚡ 3 phát hiện đáng chú ý nhất

1. **"92% đơn giao sớm" là con số ảo.** Nó không phản ánh vận hành xuất sắc — Olist đệm lời hứa giao hàng trung vị **12 ngày** (hứa 24 ngày, giao thật chỉ 12). Con số đẹp là kết quả của lời hứa phòng thủ, không phải logistics giỏi.
2. **Điểm đen không phải nơi tệ nhất, mà là nơi đông nhất.** Tuyến SP→SP có tỉ lệ trễ thấp (~5%) nhưng vẫn là điểm đen số 1 vì volume khổng lồ — 2 tuyến SP→SP và SP→RJ gộp lại chiếm **~40% tổng đơn trễ**. Bài học: khi ưu tiên nguồn lực, phải phân biệt *rate* và *volume*.
3. **Tiền rủi ro không tỉ lệ thuận với mức độ trễ.** Nhóm trễ vừa (8–15 ngày) mang nhiều doanh thu rủi ro hơn nhóm trễ nặng nhất (>15 ngày) — vì tần suất thắng thế cường độ.

---

## 1. Bối cảnh & câu hỏi business

Olist là sàn e-commerce kết nối seller nhỏ với các marketplace lớn tại Brazil. Với mô hình này, trải nghiệm giao hàng là thứ Olist *chịu trách nhiệm về uy tín* nhưng *không trực tiếp kiểm soát toàn bộ* — nên câu hỏi "giao hàng đang tốt hay tệ, và tệ ở đâu" có giá trị hành động thật.

Dự án trả lời **7 câu hỏi, xếp theo 3 tầng phân tích**:

| Tầng | # | Câu hỏi |
|---|---|---|
| **Mô tả** | Q1 | Lời hứa giao hàng có sát thực tế không? |
| | Q2 | Phí vận chuyển (freight) chiếm bao nhiêu % giá trị đơn? |
| **Chẩn đoán** | Q3 | Trễ ảnh hưởng review thế nào — điểm gãy ở đâu? |
| | Q4 | Trễ do khâu nào: seller chuẩn bị hàng hay carrier vận chuyển? |
| | Q5 | Tuyến giao hàng nào là điểm đen? |
| **Hành động** | Q6 | Bao nhiêu doanh thu đang mắc kẹt ở đơn vừa trễ vừa review thấp? |
| | Q7 | Ngưỡng hành động cụ thể nằm ở đâu? |

---

## 2. Dữ liệu & pipeline

**Nguồn:** [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — 8 bảng, ~99K đơn hàng, 2016–2018.

```
Kaggle CSV (8 bảng)
   │
   ▼  Python (pandas) — cleaning_copy.ipynb
   │   • Chuẩn hóa datetime, strip text, xử lý null
   │   • 1 order có nhiều review → giữ review mới nhất theo review_answer_timestamp
   │   • Làm sạch geolocation → geo_clean (19K zip prefix)
   │   • Nạp vào SQL Server qua SQLAlchemy + pyodbc
   ▼
SQL Server — kpi_queries.sql
   │   • Tạo view fact_orders: delay_days, promised_days, seller_processing_days,
   │     shipping_days, total_value, main_seller (window function)
   │   • Kiểm tra chất lượng: đếm dòng, orphan keys giữa fact và dimension
   │   • Truy vấn KPI: bucket độ trễ × review, phân rã trễ theo khâu,
   │     Pareto tuyến (lọc n ≥ 30 tránh sai lệch thống kê), doanh thu rủi ro
   ▼
Power BI — dashboard 4 trang
       Star schema: fact_orders + dim (customers, sellers, dim_date, geo_clean)
       DAX measures riêng trong bảng Measure
```

### Vòng đời một đơn hàng — và vì sao chỉ phân tích đơn `delivered`

Mỗi đơn Olist đi qua chuỗi trạng thái, mỗi mốc để lại một timestamp:

![Vòng đời đơn hàng Olist](images/order_lifecycle.png) <!-- 🖼️ ẢNH 6: sơ đồ vòng đời đơn hàng (flowchart Created → Delivered) → lưu vào images/ với tên order_lifecycle.png -->

Nhánh chính: `created → approved → processing → invoiced → shipped → delivered`. Hai nhánh fail: `canceled` (hủy sau khi đặt/thanh toán) và `unavailable` (seller không fulfill được).

Các timestamp này chính là nguyên liệu cho mọi metric trong dự án:

| Timestamp | Ý nghĩa business | Metric tính từ nó |
|---|---|---|
| `order_purchase_timestamp` | Khách đặt hàng | Mốc gốc; `promised_days = estimated − purchase` |
| `order_approved_at` | Thanh toán xác nhận — khâu seller bắt đầu | `seller_processing_days = carrier − approved` |
| `order_delivered_carrier_date` | Seller bàn giao carrier — khâu vận chuyển bắt đầu | `shipping_days = customer − carrier` |
| `order_delivered_customer_date` | Khách nhận hàng | `delay_days = customer − estimated` |
| `order_estimated_delivery_date` | ETA hứa với khách ngay lúc đặt | Chuẩn so sánh cho trễ/sớm |

Hiểu vòng đời giúp phân biệt **NULL hợp lệ** và **lỗi dữ liệu**: đơn `shipped` chưa có `customer_date` là bình thường (hàng đang trên đường); đơn `canceled` không có `carrier_date` là bình thường (chưa từng bàn giao); nhưng đơn `delivered` mà thiếu `approved_at` là mâu thuẫn business → data quality issue. Đây là lý do phân tích **lọc `order_status = 'delivered'`**: chỉ nhóm này có đủ cả 4 timestamp để tính trọn chuỗi metric và so sánh công bằng giữa các đơn.

**Mô hình dữ liệu trong Power BI:**

![Data model](images/data_model.png) <!-- 🖼️ ẢNH 1: ảnh chụp sơ đồ quan hệ (ảnh star schema bạn có sẵn) → lưu vào thư mục images/ với tên data_model.png -->

---

## 3. Trả lời từng câu hỏi

### Q1 — Lời hứa giao có sát thực tế không? → Không, đệm rất dày
91,8% đơn giao "sớm hơn hứa", nhưng trung vị đệm lời hứa là **12 ngày** (hứa ~24, giao thật ~12). Đệm còn **lệch mạnh theo vùng**: từ 10 ngày (AL) đến 21 ngày (RO) — Olist biết vùng nào rủi ro và phòng thủ bằng lời hứa dài hơn. Đáng chú ý: một số vùng (AL, MA) đệm ít mà tỉ lệ trễ vẫn cao — phòng thủ thất bại đúng nơi cần nhất.

### Q2 — Freight chiếm bao nhiêu? → ~14%, và là "phí hồi quy ngược"
Freight chiếm ~14% giá trị đơn, nhưng đơn giá trị thấp chịu tỉ trọng cước cao hơn đơn giá trị cao. Category nặng cước nhất chịu tỉ lệ gần gấp đôi category nhẹ nhất.

### Q3 — Trễ ảnh hưởng review thế nào? → Điểm gãy ở mốc 3 ngày
Tỉ lệ review thấp (≤2 sao) nhảy bậc theo độ trễ:

| Đúng/sớm hạn | Trễ 1–3 ngày | Trễ 4–7 | Trễ 8–15 | Trễ >15 |
|---|---|---|---|---|
| 9,8% | 33,2% | 70,8% | 82,2% | 82,2% |

Kiểm định chi-square xác nhận khác biệt có ý nghĩa thống kê (p < 0.001). **Mốc 3 ngày là ngưỡng hành động quan trọng nhất** — vượt qua nó, xác suất mất khách tăng gấp hơn 3 lần.

### Q4 — Trễ do khâu nào? → 82% nằm ở vận chuyển
Phân rã tổng thời gian trễ: **82% thuộc khâu carrier vận chuyển, chỉ 18% thuộc khâu seller chuẩn bị hàng**. Vấn đề là logistics, không phải seller chậm — điều này định hướng thẳng khuyến nghị: đàm phán/đổi carrier hiệu quả hơn là ép seller.

### Q5 — Tuyến nào là điểm đen? → SP→SP và SP→RJ (theo volume, không phải rate)
Phân tích Pareto (lọc tuyến ≥ 30 đơn): 2 tuyến **SP→SP (1.425 đơn trễ) và SP→RJ (1.149 đơn)** chiếm ~40% tổng đơn trễ. SP→SP có tỉ lệ trễ thấp (~5%) vì là "sân nhà" — nhưng volume khiến nó vẫn là nơi đáng ưu tiên nhất về giá trị tuyệt đối.

### Q6 — Doanh thu nào mắc kẹt? → ~756K R$ ở đơn vừa trễ vừa review thấp
4.125 đơn vừa trễ vừa review ≤2 sao mang ~756K R$ doanh thu (trung bình ~183 R$/đơn). Số tiền này **hội tụ đúng vào 2 tuyến điểm đen** ở Q5 (~36%) — không phải trùng hợp, mà là cùng một vấn đề nhìn từ hai góc: vận hành và tài chính.

### Q7 — Ngưỡng hành động ở đâu? → Giữ đơn dưới mốc trễ 3 ngày
Doanh thu vượt ngưỡng trễ 3 ngày: ~662K R$. Phát hiện phụ đáng giá: tiền không dồn nhiều nhất ở nhóm trễ nặng nhất (>15 ngày: 177K) mà ở **nhóm trễ 8–15 ngày (250K)** — vì nhóm này đông đơn hơn. Chiến lược "cứu" nhóm trễ vừa hiệu quả về tiền hơn là chỉ tập trung ca nặng.

---

## 4. Dashboard (Power BI, 4 trang)

**Trang 1 — Tổng quan:** KPI tổng (95K đơn, 7% trễ, đệm 12 ngày, freight 14%), xu hướng trễ theo tháng, phổ giao hàng, phân phối ngày đệm. *(Trả lời Q1, Q2)*

![Trang Tổng quan](images/page1_tongquan.png) <!-- 🖼️ ẢNH 2: screenshot trang Tổng quan (chụp lại sau khi đã dịch xong nhãn, KHÔNG chụp cả cửa sổ Power BI Desktop — chỉ vùng canvas) -->

**Trang 2 — Trễ có hại gì?:** Điểm gãy review theo bucket trễ, tỉ trọng trễ theo khâu (donut 82/18), so sánh trung vị số ngày mỗi khâu. *(Trả lời Q3, Q4)*

![Trang Trễ & review](images/page2_tre_review.png) <!-- 🖼️ ẢNH 3 -->

**Trang 3 — Tuyến nào là điểm đen?:** Pareto đơn trễ theo tuyến, tỉ lệ trễ theo nhóm hàng và theo tuyến. *(Trả lời Q5)*

![Trang Điểm đen](images/page3_diemden.png) <!-- 🖼️ ẢNH 4 -->

**Trang 4 — Doanh thu rủi ro:** Doanh thu rủi ro theo tuyến và theo mức độ trễ, ngưỡng 3 ngày. *(Trả lời Q6, Q7)*

![Trang Doanh thu rủi ro](images/page4_doanhthu.png) <!-- 🖼️ ẢNH 5 -->

---

## 5. Khuyến nghị

1. **Ưu tiên cải thiện vận chuyển ở 2 tuyến SP→RJ và SP→SP** — giải quyết đồng thời ~40% đơn trễ và ~36% doanh thu rủi ro, và vì 82% thời gian trễ nằm ở khâu carrier, đòn bẩy là đàm phán SLA/đổi carrier trên 2 tuyến này.
2. **Lấy mốc "trễ ≤ 3 ngày" làm KPI bảo vệ review** — đây là điểm gãy đã kiểm định, không phải ngưỡng cảm tính. Đơn có nguy cơ vượt mốc này đáng được can thiệp chủ động (thông báo sớm, ưu tiên xử lý).
3. **Rút ngắn lời hứa ở vùng đã đệm quá an toàn** (nội thành SP đệm ~11–12 ngày) — lời hứa ngắn hơn tăng tỉ lệ chốt đơn mà vẫn giữ biên an toàn; ngược lại tăng đệm ở vùng đệm ít nhưng trễ cao (AL, MA).

---

## 6. Hạn chế & hướng phát triển

- **Doanh thu rủi ro là ước lượng trần**, không phải tổn thất thực: đơn trễ + review thấp không đồng nghĩa mất 100% giá trị khách hàng đó.
- **Tương quan ≠ nhân quả**: review thấp gắn với trễ rất mạnh (p < 0.001) nhưng có thể còn yếu tố đồng thời (chất lượng sản phẩm, kỳ vọng theo vùng).
- Dữ liệu dừng ở 2018 — mẫu hình tuyến/carrier có thể đã thay đổi.
- **Hướng phát triển:** xây model dự báo đơn có nguy cơ trễ (feature sẵn có: promised_days, freight, tuyến) để chuyển từ phân tích hồi cứu sang can thiệp chủ động.

---

## 7. Cấu trúc repo

```
├── cleaning_copy.ipynb        # Python: làm sạch 8 bảng, nạp SQL Server
├── kpi_queries.sql            # T-SQL: view fact_orders + truy vấn KPI
├── dashboard.pbix             # Power BI 4 trang            <!-- đổi đúng tên file .pbix của bạn -->
├── images/                    # Screenshot dashboard + data model
└── README.md
```

**Chạy lại dự án:** tải dataset từ Kaggle → chạy `cleaning_copy.ipynb` (cần SQL Server + ODBC Driver 17, sửa chuỗi kết nối `SERVER=` theo máy của bạn) → chạy `kpi_queries.sql` tạo view → mở `dashboard.pbix` và trỏ nguồn về database `olist`.

---

*Dự án portfolio cá nhân — dữ liệu công khai từ Olist/Kaggle.*
<!-- 🔗 LINK 2 (tùy chọn): thêm dòng liên hệ — LinkedIn / email của bạn -->
