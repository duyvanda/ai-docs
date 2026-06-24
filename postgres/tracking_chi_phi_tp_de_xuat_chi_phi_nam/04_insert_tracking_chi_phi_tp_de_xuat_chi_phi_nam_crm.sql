/*
CRM submit form đề xuất chi phí năm. Upsert vào bảng tracking. Validate tổng tiền.
*/
CREATE OR REPLACE FUNCTION public.insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_crm(json_input jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_check_1 INT := 0;
    v_err_msg TEXT;
BEGIN
    /* ==============================================================
       1 & 2. PARSE INPUT & TẠO TEMP TABLE 
       ============================================================== */
    CREATE TEMP TABLE input_raw ON COMMIT DROP AS (
        SELECT 
            (el->>'id')::text AS id,
            (el->>'custid')::text AS custid,
            (el->>'hoat_dong_id')::text AS hoat_dong_id,
            (el->>'ten_hoat_dong')::text AS ten_hoat_dong,
            (el->>'manv_crm')::text AS manv_crm,
            (el->>'so_tien_de_xuat')::numeric AS so_tien_de_xuat,
            (el->>'ghi_chu')::text AS ghi_chu,
            'H'::text AS status,
            (el->>'applyfor')::date AS applyfor,
            COALESCE((el->>'inserted_at')::timestamp, CURRENT_TIMESTAMP) AS inserted_at
        FROM jsonb_array_elements(json_input) AS el
        -- Bỏ qua nếu so_tien_de_xuat là NULL hoặc 0 để không insert dòng rác
        WHERE (el->>'so_tien_de_xuat')::numeric > 0 
    );

    /* ==============================================================
       3. TẠO CÁC TEMP TABLE XỬ LÝ BỔ SUNG (Tính tổng đề xuất hiện tại)
       ============================================================== */
    -- Tính tổng đề xuất của request này theo KH
    CREATE TEMP TABLE calc_request_summary ON COMMIT DROP AS
    SELECT 
        custid, 
        applyfor,
        SUM(so_tien_de_xuat) AS total_request
    FROM input_raw
    GROUP BY custid, applyfor;

    -- Lấy tổng tiền đã đề xuất trong DB cho những KH này (ngoại trừ các hoạt động đang có trong request)
    CREATE TEMP TABLE calc_db_summary ON COMMIT DROP AS
    SELECT 
        tr.custid,
        tr.applyfor,
        SUM(tr.so_tien_de_xuat) AS total_db
    FROM public.tracking_chi_phi_tp_de_xuat_chi_phi_nam tr
    JOIN (SELECT DISTINCT custid, applyfor FROM calc_request_summary) req 
      ON req.custid = tr.custid AND req.applyfor = tr.applyfor
    -- Bỏ qua các hoạt động nằm trong đợt cập nhật này để không bị double count
    WHERE NOT EXISTS (
        SELECT 1 FROM input_raw i WHERE i.custid = tr.custid AND i.hoat_dong_id = tr.hoat_dong_id
    )
    GROUP BY tr.custid, tr.applyfor;

    -- Gom thông tin ngân sách tổng từ settings
    CREATE TEMP TABLE calc_ngan_sach_tong ON COMMIT DROP AS
    SELECT 
        (el->>'makhdms')::text AS custid,
        SUM((el->>'ngan_sach')::numeric) AS ngan_sach_tong
    FROM public.settings_data s, jsonb_array_elements(s.js->'nt_options') AS el
    WHERE s.appid = 'tracking_chi_phi_tp_de_xuat_chi_phi_nam'
    GROUP BY (el->>'makhdms')::text;

    -- Bảng kết hợp validate (request + db_cũ > ngân_sach)
    CREATE TEMP TABLE validate_ngan_sach ON COMMIT DROP AS
    SELECT 
        r.custid,
        (COALESCE(r.total_request, 0) + COALESCE(d.total_db, 0)) AS total_proposed,
        COALESCE(ns.ngan_sach_tong, 0) AS ngan_sach_tong
    FROM calc_request_summary r
    LEFT JOIN calc_db_summary d ON r.custid = d.custid AND r.applyfor = d.applyfor
    LEFT JOIN calc_ngan_sach_tong ns ON ns.custid = r.custid;

    /* ==============================================================
       4. VALIDATE INPUT CỦA NGƯỜI DÙNG
       ============================================================== */
    -- Kiểm tra vượt ngân sách
    SELECT COUNT(*), MAX('Khách hàng ' || custid || ' vượt ngân sách tổng. (Đề xuất: ' || total_proposed || ' > ' || ngan_sach_tong || ')')
    INTO v_check_1, v_err_msg
    FROM validate_ngan_sach
    WHERE total_proposed > ngan_sach_tong;

    IF v_check_1 > 0 THEN
        RETURN jsonb_build_object(
            'status', 'fail',
            'error_message', v_err_msg
        );
    END IF;

    /* ==============================================================
       5. NẾU PASS → UPSERT DỮ LIỆU
       ============================================================== */
    INSERT INTO public.tracking_chi_phi_tp_de_xuat_chi_phi_nam (
        id, custid, hoat_dong_id, ten_hoat_dong, manv_crm, so_tien_de_xuat, ghi_chu, status, applyfor, inserted_at
    )
    SELECT 
        id, custid, hoat_dong_id, ten_hoat_dong, manv_crm, so_tien_de_xuat, ghi_chu, status, applyfor, inserted_at
    FROM input_raw
    ON CONFLICT (id) DO UPDATE 
    SET 
        so_tien_de_xuat = EXCLUDED.so_tien_de_xuat,
        ghi_chu = EXCLUDED.ghi_chu,
        status = 'H', -- Luôn reset về Hold khi CRM update
        inserted_at = EXCLUDED.inserted_at;

    /* ==============================================================
       6. RETURN JSON SUCCESS
       ============================================================== */
    RETURN jsonb_build_object(
        'status', 'ok',
        'success_message', 'Đã lưu đề xuất thành công.'
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'fail',
        'error_message', SQLERRM
    );
END;
$$;
