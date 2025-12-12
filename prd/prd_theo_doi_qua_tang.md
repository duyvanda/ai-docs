# PRD v1.19 – Hệ thống Theo Dõi Tặng Quà (Postgres-RPC Architecture)

**Date:** 15/02/2025
**Architecture:** Modern Monolith (Postgres-First)
**API Gateway:** Python (Dumb Pipe - RPC Style)
**Format Standard:** AdPyke Style (Strict Input/Output Rules)

---

# 1. Tổng quan kiến trúc
Mọi logic nghiệp vụ nằm trong **PostgreSQL Stored Functions**.
---

# 2. Database Schema Design
*Ràng buộc: Chỉ sử dụng kiểu dữ liệu `text`, `numeric`, `timestamp without time zone`.*

### **2.1. Bảng Master: theo_doi_tang_qua_danh_sach_qua**
Lưu trữ dữ liệu gốc từ file Excel Admin upload.

```sql
CREATE TABLE theo_doi_tang_qua_danh_sach_qua (
    -- Khóa chính: Chương trình + Khách hàng + Loại quà
    ma_chuong_trinh     text NOT NULL,
    ten_chuong_trinh    text NOT NULL,
    
    ma_khach_hang       text NOT NULL,
    ma_nhan_vien        text NOT NULL, -- Index cho Sales query
    
    ma_qua_tang         text NOT NULL,
    ten_qua             text NOT NULL,
    
    so_luong            numeric NOT NULL DEFAULT 0,
    
    -- Metadata
    nguoi_tai_len       text NOT NULL,
    thoi_gian_tai_len   timestamp without time zone DEFAULT NOW(),

    PRIMARY KEY (ma_chuong_trinh, ma_khach_hang, ma_qua_tang)
);

CREATE INDEX idx_phan_bo_sales ON theo_doi_tang_qua_danh_sach_qua (ma_chuong_trinh, ma_nhan_vien);
```

### **2.2. Bảng Transaction: theo_doi_tang_qua_chung_tu**
Lưu trữ kết quả thực hiện của Sales (Evidence).

```sql
CREATE TABLE theo_doi_tang_qua_chung_tu (
    -- Khóa chính: Mỗi khách trong 1 chương trình chỉ có 1 bộ chứng từ
    ma_chuong_trinh     text NOT NULL,
    ma_khach_hang       text NOT NULL,

    -- 5 Slots hình ảnh (Lưu URL minio)
    hinh_anh_1          text,
    hinh_anh_2          text,
    hinh_anh_3          text,
    hinh_anh_4          text,
    hinh_anh_5          text,

    ghi_chu             text,

    -- Metadata
    nguoi_tai_len       text NOT NULL, -- Mã nhân viên Sales
    thoi_gian_tai_len   timestamp without time zone DEFAULT NOW(),

    PRIMARY KEY (ma_chuong_trinh, ma_khach_hang)
);
```

---

# 3. User Flow & UI Overview

## **3.1. Phân hệ Admin (Web Desktop)**

### **User Flow: Upload Chương Trình**
1.  **Start:** Admin truy cập trang "Quản lý chương trình tặng quà".
2.  **Input:** Nhập `Mã chương trình` (Text) & `Tên chương trình` (Text).
3.  **Upload:** Chọn file Excel từ máy tính.
4.  **Parsing (Frontend):** React đọc file Excel, hiển thị bảng Preview (10 dòng đầu) để check cột.
5.  **Submit:**
    * Admin bấm nút "Import dữ liệu".
    * FE gọi API: `insert_theo_doi_tang_qua_admin_excel`.
6.  **Feedback:**
    * Thành công: Hiển thị "Import thành công X dòng".
    * Thất bại: Hiển thị Alert lỗi cụ thể (ví dụ: "Sai định dạng dòng 5").
  
7.  **Nút xem file template:** Admin có thể xem file template mẫu, react tự tạo bằng thư viện.
---

## **3.2. Phân hệ Sales (Mobile Web App)**

### **User Flow: Checklist công việc & Báo cáo**
Mục tiêu: Giúp Sales biết hôm nay cần tặng quà cho ai và cập nhật bằng chứng nhanh nhất.

1.  **View List (Checklist):**
    * Sales vào màn hình chính, chọn Chương trình (Dropdown).
    * FE gọi API `get_theo_doi_tang_qua_chi_tiet_phan_bo_crs` và `get_theo_doi_tang_qua_danh_sach_chuong_trinh`.
    * Hệ thống hiển thị danh sách Khách hàng dạng thẻ (Card).
    * **Phân loại thẻ:**
        * 🔴 **Chưa xong:** Có nút "Chụp ảnh/Upload".
        * ✅ **Đã xong:** Có icon Check xanh, bấm vào để xem/sửa lại.

