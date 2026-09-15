CREATE OR REPLACE FUNCTION get_tracking_chi_phi_tp_medigo_tuyen_nt(
    p_input jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_manv      text;
    v_thang_dk  date;
    v_thang_cu  date;
    v_data      jsonb;
BEGIN
    v_manv     := p_input->>'manv';
    v_thang_dk := date_trunc('month', CURRENT_DATE + interval '1 month')::date;
    v_thang_cu := (v_thang_dk - interval '1 month')::date;

    SELECT jsonb_agg(row_to_json(q)::jsonb) INTO v_data
    FROM (
        SELECT
            p.ma_khachhang as custid,
            COALESCE(m.custname, p.tenkhachhang) as custname,
            COALESCE(m.address, '') as dia_chi_nt,
            p.manv as manv_tdv,
            p.tencvbh as ten_tdv,
            COALESCE(s.ds_thang_cu, 0) as doanh_so_thang_cu_covat,
            COALESCE(s.ds_ytd, 0) as doanh_so_ytd_covat,
            CASE WHEN ex.custid IS NOT NULL THEN true ELSE false END as da_co_trong_danh_sach
        FROM (
            SELECT DISTINCT ON (ma_khachhang) ma_khachhang, tenkhachhang, manv, tencvbh
            FROM api_f_thongtin_tuyen_mcp_tp_pcl
            WHERE supid = v_manv
            ORDER BY ma_khachhang, thang DESC
        ) p
        LEFT JOIN d_master_khachhang m ON m.custid = p.ma_khachhang
        LEFT JOIN (
            SELECT makhdms,
                SUM(CASE WHEN thang = v_thang_cu THEN doanhsocovat ELSE 0 END) as ds_thang_cu,
                SUM(CASE WHEN year = EXTRACT(year FROM v_thang_cu)::int AND thang <= v_thang_cu THEN doanhsocovat ELSE 0 END) as ds_ytd
            FROM f_raw_data_sales_yoy
            WHERE year = EXTRACT(year FROM v_thang_cu)::int
              AND makhdms IN (SELECT DISTINCT ma_khachhang FROM api_f_thongtin_tuyen_mcp_tp_pcl WHERE supid = v_manv)
            GROUP BY makhdms
        ) s ON s.makhdms = p.ma_khachhang
        LEFT JOIN (
            SELECT custid FROM tracking_chi_phi_tp_medigo_dang_ky
            WHERE manv = v_manv AND thang = v_thang_dk
        ) ex ON ex.custid = p.ma_khachhang
        ORDER BY p.ma_khachhang
    ) q;

    RETURN jsonb_build_object(
        'status', 'ok',
        'manv', v_manv,
        'thang_dang_ky', v_thang_dk,
        'nt_options', COALESCE(v_data, '[]'::jsonb)
    );
END;
$$;
