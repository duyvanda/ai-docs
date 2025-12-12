# DATA REQUIREMENT SPEC (PRD)

## 1. Goal (Mục tiêu)
Viết query lấy báo cáo **Doanh thu theo ngày** và **Tỉ lệ hủy đơn** cho team Sale.

## 2. Output Definition (Kết quả mong muốn)
| Column Name | Data Type | Description / Logic |
| :--- | :--- | :--- |
| `report_date` | Date | Ngày đặt hàng |
| `platform` | String | 'iOS', 'Android', 'Web' |
| `total_gmv` | Float | Tổng giá trị đơn hàng (chưa trừ discount) |
| `net_revenue` | Float | `total_gmv` - `discount` - `refund` |
| `cancel_rate` | Float | Số đơn hủy / Tổng số đơn |

## 3. Data Source (Nguồn dữ liệu)
* **Table `orders`**: 
    * `order_id` (PK)
    * `user_id`
    * `amount`
    * `discount_amount`
    * `status` (values: 'completed', 'cancelled', 'pending')
    * `platform_source`
    * `created_at`
* **Table `refunds`**:
    * `order_id`
    * `refund_amount`

## 4. Business Logic / Filters (Quy tắc nghiệp vụ)
1. **Time Range:** Lấy dữ liệu 90 ngày gần nhất.
2. **Filter:** Chỉ tính các đơn hàng `status = 'completed'` vào doanh thu. Đơn `cancelled` chỉ dùng để tính tỉ lệ hủy.
3. **User:** Loại bỏ user có `user_id` < 1000 (đây là user test).
4. **Platform:** Map lại tên platform: 
    * `ios_app` -> 'iOS'
    * `android_app` -> 'Android'
    * NULL hoặc khác -> 'Web'

## 5. Relationships (Quan hệ bảng)
* `orders` LEFT JOIN `refunds` ON `orders.order_id` = `refunds.order_id`