# HƯỚNG DẪN JSON TRONG PL/pgSQL (VIBE CODE)

Tài liệu này hướng dẫn **các khái niệm và thao tác JSON cơ bản – thực tế** trong **PostgreSQL / PL/pgSQL**, tập trung vào cách **AI và dev đều hiểu đúng**.

---

## 1️⃣ Object là gì?

### Khái niệm
- **Object** trong PostgreSQL JSON = cấu trúc **key – value**
- Tương đương `{}` trong JSON

### Ví dụ
```sql
SELECT '{"id": 1, "name": "Alice"}'::json AS obj;
```

👉 Đây là **1 JSON object**

---

## 2️⃣ Cách lấy giá trị trong object

### Lấy giá trị dạng text
```sql
SELECT obj ->> 'name' AS name_text
FROM (SELECT '{"id": 1, "name": "Alice"}'::json AS obj) t;
```

**Output**
```text
Alice
```

📌 Ghi nhớ:
- `->>` : dùng trong 99% trường hợp thực tế

---

## 3️⃣ Mảng (Array) là gì?

### Khái niệm
- **Array** = danh sách các phần tử `[]`
- Mỗi phần tử có thể là object

### Ví dụ
```sql
SELECT '[{"id":1},{"id":2}]'::json AS arr;
```

---

## 4️⃣ Cách lấy giá trị trong mảng (theo index)

### 4.0 Lấy phần tử theo index rồi lấy value từ object

```sql
SELECT
  arr -> 0 ->> 'sku' AS item_1,
  arr -> 1 ->> 'sku' AS item_2,
  arr -> 2 ->> 'sku' AS item_3
FROM (
  SELECT '[
    {"sku":"A01","price":100},
    {"sku":"B02","price":200},
    {"sku":"C03","price":50}
  ]'::json AS arr
) t;
```

**Output**
```text
A01 | B02 | C03
```

📌 Index bắt đầu từ **0**

---

## 4.1️⃣ Tách mảng / Làm phẳng – ví dụ ecommerce

```sql
SELECT
  order_obj ->> 'order_id' AS order_id,
  item ->> 'sku'           AS sku,
  (item ->> 'qty')::int    AS qty,
  (item ->> 'price')::int  AS price
FROM json_array_elements(
  '{"order_id":1001,"items":[
    {"sku":"A01","qty":2,"price":100},
    {"sku":"B02","qty":1,"price":200}
  ]}'::json
) AS order_obj
CROSS JOIN json_array_elements(order_obj -> 'items') AS item;
```

### Output
| order_id | sku | qty | price |
| :--- | :--- | :--- | :--- |
| 1001 | A01 | 2 | 100 |
| 1001 | B02 | 1 | 200 |

---

## 4.2️⃣ Gom dòng thành mảng theo key

**Ví dụ bảng `order_items`**

| order_id | sku | qty | price |
| :--- | :--- | :--- | :--- |
| 1001 | A01 | 2 | 100 |
| 1001 | B02 | 1 | 200 |
| 1002 | C03 | 5 | |

---

```sql
SELECT
  order_id,
  json_agg(
    json_build_object(
      'sku', sku,
      'qty', qty
    )
  ) AS items
FROM order_items
GROUP BY order_id;
```

**Output**
```JSON
[
  {
    "order_id": 1001,
    "items": [
      {"sku": "A01", "qty": 2},
      {"sku": "B02", "qty": 1}
    ]
  },
  {
    "order_id": 1002,
    "items": [
      {"sku": "C03", "qty": 5}
    ]
  }
]
```

---

## 5️⃣ Xử lý JSON ecommerce bằng hàm

### Trường hợp A: Nhận mảng items trực tiếp
```sql
SELECT
  item ->> 'sku' AS sku,
  (item ->> 'qty')::int   AS qty,
  (item ->> 'price')::int AS price
FROM json_array_elements(
  '[
    {"sku":"A01","qty":2,"price":100},
    {"sku":"B02","qty":1,"price":200}
  ]'::json
) AS item;
```

**Output**
| sku | qty | price |
| :--- | :--- | :--- |
| SKU01 | 2 | 150 |
| SKU02 | 1 | 300 |

### Trường hợp B: Object có field items
```sql
SELECT
  o ->> 'order_id' AS order_id,
  i ->> 'sku'      AS sku,
  (i ->> 'qty')::int   AS qty,
  (i ->> 'price')::int AS price
FROM (
  SELECT '{"order_id":1001,"items":[
    {"sku":"A01","qty":2,"price":100},
    {"sku":"B02","qty":1,"price":200}
  ]}'::json AS o
) t
CROSS JOIN json_array_elements(o -> 'items') AS i;
```

