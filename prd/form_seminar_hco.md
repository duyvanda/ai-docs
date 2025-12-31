# Product Requirements Document (PRD)

## Module Quản lý Đề xuất & Phê duyệt Seminar HCO

## 1. Tổng quan (Overview)

Module này cho phép Trình dược viên (Sales Rep) tạo các đề xuất tổ chức hội thảo (Seminar) tại các cơ sở y tế (HCO), tính toán chi phí dự kiến và thực hiện quy trình phê duyệt 2 cấp (CRM -> CXM) để kiểm soát ngân sách.

Dữ liệu được tích hợp với:
* **Hệ thống nhân sự (HRM):** Xác thực chức danh (`d_hr_dsns`) để phân quyền duyệt.
* **Hệ thống khách hàng (DMS/CRM):** Lấy danh sách HCO, HCP (`view_list_hcp`) và thông tin khách hàng (`d_master_khachhang`).
* **Hệ thống doanh số (Sales):** Lấy dữ liệu doanh số lịch sử (`f_raw_data_sales_yoy`) để hỗ trợ ra quyết định.

-----

## 2. Mục tiêu (Goals)

* **[Mục tiêu 1]:** **Chuẩn hóa quy trình lập kế hoạch:** Đảm bảo nhân viên cung cấp đầy đủ thông tin về địa điểm, mục đích, nhóm sản phẩm và dự toán chi phí chi tiết trước khi gửi đề xuất.
* **[Mục tiêu 2]:** **Phân quyền duyệt tự động theo Role:** Hệ thống tự động định tuyến đề nghị dựa trên trạng thái và chức danh của người dùng (CRM hoặc CXM).
* **[Mục tiêu 3]:** **Hỗ trợ ra quyết định dựa trên dữ liệu:** Cung cấp số liệu doanh số (YTD) của HCO và nhóm sản phẩm ngay trên giao diện duyệt để quản lý đánh giá tính hiệu quả.

-----

## 3. Đối tượng sử dụng (User Personas)

| Vai trò | Mô tả công việc trên hệ thống |
| :--- | :--- |
| **User (Trình dược viên)** | - Tìm kiếm HCO, chọn Khoa/Phòng.<br>- Nhập thông tin kế hoạch, dự toán chi phí và gửi đề xuất mới chờ duyệt. |
| **CRM (Quản lý vùng)** | - Xem danh sách các đề xuất mới từ nhân viên trực thuộc.<br>- Duyệt để chuyển lên cấp tiếp theo hoặc Từ chối trả về. |
| **CXM (Giám đốc trải nghiệm)** | - Xem danh sách các đề xuất đã được Quản lý vùng thông qua.<br>- Thực hiện phê duyệt cuối cùng hoặc Từ chối. |

-----

## 4. User Flow & UI Overview (Chi tiết quy trình)

### 4.1. Phân hệ [Đề xuất] - [Tạo Đề Xuất Seminar]

**User Flow: Gửi đề xuất mới**

1.  **Start:** User truy cập Tab "Đề xuất".
2.  **Input & UI Logic:**
    * Hệ thống tải dữ liệu options qua API `get_form_seminar_hco_crs`.
    * **Logic chọn HCO:**
        * User tìm kiếm tên HCO (không dấu).
        * User có thể chọn nhiều Khoa/Phòng (Switch).
        * *Validation:* Hệ thống chặn nếu chọn các Khoa/Phòng thuộc các HCO khác nhau (Logic `unique_real_ids`).
    * **Các trường thông tin:**
        * `hco`: Danh sách Khoa/Phòng đã chọn.
        * `smn_thang`: Tháng thực hiện (Select).
        * `tuan_thuc_hien`: Tuần (W1-W4).
        * `nhom_san_pham`: Nhóm sản phẩm chính.
        * `so_luong_bs_ds`: Số lượng khách mời.
        * `dia_diem`, `muc_dich`: Text input.
        * `chi_phi_*`: 6 trường chi phí (Hội trường, Máy chiếu, Ăn uống, Teabreak, BCV, Tặng phẩm).
