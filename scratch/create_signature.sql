-- Table: public.form_claim_chi_phi_internal_signature_form

-- DROP TABLE IF EXISTS public.form_claim_chi_phi_internal_signature_form;

CREATE TABLE IF NOT EXISTS public.form_claim_chi_phi_internal_signature_form
(
    id text COLLATE pg_catalog."default",
    manv text COLLATE pg_catalog."default",
    ky_chi_phi_kt timestamp without time zone,
    js_value jsonb,
    inserted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE IF EXISTS public.form_claim_chi_phi_internal_signature_form
    OWNER to subiteam;

-- Function
CREATE OR REPLACE FUNCTION public.insert_form_claim_chi_phi_internal_signature_form(input_json jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_json_record JSONB;
BEGIN
    SELECT input_json->0 INTO v_json_record;

    -- Upsert logic: first delete if exists, then insert
    DELETE FROM public.form_claim_chi_phi_internal_signature_form
    WHERE id = (v_json_record->>'id')::text;

    INSERT INTO public.form_claim_chi_phi_internal_signature_form (
        id, manv, ky_chi_phi_kt, js_value, inserted_at
    )
    VALUES (
        (v_json_record->>'id')::text,
        (v_json_record->>'manv')::text,
        (v_json_record->>'ky_chi_phi_kt')::timestamp,
        (v_json_record->>'js_value')::jsonb,
        COALESCE((v_json_record->>'inserted_at')::timestamp, CURRENT_TIMESTAMP)
    );

    RETURN jsonb_build_object(
        'status', 'ok',
        'success_message', 'Đã nhận thành công'
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'status', 'fail',
            'error_message', SQLERRM
        );
END;
$function$;
