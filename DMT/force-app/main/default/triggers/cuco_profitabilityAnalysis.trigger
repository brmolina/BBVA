/**
* @author       torcuato.tejada.contractor@bbva.com
* @date         08/07/2020
* @description  Profitability Analysis Trigger
*
*/
trigger cuco_profitabilityAnalysis on cuco__profitability_analysis__c(before insert, after update, after insert) {

    final ProfitabilityAnalysisTriggerHandler handler =  ProfitabilityAnalysisTriggerHandler.getInstance();

    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
    } else if(Trigger.isAfter) {
        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new);
        }
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}