/**
 * @description Tests for DMT_OpportunityGroupHolderService: Grupo y Main Holder en Opportunity
 * tras migración Multiholder. Verifies the denormalized DMT_Group_Name__c / DMT_Main_Holder_Name__c
 * fields are populated correctly for both Multiholder and non-Multiholder Opportunities.
 */
@isTest
private with sharing class DMT_OpportunityGroupHolderService_Test {
    private static final String MAIN_HOLDER_ALPHA_CODE = 'GHS_ALPHA_MH';

    @TestSetup
    static void makeData() {
        DMT_Test_DataFactory.loadCurrencies();

        Account groupAccount = new Account(
            Name = 'GHS Group Account',
            DES_Structure_Type__c = 'Group',
            DES_Group_Code__c = 'GHS_GRP01'
        );
        insert groupAccount;

        Account subAccount = new Account(
            Name = 'GHS Subgroup Account',
            DES_Structure_Type__c = 'Subgroup',
            DES_Group_Code__c = 'GHS_SUB01'
        );
        insert subAccount;

        insert new AMH_GBL_Account_Relationship__c(
            AMH_Vision__c = 'Riesgos',
            AMH_Parent_Account__c = groupAccount.Id,
            AMH_Child_Account__c = subAccount.Id
        );

        insert new Account(
            Name = 'GHS Main Holder Account',
            g_customer_id__c = MAIN_HOLDER_ALPHA_CODE
        );

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        TriggerBypass.setBypass();
        opp.AccountId = subAccount.Id;
        update opp;
        TriggerBypass.removeBypass();

        insert new Custom_Association_Opportunity__c(
            Opportunity__c = opp.Id,
            g_customer_id__c = MAIN_HOLDER_ALPHA_CODE,
            gf_customer_group_id__c = 'GRPM-' + opp.Id
        );
    }

    @isTest
    static void testSyncPopulatesGroupAndMainHolderNameForMultiholderOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        DMT_OpportunityGroupHolderService.syncGroupAndMainHolderNames(new Set<Id>{ opp.Id });
        Test.stopTest();

        Opportunity result = [SELECT DMT_Group_Name__c, DMT_Main_Holder_Name__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('GHS Group Account', result.DMT_Group_Name__c, 'Group Name should come from the Account group hierarchy');
        Assert.areEqual('GHS Main Holder Account', result.DMT_Main_Holder_Name__c, 'Main Holder Name should come from the Multiholder Custom Association');
    }

    @isTest
    static void testSyncFallsBackToAccountNameWhenNotMultiholder() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        delete [SELECT Id FROM Custom_Association_Opportunity__c WHERE Opportunity__c = :opp.Id];

        Test.startTest();
        DMT_OpportunityGroupHolderService.syncGroupAndMainHolderNames(new Set<Id>{ opp.Id });
        Test.stopTest();

        Opportunity result = [SELECT DMT_Group_Name__c, DMT_Main_Holder_Name__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('GHS Group Account', result.DMT_Group_Name__c,
            'With no Custom_Association_Opportunity__c record, Group Name should fall back to the Account hierarchy walk');
        Assert.areEqual('GHS Subgroup Account', result.DMT_Main_Holder_Name__c, 'Non-Multiholder Opportunities should use the Opportunity\'s own Account name');
    }

    @isTest
    static void testSyncUsesGroupNameFromAssociationWhenPopulated() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account fedGroupAccount = new Account(Name = 'Fed Group Account');
        insert fedGroupAccount;

        Custom_Association_Opportunity__c assoc = [SELECT Id FROM Custom_Association_Opportunity__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        assoc.Group__c = fedGroupAccount.Id;
        update assoc;

        Test.startTest();
        DMT_OpportunityGroupHolderService.syncGroupAndMainHolderNames(new Set<Id>{ opp.Id });
        Test.stopTest();

        Opportunity result = [SELECT DMT_Group_Name__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Fed Group Account', result.DMT_Group_Name__c,
            'Group Name should be read directly from Custom_Association_Opportunity__c.Group__c when populated, taking priority over the Account hierarchy walk');
    }

    @isTest
    static void testSyncWithEmptyIdsDoesNothing() {
        Test.startTest();
        DMT_OpportunityGroupHolderService.syncGroupAndMainHolderNames(new Set<Id>());
        DMT_OpportunityGroupHolderService.syncGroupAndMainHolderNames(null);
        Test.stopTest();

        Assert.isTrue(true, 'Should not throw for an empty or null set of Opportunity ids');
    }
}