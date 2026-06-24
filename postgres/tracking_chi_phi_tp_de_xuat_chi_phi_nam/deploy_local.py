import psycopg2
import os

postgres_conf = {"host": "101.99.42.30","port": 5432,"user": "postgres","password": "postgres321","database": "postgres"}
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
    "07_insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_cxd.sql"
]

for f in files:
    path = os.path.join(folder, f)
    with open(path, 'r', encoding='utf-8') as file:
        sql = file.read()
        cursor.execute(sql)
        print(f"Deployed {f} to local schema.")

print("All functions redeployed.")
