# Medigo – Hướng dẫn FE: đăng ký từ Tháng 11/2026

Áp dụng từ kỳ đăng ký **T11/2026**. API đã deploy sẵn (23/10/2026), FE chỉ cần sửa giao diện + payload.
Tài liệu đầy đủ: [`tracking_chi_phi_tp_medigo_dang_ky.md`](tracking_chi_phi_tp_medigo_dang_ky.md) mục 4.5.

## 0. Yêu cầu từ business

Đề xuất của phòng kinh doanh cho phần cài đặt tư vấn từ tháng 11:

1. **MỚI**: khách hàng chưa từng tham gia.
2. **NGƯNG THAM GIA**: số lượt tự động về 0. Dù lượt về 0 vẫn phải ghi nhận là NT đã từng được cài đặt, để sau này kế toán cần thì có dữ liệu.
3. **GIA HẠN**: tiếp tục tham gia nhưng không phân bổ thêm.
4. **PHÂN BỔ THÊM**: số lượt còn lại của tháng 10 + số PB thêm tháng 11.

Trên màn hình:
- CRM thấy được **số còn lại của tháng trước** = lượt tháng trước − đã dùng tháng trước.
- CRM điền **số PB thêm** cho tháng mới.
- Có thêm cột **Tổng lượt**:
  - Mới: Tổng lượt = PB thêm.
  - NT tháng trước: Tổng lượt = Còn lại + PB thêm (PB thêm = 0 thì Tổng lượt = Còn lại, tức Gia hạn).
  - Ngưng: Tổng lượt = 0.
- Chỉ được PB thêm khi **tỷ lệ thực hiện / PB của tháng trước ≥ 50%**. Thấp hơn thì không cho phân bổ thêm.

**Ví dụ:** đăng ký T11 cho 4 nhà thuốc.

| NT | T10: lượt | T10: đã dùng | % dùng T10 | Còn lại | CRM thao tác | PB thêm (CRM nhập) | **Tổng lượt T11** | Trạng thái (FE tự suy ra) |
|---|---|---|---|---|---|---|---|---|
| A | – | – | – | – | Bấm **+ Thêm mới** | 20 | **20** | Mới |
| B | 20 | 5 | 25% | 15 | Không làm gì | 0 (khóa vì < 50%) | **15** | Gia hạn |
| C | 30 | 18 | 60% | 12 | Nhập PB thêm | 10 | **22** | Phân bổ thêm |
| D | 20 | 2 | 10% | 18 | Bấm **Ngưng** | 0 | **0** (vẫn lưu dòng) | Ngưng tham gia |

NT B (25%) và D (10%) dưới 50% nên ô PB thêm bị khóa. Nếu C để PB thêm = 0 thì C thành Gia hạn.

## 1. Điểm mới

Lượt chưa dùng của tháng trước được **chuyển sang** tháng mới.

CRM chỉ có **2 nút**: **+ Thêm mới** và **Ngưng**. Ngoài ra CRM chỉ nhập số **PB thêm**. Trạng thái do FE tự suy ra:

| CRM thao tác | Còn lại | PB thêm | Tổng lượt | → `trang_thai_nt` gửi BE |
|---|---|---|---|---|
| Bấm **+ Thêm mới** | – | CRM nhập (> 0) | = PB thêm | `New` |
| Không bấm gì, PB thêm = 0 | tự tính | 0 | = Còn lại | `Renew` (Gia hạn) |
| Không bấm gì, PB thêm > 0 | tự tính | CRM nhập | = Còn lại + PB thêm | `Add` (Phân bổ thêm) |
| Bấm **Ngưng** | tự tính | 0 (khóa ô) | = 0 | `Stop` |

- Ô **PB thêm** của NT tháng trước chỉ mở khi `phan_tram_used >= 50`. Dưới 50 thì khóa ô = 0, NT tự thành Gia hạn (gợi ý tooltip: "Tỷ lệ dùng tháng trước < 50%, không được phân bổ thêm").
- Bấm **Ngưng** lần nữa (bỏ ngưng) thì NT quay lại Gia hạn / Phân bổ thêm theo số PB thêm.
- Mặc định khi mở form: PB thêm = 0 → Gia hạn.

## 2. Lấy số tháng trước để hiển thị

API cũ `get_tracking_chi_phi_tp_medigo_danh_sach` đã trả sẵn số của tháng trước trên từng dòng NT. FE không cần gọi API mới.

Ví dụ dòng của NT C (trong bảng ví dụ ở mục 0) khi CRM mở form đăng ký T11:

```json
{
  "custid": "C",
  "so_luot_dang_ky_thang_cu": 30,    // T10 có 30 lượt
  "so_luot_su_dung_thang_cu": 18,    // T10 đã dùng 18 lượt
  "phan_tram_used": 60,              // T10 dùng 60%
  "so_luot_pb_them": 0               // số PB thêm đã lưu (lần đầu = 0)
}
```

Từ dòng này FE tính 3 thứ:

| Hiển thị | Cách tính | NT C |
|---|---|---|
| Còn lại | `so_luot_dang_ky_thang_cu − so_luot_su_dung_thang_cu` | 30 − 18 = **12** |
| Mở ô PB thêm? | `phan_tram_used >= 50` | 60 ≥ 50 → **mở** |
| Tổng lượt | theo bảng mục 1 | CRM nhập PB thêm 10 → 12 + 10 = **22** (Phân bổ thêm) |

NT đã Ngưng ở tháng trước sẽ không có trong danh sách tháng mới.

## 3. Chốt danh sách – `POST insert_tracking_chi_phi_tp_medigo_chot_danh_sach`

Giữ payload cũ, thêm `so_luot_pb_them`; `so_luot_dang_ky` = **Tổng lượt** FE đã tính. BE lưu đúng số FE gửi.

```json
[{
  "thang": "2026-11-01",
  "manv": "MR0738",
  "data": [
    { "custid": "A", "trang_thai_nt": "New",   "so_luot_pb_them": 20, "so_luot_dang_ky": 20, "...": "các field cũ" },
    { "custid": "B", "trang_thai_nt": "Renew", "so_luot_pb_them": 0,  "so_luot_dang_ky": 15 },
    { "custid": "C", "trang_thai_nt": "Add",   "so_luot_pb_them": 10, "so_luot_dang_ky": 22 },
    { "custid": "D", "trang_thai_nt": "Stop",  "so_luot_pb_them": 0,  "so_luot_dang_ky": 0 }
  ]
}]
```

Validation phía FE trước khi post:
- `New`: `so_luot_pb_them > 0`.
- `trang_thai_nt` suy ra đúng bảng mục 1: không Ngưng, không Mới → `so_luot_pb_them > 0` là `Add`, `= 0` là `Renew`.
- `Stop`: vẫn gửi dòng lên (không xóa) để lưu lịch sử, `so_luot_dang_ky = 0`.
- Các field bắt buộc cũ (SĐT, thời gian mở cửa, đại diện NT...) giữ nguyên.

## 4. Màn duyệt (MR0485)

API trả thêm `so_luot_pb_them`, `approved_at`, `approved_by`, `rejected_at`. Có thể hiển thị cột Còn lại / PB thêm / Tổng lượt giống màn CRM để anh Viển dễ duyệt.
