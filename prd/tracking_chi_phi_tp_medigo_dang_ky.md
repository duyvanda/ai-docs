# Product Requirements Document (PRD)

## Module Đăng ký Tư vấn Eclinic Medigo – Kênh TP

---

## 1. Tổng quan (Overview)

Chương trình hợp tác giữa **Tập đoàn MERAP** và **MEDIGO** triển khai nền tảng tư vấn y khoa từ xa (Eclinic) đến các Nhà thuốc (NT) thuộc kênh Trình Dược (TP). Mỗi Nhà thuốc tham gia sẽ được cấp một tài khoản Eclinic cùng với một gói số lượt tư vấn bác sĩ/dược sĩ định kỳ hàng tháng để hỗ trợ chăm sóc và tư vấn cho người tiêu dùng đến mua thuốc tại NT.

Module **Đăng ký Tư vấn Eclinic Medigo** trên Portal Web Merap cho phép Quản lý trực tiếp (CRM) chủ động quản lý danh sách Nhà thuốc tham gia theo từng tháng:
* **Tự động gia hạn (Auto-renewal):** Kế thừa toàn bộ danh sách Nhà thuốc của tháng liền kề trước đó nếu CRM không can thiệp chỉnh sửa.
* **Đánh giá & Điều chỉnh (Review & Update):** CRM có thể xem xét tỷ lệ sử dụng lượt tư vấn (`% Used`) của tháng cũ kết hợp với **Doanh số tháng cũ** và **Doanh số lũy kế đầu năm (YTD)** của Nhà thuốc để đưa ra quyết định: tăng/giảm số lượt tư vấn, giữ nguyên gia hạn (`Renew`), hoặc ngưng tham gia (`Stop`).
* **Mở rộng tham gia (Add New):** CRM lựa chọn thêm các Nhà thuốc mới thuộc tuyến quản lý vào danh sách tháng mới (`New`).
* **Quy trình Phê duyệt (Approval Workflow):** CRM hoàn tất và "Chốt danh sách", chuyển cấp Quản lý (GĐBH / Admin) phê duyệt và khóa dữ liệu trước khi chuyển giao dữ liệu sang MEDIGO kích hoạt tài khoản.

Dữ liệu được tích hợp chặt chẽ với:
* **Hệ thống nhân sự (`d_users`):** Xác thực CRM, phân quyền theo chi nhánh và nhân sự cấp dưới.
* **Hệ thống Tuyến & Khách hàng (DMS - `api_f_thongtin_tuyen_mcp_tp_pcl`, `d_master_khachhang`):** Lấy danh sách Nhà thuốc hợp lệ theo tuyến phụ trách của CRM, tự động map tên NT, địa chỉ, TDV phụ trách.
* **Hệ thống Doanh số (`f_raw_data_sales_yoy`):** Lấy dữ liệu doanh số tổng của Nhà thuốc (Doanh số tháng trước và Doanh số YTD có VAT) phục vụ việc ra quyết định.
* **Dữ liệu Đối soát Sử dụng (Medigo Usage):** Tiếp nhận dữ liệu số lượt tư vấn thực tế NT đã sử dụng từ MEDIGO đồng bộ trực tiếp vào bảng đăng ký theo cặp khóa `(thang, custid)` để theo dõi tỷ lệ `% Used`.

---

## 2. Mục tiêu (Goals)

* **[Mục tiêu 1]: Số hóa 100% quy trình đăng ký & gia hạn gói tư vấn Medigo:** Thay thế hoàn toàn việc cập nhật thủ công trên Google Sheets, tránh sai lệch và trùng lặp dữ liệu.
* **[Mục tiêu 2]: Tối ưu hóa hiệu quả phân bổ ngân sách (Data-driven Decision):** Cung cấp trực quan chỉ số `% Used` của tháng trước và doanh số bán hàng của Nhà thuốc giúp CRM ra quyết định giữ lại, điều chỉnh số lượt, hoặc loại bỏ các NT không hiệu quả.
* **[Mục tiêu 3]: Tự động hóa kế thừa dữ liệu (Zero-effort Renewal):** Giảm thiểu thao tác nhập liệu định kỳ hàng tháng cho CRM thông qua cơ chế tự động gia hạn các NT cũ.
* **[Mục tiêu 4]: Chuẩn hóa quy trình kiểm duyệt và tích hợp 2 chiều với Medigo:** Đảm bảo danh sách được phê duyệt chặt chẽ bởi cấp Quản lý (GĐBH/Admin) trước khi chuyển giao cho kỹ thuật Medigo tạo tài khoản.

---

## 3. Đối tượng sử dụng (User Personas)

| Vai trò | Mô tả nghiệp vụ trên hệ thống |
| :--- | :--- |
| **CRM (Quản lý Bán hàng)** | - Truy cập module hàng tháng (chu kỳ đăng ký tháng tiếp theo, ví dụ: lập danh sách cho Tháng 10).<br>- Xem danh sách tự động gia hạn từ tháng trước kèm `% Used`, Doanh số tháng cũ, Doanh số YTD.<br>- Sửa thông tin hoặc đánh dấu ngưng tham gia (`Stop`) với NT cũ.<br>- Thêm mới các NT trong tuyến (`New`) và nhập các thông tin vận hành bắt buộc.<br>- Bấm **"Chốt danh sách"** gửi lên cấp trên phê duyệt. |
| **CRD - Anh Viển `MR0045` / Admin (Cấp Phê duyệt)** | - Xem toàn bộ danh sách đăng ký theo từng CRM / Chi nhánh.<br>- Kiểm tra tổng số NT, tổng số lượt tư vấn đề xuất.<br>- **Phê duyệt (`C`)** hoặc **Từ chối (`R`)** chi tiết theo từng Nhà thuốc `(thang, custid)`. |

