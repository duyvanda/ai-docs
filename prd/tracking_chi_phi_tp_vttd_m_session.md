# Product Requirements Document (PRD)

## Module Quản lý M.Session – Hội thảo Y khoa TP

## 1. Tổng quan (Overview)

Module **M.Session** cho phép CRS/CRM đề xuất và tổ chức các buổi hội thảo y khoa (Medical Session) tại Nhà thuốc (NT) hoặc địa điểm bên ngoài thuộc kênh TP. Hệ thống quản lý toàn bộ vòng đời sự kiện: từ lập đề xuất, phân công nhân sự hỗ trợ (CXS/CXM), duyệt đề xuất, đến nộp chứng từ thanh toán sau sự kiện.

Dữ liệu được tích hợp chặt chẽ với:

* **Hệ thống nhân sự (HRM):** Xác thực chức danh (`d_hr_dsns`) và cấp bậc quản lý (`d_users`) để phân quyền hiển thị và phê duyệt.
* **Hệ thống khách hàng (DMS/CRM):** Lấy danh sách NT hợp lệ theo tuyến và quyền phụ trách của CRS.
* **Danh sách NVBH Nhà thuốc:** Tổng hợp từ Zalo OA và file rời do Admin upload định kỳ qua Google Stitch.
* **Hệ thống Cấu hình (Settings):** Đồng bộ cấu hình nhãn, vật tư và tham số vận hành do Admin thiết lập.

---

## 2. Mục tiêu (Goals)

* **[Mục tiêu 1]: Số hóa quy trình đề xuất M.Session:** Thay thế hoàn toàn quy trình giấy tờ, cho phép CRS/CRM lập đề xuất tổ chức buổi hội thảo trực tiếp trên hệ thống với đầy đủ thông tin nhân sự, địa điểm và chi phí.
* **[Mục tiêu 2]: Quản lý lịch trình và phân công nhân sự hỗ trợ:** Kiểm soát xung đột lịch của CXS và CXM, đảm bảo mỗi cá nhân không bị book trùng lịch.
* **[Mục tiêu 3]: Kiểm soát chi phí sự kiện:** Theo dõi và ghi nhận các khoản chi phí (hội trường, máy chiếu, ăn uống) gắn với từng M.Session.
* **[Mục tiêu 4]: Quản lý chứng từ sau sự kiện:** Cung cấp luồng upload hình ảnh và file PDF chứng từ có cấu trúc, đồng thời ghi nhận thực tế vật tư đã sử dụng.

---

## 3. Đối tượng sử dụng (User Personas)

| Vai trò | Mô tả công việc trên hệ thống |
| :--- | :--- |
| **Admin** | - Upload file Excel settings và danh sách NVBH bên ngoài qua Google Stitch.<br>- Dữ liệu cấu hình được đồng bộ vào hệ thống để phục vụ các luồng nghiệp vụ. |
| **CRS (Trình dược viên)** | - Lập đề xuất M.Session: chọn NT, danh sách người tham gia, CXS/CXM hỗ trợ, nhãn, ngày giờ, địa điểm, chi phí.<br>- Nộp chứng từ sau sự kiện (hình ảnh, hóa đơn PDF). |
| **CRM (Quản lý trực tiếp)** | - Xem và theo dõi các đề xuất M.Session của nhân viên cấp dưới.<br>- Nộp chứng từ sau sự kiện. |
| **CXS (Chuyên viên sản phẩm)** | - Xem danh sách đề xuất được giao, lọc theo CRM/CXS/Mã NT.<br>- Điền danh mục vật tư cần mang theo.<br>- Điều chỉnh người đi nói bài và CXM hỗ trợ.<br>- Duyệt đề xuất.<br>- Ghi nhận thực tế vật tư đã dùng sau sự kiện. |

---

## 4. User Flow & UI Overview (Chi tiết quy trình)

