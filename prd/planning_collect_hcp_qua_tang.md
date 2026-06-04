# Product Requirements Document (PRD)

## Module Quản lý Đề xuất Quà tặng HCP

## 1. Tổng quan (Overview)

Module này cho phép Trình dược viên (CRS) thực hiện đăng ký và đề xuất cấp phát quà tặng cho các chuyên gia y tế (HCP) thuộc tuyến quản lý. Hệ thống tự động kiểm soát các quy tắc về ngân sách (định mức cá nhân, định mức quản lý, định mức theo HCP) được thiết lập từ trước, đồng thời cung cấp luồng phê duyệt 1 cấp cho Quản lý vùng (CRM) để ra quyết định.

Dữ liệu được tích hợp chặt chẽ với:
* **Hệ thống nhân sự (HRM):** Xác thực cấp bậc quản lý (`d_users`) để phân quyền hiển thị tuyến và phê duyệt.
* **Hệ thống danh sách HCP (`view_list_hcp`):** Lấy danh sách khách hàng (HCP) hợp lệ dựa trên tuyến, kênh và quyền phụ trách của CRS.
* **Hệ thống cấu hình (Settings):** Đồng bộ cấu hình chương trình, thời gian mở/đóng link, danh mục quà tặng, và ngân sách linh hoạt theo từng chu kỳ.

-----

## 2. Mục tiêu (Goals)

* **[Mục tiêu 1]: Quản lý và kiểm soát ngân sách chặt chẽ:** Đảm bảo chi phí cấp phát quà tặng không vượt quá định mức tối đa cho một HCP, định mức cá nhân của CRS và tổng ngân sách của khu vực (CRM).
* **[Mục tiêu 2]: Tự động hóa các quy tắc phân bổ (Validation):** Hệ thống tự động chặn các đề xuất sai quy định như: quá thời gian đóng link, tặng quà cho HCP bị block (exclude list), hoặc trùng lặp đề xuất cho cùng một HCP.
* **[Mục tiêu 3]: Tối ưu hóa luồng công việc:** Số hóa hoàn toàn quy trình đề xuất từ CRS đến CRM duyệt/từ chối, loại bỏ giấy tờ, hỗ trợ tracking dữ liệu nhanh chóng.

-----

## 3. Đối tượng sử dụng (User Personas)

| Vai trò | Mô tả công việc trên hệ thống |
| :--- | :--- |
| **CRS (Trình dược viên)** | - Tìm kiếm và chọn HCP thuộc tuyến quản lý.<br>- Chọn quà tặng và nhập số lượng cần cấp phát.<br>- Gửi đề xuất và theo dõi trạng thái phê duyệt. |
| **CRM (Quản lý vùng)** | - Xem danh sách các đề xuất chờ duyệt (Status: H) từ nhân viên trực thuộc.<br>- Đối soát chi phí và thực hiện Duyệt (C) hoặc Từ chối (R) các đề xuất. |
| **Admin / CXM** | - Thiết lập thời gian mở/đóng link, chương trình, danh mục quà tặng, danh sách loại trừ (exclude list) và định mức ngân sách (thông qua Backend). |

-----

## 4. User Flow & UI Overview (Chi tiết quy trình)

### 4.0. Điều kiện tiên quyết (Pre-conditions)
*   **Kỳ đăng ký mở:** Quản lý/Admin (CXM) đã thiết lập thời gian mở link và chương trình quà tặng hợp lệ. Nếu ngoài thời gian quy định, trình dược viên sẽ không thể thao tác gửi đề xuất.

### 4.1. Phân hệ Đề xuất - Trình dược viên (CRS)

**Mục đích:** CRS chọn Bác sĩ/Dược sĩ (HCP) thuộc tuyến của mình để tặng quà và gửi lên quản lý duyệt.

1.  **Xem thông tin chương trình:** 
    *   Khi truy cập màn hình, CRS sẽ thấy rõ các thông tin về đợt tặng quà hiện tại: Tên chương trình, thời gian đăng ký (mở/đóng), ngân sách tối đa cho phép trên mỗi HCP, loại kênh và đối tượng áp dụng.
2.  **Chọn khách hàng (HCP):** 
    *   Hệ thống hiển thị danh sách các HCP hợp lệ thuộc tuyến của CRS (đã tự động loại bỏ các HCP nằm trong danh sách không được phép tặng quà).
    *   CRS tìm kiếm và tích chọn 1 HCP cần tặng quà.
3.  **Chọn quà tặng & Số lượng:** 
    *   CRS chọn món quà từ danh mục cho phép và nhập số lượng dự kiến tặng.
