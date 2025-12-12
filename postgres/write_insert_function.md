# ✅ **1. STRUCTURE RULES — KHUNG CỐ ĐỊNH CỦA MỌI HÀM**

## **Quy tắc đặt tên**
* snake_case
* có prefix theo domain
  * `insert_` → thêm, thường thêm vào 1 bảng
👉 Ví dụ:
`insert_form_data`
---

Mọi hàm insert/validate phải theo đúng thứ tự:

1. **Parse input fields từ JSON**
2. **Tạo TEMP TABLE chứa bản ghi người dùng nhập**
3. **Tạo các TEMP TABLE xử lý bổ sung** (summary, grouping, lookup…)
4. **Tạo nhiều khối VALIDATION**
5. **Quy tắc thứ tự validation**
6. **Nếu fail → return JSON fail**
7. **Nếu pass → insert dữ liệu**
8. **Return JSON success**
9. **Exception block**

```sql
CREATE OR REPLACE FUNCTION schema.function_name(url_param jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    -- variable declarations and parse inputs
BEGIN
    -- main logic
    -- PARSE INPUT
    

    IF v_check_1 > 0 THEN
    RETURN jsonb_build_object('status','fail','error_message','<error 1>');

    RETURN
    jsonb_build_object(
    'status', 'ok',
    'message', '<tự điền theo yêu cầu>'
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

# ✅ **2. INPUT RULES**

* Hàm luôn nhận **json_input JSONB ARRAY**.
* Các giá trị bắt buộc phải parse từ **json_input->0**.

---

# ✅ **3. TEMP TABLE RULES (GENERIC)**

Mọi hàm dạng này phải có:

### **3.1. TEMP TABLE 1 — Raw Input**

* Chứa toàn bộ cột người dùng gửi lên.
* Cột nào optional phải dùng `NULLIF`.
* Cột nào numeric/date phải CAST sang đúng kiểu.
* Không thực hiện validation ở đây.

### **3.2. TEMP TABLE 2+ — Summary / Calculation**

Có thể có 1 hoặc nhiều TEMP TABLE tùy logic business, ví dụ:

* Tổng hợp theo một key
* Tính tổng số lượng/tổng tiền
* Ghép với bảng setting để lấy định mức
* Ghép với dữ liệu lịch sử

**Luật chung:**

* Mọi logic cần để validate đều phải tính trước bằng temp table.
* Tuyệt đối không validate trực tiếp từ raw JSON.

---

# ✅ **4. VALIDATION RULES (GENERIC)**

### **4.1. Validation phải được gom thành từng nhóm rõ ràng**

Ví dụ:

* Validation Group 1: Kiểm tra giới hạn (threshold)
* Validation Group 2: Kiểm tra tồn tại/trùng lặp
* Validation Group 3: Kiểm tra tính hợp lệ dữ liệu
* Validation Group 4: Kiểm tra cross-table constraint
* Validation Group 5: Kiểm tra tổng/định mức
* Validation Group 6: Kiểm tra quyền/authorization

**Không viết trực tiếp logic — chỉ áp dụng theo mô tả.**

---

### **4.2. Mỗi validation phải trả kết quả dạng boolean/INT**

Ví dụ dạng generic:

```sql
SELECT COUNT(*) INTO v_condition_X
FROM some_table
WHERE <condition>;
```

> AI sẽ tự thay `<condition>` theo logic bạn mô tả.

---

### **4.3. Validation priority rule**

Nếu bạn mô tả bài toán có nhiều validation, AI phải:

1. Sắp xếp từ high priority → low priority
2. Check theo đúng thứ tự
3. Dừng ngay khi một validation fail
4. Trả JSON fail rõ ràng

---

# ✅ **5. INSERT RULES**

* Chỉ insert nếu **tất cả** validation pass.
* Insert phải lấy dữ liệu từ **temp table raw input**, không phải từ JSON trực tiếp.
* Không bao giờ insert từng dòng bằng vòng lặp.

---

# ✅ **6. RETURN RULES**

### **6.1. SUCCESS FORMAT**

```sql
jsonb_build_object(
  'status', 'ok',
  'message', '<tự điền theo yêu cầu>'
)
```

### **6.2. FAIL FORMAT**

```sql
jsonb_build_object(
  'status', 'fail',
  'error_message', '<mỗi validation có 1 error riêng>'
)
```

### **6.3. EXCEPTION BLOCK (luôn có)**

```sql
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'fail',
        'error_message', SQLERRM
    );
