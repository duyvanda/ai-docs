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
                * *Ràng buộc:* Nếu chọn nội dung là dịp sinh nhật, chỉ được phép chọn duy nhất **1 HCP**.
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
    * **Payload:** Gửi danh sách các records đã tick kèm trạng thái mới (`C`: Confirmed hoặc `R`: Rejected hoặc `X`: Xóa).
5.  **Feedback:** Reload lại bảng dữ liệu sau 2 giây.

---

### 4.3. Phân hệ Sales (TDV) - Gắn Hóa đơn (Mapping Invoice)

**User Flow: Chọn hóa đơn cho kế hoạch đã duyệt**

1.  **Start:** User truy cập tab "Gắn Hóa Đơn" (Route: `/formcontrol/form_claim_chi_phi_claimed`).
2.  **Display:**
    * Load danh sách kế hoạch đã duyệt (`Status = C`).
    * Load danh sách hóa đơn đỏ từ Misa (API: `get_form_claim_chi_phi_hoa_don_misa`).
3.  **Open Form:** User bấm nút **HĐ** tại một dòng kế hoạch cụ thể. Hệ thống hiển thị giao diện xử lý mở rộng ngay dưới dòng đó (Inline Form).
4.  **Select Invoice & Upload Proof:**
    * **Chọn hóa đơn:** User tìm kiếm hóa đơn (theo số HĐ, tên NCC) và gạt nút Switch để chọn.
    * **Tự động điều chỉnh (Auto Adjust):** Frontend tự động tính tổng tiền các hóa đơn đang chọn. Nếu tổng tiền vượt quá số tiền duyệt, hệ thống sẽ **tự động cắt giảm số tiền** của hóa đơn vừa chọn sao cho tổng khớp chính xác với số tiền được duyệt (không cần popup phụ).
    * **Phương thức thanh toán:** Chọn "Chuyển khoản" hoặc "Tiền mặt" cho hóa đơn vừa chọn. Mặc định là Tiền mặt.
    * **Upload Chứng từ:** User **bắt buộc** phải tải lên chứng từ (kéo thả hình ảnh/pdf) riêng biệt cho từng hóa đơn. **Validate:** Phải có tối thiểu 2 file (1 hình CK & 1 hình quán ăn/quà) cho mỗi hóa đơn mới cho phép lưu.
5.  **Submit:**
    * User bấm nút "Xác nhận & Tải Lên".
    * **Frontend Logic:** Hệ thống gom các hình ảnh/chứng từ của MỖI hóa đơn thành từng file ZIP riêng biệt (giữ nguyên tên gốc của ảnh bên trong ZIP).
    * **Call API:** Đẩy Multipart/FormData chứa các file ZIP và chuỗi JSON tới API, từ đó gọi `insert_form_claim_chi_phi_hoa_don` (Method: POST).
    * **Data:** Chuyển trạng thái plan sang `I` (Invoiced), sinh `zip_file_url` lưu trực tiếp vào từng hóa đơn tương ứng, và lưu data vào bảng `form_claim_chi_phi_hoa_don`.
6.  **Feedback:** Đóng form hiển thị inline và hiện thông báo thành công.

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
    * **Phụ cấp:** Nhập tiền phụ cấp đi lại, ăn uống, vé xe công tác (`float8` - *User tự nhập*).
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

### 4.6. Tải và xác nhận excel (Chốt dữ liệu)

**User Flow**: 
    1. Vào mục duyệt hóa đơn, chọn kỳ chi phí và bấm "Chốt HĐ / Tải Biểu Mẫu".
    2. **Call API:** `post_form_claim_chi_phi_excel_form` (Method: POST) để sinh báo cáo Excel tổng hợp và hiển thị nút "Tải xuống dữ liệu".
    3. User bấm nút **"✍️ Tôi đã xem và tiến hành ký số thông qua MLID"** để xác nhận chốt sổ gửi email.
    4. **Call API:** `insert_form_claim_chi_phi_chung_tu` (Method: POST) để ghi nhận hoàn tất và gửi email thông báo cho hệ thống.

**Excel Export Logic**:
API trả về JSON với các sheet data (`BMKT013`, `BMKT002`, `BMKT005`):
- `BMKT013-KH-TH-CP`: Danh sách chi phí tổng hợp.
- `BMKT002-DNTT`: Đề nghị thanh toán.
- `BMKT005-DNTTCTP`: Đề nghị thanh toán chi phí công tác. 
    - Header mapping: Ưu tiên lấy từ các field API trả về riêng (như `bmkt005_nguoi_de_nghi`, `bmkt005_department`, `bmkt005_ly_do_thanh_toan`, `bmkt005_tong_cong_tac_phi`, `bmkt005_so_tien_bang_chu`). Nếu thiếu, sẽ dùng giá trị dự phòng từ `BMKT002`.
    - Cột mapping chi tiết cho `BMKT005`: `stt`, `noi_dung_chi_tiet`, `so_ngay`, `chi_phi_khach_san`, `phu_cap_an_uong`, `phu_cap_di_lai`, `ve_xe`, `chi_phi_giao_tiep`, `tong_tien`, `so_hoa_don`, `ngay_hoa_don`, `khoan_muc`, `nguoi_nhan_tien`, `ghi_chu`.

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
| `manv` | text | **PK** - Mã nhân viên |
| `usertypes` | text | Loại user (VD: CRS, CRM, Admin...) |
| `position` | text | Vị trí / chức vụ |
| `tencvbh` | text | Tên nhân viên |
| `supid` | text | **Permission** - Mã nhân viên của người quản lý trực tiếp (Line Manager) |
| `tenquanlytt` | text | Tên người quản lý trực tiếp (Denormalized — dùng để hiển thị tên CRM mà không cần join thêm bảng khác) |


