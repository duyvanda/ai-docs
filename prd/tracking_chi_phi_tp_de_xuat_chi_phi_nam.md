# Product Requirements Document (PRD)

## Module Quản lý Đề xuất Chi phí Năm TP

## 1. Tổng quan (Overview)

Module này cho phép CRM lập kế hoạch và đề xuất chi tiết ngân sách đầu tư năm cho từng Nhà thuốc (NT)/Khách hàng (KH) theo từng loại hoạt động được giao. Hệ thống kiểm soát tổng chi phí đề xuất không vượt quá ngân sách đã được phê duyệt trước cho từng KH, đồng thời cung cấp luồng phê duyệt 1 cấp cho CRD để xem xét và điều chỉnh trước khi chốt kế hoạch.

Dữ liệu được tích hợp chặt chẽ với:

* **Hệ thống nhân sự (HRM):** Xác thực chức danh (`d_hr_dsns`) và cấp bậc quản lý (`d_users`) để phân quyền hiển thị và phê duyệt.
* **Hệ thống khách hàng (DMS):** Lấy thông tin khách hàng (`d_master_khachhang`).
* **Hệ thống Cấu hình (Settings):** Đồng bộ danh sách KH mục tiêu, danh mục hoạt động đầu tư, và tổng ngân sách được duyệt cho từng KH do bộ phận CX thiết lập.

---

## 2. Mục tiêu (Goals)

* **[Mục tiêu 1]: Số hóa kế hoạch đầu tư năm (Digitize Annual Plan):** Thay thế hoàn toàn quy trình Excel/giấy tờ, cho phép CRM lập đề xuất chi tiết trực tiếp trên hệ thống theo từng KH và từng loại hoạt động.
* **[Mục tiêu 2]: Kiểm soát ngân sách tự động (Budget Control):** Hệ thống tự động chặn khi tổng tiền đề xuất của CRM cho một KH vượt quá tổng ngân sách được duyệt trước cho KH đó.
* **[Mục tiêu 3]: Luồng duyệt linh hoạt (Flexible Approval):** Cho phép CRD chỉnh sửa số tiền duyệt theo từng hoạt động, tách biệt "số tiền đề xuất" (CRM) và "số tiền được duyệt" (CRD).

---

## 3. Đối tượng sử dụng (User Personas)

| Vai trò | Mô tả công việc trên hệ thống |
| :--- | :--- |
| **CX (Admin)** | - Upload file Excel cấu hình gồm 2 sheet: danh sách KH mục tiêu (kèm ngân sách và các hoạt động được gắn), và danh mục loại hoạt động đầu tư.<br>- Dữ liệu được ghi vào `settings_data` và là cơ sở cho toàn bộ luồng nghiệp vụ. |
| **CRM (Quản lý vùng)** | - Xem danh sách KH thuộc mình kèm tổng ngân sách và số dư còn lại.<br>- Nhập số tiền đề xuất cho từng hoạt động của từng KH (chỉ hiển thị các hoạt động được gắn cho KH đó).<br>- Theo dõi trạng thái phê duyệt từ CRD. |
| **CRD (Giám đốc vùng)** | - Xem toàn bộ đề xuất của các CRM cấp dưới, tổng hợp theo KH và hoạt động.<br>- Duyệt hoặc từ chối từng đề xuất, có thể chỉnh sửa số tiền duyệt trước khi xác nhận. |

---

## 4. User Flow & UI Overview (Chi tiết quy trình)

### Bước 1: CX Upload cấu hình hệ thống

1. CX chọn **năm áp dụng** (`applyfor`) trên giao diện trước khi upload (VD: `2026`). Đây là khóa để upsert settings và lọc dữ liệu về sau.
2. CX chuẩn bị file Excel gồm 2 sheet:
   - **Sheet `ds_kh`:** Danh sách KH mục tiêu (41 KH), gồm: Mã KH, Tên KH, Danh sách `appid` hoạt động được gắn (phân cách bằng dấu phẩy), Mã/Tên CRM phụ trách, Tỉnh, Tổng ngân sách được duyệt.
   - **Sheet `ds_app`:** Danh mục các loại hoạt động đầu tư, gồm: Loại (Chiến lược / Commercial), Nội dung mô tả, `appid`.
3. CX chọn file và nhấn Upload. Frontend xử lý 2 sheet thành JSON, gắn `applyfor` từ bước 1, rồi gọi hàm `insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings`. Dữ liệu ghi vào `settings_data`.

### Bước 2: CRM đề xuất ngân sách chi tiết

