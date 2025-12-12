{
    "status": "ok",
    
    // ------------------------------------------------------------------
    // SHEET BMKT013: Chi tiết chi phí tiếp khách
    // ------------------------------------------------------------------
    "BMKT013": [
        {
            "khu_vuc": "",                   
            "supid": "SUP001",               
            "tenquanlytt": "Nguyễn Văn Boss",
            
            // Hai trường này code SQL select lặp lại, FE có thể dùng hoặc bỏ qua
            "supid_2": "SUP001",             
            "tenquanlytt_2": "Nguyễn Văn Boss",

            "ma_kh": "CUS_001",              
            "ten_kh": "Công ty ABC",         
            "ho_ten_nguoi_tiep": "Anh Khách",
            "kenh": "OTC",                   
            "noi_dung": "Mua quà trung thu", 
            "so_khid": "CCP001",             
            "de_xuat_kh": 500000,            
            "duyet_kh": 500000,              
            "ngay_thuc_hien": "2025-10-15",  
            "tong_tien_thuc_hien": 500000,   
            "so_hoa_don": "00123",           
            "ghi_chu": "Ghi chú thêm"        
        }
    ],

    // ------------------------------------------------------------------
    // SHEET BMKT002: Tổng hợp đề nghị thanh toán
    // ------------------------------------------------------------------
    "BMKT002": [
        {
            "stt": 1,
            "noi_dung": "Mua quà trung thu", 
            "so_hoa_don": "00123",
            "ngay_hoa_don": "2025-10-15",
            "thoi_gian_de_nghi": "Trước ngày 20 tháng sau", 
            "nguoi_nhan_tien": "MR0673 - Nguyễn Văn A", 
            "ghi_chu": "Ghi chú từ Plan",    
            "so_tien": 500000
        },
        {
            "stt": 2,
            "noi_dung": "CTP THÁNG :10-2025, từ : 01-10-2025 đến: 02-10-2025", 
            "so_hoa_don": null,              
            "ngay_hoa_don": null,
            "thoi_gian_de_nghi": "Trước ngày 20 tháng sau",
            "nguoi_nhan_tien": "MR0673 - Nguyễn Văn A",
            "ghi_chu": "Công tác phí",       
            "so_tien": 300000                
        }
    ],

    // ------------------------------------------------------------------
    // FOOTER: Thông tin tổng hợp
    // ------------------------------------------------------------------
    "tong_so_tien": "800,000",             
    "so_tien_bang_chu": "Tám trăm ngàn đồng", 
    "nguoi_de_nghi": "MR0673 - Nguyễn Văn A",
    "department": "Phòng Kinh Doanh",
    "ly_do_thanh_toan": "Thanh toán chi phí giao tiếp tháng: 10-2025",
    "nguoi_nhan": "MR0673 - Nguyễn Văn A"
}