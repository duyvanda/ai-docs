# Product Requirements Document (PRD)

## Hệ Thống Theo Dõi Tặng Quà (Gift Tracking System)

**Version:** 1.0

**Date:** 12/12/2025

**Architecture:** Modern Monolith (Postgres-First)

**API Gateway:** Python (Dumb Pipe - RPC Style)

## 1. Tổng quan (Overview)

Hệ thống quản lý quy trình phân bổ và theo dõi tặng quà CSKH.
Dữ liệu được tích hợp với:
* **PostgreSQL:** Lưu trữ dữ liệu nghiệp vụ.
* **Local server:** Lưu trữ hình ảnh chứng từ.

-----

## 2. Mục tiêu (Goals)

* **Kiểm soát minh bạch:** Đảm bảo quà tặng đến đúng tay khách hàng thông qua bằng chứng hình ảnh.
* **Số hóa quy trình:** Thay thế báo cáo thủ công (Zalo/Excel) bằng hệ thống tập trung.
* **Real-time Tracking:** Admin nắm bắt tiến độ tặng quà của Sales ngay lập tức.

-----

## 3. Đối tượng sử dụng (User Personas)

| Vai trò | Mô tả công việc trên hệ thống |
| :--- | :--- |
| **Admin** | - Import danh sách quà tặng từ Excel.<br>- Theo dõi báo cáo. |
| **User (Sales)** | - Xem danh sách khách hàng và quà cần tặng.<br>- Upload hình ảnh chứng từ khi hoàn thành. |

-----

## 4. User Flow & UI Overview (Chi tiết quy trình)

### 4.1. Phân hệ Admin - Import dữ liệu

**User Flow: Upload Chương Trình**

1.  **Start:** Admin truy cập trang quản lý (/formcontrol/theo_doi_tang_qua/admin).
2.  **Input:** Nhập Mã & Tên chương trình. Chọn file Excel (chứa danh sách KH, NV, Quà). Adding a reset mechanism and ensuring the input value is cleared when a new file is selected
3.  **Submit:**
    * Admin bấm "Import".
    * **Call API:** `insert_theo_doi_tang_qua_admin_excel`.
4.  **Feedback:** Thông báo số dòng import thành công/thất bại.
5.  **Các cột:**
ma_chuong_trinh
ten_chuong_trinh
ma_khach_hang
ten_nha_thuoc
ma_phu
ten_phu
ma_nhan_vien
ma_qua_tang
ten_qua
so_luong
6. Bấm vào lịch sử để xem lại mã và CT đã up, goi API `get_theo_doi_tang_qua_admin_dashboard`

### 4.2. Phân hệ Sales - Thực hiện tặng quà
**Start:** Sales truy cập trang thực hiện (/formcontrol/theo_doi_tang_qua/sales).
**User Flow: Checklist & Báo cáo**

1.  **View List:**
    * Sales chọn chương trình từ dropdown (API: `get_theo_doi_tang_qua_danh_sach_chuong_trinh`).
    * Hệ thống load danh sách chi tiết (API: `get_theo_doi_tang_qua_chi_tiet_phan_bo_crs`).
    * Hiển thị danh sách khách hàng kèm trạng thái `trang_thai_upload` (True/False).
2.  **Action:**
    * Sales bấm vào khách hàng.
    * Nhập ghi chú, chọn ảnh.
    * Bấm "Lưu".
    * **Call API:** `insert_theo_doi_tang_qua_chung_tu`.

-----

## 5. Thiết kế Cơ sở dữ liệu (Database Schema)

### **Table 1: `theo_doi_tang_qua_danh_sach_qua`** (Master)
Lưu trữ dữ liệu gốc từ file Excel Admin upload.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `ma_chuong_trinh` | text | **PK** - Mã chương trình |
| `ten_chuong_trinh` | text | Tên chương trình |
| `ma_khach_hang` | text | **PK** - Mã khách hàng |
| `ten_nha_thuoc` | text      | Tên nhà thuốc |
| `ma_phu`        | text      | **PK** Mã phụ (NOT NULL)        |
| `ten_phu`       | text      | Tên phụ       |
| `ma_nhan_vien` | text | Mã nhân viên (Index) |
| `ma_qua_tang` | text | **PK** - Mã quà tặng |
| `ten_qua` | text | Tên quà |
| `so_luong` | numeric | Số lượng |
| `nguoi_tai_len` | text | User Admin upload |
| `thoi_gian_tai_len` | timestamp | Thời gian upload |

