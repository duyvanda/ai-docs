# ✅ **1. STRUCTURE RULES — KHUNG CỐ ĐỊNH CỦA MỌI HÀM**

## **Quy tắc chung**
* Không dùng vòng lặp (loop) trừ khi được yêu cầu.
* Nếu không yêu cầu validation thì không cần block validation.

### **Quy tắc đặt tên**
* snake_case
* có prefix theo domain
  * `insert_` → thêm, thường thêm vào 1 bảng
👉 Ví dụ:
`insert_form_data`

### **Quy tắc comments**
* Sử dụng **Block Comment** `/* ... */` cho mọi giải thích.

---

## Quy trình xử lý dữ liệu (Step-by-step)

### 1. Parse Input
- Parse các input fields từ **JSON request**

### 2. Tạo Temporary Table (Input)
- Tạo **TEMP TABLE** chứa:
  - Dữ liệu người dùng nhập
  - Data enrichment (nếu có)

### 3. Validate Input
- Validate dữ liệu đầu vào của người dùng:
  - Kiểu dữ liệu
  - Giá trị hợp lệ
  - Ràng buộc nghiệp vụ cơ bản

### 4. Tạo Temporary Table bổ sung (nếu có)
- Dùng cho:
  - Summary
  - Grouping
  - Lookup
- **Không sử dụng subquery trong SELECT block**

### 5. Xử lý Logic theo từng bước
- Thực hiện logic theo thứ tự:
  - Bước 1 → Bước 2 → Bước 3

#### 5.1. Các khối Validation Logic
- Kiểm tra nghiệp vụ nâng cao, ví dụ:
  - Tổng giá trị không được vượt giới hạn
  - Điểm đã được cộng hay chưa
  - Trạng thái dữ liệu có hợp lệ không

### 6. Xử lý khi Validate Fail
- Dừng xử lý
- **Return JSON với trạng thái `fail`**
- Kèm message lỗi chi tiết

### 7. Xử lý khi Validate Pass
- Thực hiện **INSERT dữ liệu** vào bảng chính

### 8. Return kết quả thành công
- **Return JSON với trạng thái `success`**
- Kèm dữ liệu hoặc message cần thiết

### 9. Exception Handling
- Bắt toàn bộ exception
- Log lỗi
- Return JSON lỗi hệ thống

```sql
CREATE OR REPLACE FUNCTION schema.function_name(url_param jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    */variable declarations and parse inputs
BEGIN

    /*
    main logic
    PARSE INPUT
    */
    SELECT json_input->0->>'field_1' INTO p_field_1;

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

Ví dụ dạng generic:

```sql
SELECT COUNT(*) INTO v_condition_X
FROM some_table
WHERE <condition>;
```

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

---

# ✅ **8. GENERIC FUNCTION TEMPLATE**

```sql
CREATE OR REPLACE FUNCTION schema.fn_template(
    json_input jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    /* user input*/
    p_field_1 TEXT;
    p_field_2 TEXT;

    /* validation flag*/
    v_check_1 INT := 0;
    v_check_2 INT := 0;
    v_check_3 INT := 0;

    /* Calculated values*/
    v_value_1 NUMERIC;
BEGIN
    /* ==============================================================
       1. PARSE INPUT FIELDS TỪ JSON
       ============================================================== */
    SELECT json_input->0->>'field_1' INTO p_field_1;
    SELECT json_input->0->>'field_2' INTO p_field_2;

    /* ==============================================================
       2. TẠO TEMP TABLE CHỨA BẢN GHI NGƯỜI DÙNG NHẬP
          + DATA ENRICHMENT (NẾU CÓ)
       ============================================================== */
    CREATE TEMP TABLE input_raw ON COMMIT DROP AS (
        SELECT *
        FROM jsonb_populate_recordset(NULL::your_target_type, v_json_input)
    );

    /* Hoặc: parse các JSON ARRAY bên trong sử dụng jsonb_array_elements */
    CREATE TEMP TABLE input_array ON COMMIT DROP AS (
        SELECT
            /* parse text */
            (el ->> 'some_text')::TEXT AS some_text,

            /* parse number */
            (el ->> 'some_number')::INT AS some_number,

            /* parse date / timestamp */
            TO_DATE(el ->> 'some_date', 'DD-MM-YYYY')::TIMESTAMP AS some_date,

        FROM jsonb_array_elements(v_json_input -> 'array_key') AS el
    );

    /* ==============================================================
       3. VALIDATE INPUT CỦA NGƯỜI DÙNG
       ============================================================== */

        SELECT COUNT(*)
        INTO v_check_1
        FROM input_raw
        WHERE some_required_field IS NULL;

    /* ==============================================================
       4. TẠO CÁC TEMP TABLE XỬ LÝ BỔ SUNG (NẾU CÓ)
          (summary, grouping, lookup…)
          LƯU Ý: KHÔNG DÙNG SUBQUERY TRONG SELECT
       ============================================================== */
    CREATE TEMP TABLE calc_summary ON COMMIT DROP AS
    SELECT
        field_1,
        SUM(amount) AS total_amount
    FROM raw_input
    GROUP BY field_1;

    /* ==============================================================
       4. XỬ LÝ STEP-BY-STEP LOGIC
          (BƯỚC 1 → BƯỚC 2 → BƯỚC 3)
       ============================================================== */
    
    /* Bước 1: kiểm tra tổng giá trị */
    SELECT COUNT(*)
    INTO v_check_2
    FROM calc_summary
    WHERE total_amount > 1000000;

    /* Bước 2: kiểm tra trạng thái đã xử lý hay chưa */
    SELECT COUNT(*)
    INTO v_check_3
    FROM some_lookup_table
    WHERE status = 'DONE';

    /* ==========================================================
        6. NẾU FAIL → RETURN JSON FAIL
        ========================================================== */

    RETURN jsonb_build_object(
        'status', 'fail',
        'error_message', '<Cụ thể lý do fail>'
    );

    /* ==============================================================
       7. NẾU PASS → INSERT DỮ LIỆU
       ============================================================== */
    INSERT INTO target_table
    SELECT *
    FROM input_raw;

    /* ==============================================================
       8. RETURN JSON SUCCESS
       ============================================================== */
    RETURN jsonb_build_object(
        'status', 'success',
        'message', 'Xử lý dữ liệu thành công'
    );

        /* ==============================================================
       9. EXCEPTION BLOCK
       ============================================================== */

    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'status','fail',
            'error_message', SQLERRM
        );
    END;
$$;
```