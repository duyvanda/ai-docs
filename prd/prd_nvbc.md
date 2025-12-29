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
---

## 4.5 Flow Referrer-Invitee

* **Invitee**: chọn referrer trong tháng, xem video tích điểm; khi đạt ≥20 điểm thì kích hoạt xét thưởng cho referrer.
* **Referrer**: không thao tác; nhận tối đa 100 điểm khi invitee đạt điều kiện trong tháng.
* **System**: ghi nhận quan hệ referral theo tháng, theo dõi điểm invitee và tự động cộng bonus khi đủ điều kiện.
* **API**: Hệ thống gọi API `insert_nvbc_ref_month_regis`.

## 4.6 Flow Streak

* **System**: Ghi nhận điểm theo số ngày LIÊN TIẾP user xem tài liệu.
* **API**: Hệ thống gọi API `insert_nvbc_track_view` sau đó gọi hàm phụ `insert_nvbc_daily_streak`.
---



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


### Table: `nvbc_ref_month`

**Overview**
Lưu quan hệ giới thiệu (invitee – referrer) theo tháng và trạng thái thưởng referral.
Bảng này đồng thời đóng vai trò **giới hạn referrer theo tháng** và **ghi nhận bonus**.

| Column           | Type      | Description                                                         |
| ---------------- | --------- | ------------------------------------------------------------------- |
| `invitee_phone`  | text      | SĐT người được giới thiệu (invitee)                                 |
| `referrer_phone` | text      | SĐT người giới thiệu (referrer)                                     |
| `month`          | date      | Tháng áp dụng referral (luôn là ngày đầu tháng, ví dụ `2025-12-01`) |
| `bonus_point`    | integer   | Điểm thưởng referral cho referrer (0 hoặc 100)                      |
| `inserted_at`    | timestamp | Thời điểm tạo quan hệ referral                                      |
| `bonus_at`       | timestamp | Thời điểm cộng bonus (nullable)


**Constraints / Business Notes**

* **UNIQUE (`referrer_phone`, `month`)**
  → mỗi referrer chỉ được nhận **1 referral / tháng**
* `bonus_point` ∈ {0, 100}
* Invitee chỉ hợp lệ nếu **chưa có điểm trước khi được invite** (xử lý ở backend)
* Không lưu điểm referral vào bảng điểm hoạt động


### Bảng nvbc_streak_daily (Daily Streak)

Bảng lưu trạng thái streak theo **ngày Việt Nam** cho từng user.

**Table: nvbc_streak_daily**

| Column Name  | Data Type | Description |
| :----------- | :-------- | :---------- |
| phone        | text      | **PK part** – Số điện thoại user |
| streak_date  | date      | **PK part** – Ngày VN được tính streak (timezone `Asia/Ho_Chi_Minh`) |
| streak_length| integer   | Độ dài chuỗi liên tiếp kết thúc tại `streak_date` (1–7 ngày) |
| bonus_point  | integer   | Điểm thưởng của ngày đó |
| inserted_at   | timestamp | Thời gian ghi nhận record |                                   |

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

#### **Function: get_nvbc_point**

* **Endpoint:** `/local/get_data/get_nvbc_point/`
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
  * `point = sum(effective_point)`.
  * `referral_point` = Tổng điểm trong bảng ref month.
  * *User Filter:* Chỉ lấy dữ liệu khớp chính xác với `phone` của người dùng.
  * *Sorting:* Sắp xếp lịch sử theo thời gian giảm dần (`ORDER BY inserted_at DESC`).


#### **Mở rộng get_nvbc_point – Daily Activity 7 Days**

* Trả về **lịch sử streak 7 ngày gần nhất** (tính từ hôm nay về trước) cho user.
* Cung cấp đủ thông tin để UI hiển thị:
  * Những ngày nào user đã xem (có streak).
  * Streak length từng ngày.
  * Điểm bonus từng ngày (nếu có).
  * Các flag hỗ trợ UI (chuỗi hiện tại, chuỗi bị đứt, milestone 3/7 ngày).

