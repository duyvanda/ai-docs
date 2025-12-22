**Product Requirements Document (PRD)**

## **Hệ thống M.Ambassador (Nhân Viên Bán Chính - NVBC)**

## **1. Tổng quan (Overview)**

Hệ thống M.Ambassador là cổng đào tạo và tích lũy điểm thưởng dành riêng cho Nhân viên bán chính (NVBC)/Dược sĩ tại nhà thuốc đối tác. Hệ thống cho phép người dùng xem tài liệu/video chuyên môn để tích điểm và đổi quà theo các chương trình thi đua (Tháng/Quý).

Dữ liệu được tích hợp với:

* **Hệ thống Zalo OA:** Xác thực danh tính và quyền truy cập qua số điện thoại.  
* **PostgreSQL:** Lưu trữ lịch sử truy cập, danh sách trúng thưởng và trạng thái đổi quà.

**2. Mục tiêu (Goals)**

* **[Đào tạo]:** Cung cấp kiến thức chuẩn hóa về sản phẩm và bệnh học cho dược sĩ thông qua video/PDF.  
* **[Gamification]:** Tăng tương tác bằng cơ chế tích điểm (xem trên 60s) và bảng xếp hạng/quà tặng.  
* **[Tracking]:** Ghi nhận chính xác lịch sử học tập để làm cơ sở trả thưởng.

**3. Đối tượng sử dụng (User Personas)**

| Vai trò | Mô tả công việc trên hệ thống |
| :---- | :---- |
| **Dược sĩ / NVBC** | - Đăng nhập bằng SĐT. - Xem tài liệu đào tạo. - Theo dõi điểm tích lũy. - Chọn quà khi đạt giải thưởng. |

**4. User Flow & UI Overview (Chi tiết quy trình)**

### **4.1. Phân hệ Đăng nhập (Authentication)**

* **User Flow:** User nhập SĐT -> Hệ thống gọi API nvbc_login.  
* **UI Logic:** Validate không để trống SĐT. Nếu thành công, lưu User Info vào LocalStorage và chuyển hướng sang trang Introduction.

### **4.2. Phân hệ Trang chủ & Xem Điểm (Mainpage)**

* **User Flow:** Truy cập trang chủ -> Hệ thống tự động gọi API nvbc_get_point.  
* **UI Logic:** Hiển thị tổng điểm, danh sách bài học (accordion), lịch sử điểm (modal), và tự động bật popup chọn quà nếu đủ điều kiện.

### **4.3. Phân hệ Tracking (Ghi nhận điểm)**

* **User Flow:** User xem Video/PDF > 60 giây -> Hệ thống gọi API insert_nvbc_track_view.  
* **UI Logic:** Xử lý ngầm (background), không hiển thị thông báo.

### **4.4. Phân hệ Đổi quà (Reward Redemption)**

* **User Flow:** User chọn quà trên popup -> Bấm "Lưu quà" -> Hệ thống gọi API insert_nvbc_reward_item.  
* **UI Logic:**

  - Hiển thị thông báo thành công/thất bại và tắt popup.
  - Vì quà là có giới hạn nên nếu chọn quà hết tồn sẽ phải chọn lại.

**5. Thiết kế Cơ sở dữ liệu (Database Schema)**

### **5.1. Các tables nội bộ**

Table: nvbc_docs  
Lưu trữ danh mục tài liệu đào tạo.

| Column Name | Data Type | Description |
| :---- | :---- | :---- |
| document_id | integer | **PK** - Mã tài liệu |
| document_name | text | Tên hiển thị |
| type | text | Loại: 'video' hoặc 'pdf' |
| category | text | Nhóm chính (VD: Thông tin sản phẩm) |
| sub-category | text | Nhóm phụ (Lưu ý: Tên cột có dấu gạch ngang) và có thể bị Trống “” |
| url | text | Link Youtube hoặc PDF |
| point | integer | Điểm thưởng cho bài này |
| type | text | loại mới hay cũ, mặc định `old` |

### 

Table 1: nvbc_track_view

| Column Name | Data Type | Description |
| :---- | :---- | :---- |
| phone | text | **Index** - Số điện thoại user |
| ma_kh_dms | text | Mã khách hàng DMS |
| document_id | text | ID tài liệu đã xem |
| watch_duration_seconds  | integer     | Tổng số giây người dùng đã thực sự xem tài liệu trong lượt này (do Client đo lường). |
| time_rate | numeric(3,2)| Hệ số tỷ lệ thời gian xem, nằm trong [0, 1]. Phiên bản đầu sử dụng tập giá trị {0, 0.5, 1.0}. |
| base_point | numeric     | Điểm gốc user nhận được cho lượt xem này được tính bằng `nvbc_docs.point` |
| effective_point         | numeric     | Điểm thực tế user nhận được cho lượt xem này, được tính bằng `nvbc_docs.point * time_rate`. |
| inserted_at | timestamp | Thời gian xem |

