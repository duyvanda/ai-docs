import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()
postgres_conf = {
    "host": os.getenv("DB_HOST"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}
conn = psycopg2.connect(**postgres_conf)
conn.autocommit = True
cursor = conn.cursor()

folder = r"d:\ai-docs\postgres\tracking_chi_phi_tp_de_xuat_chi_phi_nam"
files = [
    "01_insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings.sql",
    "02_get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings.sql",
    "03_get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm.sql",
    "04_insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm.sql",
    "05_get_tracking_chi_phi_tp_de_xuat_chi_phi_nam.sql",
    "06_insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crd.sql",
    "07_insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_cxd.sql",
    "08_get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_kh_options.sql",
    "09_insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_chung_tu.sql"
]

for f in files:
    path = os.path.join(folder, f)
    with open(path, 'r', encoding='utf-8') as file:
        sql = file.read()
        cursor.execute(sql)
        print(f"Deployed {f} to local schema.")

print("All functions redeployed.")