## View: `view_list_hcp` 

(Danh sách Bác sĩ & Phân quyền) View tổng hợp thông tin Bác sĩ/Dược sĩ (HCP) và thông tin phân công địa bàn. Đây là nguồn dữ liệu chính để lọc danh sách bác sĩ cho nhân viên Sales kênh HCP.

| Column Name | Data Type | Description |
| --- | --- | --- |
| `ma_hcp_2` | text | **PK** - Mã định danh duy nhất của HCP (VD: HCP1000001734-P) |
| `ten_hcp` | text | Họ và tên Bác sĩ / Dược sĩ |
| `hco_bv` | text | Mã Bệnh viện / Phòng khám nơi HCP công tác |
| `pubcustname` | text | Tên Bệnh viện / Phòng khám hiển thị |
| `kenh_lam_viec` | text | Kênh hoạt động (CLC, INS, PCL...) |
| `concat_crs_sup` | text | **Permission Column** - Chuỗi chứa danh sách mã nhân viên và quản lý phụ trách HCP này (VD: "MR0673,SUP001"). Hệ thống dùng hàm `strpos` để kiểm tra quyền truy cập. |
| `status` | text | Trạng thái hoạt động (`active` / `inactive`) |

## Table: `d_master_khachhang` 

(Danh sách Khách hàng Tổ chức)Bảng Master Data chứa danh sách Bệnh viện, Nhà thuốc, Phòng khám (HCO). Dùng để lọc khách hàng cho nhân viên Sales kênh OTC/ETC (TP, MT) hoặc lấy thông tin khách hàng chung.

| Column Name | Data Type | Description |
| --- | --- | --- |
| `custid` | text | **PK** - Mã khách hàng (VD: 000214) |
| `custname` | text | Tên khách hàng (VD: BV QUẬN TÂN PHÚ - SG) |
| `mnv_supid` | text | **Permission Column** - Chuỗi kết hợp Mã NV và Mã SUP (VD: "MR0673,SUP001"). Dùng để xác định nhân viên nào được phép làm việc với khách hàng này. |
| `channel` | text | Kênh bán hàng (Hospital, Pharmacy, Wholesaler...) |
| `province` | text | Tỉnh/Thành phố của khách hàng (Hỗ trợ lọc theo vùng) |

## Table: `d_tracking_cost_hcp_v2` 

(Lịch sử chi phí Marketing)Đây là bảng dữ liệu lịch sử được đồng bộ từ hệ thống Marketing, lưu trữ các khoản chi phí đã thực hiện cho từng HCP trong quá khứ. Bảng này được dùng để tính toán định mức "Ngân sách còn lại" (đặc biệt là cho quà Sinh nhật) nhằm tránh chi vượt trần.

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
| `array_hcp` | jsonb | array các hcp từ fontend |
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
| `ve_xe_cong_tac` | float8 | Tiền phụ cấp (User nhập) |
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
| `ghi_chu` | text | . |


### Table 5: `form_claim_chi_phi_email_kt`
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `ma_ql` | text | mã quản lý của nhân viên yêu cầu xác nhận |
| `ma_nv_kt` | text | mã KT phụ trách yêu cầu xác nhận |

### Table 6: `form_claim_chi_phi_chung_tu`

Bảng lưu trữ thông tin đi kèm với chứng từ chi phí được upload từ Form Claim.

| Column Name | Data Type | Description |
| --- | --- | --- |
| `id` | text | **PK** - Mã định danh chứng từ (VD: MNV123_15_01_2026). |
| `manv` | text | Mã nhân viên (VD: MR1391). |
| `from_date` | date | Thời gian bắt đầu của kỳ claim. |
| `to_date` | date | Thời gian kết thúc của kỳ claim. |
| `file_1` | text | Đường dẫn file chứng từ/hình ảnh (URL). |
| `inserted_at` | timestamp | Thời gian ghi nhận dữ liệu (Default: `CURRENT_TIMESTAMP`). |

### Table 7: `form_claim_chi_phi_internal_signature_form`

Lưu trữ dữ liệu phục vụ quy trình ký nội bộ cho form claim chi phí.