1. CRM mở form. Hệ thống load danh sách KH thuộc quyền quản lý của CRM (lọc theo `ma_crm` trong settings).
2. Với mỗi KH, hệ thống hiển thị:
   - Tổng ngân sách được duyệt (`ngan_sach`).
   - Tổng tiền CRM đã đề xuất (sum `so_tien_de_xuat` của các dòng status `H` và `C`).
   - Số dư ngân sách còn lại.
   - Chỉ các hoạt động (`appid`) được gắn cho KH đó trong settings.
3. CRM nhập số tiền đề xuất (`so_tien_de_xuat`) cho từng hoạt động.
4. **Validation (Tự động):**
   - **Rule 1 – Ngân sách KH:** Tổng `so_tien_de_xuat` của tất cả hoạt động cho một KH không được vượt quá `ngan_sach` của KH đó trong settings.
5. Submit thành công → các dòng được lưu với trạng thái **`H` (Chờ CRD duyệt)**.
   - Nếu đề xuất đã tồn tại (cùng `custid` + `appid` + `applyfor`), hệ thống **xóa dòng cũ và insert mới** (phục vụ chỉnh sửa).

### Bước 3: CRD duyệt và điều chỉnh

1. CRD mở màn hình duyệt. Hệ thống hiển thị toàn bộ đề xuất `H` của các CRM cấp dưới, nhóm theo KH.
2. CRD xem chi tiết từng đề xuất (Tên KH, loại hoạt động, số tiền CRM đề xuất, tổng ngân sách KH).
3. CRD nhập `so_tien_duyet` (có thể khác `so_tien_de_xuat`) và chọn **Duyệt (C)** hoặc **Từ chối (R)**.
4. Khi chọn **Từ chối (R)**, CRD bắt buộc phải nhập lý do (`ly_do_tu_choi`) trước khi xác nhận.
5. Có thể xử lý nhiều đề xuất cùng lúc.

---

## 5. Bảng trạng thái (Status Reference)

| Status | Tên | Diễn giải | Ai set |
| :---: | :--- | :--- | :--- |
| `H` | Pending | CRM đã gửi đề xuất, chờ CRD duyệt | CRM |
| `C` | Approved | CRD đã duyệt (số tiền duyệt có thể được điều chỉnh) | CRD |
| `R` | Rejected | CRD từ chối đề xuất | CRD |

**Luồng trạng thái:** `H` → `C` hoặc `H` → `R`

---

## 6. Thiết kế Cơ sở dữ liệu (Database Schema)

### Các table có sẵn/bên ngoài (External Tables):

**Table `d_hr_dsns`** (Nhân sự)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `msnvcsmmoi` | text | **PK** - Mã nhân viên |
| `chucdanhengtitlesum` | text | Chức danh (Dùng để check Role CX/CRM/CRD) |

**Table `d_users`** (Nhân sự)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `manv` | text | **PK** - Mã nhân viên |
| `supid` | text | Quản lý trực tiếp (CRD là supid của CRM) |

**Table `d_master_khachhang`** (Khách hàng)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `custid` | text | **PK** - Mã khách hàng |
| `custname` | text | Tên khách hàng |
| `channel` | text | Kênh |
| `hcotypeid` | text | Phân loại HCO |

---

### Các table mới của hệ thống (New Tables):

**Table: `tracking_chi_phi_tp_de_xuat_chi_phi_nam`**
*Mỗi dòng đại diện cho đề xuất chi phí của một CRM cho một cặp (KH, hoạt động) trong năm. Constraint unique: (`custid`, `appid`, `applyfor`).*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `uuid` | text | **PK** - Mã đề xuất (short-uuid) |
| `custid` | text | Mã Khách hàng (NT) |
| `appid` | text | Mã loại hoạt động đầu tư (VD: `tracking_chi_phi_tp_conference`) |
| `manv_crm` | text | Mã CRM tạo đề xuất |
| `so_tien_de_xuat` | numeric | Số tiền CRM đề xuất |
| `so_tien_duyet` | numeric | Số tiền CRD duyệt *(nullable, điền khi status = C)* |
| `status` | text | Trạng thái: `H` (Chờ duyệt), `C` (Đã duyệt), `R` (Từ chối) |
| `applyfor` | date | Năm/kỳ áp dụng (VD: `2026-01-01`) |
| **--- SYSTEM ---** | | |
| `inserted_at` | timestamp | Thời gian tạo (Mặc định: Current ICT time) |
| `ly_do_tu_choi` | text | Lý do từ chối *(nullable, bắt buộc khi status = R)* |
| `approved_at` | timestamp | Thời điểm CRD duyệt hoặc từ chối *(nullable)* |
| `approved_manv` | text | Mã CRD thực hiện duyệt/từ chối *(nullable)* |

