/*
Lấy Mã KH + Tên KH từ bảng d_master_khachhang theo mã khách hàng truyền vào.
*/
CREATE OR REPLACE FUNCTION public.get_ma_ten_khach_hang(url_param jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    p_custid text := url_param->>'custid';
BEGIN
    RETURN (
        WITH rows_data AS (
            SELECT 
                kh.custid,
                kh.custname
            FROM public.d_master_khachhang kh
            --WHERE kh.custid = p_custid
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