| Column Name | Data Type | Description |
| --- | --- | --- |
| `id` | text | **PK** - Mã định danh. |
| `manv` | text | Mã nhân viên. |
| `ky_chi_phi_kt` | timestamp | Kỳ chi phí kế toán. |
| `js_value` | jsonb | Nội dung dữ liệu. |
| `inserted_at` | timestamp | Thời gian ghi nhận dữ liệu (Default: `CURRENT_TIMESTAMP`). |

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
        * **Ngoại lệ:** Đối với tất cả các mã phòng ban khác, giá trị `data_hcp` mặc định trả về là một mảng rỗng `[]`.


    3. **Lọc danh sách Khách hàng (`data_kh_chung`):**
        * **Trường hợp 1 (Phòng HCP):** Truy vấn bảng `view_list_hcp`. Lấy danh sách `hco_bv` (Bệnh viện/PK) duy nhất (`DISTINCT`) từ danh sách bác sĩ đã lọc được ở bước 2.
        * **Trường hợp 2 (Phòng TP):** Truy vấn bảng `d_master_khachhang`. Lọc theo điều kiện `manv` và `supid` nằm trong thuộc địa bàn quản lý. Lấy `custid` và `custname`.
        * **Trường hợp 3 (Phòng MT):** Truy vấn bảng `d_master_khachhang`. Lấy tất cả DISTINCT của `pubcustid` và `pubcustname`.


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
        * Nếu tháng sinh (`p_thang_sinh` ) nhỏ hơn tháng hiện tại.
        * *Thông báo lỗi:* `"Đã quá thời gian chọn quà sinh nhật cho khách hàng"`.
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

  * **JSON Input (`body`):** *Array 1 phần tử*
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
            "array_hcp": [
                {
                    "ma_hcp_2": "HCP00021426-H",
                    "ten_hcp": "PHAN NGUYỄN ANH KHOA"
                }
            ],
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
            "array_hcp": [
                {
                    "ma_hcp_2": "HCP00021426-H",
                    "ten_hcp": "PHAN NGUYỄN ANH KHOA"
                }
            ],
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
        "khid": "CCP20260608170549642",
        "manv": "MR0055",
        "so_tien_claim": 600000,
        "lst_chon_invoices": [
        {
            "stt": 12,
            "check": true,
            "check_tm": 1,
            "clean_ten": "CONG TY TNHH DAU TU VA PHAT TRIEN HE THONG DAU THAU QUA MANG QUOC GIA | 00174256 | 08-06-2026 | 0108930466 | ",
            "so_hoa_don": "000174256",
            "ngay_hoa_don": "08-06-2026",
            "ten_hien_thi": "CÔNG TY TNHH ĐẦU TƯ VÀ PHÁT TRIỂN HỆ THỐNG ĐẤU THẦU QUA MẠNG QUỐC GIA | 000174256 | 08-06-2026 | 0108930466 | ",
            "tien_con_lai": 330000,
            "selected_time": "2026-06-08T17:06:14.322",
            "so_tien_claim": 330000,
            "ten_nguoi_ban": "CÔNG TY TNHH ĐẦU TƯ VÀ PHÁT TRIỂN HỆ THỐNG ĐẤU THẦU QUA MẠNG QUỐC GIA",
            "tong_tien_thanh_toan": 330000,
            "id_duy_nhat_cua_hoa_don": "019ea5bb498f71379cb0c8e7d8875221",
            "original_so_tien_claim": 330000,
            "zip_file_url": "https://bi.meraplion.com/DMS/form_claim_chi_phi_proof/0_CCP20260608170549642.zip"
        },
        {
            "stt": 13,
            "check": true,
            "check_tm": 1,
            "clean_ten": "CONG TY TNHH DAU TU VA PHAT TRIEN HE THONG DAU THAU QUA MANG QUOC GIA | 00173965 | 08-06-2026 | 0108930466 | ",
            "so_hoa_don": "000173965",
            "ngay_hoa_don": "08-06-2026",
            "ten_hien_thi": "CÔNG TY TNHH ĐẦU TƯ VÀ PHÁT TRIỂN HỆ THỐNG ĐẤU THẦU QUA MẠNG QUỐC GIA | 000173965 | 08-06-2026 | 0108930466 | ",
            "tien_con_lai": 220000,
            "selected_time": "2026-06-08T17:06:20.377",
            "so_tien_claim": 220000,
            "ten_nguoi_ban": "CÔNG TY TNHH ĐẦU TƯ VÀ PHÁT TRIỂN HỆ THỐNG ĐẤU THẦU QUA MẠNG QUỐC GIA",
            "tong_tien_thanh_toan": 220000,
            "id_duy_nhat_cua_hoa_don": "019ea5bb498d7367990ff54cd36eb274",
            "original_so_tien_claim": 220000,
            "zip_file_url": "https://bi.meraplion.com/DMS/form_claim_chi_phi_proof/1_CCP20260608170549642.zip"
        }
        ],
        "status": "I",
        "inserted_at": "2026-06-08T17:06:40.049"
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
            "ve_xe_cong_tac": 200000,
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

#### **Function (PYTHON):** `post_form_claim_chi_phi_excel_form`

