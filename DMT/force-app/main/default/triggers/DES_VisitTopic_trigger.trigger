/**********************************************************************************
* @author       Global Desktop
* @description  Trigger para objeto dwp_kitv__Visit_Topic__c
**********************************************************************************/
trigger DES_VisitTopic_trigger on dwp_kitv__Visit_Topic__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

  pith.VisitRelPitchTriggerHandler visitPitchHandler = new pith.VisitRelPitchTriggerHandler ();

  if(trigger.isAfter){
    if(trigger.isInsert){
      visitPitchHandler.completePitchTeam(trigger.new);
      Visit_Topic_TriggerHandler.onAfterInsert(Trigger.new);
    }
  }
  if(Trigger.isBefore) {
    if(Trigger.isDelete) {
      Visit_Topic_TriggerHandler.onBeforeDelete(Trigger.old);
      intt.GBL_VisitTriggerHandler.beforeDelete(Trigger.old);
    }
  }
  if(Trigger.isBefore) {
    if(Trigger.isInsert) {
      intt.GBL_VisitTriggerHandler.beforeInsert(Trigger.new);
      Visit_Topic_TriggerHandler.onBeforeInsert(Trigger.new);
    }
  }
}