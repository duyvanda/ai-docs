# Product Requirements Document (PRD)

## Hệ Thống Quản Lý Claim Chi Phí & Công Tác Phí (Cost Claim Management)

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

-----

## 4. User Flow & UI Overview (Chi tiết quy trình)

### 4.1. Phân hệ Sales (TDV) - Đăng ký Kế hoạch Chi phí (Submit Plan)

**User Flow: Tạo mới phiếu đăng ký (Quà tặng/Mời cơm)**

1.  **Start:** User truy cập tab "Đăng ký Plan" (Route: `/formcontrol/form_claim_chi_phi`).
2.  **Input & UI Logic:** User nhập thông tin vào Form. Hệ thống sẽ **kiểm tra phòng ban** (`phongdeptsummary`) để hiển thị các trường nhập liệu phù hợp:

    * **Các trường chung (Luôn hiển thị):**
        * `Kỳ chi phí`: Chọn tháng/năm (`timestamp` - *VD: 2025-10-01*).
        * `Loại quà`: Chọn "Quà tặng" hoặc "Giao tiếp - Mời cơm" (`text`).
        * `Khách hàng (KH Chung)`: Chọn từ dropdown (`text` - *VD: HCO123*).
        * `Số kế hoạch`: Nhập số tiền dự kiến (`float8`).

    * **Logic hiển thị riêng theo Phòng ban:**
        * **Trường hợp 1: Nhóm TP hoặc MT (Trade/Marketing):**
            * `Người tiếp`: **Hiển thị** ô nhập liệu text "Họ và Tên người tiếp", **bắt buộc** nhập.
            * `Nội dung`: Cho phép **nhập tay** (Textarea) thay vì chọn danh sách.
            * `Bác sĩ (HCP)`: **Ẩn** hoặc **Disable** dropdown (Do làm việc với người tiếp cụ thể hoặc KH chung).
            * `Kênh`: Tự động set theo phòng ban, ẩn dropdown chọn kênh.

        * **Trường hợp 2: Nhóm Sales thường (Không phải TP/MT):**
            * `Người tiếp`: **Ẩn** ô nhập liệu này.
            * `Nội dung`: Bắt buộc **chọn từ Dropdown** (Danh sách định sẵn).
            * `Bác sĩ (HCP)`: **Hiển thị** dropdown, bắt buộc chọn HCP tương ứng.
            * `Kênh`: **Hiển thị** dropdown cho phép chọn (CLC, INS, PCL, hoặc CLC & INS).
                * *Lưu ý:* Nếu chọn `CLC & INS`, hiển thị thêm ô chọn `Tỷ lệ` (5:5, 6:4...).

3.  **Submit:**
    * User bấm nút "GỬI QL DUYỆT".
    * **Call API:** `insert_form_claim_chi_phi` (Method: POST).
4.  **Feedback:**
    * **Thành công:** Hiển thị Alert xanh: kèm `success_message` từ server. Form tự động clear.
    * **Thất bại:** Hiển thị Alert đỏ kèm `error_message` từ server.

---

### 4.2. Phân hệ Quản lý (CRS/CRM) - Phê duyệt Kế hoạch

**User Flow: Duyệt hoặc Từ chối kế hoạch**

1.  **Start:** CRS/CRM truy cập tab "Duyệt Đề Xuất" (Route: `/formcontrol/form_claim_chi_phi_crm`).
2.  **Display:** Hệ thống load danh sách các khoản chi ở trạng thái `H` (New) thông qua API `get_form_claim_chi_phi_crm`.
3.  **Action (Điều chỉnh & Chọn):**
    * **Sửa tiền:** Manager có thể sửa ô "Số duyệt" (`float8`). *Lưu ý: FE chặn không cho nhập lớn hơn `max_ke_hoach`*.
    * **Chọn:** Tick vào checkbox ở đầu dòng các khoản muốn xử lý (`boolean`).
4.  **Submit:**
    * Có phân quyền được duyệt dựa trên chức danh. CRM thì DUYỆT/DENY. CRS thì chỉ DENY.
    * CRM bấm nút **CONFIRM** (Duyệt) hoặc **DENY** (Từ chối) hoặc XÓA.
    * CRS bấm nút **DENY**. Không có quyền duyệt.
    * **Call API:** `insert_form_claim_chi_phi_crm` (Method: POST).
    * **Payload:** Gửi danh sách các records đã tick kèm trạng thái mới (`C`: Confirmed hoặc `R`: Rejected) hoặc `X`: Xóa.
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

## 5. Thiết kế Cơ sở dữ liệu (Database Schema)

Hệ thống sử dụng PostgreSQL với 4 bảng dữ liệu chính để quản lý quy trình Claim chi phí và Công tác phí.

### Các table có sẵn của nền tảng: 

## Table `d_hr_dsns` (bảng dữ liệu nhân sự)

Lưu trữ thông tin nhân sự.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `msnvcsmmoi` | text | **PK** - Mã định danh (VD: CCP_202510_MR123) |
| `phongdeptsummary` | text | Phòng bạn của nhân viên TP, MT, INS, etc |
| `chucdanhengtitlesum` | text | Chức danh của nhân viên |
| `hovatenfullname` | text | Tên của nhân viên |

### Table: `d_users` (Danh sách User & Phân quyền)
Bảng quản lý thông tin cây phân cấp nhân sự, được sử dụng để xác định cấp trên (`supid`) phục vụ logic phân quyền duyệt.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `manv` | text | **PK** - Mã nhân viên (Khớp với `d_hr_dsns`) |
| `supid` | text | **Permission** - Mã nhân viên của người quản lý trực tiếp (Line Manager) |

## View: `view_list_hcp` (Danh sách Bác sĩ & Phân quyền) View tổng hợp thông tin Bác sĩ/Dược sĩ (HCP) và thông tin phân công địa bàn. Đây là nguồn dữ liệu chính để lọc danh sách bác sĩ cho nhân viên Sales kênh HCP.

| Column Name | Data Type | Description |
| --- | --- | --- |
| `ma_hcp_2` | text | **PK** - Mã định danh duy nhất của HCP (VD: HCP1000001734-P) |
| `ten_hcp` | text | Họ và tên Bác sĩ / Dược sĩ |
| `hco_bv` | text | Mã Bệnh viện / Phòng khám nơi HCP công tác |
| `pubcustname` | text | Tên Bệnh viện / Phòng khám hiển thị |
| `kenh_lam_viec` | text | Kênh hoạt động (CLC, INS, PCL...) |
| `concat_crs_sup` | text | **Permission Column** - Chuỗi chứa danh sách mã nhân viên và quản lý phụ trách HCP này (VD: "MR0673,SUP001"). Hệ thống dùng hàm `strpos` để kiểm tra quyền truy cập. |
| `status` | text | Trạng thái hoạt động (`active` / `inactive`) |

## Table: `d_master_khachhang` (Danh sách Khách hàng Tổ chức)Bảng Master Data chứa danh sách Bệnh viện, Nhà thuốc, Phòng khám (HCO). Dùng để lọc khách hàng cho nhân viên Sales kênh OTC/ETC (TP, MT) hoặc lấy thông tin khách hàng chung.

