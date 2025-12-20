# Thiết kế time-based scoring cho NVBC – Schema & API Update

> Phiên bản: 2025-12-19 – Phần mở rộng cho PRD NVBC hiện tại (không thay đổi quy tắc thưởng hiện hành, chỉ bổ sung cơ chế tính điểm theo thời lượng xem).

---

## 1. Bối cảnh & mục tiêu thay đổi

### 1.1. Bối cảnh

- Hiện tại, mỗi lượt xem tài liệu hợp lệ (đủ điều kiện thời gian, ví dụ > 60s) được tính **trọn điểm cố định** theo cột `point` của bảng `nvbc_docs`.
- Business yêu cầu bổ sung cơ chế **time-based scoring**: điểm nhận được tỉ lệ thuận với thời lượng xem thực tế, thông qua hệ số `time_rate` nằm trong khoảng [0, 1].

### 1.2. Rule mới: mapping thời gian → time_rate

- Frontend sẽ tính toán `time_rate` dựa trên thời lượng xem `watch_duration_seconds` và quy tắc nội bộ (config client). Ví dụ (tham khảo, có thể chỉnh trên FE mà không ảnh hưởng DB):
  - Xem rất ít / bỏ ra sớm  → `time_rate = 0` (không cộng điểm).
  - Xem đủ ngưỡng tối thiểu (ví dụ ~50%) → `time_rate = 0.5` (cộng nửa điểm).
  - Xem đủ hoặc gần như toàn bộ (>= ngưỡng full) → `time_rate = 1.0` (cộng đủ điểm).
- Tập giá trị `time_rate` phiên bản đầu: **{0, 0.5, 1.0}**.

### 1.3. Phân chia trách nhiệm Client / Backend

- **Client (Frontend App):**
  - Thu thập thời lượng xem `watch_duration_seconds`.
  - Tính toán `time_rate` theo rule cấu hình (có thể thay đổi theo campaign / loại nội dung, nhưng không làm đổi schema backend).
  - Gửi `watch_duration_seconds` + `time_rate` trong payload JSON khi gọi API tracking.
- **Backend (Postgres RPC):**
  - **Không** nhận điểm tuyệt đối từ Client.
  - Chỉ **validate** `time_rate` (range và tập giá trị hợp lệ).
  - Tự tính `effective_point = base_point * time_rate` dựa trên điểm gốc `base_point` (cột `point` trong `nvbc_docs`).

### 1.4. Mục tiêu

- Hỗ trợ **điểm theo thời lượng xem** mà **không phá vỡ dữ liệu cũ** và các campaign đang chạy.
- Đảm bảo backward-compatible:
  - Dữ liệu cũ vẫn cho **đủ điểm** như trước khi rollout (full credit).
  - API output (tổng điểm, lịch sử) không thay đổi key quan trọng, chỉ bổ sung thêm field mới.

---

## 2. Thay đổi Database – nvbc_track_view & nvbc_docs

### 2.1. Bảng nvbc_track_view – cột mới

Bổ sung 3 cột sau vào bảng `nvbc_track_view`:

1. `watch_duration_seconds`
   - **Kiểu:** `integer`
   - **Ý nghĩa:** Tổng số giây người dùng đã thực sự xem tài liệu trong lượt tracking này (do Client đo lường).
   - **Dữ liệu mới (sau rollout):**
     - Ghi nhận giá trị thực tế do Client gửi lên (>= 0).
   - **Dữ liệu cũ (trước rollout):**
     - Chiến lược: cho phép **NULL** (hoặc 0 theo convention, xem thêm mục 6) vì không có thông tin thời lượng lịch sử.

2. `time_rate`
   - **Kiểu:** `numeric(3,2)` hoặc tương đương (0–1 với 2 chữ số thập phân).
   - **Ý nghĩa:** Hệ số tỷ lệ thời gian xem, nằm trong [0, 1].
   - **Quy tắc validate (backend):**
     - `0 <= time_rate <= 1`.
     - Thuộc tập giá trị hợp lệ ban đầu: `{0, 0.5, 1.0}`. Có thể mở rộng trong tương lai (ví dụ 0.25, 0.75) nhưng vẫn phải trong [0,1].
   - **Dữ liệu mới (sau rollout):**
     - Bắt buộc Client gửi `time_rate`.
     - Nếu không gửi hoặc không hợp lệ → trả HTTP 400 (invalid time_rate).
   - **Dữ liệu cũ (trước rollout):**
     - Áp dụng **Option 1 – Backfill full credit**: set `time_rate = 1.0` cho tất cả bản ghi lịch sử.

