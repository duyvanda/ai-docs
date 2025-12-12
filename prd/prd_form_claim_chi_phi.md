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
    * **System Logic:** Nếu kênh là `CLC & INS`, hệ thống tự động tách thành 2 bản ghi riêng biệt dựa trên tỷ lệ.
    * Gọi API `insert_form_claim_chi_phi`.

4.  **Feedback:**
    * Thành công: Hiển thị Alert xanh "Thao tác thành công".
    * Thất bại: Hiển thị Alert đỏ kèm thông báo lỗi.

-----
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

## 5. Thiết kế Cơ sở dữ liệu (Database Schema)

Hệ thống sử dụng PostgreSQL với 4 bảng dữ liệu chính để quản lý quy trình Claim chi phí và Công tác phí.

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
    1.  **Thông tin nhân viên:** Lấy thông tin cơ bản và phòng ban (`phongdeptsummary`) của user đang đăng nhập để quyết định giao diện (Ví dụ: Nếu là TP/MT thì ẩn dropdown chọn HCP).
    2.  **Lọc khách hàng (Customer Filter):** Chỉ tải danh sách Khách hàng/HCP thuộc địa bàn quản lý của nhân viên (`manv` nằm trong danh sách `concat_crs_sup`).
    3.  **Lọc chương trình quà tặng (Program Filter):**
          * Truy xuất bảng danh sách quà tặng.
          * **Quy tắc:** Chỉ lấy các chương trình (dịp tặng quà) mà nhân viên này **được phân bổ** hoặc có quyền tham gia (Active). Loại bỏ các chương trình rác hoặc của vùng khác.
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
  * **Standard:** Tuân thủ tuyệt đối write_insert_function.md
  * **Mục đích:** Xử lý logic kiểm tra và lưu dữ liệu khi Sales bấm "Gửi QL Duyệt".
  * **Logic Validate (Server-side):**
    1.  **Kiểm tra Sinh nhật:** Nếu nội dung là "Quà tặng sinh nhật" -\> Hệ thống tự động kiểm tra HCP đó có thông tin ngày sinh trong `view_list_hcp` hay không. Nếu không -\> Báo lỗi.
    2.  **Kiểm tra Lịch sử (Duplication Check):** Kiểm tra trong bảng `d_tracking_cost_hcp_v2`. Nếu HCP này đã nhận quà của chương trình này trong năm nay -\> Báo lỗi "HCP đã nhận quà này rồi".
    3.  **Kiểm tra Định mức (Budget Cap):** Tính tổng tiền đăng ký.
          * Nếu phòng ban là HCP: Max **2.000.000 VNĐ** / suất.
          * Nếu phòng ban là TP: Max **4.000.000 VNĐ** / suất.
          * Khác: Max **50.000.000 VNĐ**.
          * *Hành động:* Nếu vượt quá -\> Báo lỗi.
    4.  **Tự động tính toán:**
          * `thang_chi_phi`: Nếu là sinh nhật, tự động set về ngày 01 của tháng sinh HCP. Nếu là quà thường, set theo kỳ chi phí kế toán user chọn.
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
  * **Standard:** Tuân thủ tuyệt đối write_get_function.md
  * **Mục đích:** CRM lấy danh sách các khoản chi chờ duyệt (Status = 'H').
  * **Nguyên tắc lọc dữ liệu:** Query bảng `form_claim_chi_phi` join với `d_users` để lấy danh sách nhân viên cấp dưới của `manv` đang login.
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
  * **Mục đích:** CRM xác nhận duyệt (C) hoặc từ chối (R).
  * **Logic:** Update bảng `form_claim_chi_phi` các trường `status`, `approved_so_ke_hoach`, `approved_manv`, `approved_at` dựa trên ID gửi lên.
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
    1.  **Filter by User:** Chỉ lấy các bản ghi thuộc về nhân viên đang đăng nhập (`manv`).
    2.  **Filter by Status:** Chỉ lấy các bản ghi có `status = 'C'` (Confirmed/Approved by Admin, waiting for Invoice).
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
  * **Mục đích:** Lấy danh sách hóa đơn từ hệ thống Misa (`d_misa_invoice`) khả dụng để claim tiền.
  * **Nguyên tắc lọc dữ liệu:**
    1.  **Calculation:** Tính `tien_con_lai` = `tong_tien_thanh_toan` (tổng giá trị hóa đơn) - `so_tien_da_claim` (tổng tiền đã được map vào các phiếu khác).
    2.  **Filter by Balance:** Chỉ lấy các hóa đơn có `tien_con_lai` \> 10,000 VNĐ (để tránh các số dư rác).
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
  * **Mục đích:** Tạo mới tờ trình công tác phí (Header), bao gồm cả phụ cấp và gắn danh sách hóa đơn chi phí phát sinh (Detail) trong cùng một lượt submit.
  * **Validation (Thứ tự thực hiện theo Code):**
    1.  **Check Invoice Duplication:** Kiểm tra xem bất kỳ `id_duy_nhat_cua_hoa_don` nào trong danh sách gửi lên đã tồn tại trong bảng `form_claim_chi_phi_hoa_don` hay chưa.
          * **Điều kiện lỗi:** Nếu tìm thấy ít nhất 1 bản ghi trùng.
          * **Thông báo lỗi:** `"Hóa đơn đã được chọn"`.
  * **Logic:**
    1.  **Chuẩn bị dữ liệu (`data_input`):**
          * Parse JSON Input.
          * Xử lý định dạng ngày tháng đa dạng:
              * `ky_chi_phi_kt`: Format `YYYY-MM-DD`.
              * `ngay_hoa_don`, `selected_time`: Format `DD-MM-YYYY`.
              * `tu_ngay`, `den_ngay`, `inserted_at`: Format ISO Timestamp.
          * Chuyển đổi `check_tm` sang kiểu boolean/int.
    2.  **Insert Header (Luôn thực hiện):**
          * Insert dữ liệu vào bảng `form_cong_tac_phi`. Lưu các thông tin chung: ngày đi, ngày đến, phụ cấp, tỉnh công tác...
    3.  **Insert Detail (Có điều kiện):**
          * Kiểm tra độ dài mảng `lst_chon_invoices`. Nếu có dữ liệu (`arr_length >= 1`):
          * Insert vào bảng `form_claim_chi_phi_hoa_don`.
          * Map `check_tm` thành `1` (true) để đánh dấu hóa đơn thuộc CTP.
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
                    "check_tm": true,                 // true = Công tác phí
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
  * **Mục đích:** Lấy toàn bộ dữ liệu thô (Raw Data) của các khoản chi phí **đã được duyệt (Status = 'D')** để Backend/Frontend render ra file Excel báo cáo thanh toán (Form BMKT013 và BMKT002).
  * **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR0673",
        "fromDate": "2025-10-01", 
        "toDate": "2025-10-01" // luôn bị ép = fromDate từ fontend
    }
    ```
  * **JSON Output:**
    ```json
    {
        "status": "ok",
        
        // ------------------------------------------------------------------
        // SHEET BMKT013: Chi tiết chi phí tiếp khách
        // ------------------------------------------------------------------
        "BMKT013": [
            {
                "khu_vuc": "",                   
                "supid": "SUP001",               
                "tenquanlytt": "Nguyễn Văn Boss",
                
                // Hai trường này code SQL select lặp lại, FE có thể dùng hoặc bỏ qua
                "supid_2": "SUP001",             
                "tenquanlytt_2": "Nguyễn Văn Boss",

                "ma_kh": "CUS_001",              
                "ten_kh": "Công ty ABC",         
                "ho_ten_nguoi_tiep": "Anh Khách",
                "kenh": "OTC",                   
                "noi_dung": "Mua quà trung thu", 
                "so_khid": "CCP001",             
                "de_xuat_kh": 500000,            
                "duyet_kh": 500000,              
                "ngay_thuc_hien": "2025-10-15",  
                "tong_tien_thuc_hien": 500000,   
                "so_hoa_don": "00123",           
                "ghi_chu": "Ghi chú thêm"        
            }
        ],

        // ------------------------------------------------------------------
        // SHEET BMKT002: Tổng hợp đề nghị thanh toán
        // ------------------------------------------------------------------
        "BMKT002": [
            {
                "stt": 1,
                "noi_dung": "Mua quà trung thu", 
                "so_hoa_don": "00123",
                "ngay_hoa_don": "2025-10-15",
                "thoi_gian_de_nghi": "Trước ngày 20 tháng sau", 
                "nguoi_nhan_tien": "MR0673 - Nguyễn Văn A", 
                "ghi_chu": "Ghi chú từ Plan",    
                "so_tien": 500000
            },
            {
                "stt": 2,
                "noi_dung": "CTP THÁNG :10-2025, từ : 01-10-2025 đến: 02-10-2025", 
                "so_hoa_don": null,              
                "ngay_hoa_don": null,
                "thoi_gian_de_nghi": "Trước ngày 20 tháng sau",
                "nguoi_nhan_tien": "MR0673 - Nguyễn Văn A",
                "ghi_chu": "Công tác phí",       
                "so_tien": 300000                
            }
        ],

        // ------------------------------------------------------------------
        // FOOTER: Thông tin tổng hợp
        // ------------------------------------------------------------------
        "tong_so_tien": "800,000",             
        "so_tien_bang_chu": "Tám trăm ngàn đồng", 
        "nguoi_de_nghi": "MR0673 - Nguyễn Văn A",
        "department": "Phòng Kinh Doanh",
        "ly_do_thanh_toan": "Thanh toán chi phí giao tiếp tháng: 10-2025",
        "nguoi_nhan": "MR0673 - Nguyễn Văn A",
        "tong_so_tien": "2,000,000",
        "so_tien_bang_chu": "Hai triệu đồng chẵn",
        "nguoi_de_nghi": "MR0673 - Nguyễn Văn A",
        "department": "Phòng Kinh Doanh"
    }
    ```

#### **Nguyên tắc tổng hợp dữ liệu (Data Aggregation Logic):**

Dữ liệu trả về (đặc biệt là mảng `BMKT002`) được tổng hợp (UNION) từ 3 nguồn dữ liệu khác nhau với logic lọc riêng biệt:

| Nguồn dữ liệu | Loại chi phí | Logic lọc (Filter Criteria) | Logic hiển thị |
| :--- | :--- | :--- | :--- |
| **Nguồn 1**<br>(`lst_payment_1`) | **Tiếp khách / Quà tặng**<br>(Từ Sales) | **Status:** Chỉ lấy Status = 'D' (Đã duyệt)<br>**Thời gian:** Lọc theo **KHOẢNG** (`ky_chi_phi_kt` \>= `fromDate` VÀ \<= `toDate`). | Hiển thị chi tiết từng hóa đơn, người thụ hưởng, nội dung quà tặng. |
| **Nguồn 2**<br>(`lst_payment_2`) | **Phụ cấp CTP**<br>(Đi lại + Ăn uống) | **Số tiền:** Tổng phụ cấp \> 0.<br>**Thời gian:** Lọc theo **NGÀY CHÍNH XÁC** (`ky_chi_phi_kt` = `fromDate`). | Gom thành 1 dòng: "CTP THÁNG... từ... đến...".<br>Số hóa đơn = NULL. |
| **Nguồn 3**<br>(`lst_payment_3`) | **Hóa đơn CTP**<br>(Vé xe, KS...) | **Điều kiện:** Phải có hóa đơn đi kèm (ID Not Null).<br>**Thời gian:** Lọc theo **NGÀY CHÍNH XÁC** (`ky_chi_phi_kt` = `fromDate`). | Hiển thị chi tiết từng hóa đơn (Vé xe, KS) phát sinh trong chuyến đi. |