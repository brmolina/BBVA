/**********************************************************************************
* @author       Global Desktop
* @date         14/01/2020
* @description  Handler del trigger de intt__Opportunity_Group__c
**********************************************************************************/
trigger Opportunity_Group on intt__Opportunity_Group__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  if (Trigger.isInsert && Trigger.isAfter) {
    Opportunity_Group_TriggerHandler.onAfterInsert(Trigger.new);
  }
  if (Trigger.isDelete && Trigger.isBefore) {
    Opportunity_Group_TriggerHandler.onBeforeDelete(Trigger.old);
  }
  if (Trigger.isInsert && Trigger.isBefore) {
    intt.GBL_GroupOpportunityTriggerHandler.beforeInsert(Trigger.new);
  }
}