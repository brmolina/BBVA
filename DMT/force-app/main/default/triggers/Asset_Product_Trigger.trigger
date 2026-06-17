trigger Asset_Product_Trigger on Asset_Product__c (after update) {

    /*
    *   @AUTHOR Global Desktop
    */
    final Asset_Product_Handler handler = Asset_Product_Handler.getInstance();

    if(Trigger.isAfter) {
        if(Trigger.isUpdate){
          handler.notifyMarkitwire(Trigger.new, Trigger.oldMap);
        }
      }
}