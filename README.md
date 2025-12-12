# 📘 AI Documentation Hub

Kho tài liệu tổng hợp dành cho tất cả dự án thuộc hệ thống của công ty, bao gồm:
- Cấu trúc dữ liệu Postgres & BigQuery  
- Tài liệu PRD chi tiết cho từng module/app  
- Logic xử lý, hàm, stored procedures  
- Quy tắc đặt tên, data contract, và mô hình dữ liệu  
- Tài liệu chuẩn hoá hỗ trợ AI/Copilot/Gemini trong quá trình phát triển  

---

## 📂 Cấu trúc thư mục

```
ai-docs/
 ├── postgres/
 │    ├── schema.md          # Mô tả bảng, cột, quan hệ, ERD
 │    └── prd/               # Tài liệu PRD cho các module liên quan Postgres
 │         ├── *.md
 │         └── ...
 │
 ├── bigquery/
 │    ├── schema.md          # Dataset, tables, partitioning, clustering
 │    └── prd/               # PRD hoặc logic xử lý liên quan BigQuery
 │         ├── *.md
 │         └── ...
 │
 └── prd/
      ├── *.md               # PRD tổng cho app, form mini-app, module front-end/back-end
      └── ...
```

---

## 🧩 Mục đích của từng thư mục

### **1. `/postgres`**
Chứa tất cả tài liệu liên quan đến hệ thống chạy trên PostgreSQL:
- `schema.md`:  
  - Cấu trúc bảng  
  - Index  
  - Constraints  
  - References  
  - Mối quan hệ (ERD)  
- Folder `/prd`:  
  - Tài liệu logic nghiệp vụ  
  - PRD của các module có dùng Postgres  
  - Tài liệu mô tả các hàm SQL/Function/Trigger  

---

### **2. `/bigquery`**
Dành cho hệ thống Data Warehouse hoặc Analytics trên BigQuery:
- `schema.md`:  
  - Dataset  
  - Table  
  - Partition & Clustering  
  - Quy tắc đặt tên  
  - Data pipeline  
  - Mô tả luồng dữ liệu  
- Folder `/prd`:  
  - Tài liệu tính toán, report, KPI  
  - Logic transform (ELT)  
  - Quy tắc chuẩn hoá dữ liệu  

---

### **3. `/prd` (PRD tổng)**
Dành cho:
- PRD ứng dụng mini  
- PRD website / form  
- Các module front-end / back-end  
- Yêu cầu nghiệp vụ tổng  
- Flow màn hình  
- API mapping  
- Business rule & validation  

Folder này giúp team xem tổng quan từng dự án mà không phụ thuộc vào database nào.

---

## 🧭 Quy ước đặt tên Markdown

| Loại file | Quy ước tên | Ví dụ |
|----------|-------------|-------|
| PRD module | `prd_<module>.md` | `prd_inventory.md` |
| Schema | `schema.md` cố định | `schema.md` |
| API | `api_<module>.md` | `api_auth.md` |
| Logic SQL | `sql_<feature>.md` | `sql_customer_points.md` |

---

## 🚀 Quy trình cập nhật tài liệu

1. Sửa tài liệu ở dự án gốc (**Postgres, BigQuery, mini-app**)  
2. Sync vào repo `ai-docs` (copy, symlink hoặc script auto-sync)  
3. Push thẳng lên GitHub:
```sh
git add .
git commit -m "Update docs"
git push
```

---

## 🤖 Gợi ý sử dụng với AI (Copilot / Gemini)

Để AI hiểu dự án tốt hơn:
- Đặt toàn bộ PRD + Schema trong từng folder đúng chuẩn  
- Tách rõ:
  - logic  
  - cấu trúc bảng  
  - quy tắc validate  
  - luồng nghiệp vụ  
- Viết mô tả input/output rõ ràng  
- Đặt tên file nhất quán  

Điều này giúp AI sinh code chính xác và hiểu dự án như tài liệu nội bộ.

---

## 🧱 Roadmap

- [ ] Thêm `data-contract.md`  
- [ ] Template PRD chuẩn hoá  
- [ ] Folder `/ai-prompts`  
- [ ] Chuẩn hoá schema cho tất cả dự án  

---

## 📄 License  
Internal use only.