/**********************************************************************************
* @author       Global Desktop
* @date         18/02/2020
* @description  Test del controller del componente de CommAlert_Get_Last_Alerts
**********************************************************************************/
@isTest
public class CommAlert_Get_Last_Alerts_Test {
  /**
   * Test method 1
   */
  @isTest
  public static void test1() {
    Test.startTest();
      final CommAlert_Get_Last_Alerts_Controller iController = new CommAlert_Get_Last_Alerts_Controller();
      System.assertNotEquals(iController, null);
    Test.stopTest();
  }
}