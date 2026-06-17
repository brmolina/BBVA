/**********************************************************************************
* @author       Global Desktop
* @description  Trigger para objeto pith__Related_opportunity_pitch__c
**********************************************************************************/
trigger OppRelPitchTrigger on pith__Related_opportunity_pitch__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  pith.OppRelPitchTriggerHandler handlerRel = new pith.OppRelPitchTriggerHandler();

  if(Trigger.isAfter && Trigger.isInsert) {
    handlerRel.completePitchTeam(Trigger.new);
    Related_Opp_Pitch_TriggerHandler.onAfterInsert(Trigger.new);
  }
}