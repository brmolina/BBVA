@isTest
private without sharing class DMT_CloseLostOpportunityBatch_Test {

    @testSetup
    static void setupData() {
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

        DMT_Test_DataFactory.generateOpportunityTenor(opportunityLineItem);
        DMT_Test_DataFactory.generateOpportunityMitigant(opportunityLineItem);
        DMT_Test_DataFactory.generatexSell(opp);
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        DMT_TeamMember__c participants = new DMT_TeamMember__c(Opportunity__c = opp.Id, User__c = UserInfo.getUserId(), AccessLevel__c = 'Read');
        insert participants;
        Local_Client__c localClient = new Local_Client__c(Name = 'test local client', RecordTypeId = Schema.SObjectType.Local_Client__c.getRecordTypeInfosByName().get('Client').getRecordTypeId(), Cib_Client__c = opp.AccountId);
        insert localClient;
        opp.CloseDate = Date.today().addDays(-31);
        opp.StageName = 'Draft';
        update opp;
    }

    @isTest
    static void testBatchUpdatesOpportunities() {
        Test.startTest();
        String opportunityRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        DMT_CloseLostOpportunityBatch batch = new DMT_CloseLostOpportunityBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Id, StageName FROM Opportunity WHERE RecordTypeId =: opportunityRecordTypeID];
        Assert.areEqual('Closed Lost', updatedOpp.StageName, 'the opportunity must be in Closed Lost');
    }

    @isTest
    static void testBatchHandlesDmlException() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.CurrencyIsoCode = 'INVALID';

        Test.startTest();
        DMT_CloseLostOpportunityBatch batch = new DMT_CloseLostOpportunityBatch();
        batch.execute(null, new List<SObject>{opp});
        Test.stopTest();

        Opportunity oppCheck = [SELECT CurrencyIsoCode FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('EUR', oppCheck.CurrencyIsoCode, 'The currencyIsoCode should be EUR');
    }
}