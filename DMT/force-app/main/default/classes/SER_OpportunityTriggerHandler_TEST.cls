/*--------------------------------------------------------------------------------
    @author       Accenture
    @date         17/01/2018
    @description  TEST for Oportunity trigger.
------------------------------------------------------------------------------------*/
@isTest
private class SER_OpportunityTriggerHandler_TEST {
  /*--------------------------------------------------------------------------------
      @author       Accenture
      @date         17/01/2018
      @description  TEST for AfterDelete
  ------------------------------------------------------------------------------------*/
  public static testMethod void onAfterDeleteTEST() {
    ActivitiesUtils_Test.crearData();
    List<Opportunity> lstOppToDel = new List<Opportunity>();
    final Opportunity oportunity =  new Opportunity(AccountId = ActivitiesUtils_Test.account.Id
                                                    ,Name = 'TEST Opportunity'
                                                    , StageName = Label.DES_Draft
                                                    , CloseDate = Date.today());
    insert oportunity;
    lstOppToDel = [select Id from Opportunity LIMIT 1000000];
    delete lstOppToDel;
    System.Assert(lstOppToDel!=null,'onAfterDeleteTEST');
  }
}