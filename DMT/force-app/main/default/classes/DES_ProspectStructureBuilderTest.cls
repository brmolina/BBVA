/*----------------------------------------------------------------------------------------------------------------------------
* @Name     DES_ProspectStructureBuilderTest
* @Date     Created: 2026-09-03
* ----------------------------------------------------------------------------------------------------------------------------
* @Description Dedicated unit test class for DES_ProspectStructureBuilder.
* ----------------------------------------------------------------------------------------------------------------------------
*/
@isTest
private class DES_ProspectStructureBuilderTest {

    @testSetup
    static void setupData() {
        TriggerBypass.setBypass();
        DES_UtilTestClass utilClass = new DES_UtilTestClass();

        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();

        // Prospect Group
        Account prospectGroup = utilClass.createClient();
        prospectGroup.RecordTypeId = groupRtId;
        prospectGroup.Name = 'PSB Test Group';
        prospectGroup.DES_Group_Code__c = 'GP0000000000900';
        insert prospectGroup;

        // Prospect Subsidiary
        Account prospectSubsidiary = utilClass.createClient();
        prospectSubsidiary.RecordTypeId = subsidiaryRtId;
        prospectSubsidiary.Name = 'PSB Test Subsidiary';
        prospectSubsidiary.DES_ID_Fiscal__c = 'psb001';
        prospectSubsidiary.participant_id__c = prospectGroup.Id;
        prospectSubsidiary.g_customer_id__c = 'ES0000000000900';
        prospectSubsidiary.g_golden_customer_id__c = 'x900';
        insert prospectSubsidiary;

        Id commercialClientRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('DES_Commercial_Client').getRecordTypeId();
        Account plainParent = utilClass.createClient();
        plainParent.RecordTypeId = commercialClientRtId;
        plainParent.Name = 'PSB Plain Parent';
        insert plainParent;

        // Prospect Subsidiary whose parent resolves to no group code
        Account orphanSubsidiary = utilClass.createClient();
        orphanSubsidiary.RecordTypeId = subsidiaryRtId;
        orphanSubsidiary.Name = 'PSB Orphan Subsidiary';
        orphanSubsidiary.DES_ID_Fiscal__c = 'psb002';
        orphanSubsidiary.participant_id__c = plainParent.Id;
        orphanSubsidiary.g_customer_id__c = 'ES0000000000901';
        insert orphanSubsidiary;
    }

    @isTest
    static void testHandleProspectIntegration_InvalidAndUnknownPayloads() {
        Account grp = [SELECT Id FROM Account WHERE Name = 'PSB Test Group' LIMIT 1];

        Test.startTest();
        DES_ProspectStructureBuilder.handleProspectIntegration(null);
        DES_ProspectStructureBuilder.handleProspectIntegration(new DES_ProspectStructurePayload(grp, null, ''));
        DES_ProspectStructureBuilder.handleProspectIntegration(new DES_ProspectStructurePayload(grp, null, 'Unknown_Service'));
        Test.stopTest();

        Assert.isTrue(true, 'Null payload, blank serviceName and unknown serviceName must be handled without exceptions');
    }

    @isTest
    static void testPostCreateProspect_ProspectGroupMarksSyncOnSuccess() {
        Account grp = [SELECT Id, Name, RecordTypeId, participant_id__c, DES_Group_Code__c, g_customer_id__c, g_golden_customer_id__c, DES_Country_Client__c FROM Account WHERE Name = 'PSB Test Group' LIMIT 1];

        Test.startTest();
        DES_ProspectStructureBuilder.handleProspectIntegration(
            new DES_ProspectStructurePayload(grp, null, 'DES_PostCreateProspect')
        );
        Test.stopTest();

        Account result = [SELECT Id, DMT_Prospect_HPG_Sync__c FROM Account WHERE Id = :grp.Id];
        Assert.isTrue(result.DMT_Prospect_HPG_Sync__c, 'A successful POST response must mark the Prospect as synced with HPG');
    }

