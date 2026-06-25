import psycopg2
import json
import os
import sys
from dotenv import load_dotenv

sys.stdout.reconfigure(encoding='utf-8')

load_dotenv()
postgres_conf = {
    "host": os.getenv("DB_HOST"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}

try:
    conn = psycopg2.connect(**postgres_conf)
    conn.autocommit = True
    cursor = conn.cursor()
    print("Connected to DB.")
    
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS public.tracking_chi_phi_tp_de_xuat_chi_phi_nam (
        id text PRIMARY KEY,
        custid text,
        hoat_dong_id text,
        ten_hoat_dong text,
        manv_crm text,
        so_tien_de_xuat numeric,
        ghi_chu text,
        so_tien_duyet_crd numeric,
        so_tien_duyet_cxd numeric,
        status text,
        applyfor date,
        inserted_at timestamp DEFAULT CURRENT_TIMESTAMP,
        ly_do_tu_choi text,
        crd_approved_at timestamp,
        crd_approved_manv text,
        cxd_approved_at timestamp,
        cxd_approved_manv text,
        CONSTRAINT unique_cust_hoatdong_applyfor UNIQUE (custid, hoat_dong_id, applyfor)
    );
    """
    cursor.execute(create_table_sql)
    print("Created table tracking_chi_phi_tp_de_xuat_chi_phi_nam.")

    folder = r"d:\ai-docs\postgres\tracking_chi_phi_tp_de_xuat_chi_phi_nam"
    files = [
        "01_insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings.sql",
        "02_get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings.sql",
        "03_get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm.sql",
        "04_insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm.sql",
        "05_get_tracking_chi_phi_tp_de_xuat_chi_phi_nam.sql",
        "06_insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crd.sql",
        "07_insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_cxd.sql"
    ]

    for f in files:
        path = os.path.join(folder, f)
        with open(path, 'r', encoding='utf-8') as file:
            sql = file.read()
            cursor.execute(sql)
            print(f"Deployed {f}")

    print("\n--- Testing API 01: Settings ---")
    settings_payload = [{
        "appid": "tracking_chi_phi_tp_de_xuat_chi_phi_nam",
        "manv": "MR1682",
        "inserted_at": "2026-01-10T09:00:00",
        "applyfor": "2026-01-01T00:00:00",
        "settings_data": {
            "quy_tac_chung": {
                "ten_chuong_trinh": "Đề xuất Chi phí Năm 2026"
            },
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
                },
                {
                    "makhdms": "000691",
                    "ten_kh": "CT DP Hồng Đào - TP Cà Mau",
                    "ma_crm": "MR1035",
                    "ten_crm": "Nguyễn Thanh Tài",
                    "ngan_sach": 100000000,
                    "hoat_dong_id": "tracking_chi_phi_tp_m_session",
                    "ten_hoat_dong": "Đào tạo CMSP (M.Session)",
                    "ngan_sach_uoc_luong": 70000000
                }
            ],
            "hoat_dong_options": [
                {
                    "loai": "Chiến lược",
                    "ten_hoat_dong": "Hội nghị KH",
                    "hoat_dong_id": "tracking_chi_phi_tp_conference"
                },
                {
                    "loai": "Commercial",
                    "ten_hoat_dong": "Đào tạo CMSP (M.Session)",
                    "hoat_dong_id": "tracking_chi_phi_tp_m_session"
                }
            ]
        }
    }]
    cursor.execute("SELECT public.insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings(%s::jsonb);", (json.dumps(settings_payload),))
    res = cursor.fetchone()
    print("Result:", json.dumps(res[0], indent=2, ensure_ascii=False))

    print("\n--- Testing API 04: CRM Submit ---")
    crm_payload = [
        {
            "id": "000691_tracking_chi_phi_tp_conference_2026",
            "custid": "000691",
            "hoat_dong_id": "tracking_chi_phi_tp_conference",
            "ten_hoat_dong": "Hội nghị KH",
            "manv_crm": "MR1035",
            "so_tien_de_xuat": 40000000,
            "ghi_chu": "Làm event lớn vượt mức",
            "applyfor": "2026-01-01"
        }
    ]
    cursor.execute("SELECT public.insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm(%s::jsonb);", (json.dumps(crm_payload),))
    res = cursor.fetchone()
    print("Result:", json.dumps(res[0], indent=2, ensure_ascii=False))

    print("\n--- Testing API 03: CRM Get ---")
    get_crm_payload = {"manv": "MR1035"}
    cursor.execute("SELECT public.get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm(%s::jsonb);", (json.dumps(get_crm_payload),))
    res = cursor.fetchone()
    print("Result:", json.dumps(res[0], indent=2, ensure_ascii=False))
    
    print("\n--- Testing API 05: Get List ---")
    get_all_payload = {"manv": "MR0001"}
    cursor.execute("SELECT public.get_tracking_chi_phi_tp_de_xuat_chi_phi_nam(%s::jsonb);", (json.dumps(get_all_payload),))
    res = cursor.fetchone()
    print("Result:", json.dumps(res[0], indent=2, ensure_ascii=False))

    print("\n--- Testing API 06: CRD Approve ---")
    crd_payload = [
        {
            "id": "000691_tracking_chi_phi_tp_conference_2026",
            "status": "C",
            "so_tien_duyet_crd": 35000000,
            "crd_approved_manv": "MR0001",
            "crd_approved_at": "2026-01-20T14:00:00"
        }
    ]
    cursor.execute("SELECT public.insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crd(%s::jsonb);", (json.dumps(crd_payload),))
    res = cursor.fetchone()
    print("Result:", json.dumps(res[0], indent=2, ensure_ascii=False))

    print("\n--- Testing API 07: CXD Approve ---")
    cxd_payload = [
        {
            "id": "000691_tracking_chi_phi_tp_conference_2026",
            "status": "D",
            "so_tien_duyet_cxd": 35000000,
            "cxd_approved_manv": "CXD001",
            "cxd_approved_at": "2026-01-21T09:00:00"
        }
    ]
    cursor.execute("SELECT public.insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_cxd(%s::jsonb);", (json.dumps(cxd_payload),))
    res = cursor.fetchone()
    print("Result:", json.dumps(res[0], indent=2, ensure_ascii=False))

except Exception as e:
    import traceback
    traceback.print_exc()
finally:
    if 'cursor' in locals() and cursor:
        cursor.close()
    if 'conn' in locals() and conn:
        conn.close()