3.  **Submit:**
    * User bấm "Gửi Đề Xuất".
    * Hệ thống tính tổng `tong_sl_nvyt` từ các options đã chọn.
    * Gộp ID khoa phòng thành chuỗi phân cách dấu phẩy.
    * **Call API:** `insert_form_seminar_hco` (Method: POST).
4.  **Feedback:**
    * **Thành công:** Alert xanh "Đã nhận thông tin thành công", Reset form.
    * **Thất bại:** Alert đỏ hiển thị lỗi.

### 4.2. Phân hệ [Quản lý Duyệt] - [Duyệt/Từ chối]

**User Flow: Phê duyệt theo cấp**

1.  **Start:** User truy cập Tab "QL Duyệt".
2.  **Input & UI Logic:**
    * Gọi API `get_form_seminar_hco_cxm`.
    * **Logic hiển thị:**
        * Nếu User là CXM: Hiển thị đơn có Status `I`.
        * Nếu User là CRM (Khác): Hiển thị đơn có Status `H`.
    * **UI:** Hiển thị bảng chi tiết kèm cột `Tổng CP`, `DS Tổng HCO`, `DS Nhóm SP`.
3.  **Submit:**
    * User chọn (Switch) các đơn cần xử lý.
    * Bấm nút "**✅ DUYỆT**" hoặc "**❌ TỪ CHỐI**".
    * **Logic Status:**
        * Duyệt + CRM -> Status `I`.
        * Duyệt + CXM -> Status `C`.
        * Từ chối -> Status `R`.
    * **Call API:** `insert_form_seminar_hco_cxm` (Method: POST).
4.  **Feedback:**
    * Reload danh sách và hiển thị thông báo kết quả.

-----

## 5. Thiết kế Cơ sở dữ liệu (Database Schema)

### Các table có sẵn/bên ngoài (External Tables):

**Table `d_hr_dsns`** (Nhân sự)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `msnvcsmmoi` | text | **PK** - Mã nhân viên |
| `chucdanhengtitlesum` | text | Chức danh (Dùng để check Role CXM/CRM) |

**Table `view_list_hcp`** (Danh sách HCO/HCP)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `hco_bv` | text | Mã Bệnh viện |
| `nganh_khoa_phong` | text | Tên Khoa/Phòng |
| `concat_crs_sup` | text | Chuỗi phân cấp quản lý ví dụ NV1-SUP1 (Dùng để filter theo User) |

### Các table mới của hệ thống (New Tables):

**Table 1: `form_seminar_hco`**
*(Dựa trên keys của `jsonb_populate_recordset` trong function `insert_form_seminar_hco`)*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `id` | text | **PK** - Format: `YYYYMMDD...` |
| `manv` | text | Mã nhân viên tạo |
| `status` | text | `H` (New), `I` (Pending CXM), `C` (Completed), `R` (Rejected) |
| `hco` | text | Mã HCO (pubcustid) |
| `nganh_khoa_phong` | text | Danh sách khoa phòng (String, comma separated) |
| `tong_sl_nvyt` | int | Tổng số lượng NVYT tại các khoa phòng đã chọn |
| `smn_thang` | text | Tháng thực hiện (DD-MM-YYYY) |
| `tuan_thuc_hien` | text | Tuần thực hiện (W1, W2...) |
| `nhom_san_pham` | text | Nhóm sản phẩm chính |
| `so_luong_bs_ds` | int | Số lượng khách mời dự kiến |
| `dia_diem` | text | Địa điểm tổ chức |
| `muc_dich` | text | Mục đích tổ chức |
| `chi_phi_hoi_truong` | numeric | Chi phí |
| `chi_phi_may_chieu` | numeric | Chi phí |
| `chi_phi_an_uong` | numeric | Chi phí |
| `chi_phi_teabreak` | numeric | Chi phí |
| `chi_phi_bao_cao_vien` | numeric | Chi phí |
| `tang_pham` | numeric | Chi phí |
| `inserted_at` | timestamp | Thời gian tạo/cập nhật |

