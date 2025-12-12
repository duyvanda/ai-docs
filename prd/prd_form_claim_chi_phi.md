Dựa trên cấu trúc file `prd_theo_doi_qua_tang.md` bạn cung cấp, cùng với phân tích chi tiết các file code React (`.jsx`) và hình ảnh Schema Database, dưới đây là **Product Requirements Document (PRD)** cho hệ thống **Quản Lý Claim Chi Phí & Công Tác Phí**.

-----

# Product Requirements Document (PRD)

## Hệ Thống Quản Lý Claim Chi Phí & Công Tác Phí (Cost Claim Management)

| Mục | Chi tiết |
| :--- | :--- |
| **Dự án** | Meraplion BI - Cost Claim Module |
| **Phiên bản** | 1.0 |
| **Ngày cập nhật** | 12/12/2025 |
| **Trạng thái** | Draft |

-----

## 1\. Tổng quan (Overview)

Hệ thống được xây dựng nhằm số hóa quy trình đăng ký, phê duyệt và thanh toán các khoản chi phí của khối Kinh doanh (Sales/TDV). Hệ thống bao gồm 2 mảng chính:

1.  **Chi phí Marketing/CSKH:** Quà tặng, mời cơm, hội nghị (Claim theo kế hoạch và gắn hóa đơn).
2.  **Công tác phí (CTP):** Phụ cấp đi lại, ăn uống, khách sạn (Claim theo chuyến công tác).

Dữ liệu được tích hợp với hệ thống BI để báo cáo và hệ thống kế toán (Misa) để lấy dữ liệu hóa đơn đầu vào.

-----

## 2\. Mục tiêu (Goals)

  * **Kiểm soát ngân sách:** Đảm bảo số tiền claim không vượt quá số kế hoạch đã được duyệt (`max_ke_hoach`).
  * **Minh bạch hóa:** Gắn kết chặt chẽ giữa khoản chi đăng ký (Plan) và hóa đơn thực tế (Invoice).
  * **Tự động hóa:** Giảm thiểu thao tác nhập liệu thủ công, tự động chia tách chi phí theo kênh (CLC/INS) và tính toán phụ cấp.
  * **Tối ưu hóa phê duyệt:** Cung cấp giao diện duyệt nhanh (Bulk approve) cho quản lý.

-----

## 3\. Đối tượng sử dụng (User Personas)

| Vai trò | Mô tả công việc trên hệ thống |
| :--- | :--- |
| **User (TDV/Sales)** | - Đăng ký kế hoạch chi phí (Quà tặng/Mời cơm).<br>- Gắn hóa đơn (Red Invoice) vào kế hoạch đã duyệt.<br>- Khai báo công tác phí (Di chuyển/Khách sạn). |
| **Manager/CRM** | - Xem xét và phê duyệt/từ chối kế hoạch.<br>- Điều chỉnh số tiền kế hoạch (nếu cần).<br>- Duyệt đề nghị thanh toán hóa đơn. |
| **Finance/Admin** | - Kiểm tra tính hợp lệ của hóa đơn.<br>- Xuất dữ liệu phục vụ hạch toán. |

-----

## 4. User Flow & UI Overview (Chi tiết quy trình)

### 4.1. Phân hệ Sales (TDV) - Đăng ký Kế hoạch Chi phí (Submit Plan)

**User Flow: Tạo mới phiếu đăng ký (Quà tặng/Mời cơm)**

1.  **Start:** User truy cập tab "Đăng ký Plan" (Route: `/formcontrol/form_claim_chi_phi`).
2.  **Input:** User nhập các thông tin vào Form:
    * **Kỳ chi phí:** Chọn tháng/năm (`timestamp` - *VD: 2025-10-01*).
    * **Loại quà:** Chọn "Quà tặng" hoặc "Giao tiếp - Mời cơm" (`text`).
    * **Nội dung (Dịp):** Chọn từ danh sách dropdown hoặc nhập tay nếu là TP/MT (`text`).
    * **Khách hàng (KH Chung):** Chọn từ dropdown (`text` - *VD: HCO123*).
    * **Bác sĩ (HCP):** Chọn HCP tương ứng (`text` - *VD: HCP001*).
    * **Kênh:** Chọn CLC, INS, hoặc CLC & INS (`text`). *Nếu chọn CLC & INS, hệ thống yêu cầu chọn tỷ lệ (5:5, 6:4...)*.
    * **Số kế hoạch:** Nhập số tiền dự kiến (`float8`).
