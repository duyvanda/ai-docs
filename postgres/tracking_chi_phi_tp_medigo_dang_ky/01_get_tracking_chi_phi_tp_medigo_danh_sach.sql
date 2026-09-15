CREATE OR REPLACE FUNCTION get_tracking_chi_phi_tp_medigo_danh_sach(
    p_input jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_manv           text;
    v_ma_crm         text;
    v_ten_crm        text;
    v_thang_dk       date;
    v_thang_cu       date;
    v_data           jsonb;
    v_tong_so_nt     int;
    v_tong_so_luot   int;
    v_has_new_month  boolean;
BEGIN
    -- Parse input
    v_manv := p_input->>'manv';

    -- 1. Lấy thông tin CRM từ d_users
    SELECT manv, tencvbh
    INTO v_ma_crm, v_ten_crm
    FROM d_users
    WHERE manv = v_manv
    LIMIT 1;

    IF v_ma_crm IS NULL THEN
        RETURN jsonb_build_object('status', 'error', 'message', 'Không tìm thấy nhân viên: ' || v_manv);
    END IF;

    -- 2. Xác định tháng đăng ký (mặc định = tháng tiếp theo)
    IF p_input->>'thang_dang_ky' IS NOT NULL THEN
        v_thang_dk := date_trunc('month', (p_input->>'thang_dang_ky')::date)::date;
    ELSE
        v_thang_dk := date_trunc('month', CURRENT_DATE + interval '1 month')::date;
    END IF;
    v_thang_cu := (v_thang_dk - interval '1 month')::date;

    -- 3. Kiểm tra đã có dữ liệu tháng mới chưa
    SELECT EXISTS(
        SELECT 1 FROM tracking_chi_phi_tp_medigo_dang_ky
        WHERE manv = v_ma_crm AND thang = v_thang_dk
    ) INTO v_has_new_month;

    IF NOT v_has_new_month THEN
        -- Case 1: Chưa có -> Lấy dữ liệu tháng cũ để gợi ý Renew
        SELECT jsonb_agg(row_to_json(q)::jsonb) INTO v_data
        FROM (
            SELECT
                t.thang,
                t.custid,
                t.custname,
                COALESCE(m.address, '') as dia_chi_nt,
                t.thoi_gian_mo_cua,
                t.sdt_nha_thuoc,
                t.ten_dai_dien_nt,
                p.manv as manv_tdv,
                p.tencvbh as ten_tdv,
                t.sdt_tdv,
                t.so_luot_dang_ky,
                t.so_luot_su_dung,
                t.phan_tram_used,
                COALESCE(s.ds_thang_cu, 0) as doanh_so_thang_cu_covat,
                COALESCE(s.ds_ytd, 0) as doanh_so_ytd_covat,
                t.ghi_chu,
                'Renew' as trang_thai_nt,
                null::text as status,
                null::text as ly_do_tu_choi,
                null::integer as so_luot_dang_ky_thang_cu,
                null::integer as so_luot_su_dung_thang_cu
            FROM tracking_chi_phi_tp_medigo_dang_ky t
            LEFT JOIN d_master_khachhang m ON m.custid = t.custid
            LEFT JOIN (
                SELECT DISTINCT ON (ma_khachhang) ma_khachhang, manv, tencvbh
                FROM api_f_thongtin_tuyen_mcp_tp_pcl
                WHERE supid = v_ma_crm
                ORDER BY ma_khachhang, thang DESC
            ) p ON p.ma_khachhang = t.custid
            LEFT JOIN (
                SELECT makhdms,
                    SUM(CASE WHEN thang = v_thang_cu THEN doanhsocovat ELSE 0 END) as ds_thang_cu,
                    SUM(CASE WHEN year = EXTRACT(year FROM v_thang_cu)::int AND thang <= v_thang_cu THEN doanhsocovat ELSE 0 END) as ds_ytd
                FROM f_raw_data_sales_yoy
                WHERE year = EXTRACT(year FROM v_thang_cu)::int
                GROUP BY makhdms
            ) s ON s.makhdms = t.custid
            WHERE t.manv = v_ma_crm AND t.thang = v_thang_cu AND t.status != 'Stop'
            ORDER BY t.custid
        ) q;
    ELSE
        -- Case 2: Đã có -> Lấy dữ liệu tháng mới + bổ sung so sánh tháng cũ
        SELECT jsonb_agg(row_to_json(q)::jsonb) INTO v_data
        FROM (
            SELECT
                t.thang,
                t.custid,
                t.custname,
                COALESCE(m.address, '') as dia_chi_nt,
                t.thoi_gian_mo_cua,
                t.sdt_nha_thuoc,
                t.ten_dai_dien_nt,
                p.manv as manv_tdv,
                p.tencvbh as ten_tdv,
                t.sdt_tdv,
                t.so_luot_dang_ky,
                t.ghi_chu,
                t.trang_thai_nt,
                t.status,
                t.ly_do_tu_choi,
                old.so_luot_dang_ky as so_luot_dang_ky_thang_cu,
                old.so_luot_su_dung as so_luot_su_dung_thang_cu,
                old.phan_tram_used as phan_tram_used,
                COALESCE(s.ds_thang_cu, 0) as doanh_so_thang_cu_covat,
                COALESCE(s.ds_ytd, 0) as doanh_so_ytd_covat
            FROM tracking_chi_phi_tp_medigo_dang_ky t
            LEFT JOIN d_master_khachhang m ON m.custid = t.custid
            LEFT JOIN (
                SELECT DISTINCT ON (ma_khachhang) ma_khachhang, manv, tencvbh
                FROM api_f_thongtin_tuyen_mcp_tp_pcl
                WHERE supid = v_ma_crm
                ORDER BY ma_khachhang, thang DESC
            ) p ON p.ma_khachhang = t.custid
            LEFT JOIN tracking_chi_phi_tp_medigo_dang_ky old ON old.custid = t.custid AND old.thang = v_thang_cu
            LEFT JOIN (
                SELECT makhdms,
                    SUM(CASE WHEN thang = v_thang_cu THEN doanhsocovat ELSE 0 END) as ds_thang_cu,
                    SUM(CASE WHEN year = EXTRACT(year FROM v_thang_cu)::int AND thang <= v_thang_cu THEN doanhsocovat ELSE 0 END) as ds_ytd
                FROM f_raw_data_sales_yoy
                WHERE year = EXTRACT(year FROM v_thang_cu)::int
                GROUP BY makhdms
            ) s ON s.makhdms = t.custid
            WHERE t.manv = v_ma_crm AND t.thang = v_thang_dk
            ORDER BY t.custid
        ) q;
    END IF;

    SELECT COALESCE(jsonb_array_length(v_data), 0),
           COALESCE((SELECT SUM((x->>'so_luot_dang_ky')::int) FROM jsonb_array_elements(COALESCE(v_data,'[]'::jsonb)) x), 0)
    INTO v_tong_so_nt, v_tong_so_luot;

    RETURN jsonb_build_object(
        'status', 'ok',
        'ma_crm', v_ma_crm,
        'ten_crm', v_ten_crm,
        'thang_dang_ky', v_thang_dk,
        'thang_cu', v_thang_cu,
        'tong_so_nt', v_tong_so_nt,
        'tong_so_luot', v_tong_so_luot,
        'data', COALESCE(v_data, '[]'::jsonb)
    );
END;
$$;
