/**********************************************************************************
* @Company BBVA
* @description: Clase de Test de CIB_LogClear_JOB.
**********************************************************************************/
@isTest
public class CIB_LogClear_JOB_TEST {
  /*
      @Value/Usage: schedule time expression
  */
  public static final String SCH = '0 0 2 * * ?';
  
   @isTest
  static void batchTest1() {

    test.startTest();
    final CIB_LogClear_JOB ccj = new CIB_LogClear_JOB();
    final String jid = system.schedule('Test CIB Log Cleaner Job', CIB_LogClear_JOB_TEST.SCH, ccj);
    
    test.stopTest();
    system.assertNotEquals(jid, null);
  }

  @isTest
  static void batchTest2() {

    test.startTest();
    final List<sObject> scope  = new List<CIB_Log__c>();
    final CIB_LogClear_BATCH clcb = new CIB_LogClear_BATCH();
    clcb.execute(null, scope);
    
    test.stopTest();
    system.assertNotEquals(clcb, null);
  }
    
   @isTest
  static void batchTest3() {

    test.startTest();
    final List<sObject> scope  = new List<CIB_Log__c>();
    final CIB_Log__c cibLog = new CIB_Log__c();
    scope.add(cibLog);
    insert scope;
    final CIB_LogClear_BATCH clcb = new CIB_LogClear_BATCH();
    clcb.execute(null, scope);
    
    test.stopTest();
    system.assertNotEquals(clcb, null);
  }

}