| Column Name | Data Type | Description |
| --- | --- | --- |
| `custid` | text | **PK** - Mã khách hàng (VD: 000214) |
| `custname` | text | Tên khách hàng (VD: BV QUẬN TÂN PHÚ - SG) |
| `mnv_supid` | text | **Permission Column** - Chuỗi kết hợp Mã NV và Mã SUP (VD: "MR0673,SUP001"). Dùng để xác định nhân viên nào được phép làm việc với khách hàng này. |
| `channel` | text | Kênh bán hàng (Hospital, Pharmacy, Wholesaler...) |
| `province` | text | Tỉnh/Thành phố của khách hàng (Hỗ trợ lọc theo vùng) |

## Table: `d_tracking_cost_hcp_v2` (Lịch sử chi phí Marketing)Đây là bảng dữ liệu lịch sử được đồng bộ từ hệ thống Marketing, lưu trữ các khoản chi phí đã thực hiện cho từng HCP trong quá khứ. Bảng này được dùng để tính toán định mức "Ngân sách còn lại" (đặc biệt là cho quà Sinh nhật) nhằm tránh chi vượt trần.

| Column Name | Data Type | Description |
| --- | --- | --- |
| `id` | text | **PK** - Mã định danh khoản chi |
| `ma_hcp_2` | text | Mã định danh HCP (Dùng để map với `view_list_hcp`) |
| `ten_hcp` | text | Tên Bác sĩ |
| `hoat_dong` | text | Tên hoạt động/chương trình (VD: "Quà tặng sinh nhật 2024", "Hội nghị A") |
| `chi_phi_thuc_hien_dong` | float8 | Số tiền thực tế đã chi |
| `nam_thuc_hien` | int4 | Năm ghi nhận chi phí (VD: 2025) |
| `thang_thuc_hien` | int4 | Tháng ghi nhận chi phí |

### Table: `d_misa_invoice` (Hóa đơn điện tử)
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `id_duy_nhat_cua_hoa_don` | text | **PK** - GUID định danh hóa đơn |
| `so_hoa_don` | text | Số hóa đơn |
| `ngay_hoa_don` | timestamp | Ngày xuất hóa đơn |
| `ten_nguoi_ban` | text | Tên đơn vị bán |
| `tong_tien_thanh_toan` | float8 | Tổng giá trị hóa đơn |

---

### Table 1: `form_claim_chi_phi` (Bảng chính - Kế hoạch quà tặng/Mời cơm)

Lưu trữ thông tin đăng ký kế hoạch chi phí (Plan).

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `id` | text | **PK** - Mã định danh (VD: CCP_202510_MR123) |
| `status` | text | Trạng thái (H: New, C: Confirmed, R: Rejected, I: Invoiced, D: Done, E: Error) |
| `manv` | text | Mã nhân viên tạo plan |
| `tencvbh` | text | Tên nhân viên (Denormalized) |
| `phongdeptsummary` | text | Phòng ban (CLC / INS / PCL...) |
| `chon_kh_chung` | text | Mã khách hàng tổng (HCO) |
| `pubcustname` | text | Tên khách hàng tổng |
| `chon_hcp` | text | Mã bác sĩ (HCP ID) |
| `ten_hcp` | text | Tên bác sĩ |
| `nguoi_tiep` | text | **Họ tên người tiếp (Dành cho nhóm TP/MT)** |
| `qua_tang` | text | Phân loại: "Quà tặng" hoặc "Giao tiếp - Mời cơm" |
| `kenh` | text | Kênh chi phí (CLC, INS, PCL, CLC & INS) |
| `ty_le` | text | Tỷ lệ split (5:5, 6:4...) nếu kênh là CLC & INS |
| `noi_dung` | text | Nội dung chi tiết |
| `ghi_chu` | text | Ghi chú bổ sung |
| `ma_dip` | text | Mã dịp quà tặng (Map với Table 4) |
| `so_ke_hoach` | float8 | Số tiền user đăng ký |
| `max_ke_hoach` | int4 | Ngân sách trần cho phép |
| `thang_chi_phi` | timestamp | Tháng ghi nhận chi phí thực tế |
| `ky_chi_phi_kt` | timestamp | Kỳ kế toán (Ngày đầu tháng) |
| `inserted_at` | timestamp | Thời gian tạo bản ghi |
| `approved_manv` | text | Mã quản lý duyệt |
| `approved_at` | timestamp | Thời gian quản lý duyệt |
| `approved_so_ke_hoach` | float8 | Số tiền quản lý duyệt |
| `so_tien_claim_hoa_don` | float8 | Tổng số tiền đã gắn hóa đơn thực tế |
| `claim_approved_at` | timestamp | Thời gian Finance/Admin duyệt thanh toán |

---

### Table 2: `form_claim_chi_phi_hoa_don` (Bảng Chi tiết Hóa đơn)

Lưu trữ mapping giữa Hóa đơn thực tế và Khoản chi (dùng chung cho cả Plan và Công tác phí).

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `khid` | text | **FK** - Trỏ về `form_claim_chi_phi.id` hoặc `form_cong_tac_phi.khid` |
| `id_duy_nhat_cua_hoa_don` | text | ID định danh duy nhất của hóa đơn (từ Misa/Invoice) |
| `ten_nguoi_ban` | text | Tên nhà cung cấp / đơn vị bán hàng |
| `so_hoa_don` | text | Số hóa đơn đỏ |
| `ngay_hoa_don` | timestamp | Ngày ghi trên hóa đơn |
| `tong_tien_thanh_toan` | float8 | Tổng trị giá gốc của hóa đơn |
| `so_tien_claim` | float8 | Số tiền trích ra từ hóa đơn để thanh toán cho `khid` này |
| `selected_time` | timestamp | Thời điểm user thực hiện thao tác chọn hóa đơn |
| `check_tm` | int2 | Cờ phân loại: `0` (Plan quà tặng), `1` (Công tác phí) |
| `manv` | text | Mã nhân viên thực hiện thao tác |
| `cost_type` | text | Loại chi phí CTP (Chỉ dùng khi check_tm=1): `hotel` hoặc `transport` |

---

### Table 3: `form_cong_tac_phi` (Bảng Header - Công tác phí)

Lưu trữ tờ trình công tác (Header). Chi tiết hóa đơn vé xe/khách sạn được lưu ở Table 2.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `khid` | text | **PK** - Mã tờ trình (VD: CTP_202510_MR123) |
| `manv` | text | Mã nhân viên đi công tác |
| `ky_chi_phi_kt` | timestamp | Kỳ tính chi phí (Tháng/Năm) |
| `tu_ngay` | timestamp | Ngày bắt đầu chuyến đi |
| `den_ngay` | timestamp | Ngày kết thúc chuyến đi |
| `tinh` | text | Địa điểm công tác (Tỉnh/Thành phố) |
| `khoan_muc` | text | Diễn giải mục đích công tác |
| `phu_cap_di_lai` | float8 | Tiền phụ cấp đi lại (User nhập) |
| `phu_cap_an_uong` | float8 | Tiền phụ cấp ăn uống (User nhập) |
| `tong_tien_ve_xe` | float8 | Tổng tiền vé xe (Sum từ Table 2 where type='transport') |
| `tong_tien_khach_san` | float8 | Tổng tiền KS (Sum từ Table 2 where type='hotel') |
| `inserted_at` | timestamp | Ngày tạo tờ trình |

---

### Table 4: `form_claim_chi_phi_content_list` (Danh mục Dịp quà tặng)

