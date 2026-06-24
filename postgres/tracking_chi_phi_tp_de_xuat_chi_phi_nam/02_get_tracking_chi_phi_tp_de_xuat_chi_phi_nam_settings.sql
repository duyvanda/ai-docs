/*
Lấy cấu hình hệ thống (settings) cho đề xuất chi phí năm.
*/
CREATE OR REPLACE FUNCTION public.get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings(url_param jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    p_appid text := 'tracking_chi_phi_tp_de_xuat_chi_phi_nam';
BEGIN
    RETURN (
        WITH rows_data AS (
            SELECT 
                appid,
                manv,
                inserted_at,
                applyfor,
                js AS settings_data
            FROM public.settings_data
            WHERE appid = p_appid
        )
        SELECT jsonb_build_object(
            'status', 'ok',
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
