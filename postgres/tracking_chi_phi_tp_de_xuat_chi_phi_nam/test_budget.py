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

print("\n--- Testing API 04: CRM Submit OVER BUDGET (Rule 1 Validation) ---")
# Currently the customer 000691 has 1 proposal of 45,000,000 VND (Hội nghị KH)
# The total budget is 100,000,000 VND.
# We will submit another activity (Đào tạo CMSP) with 60,000,000 VND.
# The total will be 105,000,000 > 100,000,000. It MUST fail.
post_data("insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm", [{
    "id": "000691_tracking_chi_phi_tp_m_session_2026",
    "custid": "000691",
    "hoat_dong_id": "tracking_chi_phi_tp_m_session",
    "ten_hoat_dong": "Đào tạo CMSP (M.Session)",
    "manv_crm": "MR1035",
    "so_tien_de_xuat": 60000000,
    "ghi_chu": "Thử test lố ngân sách",
    "applyfor": "2026-01-01"
}])
