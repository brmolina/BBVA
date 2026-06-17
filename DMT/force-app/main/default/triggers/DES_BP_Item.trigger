/**
* @author       Global Desktop
* @date         29/10/2019
* @description  Trigger de BP_Need__c
* @Revision
*
* Version   Date            Author          Summary of changes
* 
*/
trigger DES_BP_Item on bupl__BusinessPlan_Item__c (after update, after insert) {
    final acpl.BP_ItemHandler bpiHandler = acpl.BP_ItemHandler.getInstance();
    final DES_BP_ItemHandler des_bpiHandler = DES_BP_ItemHandler.getInstance();
    final String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].get(0).Name;

    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            des_bpiHandler.insertLocalAnalysis(Trigger.new);
        } else if(Trigger.isUpdate) {
            if (profileName != LABEL.DES_ADMIN_PROFILE && profileName != LABEL.DES_INTEGRATION_PROFILE) {
                bpiHandler.updateStatusOnAP(Trigger.newMap);
            }
        }
    }
}