#### **Logic xử lý (bổ sung vào nvbc_get_point):**

1. **Xác định ngày VN hiện tại (`today_vn`):**
   * Lấy `NOW()` của DB và convert sang timezone `Asia/Ho_Chi_Minh` → `today_vn` (kiểu date).

2. **Sinh series 7 ngày gần nhất:**
   * Tạo series từ `today_vn - 6 days` đến `today_vn` (7 ngày).
   * Với mỗi ngày `d` trong series:
     * Join với `nvbc_streak_daily` để lấy `streak_length`, `bonus_point` (nếu có).
     * Join/Check với `nvbc_track_view` (theo ngày VN) để xác định `has_view` (true/false).

3. **Tính các flag per day:**
   * `has_view`: `true` nếu tồn tại ít nhất 1 record `nvbc_track_view` có `inserted_at` rơi vào ngày VN `d`.
   * `streak_length`: lấy từ `nvbc_streak_daily.streak_length` (1–7), nếu không có record thì `0`.
   * `bonus_point`: lấy từ `nvbc_streak_daily.bonus_point` (0 / 30 / 70), nếu không có record thì `0`.

4. **Tính tổng điểm:**
   * `base_point`: SUM `effective_point` từ `nvbc_track_view` (theo điều kiện campaign hiện tại, ví dụ `inserted_at >= c_start_date`).
   * `streak_bonus_point`: SUM `bonus_point` từ `nvbc_streak_daily` cho `phone` (toàn bộ lịch sử, không giới hạn campaign).
   * `total_point` = `base_point + streak_bonus_point`.

5. **Lịch sử điểm streak (`lich_su_diem_streak`):**
   * Lấy toàn bộ record từ `nvbc_streak_daily` cho `phone` có `bonus_point > 0`.
   * Sắp xếp theo `streak_date DESC` (mới nhất trước).
   * Mỗi item gồm: `streak_date`, `streak_length`, `bonus_point`.
  
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
      "lich_su_diem_referral": [
        {
          "invitee_phone": "0909xxxxxx",
          "referrer_phone": "0987654321",
          "month": "2025-12-01",
          "bonus_point": 100,
          "inserted_at": "2025-12-10 09:30:00",
          "bonus_at": "2025-12-16 15:20:00" -- ORDER BY theo field này.
        }
      ],
      "lich_su_diem_streak": [
          {
            "streak_date": "2025-12-16",
            "streak_length": 3,
            "bonus_point": 30
          },
          {
            "streak_date": "2025-12-10",
            "streak_length": 7,
            "bonus_point": 70
          },
          {
            "streak_date": "2025-12-08",
            "streak_length": 3,
            "bonus_point": 30
          }
        ],
        "streak_last_7_days": [
          {
            "date": "2025-12-13",
            "has_view": false,
            "streak_length": 0,
            "bonus_point": 0
          },
          {
            "date": "2025-12-14",
            "has_view": true,
            "streak_length": 1,
            "bonus_point": 0
          },
          {
            "date": "2025-12-15",
            "has_view": true,
            "streak_length": 2,
            "bonus_point": 0
          },
          {
            "date": "2025-12-16",
            "has_view": true,
            "streak_length": 3,
            "bonus_point": 30
          },
          {
            "date": "2025-12-17",
            "has_view": true,
            "streak_length": 4,
            "bonus_point": 0
          },
          {
            "date": "2025-12-18",
            "has_view": false,
            "streak_length": 0,
            "bonus_point": 0
          },
          {
            "date": "2025-12-19",
            "has_view": true,
            "streak_length": 1,
            "bonus_point": 0
          }
        ],
  
      "phone": "0909xxxxxx",  
      "point": 150,
      "referral_point": 150,
      "streak_point": 150,
      "show_reward_selection": true,  
      "th_monthly_reward": true,  
      "product_expert_reward": false,  
      "avid_reader_reward": false,  
      "fail_show_reward_selection": false,
      "reward_event":"12_25_th_monthly_reward",
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
      "referral_bonus": "Đã cộng thưởng cho người giới thiệu thành công",
      "streak_info": "Ghi nhận streak thành công"

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
          "reward_event": "12_25_th_monthly_reward",
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

