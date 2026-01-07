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
| **CXM (Giám đốc trải nghiệm)** | - Upload cấu hình.<br>- Xem danh sách các đề xuất đã được Quản lý vùng thông qua.<br>- Thực hiện phê duyệt cuối cùng hoặc Từ chối. |

-----

## 4. User Flow & UI Overview (Chi tiết quy trình)

### 4.0 Admin upload settings

Admin vô `/formcontrol/form_seminar_hco_settings` tải file mẫu và upload lên lại.

#### Up file excel 3 sheets và frontend xử lý như sau.

File Excel cấu hình đầu vào gồm **3 Sheets**. Frontend cần parse và gom tất cả dữ liệu vào trong một JSON Object `settings_data` duy nhất:

* **Sheet 1: "Cấu hình chung"**
  * Cột "Nhóm sản phẩm" -> Map vào key `list_nhom_san_pham_gioi_thieu` (Array String).
  * Cột "Địa điểm thực hiện" -> Map vào key `list_dia_diem_thuc_hien` (Array String).
  * Cột "Mục đích thực hiện" -> Map vào key `list_muc_dich_thuc_hien` (Array String).
  * Cột "Quy tắc chung" -> Map vào key `quy_tac_chung` (String). **Logic:** Đọc từng dòng trong cột này và ghép lại thành một chuỗi duy nhất, phân cách mỗi dòng bằng ký tự xuống dòng `\n`.

* **Sheet 2: "Định mức chi phí"**
  * Gồm các cột: *Mã chi phí, Tên hiển thị, Max chi phí*.
  * Mapping toàn bộ danh sách vào key -> `list_dinh_muc_chi_phi` (Array Object).

* **Sheet 3: "Phân bổ ngân sách"**
  * Gồm các cột: *Zone, NCRM, Mã nhân viên, Tên nhân viên, Định mức quỹ*.
  * Mapping toàn bộ danh sách vào key -> `list_phan_bo_ngan_sach` (Array Object).

* **Submit:**
  1. Gửi api `insert_form_seminar_hco_settings`

### 4.1. Phân hệ [Đề xuất] - [Tạo Đề Xuất Seminar]

#### User Flow: Gửi đề xuất mới

1. **Start:** User truy cập Tab "Đề xuất".
2. **Input & UI Logic:**
    * Hệ thống tải dữ liệu options qua API `get_form_seminar_hco_crs`.
    * **Logic chọn HCO:**
        * User tìm kiếm tên HCO (không dấu).
        * User chọn 1 HCO và 1 Khoa phòng cho mỗi lần.
    * **Các trường thông tin:**
        * `hco`: Danh sách Khoa/Phòng đã chọn.
        * `smn_thang`: Tháng thực hiện (Select).
        * `ngay_thuc_hien`: Ngày dd-mm-yyyy.
        * `nhom_san_pham`: Nhóm sản phẩm chính.
        * `so_luong_bs_ds`: Số lượng khách mời.
        * `dia_diem`, `muc_dich`: Text input.
        * `chi_phi_*`: 6 trường chi phí (Hội trường, Máy chiếu, Ăn uống, Teabreak, BCV, Tặng phẩm).
        * `danh_sach_hcp_bo_sung*`: Tên + BS
3. **Submit:**
    * User bấm "Gửi Đề Xuất".
    * Hệ thống tính tổng `tong_sl_nvyt` từ các options đã chọn.
    * Gộp ID khoa phòng thành chuỗi phân cách dấu phẩy.
    * **Call API:** `insert_form_seminar_hco` (Method: POST).
4. **Feedback:**
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


#### User Flow: Upload chứng từ & Chi phí thực tế

1.  **Start:** User truy cập Tab "**Chứng từ**".
2.  **Load Data & UI Logic:**
    * Hệ thống gọi API `get_form_seminar_hco_proof` lấy danh sách seminar cần báo cáo.
    * **Logic hiển thị (Filter):**
        * Sắp xếp: Mới nhất lên đầu.
    * **Giao diện (UI) - Card View:**
        * Mỗi Seminar hiển thị 1 Card tóm tắt: *Mã SMN - Ngày thực hiện - Tên HCO - Khoa/Phòng*.
        * Action: Nút "Cập nhật báo cáo".

