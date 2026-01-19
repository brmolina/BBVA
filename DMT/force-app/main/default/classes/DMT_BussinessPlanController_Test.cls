@isTest
public with sharing class DMT_BussinessPlanController_Test {

    @TestSetup
    static void makeData(){

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);

    }
    
    @isTest
    static void testGetAccountFields() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Opportunity> opps = DMT_BussinessPlanController.getAccountFields(opp.Id);
        Test.stopTest();

        System.assertEquals(opps.get(0).Account.Past2_FY_Corp_Synd_Lending_amount__c, 13, 'It is equals to the amount from the mock');

    }

    @isTest
    static void testGetBussinessPlan() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<DMT_Opportunity_Client__c> opps = DMT_BussinessPlanController.getBussinessPlan(opp.Id);
        Test.stopTest();

        System.assertEquals(opps.get(0).Past2_FY_Corp_Synd_Lending_amount__c, 14, 'It is equals to the amount from the mock');
    }

}