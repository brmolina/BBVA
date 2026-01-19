@isTest
public with sharing class DMT_BasicFinancialsController_Test {
    @TestSetup
    static void makeData(){

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);

    }
    
    @isTest
    static void testGetAccountFields() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Opportunity> opps = DMT_BasicFinancialsController.getAccountFields(opp.Id);
        Test.stopTest();

        System.assertEquals(opps.get(0).Account.Revenues_Last_Year_number__c, 13, 'It is equals to the amount from the mock');

    }

    @isTest
    static void testGetFinancials() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<DMT_Opportunity_Client__c> opps = DMT_BasicFinancialsController.getFinancials(opp.Id);
        Test.stopTest();

        System.assertEquals(opps.get(0).Revenues_Last_Year_number__c, 14, 'It is equals to the amount from the mock');
    }
}