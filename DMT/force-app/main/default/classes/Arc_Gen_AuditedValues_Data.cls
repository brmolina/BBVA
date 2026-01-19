/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AuditedValues_Data
* @Author   Israel Rodríguez Ramos  israel.rodriguez.ramos.contractor@bbva.com
* @Date     Created: 26/05/2021
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Data class for object arce__Audited_Values__c
* -----------------------------------------------------------------------------------------------
*_______________________________________________________________________________________
* @Changes
*Version    Date           Author                                       Description
*1.0        26/05/2021     israel.rodriguez.ramos.contractor@bbva.com   Creación.
*1.1        05/08/2021     juanignacio.hita.contractor@bbva.com         Create getMapAuditValues & getMapLimitExposures methods
-----------------------------------------------------------------------------------------*/
public without sharing class Arc_Gen_AuditedValues_Data {
    /**
    * @Description Private constructor to avoid sonar warnings.
    */
    private Arc_Gen_AuditedValues_Data() {}

    /**
    *-------------------------------------------------------------------------------------------
    * @description save Audited Values register from arce__Account_has_Analysis__c  data
    *-------------------------------------------------------------------------------------------
    * @date		26/05/2021
    * @author	israel.rodriguez.ramos.contractor@bbva.com
    * @param	arce__Audited_Values__c
    * @return	void
    * @example	Arc_Gen_AuditedValues_Data.upsertReg(arce__Audited_Values__c);
    */
    public static void upsertReg(List<arce__Audited_Values__c> auditeds) {
        try {
            UPSERT auditeds;
        } catch (Exception ex) {
            system.debug('Exception: ' + ex.getMessage() + ' | Stack trace: ' + ex.getStackTraceString());
        }
    }

    /**
    *-------------------------------------------------------------------------------------------
    * @description get Audited Values register from arce__Account_has_Analysis__c id
    *-------------------------------------------------------------------------------------------
    * @date		26/05/2021
    * @author	israel.rodriguez.ramos.contractor@bbva.com
    * @param	ahaId Id
    * @return	List<arce__Audited_Values__c>
    * @example	Arc_Gen_AuditedValues_Data.getData(Id ahaId);
    */
    private static List<arce__Audited_Values__c> getData(List<Id> ahaIds) {
        return [SELECT arce__Account_has_Analysis__c, Name,
        arce__Outstanding_sctn_amount__c, arce__currency_psl_id__c, arce__currency_sctn_id__c,
        arce__current_frmlzd_psl_amount__c, arce__current_frmlzd_sctn_amount__c,
        arce__current_proposed_psl_amount__c, arce__current_proposed_sctn_amount__c,
        arce__last_approved_psl_amount__c, arce__last_approved_sctn_amount__c,
        arce__ll_after_adj_clsfn_psl_type__c, arce__ll_after_adj_clsfn_sctn_type__c,
        arce__ll_after_adj_ind_psl_type__c, arce__ll_after_adj_ind_sctn_type__c,
        arce__ll_before_adj_ind_psl_type__c, arce__ll_before_adj_ind_sctn_type__c,
        arce__ll_bf_adj_clsfn_psl_type__c, arce__ll_bf_adj_clsfn_sctn_type__c,
        arce__ll_test_manl_excl_rsn_psl_type__c, arce__ll_test_manl_excl_rsn_sctn_type__c,
        arce__magnitude_unit_psl_type__c, arce__magnitude_unit_sctn_type__c,
        arce__outstanding_psl_amount__c, arce__risk_policy_psl_type__c,
        arce__risk_policy_sctn_type__c, arce__smes_eur_comuty_psl_type__c,
        arce__smes_eur_comuty_sctn_type__c, arce__total_rtg_score_psl_number__c,
        arce__total_rtg_score_sctn_number__c, arce__cur_apprv_deleg_rm_psl_amount__c,
        arce__cur_apprv_deleg_rm_sctn_amount__c, arce__cur_apprv_limit_term_psl_id__c,
        arce__cur_apprv_limit_term_sctn_id__c, arce__fnl_long_rtg_val_psl_id__c,
        arce__fnl_long_rtg_val_sctn_id__c, arce__pd_psl_per__c, arce__pd_sctn_per__c,
        arce__stdln_long_rtg_val_psl_id__c, arce__stdln_long_rtg_val_sctn_id__c
                FROM arce__Audited_Values__c
                WHERE arce__Account_has_Analysis__c = :ahaIds];
    }

    /**
    *-------------------------------------------------------------------------------------------
    * @description Returns a map with audited values data
    *-------------------------------------------------------------------------------------------
    * @date		05/08/2021
    * @author	juanignacio.hita.contractor@bbva.com
    * @param	ahaId Id
    * @return	Map<Id, arce__Audited_Values__c>
    * @example	Map<Id, arce__Audited_Values__c> map = getMapAuditValues(ahaId);
    */
    public static Map<Id, arce__Audited_Values__c> getMapAuditValues(List<Id> ahaId) {
        final Map<Id,arce__Audited_Values__c> mapAudited = new Map<Id,arce__Audited_Values__c>();
        for (arce__Audited_Values__c audi : getData(ahaId)) {
            mapAudited.put(audi.arce__Account_has_Analysis__c,audi);
        }
        return mapAudited;
    }

    /**
    *-------------------------------------------------------------------------------------------
    * @description Returns map of limit exposure records of TP_0003 tipology
    *-------------------------------------------------------------------------------------------
    * @date		05/08/2021
    * @author	juanignacio.hita.contractor@bbva.com
    * @param	ahaId Id
    * @return	Map<Id,arce__limits_exposures__c>
    * @example	Map<Id,arce__limits_exposures__c> mapLimits = getMapLimitExposures(ahaId);
    */
    public static Map<Id,arce__limits_exposures__c> getMapLimitExposures(List<Id> ahaId) {
        final Map<Id,arce__limits_exposures__c> mapLimExp003 = new Map<Id,arce__limits_exposures__c>();
        for (arce__limits_exposures__c limExp003 : arce.Arc_Gen_LimitsExposures_Data.getExposureByDevName(ahaId, new List<String>{Arc_Gen_AuditedValues_service.TOTAL_CORPORATE})) {
            mapLimExp003.put(limExp003.arce__account_has_analysis_id__c,limExp003);
        }
        return mapLimExp003;
    }

}