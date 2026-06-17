/**
* @author       Global Desktop
* @date         29/10/2019
* @description  Trigger de BP_GrowthDriver__c
* @Revision
*
* Version   Date            Author          Summary of changes
*
*/
trigger DES_BP_GrowthDriver on bupl__BP_GrowthDriver__c (after insert) {
    //final acpl.BP_GrowthDriverHandler gdHandler = acpl.BP_GrowthDriverHandler.getInstance();

    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            acpl.BP_GrowthDriverHandler.updateStatusOnAP(Trigger.newMap);
        }
    }
}