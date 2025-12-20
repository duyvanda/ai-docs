### **6.x. Function: insert_nvbc_streak_daily**

* **Loại:** WRITE (Internal Helper – chỉ được gọi nội bộ từ `insert_nvbc_track_new`, không expose RPC riêng)  
* **Mục đích:**  
  * Cập nhật bảng `nvbc_streak_daily` cho **một user tại một thời điểm xem**, theo rule streak tối đa 7 ngày và điểm thưởng 0 / 30 / 70.  
  * Đảm bảo mỗi `(phone, streak_date)` chỉ có **tối đa 1 record** và toàn bộ business streak nằm tập trung trong 1 function riêng, dễ test & bảo trì.

**Input Parameters (Postgres function, không phải JSON RPC):**

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