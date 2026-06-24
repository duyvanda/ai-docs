/*
Lấy danh sách Khách hàng và các hoạt động đầu tư được phép đề xuất dành cho CRM.
*/
CREATE OR REPLACE FUNCTION local.get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm(url_param jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    p_manv text := url_param->>'manv';
    v_chucdanh text;
BEGIN
    -- Lấy chức danh user
    SELECT chucdanhengtitlesum INTO v_chucdanh
    FROM public.d_hr_dsns
    WHERE msnvcsmmoi = p_manv;

    RETURN (
        WITH settings AS (
            SELECT applyfor, js
            FROM public.settings_data
            WHERE appid = 'tracking_chi_phi_tp_de_xuat_chi_phi_nam'
            LIMIT 1
        ),
        nt_options_raw AS (
            SELECT 
                s.applyfor,
                (el->>'makhdms')::text AS makhdms,
                (el->>'ten_kh')::text AS ten_kh,
                (el->>'ma_crm')::text AS ma_crm,
                (el->>'ten_crm')::text AS ten_crm,
                (el->>'ngan_sach')::numeric AS ngan_sach,
                (el->>'hoat_dong_id')::text AS hoat_dong_id,
                (el->>'ten_hoat_dong')::text AS ten_hoat_dong,
                (el->>'ngan_sach_uoc_luong')::numeric AS ngan_sach_uoc_luong
            FROM settings s, jsonb_array_elements(s.js->'nt_options') AS el
        ),
        nt_options_filtered AS (
            SELECT n.*
            FROM nt_options_raw n
            -- Filter theo quy định STRPOS: CRM chỉ thấy data của chính mình hoặc cấp dưới
            -- Giả định ma_crm trong settings_data map với d_users.supid hoặc d_users.manv
            LEFT JOIN public.d_users u ON u.supid = n.ma_crm OR u.manv = n.ma_crm
            WHERE STRPOS(COALESCE(u.manv, '') || COALESCE(u.supid, ''), p_manv) > 0
               OR n.ma_crm = p_manv
            GROUP BY n.applyfor, n.makhdms, n.ten_kh, n.ma_crm, n.ten_crm, n.ngan_sach, n.hoat_dong_id, n.ten_hoat_dong, n.ngan_sach_uoc_luong
        ),
        rows_data AS (
            SELECT 
                nt.makhdms,
                nt.ten_kh,
                kh.statedescr AS tinh,
                nt.ngan_sach,
                nt.hoat_dong_id,
                nt.ten_hoat_dong,
                nt.ngan_sach_uoc_luong,
                tr.so_tien_de_xuat,
                tr.ghi_chu,
                tr.status
            FROM nt_options_filtered nt
            LEFT JOIN public.d_master_khachhang kh ON kh.custid = nt.makhdms
            LEFT JOIN public.tracking_chi_phi_tp_de_xuat_chi_phi_nam tr 
                   ON tr.custid = nt.makhdms 
                  AND tr.hoat_dong_id = nt.hoat_dong_id
                  AND tr.applyfor::date = nt.applyfor::date
        )
        SELECT jsonb_build_object(
            'status', 'ok',
            'chucdanhengtitlesum', v_chucdanh,
            'applyfor', (SELECT applyfor FROM settings),
            'nt_options', COALESCE((SELECT jsonb_agg(f) FROM rows_data f), '[]'::jsonb)
        )
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'fail',
        'error_message', SQLERRM
    );
END;
$$;
