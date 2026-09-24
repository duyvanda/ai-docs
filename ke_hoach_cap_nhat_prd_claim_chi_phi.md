# Kế Hoạch & TODO List Cập Nhật PRD Hệ Thống Claim Chi Phí
## Đặc Tả Kỹ Thuật & Danh Sách Công Việc Triển Khai Cho Backend và Frontend

> **Tài liệu tham chiếu:**
> - PRD hệ thống: [prd_form_claim_chi_phi.md](file:///D:/ai-docs/prd/prd_form_claim_chi_phi.md)
> - Database: PostgreSQL (`postgres@101.99.42.30:5432` / local server)
> - Backend: Python Django REST Framework Gateway (`D:\django_apps\rest\backend`)
> - Frontend Web: React, Bootstrap 5 (`D:\django_apps\rest\frontend1`)
> - Frontend Mobile App: Expo, React Native (`D:\django_apps\rest\fontendapp`)

---

## I. Nguyên Tắc Nghiệp Vụ Cốt Lõi (Core Business Rules)

1. **Chuỗi trạng thái vòng đời phiếu**:
   $$\mathbf{H} \xrightarrow{\text{QL gánh CP duyệt KH}} \mathbf{C} \xrightarrow{\text{Gắn HĐ}} \mathbf{I} \xrightarrow{\text{QL gánh CP duyệt HĐ}} \mathbf{D} \xrightarrow{\text{KT duyệt chi}} \mathbf{DKT}$$
   - `H` (Tạo mới) $\rightarrow$ `C` (QL gánh CP duyệt KH - L1) $\rightarrow$ `I` (Đã gắn HĐ Misa & bill) $\rightarrow$ `D` (QL gánh CP duyệt HĐ - L2) $\rightarrow$ `DKT` (Kế toán duyệt chi hoàn tất 100%).
   - `RKT` (Kế toán từ chối chi): **Phiếu bị hủy vĩnh viễn**, hệ thống tự động xóa HĐ (`DELETE` khỏi `form_claim_chi_phi_hoa_don`) để nhả HĐ tự do. Nhân viên không thể sửa trên phiếu này (phải tạo lại đề xuất mới từ đầu).
   - `R` (QL từ chối L1); `E` (QL từ chối L2 - tự động nhả HĐ để nhân viên gắn lại).

2. **Người gánh chi phí (`manv_quan_ly_chi_phi`) duyệt xuyên suốt cả 2 lần**:
   - Khi nhân viên đi thực hiện hoạt động nhưng tính vào ngân sách cấp trên: Chọn cấp Quản lý gánh chi phí (CRM / ASM / NCRM). **Chính Quản lý đó sẽ trực tiếp duyệt cả Lần 1 (`H -> C`) lẫn Lần 2 (`I -> D`)**.

3. **Quy tắc ngoại lệ "Tự làm - Tự duyệt"**:
   - Toàn hệ thống **chỉ đúng 03 nhân sự cấp cao** được quyền tự duyệt cho chính mình: `MR1137` (Vũ Mừng), `MR0485` (Nguyễn Hoàng Viển), `MR2685` (Lê Thị Hương Sa). Toàn bộ nhân sự khác không được tự duyệt.

4. **Quyền hạn Kế toán viên khi duyệt chi (`status = 'D'`)**:
   - **Sửa số tiền claim**: Cho phép sửa trực tiếp `so_tien_claim` trên từng HĐ ($0 < \text{so\_tien\_claim} \le \text{tong\_tien\_hoa\_don}$). Hệ thống tự động tính lại tổng tiền claim của cả phiếu.
   - **Loại bỏ HĐ**: `DELETE` trực tiếp dòng HĐ khỏi bảng `form_claim_chi_phi_hoa_don` (nhả HĐ tự do).

5. **Tách dòng thuế HĐ Misa & Logic `rn_max = 1`**:
   - Một HĐ có nhiều mức thuế suất (0%, 5%, 8%, 10%...) được tự động tách dòng theo từng mức thuế.
   - Khi có giảm trừ (`so_tien_claim < tong_tien_hoa_don`), khoản giảm trừ $\Delta = \text{tong\_tien\_hoa\_don} - \text{so\_tien\_claim}$ **chỉ trừ duy nhất vào dòng nhóm thuế có số tiền lớn nhất (`rn_max = 1`)**, các dòng khác giữ nguyên giá trị gốc từ Misa (tránh lệch tiền lẻ do chia tỷ lệ).
   - **Công thức dòng `rn_max = 1`**:
     - $\text{tong\_tien} = \text{tong\_tien\_goc} - \Delta$
     - $\text{so\_tien\_truoc\_thue} = \text{round}(\text{tong\_tien} / (1 + \text{thue\_suat} / 100))$
     - $\text{tien\_thue} = \text{tong\_tien} - \text{so\_tien\_truoc\_thue}$
   - **Ví dụ số học minh họa**: HĐ gốc 2.100.000 đ gồm dòng 8% (1.500.000 đ, `rn_max=1`) và 10% (600.000 đ, `rn_max=2`). Kế toán duyệt 1.900.000 đ ($\Delta = 200.000 \text{ đ}$):
     - **Dòng 8% (`rn_max=1`)**: $\text{tong\_tien} = 1.500.000 - 200.000 = \mathbf{1.300.000 \text{ đ}}$ (tiền trước thuế: $1.203.704 \text{ đ}$, tiền thuế: $96.296 \text{ đ}$).
     - **Dòng 10% (`rn_max=2`)**: Giữ nguyên gốc $\mathbf{600.000 \text{ đ}}$ (tiền trước thuế: $545.455 \text{ đ}$, tiền thuế: $54.545 \text{ đ}$).
     - $\rightarrow$ Tổng tiền sau điều chỉnh: $1.300.000 + 600.000 = \mathbf{1.900.000 \text{ đ}}$ (khớp chính xác 100% với `so_tien_claim`).

---

## II. PHẦN 1: TODO LIST KỸ THUẬT - BACKEND (BE)

### 1. Cơ Sở Dữ Liệu & DDL (Database Schema)

- [ ] **BE-1.1. Bổ sung cột cho bảng `form_claim_chi_phi`**
  - Chạy lệnh DDL trên PostgreSQL:
    ```sql
    ALTER TABLE form_claim_chi_phi 
    ADD COLUMN IF NOT EXISTS manv_quan_ly_chi_phi TEXT, -- Mã Quản lý chịu chi phí (CRM / ASM / NCRM)
    ADD COLUMN IF NOT EXISTS kt_approved_manv TEXT,     -- Mã Kế toán viên duyệt chi
    ADD COLUMN IF NOT EXISTS kt_approved_at TIMESTAMP,  -- Thời điểm Kế toán duyệt chi
    ADD COLUMN IF NOT EXISTS kt_note TEXT;              -- Ghi chú của Kế toán
    ```
  - Cập nhật định nghĩa giá trị trạng thái mới trong comment table: `H`, `C`, `I`, `D`, `DKT`, `RKT`, `R`, `E`.

- [ ] **BE-1.2. Xác nhận cơ chế bảng `form_claim_chi_phi_hoa_don`**
  - Giữ nguyên 100% cấu trúc hiện tại (không thêm cột `is_rejected_by_kt` hay `reject_reason`).
  - Khi HĐ bị loại bỏ hoặc phiếu bị từ chối (`RKT`), thực hiện `DELETE` trực tiếp dòng HĐ khỏi `form_claim_chi_phi_hoa_don` để giải phóng HĐ tự do.

- [ ] **BE-1.3. Cập nhật DDL View `view_form_claim_chi_phi_ge_bang_ke` chuẩn 42 cột**
  - Tái tạo cấu trúc View đủ 42 cột theo đặc tả đã đối soát.
  - Bổ sung 05 cột thông tin mới:
    1. `mau_so`: Mẫu số hóa đơn Misa lấy từ `max(d.mau_so)` trong `d_misa_invoice_item_details` (giá trị `"1"` hoặc `"2"`).
    2. `seri`: Ký hiệu mẫu hóa đơn (Seri) lấy từ `max(d.ky_hieu)` trong `d_misa_invoice_item_details`.
    3. `thue_suat`: Mức thuế suất GTGT dòng hàng sau khi tách dòng (0, 5, 8, 10...).
    4. `hinh_thuc_thanh_toan`: Phân loại dựa trên `cl.check_tm` (`1` $\rightarrow$ `'Tiền mặt'`, `0` $\rightarrow$ `'Chuyển khoản'`).
    5. `ten_ke_toan_phu_trach`: Tên Kế toán viên phụ trách hồ sơ (lấy từ bảng `form_claim_chi_phi_email_kt`).
  - **Logic tính toán tách dòng và trừ chênh lệch (`rn_max = 1`)**:
    - Nhóm dữ liệu từ `d_misa_invoice_item_details` theo `(id_duy_nhat_cua_hoa_don, thue_suat)` và xếp thứ tự:
      `row_number() OVER (PARTITION BY id_duy_nhat_cua_hoa_don ORDER BY sum(tong_tien_thanh_toan) DESC, thue_suat DESC) AS rn_max`
    - Khi có giảm trừ chi phí (`cl.so_tien_claim < m.tong_tien_hoa_don`):
      - **Dòng `rn_max = 1` (Dòng có tiền lớn nhất)**:
        - `tong_tien = tong_tien_nhom_goc - (m.tong_tien_hoa_don - cl.so_tien_claim)`
        - `so_tien_truoc_thue = CASE WHEN thue_suat > 0 THEN round((tong_tien / (1.0 + thue_suat / 100.0))::numeric, 0) ELSE tong_tien END`
        - `tien_thue = tong_tien - so_tien_truoc_thue`
      - **Dòng `rn_max > 1` (Các dòng thuế còn lại)**:
        - Giữ nguyên 100% giá trị gốc từ Misa (`tong_tien = tong_tien_nhom_goc`, `so_tien_truoc_thue = so_tien_truoc_thue_goc`, `tien_thue = tien_thue_goc`).
    - Tham chiếu chi tiết bảng số liệu mẫu tại [Mục I.5](#quy-tắc-tách-dòng-thuế-hđ-misa--điều-chỉnh-số-tiền-logic-rn_max--1).
  - Điều kiện lọc:
    ```sql
    WHERE a.status = 'DKT' -- Chỉ lấy phiếu Kế toán đã chốt duyệt chi hoàn tất
    ```

---

### 2. Cập Nhật Các Stored Functions & Endpoints Hiện Hữu

- [ ] **BE-2.1. Cập nhật Stored Function `get_form_claim_chi_phi`**
  - **Method**: GET
  - **URL Gateway**: `/get_data/get_form_claim_chi_phi/?manv=MR1714`
  - **JSON Input (Query Params / url_param)**:
    ```json
    {
      "manv": "MR1714"
    }
    ```
  - **Logic xử lý cây quản lý**:
    - Lấy thông tin user `p_manv` từ bảng `d_users`.
    - Tạo mảng `lst_quan_ly_chi_phi` theo cấp bậc người gọi:
      - **Nhân viên (TDV/CRS)**: Trả về 3 options: `CRM` (`u.supid`, mặc định `mac_dinh: true`), `ASM` (`u.asm`), `NCRM` (`u.rsmid`).
      - **Quản lý trực tiếp (CRM)**: Trả về 2 options: `ASM` (`u.asm`, mặc định `mac_dinh: true`), `NCRM` (`u.rsmid`).
      - **Quản lý khu vực (ASM)**: Trả về 1 option: `NCRM` (`u.rsmid`, mặc định `mac_dinh: true`).
      - **Trưởng bộ phận bán hàng (NCRM)**: Trả về mảng rỗng `[]`.
  - **JSON Output (Key bổ sung mới trong Response JSON)**:
    ```json
    {
      "lst_quan_ly_chi_phi": [
        {
          "cap_quan_ly": "CRM",
          "ten_cap_quan_ly": "Quản lý trực tiếp (CRM)",
          "manv": "MR0253",
          "ho_ten": "Nguyễn Thị Dung",
          "mac_dinh": true
        },
        {
          "cap_quan_ly": "ASM",
          "ten_cap_quan_ly": "Quản lý khu vực (ASM)",
          "manv": "MR1650",
          "ho_ten": "Hoàng Trung Thành",
          "mac_dinh": false
        },
        {
          "cap_quan_ly": "NCRM",
          "ten_cap_quan_ly": "Trưởng bộ phận bán hàng toàn quốc (NCRM)",
          "manv": "MR1137",
          "ho_ten": "Vũ Mừng",
          "mac_dinh": false
        }
      ]
    }
    ```

- [ ] **BE-2.2. Cập nhật Stored Function `insert_form_claim_chi_phi`**
  - Nhận tham số mới `"manv_quan_ly_chi_phi"` từ payload.
  - Kiểm tra hạn mức ngân sách (Budget threshold check) theo định mức ngân sách của chính Quản lý được chọn gánh chi phí (`manv_quan_ly_chi_phi`).
  - Ghi giá trị `manv_quan_ly_chi_phi` vào bảng `form_claim_chi_phi`.
  - Lưu trạng thái khởi tạo `status = 'H'`.

- [ ] **BE-2.3. Cập nhật Stored Function `get_form_claim_chi_phi_crm` (QL Duyệt Lần 1 - Kế hoạch)**
  - Cập nhật mệnh đề WHERE lọc danh sách phiếu `status = 'H'` cho người duyệt (`p_manv`):
    ```sql
    WHERE a.status = 'H'
      AND (
        -- TH1: 03 nhân sự ngoại lệ tự duyệt cho chính mình
        (p_manv IN ('MR1137', 'MR0485', 'MR2685') AND a.manv = p_manv)
        -- TH2: Quản lý được chọn gánh chi phí duyệt đề xuất
        OR (a.manv_quan_ly_chi_phi = p_manv AND a.manv <> p_manv)
      )
    ```

- [ ] **BE-2.4. Cập nhật Stored Function `get_form_claim_chi_phi_crm_claimed` (QL Duyệt Lần 2 - Hóa đơn)**
  - Đồng bộ người duyệt nghiệm thu Lần 2 theo nguyên tắc người gánh chi phí duyệt:
    ```sql
    WHERE a.status = 'I'
      AND (
        -- TH1: 03 nhân sự ngoại lệ tự duyệt cho chính mình
        (p_manv IN ('MR1137', 'MR0485', 'MR2685') AND a.manv = p_manv)
        -- TH2: Quản lý được chọn gánh chi phí duyệt nghiệm thu hóa đơn
        OR (a.manv_quan_ly_chi_phi = p_manv AND a.manv <> p_manv)
      )
    ```

- [ ] **BE-2.5. Kiểm tra Function `insert_form_claim_chi_phi_crm_claimed`**
  - Duyệt ghi nhận `status = 'D'`.
  - Từ chối ghi nhận `status = 'E'` và xóa HĐ khỏi `form_claim_chi_phi_hoa_don` để giải phóng HĐ cho nhân viên gắn lại.

- [ ] **BE-2.6. Cập nhật Stored Function `get_form_claim_chi_phi_excel_form`: Ưu tiên tiền vé xe từ Invoice**
  - **Mục tiêu**: Khi sinh dữ liệu chi tiết công tác phí biểu mẫu `BMKT005-DNTTCTP`, nếu nhân viên đã gắn hóa đơn vé xe (`cost_type = 'transport'` trong bảng `form_claim_chi_phi_hoa_don`), hệ thống phải **ưu tiên lấy tổng số tiền claim thực tế từ hóa đơn** thay vì chỉ lấy số tiền đề xuất dự kiến ban đầu trong bảng `form_cong_tac_phi`.
  - **Logic xử lý chi tiết**:
    - Truy vấn bảng `form_claim_chi_phi_hoa_don` theo `khid = cp.khid` và `cost_type = 'transport'`.
    - Tính số tiền vé xe:
      ```sql
      COALESCE(
          NULLIF((SELECT SUM(so_tien_claim) FROM public.form_claim_chi_phi_hoa_don WHERE khid = cp.khid AND cost_type = 'transport'), 0),
          COALESCE(cp.ve_xe_cong_tac, 0) + COALESCE(cp.tong_tien_ve_xe, 0)
      ) AS ve_xe
      ```
    - Đồng bộ tính lại tổng tiền công tác phí trên toàn bộ biểu mẫu `BMKT005-DNTTCTP` và giấy đề nghị thanh toán `BMKT002-DNTT` khi trình ký.

---

### 3. Xây Dựng 02 Stored Functions & Endpoints Mới Cho Kế Toán

- [ ] **BE-3.1. Viết Function & Endpoint GET `get_form_claim_chi_phi_kt_review`**
  - **Method**: GET
  - **URL Gateway**: `/get_data/get_form_claim_chi_phi_kt_review/?manv_kt=MR0349&ky_chi_phi=2026-08-01`
  - **Query Params (Chi tiết tham số)**:
    - `manv_kt` (Bắt buộc, `TEXT`): Mã nhân viên KT đăng nhập (lọc các phiếu thuộc Quản lý do KT này phụ trách dựa vào `form_claim_chi_phi_email_kt`).
    - `ky_chi_phi` (Tùy chọn, `TEXT`): Kỳ chi phí (`YYYY-MM-DD`). Nếu rỗng/null thì lấy tất cả kỳ.
  - **JSON Input (Query Params / url_param)**:
    ```json
    {
      "manv_kt": "MR0349",
      "ky_chi_phi": "2026-08-01"
    }
    ```
  - **Logic xử lý**:
    - Lọc các phiếu có `status = 'D'` thuộc các Quản lý do Kế toán viên này phụ trách.
    - Gom thông tin hóa đơn lồng trong mảng `lst_hoa_don`.
  - **JSON Output (Response JSON)**:
    ```json
    {
      "status": "ok",
      "thong_tin_ke_toan": {
        "manv_kt": "MR0349",
        "ten_kt": "NGUYEN THI DOAN THUY",
        "email_kt": "thuyntd@meraplion.com"
      },
      "tong_so_phieu": 2,
      "tong_tien_cho_duyet": 3450000.0,
      "lst_cho_duyet": [
        {
          "id": "CCP20260919102850842",
          "status": "D",
          "ky_chi_phi": "2026-08-01",
          "thang_chi_phi": "2026-08-01",
          "manv": "MR1714",
          "tencvbh": "Nguyễn Thị Kim Yến",
          "phongdeptsummary": "HCP",
          "kenh": "HCP",
          "ma_kh": "000214",
          "ten_kh": "BV QUẬN TÂN PHÚ - SG",
          "ma_hcp": "HCP00021426-H",
          "ten_hcp": "BS. Nguyễn Văn A",
          "qua_tang": "Giao tiếp - Mời cơm",
          "noi_dung": "Chi phí giao tiếp đánh giá về hiệu quả của thuốc",
          "ghi_chu": "Tiếp khách ngày 15/08 tại nhà hàng Vựa Cua Đăng Quân",
          "manv_quan_ly_chi_phi": "MR0253",
          "ten_quan_ly_chi_phi": "Nguyễn Thị Dung",
          "cap_quan_ly_chi_phi": "CRM",
          "so_ke_hoach": 2000000.0,
          "approved_so_ke_hoach": 2000000.0,
          "so_tien_claim_hoa_don": 1950000.0,
          "hinh_thuc_thanh_toan": "Chuyển khoản",
          "zip_file_url": "https://bi.meraplion.com/dms/claim_files/CCP20260919102850842.zip",
          "claim_approved_at": "2026-09-20T14:30:00",
          "lst_hoa_don": [
            {
              "id_duy_nhat_cua_hoa_don": "01a003dd038470d0ba32ce239630ed25",
              "mau_so": "1",
              "seri": "C26TYY",
              "so_hoa_don": "00018827",
              "ngay_hoa_don": "2026-08-15",
              "ten_nha_cung_cap": "CÔNG TY TNHH THƯƠNG MẠI ẨM THỰC VỰA CUA ĐĂNG QUÂN",
              "mst_ncc": "1801796441",
              "noi_dung_chi_tiet_hd": "Dịch vụ ăn uống tiếp khách",
              "tong_tien_hoa_don": 2100000.0,
              "so_tien_claim": 1950000.0,
              "thue_suat": 8.0,
              "so_tien_truoc_thue": 1805556.0,
              "tien_thue": 144444.0,
              "file_url": "https://bi.meraplion.com/dms/invoices/01a003dd038470d0ba32ce239630ed25.pdf"
            }
          ]
        }
      ]
    }
    ```

- [ ] **BE-3.2. Viết Function & Endpoint POST `insert_form_claim_chi_phi_kt_claimed`**
  - **Method**: POST
  - **URL Gateway**: `/post_data/insert_form_claim_chi_phi_kt_claimed/`
  - **JSON Input (Request Body Payload - JSON Array)**:
    ```json
    [
      {
        "id": "CCP20260919102850842",
        "manv": "MR0349",
        "status": "DKT",
        "ghi_chu": "Đã kiểm tra hóa đơn và chứng từ, duyệt chi thanh toán",
        "inserted_at": "2026-09-22 10:30:00",
        "lst_hoa_don": [
          {
            "id_duy_nhat_cua_hoa_don": "01a003dd038470d0ba32ce239630ed25",
            "loai_bo": false,
            "ly_do_loai_bo": "",
            "so_tien_claim": 1900000.0 // Số tiền claim thực tế sau điều chỉnh
          },
          {
            "id_duy_nhat_cua_hoa_don": "019ea5bb498f71379cb0c8e7d8875221",
            "loai_bo": true,
            "ly_do_loai_bo": "Hóa đơn thiếu thông tin MST người mua",
            "so_tien_claim": 0.0
          }
        ]
      },
      {
        "id": "CCP20260919102850843",
        "manv": "MR0349",
        "status": "RKT",
        "ghi_chu": "Chứng từ thanh toán không khớp với hóa đơn",
        "inserted_at": "2026-09-22 10:30:00",
        "lst_hoa_don": []
      }
    ]
    ```
    *(Ghi chú: Nếu duyệt nhanh trên bảng danh sách mà không sửa hóa đơn, trường `lst_hoa_don` có thể gửi rỗng `[]` hoặc `null`)*.
  - **Logic xử lý trong Stored Function**:
    1. Parse JSON input thành bảng tạm `kt_result`.
    2. **Xử lý Từ chối (`status = 'RKT'`)**:
       - `DELETE` toàn bộ hóa đơn của phiếu trong `form_claim_chi_phi_hoa_don` (nhả HĐ tự do).
       - Phiếu đóng vĩnh viễn, không thể thao tác lại.
    3. **Xử lý Duyệt chi (`status = 'DKT'`)**:
       - Nếu hóa đơn có `loai_bo = true`: `DELETE` dòng HĐ khỏi `form_claim_chi_phi_hoa_don`.
       - Nếu hóa đơn có `loai_bo = false`: `UPDATE form_claim_chi_phi_hoa_don SET so_tien_claim = item.so_tien_claim`.
       - Tính lại tổng tiền claim của phiếu:
         `UPDATE form_claim_chi_phi SET so_tien_claim_hoa_don = (SELECT COALESCE(SUM(so_tien_claim), 0) FROM form_claim_chi_phi_hoa_don WHERE khid = b.id) WHERE id = b.id`.
    4. **Cập nhật bảng chính `form_claim_chi_phi`**:
       ```sql
       UPDATE form_claim_chi_phi p
       SET
           status = b.status,
           kt_approved_manv = b.manv,
           kt_approved_at = b.inserted_at,
           kt_note = b.ghi_chu
       FROM kt_result b
       WHERE p.id = b.id;
       ```
  - **JSON Output (Response JSON)**:
    - **Trường hợp thành công (Success Response - HTTP 200)**:
      ```json
      {
        "status": "ok",
        "data": [
          {
            "id": "CCP20260919102850842",
            "status": "DKT",
            "manv": "MR0349",
            "ghi_chu": "Đã kiểm tra hóa đơn và chứng từ, duyệt chi thanh toán",
            "inserted_at": "2026-09-22 10:30:00"
          },
          {
            "id": "CCP20260919102850843",
            "status": "RKT",
            "manv": "MR0349",
            "ghi_chu": "Chứng từ thanh toán không khớp với hóa đơn",
            "inserted_at": "2026-09-22 10:30:00"
          }
        ],
        "success_message": "Đã nhận thành công"
      }
      ```
    - **Trường hợp lỗi / Thất bại (Error Response)**:
      ```json
      {
        "status": "fail",
        "error_message": "Không tìm thấy mã phiếu hoặc lỗi kết nối cơ sở dữ liệu"
      }
      ```

---

### 4. Migration Dữ Liệu & Kiểm Thử Backend

- [ ] **BE-4.1. Chạy Script Migration dữ liệu lịch sử**
  - Chuyển các phiếu đã duyệt trước đây sang trạng thái hoàn tất Kế toán:
    ```sql
    UPDATE form_claim_chi_phi 
    SET status = 'DKT' 
    WHERE status = 'D';
    ```

- [ ] **BE-4.2. Kiểm thử Unit Test các Function PostgreSQL**
  - Test `get_form_claim_chi_phi`: Thử các role TDV, CRM, ASM, NCRM xem mảng `lst_quan_ly_chi_phi`.
  - Test `insert_form_claim_chi_phi`: Lưu đúng `manv_quan_ly_chi_phi` và kiểm tra chặn khi vượt ngân sách.
  - Test lọc `get_form_claim_chi_phi_crm` (L1) và `get_form_claim_chi_phi_crm_claimed` (L2): Chỉ người gánh CP thấy phiếu.
  - Test 3 nhân sự đặc quyền (`MR1137`, `MR0485`, `MR2685`): Tự lập tự thấy phiếu.
  - Test `get_form_claim_chi_phi_kt_review`: Lấy đúng phiếu thuộc Quản lý do KT phụ trách.
  - Test `insert_form_claim_chi_phi_kt_claimed`:
    - Duyệt `DKT` có giảm tiền HĐ và tính lại tổng tiền.
    - Duyệt `DKT` có loại bỏ 1 HĐ (HĐ bị xóa, tổng tiền giảm).
    - Từ chối `RKT` (xóa sạch HĐ, trạng thái sang `RKT`).
  - Test View `view_form_claim_chi_phi_ge_bang_ke`: Đủ 42 cột, đúng mẫu số, seri, thuế suất, hình thức thanh toán.

---

## III. PHẦN 2: TODO LIST KỸ THUẬT - FRONTEND (FE)

### 1. Phân Hệ Tạo Kế Hoạch Chi Phí (`FE Web` & `FE App`)

- [ ] **FE-1.1. Tích hợp API đọc danh sách Quản lý chịu chi phí**
  - Trong API `get_form_claim_chi_phi`, đọc trường `lst_quan_ly_chi_phi`.
  - Lưu trữ vào state để binding lên giao diện.

- [ ] **FE-1.2. Bổ sung UI Component "Đối tượng ghi nhận chi phí"**
  - **Vị trí**: Đặt trong Form Đăng ký Plan (cùng khối Kỳ chi phí, Loại quà tặng/Mời cơm).
  - **Component UI**: Sử dụng `Radio Group` hoặc `Select Dropdown`.
  - **Label hiển thị**: Kết hợp cấp bậc và họ tên (Ví dụ: `Quản lý trực tiếp (CRM) - Nguyễn Thị Dung`, `Quản lý khu vực (ASM) - Hoàng Trung Thành`).
  - **Giá trị mặc định**: Tự động chọn item có `mac_dinh = true` (thường là Quản lý trực tiếp CRM).
  - **Ẩn component**: Nếu `lst_quan_ly_chi_phi` rỗng `[]` (NCRM tự lập), tự động ẩn field.

- [ ] **FE-1.3. Gửi `manv_quan_ly_chi_phi` khi Submit Form**
  - Đưa trường `manv_quan_ly_chi_phi` vào payload POST gửi lên API `insert_form_claim_chi_phi`.

---

### 2. Phân Hệ Quản Lý Phê Duyệt Kế Hoạch & Hóa Đơn (`FE Web` & `FE App`)

- [ ] **FE-2.1. Phân quyền và khóa nút "Tự duyệt"**
  - Tại 2 màn hình **Duyệt Đề Xuất (Lần 1)** và **Duyệt Hóa Đơn (Lần 2)**:
  - Nếu `item.manv === currentUser.manv` (user tự lập phiếu):
    - **Ngoại lệ 03 nhân sự**: Nếu user là `MR1137`, `MR0485` hoặc `MR2685` $\rightarrow$ Cho phép bấm duyệt bình thường.
    - **Các trường hợp còn lại**: Ẩn/Disable nút Duyệt (`CONFIRM`), chỉ cho phép Xem hoặc Từ chối.

- [ ] **FE-2.2. Bổ sung Badge nhận diện "Phiếu phân bổ chi phí"**
  - Nếu `item.manv_quan_ly_chi_phi === currentUser.manv` và `item.manv !== currentUser.manv`:
  - Hiển thị nhãn Badge trực quan trên dòng phiếu:
    `<Badge bg="info">Phiếu phân bổ chi phí cho bạn</Badge>` (trên Web) hoặc thẻ Tag xanh (trên App) để người duyệt biết lý do phiếu xuất hiện ở danh sách của mình.

---

### 3. Phân Hệ MỚI: Màn Hình Kế Toán Duyệt Chi (`FE Web`)

- [ ] **FE-3.1. Cấu hình Menu & Route mới**
  - Tạo route mới: `/formcontrol/form_claim_chi_phi_kt_review`
  - Thêm menu sidebar **"Kế toán Duyệt chi"** kèm icon thích hợp.
  - Phân quyền chỉ hiển thị và cho phép truy cập với role Kế toán viên.

- [ ] **FE-3.2. Xây dựng Thanh Lọc Dữ Liệu (Filter Bar)**
  - Bộ lọc gồm:
    - **Kỳ chi phí**: Month/Year Picker (mặc định tháng hiện tại hoặc "Tất cả").
    - **Tìm kiếm nhanh**: Ô input search theo mã phiếu, mã NV, tên NV, tên HCP/Khách hàng.
  - Gọi API `get_form_claim_chi_phi_kt_review` khi thay đổi filter.

- [ ] **FE-3.3. Bảng Dữ Liệu Các Phiếu Chờ Duyệt Chi (`status = 'D'`)**
  - Hiển thị bảng tổng hợp:
    - Checkbox chọn nhiều phiếu để duyệt hàng loạt.
    - Cột: Mã phiếu, Kỳ CP, Nhân viên đề xuất, Khách hàng / Bác sĩ (HCP), Nội dung, Người gánh chi phí (`manv_quan_ly_chi_phi`), Số tiền kế hoạch duyệt, Tổng tiền claim HĐ, Hình thức thanh toán.
    - Nút thao tác: `[Xem chi tiết]` / `[Duyệt]`.
  - Thanh Bar tổng hợp: Hiển thị `Tổng số phiếu chờ duyệt` và `Tổng số tiền claim chờ duyệt` (format tiền tệ VNĐ).

- [ ] **FE-3.4. Drawer / Modal Chi Tiết Phê Duyệt Hồ Sơ**
  - **Khối 1: Thông tin chung của phiếu**:
    - Hiển thị chi tiết nội dung, ghi chú tiếp khách, người gánh CP, link tải file tổng hợp ZIP chứng từ (`zip_file_url`).
  - **Khối 2: Bảng chi tiết từng hóa đơn đỏ (`lst_hoa_don`)**:
    - Hiển thị: Mẫu số ("1" hoặc "2"), Ký hiệu (Seri), Số HĐ, Ngày HĐ, Tên NCC, MST, Thuế suất, Tiền trước thuế, Tiền thuế, Tổng tiền HĐ gốc.
    - Link xem file hóa đơn PDF gốc & link xem ảnh chứng từ thanh toán/chuyển khoản.
    - **Cột "Số tiền duyệt chi" (Editable Input)**:
      - Cho phép Kế toán viên sửa trực tiếp `so_tien_claim`.
      - Validation: $0 < \text{so\_tien\_claim} \le \text{tong\_tien\_hoa\_don}$.
      - **Realtime recalculate**: Tự động tính lại tổng tiền claim cả phiếu khi sửa tiền HĐ.
    - **Cột Thao tác trên từng HĐ**: Nút Toggle `[Hợp lệ]` / `[Loại bỏ]`.
      - Bấm `[Loại bỏ]` $\rightarrow$ Bật ô input bắt buộc nhập lý do loại bỏ. Tiền duyệt của HĐ tự set về 0.
  - **Khối 3: Ghi chú của Kế toán (`kt_note`)**:
    - Textarea cho KT nhập giải trình (bắt buộc nếu có giảm tiền hoặc loại bỏ HĐ).
  - **Khối 4: Nút hành động cuối Drawer**:
    - Nút **"Xác nhận Duyệt chi"** (Xanh) $\rightarrow$ Gọi API `insert_form_claim_chi_phi_kt_claimed` với `status: "DKT"` kèm mảng HĐ đã điều chỉnh.
    - Nút **"Từ chối hồ sơ"** (Đỏ) $\rightarrow$ Bật Modal cảnh báo:
      > ⚠️ **Cảnh báo từ chối duyệt chi**:
      > Khi từ chối, **phiếu này sẽ bị HỦY VĨNH VIỄN, nhân viên KHÔNG THỂ làm lại trên phiếu này**. Toàn bộ hóa đơn sẽ được giải phóng để nhân viên tạo đề xuất mới từ đầu. Bạn có chắc chắn muốn từ chối?
      - Yêu cầu nhập lý do từ chối $\rightarrow$ Gọi API `insert_form_claim_chi_phi_kt_claimed` với `status: "RKT"`.
  - Feedback: Toast alert thông báo thành công, đóng Drawer và reload bảng dữ liệu.

---

### 4. Phân Hệ Báo Cáo Bảng Kê GE (`FE Web`)

- [ ] **FE-4.1. Cập nhật Data Table Báo Cáo Bảng Kê GE**
  - Thêm 05 cột mới vào cấu hình bảng:
    1. **Mẫu số** (`mau_so`): Căn giữa, hiển thị "1" (GTGT) hoặc "2" (Bán hàng).
    2. **Ký hiệu mẫu (Seri)** (`seri`): Ví dụ `C26TYY`.
    3. **Thuế suất (%)** (`thue_suat`): Căn phải, ví dụ `8%`, `10%`.
    4. **Hình thức thanh toán** (`hinh_thuc_thanh_toan`): 'Tiền mặt' / 'Chuyển khoản'.
    5. **Kế toán phụ trách** (`ten_ke_toan_phu_trach`): Họ tên nhân viên kế toán.

- [ ] **FE-4.2. Cập nhật chức năng Xuất Excel (Export Excel)**
  - Cập nhật header và mapping data trong hàm xuất Excel đồng bộ đủ 42 cột.
  - Format đúng kiểu dữ liệu tiền tệ VNĐ và phần trăm thuế suất.

---

### 5. Kiểm Thử UX/UI & Liên Thông Frontend

- [ ] **FE-5.1. Test màn hình Tạo Kế hoạch**:
  - TDV thấy 3 options (mặc định CRM); CRM thấy 2 options (ASM mặc định, NCRM); ASM thấy 1 option (NCRM); NCRM không thấy dropdown.
  - Kiểm tra payload gửi lên API có `manv_quan_ly_chi_phi`.
- [ ] **FE-5.2. Test màn hình Quản lý Duyệt**:
  - Không tự duyệt được phiếu của mình (trừ 3 nhân sự đặc quyền).
  - Thấy Badge `[Phiếu phân bổ chi phí cho bạn]`.
- [ ] **FE-5.3. Test màn hình Kế toán Duyệt chi**:
  - Tải danh sách phiếu `status = 'D'`.
  - Mở Drawer xem chi tiết HĐ và chứng từ.
  - Sửa giảm tiền HĐ $\rightarrow$ Kiểm tra tổng tiền claim tự động tính lại realtime.
  - Bấm loại bỏ HĐ $\rightarrow$ Nhập lý do và kiểm tra tổng tiền giảm.
  - Duyệt chi `DKT` thành công.
  - Bấm từ chối `RKT` $\rightarrow$ Thấy cảnh báo hủy vĩnh viễn và thực hiện thành công.
- [ ] **FE-5.4. Test Bảng kê GE**:
  - Kiểm tra hiển thị đủ 5 cột mới trên bảng web và file Excel xuất ra.

---

## IV. Kế Hoạch Phối Hợp & Tiến Độ Triển Khai (Rollout Timeline)

| Giai đoạn | Thời gian | Nhiệm vụ Backend (BE) | Nhiệm vụ Frontend (FE) |
| :---: | :---: | :--- | :--- |
| **Giai đoạn 1** | **23/09 - 25/09/2026** | • Chạy DDL bổ sung 4 cột<br>• Cập nhật 4 Stored Functions hiện hữu<br>• Viết 2 API Kế toán mới (`get_review` & `kt_claimed`)<br>• Cập nhật View 42 cột & Migration `D -> DKT` | • Thiết kế UI "Đối tượng ghi nhận chi phí"<br>• Thiết kế giao diện Màn hình Kế toán Duyệt chi<br>• Thêm 5 cột vào Bảng kê GE |
| **Giai đoạn 2** | **26/09 - 27/09/2026** | • Hỗ trợ kết nối API với FE<br>• Tinh chỉnh SQL / performance truy vấn | • Tích hợp API Kế toán Duyệt chi<br>• Hoàn thiện Drawer sửa tiền & loại bỏ HĐ<br>• Kiểm thử liên thông E2E từ CRS $\rightarrow$ QL Duyệt L1 $\rightarrow$ Gắn HĐ $\rightarrow$ QL Duyệt L2 $\rightarrow$ Kế toán duyệt chi `DKT` |
| **Giai đoạn 3** | **28/09/2026** | **Nghiệm thu toàn diện & Triển khai chính thức (Go-Live Deadline)** | |
