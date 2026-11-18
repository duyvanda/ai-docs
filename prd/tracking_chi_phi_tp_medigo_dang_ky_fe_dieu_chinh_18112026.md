# Medigo – Hướng dẫn FE: điều chỉnh lượt trong tháng (sau khi duyệt)

> ✅ **API đã deploy lên production ngày 18/11/2026**, FE gọi được ngay.

Tài liệu đầy đủ: [`tracking_chi_phi_tp_medigo_dang_ky.md`](tracking_chi_phi_tp_medigo_dang_ky.md). Luồng đăng ký tháng sau: [`tracking_chi_phi_tp_medigo_dang_ky_fe_t11.md`](tracking_chi_phi_tp_medigo_dang_ky_fe_t11.md).
Mockup giao diện: [`tracking_chi_phi_tp_medigo_dieu_chinh_18112026_mockup.html`](tracking_chi_phi_tp_medigo_dieu_chinh_18112026_mockup.html) (mở bằng trình duyệt).

## 0. Yêu cầu từ business

Đăng ký tháng sau vẫn giữ như cũ (CRM chốt → anh Viển `MR0485` duyệt). Business muốn thêm:

- Sau khi đã duyệt, **trong tháng đang chạy** CRM được **điều chỉnh từng NT**, so với số liệu **của chính tháng hiện tại**.
- 3 kiểu điều chỉnh: **Tăng**, **Giảm**, **Ngưng**.
- **Không cần duyệt lại**, cập nhật thẳng vào số lượt của tháng.
- **Lưu lịch sử** mỗi lần điều chỉnh (ngày, người, số lượt) để kế toán tra cứu.
- Chỉ được **Tăng khi % dùng tháng hiện tại ≥ 40%**.

**Ví dụ:** 3 NT trong tháng 11.

| NT | Tổng lượt | Đã dùng | Còn lại | % dùng | CRM điều chỉnh | Tổng lượt sau | Còn lại sau |
|---|---|---|---|---|---|---|---|
| A | 10 | 10 | 0 | 100% | **Tăng 10** | **20** | 10 |
| B | 10 | 1 | 9 | 10% | **Giảm 3** (Tăng bị khóa vì < 40%) | **7** | 6 |
| C | 20 | 4 | 16 | 20% | **Ngưng** | **4** (= đã dùng) | 0 |

## 1. Quy tắc

| Điều chỉnh | Điều kiện | Tổng lượt mới | `trang_thai_nt` |
|---|---|---|---|
| **Tăng** | % dùng tháng này ≥ 40; CRM nhập số lượt tăng là số nguyên dương (≥ 1) | Tổng + số lượt nhập | `Renew` → `Add`, các trạng thái khác giữ nguyên |
| **Giảm** | CRM nhập số lượt giảm là số nguyên dương (≥ 1) và ≤ còn lại (không giảm dưới số đã dùng) | Tổng − số lượt nhập | Giữ nguyên |
| **Ngưng** | – | **= số đã dùng** (còn lại = 0) | `Stop` |

*"Số lượt nhập" = số CRM gõ vào ô Số lượt trong modal (field `so_luot` khi POST), không phải tổng lượt hay số còn lại.*

- Chỉ điều chỉnh được NT **đã duyệt** (`status = 'C'`), **tháng hiện tại**, **chưa Ngưng**, và thuộc **CRM đang đăng nhập** (`manv`).
- Ngưng giữa tháng khác ngưng lúc đăng ký: lượt đã dùng là có thật nên tổng lượt = số đã dùng, không về 0. NT đã Ngưng không được kéo sang danh sách đăng ký tháng sau.
- Điều chỉnh xong vẫn giữ trạng thái **Đã duyệt**, không phải duyệt lại.

## 2. Nút "Điều chỉnh" trên card NT

Thêm 1 nút **⚙ Điều chỉnh** cạnh badge trạng thái của card NT (màn danh sách hiện tại, API `get_tracking_chi_phi_tp_medigo_danh_sach`).

