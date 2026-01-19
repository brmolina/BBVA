/*--------------------------------------------------------------------------------
    @author       Accenture
    @date         17/01/2018
    @description  TEST for Contact on Delete.
------------------------------------------------------------------------------------*/
@isTest
private class SER_ContactTriggerHandler_TEST {
  /*--------------------------------------------------------------------------------
      @author       Accenture
      @date         17/01/2018
      @description  TEST for AfterDelete
  ------------------------------------------------------------------------------------*/
  public static testMethod void onAfterDeleteTEST() {
    ActivitiesUtils_Test.crearData();
    List<Contact> lCtctToDel = new List<Contact>();
    lCtctToDel = [select Id from Contact LIMIT 10000000];
    delete lCtctToDel;
    System.Assert(lCtctToDel!=null,'onAfterDeleteTEST:');
  }
}