# 📜 QUY TRÌNH PHÁT TRIỂN & CHUẨN HÓA CODE SQL (SQL WORKFLOW STANDARD)

**Phiên bản:** 1.3 (Updated: Data Schema & Consistent Example)
**Đối tượng áp dụng:** Data Analysts, Data Engineers, Backend Developers
**Mục tiêu:** Đảm bảo code SQL dễ đọc, dễ bảo trì, tối ưu hiệu năng và thống nhất phong cách (The "Vibe" Code).

---

## 📅 Giai đoạn 1: Requirement Gathering (Thu thập yêu cầu)
*Không viết code khi chưa rõ Output.*

Trước khi bắt đầu, Data Owner phải trả lời được câu hỏi cốt lõi:
1. **Business Goal:** Báo cáo này giải quyết vấn đề gì? (Tracking doanh thu, tìm lỗi, hay audit?)

---

## 📝 Giai đoạn 2: Technical Design & Spec (Thiết kế kỹ thuật)
*Tư duy hệ thống trước khi gõ phím.*

### 1. Data Lineage (Luồng dữ liệu)
Phác thảo luồng xử lý:
> `Source Tables` (Raw) ➡️ `Cleaning Logic` ➡️ `Business Logic` ➡️ `Final Aggregation`

### 2. Định nghĩa Output
Thống nhất Schema kết quả trả về:
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `report_month` | Date | Tháng báo cáo |
| `user_tier` | String | Hạng thành viên (Gold, Silver...) |
| `total_revenue` | Float | Tổng doanh thu thực |

### 3. Data Schema (Ví dụ mô hình dữ liệu)
Các bảng nguồn sẽ được sử dụng trong quy trình này:

**Table 1: `F_SALES` (Fact Table - Giao dịch)**
| Column | Type | Description |
| :--- | :--- | :--- |
| `sales_id` | String | PK - Mã đơn hàng |
| `user_id` | Int | FK - Mã khách hàng |
| `order_date`| Date | Ngày mua hàng |
| `net_amount`| Float | Giá trị đơn hàng (Sau KM) |

**Table 2: `D_USERS` (Dimension Table - Khách hàng)**
| Column | Type | Description |
| :--- | :--- | :--- |
| `user_id` | Int | PK - Mã khách hàng |
| `join_date` | Date | Ngày tạo tài khoản |
| `user_tier` | String | Hạng (`Standard`, `Gold`, `VIP`) |

---

## 💻 Giai đoạn 3: Coding Guidelines (Quy tắc viết Code)
*Áp dụng kiến trúc "CTE Pyramid" 4 tầng.*

### 1. Cấu trúc CTE chuẩn
Tuyệt đối hạn chế Nested Subqueries. Sử dụng `WITH` (CTE) theo lớp:

1.  **Base Layer:** Load **dữ liệu thô (Raw Data)**. Apply filter logic, rename cột.
2.  **Enrichment Layer:** Join bảng (Fact nối Dimension), tính toán logic nghiệp vụ (thuế, chiết khấu).
    * *💡 Nếu logic đơn giản, có thể gộp Base & Enrichment.*
3.  **Aggregation Layer:** Group by, SUM, COUNT.
4.  **Final Layer:** Select cuối cùng, format số, sort.

### 2. Quy tắc đặt tên (Naming Convention)
* **Tables/CTEs:** Snake_case (vd: `base_sales`, `monthly_stats`).
* **Aliases:** Ngắn gọn có nghĩa (`s` cho Sales, `u` cho Users). ❌ Không dùng `t1`, `t2`, `a`.
* **Prefix cột:** Luôn chỉ rõ nguồn gốc cột khi Join (vd: `u.user_tier`, `s.order_date`).

### 3. Quy tắc Comment (Documentation Policy)
**Nguyên tắc vàng:** Comment **"Tại sao" (Why)**, không comment **"Đang làm gì" (What)**.

* **❌ Case 1: Hiển nhiên ➡️ KHÔNG Comment.** (Vd: `WHERE price > 0`)
* **✅ Case 2: Logic phức tạp ➡️ Dùng `/* ... */` trước CTE.**
* **⚠️ Case 3: Fix lỗi Data ➡️ BẮT BUỘC Comment kèm Ticket ID.**
    * *Ví dụ:* `/* FIXME: Loại bỏ test user ID 999 (Ticket: DATA-101) */`

### 4. Quy tắc phòng thủ (Defensive Coding)
* **Xử lý NULL:** Dùng `COALESCE(col, 0)` cho các cột tính toán số học.
* **Phép chia:** Dùng `NULLIF(mau_so, 0)` để tránh lỗi Division by zero.

---

## 🧪 Giai đoạn 4: Validation & Review (Kiểm thử)

### Checklist trước khi Merge/Deploy:
- [ ] **Data Volume:** Row count hợp lý, không bị nổ dòng do Join 1-n.
- [ ] **Data Logic:** Không có số âm vô lý, không có NULL ở Primary Key.
- [ ] **Cross-check:** Tổng số liệu khớp với Dashboard cũ/Kế toán.

---

## 📎 Phụ lục: Mẫu Code Chuẩn (Template)

```sql
/*
  📂 Task: [DATA-001] Monthly Revenue by User Tier
  👤 Author: [Your Name]
  --------------------------------------------------
  Logic: Tính tổng doanh thu theo hạng thành viên mỗi tháng.
  Chỉ tính các đơn hàng thành công (net_amount > 0).
*/

WITH 
-- ==========================================================
-- 1. BASE LAYER (Raw Data Access)
-- Load dữ liệu từ F_SALES và D_USERS
-- ==========================================================
base_sales AS (
    SELECT sales_id, user_id, net_amount, order_date
    FROM `F_SALES`
    WHERE order_date >= '2024-01-01'
),

base_users AS (
    SELECT user_id, user_tier
    FROM `D_USERS`
),

-- ==========================================================
-- 2. ENRICHMENT LAYER (Business Logic & Joins)
-- Join Fact với Dimension để lấy thông tin hạng thành viên
-- ==========================================================
enriched_transactions AS (
    SELECT
        s.sales_id,
        s.order_date,
        COALESCE(u.user_tier, 'Unknown') AS user_tier, -- Xử lý user không có hạng
        s.net_amount
    FROM base_sales s
    LEFT JOIN base_users u 
        ON s.user_id = u.user_id
),

-- ==========================================================
-- 3. AGGREGATION LAYER (Grouping)
-- Gom nhóm theo Tháng và Tier
-- ==========================================================
monthly_stats AS (
    SELECT
        DATE_TRUNC('month', order_date) AS report_month,
        user_tier,
        SUM(net_amount) AS total_revenue,
        COUNT(sales_id) AS total_orders
    FROM enriched_transactions
    GROUP BY 1, 2
),

-- ==========================================================
-- 4. FINAL LAYER (Formatting)
-- Format số liệu, sort kết quả
-- ==========================================================
final_report AS (
    SELECT
        report_month,
        user_tier,
        total_orders,
        -- Format số tiền (VD: làm tròn 2 số lẻ)
        ROUND(total_revenue, 2) AS revenue
    FROM monthly_stats
)

SELECT * FROM final_report
ORDER BY report_month DESC, revenue DESC;