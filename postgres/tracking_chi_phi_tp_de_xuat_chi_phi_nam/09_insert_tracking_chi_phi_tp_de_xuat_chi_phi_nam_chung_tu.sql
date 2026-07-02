/*
CRM nộp chứng từ sau sự kiện (cập nhật trạng thái U và lưu URL zip files)
*/
CREATE OR REPLACE FUNCTION public.insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_chung_tu(json_input jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
BEGIN
    /* ==============================================================
       1. TẠO TEMP TABLE
       ============================================================== */
    CREATE TEMP TABLE input_raw ON COMMIT DROP AS (
        SELECT 
            (el->>'id')::text AS id,
            (el->>'status')::text AS status,
            (el->>'url_zip_file')::text AS url_zip_file,
            (el->>'url_zip_image')::text AS url_zip_image,
            (el->>'submitted_at')::timestamp AS submitted_at
        FROM jsonb_array_elements(json_input) AS el
    );

    /* ==============================================================
       2. UPDATE TRẠNG THÁI VÀ CHỨNG TỪ
       ============================================================== */
    UPDATE public.tracking_chi_phi_tp_de_xuat_chi_phi_nam AS t
    SET 
        status = i.status,
        url_zip_file = COALESCE(i.url_zip_file, t.url_zip_file),
        url_zip_image = COALESCE(i.url_zip_image, t.url_zip_image),
        submitted_at = COALESCE(i.submitted_at, t.submitted_at)
    FROM input_raw i
    WHERE t.id = i.id;

    /* ==============================================================
       3. RETURN JSON SUCCESS
       ============================================================== */
    RETURN jsonb_build_object(
        'status', 'ok',
        'success_message', 'Đã nộp chứng từ thành công!'
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'fail',
        'error_message', SQLERRM
    );
END;
$$;