2.  **Action: Upload Chứng Từ:**
    * Sales bấm vào thẻ Khách hàng (Trạng thái chưa xong hoặc muốn sửa).
    * Mở **Modal/Drawer** chi tiết.
    * Hiển thị danh sách quà phải tặng (Read-only).
    * **Upload Area:** 5 ô vuông (Slot) để chọn ảnh từ thư viện hoặc chụp mới.
    * **Input Note:** Textarea ghi chú (optional).
    * Bấm "Lưu chứng từ".
    * FE gọi API `insert_theo_doi_tang_qua_chung_tu`.

3.  **Completion:**
    * Sau khi lưu thành công, quay lại màn hình List.
    * Thẻ khách hàng đó chuyển sang trạng thái ✅ (Xanh).
---

# 4. API & Function Specifications

**Global Rules:**
1.  Mọi function đều nhận tham số `jsonb`.
2.  Frontend luôn gửi kèm context mặc định: `manv`, `id`, `inserted_at`.

---

## **4.1. Function: `insert_theo_doi_tang_qua_admin_excel`**
* **Loại:** WRITE
* **Standard:** Tuân thủ `write_insert_function.md`
* **Mục đích:** Admin import file Excel chương trình quà tặng. Logic: Xóa cũ -> Thêm mới.

### **Logic xử lý (PL/pgSQL):**
1.  **Parse Input:** Lấy `ma_chuong_trinh` từ phần tử đầu tiên của mảng JSON.
2.  **Temp Table:** Đổ dữ liệu JSON vào temp table.
3.  **Validation:**
    * Kiểm tra `ma_chuong_trinh` không được rỗng.
    * Kiểm tra `ma_khach_hang`, `ma_qua_tang` không được rỗng.
    * Kiểm tra `so_luong` phải > 0.
4.  **Execution:**
    * `DELETE FROM theo_doi_tang_qua_danh_sach_qua` WHERE `ma_chuong_trinh` = input.
    * `INSERT` toàn bộ dữ liệu từ temp table vào bảng chính.
5.  **Return:** JSON thông báo thành công.

### **JSON Input Specification (`json_input` - Array)**
```json
[
  {
    "ma_chuong_trinh": "CT2025_01",
    "ten_chuong_trinh": "Quà Tết 2025",
    "ma_khach_hang": "KH001",
    "ma_nhan_vien": "SALE_A",
    "ma_qua_tang": "GIFT01",
    "ten_qua": "Hộp Bánh",
    "so_luong": 1,
    "manv": "ADMIN_01",
    "id": "uuid-gen-1",
    "inserted_at": "2025-02-15T10:00:00"
  }
  // ... n rows
]
```

### **JSON Output Specification**
* **Success:**
    ```json
    { "status": "ok", "success_message": "Import thành công 150 dòng." }
    ```
* **Fail:**
    ```json
    { "status": "fail", "error_message": "Dòng 5: Thiếu mã khách hàng." }
    ```

---

## **4.2. Function: `insert_theo_doi_tang_qua_chung_tu`**
* **Loại:** WRITE
* **Standard:** Tuân thủ `write_insert_function.md`
* **Mục đích:** Sales upload hoặc cập nhật chứng từ (Upsert).

### **Logic xử lý (PL/pgSQL):**
1.  **Parse Input:** Lấy object đầu tiên từ mảng (`json_input->0`).
2.  **Validation:** Check sự tồn tại của cặp `(ma_chuong_trinh, ma_khach_hang)` trong bảng danh sách quà (để đảm bảo sales không upload cho khách không có trong list).
3.  **Execution (Upsert):**
    * Sử dụng câu lệnh `INSERT ... ON CONFLICT (ma_chuong_trinh, ma_khach_hang) DO UPDATE`.
    * Cập nhật các cột ảnh, ghi chú và `thoi_gian_tai_len`.
4.  **Return:** JSON thông báo thành công.

### **JSON Input Specification (`json_input` - Array)**
```json
[
  {
    "ma_chuong_trinh": "CT2025_01",
    "ma_khach_hang": "KH001",
    "hinh_anh_1": "https://minio.../1.jpg",
    "hinh_anh_2": "https://minio.../2.jpg",
    "hinh_anh_3": null,
    "hinh_anh_4": null,
    "hinh_anh_5": null,
    "ghi_chu": "Khách nhận đủ",
    "manv": "SALE_A",
    "id": "uuid-gen-2",
    "inserted_at": "2025-02-15T10:05:00"
  }
]
```

