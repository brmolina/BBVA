/**
 * @description       :
 * @author            : Global Desktop
 * @group             :
 * @last modified on  : 02-25-2021
 * @last modified by  : Global Desktop
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   02-25-2021   Global Desktop   Initial Version
**/
trigger LocalClient on Local_Client__c (before insert, after insert, before update, after update) {
  if(!TriggerBypass.bypassTrigger){
    if(Trigger.isBefore) {
      if(Trigger.isInsert) {
        LocalClientHandler.informName(Trigger.new, null);
        LocalClientHandler.insertAlphaCode(Trigger.new);
      } else if(Trigger.isUpdate) {
        LocalClientHandler.informName(Trigger.new, Trigger.oldMap);
        LocalClientHandler.insertAlphaCode(Trigger.new);
      }
    }
  }
}