> **Sơ đồ luồng (Google Stitch):** [https://stitch.withgoogle.com/projects/11139638456267145858](https://stitch.withgoogle.com/projects/11139638456267145858)

### 4.0. Luồng Admin – Upload dữ liệu

* Admin chuẩn bị 2 file Excel: **file settings** (cấu hình chương trình) và **file danh sách NVBH bên ngoài**.
* Hệ thống tự động sync dữ liệu vào các bảng cấu hình tương ứng.

### 4.1. Luồng CRS/CRM – Lập đề xuất M.Session

**B1: Chọn Nhà thuốc và xác nhận danh sách người tham gia**
* Chọn 1 NT (CODE & TÊN NT).
* Hệ thống hiển thị danh sách nhân viên của NT (tổng hợp từ Zalo OA + file rời).
* Tick chọn những người **không đi** để loại khỏi danh sách.
* Ghi nhận số lượng sẽ tham gia.
* Nếu danh sách **thiếu người**: bổ sung thêm bằng cách nhập Tên, Chức vụ, SDT *(SDT là optional với nhóm Nhân viên bán thuốc & Quản lý)*.
* Nếu danh sách **thừa người**: tick chọn để đánh dấu không tham gia.

**B2: Chọn CXM hỗ trợ**
* Chọn một hoặc nhiều CXM. Hệ thống cảnh báo nếu CXM đã có lịch trùng.
* **Ghi chú:** CXS được tự động gán dựa theo tài khoản đăng nhập khi CRS/CRM vào form, không cần chọn thủ công.

**B3: Chọn nhãn tập trung và nhãn còn lại**
* Chọn tối đa **4 nhãn** sản phẩm tập trung cho buổi M.Session.

**B4: Chọn ngày diễn ra sự kiện**
* Hiển thị date picker dạng lịch tháng để chọn ngày.
* Nếu ngày đã chọn có sự kiện khác của cùng NT hoặc cùng CXS/CXM: hiển thị **cảnh báo đỏ** ngay bên dưới bộ chọn ngày: *“Có thể trùng lịch với sự kiện nhà thuốc khác vào ngày này”*.
* Không chặn submit, chỉ cảnh báo để CRS/CRM tự quyết định.

**B5: Ca thực hiện**
* Chọn **Ca 1** (bắt buộc): Nhập giờ bắt đầu và giờ kết thúc.
* Chọn thêm **Ca 2** (optional): Nhập giờ bắt đầu và giờ kết thúc.
* **Lưu ý:** Thời gian giữa các ca không được trùng lập.

**B6: Địa điểm tổ chức**
* Chọn: **Tại NT** hoặc **Bên ngoài**.
* Điền thêm địa chỉ cụ thể và tên địa điểm (NH hoặc NT). Mặc định show địa chỉ NT trên DMS.

**B7: Chi phí hội trường** *(optional)*

**B8: Chi phí máy chiếu** *(optional)*

**B9: Chi phí ăn uống** *(bắt buộc)*

**B10: Ghi chú – Vật tư cần mang theo**
* Ghi chú yêu cầu mang theo Bút / VTTD.

**B11: Gửi đề xuất**
* Hệ thống validate toàn bộ các trường bắt buộc.
* Đơn được lưu với trạng thái **`H` (Chờ duyệt)** sau khi vượt qua validation.

> **Validation:** Tất cả các trường là bắt buộc, trừ các mục được ghi chú *optional* (B7, B8, SDT nhân viên bán thuốc & quản lý tại B1).

### 4.2. Luồng CXS – Duyệt đề xuất

> **Lưu ý:** Mọi CXS đều có thể xem được đề xuất của các CXS khác để hỗ trợ điều chỉnh khi cần.

**B1: Chọn đề xuất**
* Xem danh sách đề xuất CRS đã lập. Có thể lọc theo: CRM, CXS, Mã NT, Tên NT.

**B2: Điền danh mục vật tư**
* Nhập danh sách vật tư dự kiến cần mang theo cho M.Session.

**B3: Điều chỉnh người đi nói bài**
* Xác nhận hoặc thay đổi người đại diện trình bày trong buổi.

**B4: Điều chỉnh CXM**
* Xác nhận hoặc thay đổi CXM hỗ trợ.

**B5: Duyệt đề xuất**
* CXS xác nhận duyệt. Trạng thái đơn chuyển sang **`C` (Đã duyệt)**.

### 4.3. Luồng CRS/CRM – Xác nhận trước sự kiện

*Áp dụng sau khi đề xuất đã được CXS duyệt (`C`), trước ngày diễn ra sự kiện.*

**B1:** Chọn mã M.SESSION đã được duyệt.
**B2:** Xác nhận tham dự hoặc Hủy sự kiện.
* **Xác nhận tham dự:** Trạng thái chuyển sang **`I` (In Progress – Sẽ tham dự)**.
* **Hủy / Từ chối:** Trạng thái chuyển sang **`X` (Cancelled – Hủy)**. Yêu cầu điền lý do.

### 4.4. Luồng Chứng từ sau sự kiện

#### CRS/CRM – Nộp chứng từ
**B1:** Chọn mã M.SESSION có trạng thái `I` (đã xác nhận tham dự).
**B2:** Upload chứng từ:
* **File PDF:** 4 files (hóa đơn).
* **Hình ảnh:** 6–8 hình (bao gồm: 2 ảnh báo cáo, bill chuyển khoản, ảnh cửa hàng).
* Có thể chọn lại và upload lại từ đầu.

**B3:** Submit. Trạng thái chuyển sang **`U` (Updated – Đã nộp chứng từ)**.

> CRS/CRM vẫn có quyền **Hủy / Từ chối** ở bước này. Trạng thái chuyển sang **`X` (Cancelled)**. Yêu cầu điền lý do.

#### CXS – Ghi nhận vật tư thực tế
**B1:** Chọn mã M.SESSION đã được duyệt.
**B2:** Ghi nhận lại số lượng vật tư **thực tế đã sử dụng** (đối chiếu với đề xuất ban đầu của CRS).
**B3:** Submit.

---

### 4.5. Bảng trạng thái (Status Reference)

| Status | Tên | Diễn giải | Ai set |
| :---: | :--- | :--- | :--- |
| `H` | New | CRS/CRM vừa gửi đề xuất, chờ CXS duyệt | CRS/CRM |
| `C` | Completed | CXS đã duyệt, sự kiện được xác nhận sẽ tổ chức | CXS |
| `R` | Rejected | CXS từ chối đề xuất | CXS |
| `I` | In Progress | CRS/CRM xác nhận sẽ tham dự trước ngày sự kiện | CRS/CRM |
| `X` | Cancelled | Sự kiện bị hủy, có ghi lý do | CRS/CRM |
| `U` | Updated | CRS/CRM đã nộp chứng từ sau sự kiện | CRS/CRM |

**Luồng trạng thái chính:** `H` → `C` → `I` → `U`
**Luồng hủy:** `C` → `X` &nbsp;|&nbsp; `I` → `X`
**Luồng từ chối:** `H` → `R`

-----

## 5. Thiết kế Cơ sở dữ liệu (Database Schema)

### Các table có sẵn/bên ngoài (External Tables):

**Table `d_hr_dsns`** (Nhân sự)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `msnvcsmmoi` | text | **PK** - Mã nhân viên |
| `chucdanhengtitlesum` | text | Chức danh (Dùng để check Role CXS/CRM/CRS) |

**Table `d_users`** (Nhân sự)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `manv` | text | **PK** - Mã nhân viên |
| `supid` | text | Quản lý trực tiếp |

**Table `api_f_thongtin_tuyen_mcp_tp_pcl`** (Tuyến)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `manv` | text | Mã nhân viên (CRS) |
| `supid` | text | Quản lý (CRM) |
| `ma_khachhang` | text | Mã khách hàng (NT) |
| `tenkhachhang` | text | Tên khách hàng (NT) |

**Table `d_master_khachhang`** (Khách hàng)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `custid` | text | **PK** - Mã khách hàng |
| `custname` | text | Tên khách hàng |
| `channel` | text | Kênh (TP, ...) |
| `hcotypeid` | text | Phân loại HCO |
| `statedescr` | text | Tỉnh KH |

**Table `f_crawl_activate_ecom`** (Danh sách Zalo OA)
*Danh sách NVBH nhà thuốc thu thập được qua Zalo OA. Dùng để load danh sách người tham gia tại B1.*
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `customer_code` | text | Mã khách hàng (NT) |
| `customer_phone` | text | SĐT tài khoản Zalo OA của NT |
| `customer_name` | text | Tên tài khoản Zalo OA của NT |
| `follow_name` | text | Tên NVBH theo dõi |
| `follow_phone` | text | SĐT NVBH |
| `pharmacy_name` | text | Tên nhà thuốc |

### Các table mới của hệ thống (New Tables):

**Table 1: `tracking_chi_phi_tp_m_session`**
*Bảng lưu thông tin chính của mỗi đề xuất M.Session. Mỗi dòng tương ứng 1 buổi hội thảo.*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `m_session_id` | text | **PK** - Mã M.Session. Format: `{custid}-{mm-yyyy}-{short_uuid}`. VD: `NT001-04-2026-Xk9aB2` |
| `manv` | text | Mã CRS/CRM tạo đề xuất |
| `custid` | text | Mã Nhà thuốc (NT) |
| `manv_csx` | text | Mã CXS hỗ trợ (tự động gán theo tài khoản đăng nhập) |
| `ten_csx` | text |  |
| `manv_cxm_array` | jsonb | Danh sách CXM hỗ trợ. VD: `[{"ma_cxm": "MR001", "ten_cxm": "Nguyễn Văn A"}, {"ma_cxm": "MR002", "ten_cxm": "Trần Thị B"}]` |
| `nhan_tap_trung` | jsonb | Danh sách nhãn tập trung (tối đa 4). VD: `["ENT", "EYE"]` |
| `nhan_con_lai` | jsonb | Danh sách nhãn còn lại (không tập trung) được chọn trong buổi. VD: `["DERMA", "ORAL CARE"]` *(nullable)* |
| `ngay_su_kien` | date | Ngày diễn ra sự kiện |
| `ca_thuc_hien` | jsonb | Danh sách ca thực hiện. VD: `[{"ca": 1, "gio_bat_dau": "09:00", "gio_ket_thuc": "11:00"}, {"ca": 2, "gio_bat_dau": "14:00", "gio_ket_thuc": "16:00"}]` |
| `dia_diem_loai` | text | Loại địa điểm: `tai_nt` hoặc `ben_ngoai` |
| `dia_diem_dia_chi` | text | Địa chỉ cụ thể và tên địa điểm |
| `chi_phi_hoi_truong` | numeric | Chi phí hội trường *(nullable)* |
| `chi_phi_may_chieu` | numeric | Chi phí máy chiếu *(nullable)* |
| `chi_phi_an_uong` | numeric | Chi phí ăn uống dự kiến *(required)* |
| `chi_phi_an_uong_thuc_te` | numeric | Chi phí ăn uống thực tế *(nullable, điền khi nộp chứng từ)* |
| `chi_phi_hoi_truong_thuc_te` | numeric | Chi phí hội trường thực tế *(nullable)* |
| `chi_phi_may_chieu_thuc_te` | numeric | Chi phí máy chiếu thực tế *(nullable)* |
| `ghi_chu` | text | Ghi chú vật tư cần mang theo |
| `so_luong_tham_gia` | integer | Số người dự kiến tham gia |
| `danh_sach_tham_gia` | jsonb | Danh sách người xác nhận tham gia (từ Zalo OA + file rời). VD: `[{"ten": "Nguyễn A", "chuc_vu": "NVBT", "sdt": "090x", "nguon": "zalo_oa"}]` |
| `danh_sach_vat_tu` | jsonb | Danh mục vật tư dự kiến & thực tế (CXS điền). VD: `[{"ma_vat_tu": "VT001", "ten_vat_tu": "Bút", "so_luong_de_xuat": 10, "so_luong_thuc_te": null}]` |
| `ly_do_huy` | text | Lý do hủy *(nullable, điền khi status = X)* |
| `url_zip_file` | text | Đường dẫn các file PDF hóa đơn, phân cách bằng dấu phẩy *(nullable)* |
| `url_zip_image` | text | Đường dẫn các hình ảnh chứng từ, phân cách bằng dấu phẩy *(nullable)* |
| `status` | text | Trạng thái: `H` (New – Chờ CXS duyệt), `C` (Completed – CXS đã duyệt), `R` (Rejected – Từ chối), `I` (In Progress – CRS/CRM xác nhận tham dự), `X` (Cancelled – Đã hủy), `U` (Updated – Đã nộp chứng từ) |
| **--- SYSTEM ---** | | |
| `inserted_at` | timestamp | Thời gian tạo – CRS/CRM gửi đề xuất (`H`) |
| `approved_at` | timestamp | Thời gian CXS duyệt (`C`) *(nullable)* |
| `rejected_at` | timestamp | Thời gian từ chối (`R`) *(nullable)* |
| `in_progessed_at` | timestamp | Thời gian CRS/CRM xác nhận tham dự (`I`) *(nullable)* |
| `submitted_at` | timestamp | Thời gian nộp chứng từ (`U`) *(nullable)* |

**Table 2: `tracking_chi_phi_tp_m_session_danh_sach_khach_hang_file_roi`**
*Bảng lưu danh sách nhân viên bán hàng (NVBH) tại NT được Admin upload từ file rời (không thu thập được SDT qua Zalo OA). Dữ liệu này được dùng để hiển thị danh sách người tham gia tại B1.*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `ho_ten_duoc_sy` | text | **PK (1/2)** - HỌ TÊN DƯỢC SỸ |
| `chuc_vu` | text | CHỨC VỤ (VD: Chủ NT, Quản lý, NVBC) |
| `ma_hco_noi_bo` | text | **PK (2/2)** - MÃ HCO (nội bộ) |
| `ten_hco_noi_bo` | text | TÊN HCO (nội bộ) |
| `ma_khach_hang_thue` | text | MÃ KHÁCH HÀNG (mã thuế) |
| `ten_khach_hang_thue` | text | TÊN KHÁCH HÀNG (tên thuế) |
| `sdt` | text | Số điện thoại *(nullable)* |
| `manv` | text | Mã nhân viên CRS phụ trách NT |
| **--- SYSTEM ---** | | |
| `inserted_at` | timestamp | Thời gian upload (Mặc định: Current ICT time) |

### Table Cấu hình Hệ thống (Configuration Table)

**Table `settings_data`**
*Bảng cấu hình "All-in-One". Lưu trữ toàn bộ tham số vận hành (Danh mục, Định mức chi phí, Ngân sách nhân viên). Dữ liệu được cập nhật từ file Excel của Admin.*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `appid` | text | **PK** - Giá trị cố định: `tracking_chi_phi_tp_m_session` |
| `js` | jsonb | **Chứa toàn bộ data cấu hình** (Xem mẫu JSON chuẩn bên dưới) |
| `manv` | text | Mã nhân viên (Admin) thực hiện upload |
| `inserted_at` | timestamp | Thời gian thực hiện upload |
| `applyfor` | timestamp | Thời gian apply |

-----

## 6. API & Function Specifications (Chi tiết kỹ thuật)

Hệ thống sử dụng **PostgreSQL Stored Functions** nhận và trả về JSONB.

URL get: https://bi.meraplion.com/local/get_data/<ten_ham>, **input json là query params**

URL post: https://bi.meraplion.com/local/post_data/<ten_ham>


#### Function: `insert_tracking_chi_phi_tp_m_session_settings`


* Tải file mẫu settings: https://bi.meraplion.com/DMS/excel_file/tp_setting_m_session.xlsx

* Tải file mẫu dskh ngoài: https://bi.meraplion.com/DMS/excel_file/tp_setting_m_session_dskh_roi.xlsx

* **Loại:** WRITE (Configuration Upsert)
* **Mục đích:** Lưu trữ hoặc cập nhật cấu hình hệ thống M.Session. Dữ liệu nguồn từ file Google Sheet do Admin chuẩn bị, được Frontend xử lý thành JSON trước khi gửi xuống Server.
* **Bảng ảnh hưởng:** `settings_data`.
* **Validation:** Người nhập phải là CXS hoặc Admin.
* **Logic:** Upsert dựa trên `appid` và `applyfor`.

* **JSON Input (`body`):** Mảng chỉ có 1 phần tử.
    ```json
    [
        {
            "appid": "tracking_chi_phi_tp_m_session",
            "manv": "MR1682",
            "inserted_at": "2026-04-23T10:00:00.000",
            "applyfor":"2026-01-01T00:00:00", // giá trị mặc định
            "settings_data": {
                "nhan_tap_trung": [
                    "ENT",
                    "EYE",
                    "ANTI",
                    "GI"
                ],
                "nhan_con_lai": [
                    "DERMA",
                    "ORAL CARE"
                ],
                "dia_diem_thuc_hien": [
                    "Tại nhà thuốc",
                    "Bên ngoài"
                ],
                "chuc_vu_bo_sung": [
                    "NV đặt hàng",
                    "Quản lý cơ sở",
                    "Chủ cơ sở",
                    "Đại diện ký HĐ"
                ],
                "csx_cxm_incharge": [
                    {
                        "ma_cx": "MR3196",
                        "ten_cx": "Phạm Thanh Thảo",
                        "vai_tro": "CXS",
                        "ma_crm": "MR1156",
                        "ten_crm": "Huỳnh Văn Huy"
                    },
                    {
                        "ma_cx": "MR2458",
                        "ten_cx": "Nguyễn Tường Thanh",
                        "vai_tro": "CXM",
                        "ma_crm": null,
                        "ten_crm": null
                    }
                ],
                "csx_calendar": [
                    {
                        "ma_cx": "MR3196",
                        "ten_cx": "Phạm Thanh Thảo",
                        "ngay_ban": "26/04/2026"
                    },
                    {
                        "ma_cx": "MR3196",
                        "ten_cx": "Phạm Thanh Thảo",
                        "ngay_ban": "29/04/2026"
                    }
                ],
                "data_vttd_gm": [
                    {
                        "ma_vat_tu": "VT80385",
                        "ten_vat_tu": "Bút BenitaXylo",
                        "gia_tien": 7400
                    },
                    {
                        "ma_vat_tu": "VT80035",
                        "ten_vat_tu": "Bút Ebysta (8)",
                        "gia_tien": 7400
                    },
                    {
                        "ma_vat_tu": "VT80065",
                        "ten_vat_tu": "Balo",
                        "gia_tien": 110000
                    }
                ]
            }
        }
    ]
    ```

* **JSON Output:**
    ```json
    { "status": "ok", "success_message": "Đã cập nhật cấu hình thành công!" }
    ```

#### Function: `insert_tracking_chi_phi_tp_m_session_danh_sach_file_roi`

* **Loại:** WRITE (Bulk Insert / Truncate & Replace)
* **Mục đích:** Admin upload danh sách NVBH nhà thuốc từ file rời (file Excel). Frontend xử lý thành JSON rồi gửi xuống. Hàm thực hiện **xóa toàn bộ dữ liệu cũ** và insert lại toàn bộ danh sách mới.
* **Bảng ảnh hưởng:** `tracking_chi_phi_tp_m_session_danh_sach_khach_hang_file_roi`.
* **Validation:** Người nhập phải là CXS hoặc Admin.
* **Logic:** TRUNCATE bảng, sau đó bulk insert từ mảng JSON.

* **JSON Input (`body`):**
    ```json
    [
        {
            "manv":"MR1062",
            "ho_ten_duoc_sy": "Bùi Thị Tố Nga",
            "chuc_vu": "Chủ NT",
            "ma_hco_noi_bo": "N05802251",
            "ten_hco_noi_bo": "CTY Dược TM Nga (NT Thanh Hoải - Võ Tín cũ) - Nha Trang - Khánh Hòa",
            "ma_khach_hang_thue": "016563",
            "ten_khach_hang_thue": "Công Ty TNHH Dược Phẩm Và Thương Mại Nga",
            "sdt": null,
            "inserted_at": "2026-04-23T10:00:00.000"
        },
        {
            "manv":"MR1062",
            "ho_ten_duoc_sy": "Đoàn Thị Kim Linh",
            "chuc_vu": "Quản lý",
            "ma_hco_noi_bo": "N05802251",
            "ten_hco_noi_bo": "CTY Dược TM Nga (NT Thanh Hoải - Võ Tín cũ) - Nha Trang - Khánh Hòa",
            "ma_khach_hang_thue": "016563",
            "ten_khach_hang_thue": "Công Ty TNHH Dược Phẩm Và Thương Mại Nga",
            "sdt": null,
            "inserted_at": "2026-04-23T10:00:00.000"
        }
    ]
    ```

* **JSON Output:**
    ```json
    { "status": "ok", "success_message": "Đã cập nhật danh sách thành công!" }
    ```


### 6.1. Nhóm Load Data & Submit Form

#### **Function:** `get_tracking_chi_phi_tp_m_mession_de_xuat`

* **Loại:** READ
* **Mục đích:** Lấy toàn bộ dữ liệu khởi tạo cần thiết cho form lập đề xuất M.Session của CRS/CRM. Bao gồm: danh sách NT theo tuyến, danh sách người tham gia tại từng NT (Zalo OA + file rời), cấu hình settings (nhãn, vật tư, CXM, lịch bận), và thông tin role người đăng nhập.
* **Logic:**
    * Lấy danh sách NT theo tuyến của `manv` từ `api_f_thongtin_tuyen_mcp_tp_pcl` (kênh TP).
    * Với mỗi NT, tổng hợp danh sách người tham gia từ 2 nguồn: `f_crawl_activate_ecom` (nguon: `zalo_oa`) và `tracking_chi_phi_tp_m_session_danh_sach_khach_hang_file_roi` (nguon: `file_roi`), lọc theo `custid`.
    * Lấy settings từ `settings_data` với `appid = 'tracking_chi_phi_tp_m_session'`.
    * Xác định `manv_csx` tự động: tra trong `csx_cxm_incharge` (settings) theo `manv` đăng nhập. Nếu `manv` là CXS thì `manv_csx = manv`, nếu là CRS thì tra CXS phụ trách.
    * Lấy `chucdanhengtitlesum` từ `d_hr_dsns`.

* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR1077",
        "version": "2026-04-23"
    }
    ```

* **Logic version:** Nếu `version` không khớp với version hiện tại trong settings, trả về output fail ngay.

* **JSON Output Fail (version lỗi):**
    ```json
    {
        "status": "fail",
        "error_message": "Phiên bản đã cũ, vui lòng refresh lại trang!",
        "current_version": "2026-04-23"
    }
    ```

* **JSON Output Specification:**
    ```json
    {
        "status": "ok",
        "chucdanhengtitlesum": "CRS",
        "manv_csx": "MR3196",
        "ten_csx": "Phạm Thanh Thảo",
        "nt_options": [
            {
                "custid": "NT001",
                "custname": "NT Ngọc Nữ",
                "hcotypeid": "NT",
                "dia_chi": "123 Đường ABC, Q1, TP.HCM",
                "danh_sach_tham_gia": [
                    {
                        "ten": "Bùi Thị Tố Nga",
                        "chuc_vu": "Chủ NT",
                        "sdt": null,
                        "nguon": "file_roi"
                    },
                    {
                        "ten": "Nguyễn Văn A",
                        "chuc_vu": "NVBC",
                        "sdt": "0901234567",
                        "nguon": "zalo_oa"
                    }
                ]
            }
        ],
        "cxm_options": [
            // lọc từ csx_cxm_incharge WHERE vai_tro = 'CXM'
            {
                "ma_cxm": "MR2458",
                "ten_cxm": "Nguyễn Tường Thanh",
                "vai_tro":"CXM"
            }
        ],
        "csx_calendar": [
            {
                "ma_cx": "MR3196",
                "ten_cx": "Phạm Thanh Thảo",
                "ngay_ban": "26/04/2026"
            },
            {
                "ma_cx": "MR3196",
                "ten_cx": "Phạm Thanh Thảo",
                "ngay_ban": "29/04/2026"
            }
        ],
        "nhan_tap_trung": ["ENT", "EYE", "ANTI", "GI"],
        "nhan_con_lai": ["DERMA", "ORAL CARE"],
        "dia_diem_thuc_hien": ["Tại nhà thuốc", "Bên ngoài"],
        "chuc_vu_bo_sung": ["NV đặt hàng", "Quản lý cơ sở", "Chủ cơ sở", "Đại diện ký HĐ"],
        "data_vttd_gm": [
            {
                "ma_vat_tu": "VT80385",
                "ten_vat_tu": "Bút BenitaXylo",
                "gia_tien": 7400
            },
            {
                "ma_vat_tu": "VT80065",
                "ten_vat_tu": "Balo",
                "gia_tien": 110000
            }
        ],
        "version": "2026-04-23",
        "time": "2026-04-23 10:00:00+07"
    }
    ```

#### **Function:** `insert_tracking_chi_phi_tp_m_session_de_xuat`

* **Loại:** WRITE (Insert / Upsert)
* **Mục đích:** CRS/CRM gửi đề xuất M.Session mới. `m_session_id` được **Frontend sinh ra** theo format `{custid}-{mm-yyyy}-{short_uuid}`. Nếu `m_session_id` đã tồn tại (edit lại đề xuất đang ở trạng thái `H`) thì xóa và insert lại.
* **Bảng ảnh hưởng:** `tracking_chi_phi_tp_m_session`.
* **Validation:** KHÔNG CÓ VALIDATION.
* **Logic:**
    1. Nếu `m_session_id` đã tồn tại → DELETE dòng cũ.
    2. INSERT dòng mới với `inserted_at` từ input.

* **JSON Input (`body`):** *Array chỉ có duy nhất 1 phần tử*
    ```json
    [
        {
            "m_session_id": "NT001-04-2026-Xk9aB2",
            "status": "H",
            "manv": "MR1077",
            "custid": "NT001",
            "manv_csx": "MR3196",
            "ten_csx": "Phạm Thanh Thảo"  // ✅
            "manv_cxm_array": [
                {"ma_cxm": "MR2458", "ten_cxm": "Nguyễn Tường Thanh"}
            ],
            "nhan_tap_trung": ["ENT", "EYE"],
            "nhan_con_lai": ["DERMA"],
            "ngay_su_kien": "2026-05-10",
            "ca_thuc_hien": [
                {
                    "ca": 1,
                    "gio_bat_dau": "09:00",
                    "gio_ket_thuc": "11:00"
                },
                {
                    "ca": 2,
                    "gio_bat_dau": "14:00",
                    "gio_ket_thuc": "16:00"
                }
            ],
            "dia_diem_loai": "tai_nt",
            "dia_diem_dia_chi": "123 Đường ABC, Q1, TP.HCM",
            "chi_phi_hoi_truong": null,
            "chi_phi_may_chieu": null,
            "chi_phi_an_uong": 2000000,
            "ghi_chu": "Mang theo bút BenitaXylo và balo",
            "so_luong_tham_gia": 8,
            "danh_sach_tham_gia": [
                {
                    "ten": "Bùi Thị Tố Nga",
                    "chuc_vu": "Chủ NT",
                    "sdt": null,
                    "nguon": "file_roi"
                },
                {
                    "ten": "Nguyễn Văn A",
                    "chuc_vu": "NVBC",
                    "sdt": "0901234567",
                    "nguon": "zalo_oa"
                },
                {
                    "ten": "Trần Thị B",
                    "chuc_vu": "Quản lý cơ sở",
                    "sdt": "0912345678",
                    "nguon": "file_roi"
                }
            ],
            "inserted_at": "2026-04-23T10:00:00.000"
        }
    ]
    ```

* **JSON Output:**
    ```json
    {
        "status": "ok",
        "success_message": "Đã gửi đề xuất thành công!",
        "m_session_id": "NT001-04-2026-Xk9aB2"
    }
    ```

### 6.2. Nhóm Approval Flow (Duyệt)

#### **Function:** `get_tracking_chi_phi_tp_m_session_cxs`

* **Loại:** READ
* **Mục đích:** Lấy danh sách đề xuất M.Session để CXS duyệt hoặc để CRS/CRM xem lại các đơn của mình.
* **Bảng liên quan:** `tracking_chi_phi_tp_m_session`, `settings_data`, `d_hr_dsns`, `d_users`, `d_master_khachhang`.
* **Validation:** KHÔNG CÓ VALIDATION.
* **Logic Filter:**
    1. Lấy settings từ `settings_data` với `appid = 'tracking_chi_phi_tp_m_session'`, trích `csx_cxm_incharge`.
    2. Kiểm tra `manv` có nằm trong `csx_cxm_incharge` với `vai_tro = 'CXS'` hay không:
        * **Nếu CXS:** Lấy **toàn bộ** records trong bảng `tracking_chi_phi_tp_m_session` (không lọc theo manv).
        * **Nếu không phải CXS (CRS/CRM):**
            * Lấy danh sách của crm và nhân viên cấp dưới, xài hàm strpos.
    3. Nếu `status` có trong input → lọc thêm `WHERE status = input.status`. Nếu không có `status` → lấy tất cả.
    4. JOIN `d_master_khachhang` để lấy `custname`, `hcotypeid`, `statedescr`.
    5. Lấy `chucdanhengtitlesum` của `manv` từ `d_hr_dsns`.

* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR3196",
        "status": "H"
    }
    ```

