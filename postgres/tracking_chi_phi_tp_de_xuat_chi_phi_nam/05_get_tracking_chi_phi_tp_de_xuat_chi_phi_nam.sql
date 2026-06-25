/*
Lấy toàn bộ danh sách chi phí đề xuất (Dùng chung cho List Data - CRD, CXD duyệt)
*/
CREATE OR REPLACE FUNCTION public.get_tracking_chi_phi_tp_de_xuat_chi_phi_nam(url_param jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    p_manv text := url_param->>'manv';
    p_status text := url_param->>'status';
    v_chucdanh text;
BEGIN
    SELECT chucdanhengtitlesum INTO v_chucdanh
    FROM public.d_hr_dsns
    WHERE msnvcsmmoi = p_manv;

    RETURN (
        WITH calc_ngan_sach_tong AS (
            SELECT 
                (el->>'makhdms')::text AS custid,
                SUM((el->>'ngan_sach')::numeric) AS ngan_sach
            FROM public.settings_data s, jsonb_array_elements(s.js->'nt_options') AS el
            WHERE s.appid = 'tracking_chi_phi_tp_de_xuat_chi_phi_nam'
            GROUP BY (el->>'makhdms')::text
        ),
        hoat_dong_options AS (
            SELECT 
                (el->>'hoat_dong_id')::text AS hoat_dong_id,
                (el->>'loai')::text AS loai_hoat_dong
            FROM public.settings_data s, jsonb_array_elements(s.js->'hoat_dong_options') AS el
            WHERE s.appid = 'tracking_chi_phi_tp_de_xuat_chi_phi_nam'
        ),
        rows_data AS (
            SELECT 
                tr.id,
                tr.custid,
                kh.custname,
                kh.statedescr,
                tr.manv_crm,
                u.tencvbh AS ten_crm,
                ns.ngan_sach,
                tr.hoat_dong_id,
                hd.loai_hoat_dong,
                tr.ten_hoat_dong,
                tr.so_tien_de_xuat,
                tr.ghi_chu,
                tr.cx_note,
                tr.so_tien_duyet_crd,
                tr.so_tien_duyet_cxd,
                tr.status,
                tr.ly_do_tu_choi,
                tr.applyfor,
                tr.inserted_at,
                tr.crd_approved_at,
                tr.crd_approved_manv,
                tr.cxd_approved_at,
                tr.cxd_approved_manv
            FROM public.tracking_chi_phi_tp_de_xuat_chi_phi_nam tr
            LEFT JOIN public.d_master_khachhang kh ON kh.custid = tr.custid
            LEFT JOIN public.d_users u ON u.manv = tr.manv_crm
            LEFT JOIN calc_ngan_sach_tong ns ON ns.custid = tr.custid
            LEFT JOIN hoat_dong_options hd ON hd.hoat_dong_id = tr.hoat_dong_id
            WHERE (p_status IS NULL OR p_status = '' OR tr.status = p_status)
              AND (
                  p_manv IS NULL OR p_manv = '' OR
                  STRPOS(COALESCE(u.manv, '') || COALESCE(u.supid, '') || COALESCE(u.asm, '') || COALESCE(u.rsmid, ''), p_manv) > 0
                  OR v_chucdanh ILIKE '%CX%' 
                  OR v_chucdanh ILIKE '%ADMIN%'
              )
        )
        SELECT jsonb_build_object(
            'status', 'ok',
            'rows', (SELECT COUNT(*) FROM rows_data),
            'chucdanhengtitlesum', v_chucdanh,
            'data', COALESCE((SELECT jsonb_agg(f) FROM rows_data f), '[]'::jsonb)
        )
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'fail',
        'error_message', SQLERRM
    );
END;
$$;