-----

## 6. API & Function Specifications (Chi tiết kỹ thuật)

Hệ thống sử dụng **PostgreSQL Stored Functions** nhận và trả về JSONB.

### 6.1. Nhóm Load Data & Submit Form

#### **Function:** `get_form_seminar_hco_crs`

* **Loại:** READ
* **Mục đích:** Lấy dữ liệu khởi tạo cho dropdowns (HCO, Tháng, Tuần, Sản phẩm) và check chức danh user.
* **Logic:**
    1.  Lấy chức danh từ `d_hr_dsns`.
    2.  Lấy list HCO từ `view_list_hcp` (Filter theo `concat_crs_sup` chứa `manv`).
    3.  Lấy list sản phẩm từ `f_raw_data_sales_yoy`.
* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "NV001"
    }
    ```
* **JSON Output Specification:**
    ```json
    {
        "status": "ok",
        "hco_options": [
            {
                "id": "CUST01@@NOI_TIM_MACH",
                "ten_gop_hco": "BV Bạch Mai - Nội Tim Mạch (15 HCPs)",
                "sl_nvyt": 15
            },
            {
                "id": "CUST02@@NGOAI_TIEU_HOA",
                "ten_gop_hco": "BV Việt Đức - Ngoại Tiêu Hóa (10 HCPs)",
                "sl_nvyt": 10
            }
        ],
        "smn_thang_options": [
            { "value": "01-02-2025", "label": "01-02-2025" },
            { "value": "01-03-2025", "label": "01-03-2025" }
        ],
        "tuan_thuc_hien_options": [
            { "value": "W1", "label": "Tuần 1" },
            { "value": "W2", "label": "Tuần 2" }
        ],
        "nhom_san_pham_options": [
            { "value": "EYE", "label": "EYE" },
            { "value": "ANTI", "label": "ANTI" }
        ],
        "chucdanhengtitlesum": "REP - ETHICAL",
        "time": "2025-12-31 10:00:00+07"
    }
    ```

#### **Function:** `insert_form_seminar_hco`

* **Loại:** WRITE (Insert)
* **Mục đích:** Tạo mới đề xuất seminar.
* **Logic:** Sử dụng `jsonb_populate_recordset` để map trực tiếp JSON vào bảng.
* **JSON Input (`body`):** *Array chỉ có duy nhất 1 phần tử*
    ```json
    [
        {
            "id": "20251231_NV001_A",
            "manv": "NV001",
            "status": "H",
            "hco": "CUST01",
            "nganh_khoa_phong": "NOI_TIM_MACH",
            "tong_sl_nvyt": 15,
            "smn_thang": "01-02-2025",
            "tuan_thuc_hien": "W1",
            "nhom_san_pham": "EYE",
            "so_luong_bs_ds": 10,
            "dia_diem": "Hội trường A",
            "muc_dich": "Giới thiệu thuốc",
            "chi_phi_hoi_truong": 1000000,
            "chi_phi_may_chieu": 200000,
            "chi_phi_an_uong": 3000000,
            "chi_phi_teabreak": 500000,
            "chi_phi_bao_cao_vien": 2000000,
            "tang_pham": 0,
            "inserted_at": "2025-12-31 08:00:00"
        }
    ]
    ```
* **JSON Output:**
    ```json
    {
        "status": "ok",
        "success_message": "Đã nhận thông tin thành công !!!"
    }
    ```

### 6.2. Nhóm Approval Flow (Duyệt)

#### **Function:** `get_form_seminar_hco_cxm`

* **Loại:** READ
* **Mục đích:** Lấy danh sách cần duyệt theo vai trò (CRM/CXM).
* **Logic Filter:**
    * Check `d_hr_dsns`: Nếu title chứa `%CXM%` -> Filter `status = 'I'`. Ngược lại -> Filter `status = 'H'`.
    * **Data Enrichment:** Join để lấy tên NV, tên HCO, và tính tổng doanh số (`ds_tong_hco`, `ds_nhom_sp_chinh`) từ `f_raw_data_sales_yoy`.
* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR1137"
    }
    ```
