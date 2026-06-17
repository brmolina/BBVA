/**
* ____________________________________________________________________________
* Interface Between Arce and Toolkit
* ____________________________________________________________________________
* @author      Emanuel Mayo <emanuelomar.mayo.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2025-11-26
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global with sharing class CSTK_ToolkitDataInterface implements callable {

    /**
    * @description Returns General Data Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getGeneralData(Id toolkitId) {
        Map<String,Object> resGenData = new Map<String,Object>();

        List<cstk__General_Data__c> genData = [SELECT cstk__toolkit_id__r.cstk__account_id__r.Name, cstk__toolkit_id__r.cstk__account_id__r.DES_Group_Code__c, cstk__toolkit_id__r.Id, cstk__toolkit_id__r.cstk__year__c, cstk__gf_economic_actvy_sector_desc__c, cstk__overall_awareness_result__c, cstk__overall_awareness_desc__c, cstk__overall_awareness_pct__c, toLabel(cstk__controversy__c) controversy,
        cstk__g_esg_controversy_comnt_desc__c, cstk__g_esg_controversy_event_type__c, cstk__tri__c, cstk__gf_l_4_sdm_esg_outlook_cont_nat_cnc_desc__c, cstk__gf_l_5_sdm_esg_outlook_cont_nat_cnc_desc__c,
        cstk__gf_l_4_sdm_esg_evts_cont_nat_cnc_desc__c, cstk__gf_l_5_sdm_esg_evts_cont_nat_cnc_desc__c, cstk__gf_l_3_sdm_esg_evts_cont_nat_cnc_desc__c, cstk__gf_l_1_sdm_esg_evts_cont_nat_cnc_desc__c,
        cstk__gf_l_2_sdm_esg_evts_cont_nat_cnc_desc__c, cstk__gf_l_3_sdm_esg_outlook_cont_nat_cnc_desc__c, cstk__tri_score__c, cstk__tri_valuation__c, cstk__cca__c,cstk__cta__c,
        cstk__tri_assessment__c, cstk__gf_cca_sc_cl_govn_tcfd_number__c, cstk__gf_cca_sc_rk_mgmt_tcfd_number__c, cstk__gf_cca_sc_strg_tcfd_number__c, cstk__gf_cca_sc_cl_trgt_tcfd_number__c,
        cstk__gf_cta_sc_em_profl_tec_number__c, cstk__gf_cta_rk_sc_low_cb_pcy_number__c, cstk__gf_cta_trns_sc_pl_number__c, cstk__tri_date__c, cstk__g_carbon_capture_inv_type__c,
        cstk__gf_zr_em_scn_5y_em_intensity_d_sc_number__c, cstk__g_enrg_stor_batt_inv_type__c, cstk__g_e_ve_chrg_infr_inv_type__c, cstk__g_hydr_prod_inv_type__c, cstk__gf_gas_oil_pr_ex_vch_em_int_score_number__c,
        cstk__gf_green_activities_capex_inv_sc_number__c, cstk__gf_biofuels_refining_capacity_sc_number__c, cstk__gf_tri_final_score_number__c, cstk__gf_tri_final_score_label_desc__c
        FROM cstk__General_Data__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__year__c = '0000'];

        if(!genData.isEmpty()) {
            resGenData = new Map<String,Object>{
                'toolkitId' => genData[0].cstk__toolkit_id__r.Id,
                'toolkitAccCustomerId' => genData[0].cstk__toolkit_id__r.cstk__account_id__r.DES_Group_Code__c,
                'toolkitAccountName' => genData[0].cstk__toolkit_id__r.cstk__account_id__r.Name,
                'toolkitYear' => genData[0].cstk__toolkit_id__r.cstk__year__c,
                'toolkitSector' => genData[0].cstk__gf_economic_actvy_sector_desc__c, //Not Mapped, we use it for following queries. Values: AMO;APA;CEM;ENE;GEN;STE;UTI
                'overallAwarenessResult' => genData[0].cstk__overall_awareness_result__c,
                'overallAwarenessDesc'  => genData[0].cstk__overall_awareness_desc__c,
                'overallAwarenessPct' => genData[0].cstk__overall_awareness_pct__c,
                'controversy' => genData[0].get('controversy'),
                'EsGControversyComntDesc' => genData[0].cstk__g_esg_controversy_comnt_desc__c,
                'EsGControversyEventType' => genData[0].cstk__g_esg_controversy_event_type__c,
                'tri' => genData[0].cstk__tri__c,
                'L3SdmEsGOutlookContNatCncDesc' => genData[0].cstk__gf_l_3_sdm_esg_outlook_cont_nat_cnc_desc__c, //Ya no se informaran
                'L4SdmEsGOutlookContNatCncDesc' => genData[0].cstk__gf_l_4_sdm_esg_outlook_cont_nat_cnc_desc__c, //Ya no se informaran
                'L5SdmEsGOutlookContNatCncDesc' => genData[0].cstk__gf_l_5_sdm_esg_outlook_cont_nat_cnc_desc__c, //Ya no se informaran
                'L4SdmEsGEvtsContNatCncDesc' => genData[0].cstk__gf_l_4_sdm_esg_evts_cont_nat_cnc_desc__c,
                'L5SdmEsGEvtsContNatCncDesc' => genData[0].cstk__gf_l_5_sdm_esg_evts_cont_nat_cnc_desc__c,
                'L3SdmEsGEvtsContNatCncDesc' => genData[0].cstk__gf_l_3_sdm_esg_evts_cont_nat_cnc_desc__c,
                'L1SdmEsGEvtsContNatCncDesc' => genData[0].cstk__gf_l_1_sdm_esg_evts_cont_nat_cnc_desc__c,
                'L2SdmEsGEvtsContNatCncDesc' => genData[0].cstk__gf_l_2_sdm_esg_evts_cont_nat_cnc_desc__c,
                'triScore' => genData[0].cstk__gf_tri_final_score_number__c,
                'triValuation' => genData[0].cstk__gf_tri_final_score_label_desc__c,
                'cca' => genData[0].cstk__cca__c,
                'cta' => genData[0].cstk__cta__c,
                'triAssessment' => genData[0].cstk__tri_assessment__c,
                'CcaScClGovnTcfdNumber' => genData[0].cstk__gf_cca_sc_cl_govn_tcfd_number__c,
                'CcaScRkMgmtTcfdNumber' => genData[0].cstk__gf_cca_sc_rk_mgmt_tcfd_number__c,
                'CcaScStrgTcfdNumber' => genData[0].cstk__gf_cca_sc_strg_tcfd_number__c,
                'CcaScClTrgtTcfdNumber' => genData[0].cstk__gf_cca_sc_cl_trgt_tcfd_number__c,
                'CtaScEmProflTecNumber' => genData[0].cstk__gf_cta_sc_em_profl_tec_number__c,
                'CtaRkScLowCbPcyNumber' => genData[0].cstk__gf_cta_rk_sc_low_cb_pcy_number__c,
                'CtaTrnsScPlNumber' => genData[0].cstk__gf_cta_trns_sc_pl_number__c,
                'triDate' => genData[0].cstk__tri_date__c,
                'CarbonCaptureInvType' => genData[0].cstk__g_carbon_capture_inv_type__c,
                'ZrEmScn5YEmIntensityDScNumber' => genData[0].cstk__gf_zr_em_scn_5y_em_intensity_d_sc_number__c,
                'EnrgStorBattInvType' => genData[0].cstk__g_enrg_stor_batt_inv_type__c,
                'EVeChrgInfrInvType' => genData[0].cstk__g_e_ve_chrg_infr_inv_type__c,
                'HydrProdInvType' => genData[0].cstk__g_hydr_prod_inv_type__c,
                'GasOilPrExVchEmIntScoreNumber' => genData[0].cstk__gf_gas_oil_pr_ex_vch_em_int_score_number__c,
                'GreenActivitiesCapexInvScNumber' => genData[0].cstk__gf_green_activities_capex_inv_sc_number__c,
                'BiofuelsRefiningCapacityScNumber' => genData[0].cstk__gf_biofuels_refining_capacity_sc_number__c
            };
        }

        return resGenData;
    }

    /**
    * @description Returns Strategy Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getStrategy(Id toolkitId) {
        Map<String,Object> resStrategy = new Map<String,Object>();

        List<cstk__Strategy__c> strategy = [SELECT cstk__company_affected_by_framework__c, toLabel(cstk__affected_sector__c) affectedSector, cstk__engagement_plan__c, cstk__framework_engagement_link__c,
        cstk__no_engagement_plan_reason__c, cstk__non_compliant_issues__c, cstk__g_thermal_coal_exps_ind_type__c, cstk__gf_thermal_coal_rev_wg_per__c, cstk__g_thermal_coal_exps_i_src_type__c,
        cstk__count_due_diligence_on_framework__c, cstk__how_clients_portfolio_changing__c, cstk__gf_thermal_coal_prod_wg_per__c, CurrencyIsoCode, cstk__total_capex_pledged__c,
        cstk__capex_time_horizon_beginning__c, cstk__capex_annual_percent__c, cstk__capex_time_horizon_end__c, cstk__internal_co2_price__c, cstk__capex_total__c, cstk__g_coal_prgrsv_red_pl_ind_type__c,
        cstk__gf_sustainability_objectives_indt_desc__c, cstk__gf_sust_call_to_action_personalized_desc__c, toLabel(cstk__gf_cust_esg_profile_aspects_improve_id__c) aspectsImpr,
        cstk__gf_sust_commitment_plan_company_con_desc__c, cstk__gf_controversial_production_sb_ind_type__c, cstk__gf_susbsidiary_rels_restrictions_desc__c
        FROM cstk__Strategy__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__year__c = '0000'];

        if (!strategy.isEmpty()) {
            resStrategy = new Map<String,Object>{
                'companyAffectedByFramework' => strategy[0].cstk__company_affected_by_framework__c,
                'affectedSector' => strategy[0].get('affectedSector'),
                'engagementPlan' => strategy[0].cstk__engagement_plan__c,
                'frameworkEngagementLink' => strategy[0].cstk__framework_engagement_link__c,
                'noEngagementPlanReason' => strategy[0].cstk__no_engagement_plan_reason__c,
                'nonCompliantIssues' => strategy[0].cstk__non_compliant_issues__c,
                'ThermalCoalExpsIndType' => strategy[0].cstk__g_thermal_coal_exps_ind_type__c,
                'ThermalCoalRevWgPer' => strategy[0].cstk__gf_thermal_coal_rev_wg_per__c,
                'ThermalCoalExpsISrcType' => strategy[0].cstk__g_thermal_coal_exps_i_src_type__c,
                'countDueDiligenceOnFramework' => strategy[0].cstk__count_due_diligence_on_framework__c,
                'howClientsPortfolioChanging' => strategy[0].cstk__how_clients_portfolio_changing__c,
                'ThermalCoalProdWgPer' => strategy[0].cstk__gf_thermal_coal_prod_wg_per__c,
                'currencyIsoCode' => strategy[0].CurrencyIsoCode,
                'totalCapexPledged' => strategy[0].cstk__total_capex_pledged__c,
                'capexTimeHorizonBeginning' => strategy[0].cstk__capex_time_horizon_beginning__c,
                'capexAnnualPercent' => strategy[0].cstk__capex_annual_percent__c,
                'capexTimeHorizonEnd' => strategy[0].cstk__capex_time_horizon_end__c,
                'internalCo2Price' => strategy[0].cstk__internal_co2_price__c,
                'capexTotal' => strategy[0].cstk__capex_total__c,
                'CoalPrgrsvRedPlIndType' =>  strategy[0].cstk__g_coal_prgrsv_red_pl_ind_type__c,
                'SustainabilityObjectivesIndtDesc' => strategy[0].cstk__gf_sustainability_objectives_indt_desc__c,
                'SustCallToActionPersonalizedDesc' => strategy[0].cstk__gf_sust_call_to_action_personalized_desc__c,
                'CustEsgProfileAspectsImproveId' => strategy[0].get('aspectsImpr'),
                'SustCommitmentPlanCompanyConDesc' => strategy[0].cstk__gf_sust_commitment_plan_company_con_desc__c,
                'ControversialProductionSbIndType' => strategy[0].cstk__gf_controversial_production_sb_ind_type__c,
                'SubsidiaryRelsRestrictionsDesc' => strategy[0].cstk__gf_susbsidiary_rels_restrictions_desc__c
            };
        }

        return resStrategy;

    }

    /**
    * @description Returns Emissions Record Information
    * @param toolkitId: Id of the Toolkit
    * @return List<Map<String, Object>>
    */
    public List<Map<String,Object>> getEmissionRecord(Id toolkitId) {
        List<Map<String,Object>> resEmiRec = new List<Map<String,Object>>();

        List<cstk__Emission_record__c> emisRec = [SELECT cstk__emissions_intensity__c, cstk__emissions_intensity_units__c, cstk__ton_co2_y_scope12__c, cstk__gf_ghg_ems_from_op_number__c,
        cstk__gf_ghg_ems_from_cons_number__c, cstk__year__c, cstk__emissions_intensity_comments__c, cstk__comments__c, cstk__gf_ghg_ems_value_chain_number__c
        FROM cstk__Emission_record__c
        WHERE cstk__toolkit_id__c = :toolkitId
        ORDER BY cstk__year__c DESC LIMIT 10];

        if (!emisRec.isEmpty()) {

            for (cstk__Emission_record__c er : emisRec) {

                resEmiRec.add(new Map<String,Object>{
                    'ERemissionsIntensity' => er.cstk__emissions_intensity__c,
                    'ERemissionsIntensityUnits' => er.cstk__emissions_intensity_units__c,
                    'tonCo2YScope12' => er.cstk__ton_co2_y_scope12__c,
                    'GhgEmsFromOpNumber' => er.cstk__gf_ghg_ems_from_op_number__c,
                    'GhgEmsFromConsNumber' => er.cstk__gf_ghg_ems_from_cons_number__c,
                    'yearEmisRec' => er.cstk__year__c,
                    'emissionsIntensityComments' => er.cstk__emissions_intensity_comments__c,
                    'comments' => er.cstk__comments__c,
                    'GhgEmsValueChainNumber' => er.cstk__gf_ghg_ems_value_chain_number__c
                });
            }
        }

        return resEmiRec;

    }

    /**
    * @description Returns Emission Target Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getEmissionTarget(Id toolkitId) {
        Map<String,Object> resEmisTarg = new Map<String,Object>();

        List<cstk__EmissionTarget__c> emisTarg = [SELECT cstk__additional_comments__c, cstk__emission_reduction_target_year__c, cstk__emission_reduction_base_year__c, cstk__link_sbti__c,
        toLabel(cstk__net_zero_target__c) netZeroTar, cstk__net_zero_target_date__c, toLabel(cstk__paris_alignment__c) parisAlign, toLabel (cstk__science_based_target__c) scienceBased,
        toLabel(cstk__scope__c) scope, toLabel(cstk__target_metric__c) targetMetric, cstk__target_pct_reduction__c, cstk__emissions_intensity__c, cstk__group_alignment_degree__c,
        cstk__carbon_reduction_target_year__c, cstk__emissions_intensity_units__c, cstk__gf_automotive_sc_scn_proj_ems_int_number__c, cstk__gf_energy_sector_scn_proj_ems_int_number__c,
        cstk__gf_ut_sector_scn_proj_ems_int_number__c, cstk__gf_steel_sector_scn_proj_ems_int_number__c, cstk__gf_cement_sector_scn_proj_ems_int_number__c, cstk__gf_atm_sc_gp_align_deg_per__c,
        cstk__gf_energy_sector_group_align_degree_per__c, cstk__gf_ut_sc_gp_align_deg_per__c, cstk__gf_steel_sc_gp_align_deg_per__c, cstk__gf_cement_sc_gp_align_deg_per__c,
        cstk__gf_high_market_adjustment_entities_desc__c, toLabel(cstk__gf_c_revenues_highest_weight_sector_type__c) highSectType, cstk__gf_sc_higher_group_em_intensity_ind_type__c, cstk__gf_c_profits_hi_wg_gp_ac_h_trns_r_type__c,
        cstk__gf_high_trns_risk_ac_customer_ind_type__c
        FROM cstk__EmissionTarget__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__year__c = '0000'];

        if (!emisTarg.isEmpty()) {
            resEmisTarg = new Map<String,Object>{
                'additionalComments' => emisTarg[0].cstk__additional_comments__c,
                'emissionReductionTargetYear' => emisTarg[0].cstk__emission_reduction_target_year__c,
                'emissionReductionBaseYear' => emisTarg[0].cstk__emission_reduction_base_year__c,
                'linkSbti' => emisTarg[0].cstk__link_sbti__c,
                'netZeroTar' => emisTarg[0].get('netZeroTar'),
                'netZeroTargetDate' => emisTarg[0].cstk__net_zero_target_date__c,
                'parisAlign' => emisTarg[0].get('parisAlign'),
                'scienceBased' => emisTarg[0].get('scienceBased'),
                'scope' => emisTarg[0].get('scope'),
                'targetMetric' => emisTarg[0].get('targetMetric'),
                'targetPctReduction' => emisTarg[0].cstk__target_pct_reduction__c,
                'ETemissionsIntensity' => emisTarg[0].cstk__emissions_intensity__c,
                'groupAlignmentDegree' => emisTarg[0].cstk__group_alignment_degree__c,
                'ETcarbonReductionTargetYear' => emisTarg[0].cstk__carbon_reduction_target_year__c,
                'ETemissionsIntensityUnits' => emisTarg[0].cstk__emissions_intensity_units__c,
                'AutomotiveScScnProjEmsIntNumber' => emisTarg[0].cstk__gf_automotive_sc_scn_proj_ems_int_number__c,
                'EnergySectorScnProjEmsIntNumber' => emisTarg[0].cstk__gf_energy_sector_scn_proj_ems_int_number__c,
                'UtSectorScnProjEmsIntNumber' => emisTarg[0].cstk__gf_ut_sector_scn_proj_ems_int_number__c,
                'SteelSectorScnProjEmsIntNumber' => emisTarg[0].cstk__gf_steel_sector_scn_proj_ems_int_number__c,
                'CementSectorScnProjEmsIntNumber' => emisTarg[0].cstk__gf_cement_sector_scn_proj_ems_int_number__c,
                'AtmScGpAlignDegPer' => emisTarg[0].cstk__gf_atm_sc_gp_align_deg_per__c,
                'EnergySectorGroupAlignDegreePer' => emisTarg[0].cstk__gf_energy_sector_group_align_degree_per__c,
                'UtScGpAlignDegreePer' => emisTarg[0].cstk__gf_ut_sc_gp_align_deg_per__c,
                'SteelScGpAlignDegreePer' => emisTarg[0].cstk__gf_steel_sc_gp_align_deg_per__c,
                'CementScGpAlignDegreePer' => emisTarg[0].cstk__gf_cement_sc_gp_align_deg_per__c,
                'HighMarketAdjustmentEntitiesDesc' => emisTarg[0].cstk__gf_high_market_adjustment_entities_desc__c,
                'RevenuesHighestWeightSectorType' => emisTarg[0].get('highSectType'),
                'HigherGroupEmIntensityIndType' => emisTarg[0].cstk__gf_sc_higher_group_em_intensity_ind_type__c,
                'HighTrnsRiskAcCustomerIndType' => (emisTarg[0].cstk__gf_high_trns_risk_ac_customer_ind_type__c != null && emisTarg[0].cstk__gf_high_trns_risk_ac_customer_ind_type__c.equalsIgnoreCase('yes')) ? true : false
            };
            String actLabel;
            if (emisTarg[0].cstk__gf_c_profits_hi_wg_gp_ac_h_trns_r_type__c != null) {
                final cstk.Json_Selector jsonSelector = new cstk.Json_Selector();
                final List<cstk__ESG_Toolkit_Settings_Json__mdt> config = jsonSelector.selectByObjectName('activityLabels');
                final Map<String,Object> allActs = (Map<String,Object>)JSON.deserializeUntyped(config[0].cstk__json__c);
                final List<Object> acts = (List<Object>)allActs.get('activities');
                for(Object o : acts){
                    Map<String,Object> m = (Map<String,Object>)o;
                    if(m.get('code') == emisTarg[0].cstk__gf_c_profits_hi_wg_gp_ac_h_trns_r_type__c) {
                        actLabel = (String)m.get('value');
                        break;
                    }
              }
            }
            resEmisTarg.put('ProfitsHiWgGpAcHTrnsRType', actLabel);
        }
        return resEmisTarg;
    }

    /**
    * @description Returns Rating Information
    * @param toolkitId : Id of the Toolkit
    * @param cla : String with the source of the rating
    * @return List<Map<String, Object>>
    */
    public List<Map<String,Object>> getRating(Id toolkitId) {
        List<Map<String,Object>> resRating = new List<Map<String,Object>>();

        List<cstk__Rating__c> rating = [SELECT toLabel(cstk__category__c) category, cstk__assesment__c, cstk__rating__c, cstk__rank_in_sector__c, cstk__sector_avg__c
        FROM  cstk__Rating__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__source__c = 'cla'
        ORDER BY cstk__year__c DESC LIMIT 4];

        if (!rating.isEmpty()) {

            for (cstk__Rating__c rt : rating) {

                resRating.add(new Map<String,Object>{
                    'category' => rt.get('category'),
                    'assesment' => rt.cstk__assesment__c,
                    'rating' => rt.cstk__rating__c,
                    'rankInSector' => rt.cstk__rank_in_sector__c,
                    'sectorAvg' => rt.cstk__sector_avg__c
                });
            }
        }

        return resRating;

    }

    /**
    * @description Returns Sector Auto Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getSectorAuto(Id toolkitId) {
        Map<String,Object> resSectAuto = new Map<String,Object>();

        List<cstk__Sector_Auto__c> sectAuto = [SELECT Id, cstk__BEV_and_PHEV_pct__c, cstk__date__c, cstk__Plugin_hybrid_vt_2030__c, cstk__sector_auto_id__c, cstk__updated__c,
        cstk__Vehicle_battery_prdct_strtg__c, cstk__year__c
        FROM cstk__Sector_Auto__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__year__c = '0000'];

        if (!sectAuto.isEmpty()) {
            resSectAuto = new Map<String,Object>{
                'IdSectorAuto' => sectAuto[0].Id,
                'BEVAndPHEVPct' => sectAuto[0].cstk__BEV_and_PHEV_pct__c,
                'date' => sectAuto[0].cstk__date__c,
                'pluginHybridVt2030' => sectAuto[0].cstk__Plugin_hybrid_vt_2030__c,
                'sectorAutoId' => sectAuto[0].cstk__sector_auto_id__c,
                'updated' => sectAuto[0].cstk__updated__c,
                'vehicleBatteryPrdctStrtg' => sectAuto[0].cstk__Vehicle_battery_prdct_strtg__c,
                'yearSectorAuto' => sectAuto[0].cstk__year__c
            };
        }

        return resSectAuto;

    }

    /**
    * @description Returns Sector Steel Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getSectorSteel(Id toolkitId) {
        Map<String,Object> resSectSteel = new Map<String,Object>();

        List<cstk__Sector_Steel__c> sectSteel = [SELECT Id, cstk__gf_bof_production_model_per__c, cstk__g_dri_inv_ind_type__c, cstk__g_hydr_use_inv_ind_type__c, cstk__year__c
        FROM cstk__Sector_Steel__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__year__c = '0000'];

        if (!sectSteel.isEmpty()) {
            resSectSteel = new Map<String,Object>{
                'IdSectorSteel' => sectSteel[0].Id,
                'BofProductionModelPer' => sectSteel[0].cstk__gf_bof_production_model_per__c,
                'DriInvIndType' => sectSteel[0].cstk__g_dri_inv_ind_type__c,
                'HydrUseInvIndType' => sectSteel[0].cstk__g_hydr_use_inv_ind_type__c,
                'yearSectorSteel' =>  sectSteel[0].cstk__year__c
            };
        }

        return resSectSteel;
    }

    /**
    * @description Returns Sector Autoparts Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getSectorAutoparts(Id toolkitId) {
        Map<String,Object> resSectAuParts = new Map<String,Object>();

        List<cstk__Sector_Autoparts__c> sectAuParts = [SELECT toLabel(cstk__gf_energy_trns_objetives_plans_ind_type__c) objetivePlans, cstk__gf_el_car_battery_components_mfr_r_per__c,
        cstk__gf_inf_entrt_st_components_mfr_rev_per__c, cstk__gf_el_mobility_components_mfr_rev_per__c, cstk__gf_int_comb_engn_gearbox_c_mfr_r_per__c,
        cstk__gf_transmissions_components_mfr_r_per__c, cstk__year__c, cstk__gf_as_tri_final_score_label_desc__c
        FROM cstk__Sector_Autoparts__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__year__c = '0000'];

        if (!sectAuParts.isEmpty()) {
            resSectAuParts = new Map<String,Object>{
                'objetivePlans' => sectAuParts[0].get('objetivePlans'),
                'elCarBatteryComponentsMfrRPer' => sectAuParts[0].cstk__gf_el_car_battery_components_mfr_r_per__c,
                'infEntrtStComponentsMfrRevPer' => sectAuParts[0].cstk__gf_inf_entrt_st_components_mfr_rev_per__c,
                'elMobilityComponentsMfrRevPer' => sectAuParts[0].cstk__gf_el_mobility_components_mfr_rev_per__c,
                'intCombEngnGearboxCMfrRPer' => sectAuParts[0].cstk__gf_int_comb_engn_gearbox_c_mfr_r_per__c,
                'transmissionsComponentsMfrRPer' => sectAuParts[0].cstk__gf_transmissions_components_mfr_r_per__c,
                'yearSectorAuParts' => sectAuParts[0].cstk__year__c,
                'asTriFinalScoreLabelDesc' => sectAuParts[0].cstk__gf_as_tri_final_score_label_desc__c
            };
        }

        return resSectAuParts;
    }

    /**
    * @description Returns Sector Utilities Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getSectorUtility(Id toolkitId) {
        Map<String,Object> resSectUtil = new Map<String,Object>();

        List<cstk__Sector_Utilities__c> sectUtil = [SELECT Id, cstk__Capex_invested_renewables__c, cstk__Invtmt_carbon__c, cstk__Invtmt_ev_charging_inf__c,
        cstk__Invtmt_hydrogen_production__c, cstk__Production_gwh_hydro_pct__c, cstk__Production_gwh_nuclear_pct__c, cstk__Prod_gwh_other_rnwable_pct__c,
        cstk__year__c, cstk__Production_gwh_coal_pct__c, cstk__Other_high_crbn_act_pct__c
        FROM cstk__Sector_Utilities__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__year__c = '0000'];

        if (!sectUtil.isEmpty()) {
            resSectUtil = new Map<String,Object>{
                'IdSectorUtil' => sectUtil[0].Id,
                'capexInvestedRenewables' => sectUtil[0].cstk__Capex_invested_renewables__c,
                'invtmtCarbon' => sectUtil[0].cstk__Invtmt_carbon__c,
                'invtmtEvChargingInf' => sectUtil[0].cstk__Invtmt_ev_charging_inf__c,
                'invtmtHydrogenProduction' => sectUtil[0].cstk__Invtmt_hydrogen_production__c,
                'productionGwhHydroPct' => sectUtil[0].cstk__Production_gwh_hydro_pct__c,
                'productionGwhNuclearPct' => sectUtil[0].cstk__Production_gwh_nuclear_pct__c,
                'prodGwhOtherRnwablePct' => sectUtil[0].cstk__Prod_gwh_other_rnwable_pct__c,
                'yearSectorUtil' => sectUtil[0].cstk__year__c,
                'productionGwhCoalPct' => sectUtil[0].cstk__Production_gwh_coal_pct__c,
                'otherHighCrbnPct' => sectUtil[0].cstk__Other_high_crbn_act_pct__c
            };
        }

        return resSectUtil;
    }

    /**
    * @description Returns Sector Generic Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getSectorGeneric(Id toolkitId) {
        Map<String,Object> resSectGen = new Map<String,Object>();

        List<cstk__Sector_Generic__c> sectGen = [SELECT cstk__gf_last_year_green_energy_investment_per__c, cstk__gf_tech_emss_comments_desc__c, cstk__year__c
        FROM cstk__Sector_Generic__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__year__c = '0000'];

        if (!sectGen.isEmpty()) {
            resSectGen = new Map<String,Object>{
                'LastYearGreenEnergyInvestmentPer' => sectGen[0].cstk__gf_last_year_green_energy_investment_per__c,
                'TechEmssCommentsDesc' => sectGen[0].cstk__gf_tech_emss_comments_desc__c,
                'yearSectorGen' => sectGen[0].cstk__year__c
            };
        }

        return resSectGen;
    }

    /**
    * @description Returns Sector Cement Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getSectorCement(Id toolkitId) {
        Map<String,Object> resSectCem = new Map<String,Object>();

        List<cstk__Sector_Cement__c> sectCem = [SELECT cstk__gf_clinker_factor_per__c, cstk__gf_thermal_subst_rate_per__c, cstk__gf_renewable_energy_use_per__c, cstk__g_carbon_capture_inv_ind_type__c,
        cstk__g_hydr_use_inv_ind_type__c, cstk__g_altv_mats_to_cement_ind_type__c, cstk__gf_red_trgt_2030_em_int_number__c, cstk__year__c
        FROM cstk__Sector_Cement__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__year__c = '0000'];

        if (!sectCem.isEmpty()) {
            resSectCem = new Map<String,Object>{
                'ClinkerFactorPer' => sectCem[0].cstk__gf_clinker_factor_per__c,
                'ThermalSubstRatePer' => sectCem[0].cstk__gf_thermal_subst_rate_per__c,
                'RenewableEnergyUsePer' => sectCem[0].cstk__gf_renewable_energy_use_per__c,
                'CarbonCaptureInvIndType' => sectCem[0].cstk__g_carbon_capture_inv_ind_type__c,
                'HydrUseInvIndType' => sectCem[0].cstk__g_hydr_use_inv_ind_type__c,
                'AltvMatsToCementIndType' => sectCem[0].cstk__g_altv_mats_to_cement_ind_type__c,
                'RedTrgt2030EmIntNumber' => sectCem[0].cstk__gf_red_trgt_2030_em_int_number__c,
                'yearSectorCem' => sectCem[0].cstk__year__c
            };
        }

        return resSectCem;
    }

    /**
    * @description Returns Sector Energy Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getSectorEnergy(Id toolkitId) {
        Map<String,Object> resSectEne = new Map<String,Object>();

        List<cstk__Sector_Energy__c> sectEne = [SELECT cstk__Gas_production_ot__c, cstk__gf_o_gas_prod_u_cost_amount__c, toLabel(cstk__g_zr_methane_emss_trgt_type__c) methaneEmisTarg,
        cstk__year__c, cstk__gf_o_g_ex_capex_inv_avg_amount__c, cstk__green_capex__c, cstk__Biofuel_capacity_ot__c
        FROM cstk__Sector_Energy__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__year__c = '0000'];

        if (!sectEne.isEmpty()) {
            resSectEne = new Map<String,Object>{
                'gasProductionOt' => sectEne[0].cstk__Gas_production_ot__c,
                'GasProdUCostAmount' => sectEne[0].cstk__gf_o_gas_prod_u_cost_amount__c,
                'methaneEmisTarg' => sectEne[0].get('methaneEmisTarg'),
                'yearSectorEne' => sectEne[0].cstk__year__c,
                'GExCapexInvAvgAmount' => sectEne[0].cstk__gf_o_g_ex_capex_inv_avg_amount__c,
                'greenCapex' => sectEne[0].cstk__green_capex__c,
                'biofuelCapacityOt' => sectEne[0].cstk__Biofuel_capacity_ot__c
            };
        }

        return resSectEne;
    }

    /**
    * @description Returns Transition risk indicator Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getTri(Id toolkitId) {
        Map<String,Object> resTri = new Map<String,Object>();

        List<cstk__tri__c> tri = [SELECT cstk__gf_auto_sector_tri_final_score_number__c, cstk__gf_cement_sector_tri_final_score_number__c, cstk__gf_energy_sector_tri_final_score_number__c,
        cstk__gf_steel_sector_tri_final_score_number__c, cstk__gf_utilities_sc_tri_final_score_number__c, cstk__gf_auto_sc_tri_final_score_label_desc__c, cstk__gf_cement_sc_tri_final_score_label_desc__c,
        cstk__gf_energy_sc_tri_final_score_label_desc__c, cstk__gf_steel_sc_tri_final_score_label_desc__c, cstk__gf_utilities_sc_tri_final_sc_label_desc__c, cstk__gf_auto_sector_c_trns_strg_score_number__c,
        cstk__gf_cement_sector_c_trns_strg_sc_number__c, cstk__gf_steel_sector_c_trns_strg_score_number__c, cstk__gf_oil_gas_sc_c_cl_trns_strg_sc_number__c, cstk__gf_utilities_sc_c_trns_strg_score_number__c
        FROM cstk__tri__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__status__c = 'validated'
        ORDER BY cstk__validated_date__c DESC, LastModifiedDate DESC];

        if (!tri.isEmpty()) {
            resTri = new Map<String,Object>{
                'AutoSectorTriFinalScoreNumber' => tri[0].cstk__gf_auto_sector_tri_final_score_number__c,
                'CementSectorTriFinalScoreNumber' => tri[0].cstk__gf_cement_sector_tri_final_score_number__c,
                'EnergySectorTriFinalScoreNumber' => tri[0].cstk__gf_energy_sector_tri_final_score_number__c,
                'SteelSectorTriFinalScoreNumber' => tri[0].cstk__gf_steel_sector_tri_final_score_number__c,
                'UtilitiesScTriFinalScoreNumber' => tri[0].cstk__gf_utilities_sc_tri_final_score_number__c,
                'AutoScTriFinalScoreLabelDesc' => tri[0].cstk__gf_auto_sc_tri_final_score_label_desc__c,
                'CementScTriFinalScoreLabelDesc' => tri[0].cstk__gf_cement_sc_tri_final_score_label_desc__c,
                'EnergyScTriFinalScoreLabelDesc' => tri[0].cstk__gf_energy_sc_tri_final_score_label_desc__c,
                'SteelScTriFinalScoreLabelDesc' => tri[0].cstk__gf_steel_sc_tri_final_score_label_desc__c,
                'UtilitiesScTriFinalScLabelDesc' => tri[0].cstk__gf_utilities_sc_tri_final_sc_label_desc__c,
                'AutoSectorCTrnsStrgScoreNumber' => tri[0].cstk__gf_auto_sector_c_trns_strg_score_number__c,
                'CementSectorCTrnsStrgScNumber' => tri[0].cstk__gf_cement_sector_c_trns_strg_sc_number__c,
                'SteelSectorCTrnsStrgScoreNumber' => tri[0].cstk__gf_steel_sector_c_trns_strg_score_number__c,
                'OilGasScCTrnsStrgScNumber' => tri[0].cstk__gf_oil_gas_sc_c_cl_trns_strg_sc_number__c,
                'UtilitiesScCTrnsStrgScoreNumber' => tri[0].cstk__gf_utilities_sc_c_trns_strg_score_number__c
            };
        }

        return resTri;
    }

    /**
    * @description Returns Transition risk indicator Autoparts Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getTriAutoParts(Id toolkitId) {
        Map<String,Object> resTriAtp = new Map<String,Object>();

        List<cstk__tri_autoparts__c> triAtp = [SELECT cstk__carbon_reduction_target_year__c, cstk__gf_autoparts_sector_tri_score_number__c, cstk__gf_autoparts_sector_tri_final_score_id__c,
        cstk__gf_tri_autoparts_sector_cta_s_sc_number__c
        FROM cstk__tri_autoparts__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__status__c = 'validated'
        ORDER BY cstk__gf_tri_results_valid_date__c DESC, LastModifiedDate DESC];

        if (!triAtp.isEmpty()) {
            resTriAtp = new Map<String,Object>{
                'TriAutopartsCarbonReductionTargetYear' => triAtp[0].cstk__carbon_reduction_target_year__c,
                'AutopartsSectorTriScoreNumber' => triAtp[0].cstk__gf_autoparts_sector_tri_score_number__c,
                'AutopartsSectorTriFinalScoreId' => triAtp[0].cstk__gf_autoparts_sector_tri_final_score_id__c,
                'TriAutopartsSectorCTAScNumber' => triAtp[0].cstk__gf_tri_autoparts_sector_cta_s_sc_number__c
            };
        }

        return resTriAtp;
    }

    /**
    * @description Returns Transition risk indicator Generic Information
    * @param toolkitId : Id of the Toolkit
    * @return Map<String, Object>
    */
    public Map<String,Object> getTriGeneric(Id toolkitId) {
        Map<String,Object> resTriGen = new Map<String,Object>();

        List<cstk__tri_generic__c> triGen = [SELECT cstk__gf_generic_sector_tri_score_number__c, cstk__gf_generic_sector_tri_score_label_desc__c, cstk__gf_decar_objv_ambition_impl_c_sc_number__c,
        cstk__gf_geo_sector_c_trns_risk_score_number__c, cstk__gf_generic_sector_tri_final_score_number__c
        FROM cstk__tri_generic__c
        WHERE cstk__toolkit_id__c = :toolkitId AND cstk__status__c = 'validated'
        ORDER BY cstk__gf_tri_results_valid_date__c DESC, LastModifiedDate DESC];

        if (!triGen.isEmpty()) {
            resTriGen = new Map<String,Object>{
                'GenericSectorTriScoreNumber' => triGen[0].cstk__gf_generic_sector_tri_score_number__c,
                'GenericSectorTriFinalScoreNumber' => triGen[0].cstk__gf_generic_sector_tri_final_score_number__c,
                'GenericSectorTriScoreLabelDesc' => triGen[0].cstk__gf_generic_sector_tri_score_label_desc__c,
                'DecarObjvAmbitionImplCScNumber' => triGen[0].cstk__gf_decar_objv_ambition_impl_c_sc_number__c,
                'GeoSectorCTransRiskScoreNumber' => triGen[0].cstk__gf_geo_sector_c_trns_risk_score_number__c
            };
        }

        return resTriGen;
    }

    /**
    * @description Dispatch actual methods
    * @param action : name of method
    * @param toolkitId : toolkit Id
    */
    public Object call(String action, Map<String, Object> args) {
        Object response = null;
        String toolkitId = (String)args.get('toolkitId');
        switch on action {
            when 'getGeneralData' {
                response = this.getGeneralData(toolkitId);
            }
            when 'getStrategy' {
                response = this.getStrategy(toolkitId);
            }
            when 'getEmissionRecord' {
                response = this.getEmissionRecord(toolkitId);
            }
            when 'getEmissionTarget' {
                response = this.getEmissionTarget(toolkitId);
            }
            when 'getRating' {
                response = this.getRating(toolkitId);
            }
            when 'getSectorAuto' {
                response = this.getSectorAuto(toolkitId);
            }
            when 'getSectorSteel' {
                response = this.getSectorSteel(toolkitId);
            }
            when 'getSectorAutoparts' {
                response = this.getSectorAutoparts(toolkitId);
            }
            when 'getSectorUtility' {
                response = this.getSectorUtility(toolkitId);
            }
            when 'getSectorGeneric' {
                response = this.getSectorGeneric(toolkitId);
            }
            when 'getSectorCement' {
                response = this.getSectorCement(toolkitId);
            }
            when 'getSectorEnergy' {
                response = this.getSectorEnergy(toolkitId);
            }
            when 'getTri' {
                response = this.getTri(toolkitId);
            }
            when 'getTriAutoParts' {
                response = this.getTriAutoParts(toolkitId);
            }
            when 'getTriGeneric' {
                response = this.getTriGeneric(toolkitId);
            }
            when else {
                throw new ExtensionMalformedCallException('Method not implemented');
            }
        }
        return response;
    }

    /**
    * @description Extension class exception
    */
    public class ExtensionMalformedCallException extends Exception {}
}