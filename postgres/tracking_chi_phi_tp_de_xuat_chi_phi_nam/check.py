import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')

postgres_conf = {"host": "101.99.42.30","port": 5432,"user": "postgres","password": "postgres321","database": "postgres"}
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