Bảng Master Data định nghĩa các dịp tặng quà (Sinh nhật, Hội nghị...) để user chọn khi tạo Plan.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `qua_tang` | text | Loại nhóm (Quà tặng / Mời cơm...) |
| `ten_dip` | text | Tên hiển thị của dịp (VD: Sinh nhật BS A) |
| `ma_dip` | text | **PK** - Mã dịp (VD: SN_01) |
| `thang_chi_phi` | timestamp | Tháng áp dụng của dịp này |
| `trang_thai_dip` | int2 | Trạng thái: `1` (Active), `0` (Inactive) |

-----


## 6\. API & Function Specifications (Chi tiết kỹ thuật)

Hệ thống hoạt động theo mô hình: Frontend gọi API -\> API Gateway gọi Postgres-RPC Function -\> Trả về JSON.

### 6.1. Nhóm khởi tạo và đăng ký (Sales)

#### **Function:** `get_form_claim_chi_phi`

  * **Loại:** READ
  * **Standard:** Tuân thủ tuyệt đối write_get_function.md
  * **Mục đích:** Lấy toàn bộ dữ liệu danh mục (Master Data) để khởi tạo Form đăng ký kế hoạch.
  * **Nguyên tắc lọc dữ liệu:**
    1. **Xác định ngữ cảnh (User Context):**
        * Truy vấn bảng `d_hr_dsns` theo `manv` đầu vào.
        * Lấy thông tin `phongdeptsummary` để xác định giao diện (Ví dụ: Nếu là 'HCP' thì hiện list bác sĩ, nếu là 'TP/MT' thì ẩn).


    2. **Lọc danh sách Bác sĩ (`data_hcp`):**
        * **Nguồn:** `view_list_hcp`.
        * **Điều kiện:** Chỉ lấy nếu nhân viên thuộc phòng 'HCP'.
        * **Logic phân quyền:** Kiểm tra `manv` của user có nằm trong chuỗi phân công `concat_crs_sup` của bác sĩ đó không (HCP phải thuộc địa bàn quản lý).
        * **Trạng thái:** Chỉ lấy `status = 'active'`.


    3. **Lọc danh sách Khách hàng (`data_kh_chung`):**
        * **Trường hợp 1 (Phòng HCP):** Lấy danh sách `hco_bv` (Bệnh viện/PK) duy nhất (`DISTINCT`) từ danh sách bác sĩ đã lọc được ở bước 2.
        * **Trường hợp 2 (Phòng TP/MT):** Truy vấn bảng `d_master_khachhang`. Lọc theo điều kiện `manv` và `supid` nằm trong thuộc địa bàn quản lý.


    4. **Lọc danh mục Dịp/Nội dung (`lst_noi_dung` & `lst_noi_dung_giao_tiep`):**
        * **Nguồn:** `form_claim_chi_phi_content_list`.
        * **Điều kiện:** Chỉ lấy các dịp đang hoạt động (`trang_thai_dip = 1`).
        * **Phân loại:** Tách thành 2 mảng dựa trên cột `qua_tang`:
        * Mảng "Quà tặng" (cho dropdown Quà).
        * Mảng "Giao tiếp - Mời cơm" (cho dropdown Mời cơm).


  * **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR0673"
    }
    ```
  * **JSON Output Specification:**
    ```json
    {
    "data_hcp": [
        {
        "hco_bv": "008369",
        "ten_hcp": "HOÀNG TẤN CƯỜNG",
        "ma_hcp_2": "HCP1000001734-P",
        "pubcustname": "PK HOÀNG TẤN CƯỜNG - SG",
        "kenh_lam_viec": "PCL"
        },
        {
        "hco_bv": "007663",
        "ten_hcp": "NGUYỄN ĐẶNG THANH TÂM",
        "ma_hcp_2": "HCP00000527-P",
        "pubcustname": "PK NGUYỄN ĐẶNG THANH TÂM - SG",
        "kenh_lam_viec": "PCL"
        }
    ],
    "lst_kenh": [
        "CLC & INS",
        "CLC",
        "INS",
        "PCL"
    ],
    "manv_info": [
        {
        "manv": "MR0673",
        "tencvbh": "Hồ Thị Hồng Gấm",
        "phongdeptsummary": "HCP"
        }
    ],
    "lst_noi_dung": [
        {
        "ma_dip": "phunuvietnam",
        "ten_dip": "Chi phí quà tặng ngày phụ nữ Việt Nam 20/10",
        "qua_tang": "Quà tặng",
        "thang_chi_phi": "2025-10-01T00:00:00",
        "trang_thai_dip": 1
        },
        {
        "ma_dip": "giangsinh",
        "ten_dip": "Chi phí quà tặng ngày giáng sinh 24/12",
        "qua_tang": "Quà tặng",
        "thang_chi_phi": "2025-12-01T00:00:00",
        "trang_thai_dip": 1
        }
    ],
    "data_kh_chung": [
        {
        "hco_bv": "000214",
        "pubcustname": "BV QUẬN TÂN PHÚ - SG"
        },
        {
        "hco_bv": "004524",
        "pubcustname": "PK NGUYỄN HỮU DŨNG - SG"
        }
    ],
    "lst_loai_qua_tang": [
        "Quà tặng",
        "Giao tiếp - Mời cơm"
    ],
    "lst_noi_dung_giao_tiep": [
        {
        "ma_dip": "gapgotraodoithongtin",
        "ten_dip": "Chi phí gặp gỡ giao tiếp trao đổi thông tin",
        "qua_tang": "Giao tiếp - Mời cơm",
        "thang_chi_phi": null,
        "trang_thai_dip": 1
        },
        {
        "ma_dip": "danhgiahieuquathuoc",
        "ten_dip": "Chi phí giao tiếp đánh giá về hiệu quả của thuốc",
        "qua_tang": "Giao tiếp - Mời cơm",
        "thang_chi_phi": null,
        "trang_thai_dip": 1
        }
    ]
    }
    ```

-----

#### **Function:** `insert_form_claim_chi_phi`

* **Loại:** WRITE
* **Standard:** Tuân thủ tuyệt đối `write_insert_function.md`
* **Mục đích:** Xử lý logic tính toán ngân sách, kiểm tra tính hợp lệ của dữ liệu và lưu trữ kế hoạch chi phí vào hệ thống.
* **Validation (Các quy tắc chặn lỗi):**
    Hệ thống thực hiện kiểm tra tuần tự các điều kiện sau. Nếu vi phạm bất kỳ điều kiện nào, hệ thống dừng lại và trả về lỗi ngay lập tức:

    1.  **Kiểm tra dữ liệu bắt buộc (Mandatory Check):**
        * Nếu nhân viên thuộc phòng **HCP**, hệ thống bắt buộc user phải chọn Bác sĩ (trường `ten_hcp` không được để trống).
        * *Thông báo lỗi:* `"Chưa chọn HCP"`.
    2.  **Kiểm tra thông tin Sinh nhật (Data Integrity Check):**
        * Nếu nội dung đăng ký là **"Chi phí quà tặng dịp sinh nhật"**, hệ thống sẽ tự động tra cứu ngày sinh của HCP trong view `view_list_hcp`.
        * Nếu không tìm thấy thông tin tháng sinh (`p_thang_sinh` IS NULL) trong hệ thống.
        * *Thông báo lỗi:* `"Khách hàng không có thông tin ngày sinh"`.
    3.  **Kiểm tra trùng lặp (Duplication Check):**
        * **Nguyên tắc:** Một HCP/Khách hàng không được nhận quà (hoặc mời cơm) quá 1 lần trong cùng một tháng cho cùng một loại hình.
        * **Logic kiểm tra:** Hệ thống quét bảng `form_claim_chi_phi`, tìm kiếm xem có bản ghi nào thỏa mãn đồng thời các điều kiện sau:
            * Cùng **Khách hàng/HCP** (`chon_hcp` hoặc `chon_kh_chung`).
            * Cùng **Tháng chi phí** (`thang_chi_phi`) với phiếu đang tạo.
            * Cùng **Phân loại** (`qua_tang` - Ví dụ: cùng là "Quà tặng").
            * Trạng thái phiếu cũ **không phải là Từ chối** (`status != 'R'`).
        * *Thông báo lỗi:* `"Dịp này khách hàng đã được nhận"`.
    4.  **Kiểm tra vượt định mức ngân sách (Budget Threshold Check):**
        * Hệ thống tính **Tổng tiền tích lũy** (Total Risk) bao gồm tổng của 3 nguồn:
            * `(1) Current`: Số tiền đang đăng ký trong phiếu hiện tại.
            * `(2) Pending/Approved`: Tổng số tiền của các phiếu khác đang chờ duyệt hoặc đã duyệt trong cùng tháng/kỳ (Loại trừ các phiếu bị Reject).
            * `(3) Historical`: Chi phí lịch sử Marketing đã thực hiện (Truy vấn từ bảng `d_tracking_cost_hcp_v2` với điều kiện `nam_thuc_hien` = năm hiện tại VÀ `hoat_dong` chứa từ khóa "quà tặng"). **Lưu ý:** Mục (3) chỉ được cộng dồn nếu nội dung phiếu hiện tại là "Chi phí quà tặng dịp sinh nhật".
        * So sánh Tổng tiền tích lũy với **Định mức trần (Cap)**:
            * Nhóm HCP: **2.000.000 VNĐ** / suất.
            * Nhóm TP: **4.000.000 VNĐ** / suất.
            * Nhóm Khác: **50.000.000 VNĐ** / suất.
        * *Thông báo lỗi:* `"Số tiền kế hoạch vượt định mức"`.

* **Logic (Quy trình xử lý dữ liệu):**

    1.  **Chuẩn bị dữ liệu (`data_nhap`):**
        * Chuyển đổi dữ liệu JSON đầu vào thành bảng tạm.
        * Tính toán số lượng HCP (`p_sl_hcp`) được chọn để làm cơ sở nhân ngân sách (chỉ áp dụng nếu là nhóm phòng ban HCP).

    2.  **Tự động tính toán Thời gian ghi nhận chi phí (`thang_chi_phi`):**
        * **Trường hợp Sinh nhật:**
            * Lấy tháng sinh của HCP (`p_thang_sinh`) từ `view_list_hcp`.
            * Nếu *Tháng sinh >= Tháng hiện tại*: Set `thang_chi_phi` = Ngày 01 của tháng sinh năm nay.
            * Nếu *Tháng sinh < Tháng hiện tại*: Set `thang_chi_phi` = Ngày 01 của tháng sinh **năm sau**.
        * **Trường hợp khác:** Sử dụng `ky_chi_phi_kt` do người dùng nhập (hoặc `thang_chi_phi` nếu có).

    3.  **Tính toán và Tổng hợp:**
        * Thực hiện logic truy vấn và cộng dồn dữ liệu từ 3 nguồn (Current, Pending, Historical) như mô tả ở phần Validation để ra con số cuối cùng so sánh với Cap.

    4.  **Thực thi Lưu trữ (Insert):**
        * Nếu tất cả các bước Validation đều vượt qua (Pass), hệ thống thực hiện lệnh `INSERT` dữ liệu đã được xử lý vào bảng `form_claim_chi_phi`.
        * Trả về thông báo thành công.

  * **JSON Input (`body`):**
    ```json
    [
        {
            "id": "CCP20251212171819772",
            "status": "H",
            "manv": "MR0673",
            "tencvbh": "Hồ Thị Hồng Gấm",
            "phongdeptsummary": "HCP",
            "chon_kh_chung": "000214",
            "pubcustname": "BV QUẬN TÂN PHÚ - SG",
            "chon_hcp": "HCP00021426-H",
            "ten_hcp": "PHAN NGUYỄN ANH KHOA",
            "qua_tang": "Quà tặng",
            "kenh": "CLC",
            "ty_le": "5:5",
            "noi_dung": "Chi phí quà tặng ngày phụ nữ Việt Nam 20/10",
            "ghi_chu": "abc",
            "so_ke_hoach": 666666,
            "max_ke_hoach": null,
            "inserted_at": "2025-12-12T17:18:19.772",
            "ma_dip": "phunuvietnam",
            "thang_chi_phi": "2025-10-01T00:00:00",
            "ky_chi_phi_kt": "2025-11-01",
            "nguoi_tiep": ""
        },
        {
            "id": "CCP20251212171819772",
            "status": "H",
            "manv": "MR0673",
            "tencvbh": "Hồ Thị Hồng Gấm",
            "phongdeptsummary": "HCP",
            "chon_kh_chung": "000214",
            "pubcustname": "BV QUẬN TÂN PHÚ - SG",
            "chon_hcp": "HCP00021367-H",
            "ten_hcp": "TRƯƠNG ÁNH TUYẾT",
            "qua_tang": "Quà tặng",
            "kenh": "CLC",
            "ty_le": "5:5",
            "noi_dung": "Chi phí quà tặng ngày phụ nữ Việt Nam 20/10",
            "ghi_chu": "abc",
            "so_ke_hoach": 666666,
            "max_ke_hoach": null,
            "inserted_at": "2025-12-12T17:18:19.772",
            "ma_dip": "phunuvietnam",
            "thang_chi_phi": "2025-10-01T00:00:00",
            "ky_chi_phi_kt": "2025-11-01",
            "nguoi_tiep": ""
        }
    ]
    ```
  * **JSON Output Specification:**
      * **Trường hợp Thành công:**
        ```json
        {
            "status": "ok",
            "success_message": "Đã lưu kế hoạch thành công."
        }
        ```
      * **Trường hợp Lỗi (Ví dụ):**
        ```json
        {
            "status": "fail",
            "error_message": "Khách hàng HCP01 đã nhận quà sinh nhật trong năm nay rồi."
        }
        ```

-----

### 6.2. Nhóm phê duyệt kế hoạch (CRM)

#### **Function:** `get_form_claim_chi_phi_crm`

* **Loại:** READ
* **Standard:** Tuân thủ tuyệt đối `write_get_function.md`
* **Mục đích:** Lấy danh sách các khoản chi phí đang ở trạng thái "Chờ duyệt" (`Status = 'H'`) thuộc thẩm quyền của user đang đăng nhập.
* **Nguyên tắc lọc dữ liệu:**
    1.  **Logic phân quyền:**
        * Hệ thống xác định quyền truy cập bằng cách kiểm tra sự xuất hiện của Mã nhân viên đang đăng nhập (`p_manv`) trong chuỗi thông tin của phiếu.
        * **Quy tắc:** Người dùng có quyền xem/duyệt phiếu này nếu họ chính là **Người tạo phiếu** HOẶC là **Quản lý trực tiếp** của người tạo phiếu.
    2.  **Trạng thái:** Chỉ lấy các bản ghi có `status = 'H'` (Holding - Chờ duyệt).
* **Data Enrichment (Xử lý dữ liệu đầu ra)::**
    * `checked`: Mặc định là `true` (Tự động tích chọn sẵn trên giao diện duyệt).
    * `duyet_so_ke_hoach`: Mặc định gán bằng `so_ke_hoach` (Hệ thống gợi ý số tiền duyệt bằng đúng số tiền nhân viên đề xuất).


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
        "ten": "Vũ Mừng",
        "chuc_danh": "N.CRM",
        "lst_chon_ke_hoach": [
            {
                "id": "CCP20251212151104775",
                "kenh": "CLC",
                "manv": "MR1137",
                "ty_le": "5:5",
                "ma_dip": "sinhnhat",
                "status": "H",
                "checked": true,
                "ghi_chu": "abc",
                "ten_hcp": "VÕ THỊ NGỌC TRÂM",
                "tencvbh": "Vũ Mừng",
                "chon_hcp": "HCP1000001511-P",
                "noi_dung": "Chi phí quà tặng dịp sinh nhật",
                "qua_tang": "Quà tặng",
                "nguoi_tiep": "",
                "approved_at": null,
                "inserted_at": "2025-12-12T15:11:04.776",
                "pubcustname": "PK NGUYỄN THỊ BÍCH NGỌC - SG",
                "so_ke_hoach": 666666,
                "max_ke_hoach": 2000000,
                "approved_manv": null,
                "chon_kh_chung": "007987",
                "ky_chi_phi_kt": "2025-11-01T00:00:00",
                "thang_chi_phi": "2026-10-01T00:00:00",
                "phongdeptsummary": "HCP",
                "claim_approved_at": null,
                "duyet_so_ke_hoach": 666666,
                "approved_so_ke_hoach": null,
                "so_tien_claim_hoa_don": null
            }
        ]
    }
    ```

