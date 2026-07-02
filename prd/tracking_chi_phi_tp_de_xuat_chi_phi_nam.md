# Product Requirements Document (PRD)

## Module Quản lý Đề xuất Chi phí Năm TP

## 1. Tổng quan (Overview)

Module này cho phép CRM lập kế hoạch và đề xuất chi tiết ngân sách đầu tư năm cho từng Nhà thuốc (NT)/Khách hàng (KH) theo từng loại hoạt động được giao. Hệ thống kiểm soát tổng chi phí đề xuất không vượt quá ngân sách đã được phê duyệt trước cho từng KH. Quy trình áp dụng luồng phê duyệt 2 cấp (CRD duyệt bước 1, CXD duyệt chốt) để xem xét và điều chỉnh trước khi chốt kế hoạch.

Dữ liệu được tích hợp chặt chẽ với:

* **Hệ thống nhân sự (HRM):** Xác thực chức danh (`d_hr_dsns`) và cấp bậc quản lý (`d_users`) để phân quyền hiển thị và phê duyệt.
* **Hệ thống khách hàng (DMS):** Lấy thông tin khách hàng (`d_master_khachhang`).
* **Hệ thống Cấu hình (Settings):** Đồng bộ danh sách KH mục tiêu, danh mục hoạt động đầu tư, ngân sách ước lượng cho từng hoạt động, và tổng ngân sách được duyệt cho từng KH do bộ phận CX thiết lập.

---

## 2. Mục tiêu (Goals)

* **[Mục tiêu 1]: Số hóa kế hoạch đầu tư năm (Digitize Annual Plan):** Thay thế hoàn toàn quy trình Excel/giấy tờ, cho phép CRM lập đề xuất chi tiết trực tiếp trên hệ thống theo từng KH và từng loại hoạt động.
* **[Mục tiêu 2]: Kiểm soát ngân sách tự động & linh hoạt (Budget Control):** CRM được phép linh hoạt phân bổ đề xuất (vượt mức ước lượng ban đầu của một hoạt động), miễn sao hệ thống tự động chặn đảm bảo tổng tiền đề xuất cho một KH không vượt quá tổng ngân sách định mức của KH đó.
* **[Mục tiêu 3]: Luồng duyệt 2 cấp (Flexible Approval):** Tách bạch thẩm quyền duyệt: CRM đề xuất → CRD duyệt kiểm tra → CXD duyệt chốt cuối cùng. Người duyệt được phép tùy chỉnh số tiền duyệt độc lập với số đề xuất ban đầu.

---

## 3. Đối tượng sử dụng (User Personas)

| Vai trò | Mô tả công việc trên hệ thống |
| :--- | :--- |
| **CX (Admin)** | - Upload file Excel cấu hình gồm 2 sheet: danh mục hoạt động và danh sách KH (kèm tổng ngân sách KH và mức ngân sách ước lượng cho từng hoạt động được gắn).<br>- Dữ liệu được ghi vào `settings_data` làm core của hệ thống. |
| **CRM (Quản lý vùng)** | - Xem danh sách KH, tổng ngân sách KH và ngân sách ước lượng cho từng loại hoạt động.<br>- Nhập số tiền đề xuất và **ghi chú** cho từng hoạt động.<br>- Theo dõi trạng thái phê duyệt từ cấp quản lý. |
| **CRD (Giám đốc vùng)** | - Xem toàn bộ đề xuất của CRM cấp dưới.<br>- Duyệt chuyển tiếp lên CXD hoặc từ chối, có thể điều chỉnh số tiền duyệt (cấp CRD). |
| **CXD (Giám đốc CX / Cấp cao)** | - Xem toàn bộ đề xuất đã qua CRD duyệt.<br>- Duyệt chốt cuối cùng hoặc từ chối, có thể điều chỉnh số tiền duyệt chốt. |

---

## 4. User Flow & UI Overview (Chi tiết quy trình)

### Bước 1: CX Upload cấu hình hệ thống

