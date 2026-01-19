/*@Author Juan Carlos Terrón Ruiz
  @CreationDate 7-6-2019
  @Version1.0
*/
@IsTest
public with sharing class SER_CaseCleaner_BATCH_TEST {
  /*@Author Juan Carlos Terrón Ruiz
    @Definition: method to test simple call to the SER_CaseCleaner_BATCH class
  */
  /*@fieldtype String
    @Value/usage schedule time expression
  */
  public static final String SCH = '0 0 2 * * ?';
  
  /*@Author Juan Carlos Terrón Ruiz
    @TestCase : llamada simple al batch sin parámetros de constructor
  */
  @isTest
  public static void testExecute2() {
    Test.startTest();
    String query;
    query = 'select id from case where subject =\'test\'';
    final Case newcase = new case ();
                          newcase.Subject = 'test';
                          insert newcase;
                          final SER_CaseCleaner_JOB ccj = new SER_CaseCleaner_JOB(query);
                          system.schedule('Test CaseCleaner Job', SER_CaseCleaner_BATCH_TEST.SCH, ccj);
                          final List<Case> cases = new List<Case>([select id from case limit 10]);
                          final boolean casesempty = cases.isempty();
                          System.assert (!casesempty,'cases is empty');
                          Test.stopTest();
                          // add system asserts to check your expected behaviour
  }
}