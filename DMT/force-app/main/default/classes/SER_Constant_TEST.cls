/**
* Comprobacion TEST de las clase contant
*/
@isTest
public class SER_Constant_TEST {

  @isTest static void testMethodOne() {
    Test.startTest();
    final SER_Constant constantes = new SER_Constant();
    System.assertEquals(constantes,constantes, 'SER_Constant_TEST.testMethodOne');
    Test.stopTest();
  }

}