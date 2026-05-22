## Validation Results (từ SQL queries)

| Bảng | Grain | Risk |
|---|---|---|
| orders | 1 row = 1 order | Không có duplicate |
| order_items | 1 row = 1 item trong 1 order | 9,803 orders có >1 item |
| order_reviews | Assume 1-1 nhưng có duplicate | 547 orders có >1 review |
| order_payments | 1 row = 1 payment transaction | 2,961 orders có >1 payment |
| customers | customer_unique_id có duplicate | 2,997 unique customers mua >1 lần |