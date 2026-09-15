CREATE OR REPLACE FUNCTION insert_tracking_chi_phi_tp_medigo_phe_duyet(
    p_data jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_item          jsonb;
    v_action        text;
    v_thang         date;
    v_custid        text;
    v_approved_by   text;
    v_ly_do         text;
    v_total         int := 0;
BEGIN
    -- Kiểm tra phân quyền: Chỉ CRD Anh Viển (MR0045) hoặc admin
    v_approved_by := (p_data -> 0 ->> 'approved_by');
    IF v_approved_by IS NULL OR v_approved_by NOT IN ('MR0045', 'admin') THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', 'Không có quyền thực hiện phê duyệt. Chỉ CRD (MR0045) mới được phép.'
        );
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_data)
    LOOP
        v_action      := upper(v_item->>'action');
        v_thang       := (v_item->>'thang')::date;
        v_custid      := v_item->>'custid';
        v_approved_by := v_item->>'approved_by';
        v_ly_do       := NULLIF(v_item->>'ly_do_tu_choi', '');

        IF v_action = 'APPROVE' THEN
            UPDATE tracking_chi_phi_tp_medigo_dang_ky
            SET status        = 'C',
                approved_at   = NOW(),
                approved_by   = v_approved_by,
                ly_do_tu_choi = NULL,
                updated_at    = NOW()
            WHERE thang = v_thang AND custid = v_custid;

        ELSIF v_action = 'REJECT' THEN
            UPDATE tracking_chi_phi_tp_medigo_dang_ky
            SET status        = 'R',
                rejected_at   = NOW(),
                ly_do_tu_choi = v_ly_do,
                updated_at    = NOW()
            WHERE thang = v_thang AND custid = v_custid;
        END IF;

        v_total := v_total + 1;
    END LOOP;

    RETURN jsonb_build_object(
        'status', 'ok',
        'success_message', 'Đã cập nhật trạng thái phê duyệt thành công!',
        'so_ban_ghi_xu_ly', v_total
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('status', 'error', 'message', SQLERRM);
END;
$$;
