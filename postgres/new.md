Dưới đây là nội dung PRD phần **6.4** đã được cập nhật lại tên các cột (Output Keys) theo chuẩn `snake_case` như bạn yêu cầu.

---

## **6.4. Nhóm Reporting & Ranking (Báo cáo & Xếp hạng) - Cập nhật**

#### **Function: get_reward_event**

* **Loại:** READ
* **Mục đích:** Truy xuất bảng xếp hạng (Leaderboard) các dược sĩ đạt giải trong một sự kiện thi đua cụ thể. Hàm tự động tính toán điểm tích lũy trong khoảng thời gian của sự kiện đó để xếp hạng.
* **Logic Xử lý:**
1. **Parse Event Date:** Từ chuỗi `reward_event` (VD: `01_26_...`), xác định `start_date` (01/01/2026) và `end_date` (01/02/2026).
2. **Filter & Enrich:** Lấy danh sách SĐT trúng thưởng từ `nvbc_reward_list`, sau đó join với `f_crawl_activate_ecom` (lấy tên dược sĩ) và `d_master_khachhang` (lấy tên tỉnh).
3. **Ranking:** Tính tổng điểm (`nvbc_track_view`) trong khoảng thời gian sự kiện và xếp hạng (`RANK()`).


* **JSON Input (body):**
```json
{
    "reward_event": "01_26_th_monthly_reward"
}

```


* **JSON Output:**
* **Thành công (HTTP 200):**


```json
{
    "status": "ok",
    "meta_info": {
        "event": "01_26_th_monthly_reward",
        "filter_from": "2026-01-01",
        "filter_to": "2026-02-01"
    },
    "rows_data": [
        {
            "sdt": "0909xxxxxx",
            "ten_duoc_si": "Nguyễn Văn A",
            "ten_tinh": "Hồ Chí Minh",
            "tong_diem_tich_luy": 150,
            "rank_theo_diem": 1
        },
        {
            "sdt": "0912xxxxxx",
            "ten_duoc_si": "Trần Thị B",
            "ten_tinh": "Hà Nội",
            "tong_diem_tich_luy": 145,
            "rank_theo_diem": 2
        }
    ]
}

```


* **Thất bại (HTTP 400/500):**


```json
{
    "status": "fail",
    "error_message": "Invalid reward_event date format (MM_YY required)"
}

```