import psycopg2
import json

db_config = {
  "host": "101.99.42.30",
  "port": 5432,
  "user": "subiteam",
  "password": "postgres321",
  "database": "postgres"
}

output_data = {}

try:
    conn = psycopg2.connect(**db_config)
    cur = conn.cursor()
    
    # Query tìm các function thông thường (prokind = 'f') chứa s.internal_logs
    cur.execute("""
        SELECT p.proname, pg_get_functiondef(p.oid)
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.prokind = 'f' 
          AND pg_get_functiondef(p.oid) ILIKE '%s.internal_logs%'
        LIMIT 5;
    """)
    funcs = cur.fetchall()
    output_data["count"] = len(funcs)
    output_data["functions"] = []
    
    for f in funcs:
        func_name = f[0]
        code = f[1]
        lines = code.split('\n')
        snippets = []
        for idx, line in enumerate(lines):
            if 's.internal_logs' in line:
                start = max(0, idx - 5)
                end = min(len(lines), idx + 6)
                snippet_lines = [f"{i+1}: {lines[i]}" for i in range(start, end)]
                snippets.append(snippet_lines)
        output_data["functions"].append({
            "name": func_name,
            "snippets": snippets
        })
                
    cur.close()
    conn.close()
except Exception as e:
    output_data["error"] = str(e)

with open("logs_usage_output.json", "w", encoding="utf-8") as f:
    json.dump(output_data, f, ensure_ascii=False, indent=2)
print("Finished. Output written to logs_usage_output.json")
