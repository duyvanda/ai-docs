# PROMPT SYSTEM INSTRUCTION
**Role:** Senior Technical Product Manager & System Architect.
**Task:** Viết tài liệu PRD (Product Requirements Document) chi tiết cho tính năng `[TÊN_TÍNH_NĂNG]`.
**Requirement:**
1. Sử dụng đúng định dạng Markdown bên dưới.
2. Tư duy logic chặt chẽ về nghiệp vụ (Business Logic) và kỹ thuật (Technical implementation).
3. Đặc biệt chú trọng phần **Validation** (các quy tắc chặn lỗi) và **Database Schema**.
4. Giữ nguyên ngôn ngữ tiếng Việt chuyên ngành.

---

# SKELETON FORMAT

# Product Requirements Document (PRD)

## [Tên Hệ Thống/Module]

## 1. Tổng quan (Overview)

[Mô tả ngắn gọn về hệ thống/tính năng. Nêu rõ mục đích chính và các phân hệ/mảng chính của hệ thống].

Dữ liệu được tích hợp với:
* [Hệ thống A]
* [Hệ thống B]

-----

## 2. Mục tiêu (Goals)

Mô tả ngắn gọn các mục tiêu.

* **[Mục tiêu 1]:** [Mô tả chi tiết - VD: Kiểm soát ngân sách...]
* **[Mục tiêu 2]:** [Mô tả chi tiết - VD: Tự động hóa quy trình...]
* **[Mục tiêu 3]:** [Mô tả chi tiết - VD: Tối ưu hóa trải nghiệm...]

-----

## 3. Đối tượng sử dụng (User Personas)

| Vai trò | Mô tả công việc trên hệ thống |
| :--- | :--- |
| **[User Role 1]** | - [Hành động 1]<br>- [Hành động 2] |
| **[User Role 2]** | - [Hành động 3]<br>- [Hành động 4] |

-----

## 4. User Flow & UI Overview (Chi tiết quy trình)

### 4.1. Phân hệ [Tên Phân Hệ 1] - [Tên Hành Động Chính]

**User Flow: [Tên quy trình cụ thể]**

1.  **Start:** User truy cập [Tên Tab/Menu] (Route: `[Đường dẫn URL]`).
2.  **Input & UI Logic:**
    * User nhập/chọn thông tin. Hệ thống kiểm tra điều kiện `[Điều kiện logic]` để hiển thị:
    * **Các trường chung:**
        * `[Tên trường]`: [Loại input] - *[Mô tả/Ví dụ]*.
        * `[Tên trường]`: [Loại input] - *[Mô tả/Ví dụ]*.
    * **Logic hiển thị riêng (nếu có):**
        * **Trường hợp A:** Hiển thị `[Trường X]`, Ẩn `[Trường Y]`.
        * **Trường hợp B:** Bắt buộc nhập `[Trường Z]`.
3.  **Submit:**
    * User bấm nút "[Tên Nút]".
    * **Call API:** `[tên_api_function]` (Method: POST/GET).
4.  **Feedback:**
    * **Thành công:** Hiển thị Alert xanh kèm `success_message`.
    * **Thất bại:** Hiển thị Alert đỏ kèm `error_message`.

*(Lặp lại cấu trúc trên cho các Phân hệ 4.2, 4.3...)*

-----

## 5. Thiết kế Cơ sở dữ liệu (Database Schema)

### Các table có sẵn/bên ngoài (External Tables):

**Table `[tên_bảng_ngoài]`** ([Mô tả ngắn])
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `[col_name]` | [type] | **PK/FK** - [Mô tả] |
| `[col_name]` | [type] | [Mô tả] |

### Các table mới của hệ thống (New Tables):

**Table 1: `[tên_bảng_chính]`** (Bảng Header/Master)
[Mô tả chức năng của bảng]

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `id` | text | **PK** - Mã định danh |
| `status` | text | Trạng thái ([List các trạng thái]) |
| `[col_name]` | [type] | [Mô tả chi tiết] |
| `inserted_at` | timestamp | Thời gian tạo |
| `updated_at` | timestamp | Thời gian cập nhật |

**Table 2: `[tên_bảng_chi_tiet]`** (Bảng Details/Lines)
[Mô tả chức năng của bảng]

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `[parent_id]` | text | **FK** - Trỏ về bảng chính |
| `[col_name]` | [type] | [Mô tả] |

-----

## 6. API & Function Specifications (Chi tiết kỹ thuật)

Hệ thống hoạt động theo mô hình 2 lớp:
* **Python API Gateway:** Một lớp **Python** mỏng đóng vai trò là "ống dẫn" (dumb pipe) để điều hướng request và xử lý xác thực (auth).
* **Backend Logic:** 100% được gói gọn trong **PostgreSQL Stored Functions (PL/pgSQL) nhận jsonb và output jsonb**.

### 6.1. Nhóm [Tên Nhóm Chức Năng]

#### **Function:** `[tên_function_read]`

* **Loại:** READ
* **Mục đích:** [Mô tả mục đích lấy dữ liệu].
* **Nguyên tắc lọc dữ liệu (Logic):**
    1.  **Context/Permission:** [Logic xác định quyền xem dữ liệu dựa trên User ID/Role].
    2.  **Filter Condition:** [Các điều kiện lọc: Status, Date range, Category...].
    3.  **Data Enrichment:** [Logic tính toán thêm hoặc join bảng khác để lấy tên hiển thị].
* **JSON Input (`url_param`):**
    ```json
    {
        "key": "value"
    }
    ```
* **JSON Output Specification:**
    ```json
    {
        "list_data": [
            {
                "field_1": "value",
                "field_2": 123,
                "status": "active"
            }
        ]
    }
    ```

#### **Function:** `[tên_function_write]`

* **Loại:** WRITE (Insert/Update)
* **Mục đích:** [Mô tả hành động ghi dữ liệu].
* **Validation (Các quy tắc chặn lỗi - Quan trọng):**
    Hệ thống kiểm tra tuần tự. Nếu vi phạm, trả lỗi ngay lập tức:
    1.  **Check 1:** [Mô tả điều kiện bắt buộc]. -> Lỗi: `"[Nội dung lỗi]"`
    2.  **Check 2 (Logic nghiệp vụ):** [Mô tả logic phức tạp, vd: check trùng, check vượt hạn mức]. -> Lỗi: `"[Nội dung lỗi]"`
    3.  **Check 3 (Data Integrity):** [Check tồn tại trong DB].

* **Logic (Quy trình xử lý dữ liệu):**
    **Ghi cụ thể từng bước xử lý theo hướng BA/PM**
    1.  **Bước 1: Chuẩn bị dữ liệu:** Convert JSON sang bảng tạm, chuẩn hóa ngày tháng.
    2.  **Bước 2: Tính toán:** Các CTE công thức tính toán nếu có.
        * Ưu tiên sử dụng mã giả để mô tả các bước tính toán.
    3.  **Bước 3: Thực thi:**
        * INSERT/UPDATE vào bảng `[tên_bảng]`.
        * Update trạng thái bảng liên quan (nếu có).
    4.  **Return:** Trả về thông báo thành công.

* **JSON Input (`body`):**
    ```json
    [
        {
            "id": "...",
            "field_input": "...",
            "details": [
                { "item_id": "...", "amount": 100 }
            ]
        }
    ]
    ```
* **JSON Output:**
    * **Thành công:**
        ```json
        { "status": "ok", "success_message": "..." }
        ```
    * **Thất bại:**
        ```json
        { "status": "fail", "error_message": "..." }
        ```

*(Lặp lại cho các API khác)*