* **JSON Output Specification:**
    ```json
    {
        "status": "ok",
        "rows": 2,
        "chucdanhengtitlesum": "CX-Staff",
        "data": [
            {
                "m_session_id": "NT001-04-2026-Xk9aB2",
                "manv": "MR1077",
                "ma_crm": "MR0319",
                "ten_crm": "Nguyễn Văn CRM",
                "manv_csx": "MR3196",
                "ten_csx": "Phạm Thanh Thảo",
                "manv_cxm_array": [
                    {"ma_cxm": "MR2458", "ten_cxm": "Nguyễn Tường Thanh"}
                ],
                "status": "H",
                "custid": "NT001",
                "custname": "NT Ngọc Nữ",
                "hcotypeid": "NT",
                "statedescr": "Khánh Hòa",
                "nhan_tap_trung": ["ENT", "EYE"],
                "nhan_con_lai": ["DERMA"],
                "ngay_su_kien": "2026-05-10",
                "ca_thuc_hien": [
                    {"ca": 1, "gio_bat_dau": "09:00", "gio_ket_thuc": "11:00"}
                ],
                "dia_diem_loai": "tai_nt",
                "dia_diem_dia_chi": "123 Đường ABC, Q1, TP.HCM",
                "chi_phi_hoi_truong": null,
                "chi_phi_may_chieu": null,
                "chi_phi_an_uong": 2000000,
                "ghi_chu": "Mang theo bút BenitaXylo và balo",
                "so_luong_tham_gia": 8,
                "danh_sach_tham_gia": [
                    {"ten": "Bùi Thị Tố Nga", "chuc_vu": "Chủ NT", "sdt": null, "nguon": "file_roi"},
                    {"ten": "Nguyễn Văn A", "chuc_vu": "NVBC", "sdt": "0901234567", "nguon": "zalo_oa"}
                ],
                "danh_sach_vat_tu": null,
                "ly_do_huy": null,
                "chi_phi_an_uong_thuc_te": null,
                "chi_phi_hoi_truong_thuc_te": null,
                "chi_phi_may_chieu_thuc_te": null,
                "url_zip_file": null,
                "url_zip_image": null,
                "inserted_at": "2026-04-23T10:00:00.000",
                "approved_at": null,
                "rejected_at": null
            }
        ]
    }
    ```