**Output**
| order_id | sku | qty | price |
| :--- | :--- | :--- | :--- |
| 1001 | A01 | 2 | 100 |
| 1001 | B02 | 1 | 200 |

### Trường hợp C: Nhiều order → mảng các order object

**Input**

```JSON
[
  {
  "order_id": 1001,
  "items": [
    {"sku": "A01", "qty": 2, "price": 100},
    {"sku": "B02", "qty": 1, "price": 200}
  ]
  },
  {
  "order_id": 1002,
  "items": [
    {"sku": "C03", "qty": 3, "price": 150}
  ]
  }
]
```
**Tách 2 tầng**
```sql
SELECT
  order_obj ->> 'order_id' AS order_id,
  item ->> 'sku'           AS sku,
  (item ->> 'qty')::int    AS qty,
  (item ->> 'price')::int  AS price
FROM json_array_elements(
  '[
    {"order_id":1001,"items":[{"sku":"A01","qty":2,"price":100}]},
    {"order_id":1002,"items":[{"sku":"C03","qty":3,"price":150}]}
  ]'::json
) AS order_obj
CROSS JOIN json_array_elements(order_obj -> 'items') AS item;
```

---

## 6️⃣ Sub-function trả về object
### 6.1 Hàm phụ trả về JSON object

```sql
CREATE OR REPLACE FUNCTION get_user(p_id INT)
RETURNS json AS $$
BEGIN
  RETURN json_build_object(
    'id', p_id,
    'name', 'Alice'
  );
END;
$$ LANGUAGE plpgsql;
```
### 6.2 Gọi hàm và lấy giá trị trong object (2 cách)
#### Cách 1: SELECT INTO
```sql
CREATE OR REPLACE FUNCTION get_user_name_v1(p_id INT)
RETURNS TEXT AS $$
DECLARE
user_obj json;
user_name text;
BEGIN
SELECT get_user(p_id) INTO user_obj;
user_name := user_obj ->> 'name';
RETURN user_name;
END;
$$ LANGUAGE plpgsql;
```
#### Cách 2: Gán trực tiếp bằng :=
```sql
CREATE OR REPLACE FUNCTION get_user_name_v2(p_id INT)
RETURNS TEXT AS $$
DECLARE
user_obj json;
BEGIN
user_obj := get_user(p_id);
RETURN user_obj ->> 'name';
END;
$$ LANGUAGE plpgsql;
```
#### 6.3 Gọi hàm trong hàm khác.

```sql
CREATE OR REPLACE FUNCTION get_user_name(p_id INT)
RETURNS TEXT AS $$
DECLARE
user_obj json;
BEGIN
user_obj := get_user(p_id);
RETURN user_obj ->> 'name';
END;
$$ LANGUAGE plpgsql;
```

---

## 7️⃣ jsonb_populate_recordset – Map JSON array vào typed record

### Khái niệm
- Nhận vào một **JSONB array** và "ép" từng phần tử vào **kiểu record cụ thể** (table type hoặc composite type).
- Tự động map key ↔ tên cột, tự động cast kiểu dữ liệu.
- Phù hợp khi bạn đã có sẵn một bảng/type làm khuôn mẫu.

### Cú pháp
```sql
SELECT * FROM jsonb_populate_recordset(NULL::<type>, <jsonb_array>);
```

### Ví dụ thực tế

**Giả sử bảng `qr_scan_quan_ly_tai_san` có cấu trúc:**

| cot | kieu |
|-----|------|
| asset_id | text |
| asset_name | text |
| quantity | int |

**Input JSON (truyền qua biến hoặc tham số hàm):**
```json
[
  {"asset_id": "TS001", "asset_name": "Máy tính", "quantity": 5},
  {"asset_id": "TS002", "asset_name": "Bàn ghế",  "quantity": 10}
]
```

```sql
-- json_input là biến jsonb chứa mảng trên
SELECT *
FROM jsonb_populate_recordset(NULL::qr_scan_quan_ly_tai_san, json_input);
```

**Output**
| asset_id | asset_name | quantity |
|----------|------------|----------|
| TS001 | Máy tính | 5 |
| TS002 | Bàn ghế | 10 |