3.  **Submit:**
    * User bấm nút "GỬI QL DUYỆT".
    * **Frontend Logic:** Nếu kênh là `CLC & INS`, FE tự động tách thành 2 dòng dữ liệu (1 dòng CLC, 1 dòng INS) dựa trên tỷ lệ đã chọn.
    * **Call API:** `insert_form_claim_chi_phi` (Method: POST).
4.  **Feedback:**
    * **Thành công:** Hiển thị Alert xanh: "Lưu dữ liệu thành công". Form tự động clear.
    * **Thất bại:** Hiển thị Alert đỏ kèm `error_message` từ server.

---

### 4.2. Phân hệ Quản lý (CRM/Manager) - Phê duyệt Kế hoạch

**User Flow: Duyệt hoặc Từ chối kế hoạch**

1.  **Start:** Manager truy cập tab "Duyệt Đề Xuất" (Route: `/formcontrol/form_claim_chi_phi_crm`).
2.  **Display:** Hệ thống load danh sách các khoản chi ở trạng thái `H` (New) thông qua API `get_form_claim_chi_phi_crm`.
3.  **Action (Điều chỉnh & Chọn):**
    * **Sửa tiền:** Manager có thể sửa ô "Số duyệt" (`float8`). *Lưu ý: FE chặn không cho nhập lớn hơn `max_ke_hoach`*.
    * **Chọn:** Tick vào checkbox ở đầu dòng các khoản muốn xử lý (`boolean`).
4.  **Submit:**
    * Manager bấm nút **CONFIRM** (Duyệt) hoặc **DENY** (Từ chối).
    * **Call API:** `insert_form_claim_chi_phi_crm` (Method: POST).
    * **Payload:** Gửi danh sách các records đã tick kèm trạng thái mới (`C`: Confirmed hoặc `R`: Rejected).
5.  **Feedback:** Reload lại bảng dữ liệu sau 2 giây.

---

### 4.3. Phân hệ Sales (TDV) - Gắn Hóa đơn (Mapping Invoice)

**User Flow: Chọn hóa đơn cho kế hoạch đã duyệt**

1.  **Start:** User truy cập tab "Gắn Hóa Đơn" (Route: `/formcontrol/form_claim_chi_phi_claimed`).
2.  **Display:**
    * Load danh sách kế hoạch đã duyệt (`Status = C`).
    * Load danh sách hóa đơn đỏ từ Misa (API: `get_form_claim_chi_phi_hoa_don_misa`).
3.  **Open Modal:** User bấm nút **HĐ** tại một dòng kế hoạch cụ thể.
4.  **Select Invoice (Trong Modal):**
    * User tìm kiếm hóa đơn (theo số HĐ, tên NCC).
    * User gạt nút Switch để chọn hóa đơn.
    * **Frontend Logic:** Tính tổng tiền các hóa đơn đang chọn (`total_amount`).
        * Nếu `total_amount` > `Số tiền duyệt`: Hiển thị Modal phụ yêu cầu nhập số tiền điều chỉnh (Cắt bớt tiền claim của hóa đơn đó).
5.  **Submit:**
    * User bấm nút "Xác nhận".
    * **Call API:** `insert_form_claim_chi_phi_hoa_don` (Method: POST).
    * **Data:** Chuyển trạng thái plan sang `I` (Invoiced) và lưu mapping vào bảng `form_claim_chi_phi_hoa_don`.
6.  **Feedback:** Đóng Modal và hiển thị thông báo thành công.

---

### 4.4. Phân hệ Admin/Finance - Duyệt Thanh Toán (Final Approve)

**User Flow: Chốt sổ thanh toán**

