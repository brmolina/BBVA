@isTest
private class DMT_XSellTest {

    /**
     * @testSetup creates the foundational data once for all test methods.
     * This drastically speeds up test execution and ensures a clean state.
     */
    @testSetup
    static void setupTestData() {

        TriggerBypass.setBypass();
        // 1. Create a dummy Opportunity
        Opportunity testOpp = DMT_Test_DataFactory.generateOpportunity();

        // 2. Create some initial X-Sell records to test updates and deletions
        List<DMT_X_Sell__c> initialXSell = new List<DMT_X_Sell__c>();
        initialXSell.add(new DMT_X_Sell__c(Opportunity__c = testOpp.Id, Booking_Geography__c = 'ES', XSELL_Value_PY__c = 100));
        initialXSell.add(new DMT_X_Sell__c(Opportunity__c = testOpp.Id, Booking_Geography__c = 'US', XSELL_Value_PY__c = 200));
        
        // The factory already created an Account. Query it to prevent LIMIT 1 conflicts later.
        Id accId = [SELECT AccountId FROM Opportunity WHERE Id = :testOpp.Id LIMIT 1].AccountId;
        initialXSell.add(new DMT_X_Sell__c(Account__c = accId, Booking_Geography__c = 'UK', XSELL_Value_PY__c = 300));
        
        insert initialXSell;

        // 3. Create Taxonomy Data for getGeographyOptions
        DMT_Taxonomy_Values__c initialTax = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'H006', 
            DMT_Value__c = 'TEST-ENT',
            DMT_Active__c = true
        );
        insert initialTax;

