import json
import urllib.request
import urllib.parse
import sys

sys.stdout.reconfigure(encoding='utf-8')

def post_data(func_name, payload):
    url = f"https://bi.meraplion.com/local/post_data/{func_name}/"
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req) as response:
            res = response.read().decode('utf-8')
            print(f"POST {func_name} -> HTTP {response.status}")
            print(json.dumps(json.loads(res), indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"Error POST {func_name}: {e}")
        if hasattr(e, 'read'):
            print(e.read().decode('utf-8'))

def get_data(func_name, params):
    # Dùng urllib.parse.urlencode để biến dict thành query params: ?manv=MR1035
    query = urllib.parse.urlencode(params)
    url = f"https://bi.meraplion.com/local/get_data/{func_name}/?{query}"
    req = urllib.request.Request(url)
    try:
        with urllib.request.urlopen(req) as response:
            res = response.read().decode('utf-8')
            print(f"GET {func_name} -> HTTP {response.status}")
            print(json.dumps(json.loads(res), indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"Error GET {func_name}: {e}")
        if hasattr(e, 'read'):
            print(e.read().decode('utf-8'))

print("--- Testing API 01: Settings ---")
post_data("insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings", [{
    "appid": "tracking_chi_phi_tp_de_xuat_chi_phi_nam",
    "manv": "MR1682",
    "inserted_at": "2026-01-10T09:00:00",
    "applyfor": "2026-01-01T00:00:00",
    "settings_data": {
        "quy_tac_chung": {"ten_chuong_trinh": "Đề xuất Chi phí Năm 2026"},
        "nt_options": [
            {
                "makhdms": "000691",
                "ten_kh": "CT DP Hồng Đào - TP Cà Mau",
                "ma_crm": "MR1035",
                "ten_crm": "Nguyễn Thanh Tài",
                "ngan_sach": 100000000,
                "hoat_dong_id": "tracking_chi_phi_tp_conference",
                "ten_hoat_dong": "Hội nghị KH",
                "ngan_sach_uoc_luong": 30000000
            }
        ],
        "hoat_dong_options": [
            {"loai": "Chiến lược", "ten_hoat_dong": "Hội nghị KH", "hoat_dong_id": "tracking_chi_phi_tp_conference"}
        ]
    }
}])

print("\n--- Testing API 04: CRM Submit ---")
post_data("insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm", [{
    "id": "000691_tracking_chi_phi_tp_conference_2026",
    "custid": "000691",
    "hoat_dong_id": "tracking_chi_phi_tp_conference",
    "ten_hoat_dong": "Hội nghị KH",
    "manv_crm": "MR1035",
    "so_tien_de_xuat": 45000000,
    "ghi_chu": "Làm event lớn qua HTTP API",
    "applyfor": "2026-01-01"
}])

print("\n--- Testing API 03: CRM Get ---")
get_data("get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm", {"manv": "MR1035"})

print("\n--- Testing API 05: Get List ---")
get_data("get_tracking_chi_phi_tp_de_xuat_chi_phi_nam", {"manv": "MR1035"})

print("\n--- Testing API 06: CRD Approve ---")
post_data("insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crd", [{
    "id": "000691_tracking_chi_phi_tp_conference_2026",
    "status": "C",
    "so_tien_duyet_crd": 40000000,
    "crd_approved_manv": "MR0001",
    "crd_approved_at": "2026-01-20T14:00:00"
}])

print("\n--- Testing API 07: CXD Approve ---")
post_data("insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_cxd", [{
    "id": "000691_tracking_chi_phi_tp_conference_2026",
    "status": "D",
    "so_tien_duyet_cxd": 40000000,
    "cxd_approved_manv": "CXD001",
    "cxd_approved_at": "2026-01-21T09:00:00"
}])
