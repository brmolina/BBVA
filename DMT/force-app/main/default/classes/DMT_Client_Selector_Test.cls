@isTest
public class DMT_Client_Selector_Test {

    @testSetup
    static void setup() {
        DMT_Test_DataFactory.generateTestTreasuryLines();
    }
    
    
    @isTest
    static void testSearchClient() {
        Test.startTest();
        List<Account> clients = DMT_Client_Selector.searchClient('Test');
        Test.stopTest();
        
        System.assertEquals(0, clients.size(), 'It does not return client');
    }
}