3. `effective_point`
   - **Kiểu:** `numeric` (hoặc `numeric(10,2)` tùy convention hiện tại cho point).
   - **Ý nghĩa:** Điểm thực tế user nhận được tại lượt xem này **sau khi áp dụng time-based scoring**.
   - **Cách tính (runtime):**
     - Lấy `base_point` từ bảng `nvbc_docs.point` (tại thời điểm insert).
     - Tính: `effective_point = base_point * time_rate`.
   - **Dữ liệu mới (sau rollout):**
     - Ghi trực tiếp giá trị `effective_point` đã tính vào `nvbc_track_view`.
   - **Dữ liệu cũ (trước rollout) – chiến lược backfill:**
     - Với mỗi bản ghi `nvbc_track_view` đang tồn tại:
       - Tham chiếu sang `nvbc_docs` theo `document_id` để lấy `point` hiện tại.
       - Gán: `time_rate = 1.0`.
       - Gán: `effective_point = nvbc_docs.point` (coi như full credit).
       - `watch_duration_seconds = NULL` hoặc 0 (tùy convention ở mục 6).

### 2.2. Bảng nvbc_docs – làm rõ business cho cột point

- Schema **không đổi**: tiếp tục sử dụng cột `point`:
  - `point` chính là **`base_point`** – điểm gốc tối đa user có thể nhận được khi xem **đủ** tài liệu.
- Cập nhật mô tả nghiệp vụ:
  - Trong các tài liệu kỹ thuật/PRD, khi nói về `point` ở bảng `nvbc_docs` cần ghi rõ: đây là **điểm tối đa** cho một lượt xem full (tương ứng `time_rate = 1.0`).
  - Điểm thực tế tính cho mỗi lượt xem sẽ lưu ở `nvbc_track_view.effective_point`.

---

## 3. Hợp đồng JSON frontend → backend (insert_nvbc_track_view)

Payload JSON mỗi lượt tracking (phía frontend gửi lên) – dạng **Array of Object** như PRD gốc, nhưng mở rộng thêm trường:

```json
[
  {
    "phone": "0909xxxxxx",          
    "ma_kh_dms": "KH00123",        
    "doc_id": 101,                  
    "watch_duration_seconds": 75,   
    "time_rate": 1.0,               
    "client_ts": "2025-12-19T10:30:00Z", 
    "platform": "zalo_web",        
    "app_version": "1.2.3"        
  }
]
```

### 3.1. Các field bắt buộc

- `phone` (string)
  - Số điện thoại NVBC, dùng để định danh user (như PRD hiện tại).
- `ma_kh_dms` (string)
  - Mã khách hàng DMS, giữ nguyên như PRD gốc.
- `doc_id` (string/int)
  - Khóa để join với `nvbc_docs.document_id`.
- `watch_duration_seconds` (number)
  - Tổng số giây người dùng đã xem tài liệu trong lượt này.
  - Yêu cầu: `watch_duration_seconds >= 0`.
- `time_rate` (number)
  - Nằm trong [0, 1].
  - Phiên bản đầu: sử dụng các giá trị rời rạc **0, 0.5, 1.0** theo config client.

### 3.2. Các field mở rộng (optional)

- `client_ts` (string)
  - Thời điểm client ghi nhận (ISO 8601). Dùng để debug/log, không tham gia tính điểm.
- `platform` (string)
  - Nguồn gọi (zalo_web, android, ios,…), chỉ phục vụ phân tích.
- `app_version` (string)
  - Phiên bản app/client, hỗ trợ theo dõi rollout.

### 3.3. Nguyên tắc hợp đồng

- Frontend **KHÔNG** gửi điểm tuyệt đối (không gửi `point` hay `effective_point`).
- Backend **luôn** tự tính `effective_point` từ `base_point` (cột `nvbc_docs.point`) nhân với `time_rate`.
- Backend **validate**:
  - `time_rate` phải nằm trong [0,1].
  - `time_rate` phải thuộc tập giá trị cho phép (ban đầu: {0, 0.5, 1}).
  - `watch_duration_seconds >= 0`.
- Nếu vi phạm → response HTTP 400 với thông điệp lỗi `invalid time_rate` hoặc tương tự.

---

## 4. Cập nhật logic insert_nvbc_track_view

### 4.1. Luồng xử lý mới (tổng quan)

1. Nhận JSON input (Array of Object) từ Frontend – cấu trúc như mục 3.
2. Thực hiện các bước **Anti-Spam / Rate Limiting** như PRD gốc (dùng bảng `cache_data`, TTL 10s) – giữ nguyên logic.
3. Với mỗi record trong input:
   - Validate `time_rate`:
     - `0 <= time_rate <= 1`.
     - Thuộc tập giá trị hợp lệ cấu hình.
   - Validate `watch_duration_seconds` (>= 0).
   - Đọc `base_point` từ `nvbc_docs.point` theo `doc_id`/`document_id`.
   - Tính `effective_point = base_point * time_rate`.
4. Ghi bản ghi mới vào `nvbc_track_view` với đầy đủ trường:
   - Các trường cũ: `phone`, `ma_kh_dms`, `document_id`, `inserted_at` (nếu vẫn cho FE gửi hoặc tự set NOW()).
   - Các trường mới: `watch_duration_seconds`, `time_rate`, `effective_point`.
5. Trả JSON output thành công giống PRD gốc:

```json
{
  "status": "ok",
  "message": "Đã nhận thông tin thành công !!!"
}
```

### 4.2. Error handling

- Cấu trúc error response giữ nguyên như hiện tại (HTTP code + body chung), chỉ bổ sung thêm case mới:
  - HTTP 400, body ví dụ:

