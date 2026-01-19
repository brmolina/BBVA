/**
* @author       Global Desktop
* @date         22/11/2019
* @description  Condiciones de la botonera de Account Planning
* @Revision
*/
global with sharing class DES_APDynamicButtonsStatusHandler implements dwp_dbpn.DynamicButtonsStatusInterface {

    /**
    * muestra los botones de la botonera en el AP
    */
    global static Set<String> getDynamicButtonStatus(String recordId, String sObjectName) {
        Set<String> buttonsStatusSet;
        buttonsStatusSet = new Set<String>();

        //Id del AP para obtener el estado
        final acpl__Account_Planning__c accountPlan = [SELECT Id, acpl__gf_ap_status_type_name__c, acpl__gf_ap_substatus_type_name__c, acpl__gf_ap_indvi_lock_edit_ind_type__c
                                            FROM acpl__Account_Planning__c
                                            WHERE Id = :recordId LIMIT 1].get(0);

        //Rol del usuario
        acpl__Account_Plan_Settings__c apSetting;
        apSetting = acpl__Account_Plan_Settings__c.getInstance();

        //Si ap validated, in place y rol correcto, añado el botón "Modify BP"
        if(apValidatedInPlace(accountPlan) && hasCorrectRole(accountPlan, apSetting)) {
            buttonsStatusSet.add('AP_Modify_Business_Plan');
        }

        //Si ap validated, under review y rol correcto, añado el botón "Ask for Validation"
        if(apValUndrRvw(accountPlan) && hasCorrectRole(accountPlan, apSetting)) {
            buttonsStatusSet.add('AP_Ask_for_validation');
        }

        //Si ap desbloqueado, añado los botones de "Growth Drivers" y "Needs"
        if(accountPlan.acpl__gf_ap_indvi_lock_edit_ind_type__c) {
            buttonsStatusSet.add('AP_New_Growth_Driver');
            buttonsStatusSet.add('AP_New_Need');
        }
        return buttonsStatusSet;
    }

    /*
    * @author       Global Desktop
    * @Description  Checks if the Account Plan is Validated and In Place
    */
    public static Boolean apValidatedInPlace(acpl__Account_Planning__c accountPlan) {
        Boolean isInPlace = false;
        if (accountPlan != null && accountPlan.acpl__gf_ap_status_type_name__c == Label.AP_Validated && accountPlan.acpl__gf_ap_substatus_type_name__c  == Label.AP_In_Place) {
            isInPlace = true;
        }
        return isInPlace;
    }

    /*
    * @author       Global Desktop
    * @Description  Checks if the Account Plan is Validated and In Place
    */
    public static Boolean apValUndrRvw(acpl__Account_Planning__c accountPlan) {
        Boolean isUndrRvw = false;
        if (accountPlan != null && accountPlan.acpl__gf_ap_status_type_name__c == Label.AP_Validated && accountPlan.acpl__gf_ap_substatus_type_name__c  == Label.AP_UnderReview) {
            isUndrRvw = true;
        }
        return isUndrRvw;
    }

    /*
    * @author       Global Desktop
    * @Description  Checks if the current user has the role defined in the custom setting
    */
    public static Boolean hasCorrectRole(acpl__Account_Planning__c accountPlan, acpl__Account_Plan_Settings__c apSetting) {
        Boolean hasCorrectRole = false;
        if(apSetting.acpl__Member_Role__c == null || apSetting.acpl__Member_Role__c== '') {
            hasCorrectRole = true;
        } else {
            final List <bupl__AP_Team__c> apTeamList = [SELECT Id, bupl__gf_ap_team_role_user_name__c, bupl__gf_ap_team_user_id__c
                                                  FROM bupl__AP_Team__c
                                                  WHERE bupl__gf_ap_team_role_user_name__c = :apSetting.acpl__Member_Role__c  AND acpl__gf_account_planning_id__c =:accountPlan.Id LIMIT 1];

            System.debug('apTeamList:' + apTeamList);
            if(!apTeamList.isEmpty()) {
                Set<Id> apTeamIdSet;
                apTeamIdSet = new Set<Id>();
                for(bupl__AP_Team__c apTeamMAux :apTeamList) {
                    apTeamIdSet.add(apTeamMAux.bupl__gf_ap_team_user_id__c);
                }
                System.debug('apTeamIdSet:' + apTeamIdSet);
                System.debug('userInfo.getUserId():' + userInfo.getUserId());
                if(apTeamIdSet.contains(userInfo.getUserId())) {
                    hasCorrectRole = true;
                }
            }
        }

        return hasCorrectRole;
    }

}