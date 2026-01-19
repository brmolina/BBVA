@isTest
private class DMT_TableTenorsTest {

    @TestSetup
    static void setupData() {
        TriggerBypass.setBypass();
        // 1. Create Base Data using Factory
        // This creates Account, Opp, Product, PricebookEntry, and OpportunityLineItem
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(opp);

        // 2. Update OLI with specific dates for predictable testing
        oli.gf_initial_date__c = Date.today();
        oli.gf_maturity_date__c = Date.today().addDays(10);
        oli.g_currency_id__c = 'EUR';
        update oli;
    }

    /**
     * Scenario: Fetching data when Tenors already exist in the database.
     */
    @isTest
    static void testGetTenorsData_Existing() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        // Create a Tenor record via Factory
        DMT_Test_DataFactory.generateOpportunityTenor(oli);

        // Manually update the tenor to ensure it has valid data for the query
        DMT_Opportunity_Tenor__c tenor = [SELECT Id FROM DMT_Opportunity_Tenor__c LIMIT 1];
        tenor.gf_tenor_date__c = Date.today();
        tenor.gj_nominal_amount_db__c = 1000;
        update tenor;

        Test.startTest();
        DMT_TableTenors.TenorInitData result = DMT_TableTenors.getTenorsData(oli.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.tenors, 'Tenors list should not be null');
        System.assertEquals(1, result.tenors.size(), 'Should return 1 existing tenor');
        System.assertEquals(1000, result.tenors[0].gj_nominal_amount_db__c, 'Amount should match DB value');
    }

    /**
     * Scenario: Fetching data when NO Tenors exist.
     * Expected: Apex should generate 2 Placeholder rows (Start Date and Maturity Date).
     */
    @isTest
    static void testGetTenorsData_Placeholders() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        // Ensure no tenors exist (TestSetup created OLI but not Tenors by default in that method)
        delete [SELECT Id FROM DMT_Opportunity_Tenor__c];

        Test.startTest();
        DMT_TableTenors.TenorInitData result = DMT_TableTenors.getTenorsData(oli.Id);
        Test.stopTest();

        System.assertEquals(2, result.tenors.size(), 'Should generate 2 placeholders (Start & End)');

        // Verify Start Row
        System.assertEquals(Date.today(), result.tenors[0].gf_tenor_date__c, 'First row should be Init Date');

        // Verify End Row
        System.assertEquals(Date.today().addDays(10), result.tenors[1].gf_tenor_date__c, 'Last row should be Maturity Date');
        System.assertEquals(0, result.tenors[1].gj_nominal_amount_db__c, 'Placeholder amount should be 0');
    }

    /**
     * Scenario: Saving Data (Sync)
     * 1. Updates an existing record (by Date).
     * 2. Inserts a new record.
     * 3. Deletes a missing record (implied by absence in payload).
     */
    @isTest
    static void testSyncTenors_UpsertAndDelete() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        // 1. Prepare Initial Data in DB
        DMT_Opportunity_Tenor__c t1 = new DMT_Opportunity_Tenor__c(
            DMT_Opportunity_Product__c = oli.Id,
            gf_tenor_date__c = Date.today(),
            gj_nominal_amount_db__c = 500
        );
        DMT_Opportunity_Tenor__c t2_toDelete = new DMT_Opportunity_Tenor__c(
            DMT_Opportunity_Product__c = oli.Id,
            gf_tenor_date__c = Date.today().addDays(1),
            gj_nominal_amount_db__c = 100
        );
        insert new List<DMT_Opportunity_Tenor__c>{t1, t2_toDelete};

        // 2. Prepare JSON Payload
        // - Row 1: Update t1 (Change Amount to 900)
        // - Row 2: Insert New (Date + 5)
        // - Row t2_toDelete is MISSING from payload, so it should be deleted.

        List<Map<String, Object>> tenorRows = new List<Map<String, Object>>();

        // Update Row
        Map<String, Object> row1 = new Map<String, Object>();
        row1.put('gf_tenor_date__c', String.valueOf(Date.today())); // Matches t1 date
        row1.put('gj_nominal_amount_db__c', 900);
        tenorRows.add(row1);

        // New Row
        Map<String, Object> rowNew = new Map<String, Object>();
        rowNew.put('gf_tenor_date__c', String.valueOf(Date.today().addDays(5)));
        rowNew.put('gj_nominal_amount_db__c', 2000);
        tenorRows.add(rowNew);

        Map<String, Object> payloadMap = new Map<String, Object>();
        payloadMap.put('oppLineItemId', oli.Id);
        payloadMap.put('tenorData', tenorRows);

        String jsonPayload = JSON.serialize(payloadMap);

        Test.startTest();
        String resultJson = DMT_TableTenors.syncTenors(jsonPayload);
        Test.stopTest();

        // 3. Assertions
        List<DMT_Opportunity_Tenor__c> finalTenors = [SELECT Id, gf_tenor_date__c, gj_nominal_amount_db__c FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c = :oli.Id ORDER BY gf_tenor_date__c];

        System.assertEquals(2, finalTenors.size(), 'Should have 2 records (1 updated, 1 new, 1 deleted)');

        // Assert Update
        System.assertEquals(900, finalTenors[0].gj_nominal_amount_db__c, 'Row 1 should be updated to 900');

        // Assert Insert
        System.assertEquals(2000, finalTenors[1].gj_nominal_amount_db__c, 'Row 2 should be inserted with 2000');

        // Assert Delete
        // Since t2_toDelete had date Today+1, and our list has Today and Today+5, T2 is gone.
    }

    /**
     * Scenario: Read Only Check via Opportunity Team Member
     */
    @isTest
    static void testCalculateReadOnlyStatus_TeamMember() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        User u = DMT_Test_DataFactory.generateUserWithoutPermissions();

        // Create Team Member with READ access
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.OpportunityId = opp.Id;
        otm.UserId = u.Id;
        otm.TeamMemberRole = 'Account Manager';
        otm.OpportunityAccessLevel = 'Read'; // Enforcing Read Only
        insert otm;

        System.runAs(u) {
            Test.startTest();
            Boolean isReadOnly = DMT_TableTenors.calculateReadOnlyStatus(opp.Id);
            Test.stopTest();

            System.assertEquals(true, isReadOnly, 'User with Read access on Team should be ReadOnly');
        }
    }

    @isTest
    static void testErrorHandling() {
        Test.startTest();
        try {
            DMT_TableTenors.getTenorsData('InvalidId');
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(true);
        }

        try {
            DMT_TableTenors.syncTenors('{"invalid": "json"');
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }
}