#### **Function:** `insert_tracking_chi_phi_tp_m_session_cxs`

* **Loại:** WRITE (Update Status + Danh sách vật tư)
* **Mục đích:** CXS duyệt (`C`) hoặc từ chối (`R`) một hoặc nhiều đề xuất M.Session, đồng thời lưu danh sách vật tư dự kiến cần mang theo (khi duyệt `C`).
* **Bảng ảnh hưởng:** `tracking_chi_phi_tp_m_session`.
* **Validation:** KHÔNG CÓ VALIDATION.
* **Logic:**
    1. Tạo bảng tạm từ JSON input.
    2. Với mỗi `m_session_id`:
        * Nếu `status = 'C'`: UPDATE `status = 'C'`, `manv_csx`, `ten_csx`, `manv_cxm_array`, `approved_at`, `danh_sach_vat_tu` từ input.
        * Nếu `status = 'R'`: UPDATE `status = 'R'`, `manv_csx`, `ten_csx`, `manv_cxm_array`, `rejected_at`, `ly_do_huy` từ input.

* **JSON Input (`body`):** *Array nhiều phần tử*
    ```json
    [
        {
            "m_session_id": "NT001-04-2026-Xk9aB2",
            "status": "C",
            "manv": "MR3196",
            "ten_csx": "Phạm Thanh Thảo",
            "manv_cxm_array": [
                {"ma_cxm": "MR2458", "ten_cxm": "Nguyễn Tường Thanh"}
            ],
            "approved_at": "2026-04-23T10:00:00.000",
            "danh_sach_vat_tu": [
                {
                    "ma_vat_tu": "VT80385",
                    "ten_vat_tu": "Bút BenitaXylo",
                    "so_luong_de_xuat": 10,
                    "so_luong_thuc_te": null
                },
                {
                    "ma_vat_tu": "VT80065",
                    "ten_vat_tu": "Balo",
                    "so_luong_de_xuat": 2,
                    "so_luong_thuc_te": null
                }
            ]
        },
        {
            "m_session_id": "NT002-04-2026-Yt3mC9",
            "status": "R",
            "manv": "MR3196",
            "ten_csx": "Phạm Thanh Thảo",
            "manv_cxm_array": [
                {"ma_cxm": "MR2458", "ten_cxm": "Nguyễn Tường Thanh"}
            ],
            "ly_do_huy": "Ngày tổ chức trùng với sự kiện khác.",
            "rejected_at": "2026-04-23T10:05:00.000",
            "danh_sach_vat_tu": null
        }
    ]
    ```