1. CX chọn **năm áp dụng** (`applyfor`) trên giao diện trước khi upload (VD: `2026`). Đây là khóa để upsert settings và lọc dữ liệu về sau.
2. CX chuẩn bị file Excel gồm 2 sheet:
   - **Sheet `nt_options`:** Danh sách KH mục tiêu, gồm: Mã KH, Tên KH, Mã/Tên CRM phụ trách, Danh sách các hoạt động được gắn kèm **mức ngân sách ước lượng** của từng hoạt động, cùng với **Ghi chú** của CX (`cx_note`). *(Lưu ý: Tổng ngân sách định mức của KH sẽ được hệ thống tự động tính bằng tổng các `ngan_sach_uoc_luong` của KH đó)*.
   - **Sheet `hoat_dong_options`:** Danh mục các loại hoạt động đầu tư, gồm: Loại (Chiến lược / Commercial), `ten_hoat_dong`, `hoat_dong_id`.
3. CX chọn file và nhấn Upload. Frontend xử lý 2 sheet thành JSON, gắn `applyfor` từ bước 1, rồi gọi hàm `insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings`. Dữ liệu ghi vào `settings_data`.

### Bước 2: CRM đề xuất ngân sách chi tiết

1. CRM mở form. Hệ thống load danh sách KH thuộc quyền quản lý của CRM (lọc theo `ma_crm` trong settings).
2. Với mỗi KH, hệ thống hiển thị:
   - Tổng ngân sách định mức được duyệt *(Frontend tự động cộng tổng `ngan_sach_uoc_luong` của các hoạt động thuộc KH đó để hiển thị)*.
   - Tổng tiền CRM đã đề xuất.
   - Số dư ngân sách tổng còn lại.
   - Danh sách các hoạt động được gắn kèm **ngân sách ước lượng được duyệt** cho từng loại hoạt động.
3. CRM nhập **số tiền đề xuất** (`so_tien_de_xuat`) và bổ sung **ghi chú** (`ghi_chu`) cho từng hoạt động.
4. **Validation (Tự động):**
   - **Vượt mức ước lượng:** Số tiền CRM đề xuất cho một hoạt động **được phép vượt** quá mức ngân sách ước lượng của hoạt động đó (do CX upload chỉ là mức độ ước lượng ban đầu).
   - **Rule 1 – Chặn vượt tổng ngân sách KH:** Tuy nhiên, tổng `so_tien_de_xuat` của tất cả hoạt động cho một KH tuyệt đối không được vượt quá `ngan_sach` tổng của KH đó.
5. Submit thành công → các dòng được lưu với trạng thái **`H` (Hold - Chờ duyệt)**. Hệ thống thực hiện Upsert (cập nhật nếu đã có, thêm mới nếu chưa) theo khóa chính `id` để CRM có thể dễ dàng chỉnh sửa lại đề xuất.

### Bước 3: CRD duyệt

1. CRD mở màn hình duyệt. Hệ thống hiển thị toàn bộ đề xuất `H` (Hold) của các CRM cấp dưới, nhóm theo KH.
2. CRD xem chi tiết: Tên KH, loại hoạt động, ngân sách KH, mức đề xuất của CRM, ghi chú CRM.
3. CRD nhập `so_tien_duyet_crd` (có thể khác `so_tien_de_xuat`) và chọn **Duyệt (C - Confirmed)** hoặc **Từ chối (R - Rejected)**.
4. Khi chọn **Từ chối (R)**, bắt buộc phải nhập lý do (`ly_do_tu_choi`) trước khi xác nhận.

### Bước 4: CXD duyệt chốt

1. CXD mở màn hình duyệt. Hệ thống hiển thị toàn bộ đề xuất đã qua CRD duyệt (trạng thái `C` - Confirmed).
2. CXD xem chi tiết số tiền CRM đề xuất, ghi chú CRM, và số tiền CRD đã duyệt.
3. CXD nhập `so_tien_duyet_cxd` (số tiền chốt cuối cùng) và chọn **Duyệt chốt (D - Done)** hoặc **Từ chối (R - Rejected)**.
4. Khi chọn **Từ chối (R)**, bắt buộc phải nhập lý do (`ly_do_tu_choi`) trước khi xác nhận.

---

## 5. Bảng trạng thái (Status Reference)

| Status | Tên | Diễn giải | Ai set |
| :---: | :--- | :--- | :--- |
| `H` | Hold | CRM đã gửi đề xuất, chờ CRD duyệt | CRM |
| `C` | Confirmed | CRD đã duyệt, đang chờ CXD duyệt chốt | CRD |
| `D` | Done | CXD đã duyệt chốt thành công | CXD |
| `R` | Rejected | Bị CRD hoặc CXD từ chối | CRD / CXD |

