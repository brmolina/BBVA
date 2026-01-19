/**
*
* @author Global Desktop
*/
@isTest
public with sharing class DES_Popup_Custom_newContactCont_Test {
    /**
     * Test method for NPS_ContactHistory controller
     */
    @isTest
    public static void testNPSContactHistory() {
        Test.startTest();
            DES_Popup_Custom_newContactController.getInstance();
            final String currentDomain = DES_Popup_Custom_newContactController.currentDomain();
            System.assert(currentDomain != null, 'The variable currentDomain is null');
        Test.stopTest();
    }
}