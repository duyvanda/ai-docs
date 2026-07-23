/*
Xóa bài thi từ bảng thi_cmsp dựa vào danh sách mã nhân viên (manv).
Có ghi log chi tiết vào s.internal_logs.
API: POST https://bi.meraplion.com/local/post_data/delete_exam_test/
Payload:
[
  {
    "manv": "MR0053",
    "requester": "MR0001"
  }
]
*/
CREATE OR REPLACE FUNCTION public.delete_exam_test(json_input jsonb)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    p_requester TEXT;
    v_check_empty INT := 0;
    v_check_exist INT := 0;
    v_deleted_count INT := 0;
    v_deleted_employees INT := 0;
    v_target_manv TEXT;
    v_deleted_json JSONB;
    v_success_msg TEXT;
BEGIN
    /* ==============================================================
       1. PARSE INPUT & TẠO TEMP TABLE
       ============================================================== */
    -- Lấy requester từ phần tử đầu tiên
    SELECT json_input->0->>'requester' INTO p_requester;

    CREATE TEMP TABLE input_raw ON COMMIT DROP AS (
        SELECT DISTINCT (el->>'manv')::text AS manv
        FROM jsonb_array_elements(json_input) AS el
        WHERE el->>'manv' IS NOT NULL AND el->>'manv' <> ''
    );

    /* ==============================================================
       2. VALIDATION
       ============================================================== */
    -- Kiểm tra danh sách nhân viên cần xóa
    SELECT COUNT(*) INTO v_check_empty FROM input_raw;
    IF v_check_empty = 0 THEN
        RETURN jsonb_build_object(
            'status', 'fail',
            'error_message', 'Danh sách mã nhân viên cần xóa trống hoặc không hợp lệ.'
        );
    END IF;

    -- Kiểm tra requester
    IF p_requester IS NULL OR p_requester = '' THEN
        RETURN jsonb_build_object(
            'status', 'fail',
            'error_message', 'Thiếu thông tin người yêu cầu xóa (requester).'
        );
    END IF;

    -- Kiểm tra sự tồn tại của các bài thi cần xóa (đếm số dòng)
    SELECT COUNT(*) INTO v_check_exist
    FROM public.thi_cmsp t
    JOIN input_raw i ON t.manv = i.manv;

    IF v_check_exist = 0 THEN
        RETURN jsonb_build_object(
            'status', 'fail',
            'error_message', 'Không tìm thấy bài thi nào của các nhân viên đã nhập để xóa.'
        );
    END IF;

    -- Đếm số nhân viên thực tế có bài thi bị xóa
    SELECT COUNT(DISTINCT t.manv) INTO v_deleted_employees
    FROM public.thi_cmsp t
    JOIN input_raw i ON t.manv = i.manv;

    /* ==============================================================
       3. LẤY DỮ LIỆU SẮP XÓA ĐỂ GHI LOG
       ============================================================== */
    SELECT COALESCE(jsonb_agg(t), '[]'::jsonb) INTO v_deleted_json
    FROM public.thi_cmsp t
    WHERE t.manv IN (SELECT manv FROM input_raw);

    /* ==============================================================
       4. GHI LOG VÀO S.INTERNAL_LOGS
       ============================================================== */
    INSERT INTO s.internal_logs (manv, result_name, js_value, inserted_at)
    VALUES (
        p_requester, 
        'thi_cmsp', 
        jsonb_build_object(
            'requester', p_requester,
            'deleted_data', v_deleted_json
        ), 
        CURRENT_TIMESTAMP
    );

    /* ==============================================================
       5. THỰC HIỆN XÓA
       ============================================================== */
    DELETE FROM public.thi_cmsp
    WHERE manv IN (SELECT manv FROM input_raw);

    -- Lấy số dòng đã xóa thực tế
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

    -- Thiết lập thông báo thành công dựa trên số lượng nhân viên
    IF v_deleted_employees = 1 THEN
        SELECT MIN(manv) INTO v_target_manv FROM input_raw;
        v_success_msg := 'Đã xóa thành công bài thi của nhân viên ' || v_target_manv || ' (' || v_deleted_count || ' dòng) và ghi log.';
    ELSE
        v_success_msg := 'Đã xóa thành công bài thi của ' || v_deleted_employees || ' nhân viên (' || v_deleted_count || ' dòng) và ghi log.';
    END IF;

    /* ==============================================================
       6. RETURN KẾT QUẢ THÀNH CÔNG
       ============================================================== */
    RETURN jsonb_build_object(
        'status', 'ok',
        'success_message', v_success_msg
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'fail',
        'error_message', SQLERRM
    );
END;
$$;