---

## 4. Quy trình nghiệp vụ & Quy tắc vận hành (Business Rules & Workflow)

### 4.1. Chu kỳ vận hành theo tháng
* Quy trình đăng ký được mở định kỳ cho **Tháng tiếp theo ($M+1$)**. 
  *(Ví dụ: Trong tháng 09/2026, CRM mở form đăng ký để chốt danh sách cho Tháng 10/2026, thời điểm áp dụng là `01/10/2026`).*

### 4.2. Luồng CRM – Lập & Chốt danh sách tháng mới

#### **Bước 1: Kế thừa danh sách tháng cũ (Auto-renewal)**
* Khi mở kỳ đăng ký tháng mới, hệ thống tự động xác định tháng đăng ký $M+1$ (VD: `01/10/2026`) và tháng đối soát liền kề $M-1$ (VD: `01/09/2026`).
* **Hệ thống tự động nạp danh sách các Nhà thuốc hoạt động từ tháng trước sang tháng mới với trạng thái mặc định là `Renew` (Gia hạn)**.
* Với mỗi Nhà thuốc cũ, hệ thống hiển thị đầy đủ các chỉ số đối soát để CRM làm căn cứ đánh giá:
  1. **Số lượt tư vấn đã cài đặt tháng trước** (Quota cũ).
  2. **Số lượt thực tế đã dùng** (`Used`).
  3. **Tỷ lệ sử dụng (`% Used`)** = `(Used / Quota cũ) * 100`.
  4. **Doanh số tháng cũ (Có VAT)**.
  5. **Doanh số lũy kế YTD (Có VAT)**.

#### **Bước 2: Điều chỉnh hoặc Ngưng Nhà thuốc cũ**
* **Gia hạn giữ nguyên:** Nếu CRM không điều chỉnh gì, danh sách cũ mặc định được giữ nguyên để gia hạn sang tháng mới.
* **Điều chỉnh quota / thông tin:** CRM có quyền cập nhật lại số lượt tư vấn cài đặt, thời gian mở cửa, SĐT Nhà thuốc, tên người đại diện, SĐT TDV, hoặc ghi chú.
* **Ngưng tham gia (`Stop`):** Đối với các Nhà thuốc sử dụng không hiệu quả hoặc ngừng hợp tác, CRM đánh dấu trạng thái sang **`Stop`**.
  - Dữ liệu dòng NT `Stop` vẫn được lưu vết trên hệ thống để theo dõi lịch sử, không xóa vật lý khỏi database.
  - NT bị gắn cờ `Stop` không được tính vào tổng quota đăng ký của tháng mới.
  - CRM có thể khôi phục lại trạng thái `Renew` trước khi bấm chốt danh sách.

#### **Bước 3: Thêm mới Nhà thuốc trong tuyến (`New`)**
* CRM chỉ được thêm các Nhà thuốc thuộc tuyến bán hàng do mình phụ trách (`api_f_thongtin_tuyen_mcp_tp_pcl`) mà **chưa có** trong danh sách tháng mới.
* **Thông tin hệ thống tự động trích xuất:**
  - *Tên Nhà thuốc* (`custname`) từ danh mục khách hàng `d_master_khachhang`.
  - *Địa chỉ Nhà thuốc* (`dia_chi_nt`) từ danh mục khách hàng `d_master_khachhang`.
  - *Mã TDV & Tên TDV phụ trách tuyến* (`manv_tdv`, `ten_tdv`) từ tuyến `api_f_thongtin_tuyen_mcp_tp_pcl` và `d_users`.
* **Thông tin bắt buộc do CRM tự điền:**
  1. **Thời gian mở cửa NT:** Bắt buộc (Text, VD: `7h-21h`).
  2. **Số ĐT Nhà thuốc:** Bắt buộc (10 chữ số, dùng làm Tên đăng nhập Eclinic).
  3. **Tên đại diện NT:** Bắt buộc (Chủ hoặc người quản lý NT).
  4. **Số ĐT TDV phụ trách:** Bắt buộc (10 chữ số – **do CRM tự điền số điện thoại của TDV phụ trách trực tiếp**).
  5. **Số lượt tư vấn cài đặt:** Bắt buộc (Số nguyên dương $> 0$).
  6. **Ghi chú:** Không bắt buộc (Text).
* *Lưu ý về GPP:* CRM không cần nhập Số GPP và Hạn GPP (thông tin này sẽ do IT/Admin bổ sung sau nếu cần).
* Nhà thuốc mới thêm được gắn cờ trạng thái **`New`**.

#### **Bước 4: Chốt danh sách gửi duyệt**
* **Điều kiện hợp lệ (Validation):**
  - Danh sách phải có ít nhất 1 Nhà thuốc có trạng thái hoạt động (`New` hoặc `Renew`).
  - Tất cả các trường bắt buộc của từng dòng NT không được để trống.
  - SĐT Nhà thuốc và SĐT TDV phải đúng định dạng 10 chữ số.
  - Số lượt đăng ký phải là số nguyên dương $> 0$.