### **Table 2: `theo_doi_tang_qua_chung_tu`** (Transaction)
Lưu trữ kết quả thực hiện của Sales.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `ma_chuong_trinh` | text | **PK** - Mã chương trình |
| `ma_khach_hang` | text | **PK** - Mã khách hàng |
| `hinh_anh_1` | text | Slot ảnh 1 |
| `hinh_anh_2` | text | Slot ảnh 2 |
| `hinh_anh_3` | text | Slot ảnh 3 |
| `hinh_anh_4` | text | Slot ảnh 4 |
| `hinh_anh_5` | text | Slot ảnh 5 |
| `ghi_chu` | text | Ghi chú |
| `nguoi_tai_len` | text | Mã nhân viên Sales |
| `thoi_gian_tai_len` | timestamp | Thời gian upload |

### **Table 3: `d_master_khachhang`** (Transaction)
Lưu trữ kết quả thực hiện của Sales.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `custid` | text | **PK** - Mã khách hàng |
| `custname` | text | Tên khách hàng |

-----

## 6. API & Function Specifications (Chi tiết kỹ thuật)

**Backend Logic:** 100% được gói gọn trong **PostgreSQL Stored Functions (PL/pgSQL) nhận jsonb và output jsonb**.
**Python API Gateway:** Dumb pipe (điều hướng & xác thực).

### 6.1. Nhóm Admin

#### **Function:** `insert_theo_doi_tang_qua_admin_excel`

* **Loại:** WRITE
* **Mục đích:** Admin import file Excel chương trình quà tặng. Logic: Xóa cũ -> Thêm mới.
* **Validation:**
    1.  `ma_chuong_trinh`, `ma_khach_hang`, `ma_qua_tang` không được rỗng.
    2.  `so_luong` > 0.
* **Logic:**
    1.  Parse Input JSON.
    2.  `DELETE FROM theo_doi_tang_qua_danh_sach_qua` WHERE `ma_chuong_trinh` = input.
    3.  `INSERT` dữ liệu mới.
* **JSON Input (`body`):**
    ```json
    [
      {
        "ma_chuong_trinh": "CT2025_01",
        "ten_chuong_trinh": "Quà Tết 2025",
        "ma_khach_hang": "KH001",
        "ten_nha_thuoc": "Nhà thuốc An Khang",
        "ma_phu": "MP001",
        "ten_phu": "Chi nhánh Quận 1"
        "ma_nhan_vien": "SALE_A",
        "ma_qua_tang": "GIFT01",
        "ten_qua": "Hộp Bánh",
        "so_luong": 1,
        "manv": "ADMIN_01",
        "id": "uuid-gen-1",
        "inserted_at": "2025-02-15T10:00:00"
      }
    ]
    ```
* **JSON Output:**
    * Success: `{ "status": "ok", "success_message": "Import thành công 150 dòng." }`
    * Fail: `{ "status": "fail", "error_message": "..." }`

Ok 👍 mình hiểu ý bạn rồi.
Dưới đây là **PHIÊN BẢN VIẾT ĐÚNG CẤU TRÚC PRD**, **KHÔNG dùng heading `###`**, **chỉ dùng `####` cho Function** và các tiêu đề con **chỉ dùng `**bold**`** đúng như format bạn đang dùng trong PRD.

Bạn **copy dán trực tiếp** là dùng được.

---

#### **Function:** `get_theo_doi_tang_qua_admin_dashboard`

**Loại:** READ

**Mục đích:**
Cho phép Admin xem danh sách các chương trình mà **một Sales cụ thể đã upload chứng từ**, kèm theo thời gian upload, phục vụ kiểm soát và audit theo từng nhân viên.

**JSON Input (`url_param`):**