#### **Function:** `insert_form_claim_chi_phi_crm`

  * **Loại:** WRITE
  * **Standard:** Tuân thủ tuyệt đối write_insert_function.md
  * **Mục đích:** CRM xác nhận duyệt (C) hoặc từ chối (R) hoặc Xóa (X).
  * **Logic:** 
    - Update bảng `form_claim_chi_phi` các trường `status`, `approved_so_ke_hoach`, `approved_manv`, `approved_at` dựa trên ID gửi lên.
    - Xóa các ID nếu trạng thái là X.
  * **JSON Input (`body` - Array):**
    ```json
    [
        {
            "id": "CCP20251212151104775",
            "kenh": "CLC",
            "manv": "MR1137",
            "ty_le": "5:5",
            "ma_dip": "sinhnhat",
            "status": "C",
            "checked": true,
            "ghi_chu": "abc",
            "ten_hcp": "VÕ THỊ NGỌC TRÂM",
            "tencvbh": "Vũ Mừng",
            "chon_hcp": "HCP1000001511-P",
            "noi_dung": "Chi phí quà tặng dịp sinh nhật",
            "qua_tang": "Quà tặng",
            "nguoi_tiep": "",
            "approved_at": null,
            "inserted_at": "2025-12-12T15:13:14.233",
            "pubcustname": "PK NGUYỄN THỊ BÍCH NGỌC - SG",
            "so_ke_hoach": 666666,
            "max_ke_hoach": 2000000,
            "approved_manv": null,
            "chon_kh_chung": "007987",
            "ky_chi_phi_kt": "2025-11-01T00:00:00",
            "thang_chi_phi": "2026-10-01T00:00:00",
            "phongdeptsummary": "HCP",
            "claim_approved_at": null,
            "duyet_so_ke_hoach": 666666,
            "approved_so_ke_hoach": null,
            "so_tien_claim_hoa_don": null
        }
    ]
    ```
  * **JSON Output:** `{"status": "ok", "success_message": "Đã nhận thành công"}`


