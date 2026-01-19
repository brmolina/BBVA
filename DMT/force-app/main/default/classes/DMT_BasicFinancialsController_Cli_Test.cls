@isTest
public with sharing class DMT_BasicFinancialsController_Cli_Test {
    @TestSetup
    static void makeData(){
        DMT_Test_DataFactory.generateAccount();
    }
    
    @isTest
    static void testGetFinancials() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<Account> accounts = DMT_BasicFinancialsController_Client.getFinancials(acc.Id);
        Test.stopTest();

        System.assertEquals(accounts.get(0).Revenues_Last_Year_number__c, 13, 'It is equals to the amount from the mock');

    }
}