        DMT_Taxonomy_Values__c finalTax = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'H007', 
            DMT_Value__c = 'TEST-ENT-ES', 
            DMT_Name__c = 'TEST LABEL', 
            DMT_Name_EN__c = 'TEST LABEL EN', 
            DMT_Active__c = true
        );
        insert finalTax;

        // Use the Factory to link them
        DMT_Taxonomy_Relationship__c rel = DMT_Test_DataFactory.generateTaxonomyRelationship(initialTax, finalTax);
        rel.DMT_Id_Catalog_Initial__c = 'H006';
        rel.DMT_Id_Catalog_Final__c = 'H007';
        update rel;
    }

    /**
     * TEST 1: The Happy Path & Ghost ID Handling
     * Validates that standard updates, deletions, and inserts work, AND proves 
     * that fake UI IDs (like '0' or 'NEW_') don't crash the Apex class.
     */
    @isTest
    static void testSuccessfulUpsertAndDelete() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // Filter specifically for Opportunity records to match original test expectations
        // Query all fields needed by buildDuplicateKey method
        List<DMT_X_Sell__c> existingRecords = [SELECT Id, Opportunity__c, Booking_Geography__c, XSELL_Value_PY__c, XSELL_Value_CY__c, XSELL_Value_NY__c, XSELL_Value_NY1__c FROM DMT_X_Sell__c WHERE Opportunity__c != null];
        
        // 1. Test Deletes (Passing valid ID, '0', and garbage text tests the getValidId catch block)
        List<String> recordsToDelete = new List<String>{
            String.valueOf(existingRecords[0].Id), 
            '0', 
            'fakeId1234567890'
        };

        // 2. Test Upserts (Update 1, Insert 1)
        List<DMT_X_Sell__c> recordsToUpsert = new List<DMT_X_Sell__c>();
        
        DMT_X_Sell__c toUpdate = existingRecords[1];
        toUpdate.XSELL_Value_PY__c = 500; 
        recordsToUpsert.add(toUpdate);

        // For "Ghost" UI rows, LWC strips '0' and sends null. We replicate that here for inserts.
        recordsToUpsert.add(new DMT_X_Sell__c(
            Opportunity__c = opp.Id, 
            Booking_Geography__c = 'FR', 
            XSELL_Value_PY__c = 400
        ));

        Test.startTest();
        DMT_XSell.saveXSellRecords(recordsToUpsert, recordsToDelete);
        Test.stopTest();

        List<DMT_X_Sell__c> postExecuteRecords = [SELECT Id, XSELL_Value_PY__c FROM DMT_X_Sell__c WHERE Opportunity__c != null ORDER BY XSELL_Value_PY__c ASC];
        
        Assert.areEqual(2, postExecuteRecords.size(), 'Started with 2, deleted 1, inserted 1. Should be 2 records.');
    }

    /**
     * TEST 2: Exception Handling & Rollback
     * Forces a DML failure to ensure the Savepoint rolls back the database 
     * and the AuraHandledException is bubbled up to the LWC.
     */
    @isTest
    static void testSaveXSellRecordsException() {
        // Generate a fake ID that perfectly matches the SObject prefix so it survives Id.valueOf(), 
        // but fails Database.upsert() because it doesn't exist, forcing the DmlException.
        String prefix = DMT_X_Sell__c.SObjectType.getDescribe().getKeyPrefix();
        String fakeValidFormatId = prefix + '000000000000'; 
        
        DMT_X_Sell__c badRecord = new DMT_X_Sell__c(
            Id = fakeValidFormatId,
            XSELL_Value_PY__c = 999
        );

        Boolean auraExceptionThrown = false;

        Test.startTest();
        try {
            DMT_XSell.saveXSellRecords(new List<DMT_X_Sell__c>{ badRecord }, null);
        } catch (AuraHandledException e) {
            auraExceptionThrown = true;
            Assert.isTrue(e.getMessage().contains('Error saving Cross Sell data'), 'Should contain expected exception text.');
        } catch (Exception e) {
            Assert.isTrue(false, 'Should have thrown AuraHandledException. Threw instead: ' + e.getMessage());
        }
        Test.stopTest();

        Assert.isTrue(auraExceptionThrown, 'AuraHandledException must be thrown.');
    }

    /**
     * TEST 3: Null Handling
     * Validates that passing null lists doesn't break the code.
     */
    @isTest
    static void testNullPayloads() {
        Test.startTest();
        // Should execute safely and do nothing
        DMT_XSell.saveXSellRecords(null, null);
        Test.stopTest();
        
        // We added 1 Account X-Sell in setup, so total is now 3
        Assert.areEqual(3, [SELECT COUNT() FROM DMT_X_Sell__c], 'Record count should remain unchanged when passing null payloads.');
    }

    /**
     * TEST 4: Get X-Sell Records
     * Validates retrieval of records for Opportunity, Account, null, and unsupported SObject types.
     */
    @isTest
    static void testGetXSellRecords() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Id = :opp.AccountId LIMIT 1];

        Test.startTest();
        List<DMT_X_Sell__c> oppRecords = DMT_XSell.getXSellRecords(opp.Id);
        List<DMT_X_Sell__c> accRecords = DMT_XSell.getXSellRecords(acc.Id);
        List<DMT_X_Sell__c> nullRecords = DMT_XSell.getXSellRecords(null);
        
        // Pass a User ID to test the fallback condition (sObjName is neither Opportunity nor Account)
        List<DMT_X_Sell__c> invalidObjRecords = DMT_XSell.getXSellRecords(UserInfo.getUserId());
        Test.stopTest();

        Assert.areEqual(2, oppRecords.size(), 'Should return 2 records for Opportunity');
        Assert.areEqual(1, accRecords.size(), 'Should return 1 record for Account');
        Assert.isTrue(nullRecords.isEmpty(), 'Should return empty list for null id');
        Assert.isTrue(invalidObjRecords.isEmpty(), 'Should return empty list for unhandled sObject type');
    }

    /**
     * TEST 5: Get Geography Options
     * Validates taxonomy retrieval with and without an entity code.
     */
    @isTest
    static void testGetGeographyOptions() {
        Test.startTest();
        // 1. Test with specific entity code (Hits DMT_Taxonomy_Relationship__c)
        List<Map<String, String>> relationshipOptions = DMT_XSell.getGeographyOptions('TEST-ENT');
        
        // 2. Test with blank entity code (Hits DMT_Taxonomy_Values__c fallback)
        List<Map<String, String>> fallbackOptions = DMT_XSell.getGeographyOptions('');
        Test.stopTest();

        Assert.isFalse(relationshipOptions.isEmpty(), 'Should return mapped taxonomy relationships based on entity code.');
        Assert.areEqual('TEST-ENT-ES', relationshipOptions[0].get('value'), 'Should map value from final taxonomy.');
        Assert.areEqual('TEST LABEL EN', relationshipOptions[0].get('label'), 'Should map label from final taxonomy.');
        
        Assert.isFalse(fallbackOptions.isEmpty(), 'Should return standard H007 fallback options when entity code is blank.');
    }

    /**
     * TEST 6: Deduplication Guardrail #1 (Before Upsert)
     * Validates that duplicate records with identical field values are skipped before insert.
     */
    @isTest
    static void testDeduplicationAgainstDatabase() {
        // Query the setup Opp to avoid factory duplication errors
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Create a test record with specific values (Using IT/PT to avoid colliding with ES/US setup data)
        DMT_X_Sell__c existingRecord = new DMT_X_Sell__c(
            Opportunity__c = opp.Id,
            Booking_Geography__c = 'IT',
            XSELL_Value_PY__c = 500,
            XSELL_Value_CY__c = 510,
            XSELL_Value_NY__c = 520,
            XSELL_Value_NY1__c = 530
        );
        insert existingRecord;

        // Verify the record exists (Counting just 'IT' to isolate from setup data)
        Integer countBefore = [SELECT COUNT() FROM DMT_X_Sell__c WHERE Opportunity__c = :opp.Id AND Booking_Geography__c = 'IT'];
        Assert.areEqual(1, countBefore, 'Should have exactly 1 IT record before save');

        // Try to save 2 records:
        // 1. DUPLICATE of existing (IT with same values) - should be filtered out
        // 2. NEW record with different values (PT) - should be inserted
        List<DMT_X_Sell__c> recordsToSave = new List<DMT_X_Sell__c>();
        recordsToSave.add(new DMT_X_Sell__c(
            Opportunity__c = opp.Id,
            Booking_Geography__c = 'IT',
            XSELL_Value_PY__c = 500,
            XSELL_Value_CY__c = 510,
            XSELL_Value_NY__c = 520,
            XSELL_Value_NY1__c = 530
        ));
        recordsToSave.add(new DMT_X_Sell__c(
            Opportunity__c = opp.Id,
            Booking_Geography__c = 'PT',
            XSELL_Value_PY__c = 600,
            XSELL_Value_CY__c = 610,
            XSELL_Value_NY__c = 620,
            XSELL_Value_NY1__c = 630
        ));

        Test.startTest();
        DMT_XSell.saveXSellRecords(recordsToSave, null);
        Test.stopTest();

        // Verify: Should have 1 IT (existing, duplicate filtered) + 1 PT (new)
        Integer countIT = [SELECT COUNT() FROM DMT_X_Sell__c WHERE Opportunity__c = :opp.Id AND Booking_Geography__c = 'IT'];
        Integer countPT = [SELECT COUNT() FROM DMT_X_Sell__c WHERE Opportunity__c = :opp.Id AND Booking_Geography__c = 'PT'];
        
        Assert.areEqual(1, countIT, 'Should keep only 1 IT record. Duplicate was successfully filtered.');
        Assert.areEqual(1, countPT, 'Should have exactly 1 new PT record.');
    }

    /**
     * TEST 7: Deduplication Guardrail #2 (After Upsert Cleanup)
     * Validates that any remaining duplicates are cleaned up after save.
     * Simulates the edge case where the same PubSub event triggers multiple saves.
     */
    @isTest
    static void testDeduplicateXSellRecords() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Manually create 3 identical duplicate records to simulate repeated PubSub saves
        List<DMT_X_Sell__c> duplicates = new List<DMT_X_Sell__c>();
        duplicates.add(new DMT_X_Sell__c(
            Opportunity__c = opp.Id,
            Booking_Geography__c = 'CH',
            XSELL_Value_PY__c = 1000,
            XSELL_Value_CY__c = 1010,
            XSELL_Value_NY__c = 1020,
            XSELL_Value_NY1__c = 1030
        ));
        duplicates.add(new DMT_X_Sell__c(
            Opportunity__c = opp.Id,
            Booking_Geography__c = 'CH',
            XSELL_Value_PY__c = 1000,
            XSELL_Value_CY__c = 1010,
            XSELL_Value_NY__c = 1020,
            XSELL_Value_NY1__c = 1030
        ));
        duplicates.add(new DMT_X_Sell__c(
            Opportunity__c = opp.Id,
            Booking_Geography__c = 'CH',
            XSELL_Value_PY__c = 1000,
            XSELL_Value_CY__c = 1010,
            XSELL_Value_NY__c = 1020,
            XSELL_Value_NY1__c = 1030
        ));
        insert duplicates;

        // Verify we have 3 identical records for this opportunity/geography combo
        Integer countBeforeCleanup = [SELECT COUNT() FROM DMT_X_Sell__c WHERE Opportunity__c = :opp.Id AND Booking_Geography__c = 'CH'];
        Assert.areEqual(3, countBeforeCleanup, 'Setup: Should have 3 identical CH records before cleanup');

        // Trigger a save with one identical record to activate the deduplication cleanup
        List<DMT_X_Sell__c> triggerRecord = new List<DMT_X_Sell__c>();
        triggerRecord.add(new DMT_X_Sell__c(
            Opportunity__c = opp.Id,
            Booking_Geography__c = 'CH',
            XSELL_Value_PY__c = 1000,
            XSELL_Value_CY__c = 1010,
            XSELL_Value_NY__c = 1020,
            XSELL_Value_NY1__c = 1030
        ));

        Test.startTest();
        DMT_XSell.saveXSellRecords(triggerRecord, null);
        Test.stopTest();

        // After deduplication cleanup, should keep ONLY the oldest (first inserted)
        Integer countAfterCleanup = [SELECT COUNT() FROM DMT_X_Sell__c WHERE Opportunity__c = :opp.Id AND Booking_Geography__c = 'CH'];
        Assert.areEqual(1, countAfterCleanup, 'After cleanup: Should keep only 1 oldest record (CH), delete the 3 newer duplicates.');
    }
}