/**
* @author        Global Desktop
* @date         09/03/2020
* @description  Controlador del componente de privacidad del Business Plan
* @Revision
*
* Version   Date            Author          Summary of changes
*/
public without sharing class DES_DisclaimersBusinessPlan {

    /*
    * SINGLETON PATTERN
    */
    private static DES_DisclaimersBusinessPlan instance;

    /*
    * getInstance
    */
    private DES_DisclaimersBusinessPlan() {  }

    /*
    * getInstance
    */
	@SuppressWarnings('sf:AvoidGetSetMethods')
    public static DES_DisclaimersBusinessPlan getInstance() {
        if (instance == null) instance = new DES_DisclaimersBusinessPlan();//NOSONAR
        return instance;
    }

    @AuraEnabled
    /*
    * @author     Global Desktop
    * @Description  Retrieves Privacy settings from Business Plan
    */
     public static Boolean getBPPrivacy (Id idAP) {
        final list<bupl__BusinessPlan__c > lstBP = [select Id, bupl__gf_ap_public_ind_type__c from bupl__BusinessPlan__c where acpl__gf_account_planning_id__c =:idAP];
        return (Boolean) lstBP.get(0).bupl__gf_ap_public_ind_type__c;
     }
}