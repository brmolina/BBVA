trigger Asset_Template_trigger on Asset_Template__c (before insert, before update, after update, before delete) {

  /*
  *   @AUTHOR Global Desktop
  */
  final Asset_Template_Handler handler = Asset_Template_Handler.getInstance();

  if(Trigger.isBefore) {
    if(Trigger.isInsert){
      handler.setAssetClass(Trigger.new);
    }
    if(Trigger.isDelete){
      handler.checkDelete(Trigger.old);
    }
  }

  if(Trigger.isAfter) {
    if(Trigger.isUpdate){
      handler.compareStageChange(Trigger.new, Trigger.oldMap);
    }
  }

}