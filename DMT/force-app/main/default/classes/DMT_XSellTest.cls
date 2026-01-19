@isTest
public with sharing class DMT_XSellTest {
    @TestSetup
    static void setUp() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_X_Sell__c xSell = DMT_Test_DataFactory.generatexSell(opp);
    }
    @isTest
    static void testXSellGet() {
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];    
        List<DMT_X_Sell__c> listxSell = DMT_XSell.getXsell(opportunity.Id);   
        System.assertNotEquals(true, listxSell.size() > 0);
    }

}