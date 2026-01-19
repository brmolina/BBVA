@isTest
public with sharing class DMT_OpportunityCloneUtilTest {

    @TestSetup
    static void loadTestData() {
        TriggerBypass.setBypass();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity(); 
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product2 = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product2);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product2, pricebookEntry, opp);
    
        opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opp.Id];
        opportunityLineItem = [SELECT Id, UnitPrice, TotalPrice FROM OpportunityLineItem WHERE Id = :opportunityLineItem.Id];
        opportunityLineItem.UnitPrice = 200;
        update opportunityLineItem;
    
        DMT_Opportunity_Tenor__c tenor = DMT_Test_DataFactory.generateOpportunityTenor(opportunityLineItem);
        DMT_Opportunity_Mitigant__c mitigant = DMT_Test_DataFactory.generateOpportunityMitigant(opportunityLineItem);
        DMT_X_Sell__c xSell = DMT_Test_DataFactory.generatexSell(opp);
        DMT_Opportunity_Client__c oppClient = DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        DMT_TeamMember__c participants = new DMT_TeamMember__c(Opportunity__c = opp.Id, User__c = UserInfo.getUserId(), AccessLevel__c = 'Read');
        insert participants;
        Local_Client__c localClient = new Local_Client__c(Name = 'test local client', RecordTypeId = Schema.SObjectType.Local_Client__c.getRecordTypeInfosByName().get('Client').getRecordTypeId(), Cib_Client__c = opp.AccountId);
        insert localClient;    
    }

    @IsTest
    static void testCloneSuccess() {
        Opportunity originalOpp = [SELECT Id, Name, Entific__c,AccountId,RecordTypeId,gf_opportunity_product_desc__c, StageName, closedate FROM Opportunity LIMIT 1];        
		List<OpportunityLineItem> olis = [SELECT Id, OpportunityId, PricebookEntryId, Quantity, UnitPrice, TotalPrice FROM OpportunityLineItem];
        List<DMT_Opportunity_Tenor__c> tenors = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Opportunity_Tenor__c];
        List<DMT_Opportunity_Mitigant__c> mitigants = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Opportunity_Mitigant__c];
        List<DMT_X_Sell__c> xSells = [SELECT Id, Opportunity__c FROM DMT_X_Sell__c];
        DMT_Opportunity_Client__c oppClient = [SELECT Id, DMT_MDE_Opportunity__c FROM DMT_Opportunity_Client__c LIMIT 1];
        Local_Client__c localClient = [SELECT Id, Cib_Client__c FROM Local_Client__c LIMIT 1];        
        List<DMT_TeamMember__c> participants = [SELECT Id, Opportunity__c FROM DMT_TeamMember__c];

        Test.startTest();
        DMT_OpportunityCloneUtil.CloneInput input = new DMT_OpportunityCloneUtil.CloneInput();
        input.originalOpportunity = originalOpp;
        input.opportunityLineItems = olis;
        input.tenors = tenors;
        input.mitigants = mitigants;
        input.xSells = xSells;
        input.opportunityClient = oppClient;
        input.localClient = localClient;
        input.participants = participants;

        List<DMT_OpportunityCloneUtil.CloneResult> results = DMT_OpportunityCloneUtil.clone(new List<DMT_OpportunityCloneUtil.CloneInput>{input});
        Test.stopTest();
        Assert.isNotNull(results[0].newOpportunityId, 'The Id of the new opportunity should not be null');
    }
}