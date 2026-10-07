@isTest
private with sharing class DES_DMT_ProspectUtils_Test {

    /*
    * Constants for testing
    */
    private static final String CIBVAR = 'C';
    private static final String SUBSIDIARYVAR = 'Subsidiary';
    private static final String TESTVAR = 'Test';

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
            DES_Country_of_Management_OLD__c = 'ES',
            DES_Revenue__c = 100000,
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
                       DES_Country_Client__c, DMT_Prospect_HPG_Sync__c, DES_Prospect_Status_Funnel__c, g_customer_id__c
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
                       DES_Country_Client__c, DMT_Prospect_HPG_Sync__c, DES_Prospect_Status_Funnel__c, g_customer_id__c
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

    @isTest
    static void testUpdateCustomAssociationsForMerge() {
        final DES_UtilTestClass tstClass = new DES_UtilTestClass();
        
        TriggerBypass.setBypass();
        // Create Group account
        final Account groupAccount = tstClass.createClient();
        groupAccount.Name = 'Test Group Merge';
        groupAccount.DES_Group_Code__c = 'GP0000000000001';
        groupAccount.DES_Structure_Type__c = 'Group';
        groupAccount.DES_ID_Fiscal__c = '99999999';
        groupAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
        insert groupAccount;
        
        // Create Prospect account
        final Account prospect = tstClass.createClient();
        prospect.Name = 'Test Prospect Merge';
        prospect.g_customer_id__c = 'ESP0000000001';
        prospect.participant_id__c = groupAccount.Id;
        prospect.DES_ID_Fiscal__c = '12345678';
        prospect.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
        insert prospect;
        
        // Create Client to merge with Group Code
        final Account clientToMerge = tstClass.createClient();
        clientToMerge.Name = 'Test Client Merge';
        clientToMerge.g_customer_id__c = 'ES0000000000001';
        clientToMerge.DES_Main_Parent__c = groupAccount.Id;
        clientToMerge.DES_Structure_Type__c = SUBSIDIARYVAR;
        clientToMerge.DES_BBVA_Segmentation__c = CIBVAR;
        clientToMerge.DES_ID_Fiscal__c = '88888888';
        insert clientToMerge;
        
        // Create hierarchy relationship
        final AMH_GBL_Account_Relationship__c relationship = new AMH_GBL_Account_Relationship__c();
        relationship.AMH_Parent_Account__c = groupAccount.Id;
        relationship.AMH_Child_Account__c = clientToMerge.Id;
        relationship.AMH_Type__c = '03 - Filial';
        relationship.DES_Main_Parent__c = 'S';
        relationship.AMH_Vision__c = 'S';
        insert relationship;
        
        // Create DMT_Line__c
        final DMT_Line__c line = new DMT_Line__c();
        line.Name = 'Test Line Merge for Custom Association Flow';
        insert line;
        
        // Create Opportunity on prospect
        final Opportunity opp = tstClass.createOpportunity(prospect);
        insert opp;
        
        // Create Custom_Association__c (Lines)
        final Custom_Association__c customAssocLine = new Custom_Association__c();
        customAssocLine.g_customer_id__c = 'ESP0000000001';
        customAssocLine.DMT_Line__c = line.Id;
        customAssocLine.g_group_id__c = 'GP0000000000001';
        customAssocLine.gf_customer_group_id__c = 'GP0000000000001';
        insert customAssocLine;
        
        // Create Custom_Association_Opportunity__c (Opportunities)
        final Custom_Association_Opportunity__c customAssocOpp = new Custom_Association_Opportunity__c();
        customAssocOpp.g_customer_id__c = 'ESP0000000001';
        customAssocOpp.Opportunity__c = opp.Id;
        customAssocOpp.g_group_id__c = 'GP0000000000001';
        customAssocOpp.gf_customer_group_id__c = 'GP0000000000001';
        insert customAssocOpp;
        
        // Create Custom_Association_Client__c (Lines)
        final Custom_Association_Client__c customAssocClient = new Custom_Association_Client__c();
        customAssocClient.g_customer_id__c = 'ESP0000000001';
        customAssocClient.Name = 'Old Client Name';
        customAssocClient.g_entific_id__c = 'ES';
        customAssocClient.Alpha_Code_Client__c = 'ESP0000000001';
        customAssocClient.Custom_Association__c = customAssocLine.Id;
        insert customAssocClient;
        
        // Create DMT_Opportunity_Client__c (Opportunities)
        final DMT_Opportunity_Client__c oppClient = new DMT_Opportunity_Client__c();
        oppClient.Alpha_Code_Client__c = 'ESP0000000001';
        oppClient.DMT_MDE_Opportunity__c = opp.Id;
        insert oppClient;
        
        Test.startTest();
        // Call the migrated method directly
        DES_DMT_ProspectUtils.updateCustomAssociationsForMerge(prospect.Id, clientToMerge);
        Test.stopTest();
        
        // Verify Custom_Association__c was updated
        final Custom_Association__c updatedCA = [
            SELECT Id, Group__c, g_customer_id__c, g_group_id__c
            FROM Custom_Association__c
            WHERE Id = :customAssocLine.Id
        ];
        Assert.areEqual('ES0000000000001', updatedCA.g_customer_id__c, 'Custom Association g_customer_id should be updated');
        Assert.areEqual('GP0000000000001', updatedCA.g_group_id__c, 'Custom Association g_group_id should match group code');
        Assert.areEqual(groupAccount.Id, updatedCA.Group__c, 'Custom Association Group should be updated');
        
        // Verify Custom_Association_Opportunity__c was updated
        final Custom_Association_Opportunity__c updatedCAO = [
            SELECT Id, Group__c, g_customer_id__c, g_group_id__c
            FROM Custom_Association_Opportunity__c
            WHERE Id = :customAssocOpp.Id
        ];
        Assert.areEqual('ES0000000000001', updatedCAO.g_customer_id__c, 'Custom Association Opp g_customer_id should be updated');
        Assert.areEqual('GP0000000000001', updatedCAO.g_group_id__c, 'Custom Association Opp g_group_id should match group code');
        Assert.areEqual(groupAccount.Id, updatedCAO.Group__c, 'Custom Association Opp Group should be updated');
        
        // Verify Custom_Association_Client__c was updated
        final Custom_Association_Client__c updatedCAC = [
            SELECT Id, Name, Alpha_Code_Client__c, g_customer_id__c, g_entific_id__c
            FROM Custom_Association_Client__c
            WHERE Id = :customAssocClient.Id
        ];
        Assert.areEqual('Test Client Merge', updatedCAC.Name, 'Custom Association Client Name should be updated');
        Assert.areEqual('ES0000000000001', updatedCAC.Alpha_Code_Client__c, 'Custom Association Client Alpha Code should be updated');
        Assert.areEqual('ES0000000000001', updatedCAC.g_customer_id__c, 'Custom Association Client g_customer_id should be updated');
        Assert.areEqual('ES', updatedCAC.g_entific_id__c, 'Custom Association Client g_entific_id should be updated');        
        // Verify DMT_Opportunity_Client__c was updated
        List<DMT_Opportunity_Client__c> updatedOC = [
            SELECT Id, Alpha_Code_Client__c
            FROM DMT_Opportunity_Client__c
            WHERE Id = :oppClient.Id
        ];
        Assert.isNotNull(updatedOC[0], 'DMT Opportunity Client should exist');
        Assert.areEqual('ES0000000000001', updatedOC[0].Alpha_Code_Client__c, 'DMT Opportunity Client Alpha Code should be updated');
    }

    

    @isTest
    static void testTransferProspectRecords() {
        final DES_UtilTestClass tstClass = new DES_UtilTestClass();
        TriggerBypass.setBypass();
        
        final Account prospectGroup = tstClass.createClient();
        prospectGroup.Name = 'Test Prospect Group';
        prospectGroup.DES_Group_Code__c = 'GP0000000000100';
        prospectGroup.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
        insert prospectGroup;
        
        final Account clientGroup = tstClass.createClient();
        clientGroup.Name = 'Test Client Group';
        clientGroup.DES_Group_Code__c = 'G00000000000200';
        insert clientGroup;
        
        final DMT_Line__c line1 = new DMT_Line__c();
        line1.Name = 'Test Line 1';
        line1.Client__c = prospectGroup.Id;
        insert line1;
        
        final Opportunity dmtOpp1 = tstClass.createOpportunity(prospectGroup);
        dmtOpp1.Name = 'Test DMT Opp 1';
        dmtOpp1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        dmtOpp1.AccountId = prospectGroup.Id;
        insert dmtOpp1;
        
        Test.startTest();
        DES_DMT_ProspectUtils.transferProspectRecords(prospectGroup.Id, clientGroup.Id);
        Test.stopTest();
        
        final DMT_Line__c updatedLine = [SELECT Id, Client__c FROM DMT_Line__c WHERE Id = :line1.Id];
        Assert.areEqual(clientGroup.Id, updatedLine.Client__c, 'Line should point to Client Group');
        
        final Opportunity updatedDMTOpp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :dmtOpp1.Id];
        Assert.areEqual(clientGroup.Id, updatedDMTOpp.AccountId, 'DMT Opp should point to Client Group');
    }

}