/* ==============================================================
   TRACKING CHI PHI TP — ĐỀ XUẤT CHI PHÍ NĂM
   Script: Tạo tables + Settings Functions
   ============================================================== */


/* ==============================================================
   TABLE: settings_data
   Bảng cấu hình All-in-One, dùng chung cho nhiều module.
   PK composite (appid, applyfor) — mỗi module x năm là 1 bản ghi.
   ============================================================== */
CREATE TABLE IF NOT EXISTS public.settings_data (
    appid       text      NOT NULL,
    js          jsonb,
    manv        text,
    inserted_at timestamp,
    applyfor    timestamp,
    CONSTRAINT settings_data_pkey PRIMARY KEY (appid, applyfor)
);


/* ==============================================================
   TABLE: tracking_chi_phi_tp_de_xuat_chi_phi_nam
   Mỗi dòng = 1 đề xuất chi phí của CRM cho cặp (KH, hoạt động).
   Unique constraint: (custid, appid, applyfor).
   ============================================================== */
CREATE TABLE IF NOT EXISTS public.tracking_chi_phi_tp_de_xuat_chi_phi_nam (
    uuid            text      NOT NULL,
    custid          text,
    appid           text,
    manv_crm        text,
    so_tien_de_xuat numeric,
    so_tien_duyet   numeric,
    status          text,
    applyfor        date,
    inserted_at     timestamp DEFAULT (NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh'),
    ly_do_tu_choi   text,
    approved_at     timestamp,
    approved_manv   text,
    CONSTRAINT tracking_chi_phi_tp_de_xuat_chi_phi_nam_pkey   PRIMARY KEY (uuid),
    CONSTRAINT tracking_chi_phi_tp_de_xuat_chi_phi_nam_unique UNIQUE (custid, appid, applyfor)
);


/* ==============================================================
   FUNCTION: insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings
   CX upload cấu hình: danh sách KH, hoạt động, ngân sách theo năm.
   Upsert dựa trên (appid, applyfor).
   Validate: người thực hiện phải có chức danh CX.
   ============================================================== */
CREATE OR REPLACE FUNCTION public.insert_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings(
    json_input jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    /* input params */
    p_appid       text;
    p_manv        text;
    p_inserted_at timestamp;
    p_applyfor    timestamp;

    /* validation flag */
    v_check_role  int := 0;
BEGIN
    /* ==============================================================
       1. PARSE INPUT FIELDS TỪ JSON
       ============================================================== */
    p_appid       := json_input->0->>'appid';
    p_manv        := json_input->0->>'manv';
    p_inserted_at := (json_input->0->>'inserted_at')::timestamp;
    p_applyfor    := (json_input->0->>'applyfor')::timestamp;

    /* ==============================================================
       2. TẠO TEMP TABLE RAW INPUT
       ============================================================== */
    CREATE TEMP TABLE raw_input ON COMMIT DROP AS
    SELECT
        p_appid                                 AS appid,
        (json_input->0->'settings_data')::jsonb AS js,
        p_manv                                  AS manv,
        p_inserted_at                           AS inserted_at,
        p_applyfor                              AS applyfor
    ;

    /* ==============================================================
       3. VALIDATE: Kiểm tra quyền CX
       ============================================================== */
    SELECT COUNT(*) INTO v_check_role
    FROM d_hr_dsns
    WHERE msnvcsmmoi = p_manv
      AND STRPOS(chucdanhengtitlesum, 'CX') > 0;

    IF v_check_role = 0 THEN
        RETURN jsonb_build_object(
            'status',        'fail',
            'error_message', 'Bạn không có quyền thực hiện thao tác này.'
        );
    END IF;

    /* ==============================================================
       4. UPSERT VÀO settings_data
       ============================================================== */
    INSERT INTO public.settings_data (appid, js, manv, inserted_at, applyfor)
    SELECT appid, js, manv, inserted_at, applyfor
    FROM raw_input
    ON CONFLICT (appid, applyfor)
    DO UPDATE SET
        js          = EXCLUDED.js,
        manv        = EXCLUDED.manv,
        inserted_at = EXCLUDED.inserted_at;

    /* ==============================================================
       5. RETURN SUCCESS
       ============================================================== */
    RETURN jsonb_build_object(
        'status',          'ok',
        'success_message', 'Cập nhật cấu hình thành công.'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'status',        'fail',
            'error_message', SQLERRM
        );
END;
$$;


/* ==============================================================
   FUNCTION: get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings
   Lấy cấu hình mới nhất theo appid.
   Output: giống cấu trúc input của insert settings.
   ============================================================== */
CREATE OR REPLACE FUNCTION public.get_tracking_chi_phi_tp_de_xuat_chi_phi_nam_settings(
    url_param jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    p_appid text;
    p_manv  text;
BEGIN
    /* ==============================================================
       1. PARSE INPUT
       ============================================================== */
    p_appid := url_param->>'appid';
    p_manv  := url_param->>'manv';

    /* ==============================================================
       2. QUERY & RETURN
       ============================================================== */
    RETURN (
        WITH latest AS (
            /* Lấy bản ghi mới nhất theo inserted_at */
            SELECT
                appid,
                js,
                manv,
                inserted_at,
                applyfor
            FROM public.settings_data
            WHERE appid = p_appid
            ORDER BY inserted_at DESC
        ),
        rows_data AS (
            SELECT
                appid,
                js                                               AS settings_data,
                manv,
                TO_CHAR(inserted_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS inserted_at,
                TO_CHAR(applyfor,    'YYYY-MM-DD"T"HH24:MI:SS') AS applyfor
            FROM latest
        )
        SELECT jsonb_build_object(
            'status', 'ok',
            'data',   COALESCE((SELECT jsonb_agg(f) FROM rows_data f), '[]'::jsonb)
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'status',        'fail',
            'error_message', SQLERRM
        );
END;
$$;