#### **Function:** `insert_nvbc_ref_month_regis`

* **Loại:** WRITE (Insert)
* **Mục đích:** Ghi nhận quan hệ Invitee-Referrer
* **Logic:**
  **Bước 1: Invitee chọn referrer**

  * Input:

      * `invitee_phone`
      * `referal_phone`
      * `inserted_at` => Tự suy ra month
  ---

  **Bước 2: Kiểm tra invitee đã từng có điểm chưa**

  * Query `nvbc_track_view`
  * Nếu **đã tồn tại bản ghi**
    → ❌ Reject
    *(invitee không hợp lệ)*
  ---

  **Bước 3: Insert quan hệ**

  * Insert vào `nvbc_ref_month`

    * `invitee_phone`
    * `referal_phone`
    * `month`
    * `bonus_point = 0`
    * `inserted_at`

  * Nếu vi phạm `UNIQUE (referal_phone, month)`
    → ❌ Reject
    *(referrer đã được dùng trong tháng)*

* **Input Json:**
  ```
  [
    {
      "invitee_phone": "0909123456",
      "referral_phone": "0987654321",
      "inserted_at": "2025-12-10T09:30:123"
    }
  ]
  ```
* **Output Json:**

  * Thành công
  ```
  {
    "status": "ok",
    "success_message": "Ghi nhận người giới thiệu thành công.",
  }
  ```

    * Thất bại
  ```
  {
    "status": "fail",
    "error_message": "Người giới thiệu đã được sử dụng trong tháng này."
  }
  ```

#### **Function:** `insert_nvbc_ref_month_check`
* **Ghi chú đặc biệt:** Hàm được gọi trong hàm `insert_nvbc_track_view` khi user tiến hành ghi điểm.
* **Loại:** WRITE (Update)
* **Mục đích:** Kiểm tra điều kiện và cộng bonus cho referrer khi invitee đạt mốc điểm

* **Logic:**

**Bước 1: Kiểm tra invitee có active invite trong tháng**

* Query `nvbc_ref_month`

  * `invitee_phone`
  * `month = current_month`
* Nếu **không tồn tại bản ghi**
  → ❌ Dừng
  *(invitee không có referrer trong tháng, không cần tính điểm)*
---

**Bước 2: Kiểm tra đã cộng bonus chưa**

* Nếu `bonus_point = 100`
  → ❌ Dừng
  *(đã cộng bonus trước đó)*

---

**Bước 3: Tính tổng điểm invitee trong tháng**

  * `phone = invitee_phone`
  * `month = current_month`

---

**Bước 4: Kiểm tra mốc 20 điểm**

* Nếu tổng `< 20`
  → ❌ Dừng
* Nếu tổng `>= 20`
  → Sang bước cộng bonus

---

**Bước 5: Cộng bonus cho referrer**

* Update `nvbc_ref_month`

  * `bonus_point = 100`
  * `bonus_at = now()`

---

✅ **Không insert điểm referral vào `user_point`**
✅ **Referral bonus chỉ được ghi nhận tại `nvbc_ref_month`**
✅ **Hàm idempotent – gọi lại không cộng trùng**

* **Input Json:**

  ```
  {
    "invitee_phone": "0909123456",
    "current_month": "2025-12-01"
  }
  ```
* **Output Json:**
  * Thành công
  ```
  {
    "status": "ok",
    "success_message": "Đã cộng thưởng cho người giới thiệu thành công.",
  }
  ```

  * Thất bại
  ```
  {
  "status": "fail",
  "error_message": "Ghi cụ thể lý do"
  }
  ```


#### **Function:** `insert_nvbc_daily_streak`
* **Ghi chú đặc biệt:** Hàm được gọi trong hàm `insert_nvbc_track_view` khi user tiến hành ghi điểm.
* **Loại:** WRITE (Update)
* **Mục đích:**  
  * Cập nhật bảng `nvbc_streak_daily` cho **một user tại một thời điểm xem**, theo rule streak tối đa 7 ngày và điểm thưởng.  
  * Đảm bảo mỗi `(phone, streak_date)` chỉ có **tối đa 1 record** và toàn bộ business streak nằm tập trung trong 1 function riêng, dễ test & bảo trì.