**Luồng trạng thái:** `H` → `C` → `D` hoặc `H` → `R` hoặc `C` → `R`

---

## 6. Thiết kế Cơ sở dữ liệu (Database Schema)

### Các table có sẵn/bên ngoài (External Tables):

**Table `d_hr_dsns`** (Nhân sự)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `msnvcsmmoi` | text | **PK** - Mã nhân viên |
| `chucdanhengtitlesum` | text | Chức danh (Dùng để check Role CX/CRM/CRD/CXD) |

**Table `d_users`** (Nhân sự)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `manv` | text | **PK** - Mã nhân viên CRS (Chuyên viên Quan hệ Khách hàng) |
| `tencvbh` | text | Tên nhân viên CRS |
| `supid` | text | Mã quản lý trực tiếp / Giám sát bán hàng của CRS (còn gọi là `ma_crm`) |
| `tenquanlytt` | text | Tên quản lý trực tiếp của CRS |
| `asm` | text | Mã quản lý khu vực (Area Sales Manager ID - còn gọi là `ma_scrm`) |
| `tenquanlykhuvuc` | text | Tên quản lý khu vực của CRS |
| `rsmid` | text | Mã quản lý vùng (Regional Sales Manager ID - còn gọi là `ma_ncxm`) |
| `tenquanlyvung` | text | Tên quản lý vùng |

**Table `d_master_khachhang`** (Khách hàng)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `custid` | text | **PK** - Mã Khách Hàng Nội Bộ (hay gọi tắt là mã khách hàng) |
| `refcustid` | text | Mã KH Cũ |
| `custname` | text | Tên Khách Hàng |
| `address` | text | Địa chỉ Khách Hàng |
| `channel` | text | Mã Kênh |
| `shoptype` | text | Mã Kênh Phụ |
| `hcotypeid` | text | Mã Loại HCO |
| `hcotypename` | text | Tên Loại HCO |
| `classid` | text | Phân Hạng HCO |
| `shortterritorydescr` | text | Tên Khu Vực Viết Tắt |
| `statedescr` | text | Tên tỉnh |

---

### Các table mới của hệ thống (New Tables):

**Table: `tracking_chi_phi_tp_de_xuat_chi_phi_nam`**
*Mỗi dòng đại diện cho đề xuất chi phí của một CRM cho một cặp (KH, hoạt động) trong năm. Constraint unique: (`custid`, `hoat_dong_id`, `applyfor`).*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `id` | text | **PK** - Mã đề xuất. Format: `{custid}_{hoat_dong_id}_{yyyy}` (VD: `000691_tracking_chi_phi_tp_conference_2026`) |
| `custid` | text | Mã Khách hàng (NT) |
| `hoat_dong_id` | text | Mã loại hoạt động đầu tư (VD: `tracking_chi_phi_tp_conference`) |
| `ten_hoat_dong` | text | Tên loại hoạt động đầu tư (VD: `Hội nghị KH`) |
| `manv_crm` | text | Mã CRM tạo đề xuất |
| `thoi_gian_du_kien_thuc_hien` | text | Thời gian dự kiến thực hiện từ CRM *(nullable)* |
| `so_tien_de_xuat` | numeric | Số tiền CRM đề xuất |
| `ghi_chu` | text | Ghi chú của CRM cho hoạt động này *(nullable)* |
| `cx_note` | text | Ghi chú của CX cho hoạt động này *(nullable)* |
| `so_tien_duyet_crd` | numeric | Số tiền CRD duyệt *(nullable, điền khi status = C)* |
| `so_tien_duyet_cxd` | numeric | Số tiền CXD duyệt chốt *(nullable, điền khi status = D)* |
| `status` | text | Trạng thái: `H` (Hold), `C` (Confirmed), `D` (Done), `R` (Rejected) |
| `applyfor` | date | Năm/kỳ áp dụng (VD: `2026-01-01`) |
| **--- SYSTEM ---** | | |
| `inserted_at` | timestamp | Thời gian tạo (Mặc định: Current ICT time) |
| `ly_do_tu_choi` | text | Lý do từ chối *(nullable, bắt buộc khi status = R)* |
| `crd_approved_at` | timestamp | Thời điểm CRD duyệt/từ chối *(nullable)* |
| `crd_approved_manv` | text | Mã CRD thực hiện duyệt/từ chối *(nullable)* |
| `cxd_approved_at` | timestamp | Thời điểm CXD duyệt/từ chối *(nullable)* |
| `cxd_approved_manv` | text | Mã CXD thực hiện duyệt/từ chối *(nullable)* |

