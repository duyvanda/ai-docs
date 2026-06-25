import psycopg2
import sys
import os
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
conn = psycopg2.connect(**postgres_conf)
cursor = conn.cursor()

try:
    cursor.execute("""
    SELECT conname, pg_get_constraintdef(c.oid)
    FROM pg_constraint c
    JOIN pg_namespace n ON n.oid = c.connamespace
    WHERE conrelid = 'public.settings_data'::regclass;
    """)
    print("settings_data constraints:", cursor.fetchall())
except Exception as e:
    print(e)

try:
    cursor.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'settings_data';
    """)
    print("settings_data columns:", cursor.fetchall())
except Exception as e:
    print(e)