1.  **Start:** Admin truy cập tab "Duyệt Hóa Đơn" (Route: `/formcontrol/form_claim_chi_phi_crm_claimed`).
2.  **Display:** Load danh sách các khoản chi đã gắn hóa đơn (API: `get_form_claim_chi_phi_crm_claimed`).
3.  **Action:** Admin kiểm tra thông tin, tick chọn các khoản hợp lệ.
4.  **Submit:**
    * Bấm **CONFIRM** -> Trạng thái chuyển thành `D` (Done/Approved).
    * Hoặc bấm **DENY** -> Trạng thái chuyển thành `E` (Error/Edit).
    * **Call API:** `insert_form_claim_chi_phi_crm_claimed` (Method: POST).

---

### 4.5. Phân hệ Sales (TDV) - Công Tác Phí (Travel Expense)

**User Flow: Khai báo chuyến công tác**

1.  **Start:** User truy cập menu "Công tác phí" (Route: `/formcontrol/cong_tac_phi`).
2.  **Input:** User nhập form thông tin chung:
    * **Thời gian:** Từ ngày - Đến ngày (`date` - *yyyy-mm-dd*).
    * **Địa điểm:** Tỉnh/Thành phố (`text`).
    * **Phụ cấp:** Nhập tiền phụ cấp đi lại, ăn uống (`float8` - *User tự nhập*).
    * **Khoản mục:** Nhập text mô tả (`text`).
3.  **Select Invoice (Modal):**
    * Bấm "Chọn Hóa Đơn Vé Xe Hoặc KS".
    * Trong danh sách hóa đơn, tick chọn và phân loại:
        * Radio button: **Hotel** (Tính vào tổng KS).
        * Radio button: **Xe** (Tính vào tổng Vé xe).
4.  **Submit:**
    * User bấm "LƯU THÔNG TIN".
    * **Call API:** `insert_form_cong_tac_phi` (Method: POST).
    * **Payload:** Gửi object bao gồm thông tin chuyến đi (`form_cong_tac_phi`) và danh sách hóa đơn kèm loại chi phí (`lst_chon_invoices`).

-----

## 5\. Thiết kế Cơ sở dữ liệu (Database Schema)

Dựa trên hình ảnh cung cấp, cấu trúc database PostgreSQL như sau:

### Table 1: `form_claim_chi_phi` (Bảng chính lưu Plan)

Lưu trữ thông tin đăng ký chi phí quà tặng/mời cơm.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `id` | text | Primary Key (VD: CCP12345) |
| `status` | text | Trạng thái (New, Approved, Rejected...) |
| `manv` | text | Mã nhân viên |
| `chon_kh_chung` | text | Mã khách hàng tổng (HCO) |
| `chon_hcp` | text | Mã bác sĩ (HCP ID) |
| `so_ke_hoach` | float8 | Số tiền user đăng ký |
| `max_ke_hoach` | int4 | Ngân sách trần (nếu có logic tính toán) |
| `approved_so_ke_hoach` | float8 | Số tiền quản lý duyệt |
| `so_tien_claim_hoa_don` | float8 | Số tiền thực tế sau khi gắn hóa đơn |
| `ky_chi_phi_kt` | timestamp | Kỳ chi phí (Tháng/Năm) |
| `ty_le` | text | Tỷ lệ split (5:5, 6:4) nếu kênh đôi |
| `inserted_at` | timestamp | Ngày tạo |

### Table 2: `form_claim_chi_phi_hoa_don` (Bảng Invoice Mapping)

Lưu trữ thông tin chi tiết các hóa đơn được gắn vào từng khoản claim.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `khid` | text | Foreign Key trỏ về `form_claim_chi_phi.id` hoặc `form_cong_tac_phi.khid` |
| `id_duy_nhat_cua_hoa_don` | text | ID định danh hóa đơn (từ hệ thống Misa/Invoice) |
| `so_hoa_don` | text | Số hóa đơn đỏ |
| `tong_tien_thanh_toan` | float8 | Tổng trị giá hóa đơn |
| `so_tien_claim` | float8 | Số tiền được dùng để claim cho ID này |
| `cost_type` | text | Loại chi phí (Hotel/Transport) cho module CTP |
| `check_tm` | int2 | Cờ đánh dấu |

### Table 3: `form_cong_tac_phi` (Bảng Công tác phí)

