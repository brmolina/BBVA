/**
* @author       Global Desktop
* @date         2019/11/08
* @description  Trigger de Business Plan Version
* @Revision
* 
* Version   Date            Author          Summary of changes
*/
trigger DES_BusinessPlanVersion on bupl__BusinessPlan_Version__c (before insert, after insert) {
    final DES_BusinessPlanVersion_TriggerHandler bpvHandler = DES_BusinessPlanVersion_TriggerHandler.getInstance();

    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            bpvHandler.populateFieldsBPVersion(Trigger.new);
        }
            
    } else if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            bpvHandler.initRelatedBPitems(Trigger.new);
            bpvHandler.insertAudit(Trigger.new);
        }
    }

}