```

---

# ✅ **7. NAMING RULES**

### **7.1. Biến**

* Prefix **p_*** → input parameters
* Prefix **v_*** → calculated variables
* Prefix **v_check_*** → validation flags

### **7.2. TEMP TABLES**

* `raw_input`
* `calc_*`
* `summary_*`
* `validate_*`

Tên do AI đặt theo mô tả của bạn, nhưng phải theo pattern.

---

# ✅ **8. GENERIC FUNCTION TEMPLATE (Không chứa logic business)**

```sql
CREATE OR REPLACE FUNCTION schema.fn_template(
    json_input jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    -- Parsed input variables
    p_field_1 TEXT;
    p_field_2 TEXT;

    -- Validation flags
    v_check_1 INT := 0;
    v_check_2 INT := 0;
    v_check_3 INT := 0;

    -- Calculated values
    v_value_1 NUMERIC;
BEGIN
    ------------------------------------------------------------------
    -- 1. PARSE INPUT
    ------------------------------------------------------------------
    SELECT json_input->0->>'field_1' INTO p_field_1;
    SELECT json_input->0->>'field_2' INTO p_field_2;

    ------------------------------------------------------------------
    -- 2. TEMP TABLE: RAW INPUT
    ------------------------------------------------------------------
    -- Parse toàn bộ JSON input thành bảng tạm
    CREATE TEMP TABLE input_raw ON COMMIT DROP AS (
        SELECT *
        FROM jsonb_populate_recordset(NULL::your_target_type, v_json_input)
    );

    -- Hoặc: parse các JSON ARRAY bên trong
    CREATE TEMP TABLE input_array ON COMMIT DROP AS (
        SELECT
            -- parse text
            (el ->> 'some_text')::TEXT AS some_text,

            -- parse number
            (el ->> 'some_number')::INT AS some_number,

            -- parse date / timestamp
            TO_DATE(el ->> 'some_date', 'DD-MM-YYYY')::TIMESTAMP AS some_date,

            -- parse bool
            (el ->> 'some_bool')::BOOLEAN AS some_bool
        FROM jsonb_array_elements(v_json_input -> 'array_key') AS el
    );
    ------------------------------------------------------------------
    -- 3. TEMP TABLE: CALCULATED DATA (GENERIC)
    ------------------------------------------------------------------
    CREATE TEMP TABLE calc_summary ON COMMIT DROP AS
    SELECT
        field_1,
        SUM(amount) AS total_amount
    FROM raw_input
    GROUP BY field_1;

    ------------------------------------------------------------------
    -- 4. VALIDATION BLOCKS (GENERIC RULES)
    ------------------------------------------------------------------
    -- Validation example (AI sẽ thay logic theo yêu cầu thật)
    SELECT COUNT(*) INTO v_check_1
    FROM calc_summary
    WHERE <condition_1>;   -- do AI tự điền

    SELECT COUNT(*) INTO v_check_2
    FROM calc_summary
    WHERE <condition_2>;

    SELECT COUNT(*) INTO v_check_3
    FROM some_lookup_table
    WHERE <condition_3>;

    ------------------------------------------------------------------
    -- 5. VALIDATION FLOW (ALWAYS FOLLOW THIS ORDER)
    ------------------------------------------------------------------
    IF v_check_1 > 0 THEN
        RETURN jsonb_build_object('status','fail','error_message','<error 1>');
    ELSIF v_check_2 > 0 THEN
        RETURN jsonb_build_object('status','fail','error_message','<error 2>');
    ELSIF v_check_3 > 0 THEN
        RETURN jsonb_build_object('status','fail','error_message','<error 3>');
    END IF;

    ------------------------------------------------------------------
    -- 6. INSERT IF VALID
    ------------------------------------------------------------------
    INSERT INTO target_table
    SELECT * FROM raw_input;

    ------------------------------------------------------------------
    -- 7. RETURN SUCCESS
    ------------------------------------------------------------------
    RETURN jsonb_build_object(
        'status','ok',
        'success_message','Insert thành công'
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status','fail',
        'error_message', SQLERRM
    );
END;
$$;
```