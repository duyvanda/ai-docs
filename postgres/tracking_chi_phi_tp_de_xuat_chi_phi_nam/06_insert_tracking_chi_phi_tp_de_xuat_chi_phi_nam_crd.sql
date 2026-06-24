/*
CRD Duyệt/Từ chối đề xuất chi phí năm.
*/
CREATE OR REPLACE FUNCTION local.insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crd(json_input jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_check_1 INT := 0;
BEGIN
    /* ==============================================================
       1 & 2. PARSE INPUT TỪ JSON -> TEMP TABLE
       ============================================================== */
    CREATE TEMP TABLE input_raw ON COMMIT DROP AS (
        SELECT 
            (el->>'id')::text AS id,
            (el->>'status')::text AS status,
            (el->>'so_tien_duyet_crd')::numeric AS so_tien_duyet_crd,
            (el->>'ly_do_tu_choi')::text AS ly_do_tu_choi,
            (el->>'crd_approved_manv')::text AS crd_approved_manv,
            COALESCE((el->>'crd_approved_at')::timestamp, CURRENT_TIMESTAMP) AS crd_approved_at
        FROM jsonb_array_elements(json_input) AS el
    );

    /* ==============================================================
       3. VALIDATE (Ví dụ: Từ chối thì phải có lý do)
       ============================================================== */
    SELECT COUNT(*)
    INTO v_check_1
    FROM input_raw
    WHERE status = 'R' AND (ly_do_tu_choi IS NULL OR ly_do_tu_choi = '');

    IF v_check_1 > 0 THEN
        RETURN jsonb_build_object(
            'status', 'fail',
            'error_message', 'Bắt buộc phải nhập lý do từ chối.'
        );
    END IF;

    /* ==============================================================
       4. UPDATE DỮ LIỆU VÀO BẢNG CHÍNH
       ============================================================== */
    UPDATE public.tracking_chi_phi_tp_de_xuat_chi_phi_nam tr
    SET 
        status = i.status,
        so_tien_duyet_crd = i.so_tien_duyet_crd,
        ly_do_tu_choi = i.ly_do_tu_choi,
        crd_approved_manv = i.crd_approved_manv,
        crd_approved_at = i.crd_approved_at
    FROM input_raw i
    WHERE tr.id = i.id;

    /* ==============================================================
       5. RETURN
       ============================================================== */
    RETURN jsonb_build_object(
        'status', 'ok',
        'success_message', 'CRD đã phê duyệt thành công.'
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'fail',
        'error_message', SQLERRM
    );
END;
$$;