Lưu trữ thông tin tờ trình công tác.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `khid` | text | Primary Key (VD: CTP...) |
| `manv` | text | Mã nhân viên |
| `tu_ngay` | timestamp | Ngày bắt đầu |
| `den_ngay` | timestamp | Ngày kết thúc |
| `phu_cap_di_lai` | float8 | Tiền phụ cấp đi lại |
| `phu_cap_an_uong` | float8 | Tiền phụ cấp ăn uống |
| `tong_tien_ve_xe` | float8 | Tổng tiền hóa đơn vé xe đã chọn |
| `tong_tien_khach_san` | float8 | Tổng tiền hóa đơn KS đã chọn |

-----

Vâng, với bộ **PostgreSQL Functions** bạn vừa cung cấp kết hợp với code **React** ban đầu, mình đã có **đầy đủ 100% thông tin** để viết chi tiết phần **API & Function Specifications**.

Dưới đây là phần tài liệu kỹ thuật chi tiết, mô tả chính xác Input/Output JSON dựa trên logic code PL/pgSQL bạn đã viết (đúng từng key và logic xử lý).

-----

## 6\. API & Function Specifications (Chi tiết kỹ thuật)

Hệ thống hoạt động theo mô hình: Frontend gọi API -\> API Gateway gọi Postgres Function -\> Trả về JSON.

### 5.1. Nhóm khởi tạo và đăng ký (Sales)

