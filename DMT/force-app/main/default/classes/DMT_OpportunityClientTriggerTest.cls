@isTest
public with sharing class DMT_OpportunityClientTriggerTest {

    @TestSetup
    static void makeData() {
        // Bypass to avoid heavy synchronous triggers during setup
        TriggerBypass.setBypass();

        // 1. Create Opportunity
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity(
            Name = 'Test Client Sync Opp',
            StageName = 'Draft Opp',
            CloseDate = Date.today().addDays(30),
            RecordTypeId = oppRtId
        );
        insert opp;

        // 2. Create X-Sells FIRST (Simulating the async job finishing before the Client record is made)
        List<DMT_X_Sell__c> xsells = new List<DMT_X_Sell__c>{
            new DMT_X_Sell__c(Opportunity__c = opp.Id, XSELL_Value_PY__c = 150, XSELL_Value_CY__c = 250),
            new DMT_X_Sell__c(Opportunity__c = opp.Id, XSELL_Value_PY__c = 50, XSELL_Value_CY__c = 50)
        };
        insert xsells;
        
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testBeforeInsert_SyncXSellTotals() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Client Sync Opp' LIMIT 1];
        
        Test.startTest();
        
        // Insert the Client record. The before insert trigger should query the 2 existing X-Sells and sum them (150+50 = 200).
        DMT_Opportunity_Client__c client = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = opp.Id,
            Counterpart__c = 'Corporates',
            DMT_Sector__c = 'N'
        );
        insert client;
        
        Test.stopTest();

        // Assert that the fields were populated correctly BEFORE the record was saved
        DMT_Opportunity_Client__c savedClient = [
            SELECT Past2_FY_Child_X_Sell_amount__c, Past_FY_Child_X_Sell_amount__c, Current_FY_Child_X_Sell_amount__c, Next_FY_Child_X_Sell_amount__c
            FROM DMT_Opportunity_Client__c 
            WHERE Id = :client.Id
        ];
        
        Assert.areEqual(200, savedClient.Past2_FY_Child_X_Sell_amount__c, 'PY total should be synced on insert');
        Assert.areEqual(300, savedClient.Past_FY_Child_X_Sell_amount__c, 'CY total should be synced on insert');
        Assert.areEqual(0, savedClient.Current_FY_Child_X_Sell_amount__c, 'NY total should default to 0 if null');
        Assert.areEqual(0, savedClient.Next_FY_Child_X_Sell_amount__c, 'NY1 total should default to 0 if null');
    }
    
    @isTest
    static void testBeforeInsert_NoXSells() {
        // Create a new Opp with NO X-Sells
        TriggerBypass.setBypass();
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Opportunity oppEmpty = new Opportunity(
            Name = 'Test Empty Opp',
            StageName = 'Draft Opp',
            CloseDate = Date.today().addDays(30),
            RecordTypeId = oppRtId
        );
        insert oppEmpty;
        TriggerBypass.removeBypass();
        
        Test.startTest();
        
        DMT_Opportunity_Client__c client = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = oppEmpty.Id,
            Counterpart__c = 'Corporates',
            DMT_Sector__c = 'N'
        );
        insert client;
        
        Test.stopTest();
        
        DMT_Opportunity_Client__c savedClient = [
            SELECT Past2_FY_Child_X_Sell_amount__c
            FROM DMT_Opportunity_Client__c 
            WHERE Id = :client.Id
        ];
        
        // If there are no X-Sells, the values should remain exactly what we inserted (null)
        Assert.areEqual(null, savedClient.Past2_FY_Child_X_Sell_amount__c, 'PY total should remain null if no X-Sells exist');
    }
}