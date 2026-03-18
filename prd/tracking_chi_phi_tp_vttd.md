# Product Requirements Document (PRD)

## Module Quản lý Đề xuất & Phê duyệt VTTD TP

## 1. Tổng quan (Overview)

Module này cho phép Trình dược viên (CRS) thực hiện đăng ký và đề xuất cấp phát vật tư tiêu điểm (VTTD), quà tặng hoặc vật phẩm trưng bày cho các Nhà thuốc (NT) thuộc kênh TP. Hệ thống tự động kiểm soát các quy tắc về ngân sách (định mức) và số lượng thiết lập từ trước, đồng thời cung cấp luồng phê duyệt 1 cấp cho Quản lý vùng (CRM) để ra quyết định.

Dữ liệu được tích hợp chặt chẽ với:

* **Hệ thống nhân sự (HRM):** Xác thực chức danh (`d_hr_dsns`) và cấp bậc quản lý (`d_users`) để phân quyền hiển thị và phê duyệt.
* **Hệ thống khách hàng (DMS/CRM):** Lấy danh sách khách hàng hợp lệ (NT) dựa trên tuyến và quyền phụ trách của CRS.
* **Hệ thống Cấu hình Ngân sách (Settings):** Đồng bộ cấu hình định mức ngân sách linh hoạt theo từng chu kỳ do bộ phận CXM thiết lập.

---

## 2. Mục tiêu (Goals)

* **[Mục tiêu 1]: Quản lý và kiểm soát ngân sách chặt chẽ (Budget Control):** Đảm bảo chi phí cấp phát vật tư không vượt quá định mức được giao cho từng cá nhân (CRS) và tổng ngân sách của khu vực (CRM).
* **[Mục tiêu 2]: Tự động hóa các quy tắc phân bổ (Rule Validation):** Hệ thống tự động chặn các đề xuất sai quy định như: nhập quá số lượng tối đa của một vật tư, hoặc vượt quá số lần đề xuất cho phép trên một Nhà thuốc (NT) trong kỳ.
* **[Mục tiêu 3]: Tối ưu hóa luồng công việc (Workflow Optimization):** Số hóa hoàn toàn quy trình đề xuất từ CRS đến CRM duyệt/từ chối, loại bỏ giấy tờ, đồng thời cung cấp dữ liệu đối soát theo thời gian thực (Real-time tracking) cho người quản lý.

---

## 3. Đối tượng sử dụng (User Personas)

| Vai trò | Mô tả công việc trên hệ thống |
| :--- | :--- |
| **CRS (Trình dược viên)** | - Tìm kiếm và chọn Nhà thuốc (NT) mục tiêu.<br>- Chọn mã vật tư (VTTD) và nhập số lượng cần cấp phát.<br>- Theo dõi ngân sách định mức cá nhân và trạng thái phê duyệt. |
| **CRM (Quản lý vùng)** | - Xem danh sách các đề xuất mới (Status: H) từ nhân viên trực thuộc.<br>- Đối soát định mức ngân sách của team với thực tế thực hiện.<br>- Thực hiện Duyệt (C) hoặc Từ chối (R) các đề xuất. |
| **CXM (Admin / Quản lý)** | - Tải lên file Excel cấu hình định kỳ: Thiết lập thời gian mở/đóng link, danh mục vật tư, giá tiền, số lượng tối đa, và định mức ngân sách cho từng CRS/CRM. |

---

## 4. User Flow & UI Overview (Chi tiết quy trình)

### 4.0. Thiết lập hệ thống (CXM)
* CXM chuẩn bị file cấu hình tổng (All-in-one).
* Upload file lên hệ thống để ghi nhận vào `settings_data` (bao gồm quy tắc chung, danh mục VTTD, định mức cá nhân, định mức quản lý). Hệ thống sẽ apply theo thời gian cấu hình.

### 4.1. Phân hệ [Đề xuất] - Trình dược viên (CRS)
1.  **Khởi tạo:** User mở form. Hệ thống load dữ liệu danh sách khách hàng (NT) thuộc quyền quản lý và hiển thị trạng thái ngân sách hiện tại (Định mức cá nhân vs Thực hiện).
2.  **Nhập liệu:** Chọn 1 Nhà thuốc (NT) cụ thể -> Chọn loại vật tư (VTTD) -> Nhập số lượng.
3.  **Hệ thống Validate (Tự động):**
    * *Tần suất:* Đã vượt số lần submit cho 1 NT chưa?
    * *Số lượng:* Số lượng VTTD nhập có vượt mức tối đa của món đó không?
    * *Ngân sách CRS:* Tổng tiền đề xuất có làm vượt định mức cá nhân không?
    * *Ngân sách CRM:* Tổng tiền có làm vượt định mức của cả khu vực (team) không?