4.  **Gửi đề xuất:**
    *   CRS bấm nút "Gửi đề xuất".
    *   Hệ thống tự động kiểm tra ngay các quy định kinh doanh:
        *   HCP này đã được đề xuất tặng quà trong đợt này chưa? (Chặn trùng lặp).
        *   Tổng tiền quà tặng có vượt mức cho phép của 1 HCP không?
        *   Tổng chi tiêu của CRS có vượt ngân sách cá nhân không?
        *   Tổng chi tiêu của cả Team có vượt ngân sách vùng (CRM) không?
5.  **Kết quả hiển thị:**
    *   **Hợp lệ:** Đề xuất được ghi nhận thành công, đơn chuyển sang trạng thái **Chờ duyệt**.
    *   **Vi phạm quy định:** Màn hình hiển thị cảnh báo đỏ và nêu rõ lý do bị chặn (vd: "Đã vượt định mức HCP", "HCP này đã được gửi trước đó").

### 4.2. Phân hệ Phê duyệt - Quản lý vùng (CRM)

**Mục đích:** CRM kiểm tra và ra quyết định duyệt hoặc từ chối các đề xuất quà tặng từ đội ngũ CRS trực thuộc.

1.  **Xem danh sách chờ duyệt:** 
    *   CRM truy cập màn hình phê duyệt, hệ thống liệt kê toàn bộ các đề xuất đang ở trạng thái **Chờ duyệt** của nhân viên cấp dưới.
    *   CRM có thể sử dụng bộ lọc để xem danh sách theo từng nhân viên (CRS) cụ thể.
2.  **Kiểm tra thông tin:**
    *   CRM xem chi tiết từng đơn: Tên nhân viên đề xuất, Tên HCP nhận quà, Bệnh viện/Nhà thuốc, Loại quà và Số lượng.
3.  **Ra quyết định xử lý:**
    *   CRM tích chọn một hoặc nhiều đề xuất cùng lúc.
    *   Bấm **"Duyệt"**: Trạng thái các đơn đã chọn chuyển thành "Đã duyệt".
    *   Bấm **"Từ chối"**: Trạng thái các đơn đã chọn chuyển thành "Từ chối".
4.  **Kết quả hiển thị:**
    *   Hệ thống thông báo cập nhật thành công, danh sách chờ duyệt tự động làm mới để CRM tiếp tục xử lý.

-----

## 5. Thiết kế Cơ sở dữ liệu (Database Schema)

### Các table có sẵn/bên ngoài (External Tables):

**Table `view_list_hcp`** (Danh sách HCP)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `ma_hcp_2` | text | **PK** - Mã định danh HCP (Dùng để mapping chính) |
| `ma_hcp_1` | text | Mã nội bộ HCP |
| `ten_hcp` | text | Tên chuyên gia y tế |
| `phan_loai_hcp` | text | Phân loại (vd: BS, DS...) |
| `hco_bv` | text | Mã khách hàng / Bệnh viện chung |
| `concat_crs_sup` | text | Danh sách CRS và SUP phụ trách |

**Table `d_users`** (Nhân sự)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `manv` | text | **PK** - Mã nhân viên |
| `supid` | text | Quản lý trực tiếp (CRM) |

**Table `settings_data`** (Cấu hình chung hệ thống)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `appid` | text | Dùng để lấy `planning_collect_hcp_gift_exclude` (Danh sách HCP không được tặng) |
| `js` | jsonb | Lưu danh sách mã HCP loại trừ |

### Các table mới của hệ thống (New Tables):

**Table 1: `planning_collect_hcp_qua_tang`** (Bảng Đề xuất)
Lưu chi tiết các quà tặng được đề xuất cho HCP.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `uuid` | text | **PK** - Mã định danh duy nhất của lượt đề xuất |
| `ma_hcp_2` | text | Mã HCP được tặng quà |
| `manv` | text | Mã nhân viên tạo đề xuất (CRS) |
| `qua_tang` | text | Mã/Tên món quà tặng |
| `so_luong` | integer | Số lượng đề xuất |
| `price` | numeric | Đơn giá của quà tặng |
| `status` | text | Trạng thái: `H` (Chờ duyệt), `C` (Đã duyệt), `R` (Từ chối) |
| `ten_chuong_trinh` | text | Tên chương trình/Đợt quà tặng áp dụng |
| `chi_phi_thang` | timestamp | Kỳ chi phí |
| `approved_manv` | text | Mã CRM đã duyệt đơn |
| `approved_at` | timestamp | Thời gian CRM xử lý |
| `inserted_at` | timestamp | Thời gian CRS tạo đề xuất |