Table 2: nvbc_reward_list  
Danh sách "Whitelist" những người đủ điều kiện nhận thưởng (Được import vào hệ thống trước).

| Column Name | Data Type | Description |
| :---- | :---- | :---- |
| phone | text | **PK** - Số điện thoại người trúng giải |
| reward_type | text | **PK** - Loại giải (11th_monthly_reward, q42025_avid_reader_reward...) |
| inserted_at | timestamp | Ngày insert |

Table 3: nvbc_reward_item  
Lưu kết quả chọn quà của người dùng.

| Column Name | Data Type | Description |
| :---- | :---- | :---- |
| phone | text | Số điện thoại user |
| value | text | Chuỗi quà đã chọn monthly |
| reward_event | text | (Có thể để trống nếu gộp chung vào value) |
| inserted_at | text | Thời gian chọn quà |
| value1 | text | Quà đã chọn product_expert |
| value2 | text | Quà đã chọn advid_reader |

## 

Table: d_master_khachhang  
Bảng danh mục khách hàng master.

| Column Name | Data Type | Description |
| :---- | :---- | :---- |
| custid | STRING | **PK/Join Key** - Mã khách hàng (Khớp với customer_code) |
| channel | STRING | Kênh phân phối. **Điều kiện bắt buộc:** channel = 'TP' |

##

**Table: nvbc_gift_options**
Bảng cấu hình danh sách các lựa chọn quà tặng (Whitelist Options) hiển thị lên Popup chọn quà. Dữ liệu này được API nvbc_get_point sử dụng để trả về các danh sách list_chon_monthly, list_chon_dgcc, list_chon_cgsp.

