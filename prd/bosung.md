Rõ rồi 👍 mình chỉnh lại **ĐÚNG YÊU CẦU** và ghi lại **CHUẨN PRD** để bạn **copy dán trực tiếp**.
👉 `JSON Input (url_param)` **có mã NV** và **chỉ lấy data của người upload đó**.

---

## 🔹 Function: `get_theo_doi_tang_qua_admin_dashboard`

### **Loại**

READ

### **Mục đích**

Cho Admin xem danh sách các chương trình mà **một Sales cụ thể đã upload chứng từ**, kèm thời gian upload, phục vụ kiểm soát & audit theo từng nhân viên.

---

## 🔹 JSON Input (`url_param`)

```json
{
  "manv": "MR2948"
}
```

| Field  | Bắt buộc | Mô tả                             |
| ------ | -------- | --------------------------------- |
| `manv` | ✅        | Mã nhân viên Sales (người upload) |

---

## 🔹 Logic xử lý (Step-by-step)

**Step 1:**
Nhận `manv` từ `url_param`.

**Step 2:**
Query bảng `theo_doi_tang_qua_chung_tu` và **filter**:

```sql
nguoi_upload = manv
```

**Step 3:**
Join bảng `theo_doi_tang_qua_danh_sach_qua` theo:

* `ma_chuong_trinh`
* `ma_khach_hang`

để lấy `ten_chuong_trinh`.

**Step 4:**
Select **DISTINCT** các trường sau:

* `ma_chuong_trinh`
* `ten_chuong_trinh`
* `nguoi_upload`
* `thoi_gian_upload`

**Step 5:**
Sắp xếp kết quả theo:

```sql
thoi_gian_upload DESC
```

---

## 🔹 JSON Output (Admin)

```json
{
  "status": "ok",
  "rows": [
    {
      "ma_chuong_trinh": "CT2025_01",
      "ten_chuong_trinh": "Quà Tết 2025",
      "nguoi_upload": "MR2948",
      "thoi_gian_upload": "2025-02-15T10:05:00"
    },
    {
      "ma_chuong_trinh": "CT2024_12",
      "ten_chuong_trinh": "Tri ân khách hàng Q4/2024",
      "nguoi_upload": "MR2948",
      "thoi_gian_upload": "2024-12-28T16:20:00"
    }
  ]
}
```

---

## 🔹 Ghi chú kỹ thuật (Implementation Notes)

* Filter **bắt buộc** theo `nguoi_upload = manv`
* Không trả dữ liệu của Sales khác
* `DISTINCT` trên tổ hợp:

  ```
  (ma_chuong_trinh, ten_chuong_trinh, nguoi_upload, thoi_gian_upload)
  ```
* API dùng cho:

  * Admin kiểm tra nhanh hoạt động của **1 Sales**
  * Audit theo từng mã nhân viên
  * Đối soát khi có khiếu nại

---

## 🔹 Câu chốt đưa vào PRD (1 dòng)

> API cho phép Admin truy vấn danh sách chương trình mà một Sales cụ thể đã upload chứng từ, dữ liệu được lọc theo mã nhân viên upload.

---

Nếu bạn muốn bước tiếp theo, mình có thể:

* viết **SQL function hoàn chỉnh (PL/pgSQL)**
* đề xuất **index tối ưu cho filter nguoi_upload**
* hoặc mở rộng **filter theo khoảng thời gian**

nói mình làm tiếp ngay nhé 👌
