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

## 🧠 Tóm tắt nhanh

| Hành động | Hàm |
|---------|-----|
| Object | json_build_object |
| Array | [] |
| Lấy index | arr -> index |
| Tách mảng / làm phẳng | json_array_elements |
| Gom mảng | json_agg |

---
