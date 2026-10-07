@isTest
public without sharing class DES_DMT_ProspectGroupHPGSyncBatchTest {
    @testSetup
    static void setupData() {
        TriggerBypass.setBypass();
        
        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();

        // Prospect Group sin sincronizar
        Account prospectGroup = new Account(
            Name = 'Test Prospect Group',
            RecordTypeId = groupRtId,
            DES_Group_Code__c = 'G20240001',
            DMT_Prospect_HPG_Sync__c = false
        );
        insert prospectGroup;
        // Prospect Subsidiary sin sincronizar
        Account prospectSubsidiary = new Account(
            Name = 'Test Prospect Subsidiary',
            RecordTypeId = subsidiaryRtId,
            g_customer_id__c = 'CUST001',
            DMT_Prospect_HPG_Sync__c = false,
            DES_Prospect_Status_Funnel__c = 'Pre-rating',
            DES_ID_Fiscal__c = 'x123'
        );
        insert prospectSubsidiary;

    }

    @isTest
    static void testBatchExecutes() {
        Test.startTest();
        DES_DMT_ProspectGroupHPGSyncBatch batch = new DES_DMT_ProspectGroupHPGSyncBatch();
        Database.executeBatch(batch, 100);
        Test.stopTest();

        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();
        List<Account> prospects = [SELECT Id FROM Account WHERE RecordTypeId = :groupRtId];
        Assert.areEqual(1, prospects.size(), 'Should have 1 prospect group');
    }
}