---

### Table Cấu hình Hệ thống (Configuration Table)

**Table `settings_data`**
*Bảng cấu hình "All-in-One". Lưu toàn bộ danh sách KH, ngân sách, danh mục hoạt động do CX upload.*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `appid` | text | **PK** - Giá trị cố định: `tracking_chi_phi_tp_de_xuat_chi_phi_nam` |
| `js` | jsonb | Chứa toàn bộ data cấu hình (bao gồm ngân sách ước lượng từng hoạt động) |
| `manv` | text | Mã nhân viên (CX) thực hiện upload |
| `inserted_at` | timestamp | Thời gian upload |
| `applyfor` | timestamp | Năm/kỳ áp dụng |

---

## 7. API & Function Specifications (Chi tiết kỹ thuật)

Hệ thống sử dụng **PostgreSQL Stored Functions** nhận và trả về JSONB.

URL get: `https://bi.meraplion.com/local/get_data/<ten_ham>`, **input json là query params**
URL post: `https://bi.meraplion.com/local/post_data/<ten_ham>`

---

### 7.0. Nhóm Settings (CX Upload)

#### Function: `insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings`

* Tải file mẫu settings: https://bi.meraplion.com/DMS/excel_file/tp_setting_de_xuat_chi_phi_hoat_dong_nam.xlsx

* **Loại:** WRITE (Configuration Upsert)
* **Mục đích:** Lưu trữ hoặc cập nhật cấu hình hệ thống.
* **JSON Input (`body`):** 
    ```json
    [
        {
            "appid": "tracking_chi_phi_tp_de_xuat_chi_phi_nam",
            "manv": "MR1682",
            "inserted_at": "2026-01-10T09:00:00",
            "applyfor": "2026-01-01T00:00:00",
            "settings_data": {
                "quy_tac_chung": {
                    "ten_chuong_trinh": "Đề xuất Chi phí Năm 2026"
                },
                "nt_options": [
                    {
                        "makhdms": "000691",
                        "ten_kh": "CT DP Hồng Đào - TP Cà Mau",
                        "ma_crm": "MR1035",
                        "ten_crm": "Nguyễn Thanh Tài",
                        "hoat_dong_id": "tracking_chi_phi_tp_conference",
                        "ngan_sach_uoc_luong": 30000000,
                        "cx_note": "Note từ CX"
                    },
                    {
                        "makhdms": "000691",
                        "ten_kh": "CT DP Hồng Đào - TP Cà Mau",
                        "ma_crm": "MR1035",
                        "ten_crm": "Nguyễn Thanh Tài",
                        "hoat_dong_id": "tracking_chi_phi_tp_m_session",
                        "ngan_sach_uoc_luong": 70000000,
                        "cx_note": ""
                    }
                ],
                "hoat_dong_options": [
                    {
                        "loai": "Chiến lược",
                        "ten_hoat_dong": "Hội nghị KH",
                        "hoat_dong_id": "tracking_chi_phi_tp_conference"
                    },
                    {
                        "loai": "Commercial",
                        "ten_hoat_dong": "Đào tạo CMSP (M.Session)",
                        "hoat_dong_id": "tracking_chi_phi_tp_m_session"
                    }
                ]
            }
        }
    ]
    ```
* **JSON Output:**
    ```json
    {
        "status": "ok",
        "success_message": "Cập nhật cấu hình thành công."
    }
    ```

#### Function: `get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings`
* **JSON Input (`url_param`):** Lấy dữ liệu settings theo `appid` và `manv`. Output cấu trúc tương tự cấu trúc insert.

---

### 7.1. Nhóm CRM – Đề xuất (Bước 2)

#### Function: `get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm`

