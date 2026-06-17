/**
* ────────────────────────────────────────────────────────────────────
* RecordZeroActions
* RecordZeroActions class
* ────────────────────────────────────────────────────────────────────
* @author      Olatz Urrutia <olatz.urrutia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-04-13
* @modified
* @systemLayer Business
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, sf:TooManyMethods')
public with sharing class CSTK_RecordZeroActions implements Database.Batchable<sObject> {

    private static Map<String, List<String>> recordZeroFields = new Map<String, List<String>>{
        'cstk__General_Data__c' => new List<String>{'cstk__tri_date__c', 'cstk__gf_auto_sector_c_trns_strg_score_number__c', 'cstk__gf_mix_tc_em_p_c_st_ats_cta_s_sc_number__c', 'cstk__gf_ctrs_low_cb_pl_rk_ats_cta_s_sc_number__c', 'cstk__gf_c_group_trns_plan_ats_cta_s_sc_number__c', 'cstk__gf_auto_sector_tri_score_number__c', 'cstk__gf_auto_sector_tri_final_score_number__c', 'cstk__gf_auto_sc_tri_final_score_label_desc__c', 'cstk__gf_cement_sector_c_trns_strg_sc_number__c', 'cstk__gf_mix_tc_em_p_c_st_cs_cta_s_sc_number__c', 'cstk__gf_ctrs_low_cb_pls_rk_cs_cta_s_sc_number__c', 'cstk__gf_c_group_trns_plan_cs_cta_s_sc_number__c', 'cstk__gf_cement_sector_tri_score_number__c', 'cstk__gf_cement_sector_tri_final_score_number__c', 'cstk__gf_cement_sc_tri_final_score_label_desc__c', 'cstk__gf_steel_sector_c_trns_strg_score_number__c', 'cstk__gf_mix_tc_em_p_c_st_ss_cta_s_sc_number__c', 'cstk__gf_ctrs_low_cb_pls_rk_ss_cta_s_sc_number__c', 'cstk__gf_c_group_trns_plan_ss_cta_s_sc_number__c', 'cstk__gf_steel_sector_tri_score_number__c', 'cstk__gf_steel_sector_tri_final_score_number__c', 'cstk__gf_steel_sc_tri_final_score_label_desc__c', 'cstk__gf_utilities_sc_c_trns_strg_score_number__c', 'cstk__gf_mix_tc_em_p_c_st_us_cta_s_sc_number__c', 'cstk__gf_ctrs_low_cb_pls_rk_us_cta_s_sc_number__c', 'cstk__gf_c_group_trns_plan_us_cta_s_sc_number__c', 'cstk__gf_utilities_sector_tri_score_number__c', 'cstk__gf_utilities_sc_tri_final_score_number__c', 'cstk__gf_utilities_sc_tri_final_sc_label_desc__c', 'cstk__gf_oil_gas_sc_c_cl_trns_strg_sc_number__c', 'cstk__gf_mix_tc_em_p_cur_st_es_cta_s_sc_number__c', 'cstk__gf_ctrs_low_cb_pls_rk_es_cta_s_sc_number__c', 'cstk__gf_c_group_trns_plan_es_cta_s_sc_number__c', 'cstk__gf_energy_sector_tri_score_number__c', 'cstk__gf_energy_sector_tri_final_score_number__c', 'cstk__gf_energy_sc_tri_final_score_label_desc__c','cstk__gf_controversies_geographic_insight_desc__c','cstk__gf_controversies_sector_insight_desc__c','cstk__average_esg_rating__c', 'cstk__cca__c', 'cstk__cta__c', 'cstk__date__c', 'cstk__executive_bonus__c', 'cstk__g_esg_controversy_comnt_desc__c', 'cstk__g_esg_controversy_event_type__c', 'cstk__g_esg_controversy_outlook_type__c', 'cstk__green_sales_pct__c', 'cstk__has_climate_committee__c', 'cstk__social_sales_pct__c', 'cstk__source__c', 'cstk__sustainability_report__c', 'cstk__sustainability_report_link__c', 'cstk__tfdc_reporter__c', 'cstk__tfdc_reporter_link__c', 'cstk__tfdc_supporter__c', 'cstk__tri__c', 'cstk__tri_assessment__c', 'cstk__gf_cca_sc_cl_govn_tcfd_number__c', 'cstk__gf_cca_sc_cl_trgt_tcfd_number__c', 'cstk__gf_cca_sc_rk_mgmt_tcfd_number__c', 'cstk__gf_cca_sc_strg_tcfd_number__c', 'cstk__gf_cta_rk_sc_low_cb_pcy_number__c', 'cstk__gf_cta_sc_em_profl_tec_number__c', 'cstk__gf_cta_trns_sc_pl_number__c', 'cstk__g_enrg_stor_batt_inv_type__c', 'cstk__g_carbon_capture_inv_type__c', 'cstk__g_e_ve_chrg_infr_inv_type__c', 'cstk__g_hydr_prod_inv_type__c', 'cstk__tri_valuation__c', 'cstk__gf_l_1_sdm_esg_evts_cont_nat_cnc_desc__c', 'cstk__gf_l_2_sdm_esg_evts_cont_nat_cnc_desc__c','cstk__gf_l_3_sdm_esg_evts_cont_nat_cnc_desc__c','cstk__gf_l_4_sdm_esg_evts_cont_nat_cnc_desc__c','cstk__gf_l_5_sdm_esg_evts_cont_nat_cnc_desc__c','cstk__gf_l_3_sdm_esg_outlook_cont_nat_cnc_desc__c','cstk__gf_l_4_sdm_esg_outlook_cont_nat_cnc_desc__c','cstk__gf_l_5_sdm_esg_outlook_cont_nat_cnc_desc__c', 'cstk__controversy__c','cstk__gf_sdm_esg_evts_controversy_nat_cnc_desc__c','cstk__gf_sdm_esg_events_exp_evo_type_cnc_desc__c', 'cstk__gf_controversies_sector_insight_html__c', 'cstk__gf_controversies_geographic_insight_html__c', 'cstk__g_esg_controversy_comnt_html__c' }, //NOSONAR

        'cstk__Strategy__c' => new List<String>{'cstk__gf_climate_req_supplier_ind_type__c', 'cstk__affected_sector__c', 'cstk__capex_time_horizon_beginning__c', 'cstk__capex_time_horizon_end__c', 'cstk__capex_total__c', 'cstk__date__c', 'cstk__climate_change_risk_opportunity__c', 'cstk__company_affected_by_framework__c', 'cstk__count_due_diligence_on_framework__c', 'cstk__detailed_description__c', 'cstk__engagement_plan__c', 'cstk__g_thermal_coal_exps_ind_type__c', 'cstk__framework_engagement_link__c', 'cstk__how_clients_portfolio_changing__c', 'cstk__source__c', 'cstk__internal_co2_price__c', 'cstk__last_pitch_made_gm__c', 'cstk__last_pitch_made_gtb__c', 'cstk__last_pitch_made_ib_f__c', 'cstk__no_engagement_plan_reason__c', 'cstk__non_compliant_issues__c', 'cstk__other_social_env_factors__c', 'cstk__portfolio_alignment_engagement_link__c', 'cstk__gf_thermal_coal_rev_wg_per__c', 'cstk__suppliers_have_to_meet_reqs__c', 'cstk__g_thermal_coal_exps_i_src_type__c', 'cstk__total_capex_pledged__c', 'cstk__tri_engagement_link__c', 'cstk__gf_thermal_coal_prod_wg_per__c', 'cstk__g_coal_prgrsv_red_pl_ind_type__c', 'cstk__gf_arce_mm_mnty_units_t_anl_capex_amount__c', 'cstk__gf_capex_currency_id__c', 'cstk__gf_total_annual_income_amount__c', 'cstk__gf_arce_total_annual_income_amount__c', 'cstk__gf_total_revenues_currency_id__c', 'cstk__gf_customer_engagement_plan_target_desc__c', 'cstk__gf_customer_approach_type_desc__c', 'cstk__gf_sust_call_to_action_personalized_desc__c', 'cstk__gf_sustainability_objectives_indt_desc__c', 'cstk__gf_sust_objv_comt_plans_monitoring_desc__c', 'cstk__gf_sust_commitment_plan_company_con_desc__c', 'cstk__gf_coal_exit_year_number__c', 'cstk__gf_the_carbon_exps_inf_dsclsr_link_desc__c'}, //NOSONAR

        'cstk__EmissionTarget__c' => new List<String>{'cstk__additional_comments__c', 'cstk__agreement_verified__c', 'cstk__emission_reduction_base_year__c', 'cstk__emission_reduction_target_year__c', 'cstk__date__c', 'cstk__emissions_intensity__c', 'cstk__emissions_tg_intensity_proy5__c', 'cstk__emissions_intensity_units__c', 'cstk__group_alignment_degree__c', 'cstk__link_sbti__c', 'cstk__net_zero_target__c', 'cstk__net_zero_target_date__c', 'cstk__paris_alignment__c', 'cstk__source__c', 'cstk__science_based_target__c', 'cstk__scope__c', 'cstk__sector_alignment_degree__c', 'cstk__target_metric__c', 'cstk__target_pct_reduction__c', 'cstk__target_to_2050__c', 'cstk__validated_by__c', 'cstk__validation_page__c', 'cstk__gf_atm_sc_gp_align_deg_per__c','cstk__gf_ut_sc_gp_align_deg_per__c','cstk__gf_cement_sc_gp_align_deg_per__c','cstk__gf_steel_sc_gp_align_deg_per__c','cstk__gf_energy_sector_group_align_degree_per__c','cstk__gf_steel_sector_scn_proj_ems_int_number__c','cstk__gf_cement_sector_scn_proj_ems_int_number__c','cstk__gf_ut_sector_scn_proj_ems_int_number__c','cstk__gf_energy_sector_scn_proj_ems_int_number__c', 'cstk__gf_energy_sector_nominal_em_amount__c', 'cstk__gf_automotive_sc_scn_proj_ems_int_number__c','cstk__gf_cur_5_y_steel_sc_avg_em_int_me_number__c','cstk__gf_cur_5_y_c_sc_avg_ems_int_me_number__c','cstk__gf_cur_5_y_ut_sc_avg_ems_int_me_number__c','cstk__gf_cur_5_y_enrg_sc_avg_ems_int_me_number__c','cstk__gf_cur_5_y_atm_sc_avg_ems_int_me_number__c','cstk__gf_power_sc_group_intensity_curve_desc__c', 'cstk__gf_pw_sc_bbva_pf_c_crv_int_number_desc__c', 'cstk__gf_og_sector_group_ems_int_curve_desc__c', 'cstk__gf_og_sc_bbva_pf_c_crv_int_number_desc__c', 'cstk__gf_ss_og_group_ems_intensity_curve_desc__c', 'cstk__gf_ss_bbva_pf_c_curve_int_number_desc__c', 'cstk__gf_ss_group_emis_intensity_curve_desc__c', 'cstk__gf_cs_bbva_pf_c_curve_int_number_desc__c', 'cstk__gf_ats_group_ems_intensity_curve_desc__c', 'cstk__gf_ats_bbva_pf_c_curve_int_number_desc__c', 'cstk__gf_avs_group_ems_intensity_curve_desc__c', 'cstk__gf_avs_bbva_pf_c_crv_int_number_desc__c', 'cstk__gf_cst_group_calculable_tri_desc__c', 'cstk__gf_high_trns_risk_ac_customer_ind_type__c', 'cstk__gf_c_profits_hi_wg_gp_ac_h_trns_r_type__c', 'cstk__gf_sc_higher_group_em_intensity_ind_type__c', 'cstk__gf_c_revenues_highest_weight_sector_type__c', 'cstk__gf_high_market_adjustment_entities_desc__c', 'cstk__gf_cust_ead_amount__c', 'cstk__gf_bbva_funding_emissions_number__c', 'cstk__gf_euro_bbva_funding_emissions_number__c',  'cstk__gf_pf_sc_a_euro_bbva_fdg_ems_sbtr_number__c'}, //NOSONAR

        'cstk__Sector_Auto__c' => new List<String>{'cstk__BEV_and_PHEV__c', 'cstk__BEV_and_PHEV_pct__c', 'cstk__Number_ev_platforms__c', 'cstk__Plugin_hybrid_vt_2025__c', 'cstk__date__c', 'cstk__Plugin_hybrid_vt_2030__c', 'cstk__R_D_expend_revenues__c', 'cstk__Total_car_sales__c', 'cstk__Total_car_sales_pct__c', 'cstk__Vehicle_battery_prdct_strtg__c', 'cstk__source__c', 'cstk__gf_bev_phev_5_y_est_trgt_per__c', 'cstk__gf_auto_sector_group_activity_per__c'}, //NOSONAR

        'cstk__Sector_Cement__c' => new List<String>{'cstk__gf_anl_capex_over_tl_rvns_per__c', 'cstk__gf_clinker_factor_per__c', 'cstk__g_cement_bus_mix_div_ind_type__c', 'cstk__gf_red_trgt_2030_em_int_number__c', 'cstk__date__c', 'cstk__gf_red_trgt_b_y_em_ints_number__c', 'cstk__gf_red_trgt_c_y_em_ints_number__c', 'cstk__g_altv_mats_to_cement_ind_type__c', 'cstk__g_carbon_capture_inv_ind_type__c', 'cstk__g_hydr_use_inv_ind_type__c', 'cstk__source__c', 'cstk__comments_low_carbon__c', 'cstk__gf_thermal_subst_rate_per__c', 'cstk__gf_renewable_energy_use_per__c', 'cstk__gf_cement_sector_group_activity_per__c'}, //NOSONAR

        'cstk__Sector_Energy__c' => new List<String>{'cstk__Biofuel_capacity_ot__c', 'cstk__Downstrm_rvn_ot__c', 'cstk__Energy_GHG_intensity__c', 'cstk__Gas_production_ot__c', 'cstk__date__c', 'cstk__Invtmt_battery_strg_capacity__c', 'cstk__Invtmt_carbon_capture_storage__c', 'cstk__Invtmt_EV_infrastructure__c', 'cstk__Invtmt_hydrogen__c', 'cstk__Oil_gas_exploration_ot__c', 'cstk__source__c', 'cstk__Petrochmcl_invtmt_ot_2025__c', 'cstk__Planned_rwbl_capacity_ot__c', 'cstk__Refinery_invtmt_ot_2025__c', 'cstk__Rwbl_capacity_ot__c', 'cstk__gf_o_gas_drv_dw_ebtd_tl_per__c', 'cstk__gf_o_gas_up_ebtd_ov_tl_per__c', 'cstk__gf_o_gas_prod_ann_number__c', 'cstk__gf_o_g_ex_capex_inv_avg_amount__c', 'cstk__gf_o_gas_prod_u_cost_amount__c', 'cstk__gf_rw_enrg_cp_trgt_2030_number__c', 'cstk__gf_rw_enrg_ov_tl_per__c', 'cstk__g_zr_methane_emss_trgt_type__c', 'cstk__gf_o_gas_up_out_n_zr_ems_per__c', 'cstk__gf_alt_enrg_incr_strg_desc__c', 'cstk__gf_new_bus_md_strg_desc__c', 'cstk__gf_o_ann_ref_cap_tl_number__c', 'cstk__g_ma_up_segm_type__c', 'cstk__gf_o_ref_mgr_per_barrll_amount__c', 'cstk__gf_rfy_inv_mid_trm_o_rev_per__c', 'cstk__gf_tl_rw_enrg_prd_cp_gw_number__c', 'cstk__green_capex__c', 'cstk__gf_energy_sector_group_activity_per__c'}, //NOSONAR

        'cstk__Sector_Steel__c' => new List<String>{'cstk__gf_bof_production_model_per__c', 'cstk__gf_eaf_production_model_per__c', 'cstk__gf_anl_capex_over_tl_rvns_per__c', 'cstk__gf_red_trgt_b_y_em_ints_number__c', 'cstk__date__c', 'cstk__gf_red_trgt_c_y_em_ints_number__c', 'cstk__g_carbon_capture_inv_ind_type__c', 'cstk__g_dri_inv_ind_type__c', 'cstk__g_hydr_use_inv_ind_type__c', 'cstk__source__c', 'cstk__gf_steel_sector_group_activity_per__c'}, //NOSONAR

        'cstk__Sector_Utilities__c' => new List<String>{'cstk__Capex_invested_renewables__c', 'cstk__Coal_exit_year__c', 'cstk__Elec_tran_dstr_ntwrk__c', 'cstk__date__c', 'cstk__Elec_tran_dstr_ntwrk_pct__c', 'cstk__Energy_generation__c', 'cstk__Energy_generation_pct__c', 'cstk__Gas_tran_dstr_ntwrk__c', 'cstk__Gas_tran_dstr_ntwrk_pct__c', 'cstk__Invtmt_carbon__c', 'cstk__Invtmt_energy_storage__c', 'cstk__Invtmt_ev_charging_inf__c', 'cstk__Invtmt_hydrogen_production__c', 'cstk__Other_high_crbn_act__c', 'cstk__Other_high_crbn_act_pct__c', 'cstk__Other_low_crbn_act__c', 'cstk__Other_low_crbn_act_prct__c', 'cstk__Other_uncategorized__c', 'cstk__Other_uncategorized_pct__c', 'cstk__Prod_gwh_other_rnwable_pct__c', 'cstk__Production_gwh_coal_pct__c', 'cstk__Production_gwh_fuel_pct__c', 'cstk__Production_gwh_gas_pct__c', 'cstk__Production_gwh_hydro_pct__c', 'cstk__Production_gwh_nuclear_pct__c', 'cstk__Production_gwh_solar_pv_pct__c', 'cstk__Production_gwh_wind_pct__c', 'cstk__Retail__c', 'cstk__Retail_pct__c', 'cstk__source__c', 'cstk__gf_utilities_sector_group_activity_per__c'}, //NOSONAR

        'cstk__Sector_Autoparts__c' => new List<String>{'cstk__gf_el_car_battery_components_mfr_r_per__c',  'cstk__gf_brakes_manufacture_revenue_per__c', 'cstk__gf_el_mobility_components_mfr_rev_per__c', 'cstk__gf_car_exterior_components_mfr_r_per__c', 'cstk__gf_int_comb_engn_gearbox_c_mfr_r_per__c', 'cstk__gf_inf_entrt_st_components_mfr_rev_per__c', 'cstk__gf_car_interior_components_mfr_r_per__c', 'cstk__gf_other_components_manufacture_r_per__c', 'cstk__gf_safety_equipment_components_mfr_r_per__c', 'cstk__gf_wheels_suspension_systems_mfr_r_per__c', 'cstk__gf_transmissions_components_mfr_r_per__c','cstk__gf_tl_ee_2030_le_srce_el_cp_tg_sc_number__c', 'cstk__gf_rw_energies_consm_incr_objv_ind_type__c','cstk__gf_ann_em_red_tg_c_em_red_strg_sc_number__c', 'cstk__gf_pr_c_business_model_risk_score_number__c', 'cstk__gf_tl_pr_comp_per_bm_c_trns_st_sc_number__c', 'cstk__gf_c_mid_t_circularity_strg_rp_sc_number__c', 'cstk__gf_cir_autoparts_strategy_plans_ind_type__c', 'cstk__gf_tri_autoparts_sector_cta_s_sc_number__c', 'cstk__date__c', 'cstk__gf_c_em_int_annual_red_per_score_number__c', 'cstk__gf_ctrs_low_cb_pls_rk_as_cta_s_sc_number__c', 'cstk__gf_mix_tc_em_p_cur_st_as_cta_s_sc_number__c', 'cstk__gf_c_group_tr_plan_as_cta_s_sc_number__c', 'cstk__gf_energy_trns_objetives_plans_ind_type__c', 'cstk__gf_dev_research_capex_tl_inv_sc_number__c', 'cstk__gf_c_five_r_geo_au_comp_pr_pcy_rs_number__c', 'cstk__gf_rel_toolkit_identifier_desc__c', 'cstk__gf_tl_ee_cp_le_srce_el_cp_per_sc_number__c', 'cstk__gf_t_el_cons_rw_sources_electricity_per__c', 'cstk__gf_thsd_dollars_id_investment_amount__c', 'cstk__gf_autoparts_sector_t_rs_score_number__c', 'cstk__gf_autoparts_sector_tri_final_score_id__c', 'cstk__gf_as_tri_final_score_label_desc__c', 'cstk__gf_autoparts_sector_tri_score_number__c', 'cstk__source__c', 'cstk__gf_auto_sector_group_activity_per__c'}, //NOSONAR

        'cstk__Rating__c' => new List<String>{'cstk__category__c', 'cstk__date__c', 'cstk__rank_in_sector__c', 'cstk__rating__c', 'cstk__sector_avg__c', 'cstk__source__c'}, //NOSONAR

        'cstk__Top_5_geographies__c' => new List<String>{'cstk__date__c', 'cstk__main_geo__c', 'cstk__Sector_Auto__c', 'cstk__Sector_Cement__c', 'cstk__Sector_Energy__c', 'cstk__Sector_Steel__c', 'cstk__Sector_Utility__c', 'cstk__source__c', 'cstk__type__c', 'cstk__main_geo_value__c'}, //NOSONAR

        'cstk__Physical_Risk__c' => new List<String>{'cstk__gf_rel_toolkit_identifier_desc__c', 'cstk__gf_pr_measures_insur_coverage_type_desc__c', 'cstk__gf_physical_risk_mi_measures_ind_type__c', 'cstk__gf_physical_risk_evaluation_ind_type__c', 'cstk__gf_last_change_date__c', 'cstk__gf_insurance_against_damage_ind_type__c', 'cstk__gf_insur_pl_coverage_reviews_ind_type__c', 'cstk__gf_insur_advisors_collaboration_ind_type__c', 'cstk__gf_general_policy_company_ind_type__c', 'cstk__gf_file_origin_name__c', 'cstk__gf_economic_loss_insur_coverage_ind_type__c', 'cstk__gf_damage_loss_insurance_proof_desc__c', 'cstk__gf_asst_pr_measures_insur_cvrg_type_desc__c', 'cstk__date__c'}, //NOSONAR

        'cstk__Water_Biodiversity__c' => new List<String>{'cstk__date__c','cstk__source__c','cstk__gf_water_risk_mitigation_level_ind_type__c','cstk__gf_water_risk_management_level_ind_type__c','cstk__gf_water_risk_level_label_ind_type__c','cstk__gf_water_risk_criteria_met_ind_type__c','cstk__gf_water_consumption_stressed_areas_per__c','cstk__gf_waste_risk_mitigation_level_ind_type__c','cstk__gf_waste_risk_management_level_ind_type__c','cstk__gf_waste_risk_level_label_ind_type__c','cstk__gf_waste_risk_criteria_met_ind_type__c','cstk__gf_waste_reduction_target_ind_type__c','cstk__gf_vulnerable_bio_areas_total_assets_per__c','cstk__gf_vch_cust_deforestation_comt_ind_type__c','cstk__gf_trend_water_consumption_intensity_per__c','cstk__gf_qnt_wtr_cp_red_objective_ind_type__c','cstk__gf_water_related_capex_ind_type__c','cstk__gf_natural_cp_bio_protect_pcy_c_ind_type__c','cstk__gf_mrv_systems_ind_type__c','cstk__gf_land_use_risk_mt_level_ind_type__c','cstk__gf_land_use_risk_mgmt_level_ind_type__c','cstk__gf_land_use_risk_level_label_ind_type__c','cstk__gf_land_use_risk_criteria_met_ind_type__c','cstk__gf_deforestation_commitment_ind_type__c','cstk__gf_circular_strategy_impl_ind_type__c','cstk__gf_certification_scheme_ind_type__c','cstk__gf_biodiversity_risk_mt_level_ind_type__c','cstk__gf_biodiversity_risk_mgmt_lvl_ind_type__c','cstk__gf_biodiversity_risk_lvl_label_ind_type__c','cstk__gf_biodiversity_risk_crit_met_ind_type__c','cstk__gf_biodiversity_risk_number__c','cstk__gf_land_use_risk_number__c','cstk__gf_rel_toolkit_identifier_desc__c','cstk__gf_waste_risk_number__c','cstk__gf_water_risk_number__c'} //NOSONAR
    };

    public final String Query;
    public final String Entity;
    public final List<String> Fields;
    private String fieldGroups;
    private Map<String, Map<String, List<String>>> groupsMap = new Map<String, Map<String, List<String>>>();
    private Map<String, Object> mappedGroup = new Map<String, Object>();
    private Map<String, Object> groupFields = new Map<String, Object>();
    private Map<String, Object> objFields = new Map<String, Object>();
    private List<String> otherFields = new List<String>();
    private String otherObjName;
    private String independentFields;
    private Map<String, Object> indepndtFieldsMap = new Map<String, Object>();
    private Map<String, Object> objectIndFields = new Map<String, Object>();
    private List<String> indepdntFields = new List<String>();
    public final List<String> autoPartsFieldEleven = new List<String>{'cstk__gf_el_car_battery_components_mfr_r_per__c', 'cstk__gf_brakes_manufacture_revenue_per__c', 'cstk__gf_el_mobility_components_mfr_rev_per__c', 'cstk__gf_car_exterior_components_mfr_r_per__c', 'cstk__gf_int_comb_engn_gearbox_c_mfr_r_per__c', 'cstk__gf_inf_entrt_st_components_mfr_rev_per__c', 'cstk__gf_car_interior_components_mfr_r_per__c', 'cstk__gf_other_components_manufacture_r_per__c', 'cstk__gf_safety_equipment_components_mfr_r_per__c', 'cstk__gf_wheels_suspension_systems_mfr_r_per__c', 'cstk__gf_transmissions_components_mfr_r_per__c'};
    private final List<String> HMMFIELDS = new List<String>{'cstk__gf_sc_higher_group_em_intensity_ind_type__c', 'cstk__gf_c_revenues_highest_weight_sector_type__c', 'cstk__gf_high_market_adjustment_entities_desc__c'};

    /**
    * @description Private constructor to avoid sonar err
    */
    @TestVisible
    public CSTK_RecordZeroActions(List<Id> toolkitIds, String objectName){
        Entity = objectName;
        Fields = recordZeroFields.get(objectName);
        final cstk.Json_Selector jsonSelector = new cstk.Json_Selector();
        final List<cstk__ESG_Toolkit_Settings_Json__mdt> config = jsonSelector.selectByObjectName(objectName);
        final List<cstk__ESG_Toolkit_Settings_Json__mdt> independentconfig = jsonSelector.selectByObjectName('independent_groups');
        final String fieldGroups = config[0].cstk__json__c;
        final String indFieldGroups = independentconfig[0].cstk__json__c;
        indepndtFieldsMap = (Map<String, Object>)JSON.deserializeUntyped(indFieldGroups);
        objectIndFields = (Map<String, Object>)indepndtFieldsMap.get(objectName);
        List<sObject> otherSobjList = new List<sObject>();
        mappedGroup = (Map<String, Object>)JSON.deserializeUntyped(fieldGroups);
        for (String groupName : mappedGroup.keySet()) {
            groupFields = (Map<String, Object>)mappedGroup.get(String.valueOf(groupName));
            Map<String, List<String>> groupMap = new Map<String, List<String>>();
            for (String objname : groupFields.keySet()) {
                objFields = (Map<String, Object>)groupFields.get(objName);
                List<String> groupsFields = new List<String>();
                for (Object fieldName : objFields.values()) {
        			groupsFields.add(String.valueOf(fieldName));
                }
                if (objname != objectName) {
                	otherObjName = objname;
                    otherFields = groupsFields;
    			}
                groupMap.put(objName, groupsFields);
            }
            groupsMap.put(groupName, groupMap);
        }

        for (Object fieldName : objectIndFields.values()) {
            indepdntFields.add(String.valueOf(fieldName));
        }

        //Get json fields
        Query = 'SELECT Id, cstk__year__c, cstk__toolkit_id__r.cstk__toolkit_unique_id__c, ' + String.join(Fields, ',') + ' from ' + objectName + ' where cstk__toolkit_id__c IN (\'' + String.join(toolkitIds, '\',\'') + '\') AND cstk__year__c != null ORDER BY cstk__toolkit_id__c DESC, cstk__year__c DESC';
        System.debug('query: ' + Query);
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(Query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<sObject> zeroRecords = new List<sObject>();
        Schema.SObjectType objectName = null;
        List<sObject> otherObjRecs = new List<sObject>();
        Map<Id,List<sObject>> toolgdList = new Map<Id,List<sObject>>();
        Map<Id, Map<String, List<sObject>>> mapToolIdObjs = new Map<Id, Map<String, List<sObject>>>();
        Map<Id, sObject> recordZeroMap = new Map<Id, sObject>();
        final Integer currentYear = System.now().year();
        for (sObject gd : scope) {
            objectName = gd.getSObjectType();
            if (Integer.valueOf(gd.get('cstk__year__c')) > currentYear) {
                continue;
            } else {
                //Borrar
                List<sObject> aux = new List<sObject>(); //NOSONAR
                if (toolgdList.get(String.valueOf(gd.get('cstk__toolkit_id__c'))) != null) { //NOSONAR
                    aux = toolgdList.get(String.valueOf(gd.get('cstk__toolkit_id__c'))); //NOSONAR
                }
                aux.add(gd);
                toolgdList.put(String.valueOf(gd.get('cstk__toolkit_id__c')), aux); //NOSONAR
                //Hasta aquí
                Map<String, List<sObject>> mapNameObjs = new Map<String, List<sObject>>();
                if (mapToolIdObjs.get(String.valueOf(gd.get('cstk__toolkit_id__c'))) != null) {
                    mapNameObjs = mapToolIdObjs.get(String.valueOf(gd.get('cstk__toolkit_id__c')));
                }
                List<sObject> objList = new List<sObject>();
                if (mapNameObjs.get(String.valueOf(objectName)) != null) {
                    objList = mapNameObjs.get(String.valueOf(objectName));
                }

                objList.add(gd);
				mapNameObjs.put(String.valueOf(objectName), objList);
                mapToolIdObjs.put(String.valueOf(gd.get('cstk__toolkit_id__c')), mapNameObjs);
            }
        }

        if (!String.isEmpty(otherObjName)) {
            Set<Id> toolkitIds = mapToolIdObjs.keySet().clone();
            //String listToolIds = '(\'' + String.join(toolkitIds, '\',\'') + '\')';
            List<String> listToolIds = (List<String>)new List<Id>(toolkitIds);
            final String queryStr = 'SELECT Id, cstk__toolkit_id__c, cstk__year__c, ' + String.join(otherFields, ',') +' FROM ' + String.valueOf(otherObjName) + ' WHERE cstk__toolkit_id__c IN :listToolIds ORDER BY cstk__year__c DESC NULLS LAST, cstk__date__c DESC';

            otherObjRecs = Database.query(String.escapeSingleQuotes(queryStr));

        }

        if (!otherObjRecs.isEmpty()) {
            for (Id toolId : mapToolIdObjs.keySet()) {
                for (sObject otherObjRec : otherObjRecs) {
                    if (otherObjRec.get('cstk__toolkit_id__c') == toolId) {
                        if (otherObjRec.get('cstk__year__c') == '0000') {
                            recordZeroMap.put(String.valueOf(toolId), otherObjRec);
                            break;
                        }
                	Map<String, List<sObject>> mapNameObjs = new Map<String, List<sObject>>();
                	if (mapToolIdObjs.get(toolId) != null) {
                    	mapNameObjs = mapToolIdObjs.get(toolId);
                	}
                	List<sObject> objList = new List<sObject>();
                	if (mapNameObjs.get(String.valueOf(otherObjName)) != null) {
                    	objList = mapNameObjs.get(String.valueOf(otherObjName));
                	}
                	objList.add(otherObjRec);
                	mapNameObjs.put(String.valueOf(otherObjName), objList);
                	mapToolIdObjs.put(toolId, mapNameObjs);
                    }
                }
            }
        }
        List<Id> toolkitIds = new List<Id>(toolgdList.keySet());
        final String yearZer = '0000';
        List<String> listToolIds = (List<String>)new List<Id>(toolkitIds);
        //final String queryZero = 'SELECT Id, cstk__year__c, cstk__toolkit_id__r.cstk__toolkit_unique_id__c, ' + String.join(Fields, ',') + ' from ' + Entity + ' where cstk__toolkit_id__c IN (\'' + String.join(toolkitIds, '\',\'') + '\') AND cstk__year__c = :yearZer ORDER BY cstk__toolkit_id__c DESC';
        final String queryZero = 'SELECT Id, cstk__year__c, cstk__toolkit_id__r.cstk__toolkit_unique_id__c, ' + String.join(Fields, ',') + ' from ' + Entity + ' where cstk__toolkit_id__c IN :listToolIds AND cstk__year__c = :yearZer ORDER BY cstk__toolkit_id__c DESC';
        List<sObject> recordsZero = Database.query(String.escapeSingleQuotes(queryZero));
        Map<Id, Id> mapIdToolId = new Map<Id,Id>();
        for (sObject gdZe : recordsZero) {
            mapIdToolId.put(String.valueOf(gdZe.get('cstk__toolkit_id__c')), String.valueOf(gdZe.get('Id')));
        }
        for (Id toolkitId : mapToolIdObjs.keySet()) {
            sObject zeroRecord = cstk.Utils.getSObject(Entity);
			zeroRecord.put('cstk__year__c', '0000'); //NOSONAR
			zeroRecord.put('cstk__toolkit_id__c', toolkitId); //NOSONAR
            if (mapIdToolId.get(toolkitId) != null) { //NOSONAR
                zeroRecord.put('Id', mapIdToolId.get(toolkitId));
            }

            if (String.valueOf(objectName) != 'cstk__Rating__c' && String.valueOf(objectName) != 'cstk__Top_5_geographies__c') {
            Map<String, String> yearsToUpdate = new Map<String, String>();
            for (String groupName: groupsMap.keySet()) {
                for (String objName : groupsMap.get(groupName).keySet()) {
                    if (mapToolIdObjs.get(toolkitId).get(objName) != null) {
                        for (sObject obj : mapToolIdObjs.get(toolkitId).get(objName)) {
                            for (String field : groupsMap.get(groupName).get(objName)) {
                                if (!String.isEmpty(String.valueOf(obj.get(field)))) {
                                    if (!String.isEmpty(yearsToUpdate.get(groupName))) {
                                        if (Integer.valueOf(yearsToUpdate.get(groupName)) < Integer.valueOf(obj.get('cstk__year__c'))) {
                                            yearsToUpdate.put(groupName, String.valueOf(obj.get('cstk__year__c')));
                                        }
                                    } else {
                                        yearsToUpdate.put(groupName, String.valueOf(obj.get('cstk__year__c')));
                                    }
                                }
                            }
                        }
                    }
                }
            }
            for (String objName : mapToolIdObjs.get(toolkitId).keySet()) {
                sObject otherZeroRecord;
                if (objName != Entity && recordZeroMap.get(toolkitId) != null) {
                    otherZeroRecord = cstk.Utils.getSObject(objName);
                    otherZeroRecord.Id = recordZeroMap.get(toolkitId).Id;
                }

                //sObject zeroRecord = cstk.Utils.getSObject(Entity);
            		for (String field : indepdntFields) {
                		for (sObject record : mapToolIdObjs.get(toolkitId).get(Entity)) {
                    		if (record.get(field) != null || HMMFIELDS.contains(field)) { //NOSONAR
                        		zeroRecord.put(field, record.get(field));
                        		break;
                    		}
                		}
            		}

					for (String groupName : groupsMap.keySet()) {
                        if (groupsMap.get(groupName).keySet().contains(objName)) {
                            Integer year;
                            if (!String.isEmpty(yearsToUpdate.get(groupName))) {
                                year = Integer.valueOf(yearsToUpdate.get(groupName));
                                for (sObject obj : mapToolIdObjs.get(toolkitId).get(objName)) {
                                    if (Integer.valueOf(obj.get('cstk__year__c')) == year) {
                                        for (String field : groupsMap.get(groupName).get(objName)) {
                                            if (objName == Entity) {
                                                zeroRecord.put(field, obj.get(field));
                                            } else {
                                                otherZeroRecord.put(field, obj.get(field));
                                            }

                                        }
                                        break;
                                    } else {
                                        for (String field : groupsMap.get(groupName).get(objName)) {
                                            if (objName == Entity) {
                                                zeroRecord.put(field, null);
                                            } else {
                                                otherZeroRecord.put(field, null);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                	}
                	if (otherZeroRecord != null) {
                    	zeroRecords.add(otherZeroRecord);
                	}
            	}
				//recsToUpdate.add(zeroRecord);
            	}   else {
                for (String field : Fields) {
                for (sObject record : toolgdList.get(toolkitId)) {
                    if (record.get(field) != null || HMMFIELDS.contains(field)) { //NOSONAR
                        zeroRecord.put(field, record.get(field));
                        break;
                    }
                }
            }
            }

            if (String.valueOf(objectName) == 'cstk__Sector_Autoparts__c') {
                sObject recordAUx = null;
                for (sObject record : toolgdList.get(toolkitId)) {
                	for (String field : autoPartsFieldEleven) {
                        if (record.get(field) != null) { //NOSONAR
                            recordAUx = record;
                            break;
                        }
                    }
                    if (recordAUx != null) {
                        break;
                    }
                }
                for (String field2 : autoPartsFieldEleven) { // recorremos los 11 campo que solo tendrán 5 informado
                    if (recordAUx != null && recordAUx.get(field2) != null) {
                        zeroRecord.put(field2, recordAUx.get(field2));
                    } else if (recordAUx != null) {
                        zeroRecord.put(field2, null);
                    }
                }
            }
            zeroRecords.add(zeroRecord);
            System.debug('Recs to Update --> ' + zeroRecords);
        }
        final List<String> errors = new List<String>();
        zeroRecords.sort();
        final List<Database.UpsertResult> responses = Database.upsert(zeroRecords, false);
        for (Database.UpsertResult response : responses) {
            if (!response.isSuccess()) {
                for (Database.Error error : response.getErrors()) {
                    errors.add(error.getMessage());
                    System.debug('Upsert Toolkit  ERROR: ' + userInfo.getUserName() + ', ' + error.getStatusCode() + ': ' + error.getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext BC){

   }

    /**
    * @description Consolidate RecordZero for generic object
    * @param toolkitId toolkit Id
    * @param objectName, name of object to consolidate
    * @return Utils.DML_Wrapper with the response of the DML operation
    */
    public static cstk.Utils.DML_Wrapper consolidateObject(List<Id> toolkitIds, String objectName) {
        final List<String> listToolIds = (List<String>)new List<Id>(toolkitIds);
        List<String> lFields = recordZeroFields.get(objectName); //NOSONAR
        List<sObject> zeroRecords = new List<sObject>(); //NOSONAR

        //final String query = 'SELECT Id, cstk__year__c, cstk__toolkit_id__r.cstk__toolkit_unique_id__c, ' + String.join(lFields, ',') + ' from ' + objectName + ' where cstk__toolkit_id__c IN (\'' + String.join(toolkitIds, '\',\'') + '\') AND cstk__year__c != null ORDER BY cstk__toolkit_id__c DESC, cstk__year__c DESC';
        final String query = 'SELECT Id, cstk__year__c, cstk__toolkit_id__r.cstk__toolkit_unique_id__c, ' + String.join(lFields, ',') + ' from ' + objectName + ' where cstk__toolkit_id__c IN :listToolIds AND cstk__year__c != null ORDER BY cstk__toolkit_id__c DESC, cstk__year__c DESC';
        System.debug(String.escapeSingleQuotes(query));

        List<sObject> records = Database.query(String.escapeSingleQuotes(query));
        System.debug(records);
        Map<Id,List<sObject>> toolgdList = new Map<Id,List<sObject>>(); //NOSONAR
        final Integer currentYear = System.now().year();
        for (sObject gd : records) {
            if (Integer.valueOf(gd.get('cstk__year__c')) > currentYear) {
                continue;
            } else {
                List<sObject> aux = new List<sObject>(); //NOSONAR
                if (toolgdList.get(String.valueOf(gd.get('cstk__toolkit_id__c'))) != null) { //NOSONAR
                    aux = toolgdList.get(String.valueOf(gd.get('cstk__toolkit_id__c'))); //NOSONAR
                }
                aux.add(gd);
                toolgdList.put(String.valueOf(gd.get('cstk__toolkit_id__c')), aux); //NOSONAR
            }

        }

        for (Id toolkitId : toolgdList.keySet()) {
            sObject zeroRecord = cstk.Utils.getSObject(objectName);
            zeroRecord.put('cstk__year__c', '0000'); //NOSONAR
            zeroRecord.put('cstk__toolkit_id__c', toolkitId); //NOSONAR
            //zeroRecord.put('cstk__unique_id__c', uniqueIdPrefix.get(objectName) + '0000' + (String)records[0].getsObject('cstk__toolkit_id__r').get('cstk__toolkit_unique_id__c'));

            for (String field : lFields) {
                for (sObject record : toolgdList.get(toolkitId)) {
                    if (record.get('cstk__year__c') == '0000') { //NOSONAR
                        zeroRecord.put('Id', record.get('Id'));
                        break;
                    } else {
                        if (record.get(field) != null) { //NOSONAR
                            zeroRecord.put(field, record.get(field));
                            break;
                        }
                    }
                }
            }
            System.debug(zeroRecord);
            zeroRecords.add(zeroRecord);
        }

        final List<String> errors = new List<String>();
        final List<Database.UpsertResult> responses = Database.upsert(zeroRecords, false);
        for (Database.UpsertResult response : responses) {
            if (!response.isSuccess()) {
                for (Database.Error error : response.getErrors()) {
                    errors.add(error.getMessage());
                    System.debug('Upsert Toolkit  ERROR: ' + userInfo.getUserName() + ', ' + error.getStatusCode() + ': ' + error.getMessage());
                }
            }
        }
        return new cstk.Utils.DML_Wrapper(errors.isEmpty(), errors);
    }

    /**
    * @description Consolidate RecordZero for generic object
    * @param toolkitId toolkit Id
    * @return Utils.DML_Wrapper with the response of the DML operation
    */
    public static cstk.Utils.DML_Wrapper consolidateObjectRating(List<Id> toolkitIds, String category, String source) {
        final String objectName = 'cstk__Rating__c';
        List<String> lFields = recordZeroFields.get(objectName); //NOSONAR
        List<sObject> zeroRecords = new List<sObject>(); //NOSONAR
        List<String> listToolIds = (List<String>)new List<Id>(toolkitIds);
        //final String query = 'SELECT Id, cstk__year__c, cstk__toolkit_id__r.cstk__toolkit_unique_id__c, ' + String.join(lFields, ',') + ' from ' + objectName + ' where cstk__toolkit_id__c IN (\'' + String.join(toolkitIds, '\',\'') + '\') AND cstk__year__c != null AND cstk__category__c = '+ '\''+category+'\' AND cstk__source__c = '+ '\''+source+'\' ORDER BY cstk__toolkit_id__c DESC, cstk__year__c DESC';
        final String query = 'SELECT Id, cstk__year__c, cstk__toolkit_id__r.cstk__toolkit_unique_id__c, ' + String.join(lFields, ',') + ' from ' + objectName + ' where cstk__toolkit_id__c IN :listToolIds AND cstk__year__c != null AND cstk__category__c = :category AND cstk__source__c = :source ORDER BY cstk__toolkit_id__c DESC, cstk__year__c DESC';
        System.debug(String.escapeSingleQuotes(query));

        List<sObject> records = Database.query(String.escapeSingleQuotes(query)); //NOSONAR
        System.debug(records);

        Map<Id,List<cstk__Rating__c>> toolgdList = new Map<Id,List<cstk__Rating__c>>(); //NOSONAR
        for (cstk__Rating__c gd : (List<cstk__Rating__c>)records) { //NOSONAR
            List<cstk__Rating__c> aux = new List<cstk__Rating__c>(); //NOSONAR
            if (toolgdList.get(gd.cstk__toolkit_id__c) != null) { //NOSONAR
                aux = toolgdList.get(gd.cstk__toolkit_id__c);
            }
            aux.add(gd);
            toolgdList.put(gd.cstk__toolkit_id__c, aux);
        }
        for (Id tool : toolgdList.keySet()) {
            //Iterate through GeneralData and consolidate record 0
            cstk__Rating__c zeroGeneralData = new cstk__Rating__c(); //NOSONAR
            zeroGeneralData.cstk__year__c = '0000'; //NOSONAR
            zeroGeneralData.cstk__toolkit_id__c = tool;
            for (String fieldName : lFields) {
                for (cstk__Rating__c gen : toolgdList.get(tool)) {
                    if (gen.cstk__year__c == '0000') { //NOSONAR
                        zeroGeneralData.Id = gen.Id;
                    } else if ( gen.get(fieldName) != null &&  gen.cstk__year__c != null) { //NOSONAR
                        zeroGeneralData.put(fieldName, gen.get(fieldName));
                        break;
                    }
                }
            }
            zeroRecords.add(zeroGeneralData);
        }
        final List<String> errors = new List<String>();
        final List<Database.UpsertResult> responses = Database.upsert(zeroRecords, false);
        for (Database.UpsertResult response : responses) {
            if (!response.isSuccess()) {
                for (Database.Error error : response.getErrors()) {
                    errors.add(error.getMessage());
                    System.debug('Upsert Toolkit  ERROR: ' + userInfo.getUserName() + ', ' + error.getStatusCode() + ': ' + error.getMessage());
                }
            }
        }
        return new cstk.Utils.DML_Wrapper(errors.isEmpty(), errors);
    }

    /**
    * @description Consolidate RecordZero for generic object
    * @param toolkitId toolkit Id
    * @return cstk.Utils.DML_Wrapper with the response of the DML operation
    */
    public static cstk.Utils.DML_Wrapper consolidateObjectTopGeography(List<Id> toolkitIds, String sectorApi) {
        final String objectName = 'cstk__Top_5_geographies__c';
        List<String> lFields = recordZeroFields.get(objectName); //NOSONAR
        List<cstk__Top_5_geographies__c> zeroRecords = new List<cstk__Top_5_geographies__c>(); //NOSONAR
        List<String> listToolIds = (List<String>)new List<Id>(toolkitIds);
        //final String query = 'SELECT Id, cstk__year__c, ' + String.join(lFields, ', ') + ' from cstk__Top_5_geographies__c where cstk__year__c != null AND '+ sectorApi +' !=null ORDER BY cstk__year__c DESC';
        final String query = 'SELECT Id, cstk__year__c, ' + String.join(lFields, ', ') + ' from cstk__Top_5_geographies__c where cstk__year__c != null AND '+ sectorApi +' !=null ORDER BY cstk__year__c DESC';
        System.debug(String.escapeSingleQuotes(query));

        List<cstk__Top_5_geographies__c> records = Database.query(String.escapeSingleQuotes(query)); //NOSONAR
        System.debug(records);

        Map<Id,List<cstk__Top_5_geographies__c>> toolgdList = new Map<Id,List<cstk__Top_5_geographies__c>>(); //NOSONAR
        for (cstk__Top_5_geographies__c gd : (List<cstk__Top_5_geographies__c>)records) {
            List<cstk__Top_5_geographies__c> aux = new List<cstk__Top_5_geographies__c>(); //NOSONAR
            if (toolgdList.get(String.valueOf(gd.get(sectorApi))) != null) { //NOSONAR
                aux = toolgdList.get(String.valueOf(gd.get(sectorApi)));
            }
            aux.add(gd);
            toolgdList.put(String.valueOf(gd.get(sectorApi)), aux);
        }
        for (Id tool : toolgdList.keySet()) {
            List<String> countryList = new List<String>();
            for (cstk__Top_5_geographies__c gen : toolgdList.get(tool)) {
                cstk__Top_5_geographies__c zeroGeneralData = new cstk__Top_5_geographies__c();
                if (gen.cstk__year__c == '0000') { //NOSONAR
                    zeroGeneralData.Id = gen.Id;
                } else if ( gen.get('cstk__main_geo__c') != null && !countryList.contains(String.valueOf(gen.get('cstk__main_geo__c'))) && gen.get('cstk__main_geo_value__c') != null &&  gen.cstk__year__c != null) { //NOSONAR
                    zeroGeneralData.cstk__year__c = '0000'; //NOSONAR
                    zeroGeneralData.put(sectorApi, tool);
                    zeroGeneralData.cstk__date__c = gen.cstk__date__c;
                    zeroGeneralData.cstk__main_geo__c = gen.cstk__main_geo__c;
                    zeroGeneralData.cstk__source__c = gen.cstk__source__c;
                    zeroGeneralData.cstk__main_geo_value__c = gen.cstk__main_geo_value__c;
                    zeroGeneralData.cstk__type__c = gen.cstk__type__c;
                    countryList.add(String.valueOf(gen.get('cstk__main_geo__c'))); //NOSONAR
                    zeroRecords.add(zeroGeneralData);
                }
            }
        }
        final List<String> errors = new List<String>();
        final List<Database.UpsertResult> responses = Database.upsert(zeroRecords, false);
        for (Database.UpsertResult response : responses) {
            if (!response.isSuccess()) {
                for (Database.Error error : response.getErrors()) {
                    errors.add(error.getMessage());
                    System.debug('Upsert Toolkit  ERROR: ' + userInfo.getUserName() + ', ' + error.getStatusCode() + ': ' + error.getMessage());
                }
            }
        }
        return new cstk.Utils.DML_Wrapper(errors.isEmpty(), errors);

    }
}