-----

### 6.3. Nhóm gắn hóa đơn (Sales)

#### **Function:** `get_form_claim_chi_phi_crm_approved`

  * **Loại:** READ
  * **Standard:** Tuân thủ tuyệt đối `write_get_function.md`
  * **Mục đích:** Lấy danh sách các Plan (kế hoạch chi phí) đã được CRM duyệt bước đầu.
  * **Nguyên tắc lọc dữ liệu:**
      1.  **Lọc theo trạng thái:**
          * Hệ thống chỉ lấy các phiếu có trạng thái là **"Đã duyệt"** ('C').
      2.  **Logic phân quyền:**
          * **Quy tắc:** Người dùng có quyền xem phiếu này nếu họ chính là **Người tạo phiếu** HOẶC là **Quản lý trực tiếp** của người tạo phiếu.
      3.  **Chuẩn bị dữ liệu hiển thị:**
          * Hệ thống tự động lấy giá trị **Số tiền đã được duyệt** (`approved_so_ke_hoach`) gán vào trường **Số tiền đề nghị thanh toán** (`so_tien_claim`) để làm giá trị mặc định, giúp người dùng biết được hạn mức tối đa có thể claim.

  * **JSON Input (`url_param`):**
    ```json
    { "manv": "MR0673" }
    ```
  * **JSON Output:**
    ```json
    {
        "status": "ok",
        "lst_da_duyet": [
            {
                "id": "CCP20251212171819772",
                "kenh": "CLC",
                "manv": "MR0673",
                "ty_le": "5:5",
                "ma_dip": "phunuvietnam",
                "status": "C",
                "ghi_chu": "abc",
                "ten_hcp": "PHAN NGUYỄN ANH KHOA,TRƯƠNG ÁNH TUYẾT",
                "tencvbh": "Hồ Thị Hồng Gấm",
                "chon_hcp": "HCP00021426-H,HCP00021367-H",
                "noi_dung": "Chi phí quà tặng ngày phụ nữ Việt Nam 20/10",
                "qua_tang": "Quà tặng",
                "mnv_supid": "MR0673 - MR1137",
                "nguoi_tiep": "",
                "approved_at": "2025-12-12T17:45:19.187",
                "inserted_at": "2025-12-12T17:18:19.772",
                "pubcustname": "BV QUẬN TÂN PHÚ - SG",
                "so_ke_hoach": 666666,
                "max_ke_hoach": 4000000,
                "approved_manv": "MR1137",
                "chon_kh_chung": "000214",
                "ky_chi_phi_kt": "2025-11-01T00:00:00",
                "so_tien_claim": 666666,
                "thang_chi_phi": "2025-10-01T00:00:00",
                "phongdeptsummary": "HCP",
                "claim_approved_at": null,
                "approved_so_ke_hoach": 666666,
                "so_tien_claim_hoa_don": null
            }
        ]
    }
    ```

#### **Function:** `get_form_claim_chi_phi_hoa_don_misa`