4.  **Submit:** Vượt qua các validaton, đơn được lưu với trạng thái **`H` (Chờ duyệt)**.

### 4.2. Phân hệ [Quản lý Duyệt] - Quản lý vùng (CRM)
1.  **Danh sách chờ duyệt:** Mở màn hình duyệt, hệ thống hiển thị toàn bộ các đơn có trạng thái `H` của nhân viên cấp dưới.
2.  **Xem chi tiết:** Xem được chi tiết từng đơn (Tên NT, danh sách vật tư, giá tiền, tổng chi phí) kèm theo cảnh báo về ngân sách tổng của Team.
3.  **Xử lý:** * Chọn một hoặc nhiều đơn để **Duyệt (C - Completed)**.
    * Chọn một hoặc nhiều đơn để **Từ chối (R - Rejected)**.


-----

## 5. Thiết kế Cơ sở dữ liệu (Database Schema)

### Các table có sẵn/bên ngoài (External Tables):

**Table `d_hr_dsns`** (Nhân sự)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `msnvcsmmoi` | text | **PK** - Mã nhân viên |
| `chucdanhengtitlesum` | text | Chức danh (Dùng để check Role CXM/CRM) |

**Table `d_users`** (Nhân sự)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `manv` | text | **PK** - Mã nhân viên |
| `supid` | text | Quản lý |

**Table `api_f_thongtin_tuyen_mcp_tp_pcl`** (Tuyến)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `manv` | text | **PK** - Mã nhân viên |
| `supid` | text | Quản lý |
| `ma_khachhang` | text |  |
| `tenkhachhang` | text |  |

**Table `d_master_khachhang`** (khách hàng)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `custid` | text | **PK** - Mã nhân viên |
| `custname` | text | Quản lý |
| `channel` | text |  |
| `hcotypeid` | text |  |

### Các table mới của hệ thống (New Tables):

**Table 1: `tracking_chi_phi_tp_vttd`**
*Bảng lưu trữ chi tiết các vật tư được đề xuất. Dữ liệu được làm phẳng, mỗi dòng đại diện cho 1 vật tư. Primary Key là khóa phức hợp để đảm bảo tính duy nhất của vật tư trong cùng một lượt đề xuất.*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `uuid` | text | **PK** - Mã đơn đề xuất (Batch ID) |
| `ma_vat_tu` | text | **PK** - Mã vật tư/quà tặng |
| `manv` | text | Mã nhân viên tạo đề xuất (CRS) |
| `status` | text | Trạng thái: `H` (Chờ duyệt), `C` (Đã duyệt), `R` (Từ chối) |
| `custid` | text | Mã khách hàng (Nhà thuốc - NT) |
| `gia_tien` | numeric | Giá tiền của vật tư tại thời điểm đề xuất |
| `so_luong` | integer | Số lượng đề xuất |
| `applyfor` | date | Ngày bắt đầu áp dụng / hiệu lực |
| **--- SYSTEM ---** | | |
| `inserted_at` | timestamp | Thời gian tạo (Mặc định: Current ICT time) |
| `updated_at` | timestamp | Thời gian cập nhật (Mặc định: Current ICT time) |


### Table Cấu hình Hệ thống (Configuration Table)

**Table `settings_data`**
*Bảng cấu hình "All-in-One". Lưu trữ toàn bộ tham số vận hành (Danh mục, Định mức chi phí, Ngân sách nhân viên). Dữ liệu được cập nhật từ file Excel của Admin.*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `appid` | text | **PK** - Giá trị cố định: `form_seminar_hco` |
| `js` | jsonb | **Chứa toàn bộ data cấu hình** (Xem mẫu JSON chuẩn bên dưới) |
| `manv` | text | Mã nhân viên (Admin) thực hiện upload |
| `inserted_at` | timestamp | Thời gian thực hiện upload |
| `applyfor` | timestamp | Thời gian apply |

-----

## 6. API & Function Specifications (Chi tiết kỹ thuật)

Hệ thống sử dụng **PostgreSQL Stored Functions** nhận và trả về JSONB.

URL get: https://bi.meraplion.com/local/get_data/<ten_ham>

URL post: https://bi.meraplion.com/local/post_data/<ten_ham>

#### Function: `insert_tracking_chi_phi_tp_vttd_settings`

* **Loại:** WRITE (Configuration Upsert)
* **Mục đích:** Lưu trữ hoặc cập nhật cấu hình hệ thống. Dữ liệu nguồn từ file Excel do Admin upload, được Frontend xử lý thành JSON trước khi gửi xuống Server.
* **Bảng ảnh hưởng:** `settings_data`.

* **Validation (Các quy tắc chặn lỗi):**  Người nhập phải là CXM.

