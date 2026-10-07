@IsTest
private class DMT_ApprovalDataControllerTest {

    // ─── Setup ───────────────────────────────────────────────────────────────

    @TestSetup
    static void setupTestData() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        DMT_Test_DataFactory.generateOppGlobalStructure(opp.Id);

        // DMT_Test_DataFactory.generateTaxonomies() only creates C375/E895.
        // The controller queries C264 and H007, so we create those records directly.
        insert new List<DMT_Taxonomy_Values__c>{
            new DMT_Taxonomy_Values__c(
                DMT_Name__c        = 'Option C264 A',
                DMT_Name_EN__c     = 'Option C264 A',
                DMT_External_Id__c = 'C264_A',
                DMT_Key__c         = 'C264_A',
                CurrencyIsoCode    = 'EUR',
                DMT_Catalog__c     = 'C264',
                DMT_Value__c       = 'VAL_C264_A',
                DMT_Active__c      = true
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Name__c        = 'Option H007 A',
                DMT_Name_EN__c     = 'Option H007 A EN',
                DMT_External_Id__c = 'H007_A',
                DMT_Key__c         = 'H007_A',
                CurrencyIsoCode    = 'EUR',
                DMT_Catalog__c     = 'H007',
                DMT_Value__c       = 'VAL_H007_A',
                DMT_Active__c      = true
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Name__c        = 'Option H007 inactive',
                DMT_Name_EN__c     = 'Option H007 inactive EN',
                DMT_External_Id__c = 'H007_B',
                DMT_Key__c         = 'H007_B',
                CurrencyIsoCode    = 'EUR',
                DMT_Catalog__c     = 'H007',
                DMT_Value__c       = 'VAL_H007_B',
                DMT_Active__c      = false
            )
        };
    }

    // ─── getApprovalData – Happy Path ─────────────────────────────────────────

    @IsTest
    static void testGetApprovalData_happyPath() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.getApprovalData(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result map must not be null');
        Assert.isTrue(result.containsKey('bankingPool'),'Result must contain bankingPool');

        DMT_Opportunity_Client__c oppClient = (DMT_Opportunity_Client__c) result.get('opportunityClient');
        Assert.isNotNull(oppClient, 'opportunityClient record must not be null');
        Assert.isNotNull(result.get('opportunityClientId'), 'opportunityClientId must not be null');

        List<DMT_Global_Structure__c> gs = (List<DMT_Global_Structure__c>) result.get('globalStructure');
        Assert.isTrue(gs.size() > 0, 'globalStructure must contain at least one record');
    }

    @IsTest
    static void testGetApprovalData_bankingPool_returnsSingleRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        insert new DMT_Banking_Pool_Structure__c(
            Name               = 'Test Pool',
            DMT_Opportunity__c = opp.Id
        );

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.getApprovalData(opp.Id);
        Test.stopTest();

        List<DMT_Banking_Pool_Structure__c> pool =
            (List<DMT_Banking_Pool_Structure__c>) result.get('bankingPool');
        Assert.areEqual(1, pool.size(), 'bankingPool must contain exactly 1 record');
    }

    // ─── getApprovalData – Negative Cases ────────────────────────────────────

    @IsTest
    static void testGetApprovalData_nullId_throwsIllegalArgument() {
        Test.startTest();
        try {
            DMT_ApprovalDataController.getApprovalData(null);
            Assert.fail('Expected IllegalArgumentException for null opportunityId');
        } catch (IllegalArgumentException e) {
            Assert.areEqual(
                'opportunityId is required',
                e.getMessage(),
                'Exception message must match'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetApprovalData_noOpportunityClient_returnsNullClient() {
        DMT_Opportunity_Client__c oc = [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];
        delete oc;
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.getApprovalData(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result map must not be null even without an OppClient');
        Assert.isNull(
            result.get('opportunityClient'),
            'opportunityClient must be null when no record exists'
        );
        Assert.isNull(
            result.get('opportunityClientId'),
            'opportunityClientId must be null when no record exists'
        );
    }

    @IsTest
    static void testGetApprovalData_withGroupAccount_populatesGroupComparisonData() {
        // Update the opportunity's linked Account to be a Group with valid comparison data
        // so that resolveComparisonAccountId returns it and groupComparisonData is populated.
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        update new Account(
            Id = opp.AccountId,
            DES_Structure_Type__c = 'Group',
            Industry_Overview_desc__c = 'Valid industry overview for comparison test'
        );

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.getApprovalData(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result must not be null');
        Assert.isTrue(result.containsKey('groupComparisonData'), 'groupComparisonData key must be present');
        Assert.isTrue(result.containsKey('groupId'), 'groupId key must be present');
        Assert.isNotNull(result.get('groupComparisonData'), 'groupComparisonData must not be null');
        Assert.areEqual(opp.AccountId, result.get('groupId'), 'groupId must match the comparison account');
    }

    // ─── saveApprovalData – Happy Path ────────────────────────────────────────

    @IsTest
    static void testSaveApprovalData_emptyPayload_succeeds() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.saveApprovalData(
            null, null, null, opp.Id, null
        );
        Test.stopTest();

        Assert.isNotNull(result, 'Result must not be null');
        Assert.isTrue((Boolean) result.get('success'), 'Empty-payload save must return success = true');
    }

    @IsTest
    static void testSaveApprovalData_updatesOppClientTextField() {
        Opportunity opp              = [SELECT Id FROM Opportunity LIMIT 1];
        DMT_Opportunity_Client__c oc = [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];

        Map<String, Object> recordFields = new Map<String, Object>{
            'DMT_History_Deal__c' => 'Updated deal history via unit test'
        };

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.saveApprovalData(
            recordFields, oc.Id, null, opp.Id, null
        );
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('success'), 'Save must return success = true');
        DMT_Opportunity_Client__c updated =
            [SELECT DMT_History_Deal__c FROM DMT_Opportunity_Client__c WHERE Id = :oc.Id];
        Assert.areEqual(
            'Updated deal history via unit test',
            updated.DMT_History_Deal__c,
            'DMT_History_Deal__c must reflect the updated value'
        );
    }

    @IsTest
    static void testSaveApprovalData_updatesOpportunityField() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, Object> opportunityFields = new Map<String, Object>{
            'Description' => 'Description set from unit test'
        };

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.saveApprovalData(
            null, null, null, opp.Id, opportunityFields
        );
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('success'), 'Save must return success = true');
        Opportunity updated = [SELECT Description FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual(
            'Description set from unit test',
            updated.Description,
            'Opportunity Description must be updated'
        );
    }

    @IsTest
    static void testSaveApprovalData_upsertsBusinessPlan() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Pre-insert a BP record so the upsert acts as an update (no required-field risk).
        DMT_Opportunity_Business_Plan__c existingBp = new DMT_Opportunity_Business_Plan__c(
            DMT_Opportunity__c   = opp.Id
        );
        insert existingBp;

        String bpJson = '[{"Id":"' + existingBp.Id
                      + '","DMT_Opportunity__c  ":"' + opp.Id + '"}]';

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.saveApprovalData(
            null, null, bpJson, opp.Id, null
        );
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('success'), 'Upsert of existing business plan must succeed');
        Integer bpCount = [
            SELECT COUNT()
            FROM DMT_Opportunity_Business_Plan__c
            WHERE Id = :existingBp.Id
        ];
        Assert.areEqual(1, bpCount, 'Business plan record must still exist after upsert');
    }

    // ─── saveApprovalData – Negative Cases ───────────────────────────────────

    @IsTest
    static void testSaveApprovalData_malformedBpJson_throwsAuraHandledException() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        try {
            DMT_ApprovalDataController.saveApprovalData(
                null, null, 'NOT_VALID{{JSON', opp.Id, null
            );
            Assert.fail('Expected AuraHandledException for malformed JSON');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Exception message must not be null');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSaveApprovalData_invalidCastValue_throwsAuraHandledException() {
        Opportunity opp              = [SELECT Id FROM Opportunity LIMIT 1];
        DMT_Opportunity_Client__c oc = [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];

        // DMT_Commitment_Deadline__c is a Date field — passing an invalid string triggers castValue failure.
        Map<String, Object> badFields = new Map<String, Object>{
            'DMT_Commitment_Deadline__c' => 'not-a-date'
        };

        Test.startTest();
        try {
            DMT_ApprovalDataController.saveApprovalData(
                badFields, oc.Id, null, opp.Id, null
            );
            Assert.fail('Expected AuraHandledException for invalid field value');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Exception message must not be null');
        }
        Test.stopTest();
    }

    // ─── getTaxonomyCatalogValues – Happy Path ─────────────────────────────

    @IsTest
    static void testGetTaxonomyCatalogValues_returnsNonNullMap() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result =
            DMT_ApprovalDataController.getTaxonomyCatalogValues();
        Test.stopTest();

        Assert.isNotNull(result, 'Taxonomy catalog map must not be null');
    }

    @IsTest
    static void testGetTaxonomyCatalogValues_activeRecordsReturnedWithLabelAndValue() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result =
            DMT_ApprovalDataController.getTaxonomyCatalogValues();
        Test.stopTest();

        Assert.isNotNull(result, 'Taxonomy catalog map must not be null');
        Assert.isTrue(result.containsKey('C264'), 'Result must contain catalog C264');
        Assert.isTrue(result.containsKey('H007'), 'Result must contain catalog H007');

        for (String code : result.keySet()) {
            for (Map<String, String> entry : result.get(code)) {
                Assert.isTrue(entry.containsKey('label'),
                    'Each entry must have a label key (catalog: ' + code + ')');
                Assert.isTrue(entry.containsKey('value'),
                    'Each entry must have a value key (catalog: ' + code + ')');
                Assert.isNotNull(entry.get('label'), 'label must not be null');
                Assert.isNotNull(entry.get('value'), 'value must not be null');
            }
        }
    }

    @IsTest
    static void testGetTaxonomyCatalogValues_inactiveRecordsExcluded() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result =
            DMT_ApprovalDataController.getTaxonomyCatalogValues();
        Test.stopTest();

        // H007 has 2 records in TestSetup but only 1 is active.
        List<Map<String, String>> h007Values = result.get('H007');
        Assert.areEqual(1, h007Values.size(),
            'H007 must return only the 1 active record, not the inactive one');
    }

    // ─── Additional coverage tests ────────────────────────────────────────────

    @IsTest
    static void testUpdateOpportunityClient_multipleFields() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        DMT_Opportunity_Client__c oc = [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];

        Map<String, Object> fields = new Map<String, Object>{
            'DMT_History_Deal__c'        => 'Updated deal',
            'DMT_Purpose__c'             => 'Updated purpose',
            'DMT_Description_Issues__c'  => 'Updated description'
        };

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.saveApprovalData(
            fields, oc.Id, null, opp.Id, null
        );
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('success'), 'Save must succeed');
        DMT_Opportunity_Client__c updated = [
            SELECT DMT_History_Deal__c, DMT_Purpose__c, DMT_Description_Issues__c
            FROM DMT_Opportunity_Client__c
            WHERE Id = :oc.Id
        ];
        Assert.areEqual('Updated deal', updated.DMT_History_Deal__c, 'Deal history must be updated');
        Assert.areEqual('Updated purpose', updated.DMT_Purpose__c, 'Purpose must be updated');
        Assert.areEqual('Updated description', updated.DMT_Description_Issues__c, 'Description must be updated');
    }

    @IsTest
    static void testUpdateOpportunityClient_dateField() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        DMT_Opportunity_Client__c oc = [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];

        Map<String, Object> fields = new Map<String, Object>{
            'DMT_Commitment_Deadline__c' => '2026-12-31'
        };

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.saveApprovalData(
            fields, oc.Id, null, opp.Id, null
        );
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('success'), 'Save must succeed');
        DMT_Opportunity_Client__c updated = [
            SELECT DMT_Commitment_Deadline__c
            FROM DMT_Opportunity_Client__c
            WHERE Id = :oc.Id
        ];
        Assert.areEqual(Date.valueOf('2026-12-31'), updated.DMT_Commitment_Deadline__c,
            'Deadline date must be updated');
    }

    @IsTest
    static void testGetApprovalData_withMultipleGlobalStructures() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Insert multiple Global Structure records with specific names and capture their IDs
        List<DMT_Global_Structure__c> structuresToInsert = new List<DMT_Global_Structure__c>{
            new DMT_Global_Structure__c(
                Name = 'Structure A',
                DMT_Opportunity__c = opp.Id
            ),
            new DMT_Global_Structure__c(
                Name = 'Structure B',
                DMT_Opportunity__c = opp.Id
            )
        };
        insert structuresToInsert;

        Set<Id> expectedIds = new Set<Id>();
        Set<String> expectedNames = new Set<String>{'Structure A', 'Structure B'};
        for (DMT_Global_Structure__c gs : structuresToInsert) {
            expectedIds.add(gs.Id);
        }

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.getApprovalData(opp.Id);
        Test.stopTest();

        List<DMT_Global_Structure__c> gs = (List<DMT_Global_Structure__c>) result.get('globalStructure');
        
        // Filter returned structures to only include the ones created in this test
        Set<Id> returnedIds = new Set<Id>();
        Set<String> returnedNames = new Set<String>();
        for (DMT_Global_Structure__c structure : gs) {
            if (expectedNames.contains(structure.Name)) {
                returnedIds.add(structure.Id);
                returnedNames.add(structure.Name);
            }
        }

        Assert.areEqual(2, returnedIds.size(), 'Must return both created global structure records');
        Assert.areEqual(expectedIds, returnedIds, 'Returned structures must match the created ones');
        Assert.areEqual(expectedNames, returnedNames, 'Returned structure names must match the created ones');
    }

    @IsTest
    static void testGetApprovalData_withMultipleBankingPools() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Insert multiple Banking Pool records
        insert new List<DMT_Banking_Pool_Structure__c>{
            new DMT_Banking_Pool_Structure__c(
                Name = 'Pool A',
                DMT_Opportunity__c = opp.Id,
                DMT_Ticket__c = '1000',
                DMT_Margin__c = '0.5',
                DMT_N_Banks__c = '5'
            ),
            new DMT_Banking_Pool_Structure__c(
                Name = 'Pool B',
                DMT_Opportunity__c = opp.Id,
                DMT_Ticket__c = '2000',
                DMT_Margin__c = '0.75',
                DMT_N_Banks__c = '8'
            )
        };

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.getApprovalData(opp.Id);
        Test.stopTest();

        List<DMT_Banking_Pool_Structure__c> bp = (List<DMT_Banking_Pool_Structure__c>) result.get('bankingPool');
        Assert.areEqual(2, bp.size(), 'Must return both banking pool records');
    }

    @IsTest
    static void testSaveApprovalData_combinedUpdates() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        DMT_Opportunity_Client__c oc = [SELECT Id FROM DMT_Opportunity_Client__c LIMIT 1];

        Map<String, Object> clientFields = new Map<String, Object>{
            'DMT_History_Deal__c' => 'Client deal update'
        };

        Map<String, Object> oppFields = new Map<String, Object>{
            'Description' => 'Opportunity description update'
        };

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.saveApprovalData(
            clientFields, oc.Id, null, opp.Id, oppFields
        );
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('success'), 'Combined save must succeed');

        DMT_Opportunity_Client__c updatedClient = [
            SELECT DMT_History_Deal__c
            FROM DMT_Opportunity_Client__c
            WHERE Id = :oc.Id
        ];
        Assert.areEqual('Client deal update', updatedClient.DMT_History_Deal__c,
            'Client field must be updated');

        Opportunity updatedOpp = [SELECT Description FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Opportunity description update', updatedOpp.Description,
            'Opportunity field must be updated');
    }

    // ─── TaxonomyValueComparator – compare coverage ───────────────────────────

    @IsTest
    static void testGetTaxonomyCatalogValues_comparator_ascendingTextSort() {
        // Insert 3 C264 records in wrong order to force comparator text-ascending logic (result > 0 and result < 0)
        insert new List<DMT_Taxonomy_Values__c>{
            new DMT_Taxonomy_Values__c(
                DMT_Name__c        = 'C264 Gamma',
                DMT_Name_EN__c     = 'C264 Gamma EN',
                DMT_External_Id__c = 'C264_GAMMA',
                DMT_Key__c         = 'C264_GAMMA',
                CurrencyIsoCode    = 'EUR',
                DMT_Catalog__c     = 'C264',
                DMT_Value__c       = 'GAMMA',
                DMT_Active__c      = true
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Name__c        = 'C264 Alpha',
                DMT_Name_EN__c     = 'C264 Alpha EN',
                DMT_External_Id__c = 'C264_ALPHA',
                DMT_Key__c         = 'C264_ALPHA',
                CurrencyIsoCode    = 'EUR',
                DMT_Catalog__c     = 'C264',
                DMT_Value__c       = 'ALPHA',
                DMT_Active__c      = true
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Name__c        = 'C264 Beta',
                DMT_Name_EN__c     = 'C264 Beta EN',
                DMT_External_Id__c = 'C264_BETA',
                DMT_Key__c         = 'C264_BETA',
                CurrencyIsoCode    = 'EUR',
                DMT_Catalog__c     = 'C264',
                DMT_Value__c       = 'BETA',
                DMT_Active__c      = true
            )
        };

        Test.startTest();
        Map<String, List<Map<String, String>>> result =
            DMT_ApprovalDataController.getTaxonomyCatalogValues();
        Test.stopTest();

        List<Map<String, String>> c264Values = result.get('C264');
        Assert.isNotNull(c264Values, 'C264 values must not be null');

        // Extract only the inserted test values (preserving order) and verify ASC sort
        List<String> testValues = new List<String>();
        for (Map<String, String> entry : c264Values) {
            String v = entry.get('value');
            if (v == 'ALPHA' || v == 'BETA' || v == 'GAMMA') {
                testValues.add(v);
            }
        }
        Assert.areEqual(3, testValues.size(), 'All 3 inserted C264 test records must be present');
        Assert.areEqual('ALPHA', testValues[0], 'First value must be ALPHA (ascending sort)');
        Assert.areEqual('BETA',  testValues[1], 'Second value must be BETA (ascending sort)');
        Assert.areEqual('GAMMA', testValues[2], 'Third value must be GAMMA (ascending sort)');
    }

    @IsTest
    static void testGetTaxonomyCatalogValues_comparator_equalValues() {
        // Insert 2 C264 records with the same DMT_Value__c to cover the result = 0 branch in compare
        insert new List<DMT_Taxonomy_Values__c>{
            new DMT_Taxonomy_Values__c(
                DMT_Name__c        = 'C264 Equal 1',
                DMT_Name_EN__c     = 'C264 Equal 1 EN',
                DMT_External_Id__c = 'C264_EQ1',
                DMT_Key__c         = 'C264_EQ1',
                CurrencyIsoCode    = 'EUR',
                DMT_Catalog__c     = 'C264',
                DMT_Value__c       = 'EQUAL_VAL',
                DMT_Active__c      = true
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Name__c        = 'C264 Equal 2',
                DMT_Name_EN__c     = 'C264 Equal 2 EN',
                DMT_External_Id__c = 'C264_EQ2',
                DMT_Key__c         = 'C264_EQ2',
                CurrencyIsoCode    = 'EUR',
                DMT_Catalog__c     = 'C264',
                DMT_Value__c       = 'EQUAL_VAL',
                DMT_Active__c      = true
            )
        };

        Test.startTest();
        Map<String, List<Map<String, String>>> result =
            DMT_ApprovalDataController.getTaxonomyCatalogValues();
        Test.stopTest();

        List<Map<String, String>> c264Values = result.get('C264');
        Assert.isNotNull(c264Values, 'C264 values must not be null');

        Integer equalCount = 0;
        for (Map<String, String> entry : c264Values) {
            if ('EQUAL_VAL'.equals(entry.get('value'))) {
                equalCount++;
            }
        }
        Assert.areEqual(2, equalCount, 'Both records with equal sort values must be present');
    }

    @IsTest
    static void testGetTaxonomyCatalogValues_comparator_h007AscendingByName() {
        // H007 sorts by DMT_Name_EN__c ASC — insert 2 active records in reverse order to force comparator
        insert new List<DMT_Taxonomy_Values__c>{
            new DMT_Taxonomy_Values__c(
                DMT_Name__c        = 'H007 Zebra',
                DMT_Name_EN__c     = 'Zebra Option',
                DMT_External_Id__c = 'H007_ZEBRA',
                DMT_Key__c         = 'H007_ZEBRA',
                CurrencyIsoCode    = 'EUR',
                DMT_Catalog__c     = 'H007',
                DMT_Value__c       = 'VAL_ZEBRA',
                DMT_Active__c      = true
            ),
            new DMT_Taxonomy_Values__c(
                DMT_Name__c        = 'H007 Apple',
                DMT_Name_EN__c     = 'Apple Option',
                DMT_External_Id__c = 'H007_APPLE',
                DMT_Key__c         = 'H007_APPLE',
                CurrencyIsoCode    = 'EUR',
                DMT_Catalog__c     = 'H007',
                DMT_Value__c       = 'VAL_APPLE',
                DMT_Active__c      = true
            )
        };

        Test.startTest();
        Map<String, List<Map<String, String>>> result =
            DMT_ApprovalDataController.getTaxonomyCatalogValues();
        Test.stopTest();

        List<Map<String, String>> h007Values = result.get('H007');
        Assert.isNotNull(h007Values, 'H007 values must not be null');

        // Apple must come before Zebra (ascending by DMT_Name_EN__c)
        Integer appleIdx = -1;
        Integer zebraIdx = -1;
        for (Integer i = 0; i < h007Values.size(); i++) {
            String lbl = h007Values[i].get('label');
            if ('Apple Option'.equals(lbl)) appleIdx = i;
            if ('Zebra Option'.equals(lbl)) zebraIdx = i;
        }
        Assert.isTrue(appleIdx >= 0, 'Apple Option must be in H007 results');
        Assert.isTrue(zebraIdx >= 0, 'Zebra Option must be in H007 results');
        Assert.isTrue(appleIdx < zebraIdx,
            'Apple Option must come before Zebra Option (ascending sort by DMT_Name_EN__c)');
    }

    @IsTest
    static void testSaveApprovalData_withNullOpportunityClientId() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, Object> oppFields = new Map<String, Object>{
            'Description' => 'Test description'
        };

        Test.startTest();
        Map<String, Object> result = DMT_ApprovalDataController.saveApprovalData(
            null, null, null, opp.Id, oppFields
        );
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('success'), 'Save with null client ID must succeed');
        Opportunity updated = [SELECT Description FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Test description', updated.Description, 'Opportunity must be updated');
    }
}