/*
    @Author: Juan Carlos Terrón Ruiz
    @Class: Clase de test para la clase SER_CaseCleaner_JOB
  */
@IsTest
public with sharing class SER_CaseCleaner_JOB_TEST {
  /*
      @Value/Usage: schedule time expression
    */
  public static final String SCH = '0 0 2 * * ?';
  /*
      @Author: Juan Carlos Terrón Ruiz
      @Method: Ejecución del job sin query especificada.
    */
  @isTest
  public static void testExecute() {
    Test.startTest();
    final SER_CaseCleaner_JOB ccj = new SER_CaseCleaner_JOB();
    final String jid = system.schedule('Test CaseCleaner Job', SER_CaseCleaner_JOB_TEST.SCH, ccj);
    Test.stopTest();
    system.assertNotEquals(jid, null);
    // add system asserts to check your expected behaviour
  }
  /*
      @Author: Juan Carlos Terrón Ruiz
      @Method: Ejecución del job con query especificada.
    */
  @isTest
  public static void testExecute2() {
    Test.startTest();
    final SER_CaseCleaner_JOB ccj = new SER_CaseCleaner_JOB('select id from case where isdeleted = true');
    final String jid = system.schedule('Test Case Cleaner Job', SER_CaseCleaner_JOB_TEST.SCH, ccj);
    Test.stopTest();
    system.assertNotEquals(jid, null);
    // add system asserts to check your expected behaviour
  }
}