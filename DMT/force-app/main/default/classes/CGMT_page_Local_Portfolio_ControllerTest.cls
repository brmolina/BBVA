/**
* ------------------------------------------------------------------------------------------------
* @Name     CGMT_page_Local_Portfolio_ControllerTest
* @Author   Alejandro Hernandez Ochoa - Alejandro.hernandez.ochoa@bbva.com
* @Date     2025-04-30
* @Group    Client & Group Mgm Tool
* -----------------------------------------------------------------------------------------------
* @Description Clase Test para CGMT_page_Local_Portfolio_Controller
* -----------------------------------------------------------------------------------------------
* @Changes
* 
* -----------------------------------------------------------------------------------------------
*/
@isTest
private class CGMT_page_Local_Portfolio_ControllerTest {

    @isTest
    static void testGetClient() {
        Account acc = new Account(
            Name = 'Test Account',
            DES_Group_Code__c = 'GROUP123'
        );
        insert acc;

        Test.startTest();
        String groupCode = CGMT_page_Local_Portfolio_Controller.getClient(acc.Id);
        Test.stopTest();

        System.assertEquals('GROUP123', groupCode, 'El código de grupo debería coincidir');
    }

    @isTest
    static void testNullIdThrowsError() {
        Test.startTest();
        try {
            CGMT_page_Local_Portfolio_Service.getGroupCode(null);
            System.assert(false, 'Se esperaba una excepción por ID nulo');
        } catch (AuraHandledException ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage());
        }
        Test.stopTest();
    }
}