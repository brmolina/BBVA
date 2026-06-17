trigger AssetGroupMemberTrigger on Asset_Group_Member__c (after insert, after delete, after update) {


  if (Trigger.isInsert && Trigger.isAfter) {
    AssetGroupMemberTriggerHandler.newGroupMember(Trigger.newMap);
  }
  /*
  if (Trigger.isUpdate && Trigger.isAfter) {
    handler.updateGroupMember(Trigger.new, Trigger.oldMap);
  }
  */
  if (Trigger.isDelete && Trigger.isAfter) {
    AssetGroupMemberTriggerHandler.deleteGroupMember(Trigger.old);
  }
}