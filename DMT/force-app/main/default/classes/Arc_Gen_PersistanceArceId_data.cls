/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistanceArceId_data
* @Author  Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
* @Date     Created: 03/09/2019
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Uses Data to conect to Risk Assesment service
* ------------------------------------------------------------------------------------------------
* @Changes
* 28/07/2019    ricardo.almanza.contractor@bbva.com
*               Class creation.
* 01/12/2019    german.sanchez.perez.contractor@bbva.com | franciscojavier.bueno@bbva.com
*               Api names modified with the correct name on business glossary
* 29/01/2020    javier.soto.carrascosa@bbva.com
*               Remove account wrapper fields and add checkbox to control risk assessment persistance
* 09/02/2020    javier.soto.carrascosa@bbva.com
*               Changed logic to identify header of assessment
* 09/07/2020    ricardo.almanza.contractor@bbva.com
*               Added to persistanceDataAcc fields arce__anlys_wkfl_cnsld_ffss_type__c, arce__analysis_template_id__c for manual triage
* 11/08/2020    javier.soto.carrascosa@bbva.com
*               Update sector field
* 22/01/2021    saimassimilianno.jordana.contractor@bbva.com
*               Add arce__CustomAccountID__c field to all AccHasAnalysis queries.
* |2020-03-12   juanpedro.benito.contractor@bbva.com
*               Change arce__subsector_desc__c for arce__subsector_id__c, arce__sector_desc__c for arce__sector_id__c and arce__sector_building_desc__c for arce__sector_building_type__c
* |2021-06-17   juanignacio.hita.contractor@bbva.com
*               Rollback last commit  (PR: 1231)
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_PersistanceArceId_data {
    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets AccHas Analysis of child reg of the parameters to the persistance service
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 03/09/2019
    * @param String analysisId id of analysis
    * @param String idArceS id of Acc related
    * @example public static arce__Account_has_Analysis__c persistanceDataS(String analysisId, String idArceS)
    **/
    private Arc_Gen_PersistanceArceId_data() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets AccHas Analysis of child reg of the parameters to the persistance service
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 03/09/2019
    * @param String analysisId id of analysis
    * @param String idArceS id of Acc related
    * @example public static arce__Account_has_Analysis__c persistanceDataS(String analysisId, String idArceS)
    **/
    public static arce__Account_has_Analysis__c persistanceDataS(String analysisId, String idArceS) {
        return[Select Id, Name, arce__Analysis__c, arce__Customer__c, arce__InReview__c,
            arce__current_proposed_amount__c, arce__current_proposed_local_amount__c,
            arce__ead_amount__c, arce__ebitda_interest_number__c, arce__ffss_for_rating_id__c,
            arce__geography_outlook_type__c, arce__gross_financial_debt_amount__c,
            arce__group_asset_header_type__c, arce__limit_asset_allocation_date__c,
            arce__ll_adj_debt_amount__c, arce__ll_adj_ebitda_amount__c,
            arce__main_subsidiary_ind_type__c, arce__path__c, arce__risk_growth_amount__c,
            arce__sector_avg_prblty_default_per__c, arce__sector_avg_prblty_dflt_date__c,
            arce__sector_building_desc__c, arce__sector_desc__c, arce__sector_outlook_type__c,
            arce__analysis_template_id__c, arce__service_type_name__c,
            arce__shrhldr_fin_sponsor_profl_type__c, arce__total_asset_amount__c,
            arce__total_asset_local_amount__c, arce__gf_total_debt_amount__c,
            arce__gf_total_revenues_ytd_amount__c, arce__branch_id__c, arce__rating_branch_level_id__c,
            arce__outstanding_amount__c, arce__arce_ctmr_flag__c,
            arce__anlys_wkfl_sbanlys_status_type__c, arce__gf_company_economic_actvy_id__c,
            arce__economic_activity_sector_desc__c, arce__debt_comt_not_disb_local_amount__c,
            arce__debt_comt_not_disb_amount__c, arce__exposure_at_default_date__c,
            arce__limit_asset_allocation_amount__c, arce__rating_econ_sector_tmpl_id__c, arce__subsector_desc__c,
            arce__WF_Stage_WF_Status__c, arce__portfolio_class_type__c,
            arce__Customer__r.controlled_by_sponsor_type__c, arce__risk_assessment_persisted__c, arce__CustomAccountID__c
            from arce__Account_has_Analysis__c
            where arce__Analysis__c = :analysisId and arce__group_asset_header_type__c = '2' and arce__Customer__c = :idArceS];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets AccHas Analysis of parent reg of the parameters to the persistance service
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 03/09/2019
    * @param String analysisId id of analysis
    * @example public static arce__Account_has_Analysis__c persistanceDataS(String analysisId, String idArceS)
    **/
    public static arce__Account_has_Analysis__c persistanceDataAcc(String analysisId) {
        return[Select Id, Name, arce__Analysis__c,arce__Customer__c, arce__InReview__c,
            arce__current_proposed_amount__c, arce__current_proposed_local_amount__c,
            arce__ead_amount__c, arce__ebitda_interest_number__c, arce__ffss_for_rating_id__c,
            arce__geography_outlook_type__c, arce__gross_financial_debt_amount__c,
            arce__group_asset_header_type__c, arce__limit_asset_allocation_date__c,
            arce__ll_adj_debt_amount__c, arce__ll_adj_ebitda_amount__c,
            arce__main_subsidiary_ind_type__c, arce__path__c, arce__risk_growth_amount__c,
            arce__sector_avg_prblty_default_per__c, arce__sector_avg_prblty_dflt_date__c,
            arce__sector_building_desc__c, arce__sector_desc__c, arce__sector_outlook_type__c,
            arce__analysis_template_id__c, arce__service_type_name__c,
            arce__shrhldr_fin_sponsor_profl_type__c, arce__total_asset_amount__c,
            arce__total_asset_local_amount__c, arce__gf_total_debt_amount__c,
            arce__gf_total_revenues_ytd_amount__c, arce__branch_id__c, arce__rating_branch_level_id__c,
            arce__outstanding_amount__c, arce__arce_ctmr_flag__c,
            arce__anlys_wkfl_sbanlys_status_type__c, arce__gf_company_economic_actvy_id__c,
            arce__economic_activity_sector_desc__c, arce__debt_comt_not_disb_local_amount__c,
            arce__debt_comt_not_disb_amount__c, arce__exposure_at_default_date__c,
            arce__limit_asset_allocation_amount__c, arce__rating_econ_sector_tmpl_id__c, arce__subsector_desc__c,
            arce__WF_Stage_WF_Status__c, arce__portfolio_class_type__c, arce__CustomAccountID__c,
            arce__Customer__r.controlled_by_sponsor_type__c, arce__risk_assessment_persisted__c, arce__anlys_wkfl_cnsld_ffss_type__c
            from arce__Account_has_Analysis__c
            where arce__Analysis__c = :analysisId ORDER BY arce__group_asset_header_type__c ASC LIMIT 1];
    }
}