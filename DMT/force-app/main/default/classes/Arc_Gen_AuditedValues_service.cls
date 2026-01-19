/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AuditedValues_service
* @Author   Israel Rodríguez Ramos  israel.rodriguez.ramos.contractor@bbva.com
* @Date     Created: 27/05/2021
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Data class for object arce__Audited_Values__c
* -----------------------------------------------------------------------------------------------
*_______________________________________________________________________________________
* @Changes
*Version    Date           Author                                       Description
*1.0        27/05/2021     israel.rodriguez.ramos.contractor@bbva.com   Creación.
*1.1        05/08/2021     juanignacio.hita.contractor@bbva.com         Refactor checkAction, migrate methods AuditedValues_Data class
-----------------------------------------------------------------------------------------*/
public with sharing class Arc_Gen_AuditedValues_service {
    /**
    * @Description Constant that stores the "propose" literal.
    */
    public static final String ACTION_PROPOSE = 'propose';
    /**
    * @Description Constant that stores the "sanction" literal.
    */
    public static final String ACTION_SANCTION = 'sanction';
    /**
    * @Description Constant Total Corporate Risk tipology code
    */
    public static final String TOTAL_CORPORATE = 'TP_0003';

    /**
    * @Description Private constructor to avoid sonar warnings.
    */
    private Arc_Gen_AuditedValues_service() {}

    /**
    *-------------------------------------------------------------------------------
    * @Description Update/Create Audited Values from AHA reg
    *-------------------------------------------------------------------------------
    * @author  israel.rodriguez.ramos.contractor@bbva.com
    * @date     26/05/2021
    * @param aha arce__Account_has_Analysis__c reg
    * @param saveType  Propose or Sanction
    * @return void
    * @example Arc_Gen_AuditedValues_service.checkAction(arce__Account_has_Analysis__c, 'Propose')
    *-------------------------------------------------------------------------------
    **/
    public static void checkAction(Id analysisId, String saveType) {
        final List<arce__Account_has_Analysis__c> ahaActivated = new List<arce__Account_has_Analysis__c>();
        final List<Id> ahaId = new List<Id>();
        for (arce__Account_has_Analysis__c aha : arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{analysisId})) {
            if (aha.arce__InReview__c == true) {
                ahaId.add(aha.Id);
                ahaActivated.add(aha);
            }
        }
        final Map<Id,arce__Audited_Values__c> mapAudited = Arc_Gen_AuditedValues_Data.getMapAuditValues(ahaId);
        final Map<Id,arce__limits_exposures__c> mapLimExp003 = Arc_Gen_AuditedValues_Data.getMapLimitExposures(ahaId);

        final List<arce__Audited_Values__c> upsertAuditedValues = new List<arce__Audited_Values__c>();
        for (arce__Account_has_Analysis__c aha : ahaActivated) {
            arce__Audited_Values__c auditedFinal = new arce__Audited_Values__c();
            if(mapAudited.containsKey(aha.Id)) {
                final arce__Audited_Values__c auditedFound = mapAudited.get(aha.Id);
                auditedFinal = auditedFound;
            }
            if(saveType == ACTION_PROPOSE) {
                upsertAuditedValues.add(savePropose(aha, auditedFinal, mapLimExp003.get(aha.Id)));
            } else if(saveType == ACTION_SANCTION) {
                upsertAuditedValues.add(saveSanction(aha, auditedFinal, mapLimExp003.get(aha.Id)));
            } else {
                arce.Arc_Gen_GenericUtilities.throwAuraExcept(System.Label.Arc_Gen_ApexCallError);
            }
        }
        Arc_Gen_AuditedValues_Data.upsertReg(upsertAuditedValues);
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Update/Create Propose fields
    *-------------------------------------------------------------------------------
    * @author  israel.rodriguez.ramos.contractor@bbva.com
    * @date     26/05/2021
    * @param aha arce__Account_has_Analysis__c reg
    * @param audited  arce__Audited_Values__c reg
    * @param limitExposure003  arce__limits_exposures__c reg
    * @return void
    * @example Arc_Gen_AuditedValues_service.savePropose(arce__Account_has_Analysis__c, arce__Audited_Values__c, arce__limits_exposures__c)
    *-------------------------------------------------------------------------------
    **/
    public static arce__Audited_Values__c savePropose(arce__Account_has_Analysis__c aha, arce__Audited_Values__c audited, arce__limits_exposures__c limitExposure003) {
        audited.arce__Account_has_Analysis__c = aha.Id;
        audited.Name = aha.Name;
        audited.arce__fnl_long_rtg_val_psl_id__c = aha.arce__ffss_for_rating_id__r.arce__rating_long_value_type__c;
        audited.arce__pd_psl_per__c = aha.arce__ffss_for_rating_id__r.arce__pd_per__c;
        audited.arce__cur_apprv_deleg_rm_psl_amount__c = limitExposure003.arce__curr_apprv_deleg_rm_amount__c;
        audited.arce__cur_apprv_limit_term_psl_id__c = limitExposure003.arce__current_apprv_limit_term_id__c;
        audited.arce__stdln_long_rtg_val_psl_id__c = aha.arce__long_rating_value_type__c;
        audited.arce__currency_psl_id__c = aha.arce__currency_id__c;
        audited.arce__current_frmlzd_psl_amount__c = aha.arce__current_formalized_amount__c;
        audited.arce__outstanding_psl_amount__c = aha.arce__outstanding_amount__c;
        audited.arce__current_proposed_psl_amount__c = aha.arce__current_proposed_amount__c;
        audited.arce__magnitude_unit_psl_type__c = aha.arce__magnitude_unit_type__c;
        audited.arce__last_approved_psl_amount__c = aha.arce__last_approved_amount__c;
        audited.arce__ll_after_adj_ind_psl_type__c = aha.arce__ll_after_adj_ind_type__c;
        audited.arce__ll_before_adj_ind_psl_type__c = aha.arce__ll_before_adj_ind_type__c;
        audited.arce__ll_after_adj_clsfn_psl_type__c = aha.arce__ll_after_adj_clsfn_type__c;
        audited.arce__ll_bf_adj_clsfn_psl_type__c = aha.arce__ll_before_adj_clsfn_type__c;
        audited.arce__ll_test_manl_excl_rsn_psl_type__c = aha.arce__ll_test_manl_excl_rsn_type__c;
        audited.arce__risk_policy_psl_type__c = aha.arce__risk_policy_type__c;
        audited.arce__smes_eur_comuty_psl_type__c = aha.arce__smes_eur_comuty_defn_type__c;
        audited.arce__total_rtg_score_psl_number__c = aha.arce__total_rating_score_number__c;
        return audited;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Update/Create Sanction fields
    *-------------------------------------------------------------------------------
    * @author  israel.rodriguez.ramos.contractor@bbva.com
    * @date     26/05/2021
    * @param aha arce__Account_has_Analysis__c reg
    * @param audited  arce__Audited_Values__c reg
    * @param limitExposure003  arce__limits_exposures__c reg
    * @return void
    * @example Arc_Gen_AuditedValues_service.savePropose(arce__Account_has_Analysis__c, arce__Audited_Values__c, arce__limits_exposures__c)
    *-------------------------------------------------------------------------------
    **/
    public static arce__Audited_Values__c saveSanction(arce__Account_has_Analysis__c aha, arce__Audited_Values__c audited, arce__limits_exposures__c limitExposure003) {
        audited.arce__Account_has_Analysis__c = aha.Id;
        audited.Name = aha.Name;
        audited.arce__fnl_long_rtg_val_sctn_id__c = aha.arce__ffss_for_rating_id__r.arce__rating_long_value_type__c;
        audited.arce__pd_sctn_per__c = aha.arce__ffss_for_rating_id__r.arce__pd_per__c;
        audited.arce__cur_apprv_deleg_rm_sctn_amount__c = limitExposure003.arce__curr_apprv_deleg_rm_amount__c;
        audited.arce__cur_apprv_limit_term_sctn_id__c = limitExposure003.arce__current_apprv_limit_term_id__c;
        audited.arce__stdln_long_rtg_val_sctn_id__c = aha.arce__long_rating_value_type__c;
        audited.arce__currency_sctn_id__c = aha.arce__currency_id__c;
        audited.arce__current_frmlzd_sctn_amount__c = aha.arce__current_formalized_amount__c;
        audited.arce__outstanding_sctn_amount__c = aha.arce__outstanding_amount__c;
        audited.arce__current_proposed_sctn_amount__c = aha.arce__current_proposed_amount__c;
        audited.arce__magnitude_unit_sctn_type__c = aha.arce__magnitude_unit_type__c;
        audited.arce__last_approved_sctn_amount__c = aha.arce__last_approved_amount__c;
        audited.arce__ll_after_adj_ind_sctn_type__c = aha.arce__ll_after_adj_ind_type__c;
        audited.arce__ll_before_adj_ind_sctn_type__c = aha.arce__ll_before_adj_ind_type__c;
        audited.arce__ll_after_adj_clsfn_sctn_type__c = aha.arce__ll_after_adj_clsfn_type__c;
        audited.arce__ll_bf_adj_clsfn_sctn_type__c = aha.arce__ll_before_adj_clsfn_type__c;
        audited.arce__ll_test_manl_excl_rsn_sctn_type__c = aha.arce__ll_test_manl_excl_rsn_type__c;
        audited.arce__risk_policy_sctn_type__c = aha.arce__risk_policy_type__c;
        audited.arce__smes_eur_comuty_sctn_type__c = aha.arce__smes_eur_comuty_defn_type__c;
        audited.arce__total_rtg_score_sctn_number__c = aha.arce__total_rating_score_number__c;
        return audited;
    }

}