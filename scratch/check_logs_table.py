import psycopg2

db_config = {
  "host": "101.99.42.30",
  "port": 5432,
  "user": "subiteam",
  "password": "postgres321",
  "database": "postgres"
}

try:
    conn = psycopg2.connect(**db_config)
    cur = conn.cursor()
    
    # Tìm schema và các cột của bảng internal_logs
    cur.execute("""
        SELECT table_schema, table_name
        FROM information_schema.tables
        WHERE table_name = 'internal_logs';
    """)
    tables = cur.fetchall()
    print("Found tables:")
    for t in tables:
        print(f" - Schema: {t[0]}, Table: {t[1]}")
        
        # Xem cấu trúc cột
        cur.execute(f"""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_schema = '{t[0]}' AND table_name = 'internal_logs';
        """)
        cols = cur.fetchall()
        for col in cols:
            print(f"   * {col[0]}: {col[1]}")
            
    cur.close()
    conn.close()
except Exception as e:
    print("Error:", e)
