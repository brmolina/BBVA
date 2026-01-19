@isTest
public with sharing class DMT_BussinessPlanController_Client_Test {

    @TestSetup
    static void makeData(){
        DMT_Test_DataFactory.generateAccount();
    }
    
    @isTest
    static void testGetBussinessPlanSuccess() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<Account> accounts = DMT_BussinessPlanController_Client.getBussinessPlan(acc.Id);
        Test.stopTest();

        System.assertEquals(accounts.get(0).Past2_FY_Corp_Synd_Lending_amount__c, 13, 'It is equals to the amount from the mock');

    }

}