* **Ghi nhận dữ liệu:**
  - Toàn bộ danh sách được gửi lưu vào database với trạng thái **`H` (Chờ duyệt / PENDING)**.
  - Dữ liệu bị khóa đối với CRM (không cho phép chỉnh sửa) khi đang ở trạng thái `H` hoặc đã duyệt `C`. CRM chỉ được mở khóa để chỉnh sửa lại các Nhà thuốc bị từ chối (`R`).
* **Lưu ý về Thời hạn (Deadline) & Cơ chế Auto-commit của IT/Admin:**
  - Định kỳ hàng tháng có mốc deadline chốt danh sách (ví dụ: ngày 25 hàng tháng).
  - Nếu đến hạn chót mà CRM chưa bấm "Chốt danh sách" cho tháng mới, bộ phận IT/Admin sẽ chạy script/job tự động quét và chốt danh sách kế thừa từ tháng cũ sang trạng thái `H` để CRD kịp phê duyệt, tránh rủi ro gián đoạn dịch vụ của Nhà thuốc.

---

### 4.3. Luồng Phê duyệt cấp trên (CRD – Anh Viển `MR0045` / Admin)

1. **Xem danh sách chờ duyệt:**
   * CRD (Anh Viển `MR0045`) xem danh sách tổng hợp theo từng CRM/Chi nhánh.
   * Kiểm tra tổng số NT tham gia (số lượng New, Renew, Stop) và Tổng số lượt tư vấn đề xuất.
2. **Ra quyết định chi tiết theo từng Nhà thuốc `(thang, custid)` (Duyệt từng phần):**
   * **Phê duyệt (`C` - Đã duyệt / APPROVED):** Phê duyệt các Nhà thuốc hợp lệ để khóa dữ liệu.
   * **Từ chối / Mở lại (`R` - Từ chối / REJECTED):** Nhập lý do từ chối cho Nhà thuốc cụ thể. Dòng NT đó chuyển sang trạng thái `R`, mở khóa để CRM chỉnh sửa và chốt lại.
3. **Quy tắc Duyệt từng phần & Chốt lại (Partial Approval & Re-submit):**
   * Trong danh sách của 1 CRM, CRD có thể duyệt một số NT (`C`) và từ chối một số NT (`R` kèm lý do).
   * Các NT đã duyệt (`C`): Bị khóa cố định (read-only), CRM không được quyền chỉnh sửa.
   * Các NT bị từ chối (`R`): CRM chỉ được sửa các NT này (hoặc chuyển sang `Stop`), sau đó bấm "Chốt danh sách" lại.
   * Khi CRM chốt lại: Hệ thống chỉ cập nhật các NT đang bị `R` sang `H` (Chờ duyệt lại), toàn bộ các NT đã `C` được giữ nguyên vẹn.

---

### 4.4. Bảng trạng thái (Status Reference)

| Status | Tên | Diễn giải | Ai set |
| :---: | :--- | :--- | :--- |
| `H` | Chờ duyệt (Pending) | CRM vừa chốt danh sách đăng ký tháng mới, chờ CRD duyệt | CRM |
| `C` | Đã duyệt (Approved) | CRD (Anh Viển `MR0045` / Admin) đã duyệt, bản ghi chính thức được khóa | CRD (`MR0045`) |
| `R` | Từ chối (Rejected) | CRD (Anh Viển `MR0045` / Admin) từ chối đề xuất (kèm lý do), mở lại cho CRM sửa và chốt lại | CRD (`MR0045`) |

**Luồng trạng thái chính:** `Chưa chốt` → `H` → `C`  
**Luồng từ chối:** `H` → `R` → `H`

* **Trạng thái từng dòng Nhà thuốc (`trang_thai_nt`):**
  - `New`: Nhà thuốc mới bổ sung trong tháng này.
  - `Renew`: Nhà thuốc cũ từ tháng trước được tự động gia hạn tiếp tục.
  - `Stop`: Nhà thuốc cũ nhưng CRM chủ động loại bỏ, không tham gia trong tháng mới.

---

## 5. Thiết kế Cơ sở dữ liệu (Database Schema)

### Các table có sẵn/bên ngoài (External Tables):

**Table `api_f_thongtin_tuyen_mcp_tp_pcl`** (Tuyến bán hàng)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `manv` | text | Mã nhân viên (CRS) |
| `supid` | text | Quản lý (CRM) |
| `ma_khachhang` | text | Mã khách hàng (NT) |
| `tenkhachhang` | text | Tên khách hàng (NT) |

**Table `d_master_khachhang`** (Khách hàng)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `custid` | text | **PK** - Mã khách hàng |
| `custname` | text | Tên khách hàng |
| `address` | text | Địa chỉ Nhà thuốc |
| `statedescr` | text | Tỉnh/Thành |
| `so_gpp` | text | Số giấy phép GPP |
| `ngay_het_han_gpp` | text | Ngày hết hạn GPP |

**Table `d_users`** (Nhân sự)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `manv` | text | **PK** - Mã nhân viên CRM/CRS |
| `tencvbh` | text | Tên nhân viên |
| `supid` | text | Quản lý trực tiếp |

**Table `public.f_raw_data_sales_yoy`** (Doanh số)
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `custid` | text | **PK** - Mã khách hàng |
| `thang` | text | Tháng phát sinh doanh số |
| `doanhsocovat` | numeric | Doanh số có VAT |
| `ytd_covat` | numeric | Doanh số lũy kế đầu năm có VAT |

