/**
* @author       Global Desktop
* @date         29/10/2019
* @description  Trigger de BP_Need__c
* @Revision
* 
* Version   Date            Author          Summary of changes
*
*/
trigger DES_CommercialPlanEvent on acpl__Commercial_Plan_Event__c (after insert) {
    //final acpl.CommercialPlanEventHandler cpeh = acpl.CommercialPlanEventHandler.getInstance();

    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            acpl.CommercialPlanEventHandler.updateStatusOnAP(Trigger.newMap);
        }
    }
}