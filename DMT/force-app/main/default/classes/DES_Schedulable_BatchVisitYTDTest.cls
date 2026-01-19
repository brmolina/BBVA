/*
* Test class for DES_Schedulable_BatchVisitYTD
*/
@isTest
public class DES_Schedulable_BatchVisitYTDTest {
  /*
  * Test method one
  */
  @isTest
  public static void schedulableBatchVisitYTD() {

    Test.startTest();
    final DES_UtilTestClass testClass = new DES_UtilTestClass();
    final Account acc = testClass.createClient();
    insert acc;
    final dwp_kitv__Visit__c visit = testClass.createVisit(acc,null);
    visit.dwp_kitv__visit_start_date__c = Date.today().addDays(-1);
    insert visit;

    final String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedulable_BatchVisitYTD());
    System.assertNotEquals(jobId, null);
    Test.stopTest();
  }

  /*
  * Test method two
  */
  @isTest
  public static void schedule_AlertDiscard() {
    Test.startTest();
    final String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedule_AlertDiscard());
    System.assertNotEquals(jobId, null);
    Test.stopTest();
  }
}