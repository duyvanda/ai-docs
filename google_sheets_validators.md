# HƯỚNG DẪN CÀI ĐẶT SCRIPT "CẢNH SÁT DỮ LIỆU" GOOGLE SHEETS

Tài liệu này hướng dẫn cài đặt Script tự động kiểm tra lỗi nhập liệu (Data Validation) trên Google Sheets bằng Apps Script.

---

## 1. TÍNH NĂNG CHÍNH
- **Chặn dữ liệu rác:** Tự động phát hiện và xóa nếu nhập sai ngày tháng (ví dụ: `32/01`) hoặc sai số (ví dụ: `10kg` vào cột số).
- **Hiệu suất cao (High Performance):** Tối ưu hóa để không bị treo máy ("Working...") khi copy-paste nhiều dòng cùng lúc.
- **Thông báo Toast:** Hiển thị thông báo nhỏ gọn góc phải, tự động tắt sau 10 giây, không chặn màn hình.
- **Báo lỗi đích danh:** Chỉ rõ dòng nào sai và giá trị sai là gì (Ví dụ: *"Dòng 10: 'abc' không phải ngày"*).

---

## 2. HƯỚNG DẪN CÀI ĐẶT

### Bước 1: Mở trình sửa Code
1. Mở file Google Sheets cần cài đặt.
2. Trên thanh menu, chọn **Tiện ích mở rộng (Extensions)** > **Apps Script**.
3. Một tab mới hiện ra. Hãy **Xóa trắng** toàn bộ code mặc định đang có.

### Bước 2: Dán Code
Copy toàn bộ đoạn code ở mục **[3. SOURCE CODE]** bên dưới và dán vào trình soạn thảo.

### Bước 3: Lưu và Dọn dẹp Trigger cũ
1. Nhấn **Lưu (Ctrl + S)**. Đặt tên script là `ValidateData`.
2. **QUAN TRỌNG:** Nhìn menu bên trái, chọn biểu tượng **Đồng hồ (Triggers)**.
3. Nếu thấy có bất kỳ Trigger (Kích hoạt) nào trong danh sách -> **XÓA HẾT NGAY**.
   *(Lý do: Script này dùng hàm `onEdit` tự động, nếu để trigger thừa sẽ gây xung đột và treo máy).*

### Bước 4: Kiểm tra Cài đặt Vùng (Locale)
1. Quay lại Google Sheets, vào **Tệp (File)** > **Cài đặt (Settings)**.
2. Tại mục **Vùng (Locale)**: Chọn **Vietnam**.
3. Nhấn **Lưu**. *(Bước này để máy hiểu ngày tháng dạng dd/mm/yyyy)*.

---

## 3. SOURCE CODE (Copy đoạn này)

