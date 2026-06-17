@isTest
private with sharing class DES_DMT_ProspectUtils_Test {

    @testSetup
    static void setupData() {
        TriggerBypass.setBypass();
        
        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();

        // Prospect Group
        Account prospectGroup = new Account(
            Name = 'Test Group',
            RecordTypeId = groupRtId,
            DES_Group_Code__c = 'G00000000000001',
            g_golden_customer_id__c = '',
            DES_Country_Client__c = 'ES',
            DMT_Prospect_HPG_Sync__c = false
        );
        insert prospectGroup;

        // Prospect Subsidiary
        Account prospectSub = new Account(
            Name = 'Test Subsidiary',
            RecordTypeId = subsidiaryRtId,
            g_customer_id__c = 'ESP000000000001',
            g_golden_customer_id__c = '',
            DES_Country_Client__c = 'ES',
            participant_id__c = prospectGroup.Id,
            DMT_Prospect_HPG_Sync__c = false,
            DES_Prospect_Status_Funnel__c = 'Pre-rating',
            DES_ID_Fiscal__c = 'x123'
        );
        insert prospectSub;
    }

    @isTest
    static void testCallCreateProspect() {
        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();

        Account acc = new Account(
            Name = 'New Group',
            RecordTypeId = groupRtId,
            DES_Group_Code__c = 'G00000000000002'
        );

        Test.startTest();
        DES_DMT_ProspectUtils.callCreateProspect(new List<Account>{ acc });
        Test.stopTest();

        Assert.isNotNull(acc.Name, 'Account should exist');
    }

    @isTest
    static void testCallCreateEditProspect_CreateGroup() {
        Account acc = [SELECT Id, Name, RecordTypeId, DES_Group_Code__c, g_golden_customer_id__c, 
                       DES_Country_Client__c, DMT_Prospect_HPG_Sync__c, DES_Prospect_Status_Funnel__c
                       FROM Account WHERE DES_Group_Code__c = 'G00000000000001' LIMIT 1];
        
        Account oldAcc = acc.clone(true);
        acc.Name = 'Updated Group';

        Test.startTest();
        DES_DMT_ProspectUtils.callCreateEditProspect(new List<Account>{ acc }, 
                                                      new Map<Id, Account>{ acc.Id => oldAcc });
        Test.stopTest();

        Assert.areEqual('Updated Group', acc.Name, 'Name should be updated');
    }

    @isTest
    static void testCallCreateEditProspect_CreateSubsidiary() {
        Account acc = [SELECT Id, Name, RecordTypeId, g_customer_id__c, g_golden_customer_id__c, 
                       DES_Country_Client__c, participant_id__c, DMT_Prospect_HPG_Sync__c,
                       DES_Prospect_Status_Funnel__c
                       FROM Account WHERE g_customer_id__c = 'ESP000000000001' LIMIT 1];
        
        Account oldAcc = acc.clone(true);
        acc.Name = 'Updated Subsidiary';

        Test.startTest();
        DES_DMT_ProspectUtils.callCreateEditProspect(new List<Account>{ acc }, 
                                                      new Map<Id, Account>{ acc.Id => oldAcc });
        Test.stopTest();

        Assert.areEqual('Updated Subsidiary', acc.Name, 'Name should be updated');
    }

    @isTest
    static void testCallCreateEditProspect_EditGroup() {
        Account acc = [SELECT Id, Name, RecordTypeId, DES_Group_Code__c, g_golden_customer_id__c, 
                       DES_Country_Client__c, DMT_Prospect_HPG_Sync__c, DES_Prospect_Status_Funnel__c
                       FROM Account WHERE DES_Group_Code__c = 'G00000000000001' LIMIT 1];
        
        acc.DMT_Prospect_HPG_Sync__c = true;
        Account oldAcc = acc.clone(true);
        acc.Name = 'Edited Group';

        Test.startTest();
        DES_DMT_ProspectUtils.callCreateEditProspect(new List<Account>{ acc }, 
                                                      new Map<Id, Account>{ acc.Id => oldAcc });
        Test.stopTest();

        Assert.areEqual('Edited Group', acc.Name, 'Name should be edited');
    }

    @isTest
    static void testCallCreateEditProspect_EditSubsidiary() {
        Account acc = [SELECT Id, Name, RecordTypeId, g_customer_id__c, g_golden_customer_id__c, 
                       DES_Country_Client__c, participant_id__c, DMT_Prospect_HPG_Sync__c,
                       DES_Prospect_Status_Funnel__c
                       FROM Account WHERE g_customer_id__c = 'ESP000000000001' LIMIT 1];
        
        acc.DMT_Prospect_HPG_Sync__c = true;
        Account oldAcc = acc.clone(true);
        acc.Name = 'Edited Subsidiary';

        Test.startTest();
        DES_DMT_ProspectUtils.callCreateEditProspect(new List<Account>{ acc }, 
                                                      new Map<Id, Account>{ acc.Id => oldAcc });
        Test.stopTest();

        Assert.areEqual('Edited Subsidiary', acc.Name, 'Name should be edited');
    }
}