\t on
\a
\o 'd:/ai-docs/scratch/function_defs.txt'
SELECT pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' AND p.proname IN (
    'get_form_claim_chi_phi',
    'insert_form_claim_chi_phi',
    'get_form_claim_chi_phi_crm',
    'insert_form_claim_chi_phi_crm',
    'get_form_claim_chi_phi_crm_approved',
    'get_form_claim_chi_phi_hoa_don_misa',
    'insert_form_claim_chi_phi_hoa_don',
    'get_form_claim_chi_phi_crm_claimed',
    'insert_form_claim_chi_phi_crm_claimed',
    'insert_form_cong_tac_phi',
    'get_form_claim_chi_phi_excel_form',
    'insert_form_claim_chi_phi_chung_tu',
    'get_form_claim_chi_phi_history'
);
\o
