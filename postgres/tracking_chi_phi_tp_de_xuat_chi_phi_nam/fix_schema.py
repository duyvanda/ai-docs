import os
import re

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
        content = file.read()
    
    # Replace ONLY the function definition
    content = re.sub(r'CREATE OR REPLACE FUNCTION public\.', 'CREATE OR REPLACE FUNCTION local.', content)
    
    with open(path, 'w', encoding='utf-8') as file:
        file.write(content)
        
print("Updated all functions to use local schema.")
