@isTest
public with sharing class DMT_OpportunityRenewUtilTest {

    private static final String BASE_OPP_NAME = 'TEST_RENEW_UTIL_BASE_OPP';

    private static DMT_OpportunityRenewUtil.OppRenewResult renewWithMock(Id opportunityId, String newName) {
        DMT_OpportunityRenewUtil.OppRenewInput input = new DMT_OpportunityRenewUtil.OppRenewInput();
        input.newName = newName;

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        DMT_OpportunityRenewUtil.OppRenewResult result =
            DMT_OpportunityRenewUtil.renewOpportunity(opportunityId, input);
        Test.stopTest();

        return result;
    }

    private static Opportunity getAnyOpportunity() {
        return [
            SELECT Id, Name, Entific__c, DMT_Entity__c
            FROM Opportunity
            WHERE Name = :BASE_OPP_NAME
            LIMIT 1
        ];
    }

    @TestSetup
    static void loadTestData() {
        TriggerBypass.setBypass();

        insert new List<iaso__GBL_Rest_Services_Url__c>{
            DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT', 'https://service.ok', 'ServicesPartition', false),
            DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket', 'https://validation.ok', 'ServicesPartition', false),
            DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint', 'https://group-position.ok', 'ServicesPartition', false)
        };

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp.Name = BASE_OPP_NAME;
        update opp;
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);

        Product2        product2       = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry  pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product2);
        OpportunityLineItem oli        = DMT_Test_DataFactory.generateOpportunityLineItem(product2, pricebookEntry, opp);

        oli = [SELECT Id, UnitPrice, TotalPrice FROM OpportunityLineItem WHERE Id = :oli.Id];
        oli.UnitPrice = 200;
        update oli;

        DMT_Test_DataFactory.generateOpportunityTenor(oli);
        DMT_Test_DataFactory.generateOpportunityMitigant(oli);
        DMT_Test_DataFactory.generatexSell(opp);

        insert new DMT_TeamMember__c(
            Opportunity__c = opp.Id,
            User__c        = UserInfo.getUserId(),
            AccessLevel__c = 'Read'
        );

        insert new Local_Client__c(
            Name         = 'test local client',
            RecordTypeId = Schema.SObjectType.Local_Client__c
                               .getRecordTypeInfosByName().get('Client').getRecordTypeId(),
            Cib_Client__c = opp.AccountId
        );
    }

    // ─── Test renew success ───────────────────────────────────────────────────────
    @IsTest
    static void testRenewOpportunitySuccess() {
        Opportunity originalOpp = getAnyOpportunity();
        DMT_OpportunityRenewUtil.OppRenewResult result =
            renewWithMock(originalOpp.Id, 'Opportunity Renewed Test');

        Assert.isNotNull(result,              'Result should not be null');
        Assert.isTrue(result.success,         'Renewal should be successful');
        Assert.isNotNull(result.newOppId,     'New Opportunity Id should not be null');
        Assert.areEqual(originalOpp.Id, result.originalOppId, 'originalOppId should match');
        Assert.isNull(result.errorMessage,    'There should be no error message');
    }

    // ─── Test renew verifies child records ───────────────────────────────────────
    @IsTest
    static void testRenewOpportunityChildRecords() {
        Opportunity originalOpp = getAnyOpportunity();

        Integer originalOliCount = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :originalOpp.Id];
        Integer originalClientCount = [SELECT COUNT() FROM DMT_Opportunity_Client__c WHERE DMT_MDE_Opportunity__c = :originalOpp.Id];
        Integer originalXSellCount = [SELECT COUNT() FROM DMT_X_Sell__c WHERE Opportunity__c = :originalOpp.Id];
        Integer originalParticipantCount = [SELECT COUNT() FROM DMT_TeamMember__c WHERE Opportunity__c = :originalOpp.Id];

        List<OpportunityLineItem> originalOlis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :originalOpp.Id];
        Integer originalTenorCount = [SELECT COUNT() FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c IN :originalOlis];
        Integer originalMitigantCount = [SELECT COUNT() FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c IN :originalOlis];

        DMT_OpportunityRenewUtil.OppRenewResult result =
            renewWithMock(originalOpp.Id, 'Opportunity Renewed Test Children');

        Assert.isTrue(result.success, 'Renewal should be successful');
        Id newOppId = result.newOppId;

        Integer newOliCount = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :newOppId];
        Integer newClientCount = [SELECT COUNT() FROM DMT_Opportunity_Client__c WHERE DMT_MDE_Opportunity__c = :newOppId];
        Integer newXSellCount = [SELECT COUNT() FROM DMT_X_Sell__c WHERE Opportunity__c = :newOppId];
        Integer newParticipantCount = [SELECT COUNT() FROM DMT_TeamMember__c WHERE Opportunity__c = :newOppId];

        List<OpportunityLineItem> newOlis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :newOppId];
        Integer newTenorCount = [SELECT COUNT() FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c IN :newOlis];
        Integer newMitigantCount = [SELECT COUNT() FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c IN :newOlis];

        Integer expectedClientClones = (originalClientCount > 0) ? 1 : 0;

        // In some orgs, automation may create additional child records on insert.
        // These asserts validate minimum expected clones without assuming an exact total.
        Assert.isTrue(newOliCount >= originalOliCount, 'OLIs should be cloned at least for original records');
        Assert.areEqual(expectedClientClones, newClientCount,
            'OppClients should follow util behavior: clone only one record per Opportunity when present');
        Assert.isTrue(newXSellCount >= originalXSellCount, 'XSells should be cloned at least for original records');
        Assert.isTrue(newParticipantCount >= originalParticipantCount, 'Participants should be cloned at least for original records');
        Assert.isTrue(newTenorCount >= originalTenorCount, 'Tenors should be cloned at least for original records');
        Assert.isTrue(newMitigantCount >= originalMitigantCount, 'Mitigants should be cloned at least for original records');
    }

    // ─── Test renew without newName keeps original name ──────────────────────────
    @IsTest
    static void testRenewOpportunityKeepsOriginalName() {
        Opportunity originalOpp = getAnyOpportunity();

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        DMT_OpportunityRenewUtil.OppRenewInput input = new DMT_OpportunityRenewUtil.OppRenewInput();
        // input.newName intentionally left blank
        DMT_OpportunityRenewUtil.OppRenewResult result =
            DMT_OpportunityRenewUtil.renewOpportunity(originalOpp.Id, input);
        Test.stopTest();

        Assert.isTrue(result.success, 'Renewal should be successful. Error: ' + result.errorMessage);
        Opportunity newOpp = [SELECT Id, Name FROM Opportunity WHERE Id = :result.newOppId];
        Assert.areEqual(originalOpp.Name, newOpp.Name, 'Name should be kept from the original');
    }

    // ─── Test getRenewOpportunityData taxonomy not found ─────────────────────────
    @IsTest
    static void testGetRenewOpportunityDataNoTaxonomy() {
        Opportunity opp = getAnyOpportunity();

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityRenewUtil.getRenewOpportunityData(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result,             'Result map should not be null');
        Assert.isNull(result.get('entific'), 'Entific should be null when no taxonomy record exists');
        Assert.isNull(result.get('entity'),  'Entity should be null when no taxonomy record exists');
    }

    // ─── Test getRenewOpportunityData null Id ─────────────────────────────────────
    @IsTest
    static void testGetRenewOpportunityDataNullId() {
        Test.startTest();
        try {
            DMT_OpportunityRenewUtil.getRenewOpportunityData(null);
            Assert.fail('An AuraHandledException should have been thrown for a null Id');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
        }
        Test.stopTest();
    }

    // ─── Test renew with non-existent ID ─────────────────────────────────────────
    @IsTest
    static void testRenewOpportunityNotFound() {
        Id fakeId = '006000000000000AAA';

        Test.startTest();
        DMT_OpportunityRenewUtil.OppRenewInput input = new DMT_OpportunityRenewUtil.OppRenewInput();
        input.newName = 'Should Fail';
        DMT_OpportunityRenewUtil.OppRenewResult result =
            DMT_OpportunityRenewUtil.renewOpportunity(fakeId, input);
        Test.stopTest();

        Assert.isNotNull(result,              'Result should not be null');
        Assert.isFalse(result.success,        'Renewal should have failed');
        Assert.isNotNull(result.errorMessage, 'There should be an error message');
    }

    @IsTest
    static void testGetRenewOpportunityDataWithTaxonomy() {
        Opportunity opp = getAnyOpportunity();

        insert new List<DMT_Taxonomy_Values__c>{
            new DMT_Taxonomy_Values__c(
                DMT_Catalog__c = 'CD07',
                DMT_Active__c = true,
                DMT_Key__c = opp.Entific__c,
                DMT_Value__c = opp.Entific__c,
                DMT_Name__c = 'Entific ES',
                DMT_Name_EN__c = 'Entific EN'
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Catalog__c = 'H006',
                DMT_Key__c = 'ENTITY_KEY',
                DMT_Value__c = opp.DMT_Entity__c,
                DMT_Name__c = 'Entity ES',
                DMT_Name_EN__c = 'Entity EN'
            )
        };

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityRenewUtil.getRenewOpportunityData(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result.get('opportunity'), 'Opportunity should be returned');
        Assert.isNotNull(result.get('entific'), 'Entific taxonomy should be returned');
        Assert.isNotNull(result.get('entity'), 'Entity taxonomy should be returned');
    }

    @IsTest
    static void testRenewOpportunitiesBulkMixedResults() {
        Opportunity originalOpp = getAnyOpportunity();
        Id fakeId = '006000000000000AAA';

        Map<Id, DMT_OpportunityRenewUtil.OppRenewInput> inputByOppId =
            new Map<Id, DMT_OpportunityRenewUtil.OppRenewInput>();

        DMT_OpportunityRenewUtil.OppRenewInput okInput = new DMT_OpportunityRenewUtil.OppRenewInput();
        okInput.newName = 'Bulk Renewed Opportunity';
        inputByOppId.put(originalOpp.Id, okInput);

        DMT_OpportunityRenewUtil.OppRenewInput badInput = new DMT_OpportunityRenewUtil.OppRenewInput();
        badInput.newName = 'Should Fail';
        inputByOppId.put(fakeId, badInput);

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        List<DMT_OpportunityRenewUtil.OppRenewResult> results =
            DMT_OpportunityRenewUtil.renewOpportunities(inputByOppId);
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Both opportunities should return a result');

        Map<Id, DMT_OpportunityRenewUtil.OppRenewResult> resultByOriginalId =
            new Map<Id, DMT_OpportunityRenewUtil.OppRenewResult>();
        for (DMT_OpportunityRenewUtil.OppRenewResult oneResult : results) {
            resultByOriginalId.put(oneResult.originalOppId, oneResult);
        }

        Assert.isTrue(resultByOriginalId.containsKey(originalOpp.Id),
            'Bulk result should include the existing opportunity');
        Assert.isTrue(resultByOriginalId.containsKey(fakeId),
            'Bulk result should include the missing opportunity as failed');
        Assert.isTrue(resultByOriginalId.get(originalOpp.Id).success,
            'Existing opportunity should be renewed successfully. Error: ' + resultByOriginalId.get(originalOpp.Id).errorMessage);
        Assert.isFalse(resultByOriginalId.get(fakeId).success,
            'Missing opportunity should fail in bulk renewal');
    }
}