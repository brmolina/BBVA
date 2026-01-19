/**********************************************************************************
* @author       Global Desktop
* @date         21/04/2020
* @description  Test del componente NPS_GetReportClient
**********************************************************************************/
@isTest
public with sharing class NPS_GetReportClient_Test {
  /**
   * Test method for NPS_ContactHistory controller
   */
  @isTest(SeeAllData='true')
  public static void testClientNPSController() {
    Test.startTest();
      final NPS_GetReportClient_Controller iController = new NPS_GetReportClient_Controller();

      System.assert(iController.reportURL != null, 'The URL is null');
    Test.stopTest();
  }
}