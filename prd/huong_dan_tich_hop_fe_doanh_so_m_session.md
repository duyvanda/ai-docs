# API Lấy Doanh số Nhà thuốc & Nhãn (M.Session)

### 1. URL & Method
- **Method:** `GET`
- **URL:** 
  ```
  https://bi.meraplion.com/local/get_data/get_tracking_chi_phi_tp_m_session_doanh_so/
  ```

---

### 2. Input JSON (Query Params)

| Field | Type | Bắt buộc | Mô tả |
| :--- | :---: | :---: | :--- |
| `custid` | string | Có | Mã Nhà thuốc được chọn ở Bước 1 |

**Ví dụ Request:**
```
GET https://bi.meraplion.com/local/get_data/get_tracking_chi_phi_tp_m_session_doanh_so/?custid=000004
```

---

### 3. Output JSON

#### Trường hợp thành công:
```json
{
  "status": "ok",
  "custid": "000004",
  "total_sales": {
    "mtd_covat": 0,
    "mtd_chuavat": 0,
    "ytd_covat": 2262000,
    "ytd_chuavat": 2154290,
    "lytd_covat": 0,
    "lytd_chuavat": 0,
    "ly_covat": 1640900,
    "ly_chuavat": 1562771
  },
  "brand_sales": [
    {
      "brand": "Metodex",
      "mtd_covat": 0,
      "mtd_chuavat": 0,
      "ytd_covat": 540000,
      "ytd_chuavat": 514280,
      "lytd_covat": 0,
      "lytd_chuavat": 0,
      "ly_covat": 0,
      "ly_chuavat": 0
    },
    {
      "brand": "Metison",
      "mtd_covat": 0,
      "mtd_chuavat": 0,
      "ytd_covat": 450000,
      "ytd_chuavat": 428580,
      "lytd_covat": 0,
      "lytd_chuavat": 0,
      "ly_covat": 300000,
      "ly_chuavat": 285720
    }
  ]
}
```

#### Trường hợp Nhà thuốc chưa có phát sinh doanh số:
```json
{
  "status": "ok",
  "custid": "999999",
  "total_sales": {
    "mtd_covat": 0,
    "mtd_chuavat": 0,
    "ytd_covat": 0,
    "ytd_chuavat": 0,
    "lytd_covat": 0,
    "lytd_chuavat": 0,
    "ly_covat": 0,
    "ly_chuavat": 0
  },
  "brand_sales": []
}
```

---

### 4. Diễn giải các trường số liệu

- **`total_sales`**: Tổng toàn bộ Nhà thuốc.
- **`brand_sales`**: Chi tiết theo từng Nhãn.
- **Các mốc thời gian:**
  - `mtd`: Tháng này (từ ngày 01 đến hôm nay).
  - `ytd`: Năm nay (từ 01/01 đến hôm nay).
  - `lytd`: Cùng kỳ năm trước (từ 01/01 năm ngoái đến cùng ngày năm ngoái).
  - `ly`: Toàn bộ cả năm trước (từ 01/01 đến 31/12 năm ngoái).
- **Hậu tố:**
  - `_covat`: Doanh số có VAT.
  - `_chuavat`: Doanh số chưa VAT.