* **JSON Input (`body`):** Mảng chỉ có 1 phần tử.
    ```json
    [
        {
            "appid": "tracking_chi_phi_tp_vttd",
            "manv": "MR1682",
            "inserted_at": "2026-01-12T16:48:44.478",
            "applyfor":"2026-03-01T00:00:00",
            "settings_data": {
                "quy_tac_chung": {
                    "ten_chuong_trinh": "GIM TP Q1.2026",
                    "thoi_gian_mo_link": "20/03/2026",
                    "thoi_gian_dong_link": "31/03/2026",
                    "gioi_han_so_lan_submit_cho_1_nt": 1,
                    "dinh_muc_toi_da_cho_nt": 1000000,
                    "loai_kenh_phu_ap_dung": "TP",
                    "phan_loai_hco_ap_dung": "CTD,QT,NT",
                    "chi_phi_thang": "01/03/2026"
                    }
                ,
                "data_vttd_gm": [
                    {
                        "ma_vat_tu": "VT80385",
                        "ten_qua_tang": "Bút BenitaXylo",
                        "nhom_vat_tu": 65870000,
                        "gia_tien": 7400,
                        "so_luong_toi_da": 1565
                    },
                    {
                        "ma_vat_tu": "VT80035",
                        "ten_qua_tang": "Bút Ebysta (8)",
                        "nhom_vat_tu": 65870000,
                        "gia_tien": 7400,
                        "so_luong_toi_da": 1565
                    }
                ],
                "dinh_muc_crs": [
                    {
                        "ten_crm": "Lê Hoàng Ái",
                        "ma_crs": "MR2047",
                        "ten_crs": "Lê Văn Thái",
                        "dinh_muc": 65870000
                    },
                    {
                        "ten_crm": "Lê Hoàng Ái",
                        "ma_crs": "MR2047",
                        "ten_crs": "Lê Văn Thái",
                        "dinh_muc": 65870000
                    },
                ],
                "dinh_muc_crm": [
                    {
                        "manv": "MR0319",
                        "qlkv": "Lê Đức Châu",
                        "dinh_muc": 65870000
                    },
                    {
                        "manv": "MR1035",
                        "qlkv": "Nguyễn Thanh Tài",
                        "dinh_muc": 65500000
                    }
                ]

            }
        }
    ]
    ```

* **Logic (PostgreSQL Function Logic):**
    Hàm thực hiện chiến lược **Upsert** (Update nếu tồn tại, Insert nếu chưa có) dựa trên `appid` và `applyfor`.

#### Function: `get_tracking_chi_phi_tp_vttd_settings`

* **Loại:** WRITE (Configuration Upsert)
* **Mục đích:** Lưu trữ hoặc cập nhật cấu hình hệ thống cho Form đăng ký Seminar. Dữ liệu nguồn từ file Excel do Admin upload, được Frontend xử lý thành JSON trước khi gửi xuống Server.
* **Bảng ảnh hưởng:** `settings_data`.

* **JSON Input (`body`):**.
    ```json
        {
            "appid": "insert_tracking_chi_phi_tp_vttd",
            "manv": "MR1682",
            "applyfor":"2026-03-01",
        }
    ```

* **JSON Output (`body`):**.
    ```json
    // giống với input của hàm insert_tracking_chi_phi_tp_vttd_settings
    ```


### 6.1. Nhóm Load Data & Submit Form

#### **Function:** `get_tracking_chi_phi_tp_vttd_crs`

* **Loại:** READ
* **Mục đích:** Lấy dữ liệu khởi tạo cho crs chọn NT và nhập số lượng.
* **Logic Filter:**
	* Filter theo tuyến CRS + kênh và phân loại trong `settings`
* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR1077"
    }
    ```
* **JSON Output Specification:**
    ```json
    {
        "status": "ok",
        "nt_options": [
            {
                "custid": "NT001",
                "custname": "NT Ngọc Nữ",
                "hcotypeid": "NT"

            },
            {
                "custid": "NT001",
                "custname": "NT Ngọc Nữ",
                "hcotypeid": "NT"

            },
        ],
        // lấy từ câu query: select DISTINCT chon_phu from data_tao_form_hcp_bv where loai = 'NGÀNH CHUYÊN KHOA' order by chon_phu
        //giống input của settings
        "quy_tac_chung": {},
        "data_vttd_gm": [], 
        // lấy từ settings
        "dinh_muc": 1955000,
        "thuc_hiem": 1000000, // sum tổng theo quý hiện tại
        "chucdanhengtitlesum": "CRS", // chưa có thì để là "CXD"
        "time": "2025-12-31 10:00:00+07"
    }
    ```

#### **Function:** `insert_tracking_chi_phi_tp_vttd_crs`

* **Loại:** WRITE (Insert)
* **Mục đích:** Tạo mới đăng ký vttd tp.
* **Validation:** Chỉ apply cho Status H, C
  * **Rule 1 - Tần suất & định mức cho mỗi NT:** Số lần/tổng tiền NT nhập không được vượt quá số lần quy định trong.
  * **Rule 2 - Số lượng:** Đối với từng mã vật tư, số lượng nhập không được vượt quá số lượng tối đa cho phép.
  * **Rule 3 - Hạn mức CRS:** Tổng tiền CRS không được vượt quá định mức quy định cho CRS.
  * **Rule 4 - Hạn mức CRM:** Tổng tiền CRM không được vượt quá định mức quy định cho CRM.
* **Logic:** 
    1. Sử dụng `jsonb_array_elements` để map JSON => CTE. 
    2. Insert vô bảng `tracking_chi_phi_tp_vttd`. 
* **JSON Input (`body`):** *Array chỉ có duy nhất 1 phần tử*
    ```json
    [
        {
            "uuid": "2gYx5fZb", //uuid short (npm install short-uuid)
            "manv": "NV001",
            "status": "H",
            "custid": "CUST01",
            "applyfor": "2026-03-01",
            // làm phẵng mảng rồi insert
            "vttd" [
                {
                    "ma_vat_tu": "VT80385",
                    "ten_vat_tu": "VTxxxx",
                    "gia_tien": 7000,
                    "so_luong": 10
                },
                {
                    "ma_vat_tu": "VT80035",
                    "ten_vat_tu": "VTxxxx",
                    "gia_tien": 7000,
                    "so_luong": 10
                },
            ],
            "inserted_at": "2025-12-31T08:00:00"
        }
    ]
    ```

* **JSON Output:**
    ```json
    {
        "status": "ok",
        "success_message": "Đã nhận thông tin thành công !!!",
    }
    ```

* **JSON Output Fail:**
  * **Rule 1:**

    ```json
    {
        "status": "fail",
        "error_message": "NT đã được chọn rồi hoặc tổng tiền là <xxx> / tổng định mức <xxx> !!!"
    }
    ```

  * **Rule 2:**

    ```json
    {
        "status": "fail",
        "error_message": "Mã vật tư <xxx> đã vượt quá định mức <xxx>"
    }
    ```

  * **Rule 3:**

    ```json
    {
        "status": "fail",
        "error_message": "Tổng tiền của bạn <xxx> đã vượt quá định mức <xxx>"
    }
    ```

  * **Rule 4:**

    ```json
    {
        "status": "fail",
        "error_message": "Tổng tiền của team <xxx> đã vượt quá định mức <xxx>"
    }
    ```

### 6.2. Nhóm Approval Flow (Duyệt)

#### **Function:** `get_tracking_chi_phi_tp_vttd_crm`

* **Loại:** READ
* **Mục đích:** Lấy danh sách chưa cần duyệt để duyệt.
* **Logic Filter:**
	* Filter `status = 'H'`và lấy ra các bản ghi của nhân viên mình.
	* **Data Enrichment:** Tổng hợp thêm các phần tổng KH CRM và tổng thực hiện của các nhân viên.
* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR0319"
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
                "uuid": "2gYx5fZb",
                "manv": "NV001",
                "status": "H",
                "custid": "NT001",
                "custname": "NT Ngọc Nữ",
                "hcotypeid": "NT",
                "applyfor":"2026-03-01",

                "vttd" [
                  {
                      "ma_vat_tu": "VT80385",
                      "ten_vat_tu": "VTxxxx",
                      "gia_tien": 7000,
                      "so_luong": 10
                  },
                  {
                      "ma_vat_tu": "VT80035",
                      "ten_vat_tu": "VTxxxx",
                      "gia_tien": 7000,
                      "so_luong": 10
                  },
                ],

                "dinh_muc":300000,
                "thuc_hien":2500000

                "inserted_at": "2025-12-31 08:00:00"
            }
        ]
    }
    ```

#### **Function:** `insert_tracking_chi_phi_tp_vttd_crm`

* **Loại:** WRITE (Update Status)
* **Mục đích:** Cập nhật trạng thái duyệt/từ chối cho danh sách các đơn đã chọn.
* **Validation:** KHÔNG CÓ VALIDATION.
* **Logic:**
    1.  Tạo bảng tạm từ JSON input.
    2.  Update `status` và `updated_at` vào bảng chính. Trạng thái chỉ có C và R
* **JSON Input (`body`):** *Array 2 phần tử ví dụ*
    ```json
    [
        {
            "uuid": "2gYx5fZb",
            "status": "C",
            "manv": "MR0319",
            "inserted_at": "2025-12-31 10:00:00"
        },
        {
            "uuid": "2gYx5fZb",
            "status": "R",
            "manv": "MR0319",
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