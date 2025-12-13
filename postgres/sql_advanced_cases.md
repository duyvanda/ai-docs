## TH1: Xử lý Duplicate (Nhân bản) Dữ liệu khi Join 1-N

### 1. Vấn đề
Khi Join **Bảng Cha** (1 dòng chứa: Plan, Ngân sách, Phí Ship...) với **Bảng Con** (N dòng chứa: Hoá đơn, Sản phẩm...), dữ liệu Bảng Cha sẽ bị lặp lại N lần.
-> **Hậu quả:** Khi tính tổng (**SUM**), kết quả sẽ bị sai (gấp N lần thực tế).

### 2. Giải pháp: Biến "Hiệu Lực" (`hieu_luc`)
Tạo một cột cờ (Flag) hoạt động như công tắc:
* **Giá trị 1:** Dòng đầu tiên -> Có **hiệu lực** tính toán.
* **Giá trị 0:** Các dòng sau -> Không hiệu lực (về 0).

### 3. Code triển khai (SQL tối ưu)

```sql
WITH RawData AS (
    SELECT
        A.id,
        B.detail_id,
        B.val_detail, -- Số liệu bảng con (Giữ nguyên)
        A.val_master, -- Số liệu bảng cha (Bị lặp: Plan/Ship/Budget...)
        
        -- Tạo biến "Hiệu Lực": Dòng đầu là 1, dòng sau là 0
        -- Dùng ORDER BY NULL để tối ưu tốc độ (không cần sort)
        CASE 
            WHEN ROW_NUMBER() OVER(PARTITION BY A.id ORDER BY NULL) = 1 
            THEN 1 
            ELSE 0 
        END as hieu_luc
    FROM TableA_Master A
    LEFT JOIN TableB_Detail B ON A.id = B.id
)

SELECT
    id,
    detail_id,
    val_detail,
    -- Công thức: [Số liệu gốc] * [Hiệu Lực]
    val_master * hieu_luc as real_val_master
FROM RawData;
```

### 4. Kết quả minh hoạ
Ví dụ ID #1 có Plan là 200, đi kèm 3 hoá đơn chi tiết:

| ID | Chi tiết | Plan Gốc (Bị lặp) | Biến `hieu_luc` | Plan Thực Tế |
| :--- | :--- | :--- | :--- | :--- |
| #1 | Inv 1 | 200 | **1** | **200** |
| #1 | Inv 2 | 200 | **0** | **0** |
| #1 | Inv 3 | 200 | **0** | **0** |
| **Tổng** | | **600 (Sai)**| | **200 (Đúng)** |