---

### Các table mới của hệ thống (New Tables):

**Table 1: `tracking_chi_phi_tp_medigo_dang_ky`**
*Bảng lưu thông tin chính đăng ký tư vấn Eclinic Medigo của từng Nhà thuốc theo từng tháng, bao gồm số lượt đăng ký, số lượt sử dụng thực tế và trạng thái phê duyệt.*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `thang` | date | **PK (1/2)** - Tháng đăng ký (Format: `YYYY-MM-01`, VD: `2026-10-01`) |
| `custid` | text | **PK (2/2)** - Mã Nhà thuốc (NT) |
| `manv` | text | Mã CRM phụ trách lập danh sách |
| `custname` | text | Tên Nhà thuốc (NT) |
| `thoi_gian_mo_cua` | text | Thời gian mở cửa NT (VD: `7h-21h`) |
| `sdt_nha_thuoc` | text | Số ĐT Nhà thuốc (dùng làm username Medigo) |
| `ten_dai_dien_nt` | text | Tên đại diện NT |
| `sdt_tdv` | text | Số ĐT TDV phụ trách |
| `so_luot_dang_ky` | integer | Số lượt tư vấn đăng ký cài đặt trong tháng |
| `so_luot_su_dung` | integer | Số lượt tư vấn đã sử dụng thực tế (Used) *(default 0)* |
| `phan_tram_used` | numeric(5,2) | Tỷ lệ % used (`so_luot_su_dung / so_luot_dang_ky * 100`) *(default 0)* |
| `ghi_chu` | text | Ghi chú *(nullable)* |
| `trang_thai_nt` | text | Trạng thái NT trong tháng: `New`, `Renew`, `Stop` |
| `status` | text | Trạng thái phê duyệt: `H` (Chờ duyệt), `C` (Đã duyệt), `R` (Từ chối) |
| `ly_do_tu_choi` | text | Lý do từ chối *(nullable, điền khi status = R)* |
| **--- SYSTEM ---** | | |
| `inserted_at` | timestamp | Thời gian tạo – CRM gửi chốt danh sách (`H`) |
| `updated_at` | timestamp | Thời gian cập nhật lần cuối |
| `approved_at` | timestamp | Thời gian Quản lý duyệt (`C`) *(nullable)* |
| `approved_by` | text | Mã Quản lý duyệt *(nullable)* |
| `rejected_at` | timestamp | Thời gian Quản lý từ chối (`R`) *(nullable)* |

---

### View Báo cáo & Bàn giao Medigo (Reporting & Export View)

**View: `v_tracking_chi_phi_tp_medigo_dang_ky_bao_cao`**
*View này tự động JOIN bảng `tracking_chi_phi_tp_medigo_dang_ky` với các bảng danh mục hệ thống để mapping đầy đủ các cột phục vụ báo cáo BI và xuất file bàn giao cho kỹ thuật Medigo:*

| Cột trong View | Nguồn Mapping | Mô tả |
| :--- | :--- | :--- |
| `thang`, `custid`, `manv`, `custname`, `thoi_gian_mo_cua`, `sdt_nha_thuoc`, `ten_dai_dien_nt`, `sdt_tdv`, `so_luot_dang_ky`, `so_luot_su_dung`, `phan_tram_used`, `ghi_chu`, `trang_thai_nt`, `status` | Bảng chính `tracking_chi_phi_tp_medigo_dang_ky` | Toàn bộ dữ liệu gốc từ bảng đăng ký & đối soát |
| `dia_chi_nt`, `statedescr` | JOIN `d_master_khachhang` theo `custid` | Địa chỉ chi tiết và Tỉnh/Thành của Nhà thuốc |
| `ma_chi_nhanh` | JOIN `d_master_khachhang` / `d_users` | Mã chi nhánh phụ trách (HYN017, HCM001, DNG013) |
| `ma_crm`, `ten_crm` | JOIN `api_f_thongtin_tuyen_mcp_tp_pcl` + `d_users` | Quản lý phụ trách tuyến NT |
| `manv_tdv`, `ten_tdv` | JOIN `api_f_thongtin_tuyen_mcp_tp_pcl` + `d_users` | Trình dược viên phụ trách tuyến NT |
| `so_gpp`, `ngay_het_han_gpp` | JOIN `d_master_khachhang` | Số GPP và Hạn GPP lưu trên DMS |
* **`public.f_raw_data_sales_yoy`**: Dữ liệu doanh số bán hàng lịch sử để lấy:
  * Doanh số tháng cũ có VAT: tổng doanh số của NT trong tháng $M-1$.
  * Doanh số YTD có VAT: `ytd_covat`.

---

## 6. API & Function Specifications (Chi tiết kỹ thuật)

Tất cả các API được đóng gói dưới dạng **PostgreSQL Stored Functions** trả về kiểu `JSONB` và gọi qua Gateway Django REST:
* **GET URL:** `https://bi.meraplion.com/local/get_data/<ten_ham>?<query_params>`
* **POST URL:** `https://bi.meraplion.com/local/post_data/<ten_ham>`

---

### 6.1. Nhóm Khởi tạo & Đọc dữ liệu (Read APIs)

