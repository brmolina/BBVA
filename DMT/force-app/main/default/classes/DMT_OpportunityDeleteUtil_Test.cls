@isTest
public with sharing class DMT_OpportunityDeleteUtil_Test {

    @TestSetup
    static void loadTestData() {
        TriggerBypass.setBypass();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity(); 
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product2 = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product2);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product2, pricebookEntry, opp);

        opportunityLineItem = [SELECT Id, UnitPrice FROM OpportunityLineItem WHERE Id = :opportunityLineItem.Id];
        opportunityLineItem.UnitPrice = 200;
        update opportunityLineItem;

        DMT_Opportunity_Tenor__c tenor = DMT_Test_DataFactory.generateOpportunityTenor(opportunityLineItem);
        DMT_Opportunity_Mitigant__c mitigant = DMT_Test_DataFactory.generateOpportunityMitigant(opportunityLineItem);
        DMT_X_Sell__c xSell = DMT_Test_DataFactory.generatexSell(opp);
        DMT_Opportunity_Client__c oppClient = DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        DMT_TeamMember__c participant = new DMT_TeamMember__c(Opportunity__c = opp.Id, User__c = UserInfo.getUserId(), AccessLevel__c = 'Read');
        insert participant;
    }

    @isTest
    static void testDeleteDataSuccess() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        DMT_Opportunity_Client__c oppClient = [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        DMT_Opportunity_Tenor__c tenor = [SELECT Id FROM DMT_Opportunity_Tenor__c LIMIT 1];
        DMT_Opportunity_Mitigant__c mitigant = [SELECT Id FROM DMT_Opportunity_Mitigant__c LIMIT 1];
        DMT_X_Sell__c xSell = [SELECT Id FROM DMT_X_Sell__c LIMIT 1];
        DMT_TeamMember__c participant = [SELECT Id FROM DMT_TeamMember__c LIMIT 1];

        DMT_OpportunityDeleteUtil.DeleteInput input = new DMT_OpportunityDeleteUtil.DeleteInput();
        input.opportunity = opp;
        input.opportunityClient = oppClient;
        input.opportunityLineItems = new List<OpportunityLineItem>{oli};
        input.tenors = new List<DMT_Opportunity_Tenor__c>{tenor};
        input.mitigants = new List<DMT_Opportunity_Mitigant__c>{mitigant};
        input.xSells = new List<DMT_X_Sell__c>{xSell};
        input.participants = new List<DMT_TeamMember__c>{participant};

        Test.startTest();
        List<DMT_OpportunityDeleteUtil.DeleteResult> results = DMT_OpportunityDeleteUtil.deleteData(new List<DMT_OpportunityDeleteUtil.DeleteInput>{input});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Debe devolver un resultado');
    }

    @isTest
    static void testDeleteDataError() {
        DMT_OpportunityDeleteUtil.DeleteInput input = new DMT_OpportunityDeleteUtil.DeleteInput();
        input.opportunity = new Opportunity();

        Test.startTest();
        List<DMT_OpportunityDeleteUtil.DeleteResult> results = DMT_OpportunityDeleteUtil.deleteData(new List<DMT_OpportunityDeleteUtil.DeleteInput>{input});
        Test.stopTest();

        System.assertEquals(false, results[0].success, 'Debe fallar');
    }
}