* **Loại:** READ
* **Mục đích:** Lấy dữ liệu khởi tạo (Đề bài) cho CRM bao gồm danh sách KH, ngân sách tổng, và danh sách các hoạt động (ngân sách ước lượng) được phép đăng ký.
* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR1035"
    }
    ```
* **JSON Output Specification:**
    ```json
    {
        "status": "ok",
        "chucdanhengtitlesum": "AREA MANAGER (CRM)",
        "applyfor": "2026-01-01T00:00:00",
        "nt_options": [
            {
                "makhdms": "000691",
                "ten_kh": "CT DP Hồng Đào - TP Cà Mau",
                "tinh": "Cà Mau",
                "hoat_dong_id": "tracking_chi_phi_tp_conference",
                "ten_hoat_dong": "Hội nghị KH",
                "ngan_sach_uoc_luong": 30000000,
                "cx_note": "Note từ CX",
                "thoi_gian_du_kien_thuc_hien": "Tháng 05/2026",
                "so_tien_de_xuat": 40000000,
                "ghi_chu": "Làm event lớn vượt mức ước lượng",
                "status": "H"
            },
            {
                "makhdms": "000691",
                "ten_kh": "CT DP Hồng Đào - TP Cà Mau",
                "tinh": "Cà Mau",
                "hoat_dong_id": "tracking_chi_phi_tp_m_session",
                "ten_hoat_dong": "Đào tạo CMSP (M.Session)",
                "ngan_sach_uoc_luong": 70000000,
                "cx_note": "",
                "thoi_gian_du_kien_thuc_hien": null,
                "so_tien_de_xuat": null,
                "ghi_chu": null,
                "status": null
            }
        ],
        "hoat_dong_options": [
            {
                "hoat_dong_id": "tracking_chi_phi_tp_conference",
                "ten_hoat_dong": "Hội nghị KH"
            },
            {
                "hoat_dong_id": "tracking_chi_phi_tp_m_session",
                "ten_hoat_dong": "Đào tạo CMSP (M.Session)"
            }
        ]
    }
    ```

#### Function: `insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm`

* **Loại:** WRITE (Upsert)
* **Logic:** Thực hiện Upsert (Insert hoặc Update) dữ liệu vào bảng `tracking_chi_phi_tp_de_xuat_chi_phi_nam` dựa trên khóa chính `id` (`ON CONFLICT (id) DO UPDATE...`). Các record sẽ luôn được set `status = 'H'`. id: `{custid}_{hoat_dong_id}_{yyyy}`
* **JSON Input (`body`):**
    ```json
    [
        {
            "id": "000691_tracking_chi_phi_tp_conference_2026",
            "custid": "000691",
            "hoat_dong_id": "tracking_chi_phi_tp_conference",
            "ten_hoat_dong": "Hội nghị KH",
            "manv_crm": "MR1035",
            "thoi_gian_du_kien_thuc_hien": "Tháng 05/2026",
            "so_tien_de_xuat": 40000000,
            "ghi_chu": "Làm event lớn vượt mức ước lượng",
            "cx_note": "Note từ CX",
            "status": "H",
            "applyfor": "2026-01-01T00:00:00",
            "inserted_at": "2026-01-15T09:30:00"
        },
        {
            "id": "000691_tracking_chi_phi_tp_m_session_2026",
            "custid": "000691",
            "hoat_dong_id": "tracking_chi_phi_tp_m_session",
            "ten_hoat_dong": "Đào tạo CMSP (M.Session)",
            "manv_crm": "MR1035",
            "thoi_gian_du_kien_thuc_hien": "Quý 3/2026",
            "so_tien_de_xuat": 60000000,
            "ghi_chu": null,
            "cx_note": "",
            "status": "H",
            "applyfor": "2026-01-01T00:00:00",
            "inserted_at": "2026-01-15T09:30:00"
        }
    ]
    ```
* **Validation (Rule 1):** Báo lỗi nếu tổng số tiền đề xuất cho một `custid` vượt quá định mức `ngan_sach` tổng của KH.

---

### 7.2. Nhóm List Data Chung (CRM/CRD/CXD)

#### Function: `get_tracking_chi_phi_tp_de_xuat_chi_phi_nam`

* **Loại:** READ
* **Mục đích:** Lấy danh sách các đề xuất ngân sách để cấp quản lý (CRD, CXD) xem xét duyệt, hoặc để CRM xem lại lịch sử các đề xuất của mình.
* **Logic Filter:**
    1. Lấy toàn bộ records trong hệ thống (Tất cả user dù là CXD, Admin, CRD hay CRM đều xem được full data).
    2. Nếu `status` có truyền vào trong input (VD: `"status": "H"`, `"status": "C"`) → lọc thêm `WHERE status = input.status`.
    3. Nếu không có `status` → trả về tất cả các trạng thái.
* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR0001",
        "status": "H"
    }
    ```