```json
{
  "manv": "MR2948"
}
```

**Input Rules:**

* `manv` là **bắt buộc**
* Chỉ lấy dữ liệu của **người upload = manv**

**Logic:**

**Step 1:**
Nhận tham số `manv` từ `url_param`.

**Step 2:**
Query bảng `theo_doi_tang_qua_chung_tu` và filter theo điều kiện:

* `nguoi_upload = manv`

**Step 3:**
Join bảng `theo_doi_tang_qua_danh_sach_qua` theo các khóa:

* `ma_chuong_trinh`
* `ma_khach_hang`

để lấy thông tin `ten_chuong_trinh`.

**Step 4:**
Select **DISTINCT** các trường sau:

* `ma_chuong_trinh`
* `ten_chuong_trinh`
* `nguoi_upload`
* `thoi_gian_upload`

**Step 5:**
Sắp xếp dữ liệu theo:

* `thoi_gian_upload DESC`

**JSON Output:**

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

### 6.2. Nhóm Sales

#### **Function:** `insert_theo_doi_tang_qua_chung_tu`

* **Loại:** WRITE
* **Mục đích:** Sales upload hoặc cập nhật chứng từ (Upsert).
* **Validation:**
    1.  Check tồn tại cặp `(ma_chuong_trinh, ma_khach_hang)` trong bảng danh sách quà.
* **Logic:**
    1.  `INSERT ... ON CONFLICT (ma_chuong_trinh, ma_khach_hang) DO UPDATE` hình ảnh và ghi chú.
* **JSON Input (`body`):**
    ```json
    [
      {
        "ma_chuong_trinh": "CT2025_01",
        "ma_khach_hang": "KH001",
        "hinh_anh_1": "https://bi.meraplion.com/DMS/theo_doi_tang_qua_chung_tu/<index>_<ma_khach_hang>.jpg",
        "hinh_anh_2": "https://bi.meraplion.com/DMS/theo_doi_tang_qua_chung_tu/<index>_<ma_khach_hang>.jpg",
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
* **JSON Output:**
    * Success: `{ "status": "ok", "success_message": "Cập nhật chứng từ thành công." }`
    * Fail: `{ "status": "fail", "error_message": "Khách hàng không thuộc chương trình này." }`

#### **Function:** `get_theo_doi_tang_qua_chi_tiet_phan_bo_crs`

* **Loại:** READ
* **Mục đích:** Lấy danh sách chi tiết phân bổ cho Sales (Checklist).
* **Logic:**
    1.  Query bảng `theo_doi_tang_qua_danh_sach_qua` (A).
    2.  Left Join `theo_doi_tang_qua_chung_tu` (B).
    3.  Tính `trang_thai_upload`: True nếu B có dữ liệu, False nếu không.
* **JSON Input (`url_param`):**
    ```json
    {
      "ma_chuong_trinh": "CT2025_01",
      "manv": "SALE_A"
    }
    ```
* **JSON Output:**
    ```json
    {
      "status": "ok",
      "rows": [
        {
          "ma_chuong_trinh": "CT2025_01",
          "ten_chuong_trinh": "Quà Tết 2025",
          "ma_khach_hang": "KH001",
          "ten_khach_hang": "KH NV Số 001",
          "ma_nhan_vien": "SALE_A",
          "ma_qua_tang": "GIFT01",
          "ten_qua": "Hộp Bánh",
          "so_luong": 1,
          "ghi_chu": "Khách nhận đủ",
          "trang_thai_upload": true
        },
        {
          "ma_chuong_trinh": "CT2025_01",
          "ten_chuong_trinh": "Quà Tết 2025",
          "ma_khach_hang": "KH002",
          "ten_khach_hang": "KH NV Số 002",
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

#### **Function:** `get_theo_doi_tang_qua_danh_sach_chuong_trinh`

* **Loại:** READ
* **Mục đích:** Lấy danh sách chương trình để lọc.
* **Logic:** `SELECT DISTINCT` chương trình theo `manv`.
* **JSON Input (`url_param`):**
    ```json
    {
      "manv": "SALE_A"
    }
    ```
* **JSON Output:**
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