### **JSON Output Specification**
* **Success:**
    ```json
    { "status": "ok", "success_message": "Cập nhật chứng từ thành công." }
    ```
* **Fail:**
    ```json
    { "status": "fail", "error_message": "Khách hàng không thuộc chương trình này." }
    ```

---

## **4.3. Function: `get_theo_doi_tang_qua_chi_tiet_phan_bo_crs`**
* **Loại:** READ
* **Standard:** Tuân thủ `write_get_function.md`
* **Mục đích:** Lấy danh sách Checklist công việc cho Sales.
* **Yêu cầu đặc biệt:** **Không** trả về link ảnh (để tối ưu performance), chỉ trả về trạng thái.

### **Logic xử lý (PL/pgSQL):**
1.  **Parse Params:** Lấy `ma_chuong_trinh`, `manv` từ `url_param`.
2.  **CTE Logic:**
    * Query bảng `theo_doi_tang_qua_danh_sach_qua` (Alias A).
    * `LEFT JOIN` bảng `theo_doi_tang_qua_chung_tu` (Alias B) ON Key.
    * Filter: `A.ma_chuong_trinh = p_ma_chuong_trinh` AND `A.ma_nhan_vien = p_manv`.
3.  **Computed Field:**
    * `trang_thai_upload`: `CASE WHEN B.ma_khach_hang IS NOT NULL THEN true ELSE false END`.
4.  **Return:** Trả về JSON object chứa mảng `rows`.

### **JSON Input Specification (`url_param` - Object)**
```json
{
  "ma_chuong_trinh": "CT2025_01",
  "manv": "SALE_A"
}
```

### **JSON Output Specification**
```json
{
  "status": "ok",
  "rows": [
    {
      "ma_chuong_trinh": "CT2025_01",
      "ten_chuong_trinh": "Quà Tết 2025",
      "ma_khach_hang": "KH001",
      "ma_nhan_vien": "SALE_A",
      "ma_qua_tang": "GIFT01",
      "ten_qua": "Hộp Bánh",
      "so_luong": 1,
      
      "ghi_chu": "Khách nhận đủ", 
      
      // True = Sales đã làm việc xong -> Show Icon ✅
      // False = Chưa có dữ liệu -> Show Button Upload
      "trang_thai_upload": true
    },
    {
      "ma_chuong_trinh": "CT2025_01",
      "ten_chuong_trinh": "Quà Tết 2025",
      "ma_khach_hang": "KH002",
      "ma_nhan_vien": "SALE_A",
      "ma_qua_tang": "GIFT01",
      "ten_qua": "Hộp Bánh",
      "so_luong": 2,
      
      "ghi_chu": null,
      "trang_thai_upload": false
    }
  ]
}
```

-----

## **4.4. Function: `get_theo_doi_tang_qua_danh_sach_chuong_trinh`**

  * **Loại:** READ
  * **Standard:** Tuân thủ `write_get_function.md`
  * **Mục đích:** Lấy danh sách các chương trình quà tặng để hiển thị lên Dropdown chọn (Filter).
  * **Logic nghiệp vụ:** Chỉ lấy các chương trình mà nhân viên Sales đó có tham gia (tránh hiển thị rác các chương trình của vùng/miền khác).

### **Logic xử lý (PL/pgSQL):**

1.  **Parse Params:** Lấy `manv` từ `url_param`.
2.  **Query:**
      * `SELECT DISTINCT` `ma_chuong_trinh`, `ten_chuong_trinh`
      * **FROM** `theo_doi_tang_qua_danh_sach_qua`
      * **WHERE** `ma_nhan_vien` = `p_manv` (Lọc theo user đang đăng nhập).
3.  **Return:** Trả về JSON object chứa mảng `rows`.

### **JSON Input Specification (`url_param` - Object)**

```json
{
  "manv": "SALE_A"
}
```

### **JSON Output Specification**

```json
{
  "status": "ok",
  "rows": [
    {
      "ma_chuong_trinh": "CT2025_01",
      "ten_chuong_trinh": "Quà Tết 2025"
    },
    {
      "ma_chuong_trinh": "CT2024_12",
      "ten_chuong_trinh": "Tri ân khách hàng Q4/2024"
    }
  ]
}
```

---
**End of PRD v1.19**