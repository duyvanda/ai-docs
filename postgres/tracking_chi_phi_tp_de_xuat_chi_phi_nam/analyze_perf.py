import psycopg2
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn = psycopg2.connect(host='101.99.42.30', port=5432, user='subiteam', password='postgres321', database='postgres')
cur = conn.cursor()

def analyze_query(query):
    cur.execute(f"EXPLAIN ANALYZE {query}")
    for row in cur.fetchall():
        print(row[0])
    print("-" * 80)

# Get a sample phone with many records
cur.execute("SELECT phone, count(*) FROM public.nvbc_track_view GROUP BY phone ORDER BY count(*) DESC LIMIT 1")
sample_phone = cur.fetchone()[0]
print(f"Using sample phone: {sample_phone}")

print("=== CTE: meraplion_doc_check ===")
analyze_query(f"""
    SELECT t.document_id, SUM(t.effective_point) as total_doc_point
    FROM public.nvbc_track_view t
    JOIN public.nvbc_docs doc ON t.document_id::int = doc.document_id
    WHERE t.phone = '{sample_phone}'
      AND doc.category = 'THÔNG TIN VỀ MERAPLION'
      AND date_trunc('month', t.inserted_at) = date_trunc('month', CURRENT_DATE)
    GROUP BY t.document_id
""")

print("=== CTE: history_raw ===")
analyze_query(f"""
    SELECT t.phone, t.ma_kh_dms, t.inserted_at, t.document_id, d.document_name, t.watch_duration_seconds, t.time_rate, t.base_point, t.effective_point
    FROM public.nvbc_track_view t
    LEFT JOIN public.nvbc_docs d ON t.document_id = d.document_id::text
    WHERE t.phone = '{sample_phone}'
      AND t.inserted_at::date >= '2026-07-01'
    ORDER BY t.inserted_at DESC
""")

print("=== CTE: streak_7_days ===")
analyze_query(f"""
    WITH day_series AS (
        SELECT generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, INTERVAL '1 day')::DATE AS day_date
    )
    SELECT ds.day_date AS date,
           (EXISTS (
               SELECT 1
               FROM public.nvbc_track_view t
               WHERE t.phone = '{sample_phone}'
                 AND t.inserted_at::DATE = ds.day_date
           )) AS has_view
    FROM day_series ds
""")