* **Loại:** READ
* **Mục đích:** Tự động hóa việc tạo hồ sơ thanh toán chi phí dưới dạng file Excel chuẩn.
* **Logic các bước:**

    **1. Dữ liệu đầu vào (Input)**
    Hệ thống tiếp nhận yêu cầu từ người dùng với các thông tin sau:
    - **Khoảng thời gian:** Từ ngày (`from_date`) đến ngày (`to_date`).
    - **Nhân sự:** Mã nhân viên (`manv`) thực hiện claim.
    - **Định danh:** ID hồ sơ (`id`) để đặt tên file và lưu trữ.
    - **Lưu file:** Lưu file dưới local server.

    **2. Truy xuất dữ liệu nguồn**
    - Hệ thống gọi hàm xử lý trong cơ sở dữ liệu (`get_form_claim_chi_phi_excel_form`).
    - **Kết quả trả về:** Một gói dữ liệu bao gồm:
        - Thông tin chung (Người đề nghị, Bộ phận, Lý do...).
        - Danh sách chi tiết cho biểu mẫu **BMKT013** (Kế hoạch & Thực hiện).
        - Danh sách chi tiết cho biểu mẫu **BMKT002** (Đề nghị thanh toán).

    **3. Khởi tạo & Tải File Mẫu (Template)**
    - Hệ thống truy cập vào đường dẫn lưu trữ nội bộ trên server (`/app/thumuc/`).
    - Tải file Excel mẫu chuẩn có tên `form_claim_chi_phi_excel.xlsx`.
    - **Đặc điểm file mẫu:** File này đã được thiết kế sẵn layout, logo, tiêu đề, và định dạng khung viền chuẩn cho hai biểu mẫu BMKT013 và BMKT002. Hệ thống sẽ điền dữ liệu lên bản sao của file này chứ không ghi đè file gốc.

    **4. Quy tắc xử lý Biểu mẫu 1: BMKT013 (Kế hoạch & Thực hiện)**
    Hệ thống thực hiện điền dữ liệu vào Sheet `BMKT013-KH-TH-CP` theo các bước:
    - **Tiêu đề:** Tự động điền tháng/năm vào ô tiêu đề dựa trên thông tin "Từ ngày".
    - **Danh sách chi tiết:**
        - **Cơ chế dòng động (Dynamic Rows):** Hệ thống tự động chèn thêm số lượng dòng mới tương ứng với số lượng bản ghi dữ liệu thực tế.
        - **Thông tin hiển thị:** Điền các cột Khu vực, SupID, Khách hàng, Nội dung, Số hóa đơn, Ghi chú...
        - **Định dạng:** Ngày tháng (`dd/mm/yyyy`) và Số tiền (phân cách hàng ngàn).
    - **Dòng tổng cộng (Footer):**
        - Hệ thống xác định dòng cuối cùng ngay sau danh sách chi tiết vừa chèn.
        - Điền giá trị **"Tổng tiền kế hoạch"** và **"Tổng tiền duyệt"** vào đúng cột tương ứng.

    **5. Quy tắc xử lý Biểu mẫu 2: BMKT002 (Đề nghị thanh toán)**
    Hệ thống thực hiện điền dữ liệu vào Sheet `BMKT002-DNTT` theo các bước:
    - **Thông tin chung (Header):**
        - Điền tự động: Người đề nghị, Bộ phận, Lý do thanh toán vào phần đầu của phiếu.
    - **Danh sách chi tiết:**
        - **Cơ chế dòng động:** Tương tự BMKT013, hệ thống chèn dòng mới bắt đầu từ dòng số 9 để chứa dữ liệu chi tiết.
        - **Thông tin hiển thị:** STT, Nội dung, Số tiền, Số hóa đơn, Ngày hóa đơn...
    - **Dòng tổng cộng & Chữ ký (Footer):**
        - **Vị trí thông minh:** Hệ thống tự động tính toán vị trí dòng tổng cộng luôn nằm **ngay sau** dòng dữ liệu cuối cùng (Logic: `Start Row + Số dòng dữ liệu`).
        - **Giá trị:**
            - Điền **Tổng số tiền** bằng số.
            - Điền **Tổng số tiền bằng chữ** ngay dòng bên dưới.

    **6. Json format**
    - File Excel sau khi xử lý được lưu vào thư mục tạm trên server với tên file theo ID hồ sơ.
    - Hệ thống trả về một đường dẫn (URL) để người dùng tải file hoàn chỉnh về máy.

    JSON Input Example:
    ```json
        {
        "data": {
            "from_date": "2026-01-01",
            "to_date": "2026-01-01",
            "manv": "MR1391",
            "id": "MNV123_15_01_2026",
            "file_1": "https://bi.meraplion.com/DMS/form_claim_chi_phi_proof/0_MNV123_15_01_2026.zip",
            "inserted_at": "2026-01-01 11:11:11"
        },
        "files": "(binary)",
        "file_metadata_other": {
            "folder_to_save": "form_claim_chi_phi_proof",
            "file_rename_field": "id"
        }
        }
    ```
    
    JSON Output Example:
    ```json
    {
        "excel_url": "https://bi.meraplion.com/DMS/form_claim_chi_phi_excel_output/MR1391_01_01_2026.xlsx",
        "send_email_info": {
            "content": "<div email content </div>",
            "subject": "Thông tin đề nghị thanh toán chi phí công tác/giao tiếp/quà tặng Tháng 01/2026",
            "email_to": [
                {
                    "receive_code": "MR1391"
                },
                {
                    "receive_code": "MR1391"
                },
                {
                    "receive_code": "MR3119"
                }
            ],
            "email_bcc": []
        }
    }
    ```

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

          Dữ liệu trả về (đặc biệt là mảng `BMKT002`) được tổng hợp (UNION) từ 2 nguồn dữ liệu khác nhau với logic lọc riêng biệt:

          | Nguồn dữ liệu | Loại chi phí | Logic lọc (Filter Criteria) | Logic hiển thị |
          | :--- | :--- | :--- | :--- |
          | **Nguồn 1**<br>(`ds_chi_phi_tiep_khach`) | **Tiếp khách / Quà tặng**<br>(Từ Sales) | **Status:** Chỉ lấy Status = 'D' (Đã duyệt)<br>**Thời gian:** Lọc theo **KHOẢNG** (`ky_chi_phi_kt` \>= `fromDate` VÀ \<= `toDate`). | Hiển thị 1 dòng tổng thanh toán chi phí giao tiếp tháng. |
          | **Nguồn 2**<br>(`tong_hop_ctp`) | **Tổng hợp Công tác phí**<br>(Đi lại + Ăn uống + Vé xe + KS) | **Thời gian:** Lọc theo **KHOẢNG** (`ky_chi_phi_kt` \>= `fromDate` VÀ \<= `toDate`). | Gom thành 1 dòng tổng quát: "Công tác phí tháng: [MM-YYYY]". |

          **Ví dụ nguồn 1:**

        | STT (No.) | Nội dung chi tiết (Detailed content) | Số tiền (Amount) | Số chứng từ (Document number) | Ngày chứng từ (Issuance date) | Thời gian đề nghị chi (Proposed advance payment date) | Người nhận/đơn vị nhận tiền (Recipient/entity receiving payment) | Ghi chú (Notes) |
        | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
        | **** | **Thanh toán chi phí giao tiếp tháng: [MM-YYYY]** | **6,950,000** | **Trống** | **Trống** | **Trước ngày 20 tháng sau** | **MR0673 - Hồ Thị Hồng Gấm** | **Bảng kê chi tiết đính kèm** |

          **Ví dụ nguồn 2:**

        | STT (No.) | Nội dung chi tiết (Detailed content) | Số tiền (Amount) | Số chứng từ (Document number) | Ngày chứng từ (Issuance date) | Thời gian đề nghị chi (Proposed advance payment date) | Người nhận/đơn vị nhận tiền (Recipient/entity receiving payment) | Ghi chú (Notes) |
        | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
        | **** | **Công tác phí tháng: [MM-YYYY]** | **4,556,849** | **Trống** | **Trống** | **Trước ngày 20 tháng sau** | **MR0055 - Phan Thị Bình Khê** | **Bảng kê chi tiết đính kèm** |

    4.  **Logic tổng hợp cho biểu mẫu BMKT005 (Chi tiết Công tác phí):**
          * Danh sách chi tiết phụ cấp công tác (Đi lại, Ăn uống, Vé xe, Khách sạn) và các hóa đơn tương ứng.
          * Trả về chi tiết các hóa đơn và các dòng phụ cấp. Lưu ý số tiền tổng hợp chỉ được hiển thị ở dòng đầu tiên của mỗi nhóm (dòng có STT = 1 của từng khid), các dòng sau của cùng khoản công tác sẽ để trống (null) số tiền.

    5.  **Cấu trúc Footer (JSON Keys) cho các biểu mẫu:**
          * Ngoài mảng dữ liệu chính, hàm trả về các **Keys** riêng biệt để điền vào phần chân trang/chữ ký của biểu mẫu Excel:
              * `bmkt002_tong_so_tien`: Tổng số tiền đã được định dạng.
              * `bmkt002_so_tien_bang_chu`: Tổng số tiền được chuyển đổi thành chữ tiếng Việt.
              * `bmkt005_so_tien_bang_chu`: Số tiền công tác phí viết bằng chữ.
              * `bmkt002_ly_do_thanh_toan`: Chuỗi `"Thanh toán chi phí giao tiếp tháng: [MM-YYYY]"`.
              * `bmkt005_ly_do_thanh_toan`: Chuỗi `"Thanh toán tiền công tác phí tháng: [MM-YYYY]"`.
              * `send_email_info`: Cấu trúc JSON chứa thông tin gửi email, bao gồm danh sách người nhận (email_to) và nội dung HTML template sẵn có.
    
  * **JSON Input (`url_param`):**
    ```json
    {
        "fromDate": "2026-06-01",
        "toDate": "2026-06-01",
        "manv": "MR0055",
        "file_id": "MR0055_2026-06-01"
    }
    ```
  * **JSON Output:**
    ```json
    {
    "id": "MR0055_2026-06-01",
    "time": "2026-06-08T17:45:06.997607",
    "status": "ok",
    "BMKT002": [
        {
        "stt": 1,
        "ghi_chu": "Bảng kê chi tiết đính kèm",
        "so_tien": 2831004,
        "noi_dung": "Thanh toán chi phí giao tiếp tháng: 06-2026",
        "so_hoa_don": null,
        "ngay_hoa_don": null,
        "nguoi_nhan_tien": "MR0055 - Phan Thị Bình Khê",
        "thoi_gian_de_nghi": "Trước ngày 20 tháng sau"
        },
        {
        "stt": 2,
        "ghi_chu": "Bảng kê chi tiết đính kèm",
        "so_tien": 4556849,
        "noi_dung": "Công tác phí tháng: 06-2026",
        "so_hoa_don": null,
        "ngay_hoa_don": null,
        "nguoi_nhan_tien": "MR0055 - Phan Thị Bình Khê",
        "thoi_gian_de_nghi": "Trước ngày 20 tháng sau"
        }
    ],
    "BMKT005": [
        {
        "stt": 1,
        "ve_xe": 2555949,
        "ghi_chu": null,
        "so_ngay": 1,
        "khoan_muc": "a2",
        "tong_tien": 2556849,
        "so_hoa_don": "000000162",
        "ngay_hoa_don": "05/06/2026",
        "phu_cap_di_lai": 300,
        "nguoi_nhan_tien": "MR0055 - Phan Thị Bình Khê",
        "phu_cap_an_uong": 600,
        "chi_phi_giao_tiep": null,
        "chi_phi_khach_san": null,
        "noi_dung_chi_tiet": "Công tác An Giang từ ngày 05/06 đến 05/06"
        },
        {
        "stt": 2,
        "ve_xe": null,
        "ghi_chu": null,
        "so_ngay": 1,
        "khoan_muc": "a2",
        "tong_tien": null,
        "so_hoa_don": "000000700",
        "ngay_hoa_don": "05/06/2026",
        "phu_cap_di_lai": null,
        "nguoi_nhan_tien": "MR0055 - Phan Thị Bình Khê",
        "phu_cap_an_uong": null,
        "chi_phi_giao_tiep": null,
        "chi_phi_khach_san": null,
        "noi_dung_chi_tiet": "Công tác An Giang từ ngày 05/06 đến 05/06"
        },
        {
        "stt": 3,
        "ve_xe": null,
        "ghi_chu": null,
        "so_ngay": 1,
        "khoan_muc": "a2",
        "tong_tien": null,
        "so_hoa_don": "000004086",
        "ngay_hoa_don": "05/06/2026",
        "phu_cap_di_lai": null,
        "nguoi_nhan_tien": "MR0055 - Phan Thị Bình Khê",
        "phu_cap_an_uong": null,
        "chi_phi_giao_tiep": null,
        "chi_phi_khach_san": null,
        "noi_dung_chi_tiet": "Công tác An Giang từ ngày 05/06 đến 05/06"
        },
        {
        "stt": 4,
        "ve_xe": null,
        "ghi_chu": null,
        "so_ngay": 1,
        "khoan_muc": "A2",
        "tong_tien": 2000000,
        "so_hoa_don": "000001052",
        "ngay_hoa_don": "29/05/2026",
        "phu_cap_di_lai": 200000,
        "nguoi_nhan_tien": "MR0055 - Phan Thị Bình Khê",
        "phu_cap_an_uong": 200000,
        "chi_phi_giao_tiep": null,
        "chi_phi_khach_san": 1600000,
        "noi_dung_chi_tiet": "Công tác Bà Rịa - Vũng Tàu từ ngày 08/06 đến 08/06"
        }
    ],
    "BMKT013": [
        {
        "kenh": "INS",
        "ma_kh": "000477",
        "supid": "MR0055",
        "ten_kh": "BV LÂM ĐỒNG II - LD",
        "ghi_chu": "test",
        "khu_vuc": "MD1",
        "so_khid": "CCP20260605164015647",
        "supid_2": "MR0055",
        "duyet_kh": 100000,
        "noi_dung": "Chi phí giao tiếp đánh giá về hiệu quả của thuốc",
        "de_xuat_kh": 100000,
        "so_hoa_don": "001269910",
        "tenquanlytt": "Phan Thị Bình Khê",
        "ky_chi_phi_kt": "2026-06-01T00:00:00",
        "tenquanlytt_2": "Phan Thị Bình Khê",
        "ngay_thuc_hien": "2026-06-06",
        "ho_ten_nguoi_tiep": "HOÀNG THỊ THU HƯƠNG",
        "tong_tien_thuc_hien": 81000
        },
        {
        "kenh": "INS",
        "ma_kh": "001444",
        "supid": "MR0055",
        "ten_kh": "PKĐK TÂM AN SÀI GÒN - BTH",
        "ghi_chu": "test",
        "khu_vuc": "NTB",
        "so_khid": "CCP20260604155939343",
        "supid_2": "MR0055",
        "duyet_kh": 3500000,
        "noi_dung": "Chi phí gặp gỡ giao tiếp trao đổi thông tin",
        "de_xuat_kh": 3500000,
        "so_hoa_don": null,
        "tenquanlytt": "Phan Thị Bình Khê",
        "ky_chi_phi_kt": "2026-06-01T00:00:00",
        "tenquanlytt_2": "Phan Thị Bình Khê",
        "ngay_thuc_hien": null,
        "ho_ten_nguoi_tiep": "NGUYỄN THẢO,NGÔ GIANG VŨ",
        "tong_tien_thuc_hien": null
        }
    ],
    "bmkt002_ma_nv": "MR0055",
    "send_email_info": {
        "content": "<div style=\"font-family: Arial, sans-serif; line-height: 1.6; color: #000;\">\n\t<p><strong>Thông tin đề nghị thanh toán chi phí công tác/giao tiếp/quà tặng Tháng 06/năm 2026</strong></p>\n\t<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"width: 100%; max-width: 600px;\">\n\t\t<tr>\n\t\t\t<td style=\"padding: 5px 0; width: 160px;\"><strong>Mã người lập ĐNTT:</strong></td>\n\t\t\t<td style=\"border-bottom: 1px dotted #000;\">MR0055</td>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td style=\"padding: 5px 0;\"><strong>Tên người lập ĐNTT:</strong></td>\n\t\t\t<td style=\"border-bottom: 1px dotted #000;\">Phan Thị Bình Khê</td>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td style=\"padding: 5px 0;\"><strong>Phòng ban:</strong></td>\n\t\t\t<td style=\"border-bottom: 1px dotted #000;\">HCP</td>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td style=\"padding: 5px 0; color: #800000;\"><strong>Vị trí:</strong></td>\n\t\t\t<td style=\"border-bottom: 1px dotted #000;\">Senior Customer Relation Manager (HCP)</td>\n\t\t</tr>\n\t</table>\n\t<br>\n\t<p>1. Số tiền giao tiếp/quà tặng đề nghị thanh toán Tháng 06/Năm 2026 là: 2,831,004 VNĐ</p>\n\t<p>2. Số tiền công tác phí đề nghị thanh toán Tháng 06/Năm 2026 là: 4,556,849 VNĐ</p>\n\t<p><strong>Tổng cộng số tiền đề nghị thanh toán là: 7,387,853 VNĐ</strong></p>\n\t<br>\n\t<p>📂 <strong>File đính kèm:</strong> <a href=\"https://bi.meraplion.com/DMS/form_claim_chi_phi_excel_output/MR0055_2026-06-30.xlsx\" target=\"_blank\" style=\"color: #0000EE; text-decoration: underline;\">Tải file chi tiết tại đây</a></p>\n</div>",
        "subject": "Thông tin đề nghị thanh toán chi phí công tác/giao tiếp/quà tặng Tháng 06/2026",
        "email_to": [
        {
            "receive_code": "MR0055"
        },
        {
            "receive_code": "MR0055"
        },
        {
            "receive_code": "MR3119"
        }
        ],
        "email_bcc": []
    },
    "bmkt002_ma_nv_kt": "MR2931",
    "bmkt002_department": "HCP",
    "bmkt002_ma_quan_ly": "MR0055",
    "bmkt002_nguoi_nhan": "MR0055 - Phan Thị Bình Khê",
    "bmkt002_tong_so_tien": "7,387,853",
    "bmkt002_nguoi_de_nghi": "MR0055 - Phan Thị Bình Khê",
    "bmkt002_ma_nguoi_duyet": "MR2931",
    "bmkt013_tong_tien_duyet": "7,800,000",
    "bmkt002_ly_do_thanh_toan": "Thanh toán chi phí giao tiếp tháng: 06-2026",
    "bmkt002_so_tien_bang_chu": "bảy triệu ba trăm tám mươi bảy nghìn tám trăm năm mươi ba đồng",
    "bmkt005_ly_do_thanh_toan": "Thanh toán tiền công tác phí tháng: 06-2026",
    "bmkt005_so_tien_bang_chu": "bốn triệu năm trăm năm mươi sáu nghìn tám trăm bốn mươi chín đồng",
    "bmkt013_tong_tien_ke_hoach": "7,800,000",
    "bmkt013_tong_tien_thuc_hien": "2,831,004",
    "bmkt005_tong_cong_tac_phi": "4,556,849"
    }
    ```