#### **API 1: `get_tracking_chi_phi_tp_medigo_danh_sach` (Khởi tạo form & Lấy danh sách tháng mới)**
* **Loại:** READ (GET)
* **Mục đích:** API chính khi CRM mở module: lấy toàn bộ thông tin quản lý (`ma_crm`, `ten_crm`, `thang_dang_ky`, `thang_cu`) và danh sách Nhà thuốc tham gia tháng mới (tự động nạp danh sách tháng cũ sang với `trang_thai_nt = 'Renew'` nếu chưa lưu, kèm theo đầy đủ `% Used` và Doanh số tháng cũ / YTD để CRM đưa ra quyết định).
* **Input Query Params:**
  ```json
  {
      "manv": "MR1156",
      "thang_dang_ky": "2026-10-01"
  }
  ```
  *(Nếu không truyền `thang_dang_ky`, hệ thống tự động tính ngày đầu tháng tiếp theo).*
* **Logic xử lý & Quy ước dữ liệu tháng:**
  1. Tra cứu `manv` trong `d_users` để lấy mã CRM (`ma_crm`), tên CRM (`ten_crm`).
  2. Xác định 2 mốc tháng:
     - `thang_dang_ky`: Ngày đầu **Tháng Mới** đang lập kế hoạch (VD: `2026-10-01`).
     - `thang_cu`: Ngày đầu **Tháng Cũ** liền trước để làm dữ liệu tham chiếu đối soát (VD: `2026-09-01`).
  3. **Phân biệt dữ liệu của Tháng Mới vs Tháng Cũ trong từng dòng `data`:**
     - **Dữ liệu Tháng Mới (`thang_dang_ky` - 10/2026):** gồm `thang`, `custid`, `so_luot_dang_ky`, `ghi_chu`, `trang_thai_nt` (`New`, `Renew`, `Stop`), `status` (`H`, `C`, `R` hoặc `null`), `ly_do_tu_choi`.
     - **Dữ liệu tham chiếu Tháng Cũ (`thang_cu` - 09/2026):** gồm `so_luot_dang_ky_thang_cu`, `so_luot_su_dung_thang_cu`, `phan_tram_used`, `doanh_so_thang_cu_covat`, `doanh_so_ytd_covat`.
  4. Kiểm tra dữ liệu tháng mới trong `tracking_chi_phi_tp_medigo_dang_ky` WHERE `thang = thang_dang_ky AND manv = ma_crm`:
     - **Case 1: Nếu CHƯA CÓ trong DB (Lần đầu CRM vào form tháng mới `2026-10-01`):**
       - Hệ thống truy vấn trực tiếp danh sách NT hoạt động từ tháng cũ trong DB (`WHERE thang = thang_cu ('2026-09-01')`).
       - Vì các bản ghi này thuộc về tháng cũ trong DB, trường `thang` trả về chính là **`2026-09-01`**.
       - Các trường `so_luot_dang_ky`, `so_luot_su_dung`, `phan_tram_used` trong dòng này chính là dữ liệu gốc của **Tháng 9/2026**.
       - Trạng thái mặc định: `trang_thai_nt = 'Renew'`, `status = null` (chưa lưu/chưa chốt cho tháng 10), `ly_do_tu_choi = null`.
       - Frontend dựa vào `thang = '2026-09-01'` (khác `thang_dang_ky`) để nhận biết danh sách đang ở chế độ kế thừa đề xuất từ tháng trước; ô nhập số lượt tháng mới sẽ mặc định gợi ý bằng `so_luot_dang_ky` của tháng cũ.
     - **Case 2: Nếu ĐÃ CÓ trong DB (CRM đã bấm "Chốt danh sách" tháng mới `2026-10-01` hoặc đang được duyệt):**
       - Lấy trực tiếp danh sách các NT đã lưu của tháng mới từ DB (trường `thang = '2026-10-01'`).
       - Mỗi NT mang sẵn `so_luot_dang_ky` do CRM đã chỉnh sửa, `status`: `H`, `C`, `R` và `ly_do_tu_choi` nếu có.
       - Tra cứu bổ sung các cột tham chiếu tháng cũ (`thang_cu`) từ dữ liệu tháng trước để hiển thị đối soát trên cùng 1 dòng.

