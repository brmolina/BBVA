/**
 *
 * @author Global Desktop
 */
@isTest
public with sharing class NPS_GetContactsOwner_Test {
  /**
   * Test method for NPS_ContactHistory controller
   */
  @isTest
  public static void testNPSContactHistory() {
    Test.startTest();
      final NPS_GetContactsOwner_Controller iController = new NPS_GetContactsOwner_Controller();

      System.assert(iController.listViewURL != null, 'The URL is null');
    Test.stopTest();
  }

}