* **JSON Output Specification:**
    ```json
    {
        "status": "ok",
        "rows": 2,
        "chucdanhengtitlesum": "AREA MANAGER (CRM)",
        "data": [
            {
                "id": "20251231_NV001_A",
                "manv": "NV001",
                "status": "H",
                "hco": "CUST01",
                "ten_nhan_vien": "Nguyễn Văn A",
                "ten_hco": "BV Bạch Mai",
                "ds_tong_hco": 150000000,
                "ds_nhom_sp_chinh": 50000000,
                "nganh_khoa_phong": "NOI_TIM_MACH",
                "tong_sl_nvyt": 15,
                "smn_thang": "01-02-2025",
                "tuan_thuc_hien": "W1",
                "nhom_san_pham": "EYE",
                "so_luong_bs_ds": 10,
                "dia_diem": "Hội trường A",
                "muc_dich": "Giới thiệu thuốc",
                "chi_phi_hoi_truong": 1000000,
                "chi_phi_may_chieu": 200000,
                "chi_phi_an_uong": 3000000,
                "chi_phi_teabreak": 500000,
                "chi_phi_bao_cao_vien": 2000000,
                "tang_pham": 0,
                "inserted_at": "2025-12-31 08:00:00"
            },
            {
                "id": "20251231_NV001_B",
                "manv": "NV001",
                "status": "H",
                "hco": "CUST02",
                "ten_nhan_vien": "Nguyễn Văn A",
                "ten_hco": "BV Việt Đức",
                "ds_tong_hco": 200000000,
                "ds_nhom_sp_chinh": 80000000,
                "nganh_khoa_phong": "NGOAI_TIEU_HOA",
                "tong_sl_nvyt": 20,
                "smn_thang": "01-02-2025",
                "tuan_thuc_hien": "W2",
                "nhom_san_pham": "ANTI",
                "so_luong_bs_ds": 15,
                "dia_diem": "Phòng họp B",
                "muc_dich": "Training",
                "chi_phi_hoi_truong": 0,
                "chi_phi_may_chieu": 0,
                "chi_phi_an_uong": 2000000,
                "chi_phi_teabreak": 500000,
                "chi_phi_bao_cao_vien": 0,
                "tang_pham": 1000000,
                "inserted_at": "2025-12-31 09:00:00"
            }
        ]
    }
    ```

#### **Function:** `insert_form_seminar_hco_cxm`

* **Loại:** WRITE (Update Status)
* **Mục đích:** Cập nhật trạng thái duyệt/từ chối cho danh sách các đơn đã chọn.
* **Logic:**
    1.  Tạo bảng tạm từ JSON input.
    2.  Check Validation: Nếu ID không tồn tại -> Return Error.
    3.  Update `status` và `inserted_at` vào bảng chính.
* **JSON Input (`body`):** *Array 2 phần tử ví dụ*
    ```json
    [
        {
            "id": "20251231_NV001_A",
            "status": "I",
            "manv": "MANAGER_01",
            "inserted_at": "2025-12-31 10:00:00"
        },
        {
            "id": "20251231_NV001_B",
            "status": "R",
            "manv": "MANAGER_01",
            "inserted_at": "2025-12-31 10:00:00"
        }
    ]
    ```
* **JSON Output:**
    ```json
    {
        "status": "ok",
        "success_message": "Update successful."
    }
    ```