* **JSON Output Specification:**
    ```json
    {
        "status": "ok",
        "rows": 1,
        "chucdanhengtitlesum": "CRM",
        "data": [
            {
                "id": "000691_tracking_chi_phi_tp_conference_2026",
                "custid": "000691",
                "custname": "CT DP Hồng Đào - TP Cà Mau",
                "statedescr": "Cà Mau",
                "manv_crm": "MR1035",
                "ten_crm": "Nguyễn Thanh Tài",
                "ngan_sach": 100000000,
                "hoat_dong_id": "tracking_chi_phi_tp_conference",
                "loai_hoat_dong": "Chiến lược",
                "ten_hoat_dong": "Hội nghị KH",
                "thoi_gian_du_kien_thuc_hien": "Tháng 05/2026",
                "so_tien_de_xuat": 40000000,
                "ghi_chu": "Làm event lớn vượt mức ước lượng",
                "cx_note": "Note từ CX",
                "so_tien_duyet_crd": null,
                "so_tien_duyet_cxd": null,
                "status": "H",
                "ly_do_tu_choi": null,
                "applyfor": "2026-01-01T00:00:00",
                "inserted_at": "2026-01-15T09:30:00",
                "crd_approved_at": null,
                "crd_approved_manv": null,
                "cxd_approved_at": null,
                "cxd_approved_manv": null
            }
        ]
    }
    ```

---

### 7.3. Nhóm CRD – Duyệt (Bước 3)

#### Function: `insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crd`

* **Mục đích:** CRD duyệt (cập nhật status thành `C`) hoặc từ chối (`R`), đồng thời ghi nhận số tiền do CRD duyệt.
* **Ràng buộc:** `crd_approved_manv` bắt buộc phải đúng mã là `MR0485`.
* **JSON Input (`body`):** 
    ```json
    [
        {
            "id": "000691_tracking_chi_phi_tp_conference_2026",
            "status": "C",
            "so_tien_duyet_crd": 35000000,
            "ly_do_tu_choi": null,
            "crd_approved_manv": "MR0485",
            "crd_approved_at": "2026-01-20T14:00:00"
        },
        {
            "id": "000691_tracking_chi_phi_tp_m_session_2026",
            "status": "R",
            "so_tien_duyet_crd": null,
            "ly_do_tu_choi": "Ngân sách không đủ",
            "crd_approved_manv": "MR0485",
            "crd_approved_at": "2026-01-20T14:15:00"
        }
    ]
    ```

---

### 7.4. Nhóm CXD – Duyệt Chốt (Bước 4)

#### Function: `insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_cxd`

* **Loại:** WRITE (Update Status)
* **Mục đích:** CXD duyệt chốt cuối cùng (thành `D`) hoặc từ chối (`R`), chốt số tiền duyệt.
* **Ràng buộc:** `cxd_approved_manv` bắt buộc phải đúng mã là `MR1214`.
* **JSON Input (`body`):** 
    ```json
    [
        {
            "id": "000691_tracking_chi_phi_tp_conference_2026",
            "status": "D",
            "so_tien_duyet_cxd": 35000000,
            "ly_do_tu_choi": null,
            "cxd_approved_manv": "MR1214",
            "cxd_approved_at": "2026-01-21T09:00:00"
        },
        {
            "id": "000691_tracking_chi_phi_tp_m_session_2026",
            "status": "R",
            "so_tien_duyet_cxd": null,
            "ly_do_tu_choi": "Tạm hoãn hoạt động này",
            "cxd_approved_manv": "MR1214",
            "cxd_approved_at": "2026-01-21T09:30:00"
        }
    ]
    ```
