import pandas as pd
import sys
import json

sys.stdout.reconfigure(encoding='utf-8')

try:
    file_path = r'd:\ai-docs\postgres\tracking_chi_phi_tp_de_xuat_chi_phi_nam\Copy of tp_setting_de_xuat_chi_phi_hoat_dong_nam_v2.xlsx'
    df = pd.read_excel(file_path, sheet_name=None)
    for sheet, data in df.items():
        print(f"--- Sheet: {sheet} ---")
        print("Columns:", list(data.columns))
        print("First 3 rows:")
        print(data.head(3).to_json(orient='records', force_ascii=False))
except Exception as e:
    import traceback
    traceback.print_exc()
