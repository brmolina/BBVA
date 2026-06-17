/**
* @author       Global Desktop
* @date         17/10/2019
* @description  Trigger de Business Plan
* @Revision
* 
* Version   Date            Author          Summary of changes
* 0.1       2019/10/28      JSS             Añadido método updateStatusOnAP que sirve para actualizar el estado del AP relacionado con el BP
* 0.2       2019/11/08      JSS             Añadida llamada after insert al método initRelatedBPversion
*
*/
trigger DES_BusinessPlan on bupl__BusinessPlan__c (after insert, after update) {
    final acpl.BusinessPlan_TriggerHandler bpHandler = acpl.BusinessPlan_TriggerHandler.getInstance();
    final DES_BusinessPlan_TriggerHandler des_bpHandler = DES_BusinessPlan_TriggerHandler.getInstance();


    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            bpHandler.insertAPHistory(Trigger.newMap, null);
            des_bpHandler.initRelatedBPversion(Trigger.new);
        }
        else if(Trigger.isUpdate) {
            bpHandler.insertAPHistory(Trigger.newMap, Trigger.oldMap);
            bpHandler.updateStatusOnAP(Trigger.newMap, Trigger.oldMap);
        }
    }

}