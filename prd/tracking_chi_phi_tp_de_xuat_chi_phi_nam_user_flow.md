# Hướng dẫn Quy trình – Đề xuất Chi phí Hoạt động Năm (TP)

## Tổng quan

Hệ thống cho phép đội ngũ TP lập kế hoạch và trình duyệt ngân sách đầu tư cho từng nhà thuốc/khách hàng theo từng loại hoạt động trong năm. Quy trình gồm 3 bước chính, thực hiện tuần tự theo vai trò.

---

## Bước 1: CX thiết lập cấu hình năm

**Người thực hiện:** CX (Admin)

1. CX chọn **năm áp dụng** trên giao diện (ví dụ: 2026).
2. CX chuẩn bị file Excel theo đúng mẫu, gồm 2 sheet:
   - **Sheet `ds_kh`:** Danh sách khách hàng mục tiêu, bao gồm tên KH, CRM phụ trách, tỉnh, tổng ngân sách được duyệt, và các loại hoạt động áp dụng cho từng KH.
   - **Sheet `ds_app`:** Danh mục các loại hoạt động đầu tư (Chiến lược / Commercial) kèm tên mô tả.
   - **File mẫu:** https://bi.meraplion.com/DMS/excel_file/tp_setting_de_xuat_chi_phi_hoat_dong_nam.xlsx
3. CX chọn file và nhấn **Upload** để nạp cấu hình vào hệ thống.

> Sau khi upload thành công, dữ liệu cấu hình này là cơ sở để hệ thống phân bổ danh sách KH cho CRM và kiểm soát ngân sách.

---

## Bước 2: CRM lập đề xuất ngân sách

**Người thực hiện:** CRM (Quản lý vùng)

1. CRM mở form đề xuất. Hệ thống tự động hiển thị **danh sách KH thuộc phạm vi quản lý** của CRM đó.
2. Với mỗi KH, CRM thấy:
   - Tổng ngân sách được duyệt cho KH.
   - Số tiền CRM đã đề xuất (nếu có).
   - **Số dư ngân sách còn lại.**
   - Chỉ các hoạt động được phân bổ cho KH đó (không hiển thị hoạt động ngoài danh sách).
3. CRM nhập **số tiền đề xuất** cho từng hoạt động.
4. Hệ thống tự động kiểm tra: **tổng đề xuất cho một KH không được vượt quá ngân sách đã duyệt** của KH đó. Nếu vượt, hệ thống sẽ báo lỗi và không cho phép gửi.
5. CRM nhấn **Gửi** → đề xuất chuyển sang trạng thái **Chờ CRD duyệt**.

> CRM có thể chỉnh sửa đề xuất bằng cách nhập lại và gửi – hệ thống sẽ tự cập nhật, thay thế đề xuất cũ.

---

## Bước 3: CRD xem xét và phê duyệt

**Người thực hiện:** CRD (Giám đốc vùng)

1. CRD mở màn hình duyệt. Hệ thống hiển thị toàn bộ đề xuất **đang chờ duyệt** của các CRM cấp dưới, nhóm theo từng KH.
2. CRD xem chi tiết: tên KH, loại hoạt động, số tiền CRM đề xuất, tổng ngân sách KH.
3. CRD có thể:
   - **Duyệt:** Xác nhận đề xuất. Có thể điều chỉnh số tiền duyệt khác với số tiền CRM đề xuất.
   - **Từ chối:** Bắt buộc nhập lý do từ chối trước khi xác nhận.
4. CRD có thể xử lý **nhiều đề xuất cùng lúc**.

---

## Trạng thái đề xuất

| Trạng thái | Ý nghĩa | Ai thực hiện |
| :---: | :--- | :--- |
| Chờ duyệt | CRM đã gửi, đang chờ CRD xem xét | CRM |
| Đã duyệt | CRD đã phê duyệt (số tiền có thể được điều chỉnh) | CRD |
| Từ chối | CRD không đồng ý, có kèm lý do | CRD |

**Luồng:** Chờ duyệt → Đã duyệt hoặc Từ chối