#### **Function:** `get_form_claim_chi_phi`

  * **Loại:** READ
  * **Mục đích:** Lấy dữ liệu master (KH, HCP, Info NV, Danh mục quà) để fill lên form đăng ký.
  * **Logic xử lý:**
    1.  Lấy thông tin phòng ban của nhân viên (`d_hr_dsns`).
    2.  Lấy danh sách Khách hàng (`view_list_hcp` hoặc `d_master_khachhang`) dựa trên `manv`.
    3.  Lấy danh mục `lst_noi_dung` (dịp tặng quà) từ bảng `form_claim_chi_phi_content_list`.
    4.  Trả về JSON tổng hợp.
  * **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR0673"
    }
    ```
  * **JSON Output:**
    ```json
    {
        "data_hcp": [
            {"ma_hcp_2": "HCP01", "ten_hcp": "Nguyen Van A", "hco_bv": "BV01", ...}
        ],
        "manv_info": [
            {"manv": "MR0673", "tencvbh": "Tran Van B", "phongdeptsummary": "CLC"}
        ],
        "data_kh_chung": [
            {"hco_bv": "BV01", "pubcustname": "Benh Vien X"}
        ],
        "lst_kenh": ["CLC & INS", "CLC", "INS", "PCL"],
        "lst_noi_dung": [...],
        "lst_noi_dung_giao_tiep": [...],
        "lst_loai_qua_tang": ["Quà tặng", "Giao tiếp - Mời cơm"]
    }
    ```

#### **Function:** `insert_form_claim_chi_phi`

  * **Loại:** WRITE
  * **Mục đích:** Sales tạo mới kế hoạch chi phí (Submit Form).
  * **Logic Validate:**
    1.  Kiểm tra khách hàng sinh nhật có ngày sinh không.
    2.  Kiểm tra `gift_history`: Dịp này khách đã nhận quà chưa (check bảng `gift_history`).
    3.  Kiểm tra `tong_tien_claim`: Có vượt định mức (2tr/HCP, 4tr/TP, 50tr/Khác) không.
    4.  Nếu thỏa mãn -\> Insert vào bảng `form_claim_chi_phi`.
  * **JSON Input (`body` - Array):**
    ```json
    [
        {
            "id": "CCP_AUTO_GEN",
            "status": "H",
            "manv": "MR0673",
            "chon_kh_chung": "BV01",
            "chon_hcp": "HCP01",
            "qua_tang": "Quà tặng",
            "kenh": "CLC",
            "noi_dung": "Chi phí quà tặng dịp sinh nhật",
            "so_ke_hoach": 500000,
            "ky_chi_phi_kt": "2025-10-01"
        }
    ]
    ```
  * **JSON Output:**
      * *Thành công:* `{"status": "ok", "success_message": "Đã nhận thành công"}`
      * *Lỗi:* `{"status": "fail", "error_message": "Dịp này khách hàng đã được nhận"}` (hoặc lỗi cụ thể khác).

-----

### 5.2. Nhóm phê duyệt kế hoạch (CRM)

#### **Function:** `get_form_claim_chi_phi_crm`

  * **Loại:** READ
  * **Mục đích:** CRM lấy danh sách các khoản chi chờ duyệt (Status = 'H').
  * **Logic:** Query bảng `form_claim_chi_phi` join với `d_users` để lấy danh sách nhân viên cấp dưới của `manv` đang login.
  * **JSON Input (`url_param`):**
    ```json
    {
        "manv": "AM001",
        "page": "approved"
    }
    ```
  * **JSON Output:**
    ```json
    {
        "chuc_danh": "Quan ly vung",
        "ten": "Nguyen Van Sep",
        "lst_chon_ke_hoach": [
            {
                "id": "CCP001",
                "status": "H",
                "manv": "MR0673",
                "tencvbh": "Tran Van B",
                "so_ke_hoach": 500000,
                "duyet_so_ke_hoach": 500000,
                "checked": true
            }
        ]
    }
    ```

#### **Function:** `insert_form_claim_chi_phi_crm`

  * **Loại:** WRITE
  * **Mục đích:** CRM xác nhận duyệt (C) hoặc từ chối (R).
  * **Logic:** Update bảng `form_claim_chi_phi` các trường `status`, `approved_so_ke_hoach`, `approved_manv`, `approved_at` dựa trên ID gửi lên.
  * **JSON Input (`body` - Array):**
    ```json
    [
        {
            "id": "CCP001",
            "status": "C",
            "manv": "AM001",
            "duyet_so_ke_hoach": 500000,
            "ghi_chu": "Ok duyet",
            "inserted_at": "2025-10-10 10:00:00"
        }
    ]
    ```
  * **JSON Output:** `{"status": "ok", "success_message": "Đã nhận thành công"}`

-----

### 5.3. Nhóm gắn hóa đơn (Sales)

#### **Function:** `get_form_claim_chi_phi_crm_approved`

  * **Loại:** READ
  * **Mục đích:** Lấy danh sách các Plan đã được duyệt (Status = 'C') để Sales tiến hành gắn hóa đơn.
  * **JSON Input (`url_param`):**
    ```json
    { "manv": "MR0673" }
    ```
  * **JSON Output:** `{"status": "ok", "lst_da_duyet": [...]}`

#### **Function:** `get_form_claim_chi_phi_hoa_don_misa`

  * **Loại:** READ
  * **Mục đích:** Lấy danh sách hóa đơn từ Misa (`d_misa_invoice`) chưa được claim hết tiền.
  * **Logic:** Tính toán `tien_con_lai` = `tong_tien_thanh_toan` - `so_tien_da_claim`. Chỉ lấy hóa đơn còn dư \> 10,000đ.
  * **JSON Input:** `{}` (Rỗng)
  * **JSON Output:**
    ```json
    {
        "lst_invoices": [
            {
                "id_duy_nhat_cua_hoa_don": "INV_XYZ",
                "so_hoa_don": "000123",
                "ten_nguoi_ban": "Cty ABC",
                "tong_tien_thanh_toan": 1000000,
                "tien_con_lai": 500000,
                "check": false
            }
        ]
    }
    ```

#### **Function:** `insert_form_claim_chi_phi_hoa_don`

  * **Loại:** WRITE
  * **Mục đích:** Mapping hóa đơn vào Plan.
  * **Logic Validate:**
    1.  Check `p_check_hoa_don`: Tổng tiền claim có vượt quá giá trị hóa đơn không.
    2.  Check `p_check_crs`: Hóa đơn này có bị người khác (NV khác) nhập chưa.
    3.  Nếu OK -\> Insert vào `form_claim_chi_phi_hoa_don` và Update `form_claim_chi_phi` (status -\> 'I').
  * **JSON Input (`body` - Array containing 1 Object):**
    ```json
    [
        {
            "khid": "CCP001",
            "manv": "MR0673",
            "status": "I",
            "lst_chon_invoices": [
                {
                    "id_duy_nhat_cua_hoa_don": "INV_XYZ",
                    "so_tien_claim": 500000,
                    "tong_tien_thanh_toan": 1000000,
                    "selected_time": "12-10-2025"
                }
            ]
        }
    ]
    ```
  * **JSON Output:** `{"status": "ok", "success_message": "Đã nhận thành công"}` (Hoặc lỗi tương ứng).

-----

### 5.4. Nhóm duyệt thanh toán (CRM)

#### **Function:** `get_form_claim_chi_phi_crm_claimed`

  * **Loại:** READ
  * **Mục đích:** CRM lấy danh sách các khoản đã gắn hóa đơn (Status = 'I') để duyệt chi.
  * **JSON Input (`url_param`):** `{"manv": "AM001"}`
  * **JSON Output:** `{"lst_duyet_hoa_don": [...]}`

#### **Function:** `insert_form_claim_chi_phi_crm_claimed`

  * **Loại:** WRITE
  * **Mục đích:** CRM chốt sổ thanh toán (Status -\> 'D' hoặc 'E').
  * **Logic:**
      * Update bảng `form_claim_chi_phi` (Status, Approved info).
      * Nếu Status = 'E' (Từ chối) -\> Xóa các record mapping trong `form_claim_chi_phi_hoa_don` để Sales làm lại.
  * **JSON Input (`body` - Array):**
    ```json
    [
        {
            "id": "CCP001",
            "status": "D",
            "manv": "AM001",
            "ghi_chu": "Duyet chi",
            "inserted_at": "..."
        }
    ]
    ```
  * **JSON Output:** `{"status": "ok", "success_message": "Đã nhận thành công"}`

-----

### 5.5. Nhóm Công tác phí & Báo cáo

#### **Function:** `insert_form_cong_tac_phi`

  * **Loại:** WRITE
  * **Mục đích:** Tạo tờ trình công tác phí và gắn hóa đơn (Xe/KS) cùng lúc.
  * **Logic:**
    1.  Insert vào bảng header `form_cong_tac_phi`.
    2.  Check xem hóa đơn đã được chọn bởi người khác chưa.
    3.  Insert vào bảng detail `form_claim_chi_phi_hoa_don` với `check_tm` = 1 (đánh dấu là CTP) và `cost_type` (hotel/transport).
  * **JSON Input (`body` - Array wrapper):**
    ```json
    [
        {
            "khid": "CTP_001",
            "manv": "MR0673",
            "tu_ngay": "2025-10-01", "den_ngay": "2025-10-02",
            "phu_cap_di_lai": 100000, "phu_cap_an_uong": 200000,
            "tong_tien_ve_xe": 500000, "tong_tien_khach_san": 1000000,
            "lst_chon_invoices": [
                {
                    "id_duy_nhat_cua_hoa_don": "INV_BUS",
                    "cost_type": "transport",
                    "so_tien_claim": 500000
                }
            ]
        }
    ]
    ```
  * **JSON Output:** `{"status": "ok", "success_message": "Đã nhận thành công"}`

#### **Function:** `get_form_claim_chi_phi_excel_form`

  * **Loại:** READ
  * **Mục đích:** Lấy dữ liệu thô (Raw Data) để Backend tạo file Excel báo cáo thanh toán.
  * **Logic:**
      * Tổng hợp dữ liệu từ 3 nguồn: Plan quà tặng (`lst_payment_1`), CTP phụ cấp (`lst_payment_2`), CTP hóa đơn (`lst_payment_3`).
      * Tính tổng tiền bằng số và bằng chữ (`utils_convert_number_to_vietnamese_text`).
  * **JSON Input:**
    ```json
    {
        "manv": "MR0673",
        "fromDate": "2025-10-01",
        "toDate": "2025-10-31"
    }
    ```
  * **JSON Output:**
    ```json
    {
        "status": "ok",
        "BMKT013": [...], // List chi tiết chi phí
        "BMKT002": [...], // List tổng hợp đề nghị thanh toán
        "tong_so_tien": "1,500,000",
        "so_tien_bang_chu": "Một triệu năm trăm ngàn đồng",
        "nguoi_de_nghi": "...",
        "department": "..."
    }
    ```