3.  **Input Form (Action):**
    * User bấm vào Card để mở form nhập liệu.
    * **Phần 1: Nhập Chi phí thực tế (Actual Costs):**
        * User điền số tiền thực tế đã chi cho từng hạng mục (Mặc định hiển thị 0 hoặc số tiền dự kiến).
        * Các trường: `CP Hội trường`, `CP Máy chiếu`, `CP Ăn uống`, `CP Teabreak`, `CP Báo cáo viên`.
    * **Phần 2: Upload hình ảnh (Proof):**
        * User upload hình ảnh minh chứng (Hóa đơn, hình ảnh hội thảo...).
        * **Validation:** Bắt buộc upload **tối thiểu 01 hình ảnh**.

4.  **Submit:**
    * User bấm "**Lưu Báo Cáo**".
    * **Validation Frontend:**
        * Các trường chi phí thực tế phải >= 0.
        * Bắt buộc có ít nhất 1 hình ảnh.
    * **Call API:** Update thông tin vào database `insert_form_seminar_hco_proof`.

5.  **Feedback:**
    * **Thành công:** Thông báo "Cập nhật chứng từ thành công".
    * **Thất bại:** Hiển thị lỗi cụ thể.

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

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `id` | text | **PK** - Format: `YYYYMMDD...` |
| `manv` | text | Mã nhân viên tạo |
| `status` | text | `H` (New), `I` (Pending CXM), `C` (Completed), `R` (Rejected) |
| `hco` | text | Mã HCO (pubcustid) |
| `nganh_khoa_phong` | text | Danh sách khoa phòng (String, comma separated) |
| `tong_sl_nvyt` | int | Tổng số lượng NVYT tại các khoa phòng đã chọn |
| `smn_thang` | text | Tháng thực hiện (DD-MM-YYYY) |
| `ngay_thuc_hien` | date | Ngày thực hiện (ví dụ: 14-02-2025) |
| `nhom_san_pham` | text | Nhóm sản phẩm chính |
| `so_luong_bs_ds` | int | Số lượng khách mời dự kiến |
| `dia_diem` | text | Địa điểm tổ chức |
| `muc_dich` | text | Mục đích tổ chức |
| **--- KẾ HOẠCH (PLAN) ---** | | |
| `chi_phi_hoi_truong` | numeric | Chi phí |
| `chi_phi_may_chieu` | numeric | Chi phí |
| `chi_phi_an_uong` | numeric | Chi phí |
| `chi_phi_teabreak` | numeric | Chi phí |
| `chi_phi_bao_cao_vien` | numeric | Chi phí |
| `tang_pham` | numeric | Chi phí |
| **--- THỰC TẾ (ACTUAL) ---** | | *Các cột này null khi mới tạo, update khi báo cáo* |
| `thuc_te_chi_phi_hoi_truong` | numeric | Chi phí thực tế |
| `thuc_te_chi_phi_may_chieu` | numeric | Chi phí thực tế |
| `thuc_te_chi_phi_an_uong` | numeric | Chi phí thực tế |
| `thuc_te_chi_phi_teabreak` | numeric | Chi phí thực tế |
| `thuc_te_chi_phi_bao_cao_vien` | numeric | Chi phí thực tế |
| `hinh_anh_1` | text | **Link ảnh chứng từ 1** (Bắt buộc khi báo cáo) |
| `hinh_anh_2` | text | Link ảnh chứng từ 2 (Optional) |
| `hinh_anh_3` | text | Link ảnh chứng từ 3 (Optional) |
| `ngay_bao_cao` | timestamp | Thời gian user submit báo cáo thực tế |
| **--- SYSTEM ---** | | |
| `inserted_at` | timestamp | Thời gian tạo |
| `updated_at` | timestamp | Thời gian cập nhật |


### Table Cấu hình Hệ thống (Configuration Table)

