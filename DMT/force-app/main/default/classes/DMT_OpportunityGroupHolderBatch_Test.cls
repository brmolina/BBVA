/**
 * @description Tests for DMT_OpportunityGroupHolderBackfillBatch: Grupo y Main Holder en
 * Opportunity tras migración Multiholder. Verifies the batch backfills the denormalized
 * DMT_Group_Name__c / DMT_Main_Holder_Name__c fields for existing DMT Opportunities.
 */
@isTest
public with sharing class DMT_OpportunityGroupHolderBatch_Test {

    @TestSetup
    static void makeData() {
        DMT_Test_DataFactory.loadCurrencies();
        DMT_Test_DataFactory.generateOpportunity();
    }

    @isTest
    static void testBatchBackfillsMainHolderNameFromAccount() {
        Opportunity opp = [SELECT Id, AccountId, Account.Name FROM Opportunity LIMIT 1];

        Test.startTest();
        Database.executeBatch(new DMT_OpportunityGroupHolderBackfillBatch(), 15);
        Test.stopTest();

        Opportunity result = [SELECT DMT_Main_Holder_Name__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual(opp.Account.Name, result.DMT_Main_Holder_Name__c,
            'Non-Multiholder Opportunities should be backfilled with their own Account name');
    }
}