* **Loại:** READ
* **Standard:** Tuân thủ tuyệt đối `write_get_function.md`
* **Mục đích:** Lấy danh sách hóa đơn Misa khả dụng (còn dư tiền) để nhân viên chọn.
* **Nguyên tắc lọc dữ liệu:**
    1.  **Tính số dư thực tế:**
        * `Tiền còn lại` = `Tổng tiền gốc hóa đơn` - `Tổng tiền đã được claim ở các phiếu khác`.
    2.  **Điều kiện hiển thị:**
        * Số dư `Tiền còn lại` **>= 10.000 VNĐ** (Chặn hóa đơn rác hoặc đã dùng hết).
        * `Ngày hóa đơn` >= Ngày 01 của **tháng trước** đến nay (Chặn hóa đơn quá hạn).
    3.  **Sắp xếp & Hiển thị:**
        * Ưu tiên: Ngày mới nhất -> Tên người bán -> Số tiền lớn nhất.
        * Tạo chuỗi `ten_hien_thi` đầy đủ thông tin (Tên, MST, Số HĐ) để hiển thị lên Dropdown.


  * **JSON Input:** `{}` (Rỗng)
  * **JSON Output:**
    ```json
    {
        "lst_invoices": [
            {
                "stt": 1,
                "check": false,
                "check_tm": true,
                "clean_ten": "TRUNG TAM Y TE HOA LU | 18820 | 12-12-2025 | 2700750668-002 | ",
                "so_hoa_don": "000018820",
                "ngay_hoa_don": "12-12-2025",
                "ten_hien_thi": "TRUNG TÂM Y TẾ HOA LƯ | 000018820 | 12-12-2025 | 2700750668-002 | ",
                "tien_con_lai": 862100,
                "selected_time": "",
                "so_tien_claim": 862100,
                "ten_nguoi_ban": "TRUNG TÂM Y TẾ HOA LƯ",
                "tong_tien_thanh_toan": 862100,
                "id_duy_nhat_cua_hoa_don": "019b1124ef32775aa5fd80199daf5623"
            }
        ]
    }
    ```

#### **Function:** `insert_form_claim_chi_phi_hoa_don`

  * **Loại:** WRITE
  * **Standard:** Tuân thủ tuyệt đối `write_insert_function.md`
  * **Mục đích:** Mapping danh sách hóa đơn vào Plan chi phí và cập nhật trạng thái/tổng tiền cho Plan.
  * **Logic & Validation (Thứ tự thực hiện theo Code):**
    1.  **Chuẩn bị dữ liệu:**
          * Hệ thống tự động gán giá trị mặc định `check_tm = 1` cho các bản ghi chi tiết.
          * Convert định dạng ngày hóa đơn từ `DD-MM-YYYY` sang Timestamp.
    2.  **Validation 1 - Check quyền sử dụng hóa đơn (`p_check_crs`):**
          * Hệ thống kiểm tra xem `id_duy_nhat_cua_hoa_don` đã tồn tại trong bảng `form_claim_chi_phi_hoa_don` chưa.
          * Nếu đã tồn tại, so sánh `manv` đã nhập trước đó với `manv` hiện tại.
          * **Điều kiện lỗi:** Nếu `manv` trong database KHÁC `manv` input (tức là hóa đơn này đã bị nhân viên khác claim).
          * **Thông báo lỗi:** `"Hóa đơn đã được chọn trước đó"`.
    3.  **Validation 2 - Kiểm soát chi vượt hóa đơn (Over-claim Protection):**
          * Nguyên tắc nghiệp vụ: Đảm bảo Tổng giá trị thanh toán trên một hóa đơn (bao gồm cả các lần đã thanh toán trước đó + lần đang đề nghị này) tuyệt đối không được vượt quá Tổng giá trị thực tế của hóa đơn đó ghi nhận trên hệ thống Misa.
          * Ý nghĩa: Hỗ trợ trường hợp một hóa đơn giá trị lớn được tách ra để thanh toán cho nhiều khoản mục khác nhau (Partial Claim), nhưng hệ thống sẽ chặn ngay lập tức nếu phát hiện số tiền yêu cầu thanh toán "bị lố" so với thực tế.
          * **Thông báo lỗi:** `"Số tiền đã vượt mức hóa đơn"`.
    4.  **Thực thi Ghi dữ liệu (Nếu Validation OK):**
          * **INSERT:** Ghi toàn bộ danh sách hóa đơn từ input vào bảng `form_claim_chi_phi_hoa_don`.
          * **UPDATE:** Cập nhật bảng `form_claim_chi_phi` (Master) dựa trên `khid`:
              * Cập nhật `status` (theo giá trị từ input).
              * Cập nhật `so_tien_claim_hoa_don` = Tổng `so_tien_claim` của đợt nhập này.
  * **JSON Input (`body` - Array containing 1 Object):**
      * *Lưu ý: Định dạng ngày tháng bắt buộc là DD-MM-YYYY.*
    <!-- end list -->
      ```json
      [
          {
              "khid": "CCP001",
              "manv": "MR0673",
              "status": "I",
              "lst_chon_invoices": [
                  {
                      "id_duy_nhat_cua_hoa_don": "INV_XYZ",
                      "ten_nguoi_ban": "Cty TNHH ABC",
                      "so_hoa_don": "0012345",
                      "ngay_hoa_don": "12-10-2025", 
                      "tong_tien_thanh_toan": 1000000,
                      "so_tien_claim": 500000,
                      "selected_time": "2025-10-12T10:00:00"
                  }
              ]
          }
      ]
      ```
  * **JSON Output:**
    * **Thành công:**
    ```json
    {
        "status": "ok",
        "success_message": "Đã nhận thành công"
    }
    ```
  * **Thất bại:**
    ```json
    {
        "status": "fail",
        "error_message": "Số tiền đã vượt mức hóa đơn" 
    }
    ```

-----

### 6.4. Nhóm duyệt thanh toán (CRM)

#### **Function:** `get_form_claim_chi_phi_crm_claimed`

  * **Loại:** READ
  * **Standard:** Tuân thủ tuyệt đối `write_get_function.md`
  * **Mục đích:** CRM/Kế toán lấy danh sách các khoản chi phí mà Sales đã gắn xong hóa đơn (Status = 'I') để kiểm tra và duyệt chi.
  * **Nguyên tắc lọc dữ liệu:**
    1.  **Filter by Status:** Chỉ lấy các bản ghi có `status = 'I'`.
    2.  **Filter by Permission:** Nếu người dùng là Admin, lấy tất cả. Nếu là quản lý vùng, chỉ lấy nhân viên thuộc vùng quản lý (Logic phân quyền dựa trên `manv` input).
    3.  **Data Enrichment:** Join với bảng chi tiết hóa đơn để hiển thị tổng số tiền hóa đơn đã gắn ngay trên danh sách (nếu cần).
  * **JSON Input:**
    ```json
    {"manv": "AM001"}
    ```
  * **JSON Output:**:
    ```json
    {
        "lst_duyet_hoa_don": [
            {
                "id": "CCP20251212171819772",
                "kenh": "CLC",
                "manv": "MR0673",
                "ty_le": "5:5",
                "ma_dip": "phunuvietnam",
                "status": "I",
                "checked": true,
                "ghi_chu": "abc",
                "ten_hcp": "PHAN NGUYỄN ANH KHOA,TRƯƠNG ÁNH TUYẾT",
                "tencvbh": "Hồ Thị Hồng Gấm",
                "chon_hcp": "HCP00021426-H,HCP00021367-H",
                "noi_dung": "Chi phí quà tặng ngày phụ nữ Việt Nam 20/10",
                "qua_tang": "Quà tặng",
                "nguoi_tiep": "",
                "approved_at": "2025-12-12T17:45:19.187",
                "inserted_at": "2025-12-12T17:18:19.772",
                "pubcustname": "BV QUẬN TÂN PHÚ - SG",
                "so_ke_hoach": 666666,
                "max_ke_hoach": 4000000,
                "approved_manv": "MR1137",
                "chon_kh_chung": "000214",
                "ky_chi_phi_kt": "2025-11-01T00:00:00",
                "thang_chi_phi": "2025-10-01T00:00:00",
                "phongdeptsummary": "HCP",
                "claim_approved_at": null,
                "approved_so_ke_hoach": 666666,
                "so_tien_claim_hoa_don": 666666
            }
        ]
    }
    ```

