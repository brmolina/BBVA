/*
    @Author: Jose Luis Aranda
    @Class: Clase de test para la clase EmailService_LogAnalizer_JOB
  */
@IsTest
public with sharing class EmailService_LogAnalizer_JOB_TEST {
  /*
      @Value/Usage: schedule time expression
    */
  public static final String SCH = '0 0 2 * * ?';
  /*
      @Author: Jose Luis Aranda
      @Method: Ejecución del job sin query especificada.
    */
  @isTest
  public static void testExecute() {
    Test.startTest();
    final EmailService_LogAnalizer_JOB ccj = new EmailService_LogAnalizer_JOB();
    final String jid = system.schedule('Test Log Analizer Job', EmailService_LogAnalizer_JOB_TEST.SCH, ccj);
    Test.stopTest();
    system.assertNotEquals(jid, null);
    // add system asserts to check your expected behaviour
  }
}