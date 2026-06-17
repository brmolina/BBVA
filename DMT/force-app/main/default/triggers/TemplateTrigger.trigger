/**
 * @description Trigger optimizado para DES_Template__c
 *              Cambios principales:
 *              - Uso de TriggerRecursionControl en lugar de ControlTriggerTemplate
 *              - Mejor control de recursión
 * @author Optimización de triggers - BBVA
 * @date 2024
 */
trigger TemplateTrigger on DES_Template__c (before update, after insert, before insert, after update, after delete) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            TemplateTriggerHandler.searchTableTemplate(Trigger.new);
            TemplateTriggerHandler.createChatter(Trigger.new);
        }
        
        if (Trigger.isUpdate && !TriggerRecursionControl.hasTemplateAfterUpdateExecuted()) {
            TriggerRecursionControl.setTemplateAfterUpdateExecuted();
            TemplateTriggerHandler.updateOpportunityPendApp(Trigger.new, Trigger.oldMap);
        }
        
        if (Trigger.isDelete) {
            TemplateTriggerHandler.oppPendingToFalse(Trigger.old);
            TemplateTriggerHandler.deleteChatter(Trigger.old);
        }
    }
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            TemplateTriggerHandler.completeIndustry(Trigger.new);
            TemplateTriggerHandler.corregirTextoPdf(Trigger.new);
            TemplateTriggerHandler.completeBooking(Trigger.new);
            TemplateTriggerHandler.isProspectClient(Trigger.new);
        }
        
        if (Trigger.isUpdate && !TriggerRecursionControl.hasTemplateBeforeUpdateExecuted()) {
            TriggerRecursionControl.setTemplateBeforeUpdateExecuted();
            TemplateTriggerHandler.corregirTextoPdf(Trigger.new);
            TemplateTriggerHandler.checkIndustryEdit(Trigger.new, Trigger.oldMap);
        }
    }
}