---

### Table Cấu hình Hệ thống (Configuration Table)

**Table `settings_data`**
*Bảng cấu hình "All-in-One". Lưu toàn bộ danh sách KH, ngân sách, và danh mục hoạt động do CX upload.*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `appid` | text | **PK** - Giá trị cố định: `tracking_chi_phi_tp_de_xuat_chi_phi_nam` |
| `js` | jsonb | Chứa toàn bộ data cấu hình (xem mẫu JSON bên dưới) |
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

* **Loại:** WRITE (Configuration Upsert)
* **Mục đích:** Lưu trữ hoặc cập nhật cấu hình hệ thống. Frontend xử lý 2 sheet Excel thành JSON rồi gửi xuống.
* **File mẫu:** https://bi.meraplion.com/DMS/excel_file/tp_setting_de_xuat_chi_phi_hoat_dong_nam.xlsx
* **Bảng ảnh hưởng:** `settings_data`
* **Validation:** Người nhập phải có chức danh là CX.
* **Logic:** Upsert dựa trên `appid` và `applyfor`.

* **JSON Input (`body`):** Mảng chỉ có 1 phần tử.
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
                "ds_kh": [
                    {
                        "makhdms": "000691",
                        "ten_kh": "CT DP Hồng Đào - TP Cà Mau",
                        "appid_list": [
                            "tracking_chi_phi_tp_conference",
                            "tracking_chi_phi_tp_m_session",
                            "tracking_chi_phi_tp_consulting"
                        ],
                        "ma_crm": "MR1035",
                        "ten_crm": "Nguyễn Thanh Tài",
                        "tinh": "Cà Mau",
                        "ngan_sach": 100000000
                    },
                    {
                        "makhdms": "N07820280",
                        "ten_kh": "NT Tuyết Thảo 1 - Bạc Liêu",
                        "appid_list": [
                            "tracking_chi_phi_tp_conference",
                            "tracking_chi_phi_tp_m_session"
                        ],
                        "ma_crm": "MR1035",
                        "ten_crm": "Nguyễn Thanh Tài",
                        "tinh": "Bạc Liêu",
                        "ngan_sach": 100000000
                    }
                ],
                "ds_app": [
                    {
                        "loai": "Chiến lược",
                        "noi_dung": "Tư vấn (thuế/BI/cấu trúc/marketing/văn hóa/...)",
                        "appid": "tracking_chi_phi_tp_consulting"
                    },
                    {
                        "loai": "Chiến lược",
                        "noi_dung": "Hội nghị KH",
                        "appid": "tracking_chi_phi_tp_conference"
                    },
                    {
                        "loai": "Commercial",
                        "noi_dung": "Đào tạo CMSP (M.Session)",
                        "appid": "tracking_chi_phi_tp_m_session"
                    },
                    {
                        "loai": "Commercial",
                        "noi_dung": "Đào tạo Kỹ năng BH/CSKH",
                        "appid": "tracking_chi_phi_tp_sales_training"
                    },
                    {
                        "loai": "Commercial",
                        "noi_dung": "M.Masage",
                        "appid": "tracking_chi_phi_tp_m_message"
                    },
                    {
                        "loai": "Commercial",
                        "noi_dung": "Thưởng thi đua",
                        "appid": "tracking_chi_phi_tp_performance_bonus"
                    },
                    {
                        "loai": "Commercial",
                        "noi_dung": "Khám sức khỏe",
                        "appid": "tracking_chi_phi_tp_health_check"
                    },
                    {
                        "loai": "Commercial",
                        "noi_dung": "BHYT",
                        "appid": "tracking_chi_phi_tp_health_insurance"
                    },
                    {
                        "loai": "Commercial",
                        "noi_dung": "Kỷ niệm/YEP/Du lịch/Teambuilding/Tất niên",
                        "appid": "tracking_chi_phi_tp_anniversary"
                    },
                    {
                        "loai": "Commercial",
                        "noi_dung": "POSM (Nhãn)",
                        "appid": "tracking_chi_phi_tp_posm_label"
                    },
                    {
                        "loai": "Commercial",
                        "noi_dung": "POSM (Bảng hiệu)",
                        "appid": "tracking_chi_phi_tp_signboard"
                    },
                    {
                        "loai": "Commercial",
                        "noi_dung": "Khác (CTKM...)",
                        "appid": "tracking_chi_phi_tp_others"
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

* **JSON Output Fail:**
    ```json
    {
        "status": "fail",
        "error_message": "Bạn không có quyền thực hiện thao tác này."
    }
    ```

---

#### Function: `get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings`

* **Loại:** READ
* **Mục đích:** Lấy dữ liệu settings theo năm áp dụng.

* **JSON Input (`url_param`):**
    ```json
    {
        "appid": "tracking_chi_phi_tp_de_xuat_chi_phi_nam",
        "manv": "CX001"
    }
    ```

* **JSON Output:** Giống cấu trúc input của `insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings`.

---

### 7.1. Nhóm CRM – Đề xuất (Bước 2)

#### Function: `get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm`

* **Loại:** READ
* **Mục đích:** Lấy dữ liệu khởi tạo cho CRM: danh sách KH thuộc mình, hoạt động được gắn cho từng KH, tình trạng ngân sách và các đề xuất đã nhập.
* **Logic Filter:**
    * Lấy dòng settings có `appid = 'tracking_chi_phi_tp_de_xuat_chi_phi_nam'` và `inserted_at` **gần nhất** (latest) → xác định `applyfor` đang hiệu lực.
    * Lọc `ds_kh` trong settings đó theo `ma_crm = manv` đầu vào.
    * Với mỗi KH, tính tổng `so_tien_de_xuat` của các dòng status `H` và `C` trong bảng chính → `tong_de_xuat`.
    * Tính `so_du = ngan_sach - tong_de_xuat`.

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
        "ds_app": [
            {
                "loai": "Chiến lược",
                "noi_dung": "Hội nghị KH",
                "appid": "tracking_chi_phi_tp_conference"
            }
        ],
        "ds_kh": [
            {
                "makhdms": "000691",
                "ten_kh": "CT DP Hồng Đào - TP Cà Mau",
                "tinh": "Cà Mau",
                "ngan_sach": 100000000,
                "tong_de_xuat": 60000000,
                "so_du": 40000000,
                "appid_list": [
                    "tracking_chi_phi_tp_conference",
                    "tracking_chi_phi_tp_m_session"
                ],
                "de_xuat": [
                    {
                        "uuid": "aBcD1234",
                        "appid": "tracking_chi_phi_tp_conference",
                        "noi_dung": "Hội nghị KH",
                        "so_tien_de_xuat": 40000000,
                        "so_tien_duyet": null,
                        "ly_do_tu_choi": null,
                        "status": "H"
                    },
                    {
                        "uuid": "xYz9876z",
                        "appid": "tracking_chi_phi_tp_m_session",
                        "noi_dung": "Đào tạo CMSP (M.Session)",
                        "so_tien_de_xuat": 20000000,
                        "so_tien_duyet": 18000000,
                        "ly_do_tu_choi": null,
                        "status": "C"
                    },
                    {
                        "uuid": "pQrS3456",
                        "appid": "tracking_chi_phi_tp_consulting",
                        "noi_dung": "Tư vấn (thuế/BI/cấu trúc/marketing/văn hóa/...)",
                        "so_tien_de_xuat": 15000000,
                        "so_tien_duyet": null,
                        "ly_do_tu_choi": "Ngân sách không phù hợp với kế hoạch quý",
                        "status": "R"
                    }
                ]
            }
        ]
    }
    ```

---

#### Function: `insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm`

* **Loại:** WRITE (Insert / Upsert)
* **Mục đích:** CRM lưu đề xuất chi phí cho một hoặc nhiều cặp (KH, hoạt động).
* **Validation:**
    * **Rule 1 – Ngân sách KH:** Với mỗi `custid`, tổng `so_tien_de_xuat` (bao gồm dữ liệu đang insert và các dòng `H`/`C` đã có trong DB, sau khi trừ dòng cũ cùng uuid) không được vượt quá `ngan_sach` của KH đó trong settings.
* **Logic:**
    1. Sử dụng `jsonb_array_elements` để map JSON → CTE.
    2. Với mỗi phần tử: nếu `uuid` đã tồn tại → xóa dòng cũ và insert mới (phục vụ chỉnh sửa). Nếu chưa có → insert mới.
    3. Status mặc định khi insert: `H`.

* **JSON Input (`body`):** *Array, mỗi phần tử là 1 cặp (KH, hoạt động)*
    ```json
    [
        {
            "uuid": "aBcD1234",
            "custid": "000691",
            "appid": "tracking_chi_phi_tp_conference",
            "manv_crm": "MR1035",
            "so_tien_de_xuat": 40000000,
            "applyfor": "2026-01-01T00:00:00",
            "inserted_at": "2026-01-15T09:30:00"
        },
        {
            "uuid": "eEfG5678",
            "custid": "000691",
            "appid": "tracking_chi_phi_tp_m_session",
            "manv_crm": "MR1035",
            "so_tien_de_xuat": 20000000,
            "applyfor": "2026-01-01T00:00:00",
            "inserted_at": "2026-01-15T09:30:00"
        }
    ]
    ```

* **JSON Output:**
    ```json
    {
        "status": "ok",
        "success_message": "Đã lưu đề xuất thành công !!!"
    }
    ```

* **JSON Output Fail:**

  * **Rule 1 – Vượt ngân sách KH:**
    ```json
    {
        "status": "fail",
        "error_message": "Tổng đề xuất cho KH <Tên KH> là <xxx> đã vượt quá ngân sách được duyệt <xxx> !!!"
    }
    ```

---

### 7.2. Nhóm CRD – Duyệt (Bước 3)

#### Function: `get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crd`

* **Loại:** READ
* **Mục đích:** Lấy danh sách đề xuất của các CRM cấp dưới để CRD xem xét và duyệt.
* **Logic Filter:**
    * Lấy danh sách CRM cấp dưới của CRD dựa trên `d_users` (CRD là `supid` của CRM).
    * Lấy toàn bộ các dòng trong `tracking_chi_phi_tp_de_xuat_chi_phi_nam` có `manv_crm` thuộc danh sách CRM cấp dưới.
    * Join với settings để lấy `ten_kh`, `noi_dung` hoạt động, `ngan_sach`.
    * **Data Enrichment:** Tính tổng `so_tien_de_xuat` và `so_tien_duyet` theo từng KH.

* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR0001",
        "applyfor": "2026-01-01"
    }
    ```

* **JSON Output Specification:**
    ```json
    {
        "status": "ok",
        "rows": 5,
        "chucdanhengtitlesum": "REGIONAL DIRECTOR (CRD)",
        "applyfor": "2026-01-01T00:00:00",
        "data": [
            {
                "uuid": "aBcD1234",
                "custid": "000691",
                "ten_kh": "CT DP Hồng Đào - TP Cà Mau",
                "tinh": "Cà Mau",
                "appid": "tracking_chi_phi_tp_conference",
                "noi_dung": "Hội nghị KH",
                "loai": "Chiến lược",
                "manv_crm": "MR1035",
                "ten_crm": "Nguyễn Thanh Tài",
                "ngan_sach_kh": 100000000,
                "tong_de_xuat_kh": 60000000,
                "tong_duyet_kh": 18000000,
                "so_tien_de_xuat": 40000000,
                "so_tien_duyet": null,
                "status": "H",
                "inserted_at": "2026-01-15 09:30:00",
                "approved_at": null,
                "approved_manv": null
            }
        ]
    }
    ```

---

#### Function: `insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crd`

* **Loại:** WRITE (Update Status)
* **Mục đích:** CRD duyệt hoặc từ chối các đề xuất, có thể nhập `so_tien_duyet` khác với đề xuất của CRM.
* **Validation:** KHÔNG CÓ VALIDATION. CRD có toàn quyền điều chỉnh.
* **Logic:**
    1. Tạo bảng tạm từ JSON input.
    2. Update `status`, `so_tien_duyet`, `ly_do_tu_choi`, `approved_manv`, `approved_at` vào bảng chính theo `uuid`. Status chỉ nhận `C` hoặc `R`. Khi status = `R`, `ly_do_tu_choi` là bắt buộc.

* **JSON Input (`body`):** *Array, nhiều phần tử*
    ```json
    [
        {
            "uuid": "aBcD1234",
            "status": "C",
            "so_tien_duyet": 35000000,
            "ly_do_tu_choi": null,
            "approved_manv": "MR0001",
            "approved_at": "2026-01-20T14:00:00"
        },
        {
            "uuid": "eEfG5678",
            "status": "R",
            "so_tien_duyet": null,
            "ly_do_tu_choi": "Ngân sách không phù hợp với kế hoạch quý",
            "approved_manv": "MR0001",
            "approved_at": "2026-01-20T14:00:00"
        }
    ]
    ```

* **JSON Output:**
    ```json
    {
        "status": "ok",
        "success_message": "Cập nhật thành công."
    }
    ```
