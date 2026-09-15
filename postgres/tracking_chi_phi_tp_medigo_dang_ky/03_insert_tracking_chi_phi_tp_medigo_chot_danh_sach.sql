CREATE OR REPLACE FUNCTION insert_tracking_chi_phi_tp_medigo_chot_danh_sach(
    p_data jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_record    jsonb;
    v_item      jsonb;
    v_thang     date;
    v_manv      text;
    v_total     int := 0;
    v_skipped   int := 0;
BEGIN
    v_record := p_data -> 0;
    v_thang  := (v_record->>'thang')::date;
    v_manv   := v_record->>'manv';

    FOR v_item IN SELECT * FROM jsonb_array_elements(v_record->'data')
    LOOP
        -- Skip nếu đã được duyệt (status = 'C') - bảo vệ bản ghi đã duyệt
        IF EXISTS (
            SELECT 1 FROM tracking_chi_phi_tp_medigo_dang_ky
            WHERE thang = v_thang AND custid = v_item->>'custid' AND status = 'C'
        ) THEN
            v_skipped := v_skipped + 1;
            CONTINUE;
        END IF;

        -- Xóa bản ghi cũ nếu tồn tại và chưa được duyệt (H hoặc R)
        DELETE FROM tracking_chi_phi_tp_medigo_dang_ky
        WHERE thang = v_thang AND custid = v_item->>'custid' AND status != 'C';

        -- Insert bản ghi mới với status = 'H' (Chờ duyệt)
        INSERT INTO tracking_chi_phi_tp_medigo_dang_ky (
            thang, custid, manv, custname, thoi_gian_mo_cua, sdt_nha_thuoc,
            ten_dai_dien_nt, sdt_tdv, so_luot_dang_ky, so_luot_su_dung,
            phan_tram_used, ghi_chu, trang_thai_nt, status, ly_do_tu_choi,
            inserted_at, updated_at
        ) VALUES (
            v_thang,
            v_item->>'custid',
            v_manv,
            v_item->>'custname',
            COALESCE(v_item->>'thoi_gian_mo_cua', '7h-21h'),
            v_item->>'sdt_nha_thuoc',
            v_item->>'ten_dai_dien_nt',
            v_item->>'sdt_tdv',
            COALESCE((v_item->>'so_luot_dang_ky')::int, 0),
            0, 0,
            NULLIF(v_item->>'ghi_chu', ''),
            COALESCE(v_item->>'trang_thai_nt', 'Renew'),
            'H',
            NULL,
            NOW(), NOW()
        );
        v_total := v_total + 1;
    END LOOP;

    RETURN jsonb_build_object(
        'status', 'ok',
        'success_message', 'Đã chốt danh sách đăng ký tháng ' || to_char(v_thang, 'MM/YYYY') || ' thành công! Đang chờ Quản lý phê duyệt.',
        'tong_so_nt', v_total,
        'da_bo_qua', v_skipped
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('status', 'error', 'message', SQLERRM);
END;
$$;