#### **Function:** `insert_form_claim_chi_phi_crm_claimed`

  * **Loại:** WRITE

  * **Standard:** Tuân thủ tuyệt đối `write_insert_function.md`

  * **Mục đích:** CRM thực hiện chốt sổ thanh toán cho các khoản chi phí: Duyệt (Done) hoặc Từ chối (Error).

  * **Validation:**

      * **Không có:** Logic kiểm tra điều kiện (như bắt buộc nhập ghi chú khi từ chối, hoặc check trạng thái cũ) không được xử lý trong DB mà tin cậy vào dữ liệu gửi lên từ Client/Backend.

  * **Logic (Thứ tự thực hiện theo Code):**

    1.  **Khởi tạo dữ liệu (`crm_result`):**
          * Phân tích chuỗi JSON input thành bảng tạm bao gồm: `id`, `manv`, `status`, `ghi_chu`, `inserted_at`.
    2.  **Xử lý trường hợp Từ chối (Rejection Logic):**
          * Kiểm tra trong dữ liệu input, nếu bản ghi nào có `status = 'E'` (Error/Reject).
          * **Hành động:** Thực hiện **DELETE** các dòng tương ứng trong bảng chi tiết `form_claim_chi_phi_hoa_don` dựa trên `khid`.
          * **Ý nghĩa nghiệp vụ:** "Nhả" các hóa đơn đã gắn ra khỏi phiếu này, trả lại trạng thái tự do để Sales có thể gắn vào phiếu khác hoặc làm lại đề nghị thanh toán mới.
    3.  **Cập nhật trạng thái (Update Master):**
          * Thực hiện **UPDATE** bảng `form_claim_chi_phi` dựa trên `id`.
          * Cập nhật các trường: `status` (Trạng thái mới), `approved_manv` (Người duyệt), `ghi_chu` (Lý do duyệt/từ chối), `claim_approved_at` (Thời điểm duyệt).
    4.  **Trả kết quả:** Trả về danh sách các bản ghi vừa xử lý kèm thông báo thành công.

  * **JSON Input (`body` - Array):**

    ```json
    [
        {
            "id": "CCP001",
            "status": "D",
            "manv": "AM001",
            "ghi_chu": "Đã kiểm tra, duyệt chi",
            "inserted_at": "2025-10-12 14:30:00"
        }
    ]
    ```

  * **JSON Output:**

    ```json
    {
        "status": "ok",
        "data": [
            {
                "id": "CCP001",
                "manv": "AM001",
                "status": "D",
                "ghi_chu": "Đã kiểm tra, duyệt chi",
                "inserted_at": "2025-10-12 14:30:00"
            }
        ],
        "success_message": "Đã nhận thành công"
    }
    ```

-----

### 6.5. Nhóm Công tác phí & Báo cáo

#### **Function:** `insert_form_cong_tac_phi`

* **Loại:** WRITE
* **Standard:** Tuân thủ tuyệt đối `write_insert_function.md`
* **Mục đích:** Tạo mới một Tờ trình công tác phí. Hành động này bao gồm việc ghi nhận thông tin chuyến đi (Header) và gắn kèm các hóa đơn chi phí phát sinh như Vé xe, Khách sạn (Details) trong cùng một lần xử lý.
* **Validation (Các quy tắc chặn lỗi):**
    * **Kiểm tra quyền sử dụng hóa đơn:** Hệ thống kiểm tra xem hóa đơn đính kèm đã bị **người khác** sử dụng chưa.
        * Nếu hóa đơn đã được nhân viên khác claim -> Báo lỗi `"Hóa đơn đã được chọn"`.
        * Nếu hóa đơn do chính user hiện tại đã nhập trước đó (đang chỉnh sửa hoặc gửi lại) -> **Cho phép**.
        * **Mục tiêu:** Ngăn chặn việc một hóa đơn được dùng để claim tiền 2 lần (Double Spending).
        * *Thông báo lỗi:* `"Hóa đơn đã được chọn"`.

* **Logic (Quy trình xử lý nghiệp vụ):**

    1.  **Tiếp nhận và Chuẩn hóa dữ liệu:**
        * Tự động chuẩn hóa các định dạng ngày tháng khác nhau (Ví dụ: Kỳ chi phí `YYYY-MM-DD` vs Ngày hóa đơn `DD-MM-YYYY`).
    2.  **Lưu thông tin Tờ trình (Header):**
        * Hệ thống tạo một bản ghi mới trong bảng `form_cong_tac_phi` chứa các thông tin chung của chuyến đi: Người đi, Thời gian (Từ ngày - Đến ngày), Địa điểm (Tỉnh), và các khoản phụ cấp (Ăn uống, Đi lại) do người dùng tự kê khai.
    3.  **Lưu chi tiết Hóa đơn (Detail):**
        * Kiểm tra xem tờ trình có đính kèm hóa đơn không. Nếu có (`arr_length >= 1`):
            * Hệ thống thực hiện gắn các hóa đơn này vào hệ thống (`form_claim_chi_phi_hoa_don`).
  
  * **JSON Input (`body` - Array wrapper):**
    ```json
    [
        {
            "khid": "CTP_001",
            "manv": "MR0673",
            "khoan_muc": "Công tác phí",
            "tinh": "Hà Nội",
            "ky_chi_phi_kt": "2025-10-31",            // Format YYYY-MM-DD
            "tu_ngay": "2025-10-01 08:00:00",         // Timestamp
            "den_ngay": "2025-10-02 17:00:00",        // Timestamp
            "inserted_at": "2025-10-02 18:00:00",     // Timestamp
            
            "phu_cap_di_lai": 100000,
            "phu_cap_an_uong": 200000,
            "tong_tien_ve_xe": 500000,
            "tong_tien_khach_san": 1000000,

            "lst_chon_invoices": [
                {
                    "id_duy_nhat_cua_hoa_don": "INV_BUS_01",
                    "so_hoa_don": "009988",
                    "ngay_hoa_don": "01-10-2025",     // Format DD-MM-YYYY
                    "selected_time": "01-10-2025",    // Format DD-MM-YYYY
                    "ten_nguoi_ban": "Nhà xe Thành Bưởi",
                    "ten_hien_thi": "Vé xe đi",
                    "cost_type": "transport",         // transport / hotel
                    "check_tm": true,
                    "tong_tien_thanh_toan": 500000,
                    "so_tien_claim": 500000,
                    "tien_con_lai": 0
                }
            ]
        }
    ]
    ```
  * **JSON Output:** `{"status": "ok", "success_message": "Đã nhận thành công"}`

-----

#### **Function:** `get_form_claim_chi_phi_excel_form`

