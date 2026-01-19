/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistenciaDB
* @Author   Berth Elena Téllez Lira  eberthaelena.tellez.contractor@bbva.com
* @Date     Created: 24/01/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class that covers:  Arc_Gen_PersistenciaDB_Serice
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |
*             Class creation.
* 2020-07-09 ricardo.almanza.contractor@bbva.com
*             Added to prepareData fields arce__analysis_template_id__c for manual triage
* 2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* 2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* 2020-11-17 joseluis.garcia4.contractor@bbva.com
*             Use approved field arce__limit_exposure_ext_ind_type__c for extended policies indicator.
* 2021-01-06 juanmanuel.perez.ortiz.contractor@bbva.com
*             Remove field references for unused fields (namings nivelation)
* 2021-01-07 eduardoefrain.hernandez.contractor@bbva.com
*             Remove field references for unused fields (namings nivelation)
* |2021-01-18 luisdavid.rivera.ortiz@bbva.com
*             Revome field references for usused fields (namings nivelation)
* 2021-03-01  juanmanuel.perez.ortiz.contractor@bbva.com
*             Added arce__stage_collective_ind_type__c field in query
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__sector_building_desc__c for arce__sector_building_type__c
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback last commit  (PR: 1231)
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_PersistenciaDB_Test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method, create data for dinamic form
    * --------------------------------------------------------------------------------------
    * @Author   berthaelena.tellez.contractor@bbva.com
    * @param void
    * @return void
    * @example setupTest()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup
    static void setupTest(){
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__Stage__c = '1';
        insert newArce;

        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, newArce.Id, groupAccount.accId, '1');
        newAnalysis.arce__InReview__c = true;
        newAnalysis.arce__path__c = 'MAC';
        insert newAnalysis;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that is responsible for preparing the list of objects and
    identifiers to execute the class to save basic data.
    * --------------------------------------------------------------------------------------
    * @Author   berthaelena.tellez.contractor@bbva.com
    * @param void
    * @return void
    * @example prepareData()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    Public static void prepareData(){
          Arc_Gen_SaveBasicData saveData = new Arc_Gen_SaveBasicData();

        List<arce__Account_has_Analysis__c> datosAcont = [SELECT id,arce__employees_number__c,arce__Analysis__r.OwnerId,arce__Analysis__r.arce__parent_analysis_id__c,arce__Analysis__r.arce__analysis_risk_sanction_date__c,
        arce__ffss_for_rating_id__r.arce__financial_statement_id__c,
        arce__ffss_for_rating_id__r.arce__rating_id__c,arce__Account_has_Analysis__c.arce__branch_id__c,
        arce__economic_activity_sector_desc__c,arce__gf_company_economic_actvy_id__c,
        arce__adj_long_rating_value_id__c,arce__adj_total_rating_score_number__c,
        arce__ll_adj_ebitda_amount__c,arce__ll_adj_debt_amount__c,
        arce__Analysis__c,arce__significant_variables_type__c,
        arce__limit_asset_allocation_amount__c,arce__data_adjusted_score_number__c,arce__ll_adj_debt_auditor_amount__c,
        arce__ll_adj_ebitda_auditor_amount__c,arce__cust_evolution_cyr_ind_type__c,arce__backlog_desc__c,arce__backlog_sales_desc__c,
        arce__bbva_financial_debt_share_per__c,arce__cust_budget_cyr_ind_type__c,arce__ffss_auditor_qlfn_type__c,
        arce__backlog_less_70_per_type__c,arce__backlog_less_70_per_desc__c,arce__enterprise_group_type__c,
        arce__enterprise_group_desc__c,arce__ll_test_scope_ind_type__c,arce__ebitda_less_70_peer_avg_desc__c,arce__ebitda_less_70_peer_avg_type__c,
        arce__level_concentration_geo_type__c,arce__sales_less_70_peer_avg_desc__c,arce__sales_less_70_peer_avg_type__c,
        arce__cust_public_private_cmprn_desc__c,arce__cust_proj_2yr_3yr_desc__c,arce__significant_variables_desc__c,
        arce__cust_evolution_cyr_desc__c,arce__Syn_expct_evol_short_term_txt__c,arce__off_balance_rlvnt_info_desc__c,
        arce__off_balance_treasury_desc__c,arce__Syn_client_situation_txt__c,arce__regulated_sector_desc__c,arce__exch_rate_vulnerability_desc__c,
        arce__competition_sector_desc__c,arce__level_conc_sector_desc__c,arce__level_concentration_geo_desc__c,
        arce__bbva_financial_debt_share_desc__c,arce__cust_budget_incl_ffss_desc__c,arce__co_actvy_prtcp_group_desc__c,
        arce__cust_contract_capacity_desc__c,arce__gf_covenant_desc__c,arce__fin_aggressiveness_mngmt_desc__c,
        arce__gntee_given_backlog_range_desc__c,arce__guarantee_given_desc__c,arce__struct_change_invst_desc__c,
        arce__shrhldr_Financialsponsor_profile_desc__c,arce__management_style_desc__c,arce__other_operation_desc__c,
        arce__other_contracted_product_desc__c,arce__shareholder_disagreement_desc__c,arce__capital_provision_desc__c,
        arce__rar_profitability_desc__c,arce__investment_relevant_fact_desc__c,arce__client_refinanced_desc__c,
        arce__shareholder_agreement_desc__c,arce__shrhldr_sig_movement_desc__c,arce__stage_collective_desc__c,
        arce__risk_position_summary_type__c,arce__shareholder_support_desc__c,arce__breakdown_activity_desc__c,
        arce__breakdown_geography_desc__c,arce__risk_position_summary_desc__c,arce__debt_comt_not_disb_amount__c,
        arce__debt_comt_not_disb_local_amount__c,arce__entity_covenants_type__c,
        CreatedById,CurrencyIsoCode,arce__outstanding_amount__c,arce__current_proposed_amount__c,
        arce__current_proposed_local_amount__c,arce__Customer__c,arce__customer_multi_country_type__c,arce__customer_multi_country_desc__c,
        arce__arce_ctmr_flag__c,arce__cust_conc_clients_desc__c,arce__prev_magnitude_unit_type__c,arce__limit_asset_allocation_date__c,
        arce__exposure_at_default_date__c,arce__bbva_avg_prblty_default_date__c,arce__cust_prblty_default_date__c,
        arce__sector_avg_prblty_dflt_date__c,arce__ll_adj_deb_excl_amount__c,arce__ll_acquisition_debt_type__c,
        arce__competition_sector_type__c,arce__level_conc_sector_type__c,arce__market_situation_desc__c,arce__cust_conc_clients_type__c,
        arce__concentration_suppliers_type__c,arce__Funds_destination_type__c,arce__banking_pool_desc__c,arce__ead_amount__c,
        arce__ll_adj_ebitda_excl_amount__c,arce__economic_capital_amount__c,arce__ffss_submitted_type__c,arce__limit_exposure_ext_ind_type__c,
        arce__equity_total_asset_20_type__c,arce__Syn_equity_type__c,arce__equity_desc__c,arce__cost_structure_desc__c,
        arce__Syn_expct_evol_short_term_type__c,arce__arce_Gen_ExceptionsParrilla__c,arce__ebitda_3yr_evolution_desc__c,
        arce__sales_evolution_desc__c,arce__account_payable_desc__c,arce__explantation_margin_desc__c,
        arce__export_range_year_type__c,arce__long_rating_value_id__c,arce__rating_short_value_type__c,
        arce__fin_covenants_breach_type__c,arce__fin_covenants_breach_desc__c,
        arce__fin_spnsr_relnshp_exprnc_type__c,arce__fin_spnsr_relnshp_exprnc_desc__c,arce__shrhldr_fin_sponsor_profl_type__c,
        arce__shrhldr_fin_sponsor_strat_type__c,arce__ffss_for_rating_id__c,arce__gl_fixed_asset_amount__c,
        arce__financial_flexibility_type__c,arce__manual_rating_value_type__c,arce__oper_guarantee_given_type__c,
        arce__conc_geography_activity_type__c,arce__gross_financial_debt_amount__c,arce__gross_financial_debt_local_amount__c,
        arce__gross_fin_debt_ebitda_number__c,arce__group_asset_header_type__c,arce__hats_risk_qualification_number__c,
        arce__sector_building_desc__c,arce__import_range_year_type__c,arce__InReview__c,
        arce__investment_relevant_fact_type__c,arce__off_balance_rlvnt_info_type__c,arce__ebitda_interest_number__c,
        arce__ebitda_interest_local_number__c,arce__invty_work_in_progress_desc__c,arce__struct_change_invst_type__c,LastModifiedById,
        arce__customer_last_projects_desc__c,arce__participant_leveraged_type__c,arce__ll_after_adj_ind_type__c,arce__ll_before_adj_ind_type__c,
        arce__ll_previous_anlys_ind_type__c,arce__ll_previous_anlys_clsfn_type__c,arce__ll_after_adj_clsfn_type__c,arce__ll_collective_type__c,
        arce__ll_before_adj_clsfn_type__c,arce__ll_test_manl_excl_rsn_type__c,arce__lgd_per__c,arce__financial_liquidity_desc__c,
        arce__main_affiliates_desc__c,arce__property_ownership_type__c,arce__main_subsidiary_ind_type__c,arce__years_experience_mngmt_type__c,
        arce__years_experience_mngmt_desc__c,arce__fin_aggressiveness_mngmt_type__c,arce__management_style_type__c,
        arce__market_growth_forecast_desc__c,arce__market_share_type__c,arce__maturity_date__c,
        arce__debt_maturity_available_type__c,Name,arce__newFFSS_ind__c,arce__ffss_auditor_fullname_name__c,arce__number_entity_type__c,
        arce__dvrsfn_product_service_desc__c,arce__dvrsfn_product_service_type__c,arce__assessment_opportunities_desc__c,
        arce__ll_other_adj_debt_amount__c,arce__ll_other_adj_ebitda_amount__c,arce__other_contracted_product_type__c,
        arce__other_operation_type__c,arce__geography_outlook_type__c,arce__path__c,
        arce__probability_default_per__c,arce__sector_avg_prblty_default_per__c,arce__Peer_information_ind_type__c,
        arce__ffss_cnsld_perimeter_desc__c,arce__risk_policy_type__c,arce__off_balance_treasury_type__c,arce__portfolio_class_type__c,
        arce__shareholder_disagreement_type__c,arce__cust_budget_incl_ffss_ind_type__c,arce__pd_per__c,arce__property_ownership_desc__c,
        arce__capital_provision_per__c,arce__cust_proj_2yr_3yr_ind_type__c,arce__smes_eur_comuty_defn_type__c,arce__customer_qualitative_type__c,
        arce__rar_profitability_per__c,arce__long_rating_value_type__c,arce__short_rating_value_type__c,arce__rating_model_type__c,
        arce__rating_scale_type__c,arce__total_rating_score_number__c,arce__ll_adj_debt_ebitda_number__c,arce__gntee_given_backlog_range_type__c,
        arce__total_debt_ebitda_per__c,arce__regulated_sector_type__c,arce__other_relevant_fact_type__c,arce__new_business_venture_type__c,
        arce__new_business_venture_desc__c,arce__other_relevant_fact_desc__c,arce__client_refinanced_type__c,arce__risk_request_desc__c,
        arce__risk_growth_amount__c,arce__sector_desc__c,arce__sector_outlook_type__c,arce__rating_econ_sector_tmpl_id__c,
        arce__service_type_name__c,arce__cust_multi_business_line_type__c,arce__shareholder_agreement_type__c,
        arce__shrhldr_sig_movement_type__c,arce__client_situation_type__c,arce__Stage__c,arce__stage_collective_type__c,
        arce__assessment_strengths_desc__c,arce__subsector_desc__c,arce__shareholder_support_type__c,
        arce__cust_contract_capacity_type__c,
        arce__cust_contract_category_type__c,arce__assessment_threats_desc__c,arce__ffss_auditor_opinion_type__c,arce__ffss_certification_type__c,
        arce__ffss_auditor_opinion_desc__c,arce__currency_id__c,arce__total_asset_amount__c,arce__total_asset_local_amount__c,arce__gf_total_debt_amount__c,
        arce__gf_total_revenues_ytd_amount__c,arce__total_revenues_local_amount__c,arce__customer_product_usage_desc__c,arce__Institution_type__c,
        arce__magnitude_unit_type__c,arce__var_over_20_balance_desc__c,arce__var_vary_10_and_10_bal_desc__c,arce__variables_vary_20_balance_desc__c,
        arce__equity_vary_not_expln_desc__c,arce__ll_anlys_clsfn_var_rsn_id__c,arce__total_revenuesvariation_percentage__c,
        arce__exch_rate_vulnerability_type__c,arce__assessment_weaknesses_desc__c,arce__anlys_wkfl_sbanlys_status_type__c,arce__WF_Stage_WF_Status__c,
        arce__gf_backlog_sales_cyr_number__c,arce__gf_backlog_sales_pyr_number__c,arce__gf_backlog_pending_cyr_amount__c,arce__gf_backlog_pending_pyr_amount__c,
        arce__prop_int_mod_rec_type__c,arce__risk_unit_confirm_desc__c,arce__contrast_risk_unit_type__c,arce__contrast_risk_unit_neg_desc__c,arce__contrast_risk_unit_posi_desc__c,
        arce__Analysis__r.arce__wf_status_id__c,arce__Analysis__r.arce__Stage__c,arce__gf_market_share_desc__c,arce__mngmt_aggressiveness_type__c,arce__Is_Deleted__c,
        arce__analysis_template_id__c
                                                            FROM arce__Account_has_Analysis__c
                                                            WHERE arce__sector_desc__c = 'Hoteleria'];
        Test.startTest();
        String test1 =  saveData.save(datosAcont);
        system.assertEquals(test1,test1, 'Test save persistance');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that is responsible for preparing the list of objects and
    identifiers to execute the class to save basic data.
    * --------------------------------------------------------------------------------------
    * @Author   berthaelena.tellez.contractor@bbva.com
    * @param void
    * @return void
    * @example prepareData()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void constructor() {
        Test.startTest();
        Arc_Gen_PersistenciaDB_Service testConstructor = new Arc_Gen_PersistenciaDB_Service();
        system.assertEquals(testConstructor, testConstructor, 'The test to the empty constructor was successfully');
        Test.stopTest();

    }
}