* **Output Specification (Minh họa rõ ràng 2 kịch bản):**

  **Kịch bản 1: Lần đầu mở form tháng mới (CHƯA CÓ dữ liệu Tháng 10 trong DB – Dữ liệu lấy từ Tháng 9):**
  ```json
  {
      "status": "ok",
      "ma_crm": "MR1156",
      "ten_crm": "Huỳnh Văn Huy",
      "thang_dang_ky": "2026-10-01",  // Tháng CRM đang chuẩn bị đăng ký
      "thang_cu": "2026-09-01",        // Tháng dữ liệu gốc đang hiển thị
      "tong_so_nt": 2,
      "tong_so_luot": 95,
      "data": [
          {
              // --- Dữ liệu gốc lấy từ bản ghi Tháng Cũ (2026-09-01) trong DB ---
              "thang": "2026-09-01",            // Bản ghi thuộc Tháng 09/2026
              "custid": "N01104172",
              "custname": "NT Minh Tâm - Quảng Ngãi",
              "dia_chi_nt": "415 Nguyễn Văn Linh, Phường Trương Quang Trọng, TP Quảng Ngãi",
              "thoi_gian_mo_cua": "7h-21h",
              "sdt_nha_thuoc": "0333045663",
              "ten_dai_dien_nt": "Lê Thị Hoài Thương",
              "manv_tdv": "MR2346",
              "ten_tdv": "Lý Hoàng Rin",
              "sdt_tdv": "0777550699",
              "so_luot_dang_ky": 20,            // Quota đã đăng ký của Tháng 09/2026
              "so_luot_su_dung": 18,            // Số lượt thực tế đã dùng Tháng 09/2026
              "phan_tram_used": 90.0,           // Tỷ lệ % used Tháng 09/2026
              "doanh_so_thang_cu_covat": 15400000, // Doanh số Tháng 09/2026 có VAT
              "doanh_so_ytd_covat": 142000000,  // Doanh số YTD có VAT đến hết Tháng 09/2026
              "ghi_chu": "",
              "trang_thai_nt": "Renew",         // Đề xuất tự động gia hạn sang Tháng 10
              "status": null,                   // null: Tháng 10 chưa chốt / chưa lưu DB
              "ly_do_tu_choi": null
          },
          {
              "thang": "2026-09-01",
              "custid": "019244",
              "custname": "CT TNHH ABC PHARMACARE - An Hải",
              "dia_chi_nt": "02 Hoàng Quốc Việt, Phường Sơn Trà, TP Đà Nẵng",
              "thoi_gian_mo_cua": "7h-21h",
              "sdt_nha_thuoc": "0985127863",
              "ten_dai_dien_nt": "Nguyễn Thị A",
              "manv_tdv": "MR2345",
              "ten_tdv": "Nguyễn Thị Khánh Vy",
              "sdt_tdv": "0985127863",
              "so_luot_dang_ky": 75,
              "so_luot_su_dung": 70,
              "phan_tram_used": 93.3,
              "doanh_so_thang_cu_covat": 32000000,
              "doanh_so_ytd_covat": 280000000,
              "ghi_chu": "NT lớn trọng điểm",
              "trang_thai_nt": "Renew",
              "status": null,
              "ly_do_tu_choi": null
          }
      ]
  }
  ```

  **Kịch bản 2: ĐÃ CÓ dữ liệu tháng mới trong DB (CRM đã bấm "Chốt danh sách", đang chờ Quản lý duyệt `status = 'H'`):**
  ```json
  {
      "status": "ok",
      "ma_crm": "MR1156",
      "ten_crm": "Huỳnh Văn Huy",
      "thang_dang_ky": "2026-10-01",
      "thang_cu": "2026-09-01",
      "tong_so_nt": 3,
      "tong_so_luot": 100,
      "data": [
          {
              // --- [DỮ LIỆU THÁNG MỚI ĐÃ CHỐT: 2026-10-01] ---
              "thang": "2026-10-01",
              "custid": "N01104172",
              "custname": "NT Minh Tâm - Quảng Ngãi",
              "dia_chi_nt": "415 Nguyễn Văn Linh, Phường Trương Quang Trọng, TP Quảng Ngãi",
              "thoi_gian_mo_cua": "7h-21h",
              "sdt_nha_thuoc": "0333045663",
              "ten_dai_dien_nt": "Lê Thị Hoài Thương",
              "manv_tdv": "MR2346",
              "ten_tdv": "Lý Hoàng Rin",
              "sdt_tdv": "0777550699",
              "so_luot_dang_ky": 25,            // Số lượt CRM đã tăng từ 20 lên 25 và chốt
              "ghi_chu": "Tăng lượt do dùng tốt",
              "trang_thai_nt": "Renew",
              "status": "H",                    // Đã chốt, đang Chờ Quản lý duyệt
              "ly_do_tu_choi": null,

              // --- [DỮ LIỆU THAM CHIẾU THÁNG CŨ: 2026-09-01] ---
              "so_luot_dang_ky_thang_cu": 20,
              "so_luot_su_dung_thang_cu": 18,
              "phan_tram_used": 90.0,
              "doanh_so_thang_cu_covat": 15400000,
              "doanh_so_ytd_covat": 142000000
          },
          {
              // --- [DỮ LIỆU THÁNG MỚI ĐÃ CHỐT: NT ĐƯỢC THÊM MỚI] ---
              "thang": "2026-10-01",
              "custid": "019245",
              "custname": "NT Phương Mai - Hải Châu",
              "dia_chi_nt": "12 Lê Duẩn, Phường Hải Châu 1, Hải Châu, Đà Nẵng",
              "thoi_gian_mo_cua": "7h-22h",
              "sdt_nha_thuoc": "0905123456",
              "ten_dai_dien_nt": "Trần Thị Mai",
              "manv_tdv": "MR2345",
              "ten_tdv": "Nguyễn Thị Khánh Vy",
              "sdt_tdv": "0985127863",
              "so_luot_dang_ky": 50,
              "ghi_chu": "NT tiềm năng mới mở",
              "trang_thai_nt": "New",           // NT mới bổ sung trong tháng 10
              "status": "H",
              "ly_do_tu_choi": null,

              // Với NT 'New', các chỉ số sử dụng tháng cũ để trống / null
              "so_luot_dang_ky_thang_cu": null,
              "so_luot_su_dung_thang_cu": null,
              "phan_tram_used": null,
              "doanh_so_thang_cu_covat": 25000000,
              "doanh_so_ytd_covat": 210000000
          }
      ]
  }
  ```

---