| column name | data type | constraints | description |
| :--- | :--- | :--- | :--- |
| id | integer | PK | Mã định danh món quà |
| name | text | | Tên hiển thị của món quà (Sẽ map với field value trong JSON Output) |
| color | text | | Mã màu nền hiển thị trên UI (VD: #42c1f5) |
| icon_color | text | | Mã màu của Icon (VD: red, gold, blue) |
| category | text | | Phân loại nhóm quà để lọc API. Giá trị: monthly_reward, avid_reader_reward, product_expert_reward |
| stock | numeric | | Số lượng quà tặng |
| start_time | timestamp | | Thời gian bắt đầu cho phép đổi quà |
| end_time | timestamp | | Thời gian kết thúc cho phép đổi quà |
| is_available | integer | Default 1 | Cờ kiểm soát còn hay hết hàng (1: Còn hàng, 0: Hết hàng) |



**Table: nvbc_reward_type**
Bảng danh mục các phần thưởng hiện tại.

| Column Name | Data Type | Description |
| :---- | :---- | :---- |
| reward_type | text | mã phần thưởng |

ví dụ:
|    | reward_type                  |
|---:|:-----------------------------|
|  1 | q42025_product_expert_reward |
|  2 | q42025_avid_reader_reward    |
|  3 | 12_25_th_monthly_reward      |

### **5.2. Các API bên ngoài**

API: eoffice.meraplion.com (Zalo OA Data)  
https://eoffice.meraplion.com/admincp/api/api/raw/data-follow?active_oa=1&phone={phone}  
Dữ liệu trả về danh sách khách hàng đã follow OA và được map số điện thoại.

| Column Name | Data Type | Description |
| :---- | :---- | :---- |
| customer_code | STRING | **Join Key** - Mã khách hàng trên hệ thống DMS |
| follow_phone | STRING | Số điện thoại Zalo của user |
| follow_name | STRING | Tên hiển thị trên Zalo |
| active_oa | INTEGER | Trạng thái quan tâm OA (Filter đầu vào active_oa=1) |
| ... | ... | *(Các trường khác trong schema nhưng chưa dùng đến)* |

## 

## ---

**6. API & Function Specifications (Chi tiết kỹ thuật)**

Hệ thống hoạt động theo mô hình: Frontend gọi API trực tiếp tới POSTGRES-RPC

* **Base URL:** https://bi.meraplion.com  
* **Authentication:** Các API là Public (AllowAny) nhưng có kiểm tra IP nội bộ (check_authen) và Token tĩnh.

### **6.1. Nhóm Authentication (Xác thực)**

#### **Function: nvbc_login**

* **Loại:** READ  
* **Mục đích:** Xác thực danh tính Nhân viên bán công (NVBC) bằng số điện thoại thông qua API EOffice, sau đó tham chiếu (map) với dữ liệu hệ thống DMS để lấy mã định danh nội bộ.  
* **Nguyên tắc lọc dữ liệu (Logic):**  
  1. **Context/Permission (Kiểm soát ngữ cảnh & quyền):**  
     * **Lớp EOffice:** Chỉ chấp nhận User có trạng thái hoạt động (active_oa = 1) trên hệ thống EOffice.  
     * **Lớp DMS:** User tìm thấy phải tồn tại trong bảng Master Khách hàng (d_master_khachhang) và bắt buộc thuộc kênh Thành phẩm (channel = 'TP'). Các kênh khác bị coi là không hợp lệ.
  2. **Filter Condition (Điều kiện lọc):**
     * Lọc chính xác theo số điện thoại (phone) được truyền vào từ url_param.
     * Giới hạn kết quả lấy dòng đầu tiên tìm thấy (LIMIT 1).  
  3. **Data Enrichment (Làm giàu & Kết hợp dữ liệu):**  
     * Sử dụng kết quả từ API EOffice (customer_code, follow_name) để JOIN với bảng d_master_khachhang.  
     * Trích xuất và chuẩn hóa tên cột output: follow_phone -> phone, custid -> ma_kh_dms.  
     * Xử lý dữ liệu trống bằng COALESCE để đảm bảo không trả về giá trị NULL.


* **JSON Input (body):**  
  ```
  {  
      "phone": "0909xxxxxx"  
  }
  ```

* **JSON Output:**  
  * **Thành công (HTTP 200):**
  ```
  {  
      "phone": "0909xxxxxx",  
      "name": "Nguyễn Văn A",  
      "ma_kh_dms": "KH00123"  
  }
  ```

* **Thất bại - Không tìm thấy SĐT (HTTP 400):**  
  ```
  {  
      "mess_error": "no phone found"  
  }
  ```

### **6.2. Nhóm Core Business (Trang chủ & Dữ liệu)**

#### **Function: nvbc_get_point**

* **Endpoint:** `/local/nvbc_get_point/`
* **Loại:** READ
* **Mục đích:** Truy xuất toàn bộ dữ liệu cần thiết để hiển thị màn hình chính (Dashboard) cho người dùng tham gia chương trình NVBC. Dữ liệu bao gồm: thông tin điểm số tích lũy, lịch sử đọc tài liệu, danh sách tài liệu hiện có, và trạng thái/quyền lợi đổi quà (Rewards) của người dùng dựa trên số điện thoại.

**Nguyên tắc lọc dữ liệu (Logic):**

**1. Context/Permission (Định danh & Quyền hạn):**

* **User Identification:** Hệ thống định danh người dùng duy nhất thông qua tham số phone được truyền vào trong input JSON (`url_param->>'phone'`).
* **Scope:** Dữ liệu trả về mang tính cá nhân hóa (Personalized) cho từng số điện thoại cụ thể.

**2. Filter Condition (Điều kiện lọc):**

* **Dynamic Configuration:** Truy vấn bảng `nvbc_reward_type` để lấy ra 3 mã sự kiện hiện hành: `c_monthly`, `c_quarterly_1`, `c_quarterly_2` (ví dụ: `11th_monthly_reward`, `q42025_avid_reader_reward`, `q42025_product_expert_reward`).

* **Logic hiển thị Quà tặng (Reward Flags):**
  * *Nguồn dữ liệu:* `public.nvbc_reward_list` (Danh sách được nhận) và `public.nvbc_reward_item` (Lịch sử đã nhận).
  * *Điều kiện chặn (Blocking Condition):* Kiểm tra xem User đã đổi quà của sự kiện hiện tại (`c_monthly`) hay chưa.
    * Nếu **ĐÃ** đổi quà tháng (tồn tại trong `nvbc_reward_item` với `reward_event = c_monthly`): Hệ thống trả về `show_reward_selection = false`.
    * Nếu **CHƯA** đổi quà tháng: Tiếp tục kiểm tra danh sách các quyền lợi khác (`c_quarterly_1`, `c_quarterly_2`) trong bảng whitelist.
  * *Output Flags:* Tính toán các cờ `th_monthly_reward`, `avid_reader_reward`, `product_expert_reward` và `fail_show_reward_selection` (nghịch đảo của `th_monthly_reward`).

* **Logic danh sách quà (Gift Options):**
  * Truy vấn bảng `public.nvbc_gift_options`.
  * **Inventory Check:** Chỉ lấy các món quà có trạng thái **`is_available = 1`**.
  * **Mapping Output:** * Category `monthly_reward` -> Output key: `list_chon_monthly`
    * Category `avid_reader_reward` -> Output key: `list_chon_dgcc`
    * Category `product_expert_reward` -> Output key: `list_chon_cgsp`

* **Logic tính Điểm & Lịch sử (History & Points):**
  * *Time Range:* Chỉ tính các lượt xem tài liệu (`nvbc_track_view`) có ngày tạo (`inserted_at`) **từ ngày 01/10/2025 trở đi** (`c_start_date`).
  * `point = sum(effective_point)`:
  * *User Filter:* Chỉ lấy dữ liệu khớp chính xác với `phone` của người dùng.
  * *Sorting:* Sắp xếp lịch sử theo thời gian giảm dần (`ORDER BY inserted_at DESC`).
  
* **JSON Output Specification:**

  JSON 
  ``` 
  {  
      "contentlist": [  
          {  
              "category": "THÔNG TIN SẢN PHẨM",  
              "subcategories": [  
                  {  
                      "sub_category": "Nhóm kháng sinh",  
                      "url": "https://youtube.com/...",  
                      "type": "video",  
                      "document_name": "Video HDSD...",  
                      "document_id": 101,  
                      "point": 2,
                      "condition": new
                  }  
              ]  
          },  
          {  
              "category": "THÔNG TIN VỀ MERAPLION",  
              "subcategories": [  
                  {  
                      "sub_category": "",  
                      "url": "https://youtube.com/...",  
                      "type": "video",  
                      "document_name": "Video HDSD...",  
                      "document_id": 101,  
                      "point": 2,
                      "condition": old
                  }  
              ]  
          }  
      ],  
      "lich_su_diem": [
        {
          "ma_kh_dms": "KH001",
          "phone": "0909xxxxxx",
          "document_id": "101",
          "inserted_at": "2025-12-16 10:00:00",
          "document_name": "Video HDSD...",
          "time_rate": 1.0,
          "watch_duration_seconds": 122,
          "base_point": 4,
          "effective_point": 4
        }
      ],
      "phone": "0909xxxxxx",  
      "point": 150,  
      "show_reward_selection": true,  
      "th_monthly_reward": true,  
      "product_expert_reward": false,  
      "avid_reader_reward": false,  
      "fail_show_reward_selection": false,
      "list_chon_monthly": [
        {
          "id": 4,
          "value": "Túi đựng mỹ phẩm, đồ du lịch da PU thoáng khí",
          "color": "#42c1f5",
          "icon_color": "red"
        },
        {
          "id": 5,
          "value": "Túi cói kèm charm đáng yêu",
          "color": "#ffbf47",
          "icon_color": "gold"
        }
      ],
      "list_chon_dgcc": [
        {
          "id": 6,
          "value": "Máy sấy tóc Philips HP8108 1000W",
          "color": "#42c1f5",
          "icon_color": "blue"
        },
        {
          "id": 7,
          "value": "Quạt cầm tay tốc độ cao Shimono SM-HF18(W)",
          "color": "#ffbf47",
          "icon_color": "green"
        }
      ],
      "list_chon_cgsp": [
        {
          "id": 8,
          "value": "Ba lô thời trang Sakos Dahlia (SBV169CR)",
          "color": "#42c1f5",
          "icon_color": "purple"
        },
        {
          "id": 9,
          "value": "Máy xây sinh tố cầm tay Bear SB –MX04X",
          "color": "#ffbf47",
          "icon_color": "black"
        }
      ]
  }
  ```

### 6.3. Nhóm Action (Ghi nhận dữ liệu)

#### **Function:** `insert_nvbc_track_view`

* **Loại:** WRITE (Insert)
* **Mục đích:** Ghi nhận lịch sử user đã xem tài liệu (Video/PDF) đủ thời gian quy định (60s), đồng thời thực hiện cơ chế **Rate Limiting (Debounce)** để ngăn chặn việc spam request liên tục từ Client.
* **Validation (Các quy tắc chặn lỗi & Logic nghiệp vụ):**
    1.  **Anti-Spam / Rate Limiting:** Hệ thống sử dụng bảng trung gian `cache_data` để kiểm soát tần suất ghi nhận.
        * Mỗi request thành công sẽ tạo/update một "khóa" (key) dựa trên số điện thoại.
        * Thời gian tồn tại (TTL) của khóa là **10 giây**.
        * Cơ chế này đảm bảo trong vòng 10 giây, hệ thống chỉ xử lý luồng ghi nhận mới nhất và dọn dẹp các request cũ/spam.
    2.  **Data Structure Check:** Dữ liệu đầu vào bắt buộc phải là một JSON Array hợp lệ để có thể parse bằng hàm `jsonb_populate_recordset`.
    3.  **Exception Handling:** Bất kỳ lỗi nào xảy ra trong quá trình thực thi (VD: Lỗi kết nối, lỗi định dạng dữ liệu, lỗi SQL) đều được bắt bởi khối `EXCEPTION WHEN OTHERS` và trả về `status: fail` kèm nội dung lỗi chi tiết (`SQLERRM`).

* **Logic (Quy trình xử lý dữ liệu):**
    1.  **Parse Input:** Trích xuất số điện thoại (`p_phone`) từ phần tử đầu tiên của mảng JSON input.
    2.  **Clean Cache (Dọn dẹp):** Xóa các bản ghi trong bảng `cache_data` đã hết hạn (`expires_at < NOW()`) để giải phóng tài nguyên hệ thống.
    3.  **Set Cache (Tạo khóa chặn):** Insert một bản ghi mới vào `cache_data`:
        * `key`: Số điện thoại User.
        * `value`: Metadata (VD: `{"time": 10}`).
        * `expires_at`: Thời gian hiện tại (`NOW()`) + 10 giây.
    4.  **Bulk Insert (Ghi dữ liệu chính):** Sử dụng `jsonb_populate_recordset` để chuyển đổi toàn bộ mảng JSON input thành các dòng dữ liệu và insert vào bảng `nvbc_track_view`.
    5.  **Return:** Trả về đối tượng JSON thông báo thành công.


* **JSON Input (body):** *Lưu ý: Input là một Array (Mảng)*  
  JSON
  ```
  [  
      {  
          "ma_kh_dms": "KH00123",  
          "phone": "0909xxxxxx",  
          "document_id": "101",
          "watch_duration_seconds": 75,
          "time_rate": 1.0,
          "base_point":4,
          "effective_point":4
          "inserted_at": "2025-12-16 10:30:00"  
      }  
  ]
  ```

* **JSON Output:**  
  * **Thành công:**  
    JSON
  ``` 
  {  
      "status": "ok",  
      "message": "Đã nhận thông tin thành công !!!"   
  }
  ```

#### **Function: insert_nvbc_reward_item**

* **Endpoint:** /local/post_data/insert_nvbc_reward_item/  
* **Method:** POST  
* **Mục đích:** Lưu thông tin quà tặng user đã chọn vào hệ thống.  
* **Logic Xử lý:**
  1.  **Nhận dữ liệu:** Hệ thống nhận mảng JSON chứa thông tin các món quà user muốn đổi (`value`, `value1`, `value2`) và mã sự kiện (`reward_event`).
  2.  **Kiểm tra tồn kho (Stock Check):**
      * Hệ thống tính toán số lượng quà đã phát thực tế bằng cách đếm trong lịch sử bảng `nvbc_reward_item`, **chỉ tính riêng cho `reward_event` hiện tại**.
      * So sánh: Nếu `(Số lượng đã đổi + 1 đang đổi) > Tổng Stock cấu hình` của món quà đó.
      * **Quy tắc:** Chỉ cần **1 trong 3** món quà (Monthly/Expert/Reader) hết hàng, hệ thống sẽ **từ chối toàn bộ** (FAIL) và trả về thông báo lỗi kèm tên món quà. Đồng thời set SET is_available = 0. 
  3.  **Ghi nhận (Insert):** Nếu tất cả món quà đều còn hàng, hệ thống thực hiện Insert dữ liệu vào bảng `nvbc_reward_item`.
  4.  **Phản hồi:** Trả về message thành công hoặc thất bại.
* **JSON Input (body):** *Lưu ý: Input là một Array (Mảng)*  
  JSON
  ```
  [  
      {  
          "phone": "0909xxxxxx",  
          "value": "Quà monthly",  
          "reward_event": "xth_monthly_reward",  
          "inserted_at": "2025-12-16 11:00:00",
          "value1": Quà product_expert,
          "value2": Quà advid_reader
      }  
  ]
  ```

* **JSON Output:**  
  **Thành công:** 
    ```
    {  
        "success_message": "Lưu quà thành công!"   
    }
    ```

  **Thất bại:**
    ```
    {  
        "error_message": "Lỗi khi lưu quà..."   
    }
    ```

    ```
    {
        "status": "fail",
        "error_message": "Rất tiếc, món quà \"Bình giữ nhiệt\" vừa hết hàng trong đợt này."
    }
    ```