**Table `settings_data`**
*Bảng cấu hình "All-in-One". Lưu trữ toàn bộ tham số vận hành (Danh mục, Định mức chi phí, Ngân sách nhân viên). Dữ liệu được cập nhật từ file Excel của Admin.*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `appid` | text | **PK** - Giá trị cố định: `form_seminar_hco` |
| `js` | jsonb | **Chứa toàn bộ data cấu hình** (Xem mẫu JSON chuẩn bên dưới) |
| `manv` | text | Mã nhân viên (Admin) thực hiện upload |
| `inserted_at` | timestamp | Thời gian thực hiện upload |

**Table 3: `form_seminar_hco_added_hcps` (Bảng Danh sách HCP bổ sung)**
Lưu trữ danh sách các HCP được nhân viên CRS (Client) chủ động bổ sung trong quá trình làm việc. Bảng này lưu chi tiết từng dòng dữ liệu thay vì JSON để phục vụ báo cáo/tracking.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `id` | text | **PK** - Mã định danh duy nhất (Client-generated ID). Ví dụ: `20251231_NV001_A`. |
| `manv` | text | Mã nhân viên thực hiện thao tác (Ví dụ: `NV001`). |
| `ten_hcp` | text | Họ và tên HCP. |
| `chuc_vu` | text | Chức vụ (Giá trị: Bác sĩ, Dược sĩ, Điều dưỡng...). |
| `inserted_at` | timestamp | Thời gian tạo bản ghi |

-----

## 6. API & Function Specifications (Chi tiết kỹ thuật)

Hệ thống sử dụng **PostgreSQL Stored Functions** nhận và trả về JSONB.

#### Function: `insert_form_seminar_hco_settings`

* **Loại:** WRITE (Configuration Upsert)
* **Mục đích:** Lưu trữ hoặc cập nhật cấu hình hệ thống cho Form đăng ký Seminar. Dữ liệu nguồn từ file Excel do Admin upload, được Frontend xử lý thành JSON trước khi gửi xuống Server.
* **Bảng ảnh hưởng:** `settings_data`.

* **Validation (Các quy tắc chặn lỗi):**  KHÔNG CẦN VALIDATION

* **JSON Input (`body`):**
    ```json
    {
        "appid": "form_seminar_hco",
        "manv": "ADMIN_01",
        "inserted_at": "2025-10-27 10:30:00",
        "settings_data": {
            "list_nhom_san_pham_gioi_thieu": [
                "ENT", "EYE", "ANTI", "GI", "DERMA", "ORAL CARE"
            ],
            "list_dia_diem_thuc_hien": [
                "Tại khoa", "Bên ngoài"
            ],
            "list_muc_dich_thuc_hien": [
                "Giới thiệu thông tin sản phẩm mới", 
                "Nhắc lại thông tin sản phẩm",
                "Commitment", 
                "Mesabi", 
                "SunoHada", 
                "ENT tập trung 2026", 
                "Nhập hàng"
            ],
            "list_dinh_muc_chi_phi": [
                { "ma_chi_phi": "hoi_truong", "ten_hien_thi": "Chi phí thuê hội trường", "max_chi_phi": 10000000 },
                { "ma_chi_phi": "may_chieu", "ten_hien_thi": "Chi phí thuê máy chiếu", "max_chi_phi": 1000000 },
                { "ma_chi_phi": "an_uong", "ten_hien_thi": "Chi phí ăn uống", "max_chi_phi": 5000000 },
                { "ma_chi_phi": "teabreak", "ten_hien_thi": "Teabreak", "max_chi_phi": 2000000 },
                { "ma_chi_phi": "bao_cao_vien", "ten_hien_thi": "Mời báo cáo viên", "max_chi_phi": 7000000 },
                { "ma_chi_phi": "tang_pham", "ten_hien_thi": "Tặng phẩm", "max_chi_phi": 450000 }
            ],
            "list_phan_bo_ngan_sach": [
                { "zone": "ZONE 1", "ncrm": "Ngô Tiến Vũ", "ma_nhan_vien": "MR1111", "ten_nhan_vien": "Bùi Hữu Toàn", "dinh_muc_quy": 50000000 },
                { "zone": "ZONE 2", "ncrm": "Hoàng Trung Thành", "ma_nhan_vien": "MR1116", "ten_nhan_vien": "Nguyễn Thị Dung", "dinh_muc_quy": 50000000 }
            ],
            "quy_tac_chung": "1/ Chỉ được chọn thực hiện SMN tại 1 khoa phòng\n2/ Số lượng NVYT tham dự là số lượng thực tế tham dự SMN\n3/ Các nội dung không có chi phí : điền số 0\n4/ Lưu ý chi phí teabreak: (lưu ý cần hình ảnh báo cáo bánh nước/ cơm phần)\n   - Bánh nước : ko quá 1 triệu , ko quá 100k/ người (1 phần bánh nước)\n   - Cơm phần : ko quá 2 triệu, ko quá 150k/ người\n5/ Định nghĩa mục đích thực hiện SMN"
        }
    }
    ```