* **JSON Output:**
    ```json
    {
        "status": "ok",
        "success_message": "Đã cập nhật trạng thái thành công!"
    }
    ```

### 6.3. Nhóm Xác nhận trước sự kiện (CRS/CRM)

#### **Function:** `insert_tracking_chi_phi_tp_m_session_xac_nhan`

* **Loại:** WRITE (Update Status)
* **Mục đích:** CRS/CRM xác nhận sẽ tham dự (`I`) hoặc hủy sự kiện (`X`) sau khi đề xuất đã được CXS duyệt (`C`). Mỗi lần chỉ xử lý 1 `m_session_id`.
* **Bảng ảnh hưởng:** `tracking_chi_phi_tp_m_session`.
* **Validation:** KHÔNG CÓ VALIDATION.
* **Logic:**
    1. Nếu `status = 'I'`: UPDATE `status = 'I'`, `in_progressed_at` từ input.
    2. Nếu `status = 'X'`: UPDATE `status = 'X'`, `ly_do_huy` từ input, `in_progressed_at` từ input.

* **JSON Input (`body`):** *Array chỉ có duy nhất 1 phần tử*
    ```json
    [
        {
            "m_session_id": "NT001-04-2026-Xk9aB2",
            "manv": "MR1077",
            "status": "I",
            "ly_do_huy": null,
            "in_progressed_at": "2026-04-23T10:00:00.000"
        }
    ]
    ```

    *Ví dụ khi hủy:*
    ```json
    [
        {
            "m_session_id": "NT001-04-2026-Xk9aB2",
            "manv": "MR1077",
            "status": "X",
            "ly_do_huy": "Nhà thuốc báo hoãn sự kiện.",
            "in_progressed_at": "2026-04-23T10:00:00.000"
        }
    ]
    ```