#### **API 2: `get_tracking_chi_phi_tp_medigo_tuyen_nt` (Lấy danh sách NT trong tuyến khi bấm Thêm mới)**
* **Loại:** READ (GET)
* **Mục đích:** Khi CRM bấm nút "+ Thêm Nhà thuốc mới", Frontend gọi API này để lấy danh sách các Nhà thuốc thuộc tuyến bán hàng do CRM quản lý (`nt_options`), phục vụ cho dropdown tìm kiếm và chọn NT thêm mới. API luôn tự động lấy theo chu kỳ tháng mới nhất (không cần truyền tháng).
* **Input Query Params:**
  ```json
  {
      "manv": "MR1156"
  }
  ```
* **Logic xử lý:**
  1. Hệ thống tự động xác định tháng đăng ký mới nhất (tháng tiếp theo: ngày đầu tháng `YYYY-MM-01`).
  2. Lấy toàn bộ danh sách Nhà thuốc thuộc tuyến bán hàng do CRM quản lý từ `api_f_thongtin_tuyen_mcp_tp_pcl`.
  3. JOIN `d_master_khachhang` để lấy tên Nhà thuốc (`custname`), địa chỉ (`dia_chi_nt`).
  4. JOIN `d_users` để lấy mã và tên TDV phụ trách tuyến (`manv_tdv`, `ten_tdv`).
  5. LEFT JOIN `public.f_raw_data_sales_yoy` để lấy Doanh số tháng cũ có VAT và Doanh số YTD có VAT (để CRM cân nhắc tiềm năng khi thêm mới).
  6. Đánh dấu cờ `da_co_trong_danh_sach: true/false` nếu NT này đã có trong danh sách tháng mới nhất của CRM (để Frontend loại bỏ khỏi dropdown hoặc hiển thị disable).
* **Output Specification:**
  ```json
  {
      "status": "ok",
      "manv": "MR1156",
      "thang_dang_ky": "2026-10-01",
      "nt_options": [
          {
              "custid": "019245",
              "custname": "NT Phương Mai - Hải Châu",
              "dia_chi_nt": "12 Lê Duẩn, Phường Hải Châu 1, Hải Châu, Đà Nẵng",
              "manv_tdv": "MR2345",
              "ten_tdv": "Nguyễn Thị Khánh Vy",
              "doanh_so_thang_cu_covat": 25000000,
              "doanh_so_ytd_covat": 210000000,
              "da_co_trong_danh_sach": false
          },
          {
              "custid": "N01104172",
              "custname": "NT Minh Tâm - Quảng Ngãi",
              "dia_chi_nt": "415 Nguyễn Văn Linh, Phường Trương Quang Trọng, TP Quảng Ngãi",
              "manv_tdv": "MR2346",
              "ten_tdv": "Lý Hoàng Rin",
              "doanh_so_thang_cu_covat": 15400000,
              "doanh_so_ytd_covat": 142000000,
              "da_co_trong_danh_sach": true
          }
      ]
  }
  ```

---

### 6.2. Nhóm Thao tác Ghi dữ liệu (Write APIs)

#### **API 3: `insert_tracking_chi_phi_tp_medigo_chot_danh_sach`**
* **Loại:** WRITE (Insert / Update)
* **Mục đích:** CRM hoàn tất danh sách (gồm các NT `Renew`, nhóm `New` mới thêm, và các NT bị gắn cờ `Stop`) và bấm **"Chốt danh sách"**. API được thiết kế linh động cho phép chỉnh sửa nhiều lần (kể cả khi đang ở `H` hoặc sau khi bị từ chối `R`): **nếu trùng cặp khóa chính `(thang, custid)` thì thực hiện `DELETE` bản ghi cũ và `INSERT` bản ghi mới**, đồng thời đưa trạng thái sang **`H` (Chờ duyệt / PENDING)**.
* **Validation & Bảo vệ dữ liệu đã duyệt (Partial Approval):**
  1. Kiểm tra trạng thái: **Tuyệt đối không ghi đè hoặc sửa đổi các Nhà thuốc đã được phê duyệt (`status = 'C'`)**. API chỉ xử lý các dòng NT chưa có trong DB, đang chờ duyệt (`status = 'H'`), hoặc bị từ chối (`status = 'R'`).
  2. Danh sách phải có ít nhất 1 NT có trạng thái hoạt động (`New` hoặc `Renew`).
  3. Mỗi dòng NT phải có đầy đủ: `custid`, `sdt_nha_thuoc` (định dạng 10 số), `thoi_gian_mo_cua`, `ten_dai_dien_nt`, `sdt_tdv`, `so_luot_dang_ky` ($> 0$).
* **Logic xử lý (Linh động cho sửa & Duyệt từng phần):**
  1. Nhận mảng danh sách các Nhà thuốc từ Frontend.
  2. Với mỗi Nhà thuốc trong `data`:
     ```sql
     -- 1. Bỏ qua nếu NT đã được phê duyệt 'C' (bảo vệ bản ghi đã duyệt)
     IF EXISTS (SELECT 1 FROM tracking_chi_phi_tp_medigo_dang_ky 
                WHERE thang = input.thang AND custid = item.custid AND status = 'C') THEN
         CONTINUE;
     END IF;

     -- 2. Xóa bản ghi cũ nếu trùng cặp key (thang, custid) với status != 'C' để cho phép sửa đổi linh động
     DELETE FROM tracking_chi_phi_tp_medigo_dang_ky 
     WHERE thang = input.thang AND custid = item.custid AND status != 'C';

     -- 3. INSERT bản ghi mới với dữ liệu cập nhật, gán status = 'H'
     INSERT INTO tracking_chi_phi_tp_medigo_dang_ky (
         thang, custid, manv, custname, thoi_gian_mo_cua, sdt_nha_thuoc,
         ten_dai_dien_nt, sdt_tdv, so_luot_dang_ky, so_luot_su_dung, phan_tram_used,
         ghi_chu, trang_thai_nt, status, ly_do_tu_choi, inserted_at, updated_at
     ) VALUES (
         input.thang, item.custid, input.manv, item.custname, item.thoi_gian_mo_cua, item.sdt_nha_thuoc,
         item.ten_dai_dien_nt, item.sdt_tdv, item.so_luot_dang_ky, 0, 0,
         item.ghi_chu, item.trang_thai_nt, 'H', NULL, NOW(), NOW()
     );
     ```
  3. Cơ chế này giúp CRM gửi lại toàn bộ danh sách hoặc chỉ gửi các NT bị từ chối `R` đều an toàn 100%, không bao giờ làm sai lệch các NT đã được CRD duyệt `C`.
