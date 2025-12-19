# ✅ **PostgreSQL Function Creation Rules (AI-Ready Guidelines)**

*(Dùng để yêu cầu AI viết function Postgres đúng chuẩn — giống style AdPyke cho SQL)*

---

## **Quy tắc comments**
* Sử dụng **Block Comment** `/* ... */` cho mọi giải thích.

## **1. Cấu trúc tổng thể chuẩn**

Mọi function phải theo skeleton sau:

1. **Parse input fields từ JSON**
2. **Tạo CTE TABLE chứa các data cần thiết**
3. **Tạo các CTE TABLE xử lý bổ sung** (summary, grouping, lookup…)
6. **Nếu fail → return JSON fail**
8. **Return JSON success**
9. **Exception block**

```sql
CREATE OR REPLACE FUNCTION schema.function_name(url_param jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    -- variable declarations
BEGIN
    -- main logic trả về duy nhất 1 JSON object phẳng (flat structure)
    RETURN
    CTE1
    CTE2
    CTE3
    -- 
    jsonb_build_object(
    'status', 'ok',
    'CTE1', (SELECT jsonb_agg(f) FROM CTE1)
)
    ;
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'status', 'fail',
            'error_message', SQLERRM
        );
END;
$$;
```

---

## **2. Quy tắc đặt tên**

### **2.1. Function**

* snake_case
* có prefix theo domain

  * `get_` → đọc
  * `insert_` → thêm
👉 Ví dụ:
`get_form_seminar_hco_cxm`
---

### **2.2. Biến**

* Tên biến bắt buộc có `p_` nếu là parameter
* Tên biến trong `DECLARE` không cần `v_` (tránh dài dòng)
* Luôn dùng `text`, `numeric`, `timestamp` thay vì type mơ hồ

---

## **3. Quy tắc Parameter**

* Luôn khai báo 1 param JSONB duy nhất khi cần nhiều filter
  → giúp mở rộng future mà không phải sửa function

Ví dụ:

```sql
url_param jsonb
```

Sau đó parse:

```sql
p_id := url_param->>'id';
p_from_date := (url_param->>'from_date')::date;
```

---

## **4. Quy tắc Build JSON Response**

Luôn trả về dạng chuẩn:

```sql
jsonb_build_object(
    'status', 'ok',
    'rows', (SELECT COUNT(*) FROM rows_data),
    'data', (SELECT jsonb_agg(f) FROM rows_data)
)
```

### Yêu cầu bắt buộc:

* `status` luôn có `'ok'` hoặc `'fail'`
* Không bao giờ để `data: null` → phải là `[]`
* Luôn wrap kết quả trong `WITH rows_data AS (...)`

---

## **5. Quy tắc CTE (WITH)**

* Tất cả query chính phải nằm trong CTE `rows_data`
* Thêm CTE khác nếu cần:

Ví dụ:

```sql
WITH filters AS (...),
     rows_data AS (...)
SELECT ...
```

---

## **6. Quy tắc EXCEPTION**

Luôn cần block EXCEPTION:

```sql
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'status', 'fail',
            'error_message', SQLERRM
        );
```

Không log lỗi vào bảng trừ khi được yêu cầu.

---

## **7. Quy tắc Comment**

* Mỗi function cần comment ngắn phía trên:

```sql
-- Function: get list seminar hco
-- Author: AI
-- Input: url_param jsonb (key: manv, month, status)
-- Output: JSONB standard format
```

---

## **8. Quy tắc về Query Safety**

* Không dùng dynamic SQL trừ khi bắt buộc
* Không dùng `SELECT *`
* Với LIKE: dùng `ILIKE` và escape `%`

---

## **9. Quy tắc Logic**

### **Luôn dùng STRPOS thay vì LIKE nếu chỉ tìm substring**

→ tốc độ nhanh hơn nhiều

```sql
WHERE STRPOS(manv, p_manv) > 0
```

### **Nếu filter rỗng → không áp dụng filter**

Ví dụ:

```sql
AND (p_manv = '' OR STRPOS(manv, p_manv) > 0)
```

---

## **10. Template function hoàn chỉnh (AI dùng luôn)**

```sql
CREATE OR REPLACE FUNCTION schema.fn_template(url_param jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    p_search text := COALESCE(url_param->>'search', '');
BEGIN
    RETURN (
        WITH rows_data1 AS (
            SELECT 
                id,
                name,
                created_at
            FROM schema.table_name
            WHERE (p_search = '' OR STRPOS(name, p_search) > 0)
            ORDER BY created_at DESC
        ),
        smn_thang_options AS (
            SELECT
                TO_CHAR(month_date, 'DD-MM-YYYY') AS value,
                TO_CHAR(month_date, 'DD-MM-YYYY') AS label
            FROM generate_series( (EXTRACT(YEAR FROM CURRENT_DATE) || '-01-01')::date, (EXTRACT(YEAR FROM CURRENT_DATE) || '-12-01')::date, '1 month') as month_date
        ),
        SELECT jsonb_build_object(
            'status', 'ok',
            'rows_data1', COALESCE((SELECT jsonb_agg(f) FROM rows_data1 f), '[]'::jsonb),
            'smn_thang_options', COALESCE((SELECT jsonb_agg(f) FROM smn_thang_options f), '[]'::jsonb)
        )
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'status', 'fail',
            'error_message', SQLERRM
        );
END;
$$;
```

---