```json
{
  "mess_error": "invalid time_rate"
}
```

- Các lỗi khác (lỗi hệ thống, lỗi SQL, lỗi parse JSON) vẫn dùng chung nhánh `EXCEPTION WHEN OTHERS` như PRD hiện tại.

---

## 5. Cập nhật nvbc_get_point (tổng điểm & lịch sử)

### 5.1. Công thức tổng điểm

- Trước đây: tổng điểm thường được hiểu là tổng `nvbc_docs.point` theo số lượt xem hợp lệ.
- Sau thay đổi:
  - Tổng điểm user trong khoảng thời gian campaign được tính bằng:

$$
\text{total_point} = \sum_{\text{lượt xem}} nvbc\_track\_view.effective\_point
$$

- Lợi ích của Option 1 (backfill full credit):
  - Vì đã set `effective_point` đầy đủ cho dữ liệu cũ, nên **không cần fallback** về `nvbc_docs.point` trong tính toán.
  - Mọi logic tổng điểm chỉ dựa trên `effective_point` cho cả dữ liệu cũ và mới.

### 5.2. Lịch sử điểm (lich_su_diem)

- Mỗi item trong mảng `lich_su_diem` hiện trả về các field như: `ma_kh_dms`, `phone`, `document_id`, `inserted_at`, `document_name`, `point`.
- Đề xuất cập nhật:
  - Sử dụng `effective_point` làm điểm hiển thị cho từng lượt:
    - Có thể:
      - **Giữ nguyên field name** `point` trong JSON nhưng map sang `effective_point` ở tầng SQL.
      - Hoặc **thêm field mới** `effective_point` nếu muốn phân biệt rõ (cần sync với FE).
  - Bổ sung thêm trường (khuyến nghị):
    - `time_rate`: hệ số điểm (0 / 0.5 / 1.0).
    - `watch_duration_seconds`: số giây xem được (nếu có).

Ví dụ JSON một item lịch sử sau khi mở rộng:

```json
{
  "ma_kh_dms": "KH001",
  "phone": "0909xxxxxx",
  "document_id": "101",
  "inserted_at": "2025-12-16 10:00:00",
  "document_name": "Video HDSD...",
  "point": 1.0,
  "time_rate": 0.5,
  "watch_duration_seconds": 45
}
```

- Các rule reward (monthly, avid reader, product expert):
  - Nếu hiện tại đang dùng **tổng điểm** để tính → không cần thay đổi logic, vì tổng điểm giờ đã chuyển sang dùng `effective_point` nhưng giá trị không giảm cho dữ liệu cũ.
  - Nếu có nơi đang dùng **số lượt xem** để tính → cần review lại xem có cần rule mới hay không (nằm ngoài scope doc này, chỉ đánh dấu ghi chú).

---

## 6. Tương thích dữ liệu cũ – Option 1 (Backfill full credit)

### 6.1. Chiến lược migration

- Phạm vi: toàn bộ bản ghi của bảng `nvbc_track_view` **trước ngày rollout** (ngày deploy chức năng time-based scoring).
- Thao tác backfill:
  - Set `time_rate = 1.0` cho tất cả record cũ.
  - Set `watch_duration_seconds = NULL` (hoặc 0 nếu muốn; đề xuất: dùng **NULL** để phân biệt rõ "không có dữ liệu").
  - Set `effective_point = nvbc_docs.point` tại thời điểm migration (JOIN theo `document_id`).

### 6.2. Hệ quả và đảm bảo business

- Tổng điểm user **không thay đổi** sau khi migrate:
  - Trước migration: hệ thống coi mỗi lượt xem hợp lệ là full điểm `point`.
  - Sau migration: mỗi lượt cũ được gán `time_rate = 1.0`, `effective_point = point` → tổng điểm giữ nguyên.
- `nvbc_get_point` có thể sử dụng duy nhất `effective_point` cho cả dữ liệu cũ/mới để tính tổng điểm và render lịch sử.
- Dữ liệu lịch sử cũ **không có chi tiết về thời lượng xem** (vì `watch_duration_seconds` = NULL) – đây là chấp nhận được với business.

---

## 7. Ghi chú triển khai

- Cần cập nhật đồng bộ:
  - Schema DB (ALTER TABLE cho `nvbc_track_view`).
  - Logic của function `insert_nvbc_track_view` (tính `effective_point`, validate `time_rate`, insert các cột mới).
  - Logic của function `nvbc_get_point` (tính tổng điểm từ `effective_point`, mở rộng JSON output cho lịch sử nếu FE chấp nhận).
- Thứ tự triển khai khuyến nghị:
  1. Deploy schema mới + backfill dữ liệu cũ (Option 1).
  2. Cập nhật backend functions (`insert_nvbc_track_view`, `nvbc_get_point`) để đọc/ghi `effective_point`, `time_rate`, `watch_duration_seconds`.
  3. Cập nhật FE để gửi `watch_duration_seconds` + `time_rate` theo hợp đồng JSON mới.
  4. Mở feature flag / rollout dần cho một nhóm user để quan sát dữ liệu thực tế.
