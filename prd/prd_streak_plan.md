### **6.x. Function: insert_nvbc_streak_daily**

* **Loại:** WRITE (Internal Helper – chỉ được gọi nội bộ từ `insert_nvbc_track_new`, không expose RPC riêng)  
* **Mục đích:**  
  * Cập nhật bảng `nvbc_streak_daily` cho **một user tại một thời điểm xem**, theo rule streak tối đa 7 ngày và điểm thưởng 0 / 30 / 70.  
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
   * Nếu `new_streak_length = 7` → `bonus_point_today = 70`.  
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

#### **Cách sử dụng trong `insert_nvbc_track_new`:**

* Sau khi `insert_nvbc_track_new`:
  * Đã validate input (phone, inserted_at, v.v.).
  * Đã ghi nhận lượt xem vào `nvbc_track_view` thành công.
* Khi đó, function sẽ được gọi nội bộ:

```sql
PERFORM insert_nvbc_streak_daily(
    p_phone      := v_phone,
    p_inserted_at := v_inserted_at
);
```

Trong đó:

- `v_phone` là số điện thoại đã parse từ JSON input.
- `v_inserted_at` là timestamp của view đang xử lý (thường là field `inserted_at` trong payload).

---

### **6.y. Mở rộng nvbc_get_point – Daily Activity 7 Days**

#### **Mục đích:**

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

#### **JSON Output – Bổ sung vào nvbc_get_point:**

Thêm các field mới vào JSON output hiện tại:

```json
{
  "contentlist": [ /* như cũ */ ],
  "lich_su_diem": [ /* như cũ */ ],
  "phone": "0909xxxxxx",
  "point": 250,
  "base_point": 150,
  "streak_bonus_point": 100,
  "show_reward_selection": true,
  "th_monthly_reward": true,
  "product_expert_reward": false,
  "avid_reader_reward": false,
  "fail_show_reward_selection": false,
  "list_chon_monthly": [ /* như cũ */ ],
  "list_chon_dgcc": [ /* như cũ */ ],
  "list_chon_cgsp": [ /* như cũ */ ],
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
  ]
}
```

#### **Ghi chú về fields:**

* `point`: Tổng điểm hiển thị cho user (`base_point + streak_bonus_point`).
* `base_point`: Điểm học từ xem tài liệu (SUM `effective_point`).
* `streak_bonus_point`: Điểm bonus từ streak (SUM `bonus_point` từ `nvbc_streak_daily`).
* `lich_su_diem_streak`: Mảng lịch sử các lần nhận điểm bonus từ streak (chỉ những ngày có `bonus_point > 0`), sắp xếp mới nhất trước. Mỗi item gồm:
  * `streak_date`: Ngày nhận bonus (YYYY-MM-DD).
  * `streak_length`: Độ dài chuỗi tại ngày đó (3 hoặc 7).
  * `bonus_point`: Điểm bonus nhận được (30 hoặc 70).
* `streak_last_7_days`: Mảng 7 ngày gần nhất, mỗi ngày có:
  * `date`: Ngày VN (YYYY-MM-DD).
  * `has_view`: User có xem tài liệu trong ngày này hay không.
  * `streak_length`: Độ dài chuỗi tại ngày đó (0 = break/không có streak, 1-7 = đang trong streak).
  * `bonus_point`: Điểm bonus nhận được trong ngày (0, 30, hoặc 70).

---

**Lưu ý triển khai:**

* Phần này **chỉ mô tả output** (contract với Frontend).
* Backend cần implement CTE/join logic để:
  1. Generate series 7 ngày.
  2. LEFT JOIN với `nvbc_streak_daily` và aggregate `nvbc_track_view` theo ngày VN.
  3. Build JSON array `streak_last_7_days` theo đúng format trên.
* Có thể cần index trên `nvbc_streak_daily(phone, streak_date)` và `nvbc_track_view(phone, inserted_at)` để query nhanh.