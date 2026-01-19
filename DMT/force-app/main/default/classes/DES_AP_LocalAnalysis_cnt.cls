/*
@Author : Global Desktop
@Created Date : 07/05/2020
*/
public without sharing class DES_AP_LocalAnalysis_cnt {//NOSONAR

    /**
    * @author Global Desktop
    * @Description Invocable method from Lightning components
    */
    @AuraEnabled
    public static Boolean isTeamMember(String recordId) {
        final List<bupl__AP_Team__c> apTeamList = [SELECT bupl__gf_ap_team_user_id__c FROM bupl__AP_Team__c WHERE acpl__gf_account_planning_id__c = :recordId];
        Set<Id> userSet;
        userSet = new Set<Id>();
        for(bupl__AP_Team__c memberAux : apTeamList) {
            userSet.add(memberAux.bupl__gf_ap_team_user_id__c);
        }
        return userSet.contains(UserInfo.getUserId());
    }
    
    /**
    * @author Global Desktop
    * @Description Invocable method from Lightning components
    */
    @AuraEnabled
    public static List<DES_Local_Analysis__c> getCountries(String recordId) {
        return [SELECT Id, country_name__c FROM DES_Local_Analysis__c WHERE gf_account_planning_id__c = :recordId ORDER BY country_name__c ASC];
    }
    
    /**
    * @author Global Desktop
    * @Description Invocable method from Lightning components
    */
    @AuraEnabled
    public static List<DES_Local_Analysis__c> getAmountValues(String recordId) {
        return [SELECT Id, country_name__c, ConvertCurrency(gf_est_ginc_lcl_product_amount__c), ConvertCurrency(gf_tl_cmt_grp_lcl_loc_amount__c), ConvertCurrency(gf_tl_drc_lcl_unfund_gp_amount__c), ConvertCurrency(gf_total_outstd_grp_lcl_amount__c), ConvertCurrency(gf_total_revenues_ytd_amount__c), ConvertCurrency(net_profit_amount__c), ConvertCurrency(tot_liabilities_equity_amount__c), ConvertCurrency(total_asset_amount__c) FROM DES_Local_Analysis__c WHERE Id = :recordId LIMIT 1];
    	
    }
}