```javascript
/**
 * SCRIPT KIỂM TRA DỮ LIỆU TỰ ĐỘNG (DATE & NUMBER)
 * Phiên bản: High Performance - Toast Notification (Siêu Tốc)
 */

function onEdit(e) {
  try {
    // ============================================================
    // PHẦN 1: CẤU HÌNH (BẠN CHỈ CẦN SỬA Ở ĐÂY)
    // ============================================================
    var CONFIG = {
      // TÊN SHEET (Phải giống hệt tên dưới tab)
      "HOP DONG NAM 2025 - KENH TP": { 
        skipRows: 4,                   // Số dòng tiêu đề muốn bỏ qua (không kiểm tra)
        dateCols: [1, 20, 21, 23, 24], // Danh sách cột bắt buộc là NGÀY (A=1, B=2...)
        numCols: []                    // Danh sách cột bắt buộc là SỐ (Để trống [] nếu không có)
      },
      
      // Thêm cấu hình cho Sheet khác (Copy block trên để thêm)
      "HOP DONG NAM 2025 - KENH MT": { 
        skipRows: 4, 
        dateCols: [1, 20, 21, 23, 24], 
        numCols: [] 
      }
    };

    // Cấu hình năm hợp lệ
    var minYear = 2000;
    var maxYear = 2050;

    // ============================================================
    // PHẦN 2: LOGIC XỬ LÝ HỆ THỐNG
    // ============================================================
    var range = e.range;
    var sheet = range.getSheet();
    var settings = CONFIG[sheet.getName()];
    
    // Check nhanh: Nếu sai tên Sheet hoặc sửa vào vùng tiêu đề -> Dừng ngay
    if (!settings || range.getRow() <= settings.skipRows) return;

    var values = range.getValues();
    var numRows = values.length;
    var numCols = values[0].length;
    var startCol = range.getColumn();
    var startRow = range.getRow();

    var errorDetail = ""; 
    var hasError = false;

    // Vòng lặp quét lỗi (Dừng ngay khi thấy lỗi đầu tiên để tối ưu tốc độ)
    for (var i = 0; i < numRows; i++) {
      var currentRow = startRow + i;
      // Bỏ qua dòng tiêu đề nếu vùng paste dính vào tiêu đề
      if (currentRow <= settings.skipRows) continue;

      for (var j = 0; j < numCols; j++) {
        var cellVal = values[i][j];
        if (cellVal === "") continue; // Bỏ qua ô trống

        var colIndex = startCol + j;

        // --- CHECK NGÀY THÁNG ---
        if (settings.dateCols.indexOf(colIndex) !== -1) {
          if (!(cellVal instanceof Date)) {
            hasError = true;
            errorDetail = "Dòng " + currentRow + ": '" + cellVal + "' không phải ngày";
          } else {
            var y = cellVal.getFullYear();
            if (y < minYear || y > maxYear) {
              hasError = true;
              var dStr = Utilities.formatDate(cellVal, "GMT+7", "dd/MM/yyyy");
              errorDetail = "Dòng " + currentRow + ": Năm " + y + " sai (" + dStr + ")";
            }
          }
        }
        
        // --- CHECK SỐ (NUMBER) ---
        if (settings.numCols.indexOf(colIndex) !== -1) {
           // Nếu không phải number HOẶC là Date (Date cũng là object nhưng ko phải số thuần)
           if (typeof cellVal !== 'number' || (cellVal instanceof Date)) {
             hasError = true;
             var valShow = (cellVal instanceof Date) ? "Ngày tháng" : ("'" + cellVal + "'");
             errorDetail = "Dòng " + currentRow + ": " + valShow + " không phải số";
           }
        }

        if (hasError) break; // Thấy lỗi dừng ngay vòng lặp cột
      }
      if (hasError) break; // Thấy lỗi dừng ngay vòng lặp dòng
    }

    // ============================================================
    // PHẦN 3: HÀNH ĐỘNG
    // ============================================================
    if (hasError) {
      range.clearContent(); // Xóa dữ liệu sai
      
      // Hiện thông báo Toast (Góc phải màn hình)
      SpreadsheetApp.getActiveSpreadsheet().toast(
        "⚠️ Đã xóa dữ liệu sai! " + errorDetail, 
        "Cảnh báo Nhập liệu", 
        10
      );
    } else {
      // Format lại ngày tháng cho đẹp (dd/mm/yyyy)
      // Chỉ format nếu vùng edit có chứa cột ngày
      if (settings.dateCols.some(function(c) { return c >= startCol && c <= startCol + numCols - 1; })) {
         try { range.setNumberFormat("dd/mm/yyyy"); } catch(e){}
      }
    }

  } catch (err) {
    // Im lặng nếu có lỗi hệ thống để tránh treo máy
  }
}
```

---

## 4. CÁCH TÙY CHỈNH CHO FILE KHÁC (CONFIG)

Khi áp dụng cho file mới, bạn chỉ cần sửa phần `CONFIG` ở đầu code.

### Cấu trúc:
```javascript
"TÊN_SHEET_CHÍNH_XÁC": { 
  skipRows: X,            // X là số dòng tiêu đề bỏ qua
  dateCols: [A, B, C],    // Điền số thứ tự cột Ngày
  numCols:  [D, E]        // Điền số thứ tự cột Số
},
```

### Bảng tra cứu số thứ tự cột:
- **A** = 1
- **B** = 2
- **C** = 3
- ...
- **Z** = 26
- **AA** = 27

---

## 5. XỬ LÝ LỖI THƯỜNG GẶP

| Hiện tượng | Nguyên nhân | Cách khắc phục |
| :--- | :--- | :--- |
| **Báo "Working..." mãi không tắt** | Do bị trùng Trigger hoặc Code cũ bị lặp | Vào menu **Triggers** xóa sạch hết trigger cũ đi. |
| **Nhập 13/01/2025 vẫn báo lỗi** | Do Google Sheets đang để Locale Mỹ | Vào **File > Settings > Locale**, chọn **Vietnam**. |
| **Không báo lỗi gì cả** | Sai tên Sheet trong Config | Copy tên Sheet dưới tab, dán đè vào code Config (coi chừng thừa dấu cách). |