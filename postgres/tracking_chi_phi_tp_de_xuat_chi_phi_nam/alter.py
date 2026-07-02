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

try:
    cursor.execute("""
    ALTER TABLE public.tracking_chi_phi_tp_de_xuat_chi_phi_nam
    ADD COLUMN IF NOT EXISTS url_zip_file text,
    ADD COLUMN IF NOT EXISTS url_zip_image text,
    ADD COLUMN IF NOT EXISTS submitted_at timestamp;
    """)
    print("Added columns successfully.")
except Exception as e:
    print(f"Error: {e}")
