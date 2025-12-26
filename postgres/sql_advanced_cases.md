## TH1: Xử lý Duplicate (Nhân bản) Dữ liệu khi Join 1-N

### 1. Vấn đề thực tế (Ví dụ Đơn hàng & Phí Ship)
Khi bạn Join bảng **Đơn hàng** (có Phí Ship 30k) với bảng **Chi tiết sản phẩm** (khách mua 3 món):
* Dòng "Phí Ship 30k" sẽ bị lặp lại 3 lần theo từng món hàng.
* **Hậu quả:** Khi tính tổng, sếp thấy tổng phí thu được là **90k** (Sai, gấp 3 lần thực tế).

### 2. Giải pháp: Biến "Hiệu Lực Tính" (`hieu_luc_tinh`)
Tạo một cột cờ (Flag) hoạt động như công tắc bật/tắt:
* **Giá trị 1:** Dòng đầu tiên -> Có **hiệu lực tính** (giữ nguyên giá trị).
* **Giá trị 0:** Các dòng sau -> Không tính (trả về 0).

### 3. Code triển khai (SQL)
#### 3.1 Giải pháp 1 Sử dụng Biến Flag "Hiệu Lực Tính"
```sql
WITH Du_Lieu_Tho AS (
    SELECT
        D.ma_don_hang,
        C.ten_san_pham,
        C.gia_san_pham, -- Giá sản phẩm (Giữ nguyên)
        D.phi_ship,     -- Phí ship (Bị lặp lại nhiều lần)
        
        -- Tạo biến "Hiệu Lực Tính": Dòng đầu là 1, dòng sau là 0
        -- Dùng ORDER BY NULL để chạy nhanh nhất (không cần sắp xếp)
        CASE 
            WHEN ROW_NUMBER() OVER(PARTITION BY D.ma_don_hang ORDER BY NULL) = 1 
            THEN 1 
            ELSE 0 
        END as hieu_luc_tinh
    FROM Don_Hang D
    LEFT JOIN Chi_Tiet_Don_Hang C ON D.ma_don_hang = C.ma_don_hang
)

SELECT
    ma_don_hang,
    ten_san_pham,
    gia_san_pham,
    -- Công thức: [Phí Ship Gốc] * [Hiệu Lực Tính]
    phi_ship * hieu_luc_tinh as phi_ship_thuc_te
FROM Du_Lieu_Tho;
```

#### 3.2 Giải pháp 2 Nhân giá trị trực tiếp với row number theo key
```SQL
SELECT
    D.ma_don_hang,
    C.ten_san_pham,
    D.phi_ship as phi_ship_goc,
    
    -- Gọn nhất: Nhân trực tiếp Phí ship với biểu thức điều kiện
    D.phi_ship * (CASE WHEN ROW_NUMBER() OVER(PARTITION BY D.ma_don_hang ORDER BY NULL) = 1 THEN 1 ELSE 0 END) as phi_ship_thuc_te

FROM Don_Hang D
LEFT JOIN Chi_Tiet_Don_Hang C ON D.ma_don_hang = C.ma_don_hang;
```


### 4. Kết quả minh hoạ
Ví dụ Đơn #101 mua 3 món (Áo, Quần, Mũ), Phí ship gốc là 30k.

| Mã Đơn | Sản Phẩm | Giá Sản Phẩm | Phí Ship Gốc | Biến `hieu_luc_tinh` | Phí Ship Thực Tế |
| :--- | :--- | :--- | :--- | :--- | :--- |
| #101 | Áo thun | 100k | 30k | **1** | **30k** |
| #101 | Quần Jean | 200k | 30k | **0** | **0** |
| #101 | Mũ lưỡi trai | 50k | 30k | **0** | **0** |
| **Tổng** | | **350k**| **90k (Sai)** | | **30k (Đúng)** |