* **JSON Output:**
    ```json
    {
        "status": "ok",
        "success_message": "Đã cập nhật trạng thái thành công!"
    }
    ```

### 6.4. Nhóm Nộp chứng từ & Quyết toán (CRS/CRM)

#### **Function:** `insert_tracking_chi_phi_tp_m_session_chung_tu`

* **Loại:** WRITE (Update Status)
* **Mục đích:** CRS/CRM nộp chứng từ sau sự kiện: upload file PDF, hình ảnh và nhập chi phí thực tế. Trạng thái chuyển sang `U`. Hoặc hủy sự kiện với `X` kèm lý do.
* **Bảng ảnh hưởng:** `tracking_chi_phi_tp_m_session`.
* **Validation:** KHÔNG CÓ VALIDATION.
* **Logic:**
    1. Nếu `status = 'U'`: UPDATE `status = 'U'`, `url_zip_file`, `url_zip_image`, `chi_phi_an_uong_thuc_te`, `chi_phi_hoi_truong_thuc_te`, `chi_phi_may_chieu_thuc_te`, `submitted_at` từ input.
    2. Nếu `status = 'X'`: UPDATE `status = 'X'`, `ly_do_huy`, `rejected_at` từ input.

* **JSON Input (`body`):** *Array chỉ có duy nhất 1 phần tử*
    ```json
    [
        {
            "m_session_id": "NT001-04-2026-Xk9aB2",
            "manv": "MR1077",
            "status": "U",
            "chi_phi_an_uong_thuc_te": 1800000,
            "chi_phi_hoi_truong_thuc_te": 500000,
            "chi_phi_may_chieu_thuc_te": null,
            "url_zip_file": "https://cdn.example.com/files/HoaDon_01.pdf,https://cdn.example.com/files/HoaDon_02.pdf",
            "url_zip_image": "https://cdn.example.com/images/anh_01.jpg,https://cdn.example.com/images/anh_02.jpg",
            "ly_do_huy": null,
            "submitted_at": "2026-04-23T10:00:00.000"
        }
    ]
    ```

    *Ví dụ khi hủy:*
    ```json
    [
        {
            "m_session_id": "NT001-04-2026-Xk9aB2",
            "manv": "MR1077",
            "status": "X",
            "chi_phi_an_uong_thuc_te": null,
            "chi_phi_hoi_truong_thuc_te": null,
            "chi_phi_may_chieu_thuc_te": null,
            "url_zip_file": null,
            "url_zip_image": null,
            "ly_do_huy": "Không thực hiện được sự kiện do mưa quá to",
            "rejected_at": "2026-04-23T10:00:00.000"
        }
    ]
    ```