* **Payload Input (`body`):**
  ```json
  [
      {
          "thang": "2026-10-01",
          "manv": "MR1156",
          "data": [
              {
                  "custid": "N01104172",
                  "custname": "NT Minh Tâm - Quảng Ngãi - Quảng Ngãi",
                  "thoi_gian_mo_cua": "7h-21h",
                  "sdt_nha_thuoc": "0333045663",
                  "ten_dai_dien_nt": "Lê Thị Hoài Thương",
                  "sdt_tdv": "0777550699",
                  "so_luot_dang_ky": 25,
                  "ghi_chu": "Tăng lượt từ 20 lên 25 do dùng tốt",
                  "trang_thai_nt": "Renew"
              },
              {
                  "custid": "N01108025",
                  "custname": "NT Tiến Thương - Đông Hà",
                  "thoi_gian_mo_cua": "7h-21h",
                  "sdt_nha_thuoc": "0905625866",
                  "ten_dai_dien_nt": "ds Mến",
                  "sdt_tdv": "0364773789",
                  "so_luot_dang_ky": 10,
                  "ghi_chu": "Không dùng hết lượt cũ",
                  "trang_thai_nt": "Stop"
              },
              {
                  "custid": "019244",
                  "custname": "CT TNHH ABC PHARMACARE - An Hải",
                  "thoi_gian_mo_cua": "7h-21h",
                  "sdt_nha_thuoc": "0985127863",
                  "ten_dai_dien_nt": "Nguyễn Thị A",
                  "sdt_tdv": "0985127863",
                  "so_luot_dang_ky": 75,
                  "ghi_chu": "NT mới tham gia",
                  "trang_thai_nt": "New"
              }
          ]
      }
  ]
  ```
* **Output Specification:**
  ```json
  {
      "status": "ok",
      "success_message": "Đã chốt danh sách đăng ký Tháng 10/2026 thành công! Đang chờ Quản lý phê duyệt.",
      "tong_so_nt": 3
  }
  ```

---

#### **API 4: `insert_tracking_chi_phi_tp_medigo_phe_duyet`**
* **Loại:** WRITE (POST)
* **Mục đích:** Cấp Phê duyệt (CRD – Anh Viển `MR0045` / Admin) thực hiện Phê duyệt (`C` / `APPROVED`) hoặc Từ chối (`R` / `REJECTED`) chi tiết theo từng Nhà thuốc dựa trên cặp khóa chính `(thang, custid)`. Hỗ trợ duyệt từng NT riêng lẻ hoặc chọn nhiều NT để xử lý hàng loạt.
* **Phân quyền & Validation:**
  - Chỉ tài khoản cấp CRD (hiện tại là anh Viển `MR0045`) hoặc Admin hệ thống mới có quyền thực thi function này. Nếu `approved_by` không phải `MR0045` hoặc Admin $\rightarrow$ Báo lỗi phân quyền truy cập.
* **Payload Input (`body`):**
  ```json
  [
      {
          "action": "APPROVE", 
          "thang": "2026-10-01",
          "custid": "N01104172",
          "approved_by": "MR0045",
          "ly_do_tu_choi": ""
      },
      {
          "action": "REJECT", 
          "thang": "2026-10-01",
          "custid": "019244",
          "approved_by": "MR0045",
          "ly_do_tu_choi": "Số lượt phân bổ 75 quá cao, yêu cầu giảm xuống 50"
      }
  ]
  ```
* **Logic xử lý:**
  - Duyệt qua từng phần tử trong mảng input:
    - Nếu `item.action = 'APPROVE'`: 
      ```sql
      UPDATE tracking_chi_phi_tp_medigo_dang_ky 
      SET status = 'C', 
          approved_at = NOW(), 
          approved_by = item.approved_by,
          ly_do_tu_choi = NULL,
          updated_at = NOW() 
      WHERE thang = item.thang AND custid = item.custid;
      ```
    - Nếu `item.action = 'REJECT'`: 
      ```sql
      UPDATE tracking_chi_phi_tp_medigo_dang_ky 
      SET status = 'R', 
          rejected_at = NOW(), 
          ly_do_tu_choi = item.ly_do_tu_choi,
          updated_at = NOW() 
      WHERE thang = item.thang AND custid = item.custid;
      ```
* **Output Specification:**
  ```json
  {
      "status": "ok",
      "success_message": "Đã cập nhật trạng thái phê duyệt thành công!"
  }
  ```

