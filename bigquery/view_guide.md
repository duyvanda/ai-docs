# 📜 QUY TRÌNH PHÁT TRIỂN & CHUẨN HÓA CODE SQL (SQL WORKFLOW STANDARD)

**Phiên bản:** 1.1 (Updated: Comment Policy)
**Đối tượng áp dụng:** Data Analysts, Data Engineers, Backend Developers
**Mục tiêu:** Đảm bảo code SQL dễ đọc, dễ bảo trì, tối ưu hiệu năng và thống nhất phong cách (The "Vibe" Code).

---

## 📅 Giai đoạn 1: Requirement Gathering (Thu thập yêu cầu)
*Không viết code khi chưa rõ Output.*

Trước khi bắt đầu, Data Owner phải trả lời được 3 câu hỏi:
1. **Business Goal:** Báo cáo này giải quyết vấn đề gì? (Tracking doanh thu, tìm lỗi, hay audit?)

---

## 📝 Giai đoạn 2: Technical Design & Spec (Thiết kế kỹ thuật)
*Tư duy hệ thống trước khi gõ phím.*

### 1. Data Lineage (Luồng dữ liệu)
Phác thảo luồng xử lý:
> `Source Tables` (Raw) ➡️ `Cleaning Logic` ➡️ `Business Logic` ➡️ `Final Aggregation`

### 2. Định nghĩa Output
Thống nhất Schema kết quả trả về:
| Column Name | Data Type | Description / Logic |
| :--- | :--- | :--- |
| `report_date` | Date | Ngày báo cáo |
| `user_type` | String | 'New' nếu mua lần đầu, 'Returning' nếu quay lại |
| `net_revenue` | Float | `(price * qty) - discount`. Không bao gồm VAT |

---

## 💻 Giai đoạn 3: Coding Guidelines (Quy tắc viết Code)
*Áp dụng kiến trúc "CTE Pyramid".*

### 1. Cấu trúc CTE chuẩn
Tuyệt đối hạn chế Nested Subqueries. Sử dụng `WITH` (CTE) theo lớp:
1.  **Base Layer:** Load data, filter rác, rename cột.
2.  **Enrichment Layer:** Join bảng, tính toán công thức.
3.  **Aggregation Layer:** Group by, SUM, COUNT.
4.  **Final Layer:** Select cuối cùng, format số, sort.

### 2. Quy tắc đặt tên (Naming Convention)
* **Tables/CTEs:** Snake_case (vd: `daily_revenue`, `active_users`).
* **Aliases:** Ngắn gọn có nghĩa (`ord`, `usr`, `prod`). ❌ Không dùng `t1`, `t2`, `a`.
* **Prefix cột:** Luôn chỉ rõ nguồn gốc cột khi Join (vd: `usr.email`, `ord.created_at`).

### 3. Quy tắc Comment (Documentation Policy) - 🆕
**Nguyên tắc vàng:** Comment **"Tại sao" (Why)**, không comment **"Đang làm gì" (What)**.

* **❌ Case 1: Code hiển nhiên ➡️ KHÔNG Comment.**
    * *Ví dụ:* `WHERE status = 'active'` (Không cần chú thích "Lấy user active").
* **✅ Case 2: Logic nghiệp vụ phức tạp ➡️ Dùng `/* ... */` trước CTE.**
    * *Ví dụ:* Công thức tính thưởng, logic phân loại khách hàng VIP.
* **⚠️ Case 3: Workaround / Fix Data bẩn ➡️ BẮT BUỘC Comment.**
    * Nếu có đoạn code lạ (Hard-code ID, Distinct On...) để fix lỗi, phải ghi rõ lý do và Ticket ID.
    * *Ví dụ:* `/* FIXME: Loại bỏ user test ID 999 theo yêu cầu ticket DATA-101 */`

### 4. Quy tắc phòng thủ (Defensive Coding)
* **Xử lý NULL:** Dùng `COALESCE` cho các cột tính toán.
* **Phép chia:** Dùng `NULLIF(mau_so, 0)` để tránh lỗi chia cho 0.

---

## 🧪 Giai đoạn 4: Validation & Review (Kiểm thử)

### Checklist trước khi Merge/Deploy:
- [ ] **Data Volume:** Số lượng dòng (Row count) hợp lý, không bị nổ dòng do Join.
- [ ] **Data Logic:** Không có số âm vô lý, không có NULL ở Primary Key.
- [ ] **Cross-check:** Tổng số liệu khớp với Dashboard cũ/Kế toán.
- [ ] **Comment Check:** Đã giải thích các đoạn logic "ảo thuật" chưa?

---

## 📎 Phụ lục: Mẫu Code Chuẩn (Template)

```sql
/*
  📂 Task: [Tên Task]
  👤 Author: [Tên bạn]
*/

WITH 
-- 1. BASE LAYER (Simple -> No comment needed)
base_orders AS (
    SELECT id, user_id, total, created_at 
    FROM `raw.orders`
    WHERE created_at >= '2024-01-01'
),

/* 2. LOGIC LAYER
   Logic: Tính doanh thu Net.
   Lưu ý: Trừ thêm 5% phí sàn nếu là đơn hàng từ kênh Affiliate.
*/
enriched_data AS (
    SELECT
        o.id,
        CASE 
            WHEN o.channel = 'affiliate' THEN o.total * 0.95
            ELSE o.total 
        END AS net_revenue
    FROM base_orders o
),

/* FIXME: Dữ liệu ngày 15/02 bị duplicate do lỗi hệ thống.
   Dùng DISTINCT để làm sạch. (Ref: JIRA-BUG-002) 
*/
clean_data AS (
    SELECT DISTINCT * FROM enriched_data
)

-- 3. FINAL SELECT
SELECT * FROM clean_data;