* **JSON Output:**
    ```json
    {
        "status": "ok",
        "success_message": "Đã nộp chứng từ thành công!"
    }
    ```

### 6.5. Nhóm Tiện ích (Utility)

#### **Function:** `get_tracking_chi_phi_tp_chuc_danh`

* **Loại:** READ
* **Mục đích:** Lấy chức danh của nhân viên từ bảng HR. Dùng để Frontend xác định role người đăng nhập (CRS / CRM / CXS / CXM) sau khi có `manv`.
* **Bảng liên quan:** `d_hr_dsns`.
* **Validation:** KHÔNG CÓ VALIDATION.
* **Logic:** SELECT `chucdanhvntitle`, `chucdanhengtitle`, `chucdanhengtitlesum`, `phongdeptsummary`, `supervisor`, `managerassistantassociateasm` từ `d_hr_dsns` WHERE `msnvcsmmoi = manv`.

* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR1077"
    }
    ```

* **JSON Output:**
    ```json
    {
        "status": "ok",
        "manv": "MR3196",
        "chucdanhvntitle": "Nhân viên Trải nghiệm khách hàng",
        "chucdanhengtitle": "Customer Experience Staff",
        "chucdanhengtitlesum": "CX-Staff",
        "phongdeptsummary": "CXM-TP-MT",
        "supervisor": "Đinh Thị Ngọc Mẫn",
        "managerassistantassociateasm": "Nguyễn Thị Ngọc Diệp"
    }
    ```