### Dùng trong PL/pgSQL (INSERT hàng loạt từ JSON)
```sql
CREATE OR REPLACE FUNCTION import_tai_san(json_input jsonb)
RETURNS void AS $$
BEGIN
  INSERT INTO qr_scan_quan_ly_tai_san (asset_id, asset_name, quantity)
  SELECT asset_id, asset_name, quantity
  FROM jsonb_populate_recordset(NULL::qr_scan_quan_ly_tai_san, json_input);
END;
$$ LANGUAGE plpgsql;
```

📌 Ghi nhớ:
- `NULL::<type>` là cách khai báo kiểu mẫu – không dùng giá trị thật.
- Các key trong JSON **phải khớp tên cột** (case-insensitive).
- Cột nào không có trong JSON → nhận giá trị `NULL`.

---

## 8️⃣ jsonb_to_recordset – Map JSON array với schema khai báo inline

### Khái niệm
- Tương tự `jsonb_populate_recordset` nhưng **không cần bảng/type có sẵn**.
- Khai báo schema trực tiếp trong câu query: `AS x(col1 type1, col2 type2, ...)`.
- Linh hoạt hơn khi chỉ cần lấy **một số cột nhất định** từ JSON, hoặc JSON không khớp hoàn toàn với bất kỳ bảng nào.

### Cú pháp
```sql
SELECT x.*
FROM <table_or_subquery>,
     jsonb_to_recordset(<jsonb_column>) AS x(col1 type1, col2 type2, ...);
```

### Ví dụ thực tế

**Bảng `settings_data`:**

| appid | js (jsonb) |
|-------|-----------|
| planning_collect_hcp_gift_exclude | `[{"stt":1,"ma_hcp_2":"HCP001"},{"stt":2,"ma_hcp_2":"HCP002"}]` |

```sql
SELECT x.*
FROM settings_data s,
     jsonb_to_recordset(s.js) AS x(stt int, ma_hcp_2 text)
WHERE s.appid = 'planning_collect_hcp_gift_exclude';
```

**Output**
| stt | ma_hcp_2 |
|-----|----------|
| 1 | HCP001 |
| 2 | HCP002 |

### Cách thay thế: dùng `json_array_elements` + `->>` (không cần khai báo type)

Khi không muốn dùng `jsonb_to_recordset`, có thể dùng `json_array_elements` rồi tự extract từng field:

```sql
SELECT
  (x.val ->> 'stt')::int  AS stt,
  x.val ->> 'ma_hcp_2'    AS ma_hcp_2
FROM settings_data s,
     json_array_elements(s.js::json) AS x(val)
WHERE s.appid = 'planning_collect_hcp_gift_exclude';
```

**Output**
| stt | ma_hcp_2 |
|-----|----------|
| 1 | HCP001 |
| 2 | HCP002 |

📌 Ghi nhớ:
- `json_array_elements` trả về mỗi phần tử là **1 json value** → phải dùng `->>` để lấy từng field.
- Phải **tự cast** kiểu dữ liệu (ví dụ `::int`), không tự động như `jsonb_to_recordset`.
- Phù hợp khi muốn **thêm logic tính toán** trên từng field trong cùng câu SELECT.

---

### So sánh với jsonb_populate_recordset

| Tiêu chí | `jsonb_populate_recordset` | `jsonb_to_recordset` |
|----------|---------------------------|----------------------|
| Cần type/bảng có sẵn? | ✅ Có | ❌ Không cần |
| Khai báo schema | Lấy từ type | Inline trong query |
| Linh hoạt chọn cột | Lấy tất cả cột của type | Chỉ khai báo cột cần |
| Dùng trong hàm PL/pgSQL | Phổ biến hơn | Tiện cho query nhanh |

📌 Ghi nhớ:
- Dùng `jsonb_to_recordset` khi query **ad-hoc**, không muốn phụ thuộc vào type.
- Dùng `jsonb_populate_recordset` khi đã có bảng khuôn và cần **INSERT / bulk load**.

---

## 🧠 Tóm tắt nhanh

| Hành động | Hàm |
|---------|-----|
| Object | json_build_object |
| Array | [] |
| Lấy index | arr -> index |
| Tách mảng / làm phẳng | json_array_elements |
| Gom mảng | json_agg |
| Map JSON array → typed record (có sẵn type) | jsonb_populate_recordset |
| Map JSON array → record inline (không cần type) | jsonb_to_recordset, json_array_elements  |

---
