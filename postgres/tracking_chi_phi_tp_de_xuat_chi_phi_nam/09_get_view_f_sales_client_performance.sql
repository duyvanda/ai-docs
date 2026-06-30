/*
Lấy toàn bộ cột từ bảng view_f_sales_client_performance theo custid, từ ngày (from_date), đến ngày (to_date).
*/
CREATE OR REPLACE FUNCTION public.get_view_f_sales_client_performance(url_param jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    p_custid text := url_param->>'custid';
    p_from_date text := url_param->>'from_date';
    p_to_date text := url_param->>'to_date';
BEGIN
    RETURN (
        WITH rows_data AS (
            SELECT 
                thang,
                makenhkh,
                manv,
                ma_crm,
                ma_scrm,
                ma_ncxm,
                tencvbh,
                tenquanlytt,
                tenquanlykhuvuc,
                tenquanlyvung,
                macongtycn,
                ngaychungtu,
                ngaydatdon,
                ngaygiaohang,
                sodondathang,
                makhdms,
                makhcu,
                tenkhachhang,
                ma_ten_kh,
                tentinhkh,
                makenhphu,
                masanpham,
                tensanphamnb,
                tensanphamviettat,
                soluong,
                doanhsochuavat,
                custid,
                quan,
                addr1,
                lat,
                lng,
                latlong,
                datatype,
                link,
                mst_tracuu,
                trangthai,
                thoigianhieuluc,
                sodienthoai,
                active,
                inactive,
                billmarket,
                businessscope,
                check_tinh_trang_ban_hang_theo_mst,
                phan_loai_xet_gdp,
                tinh_trang_gdp,
                row_
            FROM public.view_f_sales_client_performance
            WHERE custid = p_custid
              AND (p_from_date IS NULL OR p_from_date = '' OR ngaychungtu >= p_from_date::timestamp)
              AND (p_to_date IS NULL OR p_to_date = '' OR ngaychungtu <= p_to_date::timestamp)
            ORDER BY ngaychungtu DESC
        )
        SELECT jsonb_build_object(
            'status', 'ok',
            'rows', (SELECT COUNT(*) FROM rows_data),
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