    @isTest
    static void testPutEditProspect_SubsidiaryWithGroupParentSucceedsWithoutRetry() {
        Account sub = [SELECT Id, Name, RecordTypeId, participant_id__c, DES_Group_Code__c, g_customer_id__c, g_golden_customer_id__c, DES_Country_Client__c FROM Account WHERE Name = 'PSB Test Subsidiary' LIMIT 1];
        Account oldSub = sub.clone(true);

        Test.startTest();
        DMT_AsyncOrchestrator.payloadBuffer.clear();
        DES_ProspectStructureBuilder.handleProspectIntegration(
            new DES_ProspectStructurePayload(sub, oldSub, 'DES_PutEditProspect')
        );
        Test.stopTest();

        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'A successful PUT response must not enqueue a retry payload');
    }

    /**
     * Forces a duplicate error and checks sync is marked and the PUT is enqueued.
     */
    @isTest
    static void testPostCreateProspect_DuplicateErrorMarksSyncAndEnqueuesPutOnRelevantChange() {
        Account grp = [SELECT Id, Name, RecordTypeId, participant_id__c, DES_Group_Code__c, g_customer_id__c, g_golden_customer_id__c, DES_Country_Client__c FROM Account WHERE Name = 'PSB Test Group' LIMIT 1];
        Account oldGrp = grp.clone(true);
        oldGrp.Name = 'PSB Test Group OLD';

        DES_ProspectStructureBuilder.testForcedStatusCode = 400;
        DES_ProspectStructureBuilder.testForcedResponseBody = '00000017#GROUP ALREADY EXISTS';
        Test.startTest();
        DMT_AsyncOrchestrator.payloadBuffer.clear();
        DES_ProspectStructureBuilder.handleProspectIntegration(new DES_ProspectStructurePayload(grp, oldGrp, 'DES_PostCreateProspect'));
        Test.stopTest();
        DES_ProspectStructureBuilder.testForcedStatusCode = null;
        DES_ProspectStructureBuilder.testForcedResponseBody = null;

        Account result = [SELECT Id, DMT_Prospect_HPG_Sync__c FROM Account WHERE Id = :grp.Id];
        Assert.isTrue(result.DMT_Prospect_HPG_Sync__c, 'A duplicate-detected response must still mark the Prospect as synced with HPG');
        Assert.isFalse(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'A duplicate detected with relevant field changes must enqueue a PUT retry');
    }

    /**
     * Forces a 504 timeout on POST and checks sync is not marked.
     */
    @isTest
    static void testPostCreateProspect_GatewayTimeoutDoesNotMarkSync() {
        Account grp = [SELECT Id, Name, RecordTypeId, participant_id__c, DES_Group_Code__c, g_customer_id__c, g_golden_customer_id__c, DES_Country_Client__c FROM Account WHERE Name = 'PSB Test Group' LIMIT 1];

        DES_ProspectStructureBuilder.testForcedStatusCode = 504;
        DES_ProspectStructureBuilder.testForcedResponseBody = 'Gateway Timeout';
        Test.startTest();
        DES_ProspectStructureBuilder.handleProspectIntegration(new DES_ProspectStructurePayload(grp, null, 'DES_PostCreateProspect'));
        Test.stopTest();
        DES_ProspectStructureBuilder.testForcedStatusCode = null;
        DES_ProspectStructureBuilder.testForcedResponseBody = null;

        Account result = [SELECT Id, DMT_Prospect_HPG_Sync__c FROM Account WHERE Id = :grp.Id];
        Assert.isFalse(result.DMT_Prospect_HPG_Sync__c, 'A 504 gateway timeout must not mark the Prospect as synced with HPG');
    }

    /**
     * Forces a 504 timeout on PUT and checks the retry is enqueued.
     */
    @isTest
    static void testPutEditProspect_GatewayTimeoutEnqueuesRetry() {
        Account sub = [SELECT Id, Name, RecordTypeId, participant_id__c, DES_Group_Code__c, g_customer_id__c, g_golden_customer_id__c, DES_Country_Client__c FROM Account WHERE Name = 'PSB Test Subsidiary' LIMIT 1];
        Account oldSub = sub.clone(true);

        DES_ProspectStructureBuilder.testForcedStatusCode = 504;
        DES_ProspectStructureBuilder.testForcedResponseBody = 'Gateway Timeout';
        Test.startTest();
        DMT_AsyncOrchestrator.payloadBuffer.clear();
        DES_ProspectStructureBuilder.handleProspectIntegration(new DES_ProspectStructurePayload(sub, oldSub, 'DES_PutEditProspect'));
        Test.stopTest();
        DES_ProspectStructureBuilder.testForcedStatusCode = null;
        DES_ProspectStructureBuilder.testForcedResponseBody = null;

        Assert.isFalse(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'A 504 gateway timeout on PUT must enqueue a retry payload');
    }

    @isTest
    static void testProspectIntegration_OrphanParentSkipsCalloutForBothServices() {
        Account orphan = [SELECT Id, Name, RecordTypeId, participant_id__c, DES_Group_Code__c, g_customer_id__c, g_golden_customer_id__c, DES_Country_Client__c FROM Account WHERE Name = 'PSB Orphan Subsidiary' LIMIT 1];
        Account oldOrphan = orphan.clone(true);

        Test.startTest();
        DES_ProspectStructureBuilder.handleProspectIntegration(new DES_ProspectStructurePayload(orphan, null, 'DES_PostCreateProspect'));
        DES_ProspectStructureBuilder.handleProspectIntegration(new DES_ProspectStructurePayload(orphan, oldOrphan, 'DES_PutEditProspect'));
        Test.stopTest();

        Account result = [SELECT Id, DMT_Prospect_HPG_Sync__c FROM Account WHERE Id = :orphan.Id];
        Assert.isFalse(result.DMT_Prospect_HPG_Sync__c, 'Without a resolvable group code, the HPG callout must be skipped');
    }

    /**
     * Covers the Subgroup/Group/Supragroup branches, with and without a Supragroup ancestor.
     */
    @isTest
    static void testPostCreateProspect_SubgroupGroupSupragroupBranches() {
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();

        // Supragroup with no ancestor
        Account supragroupAlone = createHierarchyAccount('PSB Supragroup Alone', 'SupraGroup', 'Supragroup', 'X99000000000010');

        // Group with no ancestor
        Account groupNoAncestor = createHierarchyAccount('PSB Group No Ancestor', 'Group', 'Group', 'G99000000000011');

        // Subgroup with no ancestor
        Account subgroupNoAncestor = createHierarchyAccount('PSB Subgroup No Ancestor', 'SubGroup', 'Subgroup', 'S99000000000012');

        // Supragroup -> Group -> Subgroup chain
        Account supragroupForChain = createHierarchyAccount('PSB Supragroup Chain', 'SupraGroup', 'Supragroup', 'X99000000000013');
        Account groupWithSupraAncestor = createHierarchyAccount('PSB Group With Supra', 'Group', 'Group', 'G99000000000014');
        Account subgroupWithSupraAncestor = createHierarchyAccount('PSB Subgroup With Supra', 'SubGroup', 'Subgroup', 'S99000000000015');
        linkAsParentChild(supragroupForChain, groupWithSupraAncestor);
        linkAsParentChild(groupWithSupraAncestor, subgroupWithSupraAncestor);

        Account subUnderSupragroup = createProspectSubsidiary(subsidiaryRtId, 'PSB Sub Under Supragroup', 'psb010', 'ES0000000000910', supragroupAlone.Id);
        Account subUnderGroupNoAncestor = createProspectSubsidiary(subsidiaryRtId, 'PSB Sub Under Group No Ancestor', 'psb011', 'ES0000000000911', groupNoAncestor.Id);
        Account subUnderSubgroupNoAncestor = createProspectSubsidiary(subsidiaryRtId, 'PSB Sub Under Subgroup No Ancestor', 'psb012', 'ES0000000000912', subgroupNoAncestor.Id);
        Account subUnderGroupWithSupra = createProspectSubsidiary(subsidiaryRtId, 'PSB Sub Under Group With Supra', 'psb013', 'ES0000000000913', groupWithSupraAncestor.Id);
        Account subUnderSubgroupWithSupra = createProspectSubsidiary(subsidiaryRtId, 'PSB Sub Under Subgroup With Supra', 'psb014', 'ES0000000000914', subgroupWithSupraAncestor.Id);

        Test.startTest();
        DES_ProspectStructureBuilder.handleProspectIntegration(new DES_ProspectStructurePayload(subUnderSupragroup, null, 'DES_PostCreateProspect'));
        DES_ProspectStructureBuilder.handleProspectIntegration(new DES_ProspectStructurePayload(subUnderGroupNoAncestor, null, 'DES_PostCreateProspect'));
        DES_ProspectStructureBuilder.handleProspectIntegration(new DES_ProspectStructurePayload(subUnderSubgroupNoAncestor, null, 'DES_PostCreateProspect'));
        DES_ProspectStructureBuilder.handleProspectIntegration(new DES_ProspectStructurePayload(subUnderGroupWithSupra, null, 'DES_PostCreateProspect'));
        DES_ProspectStructureBuilder.handleProspectIntegration(new DES_ProspectStructurePayload(subUnderSubgroupWithSupra, null, 'DES_PostCreateProspect'));
        Test.stopTest();

        Map<Id, Account> syncedById = new Map<Id, Account>([
            SELECT Id, DMT_Prospect_HPG_Sync__c FROM Account WHERE Id IN :new List<Id>{
                subUnderSupragroup.Id, subUnderGroupNoAncestor.Id, subUnderSubgroupNoAncestor.Id,
                subUnderGroupWithSupra.Id, subUnderSubgroupWithSupra.Id
            }
        ]);

        Assert.isTrue(syncedById.get(subUnderSupragroup.Id).DMT_Prospect_HPG_Sync__c, 'A Supragroup parent resolves its own group code');
        Assert.isTrue(syncedById.get(subUnderGroupNoAncestor.Id).DMT_Prospect_HPG_Sync__c, 'A Group parent with no ancestor resolves its own group code');
        Assert.isFalse(syncedById.get(subUnderSubgroupNoAncestor.Id).DMT_Prospect_HPG_Sync__c, 'A Subgroup parent with no Supragroup ancestor has no group code to report');
        Assert.isTrue(syncedById.get(subUnderGroupWithSupra.Id).DMT_Prospect_HPG_Sync__c, 'A Group parent with a Supragroup ancestor resolves the Supragroup code');
        Assert.isTrue(syncedById.get(subUnderSubgroupWithSupra.Id).DMT_Prospect_HPG_Sync__c, 'A Subgroup parent with a Supragroup ancestor resolves the Supragroup code');
    }

    private static Account createHierarchyAccount(String name, String recordTypeDeveloperName, String structureType, String groupCode) {
        Account acc = new Account(
            Name = name,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId(),
            DES_Structure_Type__c = structureType,
            DES_Group_Code__c = groupCode
        );
        insert acc;
        return acc;
    }

    private static void linkAsParentChild(Account parentAcc, Account childAcc) {
        insert new AMH_GBL_Account_Relationship__c(
            AMH_Parent_Account__c = parentAcc.Id,
            AMH_Child_Account__c = childAcc.Id,
            AMH_Vision__c = 'Riesgos'
        );
    }

    private static Account createProspectSubsidiary(Id subsidiaryRtId, String name, String fiscalId, String customerId, Id participantId) {
        DES_UtilTestClass utilClass = new DES_UtilTestClass();
        Account sub = utilClass.createClient();
        sub.RecordTypeId = subsidiaryRtId;
        sub.Name = name;
        sub.DES_ID_Fiscal__c = fiscalId;
        sub.participant_id__c = participantId;
        sub.g_customer_id__c = customerId;
        insert sub;
        return [SELECT Id, Name, RecordTypeId, participant_id__c, DES_Group_Code__c, g_customer_id__c, g_golden_customer_id__c, DES_Country_Client__c, DMT_Prospect_HPG_Sync__c FROM Account WHERE Id = :sub.Id];
    }
}