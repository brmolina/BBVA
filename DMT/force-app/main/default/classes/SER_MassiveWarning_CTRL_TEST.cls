/*--------------------------------------------------------------------------------
    @author       Accenture
    @date         17/01/2018
    @description  TEST for MassiveWarning.
------------------------------------------------------------------------------------*/
@isTest
private class SER_MassiveWarning_CTRL_TEST {

  @isTest
  static void testMethodOne() {
    Test.startTest();
    final SER_MassiveWarning_CTRL serMassive = new SER_MassiveWarning_CTRL();
    Test.stopTest();
    System.assert (serMassive!=null,'testMethodOne');
  }
}