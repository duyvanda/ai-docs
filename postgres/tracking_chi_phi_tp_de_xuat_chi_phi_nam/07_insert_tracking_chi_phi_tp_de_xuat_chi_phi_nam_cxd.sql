/*
CXD Duyệt chốt/Từ chối đề xuất chi phí năm.
*/
CREATE OR REPLACE FUNCTION public.insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_cxd(json_input jsonb)
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
            (el->>'so_tien_duyet_cxd')::numeric AS so_tien_duyet_cxd,
            (el->>'ly_do_tu_choi')::text AS ly_do_tu_choi,
            (el->>'cxd_approved_manv')::text AS cxd_approved_manv,
            COALESCE((el->>'cxd_approved_at')::timestamp, CURRENT_TIMESTAMP) AS cxd_approved_at
        FROM jsonb_array_elements(json_input) AS el
    );

    /* ==============================================================
       3. VALIDATE
       ============================================================== */
    SELECT COUNT(*)
    INTO v_check_1
    FROM input_raw
    WHERE cxd_approved_manv <> 'MR1214' OR cxd_approved_manv IS NULL;

    IF v_check_1 > 0 THEN
        RETURN jsonb_build_object(
            'status', 'fail',
            'error_message', 'Mã người duyệt chốt không hợp lệ. Ràng buộc: cxd_approved_manv phải là MR1214.'
        );
    END IF;

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
        so_tien_duyet_cxd = i.so_tien_duyet_cxd,
        ly_do_tu_choi = i.ly_do_tu_choi,
        cxd_approved_manv = i.cxd_approved_manv,
        cxd_approved_at = i.cxd_approved_at
    FROM input_raw i
    WHERE tr.id = i.id;

    /* ==============================================================
       5. RETURN
       ============================================================== */
    RETURN jsonb_build_object(
        'status', 'ok',
        'success_message', 'CXD đã phê duyệt chốt thành công.'
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'fail',
        'error_message', SQLERRM
    );
END;
$$;
