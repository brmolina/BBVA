/**
* @author       torcuato.tejada.contractor@bbva.com
* @date         03/08/2021
* @description  Profitability Analysis Trigger
*
*/
trigger cuco_profitabilitySheet on cuco__profitability_sheet__c (before insert, before update, after update) {

    final ProfitabilitySheetTriggerHandler handler =  ProfitabilitySheetTriggerHandler.getInstance();

    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        } else if(Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }
}