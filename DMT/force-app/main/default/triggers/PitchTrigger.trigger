/**********************************************************************************
* @author       Global Desktop
* @description  Trigger para objeto pith__Pitch__c
**********************************************************************************/
trigger PitchTrigger on pith__Pitch__c(before insert, after insert, before update, after update) {
  pith.PitchTriggerHandler pitchHandler = new pith.PitchTriggerHandler();
  PitchTriggerCustomHandler pitchCustomHandler = new PitchTriggerCustomHandler();

  if(Trigger.isBefore && Trigger.isInsert) {
    pitchCustomHandler.changeRecordType(Trigger.new);
  }

  if(Trigger.isAfter && Trigger.isInsert) {
    pitchHandler.publicGroupCreation(Trigger.new);
    pitchHandler.ownerToTeam(Trigger.new);
    PitchTriggerCustomHandler.onAfterInsert(Trigger.new);
  }

  if(Trigger.isAfter && Trigger.isUpdate) {
    PitchTriggerCustomHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
  }
}