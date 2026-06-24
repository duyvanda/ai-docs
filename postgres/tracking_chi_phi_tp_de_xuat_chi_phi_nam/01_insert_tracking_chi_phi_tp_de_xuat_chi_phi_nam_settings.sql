/*
Insert/Update (Upsert) cấu hình cho đề xuất chi phí năm (settings_data).
*/
CREATE OR REPLACE FUNCTION public.insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings(json_input jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    p_appid text;
    p_manv text;
    p_applyfor timestamp;
    p_inserted_at timestamp;
    p_settings_data jsonb;
BEGIN
    /* ==============================================================
       1. PARSE INPUT FIELDS TỪ JSON
       ============================================================== */
    SELECT json_input->0->>'appid' INTO p_appid;
    SELECT json_input->0->>'manv' INTO p_manv;
    SELECT (json_input->0->>'applyfor')::timestamp INTO p_applyfor;
    SELECT (json_input->0->>'inserted_at')::timestamp INTO p_inserted_at;
    SELECT json_input->0->'settings_data' INTO p_settings_data;

    /* ==============================================================
       2. TẠO TEMP TABLE CHỨA BẢN GHI NGƯỜI DÙNG NHẬP
       ============================================================== */
    CREATE TEMP TABLE input_raw ON COMMIT DROP AS (
        SELECT 
            p_appid AS appid,
            p_manv AS manv,
            p_applyfor AS applyfor,
            p_inserted_at AS inserted_at,
            p_settings_data AS js
    );

    /* ==============================================================
       3. NẾU PASS → INSERT / UPSERT DỮ LIỆU
       ============================================================== */
    INSERT INTO public.settings_data (appid, js, manv, inserted_at, applyfor)
    SELECT appid, js, manv, inserted_at, applyfor
    FROM input_raw
    ON CONFLICT (appid, applyfor) DO UPDATE 
    SET 
        js = EXCLUDED.js, 
        manv = EXCLUDED.manv, 
        inserted_at = EXCLUDED.inserted_at;

    /* ==============================================================
       4. RETURN JSON SUCCESS
       ============================================================== */
    RETURN jsonb_build_object(
        'status', 'ok',
        'success_message', 'Cập nhật cấu hình thành công.'
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'fail',
        'error_message', SQLERRM
    );
END;
$$;