Chỉ hiện nút khi thỏa cả 3:
- `status === 'C'`
- `thang` = tháng hiện tại (vd hôm nay 18/11/2026 → `2026-11-01`)
- `trang_thai_nt !== 'Stop'`

## 3. Mở modal – `GET get_tracking_chi_phi_tp_medigo_dieu_chinh`

```
GET https://bi.meraplion.com/local/get_data/get_tracking_chi_phi_tp_medigo_dieu_chinh/?manv=MR0319&custid=015598
```

`manv` và `custid` **bắt buộc**. `data` là **mảng luôn có đúng 1 phần tử** (NT đang chọn), FE đọc `data[0]`:

```json
{
  "status": "ok",
  "data": [
    {
      "thang": "2026-11-01",
      "custid": "015598",
      "custname": "NT Phúc Lộc - Quận 12 - HCM",
      "trang_thai_nt": "New",
      "so_luot_dang_ky": 10,               // Tổng lượt tháng này
      "so_luot_su_dung_thang_nay": 1,      // Đã dùng tháng này
      "so_luot_con_lai_thang_nay": 9,      // Còn lại = tổng − đã dùng
      "phan_tram_used_thang_nay": 10.0     // % dùng tháng này
    }
  ]
}
```

```js
const nt = res.data[0];   // luôn 1 phần tử; không tìm thấy NT thì BE trả lỗi 400, không trả mảng rỗng
```

Lỗi (thiếu tham số, NT không thuộc CRM, chưa duyệt, không phải tháng hiện tại): function trả `{"status": "fail", "error_message": "..."}` → gateway trả **HTTP 400** kèm body đó. FE bắt lỗi 400, hiện `error_message`, không mở modal.

## 4. Nội dung modal

Xem mockup: [`tracking_chi_phi_tp_medigo_dieu_chinh_18112026_mockup.html`](tracking_chi_phi_tp_medigo_dieu_chinh_18112026_mockup.html).

## 5. Xác nhận – `POST insert_tracking_chi_phi_tp_medigo_dieu_chinh`

```
POST https://bi.meraplion.com/local/post_data/insert_tracking_chi_phi_tp_medigo_dieu_chinh/
```

```json
[{
  "manv": "MR0319",
  "thang": "2026-11-01",     // lấy từ field thang của API GET
  "custid": "015598",
  "loai": "GIAM",            // TANG | GIAM | NGUNG
  "so_luot": 3,              // bỏ trống khi NGUNG
  "ghi_chu": "NT ít khách, giảm bớt lượt"
}]
```

- `thang` **bắt buộc**. BE chỉ nhận tháng hiện tại (chặn trường hợp mở modal ngày 30 mà sang ngày 1 mới bấm xác nhận).
- BE **tự tính** tổng lượt mới, không nhận tổng lượt từ FE. BE kiểm tra lại toàn bộ điều kiện ở mục 1. Sai thì function trả `{"status": "fail", "error_message": "..."}` → gateway **rollback** và trả **HTTP 400**, ví dụ `"error_message": "% dùng tháng này 10% < 40%, chưa được tăng"`. FE bắt lỗi 400, hiện `error_message`, giữ modal mở.
- Thành công: HTTP 200, `{"status": "ok", "success_message": "Đã điều chỉnh NT Phúc Lộc - Quận 12 - HCM: tổng lượt 10 → 7.", "so_luot_dang_ky": 7}` → hiện `success_message`, đóng modal, **tải lại** danh sách (gọi lại `get_tracking_chi_phi_tp_medigo_danh_sach`).

## 6. Lưu ý

- Số "Đã dùng" lấy từ Google Sheets do Medigo nhập, IT sync định kỳ nên có thể chậm hơn thực tế vài ngày.
- Mỗi lần xác nhận, BE tự ghi lịch sử (ngày, người, loại, số lượt, tổng trước / sau) vào cột `lich_su_dieu_chinh` để kế toán tra cứu. FE không cần hiển thị.