#### **Function:** `insert_form_claim_chi_phi_chung_tu`

* **Loại:** WRITE (UPSERT theo ID) vào bảng `form_claim_chi_phi_chung_tu`
* **Standard:** Tuân thủ tuyệt đối `write_insert_function.md`
* **Mục đích:** Lưu lại dữ liệu đi kèm với chứng từ upload.
* **Validation (Các quy tắc chặn lỗi):** Không có validation.
  * **JSON Input (`body` - Array wrapper):**
    ```json
    [
        {
            "from_date": "2026-01-01",
            "to_date": "2026-01-01",
            "manv": "MR1391",
            "id": "MNV123_15_01_2026",
            "file_1": "https://bi.meraplion.com/DMS/form_claim_chi_phi_proof/0_MNV123_15_01_2026.zip",
            "inserted_at": "2026-01-01 11:11:11"
        }
    ]
    ```
  * **JSON Output:** `{"status": "ok", "success_message": "Đã nhận thành công"}`

#### **Function:** `insert_form_claim_chi_phi_internal_signature_form`

* **Loại:** WRITE (UPSERT theo ID) vào bảng `form_claim_chi_phi_internal_signature_form`
* **Standard:** Tuân thủ tuyệt đối `write_insert_function.md`
* **Mục đích:** Lưu lại dữ liệu trình ký nội bộ cho form claim chi phí.
* **Validation (Các quy tắc chặn lỗi):** Không có validation phức tạp.
  * **JSON Input (`body` - Array wrapper):**
    ```json
    [
        {
            "id": "MR1391_2026-06-01",
            "manv": "MR1391",
            "ky_chi_phi_kt": "2026-06-01T00:00:00",
            "js_value": {},
            "raw_from_be":{},
            "inserted_at": "2026-06-08T18:00:00"
        }
    ]
    ```
  * **JSON Output:** `{"status": "ok", "success_message": "Đã nhận thành công"}`