**Input Parameters (dạng Json - Single object):**

| Parameter      | Data Type | Description |
| :------------- | :-------- | :---------- |
| `p_phone`      | text      | Số điện thoại user (đã được validate ở `insert_nvbc_track_new`) |
| `p_inserted_at`| timestamp | Thời điểm xem (lấy từ payload của `insert_nvbc_track_new`, sẽ convert sang ngày VN bên trong hàm) |

---

#### **Logic xử lý (Pseudo):**

1. **Chuẩn hoá ngày Việt Nam:**
   * Convert `p_inserted_at` sang `view_date_vn` (kiểu `date`) theo timezone `Asia/Ho_Chi_Minh`.  
   * Đây là ngày VN dùng cho mọi phép tính streak.

2. **Kiểm tra đã có streak trong ngày hay chưa:**
   * Truy vấn bảng `nvbc_streak_daily` với key `(phone = p_phone, streak_date = view_date_vn)`.
   * **Nếu đã tồn tại record:**  
     * Đây không phải là view đầu tiên của ngày.  
     * Function **RETURN** ngay, **không** cập nhật gì thêm (đảm bảo 1 record/ngày).

3. **Đọc streak của ngày hôm qua:**
   * Xác định `yesterday_vn = view_date_vn - INTERVAL '1 day'` (lấy phần date).  
   * Truy vấn `nvbc_streak_daily` với `(phone = p_phone, streak_date = yesterday_vn)`:
     * Nếu **có record hôm qua** → `yesterday_streak_length = streak_length` của record đó.  
     * Nếu **không có record hôm qua** → gán `yesterday_streak_length = 0` (coi như hôm qua không có streak / chuỗi bị đứt).

4. **Tính `new_streak_length` (độ dài chuỗi mới của ngày hiện tại):**
   * **Case 1 – Hôm qua đã full 7 ngày:**  
     * Nếu `yesterday_streak_length >= 7`  
       → Chuỗi cũ đã chạm trần 7 ngày.  
       → **Reset run**, set `new_streak_length = 1`.
   * **Case 2 – Hôm qua không có streak:**  
     * Nếu `yesterday_streak_length = 0`  
       → Không có liên tiếp từ hôm qua.  
       → **Bắt đầu run mới**, set `new_streak_length = 1`.
   * **Case 3 – Hôm qua đang streak 1–6:**  
     * Nếu `1 <= yesterday_streak_length <= 6`  
       → Chuỗi đang chạy → `new_streak_length = yesterday_streak_length + 1`.
   * **Giới hạn trần an toàn:**  
     * Nếu vì bất kỳ lý do gì `new_streak_length > 7` thì ép lại `new_streak_length = 7`.  
     * Về mặt business, với logic trên, case này gần như không xảy ra, nhưng vẫn giữ để chống lỗi.

5. **Tính điểm thưởng của ngày (`bonus_point_today`):**
   * Nếu `new_streak_length = 3` → `bonus_point_today = 30`.
   * Nếu `new_streak_length = 6` → `bonus_point_today = 30`.  
   * Nếu `new_streak_length = 7` → `bonus_point_today = 40`.  
   * Ngược lại → `bonus_point_today = 0`.  
   * Như vậy, **mỗi run 7 ngày tối đa mang lại 100 điểm bonus** (30 ở ngày thứ 3 + 70 ở ngày thứ 7).

6. **Ghi nhận vào bảng `nvbc_streak_daily`:**
   * Thực hiện `INSERT` 1 record mới:
     * `phone` = `p_phone`
     * `streak_date` = `view_date_vn`
     * `streak_length` = `new_streak_length`
     * `bonus_point` = `bonus_point_today`
     * `created_at` = `NOW()`
   * Ràng buộc unique `(phone, streak_date)` đảm bảo không trùng record trong cùng 1 ngày.

---