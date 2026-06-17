/**
* @author       Global Desktop
* @date         29/10/2019
* @description  Trigger de BP_Need__c
* @Revision
*
* Version   Date            Author          Summary of changes
*
*/
trigger DES_BP_Need on bupl__BP_Need__c (after insert) {
    //final acpl.BP_NeedHandler needHandler = acpl.BP_NeedHandler.getInstance();

	if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            acpl.BP_NeedHandler.updateStatusOnAP(Trigger.newMap);
        }
    }
}