-----

### 6.6. Nhóm Lịch sử Claim (History)

#### **Function:** `get_form_claim_chi_phi_history`

* **Loại:** READ
* **Standard:** Tuân thủ tuyệt đối `write_get_function.md`
* **Mục đích:** Lấy toàn bộ lịch sử claim chi phí của một nhân viên (hoặc toàn bộ nhân viên trong nhóm của CRM) theo tháng chi phí. Mỗi bản ghi kế hoạch trả về kèm mảng `list_invoices` chứa toàn bộ hóa đơn đã gắn (từ bảng `form_claim_chi_phi_hoa_don`).

* **Nguyên tắc lọc dữ liệu:**
    1. **Parse input:**
        * `p_manv`: Mã nhân viên truy vấn (NV tự xem hoặc CRM xem nhân viên).
        * `p_thang_chi_phi`: Tháng chi phí cần lọc (timestamp dạng `YYYY-MM-01`).

    2. **Xác định phân quyền (Permission via `strpos`):**
        * Lấy `supid` của `p_manv` từ bảng `d_users`.
        * Dùng `STRPOS` để lọc: chỉ lấy các bản ghi trong `form_claim_chi_phi` mà chuỗi kết hợp `(manv || ' ' || supid_cua_manv_do)` chứa `p_manv`.
        * **Ý nghĩa:** Nhân viên tự xem phiếu của mình; CRM xem được phiếu của tất cả nhân viên cấp dưới.

    3. **Lọc theo tháng chi phí:**
        * Điều kiện: `thang_chi_phi = p_thang_chi_phi` (so sánh theo tháng).

    4. **Tổng hợp hóa đơn (`list_invoices`):**
        * Với mỗi `id` trong `form_claim_chi_phi`, lấy tất cả bản ghi tương ứng từ `form_claim_chi_phi_hoa_don` (theo `khid`).
        * Gom thành mảng JSON (`jsonb_agg`) đặt tên `list_invoices`. Nếu không có hóa đơn nào thì trả về `[]`.

    5. **Làm giàu dữ liệu (Data Enrichment - CRM Info):**
        * Join bảng `d_users` (theo `manv = f.manv`) để lấy `supid` làm `ma_crm` và `tenquanlytt` làm `ten_crm`.
        * Không cần join thêm `d_hr_dsns` — tên CRM đã có sẵn trong `d_users.tenquanlytt`.
        * Trả về thêm 2 field: `ma_crm` và `ten_crm`.

* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR0673",
        "thang_chi_phi": "2025-10-01"
    }
    ```

* **JSON Output Specification:**
    ```json
    {
        "status": "ok",
        "rows": 2,
        "data": [
            {
                "id": "CCP20251012171819772",
                "status": "D",
                "status_vn": "Đã thanh toán",
                "manv": "MR0673",
                "tencvbh": "Hồ Thị Hồng Gấm",
                "ma_crm": "MR1137",
                "ten_crm": "Vũ Mừng",
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
                "ma_dip": "phunuvietnam",
                "so_ke_hoach": 666666,
                "max_ke_hoach": 2000000,
                "approved_so_ke_hoach": 666666,
                "so_tien_claim_hoa_don": 666666,
                "thang_chi_phi": "2025-10-01T00:00:00",
                "ky_chi_phi_kt": "2025-11-01T00:00:00",
                "inserted_at": "2025-10-12T17:18:19.772",
                "approved_at": "2025-10-13T09:00:00",
                "approved_manv": "MR1137",
                "claim_approved_at": "2025-10-20T14:00:00",
                "list_invoices": [
                    {
                        "khid": "CCP20251012171819772",
                        "id_duy_nhat_cua_hoa_don": "019b1124ef32775aa5fd80199daf5623",
                        "ten_nguoi_ban": "TRUNG TÂM Y TẾ HOA LƯ",
                        "so_hoa_don": "000018820",
                        "ngay_hoa_don": "2025-10-12T00:00:00",
                        "tong_tien_thanh_toan": 862100,
                        "so_tien_claim": 666666,
                        "selected_time": "2025-10-13T09:00:00",
                        "check_tm": 0,
                        "manv": "MR0673",
                        "cost_type": null,
                        "zip_file_url": "https://bi.meraplion.com/DMS/form_claim_chi_phi_proof/0_CCP20251012171819772.zip"
                    }
                ]
            },
            {
                "id": "CCP20251012171819773",
                "status": "I",
                "status_vn": "Đã gắn hóa đơn",
                "manv": "MR0673",
                "tencvbh": "Hồ Thị Hồng Gấm",
                "ma_crm": "MR1137",
                "ten_crm": "Vũ Mừng",
                "phongdeptsummary": "HCP",
                "chon_kh_chung": "007987",
                "pubcustname": "PK NGUYỄN THỊ BÍCH NGỌC - SG",
                "chon_hcp": "HCP1000001511-P",
                "ten_hcp": "VÕ THỊ NGỌC TRÂM",
                "qua_tang": "Quà tặng",
                "kenh": "CLC",
                "ty_le": null,
                "noi_dung": "Chi phí quà tặng dịp sinh nhật",
                "ghi_chu": "",
                "ma_dip": "sinhnhat",
                "so_ke_hoach": 500000,
                "max_ke_hoach": 2000000,
                "approved_so_ke_hoach": 500000,
                "so_tien_claim_hoa_don": null,
                "thang_chi_phi": "2025-10-01T00:00:00",
                "ky_chi_phi_kt": "2025-11-01T00:00:00",
                "inserted_at": "2025-10-12T10:00:00",
                "approved_at": "2025-10-13T08:00:00",
                "approved_manv": "MR1137",
                "claim_approved_at": null,
                "list_invoices": []
            }
        ]
    }
    ```