* **Loại:** READ
* **Standard:** Tuân thủ tuyệt đối `write_get_function.md`
* **Mục đích:** Lấy toàn bộ dữ liệu đã được duyệt (Status = 'D') để kết xuất ra 2 biểu mẫu Excel báo cáo thanh toán: **BMKT013** (Bảng kê chi tiết) và **BMKT002** (Giấy đề nghị thanh toán).
* **Nguyên tắc lọc dữ liệu:**
    1.  **Điều kiện tiên quyết:**
        * Chỉ lấy các khoản chi của nhân viên đang đăng nhập (`manv`).
        * Chỉ lấy các khoản đã hoàn tất quy trình duyệt (`status = 'D'`).
        * Lọc theo khoảng thời gian (`fromDate` <= `ky_chi_phi_kt` <= `toDate`).
    2.  **Logic tổng hợp cho biểu mẫu BMKT013 (Chi tiết tiếp khách):**
        * Lấy chi tiết từ bảng `form_claim_chi_phi`.
        * **Xử lý tên khách hàng:** Nếu kênh là TP/MT -> Lấy từ danh mục khách hàng (`d_master_khachhang`). Nếu là HCP -> Lấy tên Bệnh viện/Phòng khám.
        * **Xử lý kênh:** Hiển thị kèm tỷ lệ split nếu có (Ví dụ: "CLC & INS (50:50)").
        * **Xử lý số kế hoạch và số duyệt:** Khi join với bảng `form_claim_chi_phi_hoa_don` bị đúp dòng => Chỉ Số kế hoạch/duyệt đầu tiên là có data, còn lại = 0.         
    3.  **Logic tổng hợp cho biểu mẫu BMKT002 (Đề nghị thanh toán):**
          **Nguyên tắc tổng hợp dữ liệu (Data Aggregation Logic):**

          Dữ liệu trả về (đặc biệt là mảng `BMKT002`) được tổng hợp (UNION) từ 3 nguồn dữ liệu khác nhau với logic lọc riêng biệt:

          | Nguồn dữ liệu | Loại chi phí | Logic lọc (Filter Criteria) | Logic hiển thị |
          | :--- | :--- | :--- | :--- |
          | **Nguồn 1**<br>(`ds_chi_phi_tiep_khach`) | **Tiếp khách / Quà tặng**<br>(Từ Sales) | **Status:** Chỉ lấy Status = 'D' (Đã duyệt)<br>**Thời gian:** Lọc theo **KHOẢNG** (`ky_chi_phi_kt` \>= `fromDate` VÀ \<= `toDate`). | Hiển thị chi tiết từng hóa đơn, người thụ hưởng, nội dung quà tặng. |
          | **Nguồn 2**<br>(`ds_phu_cap_ctp`) | **Phụ cấp CTP**<br>(Đi lại + Ăn uống) | **Số tiền:** Tổng phụ cấp \> 0.<br>**Thời gian:** Lọc theo **NGÀY CHÍNH XÁC** (`ky_chi_phi_kt` = `fromDate`). | Gom thành 1 dòng: "CTP THÁNG... từ... đến...".<br>Số hóa đơn = NULL. |
          | **Nguồn 3**<br>(`ds_hoa_don_ctp`) | **Hóa đơn CTP**<br>(Vé xe, KS...) | **Điều kiện:** Phải có hóa đơn đi kèm (ID Not Null).<br>**Thời gian:** Lọc theo **NGÀY CHÍNH XÁC** (`ky_chi_phi_kt` = `fromDate`). | Hiển thị chi tiết từng hóa đơn (Vé xe, KS) phát sinh trong chuyến đi. |

        **Định dạng cột Nội dung (`noi_dung`):**
              * Đối với các dòng là Công tác phí (CTP), hệ thống không lấy tên khoản mục đơn thuần mà tự động ghép chuỗi theo định dạng:
                  `"CTP THÁNG : [MM-YYYY], từ : [Ngày đi] đến: [Ngày về]"`
        **Cấu trúc Footer (JSON Keys) cho BMKT002:**
          * Ngoài 2 mảng dữ liệu chính, hàm trả về các **Keys** riêng biệt để điền vào phần chân trang/chữ ký của biểu mẫu Excel:
              * `tong_so_tien`: Tổng số tiền đã được định dạng có dấu phẩy (Ví dụ: "800,000").
              * `so_tien_bang_chu`: Tổng số tiền được chuyển đổi thành chữ tiếng Việt (Ví dụ: "Tám trăm ngàn đồng").
              * `ly_do_thanh_toan`: Chuỗi cố định `"Thanh toán chi phí giao tiếp tháng: [MM-YYYY]"`.
              * `thoi_gian_de_nghi`: Gán mặc định là `"Trước ngày 20 tháng sau"`.
              * `nguoi_nhan` & `nguoi_de_nghi`: Được ghép tự động theo công thức `[Mã NV] + " - " + [Họ tên]` (Ví dụ: "MR0673 - Nguyễn Văn A").

    4.  **Xử lý Footer:**
        * Tính tổng số tiền và tự động chuyển đổi số tiền thành chữ tiếng Việt (Ví dụ: "Một triệu đồng chẵn").

  * **JSON Input (`url_param`):**
    ```json
    {
        "from_date": "2025-11-01",
        "to_date": "2025-11-01",
        "manv": "MR1137",
        "id": "20251212235209830"
    }
    ```
  * **JSON Output:**
    ```json
    {
      "status": "ok",
      "BMKT002": [
        {
          "stt": 1,
          "ghi_chu": "abc",
          "so_tien": 666666,
          "noi_dung": "Chi phí quà tặng dịp sinh nhật",
          "so_hoa_don": "000000397",
          "ngay_hoa_don": "2025-12-12T00:00:00",
          "nguoi_nhan_tien": "MR1137 - Vũ Mừng",
          "thoi_gian_de_nghi": "Trước ngày 20 tháng sau"
        }
      ],
      "BMKT013": [
        {
          "kenh": "CLC",
          "ma_kh": "007987",
          "supid": "MR1137",
          "ten_kh": "PK NGUYỄN THỊ BÍCH NGỌC - SG",
          "ghi_chu": "abc",
          "khu_vuc": "",
          "so_khid": "CCP20251212151104775",
          "supid_2": "MR1137",
          "duyet_kh": 666666,
          "noi_dung": "Chi phí quà tặng dịp sinh nhật",
          "de_xuat_kh": 666666,
          "so_hoa_don": "000000397",
          "tenquanlytt": "Vũ Mừng",
          "tenquanlytt_2": "Vũ Mừng",
          "ngay_thuc_hien": "2025-12-12",
          "ho_ten_nguoi_tiep": "VÕ THỊ NGỌC TRÂM",
          "tong_tien_thuc_hien": 666666
        }
      ],
        "bmkt013_tong_tien_ke_hoach": "600,000",
        "bmkt013_tong_tien_duyet": "500,000",

        "bmkt002_department": "HCP",
        "bmkt002_tong_so_tien": "666,666",
        "bmkt002_nguoi_nhan": "MR1137 - Vũ Mừng",
        "bmkt002_nguoi_de_nghi": "MR1137 - Vũ Mừng",
        "bmkt002_ly_do_thanh_toan": "Thanh toán chi phí giao tiếp tháng: 11-2025",
        "bmkt002_so_tien_bang_chu": "sáu trăm sáu mươi sáu nghìn sáu trăm sáu mươi sáu đồng"
    }
    ```