* **Logic (PostgreSQL Function Logic):**
    Hàm thực hiện chiến lược **Upsert** (Update nếu tồn tại, Insert nếu chưa có) dựa trên `appid`.


* **JSON Output:**
    * **Thành công:**
        ```json
        { 
            "status": "ok", 
            "message": "Đã cập nhật cấu hình thành công!"
        }
        ```
    * **Thất bại:**
        ```json
        { "status": "fail", "error_message": "Lỗi database: ..." }
        ```


### 6.1. Nhóm Load Data & Submit Form

#### **Function:** `get_form_seminar_hco_crs`

* **Loại:** READ
* **Mục đích:** Lấy dữ liệu khởi tạo cho dropdowns (HCO, Tháng, Tuần, Sản phẩm) và check chức danh user.
* **Logic:**
    1. Lấy chức danh từ `d_hr_dsns`.
    2. Lấy list HCO từ `view_list_hcp` (Filter theo `concat_crs_sup` chứa `manv`).
    3. Lấy trong settings của appid này ra.
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
            { "value": "01-02-2025", "label": "02-2025" },
            { "value": "01-03-2025", "label": "03-2025" }
        ],
        // lấy từ settings
        "list_nhom_san_pham_gioi_thieu": [
            "ENT", "EYE", "ANTI", "GI", "DERMA", "ORAL CARE"
        ],
        "list_dia_diem_thuc_hien": [
            "Tại khoa", "Bên ngoài"
        ],
        "list_muc_dich_thuc_hien": [
            "Giới thiệu thông tin sản phẩm mới", 
            "Nhắc lại thông tin sản phẩm",
            "Commitment", 
            "Mesabi", 
            "SunoHada", 
            "ENT tập trung 2026", 
            "Nhập hàng"
        ],
        "chucdanhengtitlesum": "CRS",
        "time": "2025-12-31 10:00:00+07"
    }
    ```

#### **Function:** `insert_form_seminar_hco`

* **Loại:** WRITE (Insert)
* **Mục đích:** Tạo mới đề xuất seminar.
* **Validation:** Kiểm tra các mục chi phí có vượt quá chi phí cho phép không.
* **Logic:** 
    1. Sử dụng `jsonb_array_elements` để map JSON => CTE. 
    2. Insert vô bảng `form_seminar_hco`. 
    3. Insert vô bảng `form_seminar_hco_added_hcps` từ danh sách `danh_sach_bo_sung_ten_hcp`.
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
            "ngay_thuc_hien": "14-02-2025",
            "nhom_san_pham": "EYE",
            "so_luong_bs_ds": 10,
            // Cấu hình các lựa chọn cho Dropdown "Chức vụ" trong bảng thêm HCP
            "danh_sach_bo_sung_ten_hcp": [
                { "ten_hcp": "Nguyễn Văn A", "chuc_vu": "Bác sĩ" },
                { "ten_hcp": "Trần Thị B", "chuc_vu": "Dược sĩ" },
                { "ten_hcp": "Lê Văn C", "chuc_vu": "Điều dưỡng" }
            ],
            "dia_diem": "Hội trường A",
            "muc_dich": "Giới thiệu thuốc",
            "chi_phi_hoi_truong": 1000000,
            "chi_phi_may_chieu": 200000,
            "chi_phi_an_uong": 3000000,
            "chi_phi_teabreak": 500000,
            "chi_phi_bao_cao_vien": 2000000,
            "tang_pham": 450000,
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
    ```json
    {
        "status": "fail",
        "error_message": "Chi phí {xxx} đã vượt {xxx}, vui lòng nhập lại !!!"
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
                "ngay_thuc_hien": "13/12/2026",
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
                "ngay_thuc_hien": "13/12/2026",
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
* **Validation:** KHÔNG CÓ VALIDATION.
* **Logic:**
    1.  Tạo bảng tạm từ JSON input.
    2.  Update `status` và `inserted_at` vào bảng chính.
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

### 6.3. Nhóm Chứng từ & Báo cáo (Proof)

#### **Function:** `get_form_seminar_hco_proof`

* **Loại:** READ
* **Mục đích:** Lấy danh sách seminar **đang thực hiện** để báo cáo.
* **Logic:**
    1. Filter `manv` = Input `manv` (Lấy đơn chính chủ).
    2. Filter `status` = **'I'** (Chỉ lấy đơn đã được CXM duyệt).
    3. Sort `ngay_thuc_hien` DESC.
* **JSON Input:** 
```json 
    { "manv": "NV001" }
```
* **JSON Output:**
    ```json
    {
        "status": "ok",
        "data": [
            {
                "id": "20251231_NV001_A",
                "hco": "CUST01",
                "ten_hco": "BV Bạch Mai",
                "nganh_khoa_phong": "NOI_TIM_MACH",
                "ngay_thuc_hien": "14-02-2025",
                "smn_thang": "02-2025",
                "nhom_san_pham": "EYE",
                "dia_diem": "Hội trường A",
                "muc_dich": "Giới thiệu thuốc",
                "tong_cp_du_kien": 10000000,
                // Các trường này ban đầu sẽ null vì chưa báo cáo
                "thuc_te_chi_phi_hoi_truong": null,
                "thuc_te_chi_phi_may_chieu": null,
                "thuc_te_chi_phi_an_uong": null,
                "thuc_te_chi_phi_teabreak": null,
                "thuc_te_chi_phi_bao_cao_vien": null,
                "hinh_anh_1": null,
                "hinh_anh_2": null,
                "hinh_anh_3": null
            }
        ]
    }
    ```

#### **Function:** `insert_form_seminar_hco_proof`

* **Loại:** WRITE (UPSERT theo `id`)
* **Mục đích:** User cập nhật chi phí thực tế và đóng hồ sơ.
* **Validation:**: KHÔNG CẦN VALIDATION.
* **Logic:**
    1. Update các cột `thuc_te_*`.
    2. Update 3 cột ảnh `hinh_anh_1` (bắt buộc từ FE), `hinh_anh_2`, `hinh_anh_3`.
    3. Update `ngay_bao_cao`.
    4. **Quan trọng:** Update `status` = **'C'** (Completed/Finished).
* **JSON Input:** Array chỉ có 1 phần tử
    ```json
    [{
        "id": "20251231_NV001_A",
        "manv": "NV001",
        "thuc_te_chi_phi_hoi_truong": 1000000,
        "thuc_te_chi_phi_may_chieu": 200000,
        "thuc_te_chi_phi_an_uong": 3200000,
        "thuc_te_chi_phi_teabreak": 500000,
        "thuc_te_chi_phi_bao_cao_vien": 2000000,
        // Hình ảnh (Frontend đã validate hinh_anh_1 bắt buộc có)
        "hinh_anh_1": "https://storage.googleapis.com/bucket/img_bill_01.jpg", 
        "hinh_anh_2": "https://storage.googleapis.com/bucket/img_checkin.jpg",
        "hinh_anh_3": "",
        "ngay_bao_cao": "2025-12-31 10:00:00"
    }]
    ```
* **JSON Output:**
    ```json
    { "status": "ok", "message": "Báo cáo thành công! Hồ sơ đã hoàn tất." }
    ```