**Table 2: `planning_collect_hcp_qua_tang_settings`** (Bảng Cấu hình Chương trình)
Lưu trữ các tham số vận hành cho chương trình quà tặng HCP hiện hành.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `ten_chuong_trinh` | text | Tên chương trình (VD: Quà tặng Q1.2026) |
| `thoi_gian_mo_link` | date | Ngày bắt đầu cho phép submit |
| `thoi_gian_dong_link` | date | Ngày kết thúc |
| `gioi_han_so_lan_submit_cho_1_hcp` | integer | Số lần tối đa được submit trên 1 HCP |
| `dinh_muc_toi_da_hcp` | numeric | Tổng số tiền tối đa cho phép trên 1 HCP |
| `loai_kenh_ap_dung` | text | Các kênh áp dụng (VD: ETC, OTC...) |
| `loai_hcp_ap_dung` | text | Các loại HCP áp dụng (VD: BS, DS...) |
| `chi_phi_thang` | date | Tháng ghi nhận chi phí |

**Table 3: `planning_collect_hcp_qua_tang_dinh_muc_crm`** (Bảng Định mức Ngân sách)
Quản lý hạn mức chi tiêu cho CRS và CRM theo từng chương trình.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `ma_crm` | text | Mã nhân viên (CRS hoặc CRM) |
| `ten_crm` | text | Tên nhân viên (CRS hoặc CRM) |
| `dinh_muc` | double precision | Số tiền ngân sách tối đa được phép sử dụng |
| `ten_chuong_trinh` | text | Tên chương trình áp dụng |

**Table 4: `planning_collect_hcp_qua_tang_product_list`** (Bảng Danh mục Quà tặng)
Lưu danh sách các mặt hàng có thể chọn để tặng.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `ma_qua_tang` | text | Mã quà tặng |
| `ten_qua_tang` | text | Tên quà tặng hiển thị trên giao diện |
| `don_gia` | numeric | Giá tiền |

-----

## 6. API & Function Specifications (Chi tiết kỹ thuật)

Hệ thống hoạt động theo mô hình 2 lớp:
* **Python API Gateway:** Lớp điều hướng và xử lý xác thực.
* **Backend Logic:** Xử lý bằng **PostgreSQL Stored Functions (PL/pgSQL) nhận jsonb và output jsonb**.

### 6.1. Nhóm Load Data & Submit Form (Luồng CRS)

#### **Function:** `get_planning_collect_hcp_qua_tang`

* **Loại:** READ
* **Mục đích:** Lấy dữ liệu cấu hình, thông báo, danh sách HCP và danh sách quà tặng để CRS điền form.
* **Nguyên tắc lọc dữ liệu (Logic):**
    1.  Lấy thông tin quy tắc từ `planning_collect_hcp_qua_tang_settings`.
    2.  Check `mo_link = 1` nếu thời gian hiện tại nằm trong khoảng mở link.
    3.  Lấy danh sách HCP (`lst_hcp`):
        * Lọc theo tuyến `manv` phụ trách (dùng hàm strpos check).
        * Lọc theo `loai_kenh_ap_dung` và `loai_hcp_ap_dung`.
        * Loại trừ các mã HCP nằm trong danh sách chặn `planning_collect_hcp_gift_exclude` lấy từ bảng `settings_data`.
    4.  Lấy danh mục quà tặng (`lst_chon_qua_tang`).
* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR1234"
    }
    ```
* **JSON Output Specification:**
    ```json
    {
        "mo_link": 1,
        "ten_chuong_trinh": "Chương trình quà tặng tháng 6",
        "chi_phi_thang": "01-06-2026",
        "quy_tac": "Tên chương trình: ... \n Định mức tối đa HCP: 500,000 ...",
        "lst_hcp": [
            {
                "ma_crs": "MR1234",
                "ma_hcp_2": "HCP001",
                "ten_hcp": "Nguyễn Văn A",
                "phan_loai_hcp": "BS",
                "ten_kh_chung": "Bệnh viện X",
                "ten_hien_thi": "Bệnh viện X | HCP001 | Nguyễn Văn A",
                "id": 1,
                "check": false
            }
        ],
        "lst_chon_qua_tang": [
            {
                "ma_qua_tang": "Q01",
                "ten_qua_tang": "Balo",
                "don_gia": 200000
            }
        ],
        "nguoi_upload_file_data": ["MR1119", "MR0474", "MR2616", "MR2417"]
    }
    ```

#### **Function:** `insert_planning_collect_hcp_qua_tang`

* **Loại:** WRITE (Insert)
* **Mục đích:** Ghi nhận đề xuất xin cấp quà tặng cho HCP từ CRS.
* **Validation (Các quy tắc chặn lỗi - Quan trọng):**
    Hệ thống kiểm tra tuần tự. Nếu vi phạm, trả lỗi ngay lập tức:
    1.  **Check Trùng Lặp (Duplicate):** HCP truyền lên đã từng được submit trong đợt chương trình (có record status H, C). -> Lỗi: `"HCP <ma_hcp> đã được submit trước đó"`.
    2.  **Check Định Mức HCP:** Tổng tiền đề xuất cho 1 HCP > `dinh_muc_toi_da_hcp` (cấu hình trong settings). -> Lỗi: `"Đã vượt định mức HCP"`.
    3.  **Check Định Mức CRS (Cá nhân):** Tổng tiền toàn bộ các đơn đang submit + đơn đang nộp đợt này của user CRS > `p_dm_ca_nhan` (trong bảng `planning_collect_hcp_qua_tang_dinh_muc_crm`). -> Lỗi: `"Tổng tiền đã nhập vượt quá định mức của nhân viên"`.
    4.  **Check Định Mức CRM (Vùng):** Tổng tiền toàn team dưới trướng của CRM (supid) > `dinh_muc` team. -> Lỗi: `"Đã vượt định mức CRM"`.

* **Logic (Quy trình xử lý dữ liệu):**
    1.  Parse array JSON đầu vào thành bảng tạm `data_nhap`.
    2.  Join với các bảng cấu hình để tính toán và lấy định mức.
    3.  Kiểm tra các Validation rules.
    4.  Nếu Passed: `INSERT INTO planning_collect_hcp_qua_tang`.
    5.  Return thành công kèm tổng tiền đã nhập.

* **JSON Input (`body`):**
    ```json
    [
        {
            "uuid": "u-1234",
            "ma_hcp_2": "HCP001",
            "manv": "MR1234",
            "qua_tang": "Balo",
            "so_luong": 2,
            "price": 200000,
            "status": "H",
            "ten_chuong_trinh": "Chương trình quà tặng tháng 6",
            "chi_phi_thang": "2026-06-01T00:00:00",
            "inserted_at": "2026-06-04T10:00:00"
        }
    ]
    ```
* **JSON Output:**
    * **Thành công:**
        ```json
        { "status": "ok", "success_message": "Đã nhận thành công , <Tổng đã nhập >: 400,000" }
        ```
    * **Thất bại:**
        ```json
        { "status": "fail", "error_message": "[Nội dung lỗi]" }
        ```

### 6.2. Nhóm Approval Flow (Luồng Quản lý Duyệt)

#### **Function:** `get_planning_collect_hcp_qua_tang_crm`

* **Loại:** READ
* **Mục đích:** CRM xem danh sách các đề xuất đang ở trạng thái Chờ duyệt (`H`) từ các nhân viên cấp dưới để tiến hành kiểm duyệt.
* **Nguyên tắc lọc dữ liệu (Logic):**
    1. Lấy danh sách nhân viên cấp dưới `list_nv` (join `d_users` với `d_hr_dsns` bằng `supid`).
    2. Lọc các record trong `planning_collect_hcp_qua_tang` có `status = 'H'` và `manv` là lính của CRM (`c.supid = p_manv`).
    3. Join bảng `view_list_hcp` để lấy thông tin chi tiết tên HCP, bệnh viện.

* **JSON Input (`url_param`):**
    ```json
    {
        "manv": "MR9999"
    }
    ```
* **JSON Output Specification:**
    ```json
    {
        "list_nv": [
            { "manv": "MR1234", "tencvbh": "Nguyễn Trình Dược" }
        ],
        "lst_chon_qua_cua_nv": [
            {
                "uuid": "u-1234",
                "ma_crs": "MR1234",
                "ma_hcp_2": "HCP001",
                "ten_hcp": "Nguyễn Văn A",
                "ten_kh_chung": "Bệnh viện X",
                "ten_hien_thi": "Bệnh viện X | Nguyễn Văn A | Quà tặng: Balo(MR1234)",
                "check": true
            }
        ]
    }
    ```

#### **Function:** `insert_planning_collect_hcp_qua_tang_crm`

* **Loại:** WRITE (Update)
* **Mục đích:** CRM Duyệt (`C`) hoặc Từ chối (`R`) đề xuất.
* **Validation:** Không có validation phức tạp.
* **Logic:**
    1. Nhận mảng các UUID của đề xuất.
    2. Thực hiện `UPDATE planning_collect_hcp_qua_tang` set `status`, `approved_manv`, `approved_at` với các uuid truyền lên.
* **JSON Input (`body`):** Mảng 1 phần tử bao gồm danh sách uuid_nv cần xử lý
    ```json
    [
        {
            "manv": "MR9999",
            "status": "C",
            "inserted": "2026-06-04T12:00:00",
            "uuid_nv": [
                "u-1234",
                "u-5678"
            ]
        }
    ]
    ```
* **JSON Output:**
    ```json
    {
        "status": "ok",
        "data": [
            {
                "uuid_nv": "u-1234",
                "manv": "MR9999",
                "status": "C",
                "inserted": "2026-06-04T12:00:00"
            }
        ]
    }
    ```
