@isTest
private without sharing class DMT_TableTenorsTest {

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

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isNotNull(result.tenors, 'Tenors list should not be null');
        Assert.areEqual(1, result.tenors.size(), 'Should return 1 existing tenor');
        Assert.areEqual(1000, result.tenors[0].gj_nominal_amount_db__c, 'Amount should match DB value');
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

        Assert.areEqual(2, result.tenors.size(), 'Should generate 2 placeholders (Start & End)');

        // Verify Start Row
        Assert.areEqual(Date.today(), result.tenors[0].gf_tenor_date__c, 'First row should be Init Date');

        // Verify End Row
        Assert.areEqual(Date.today().addDays(10), result.tenors[1].gf_tenor_date__c, 'Last row should be Maturity Date');
        Assert.areEqual(0, result.tenors[1].gj_nominal_amount_db__c, 'Placeholder amount should be 0');
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

        Assert.areEqual(2, finalTenors.size(), 'Should have 2 records (1 updated, 1 new, 1 deleted)');

        // Assert Update
        Assert.areEqual(900, finalTenors[0].gj_nominal_amount_db__c, 'Row 1 should be updated to 900');

        // Assert Insert
        Assert.areEqual(2000, finalTenors[1].gj_nominal_amount_db__c, 'Row 2 should be inserted with 2000');

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

            Assert.areEqual(true, isReadOnly, 'User with Read access on Team should be ReadOnly');
        }
    }

    /**
     * Fetching data should auto-clean duplicate rows (Same Date).
     */
    @isTest
    static void testGetTenorsData_DuplicateCleanup() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        // 1. Create First Record
        DMT_Opportunity_Tenor__c row1 = new DMT_Opportunity_Tenor__c(
            DMT_Opportunity_Product__c = oli.Id,
            gf_tenor_date__c = Date.today(),
            gj_nominal_amount_db__c = 5000
        );

        // 2. Create Second Record (Duplicate Date)
        DMT_Opportunity_Tenor__c row2 = new DMT_Opportunity_Tenor__c(
            DMT_Opportunity_Product__c = oli.Id,
            gf_tenor_date__c = Date.today(), // SAME DATE as Row 1
            gj_nominal_amount_db__c = 100
        );

        insert new List<DMT_Opportunity_Tenor__c>{row1, row2};

        Test.startTest();
        // This method should detect the duplicate date and delete one of them.
        DMT_TableTenors.TenorInitData result = DMT_TableTenors.getTenorsData(oli.Id);
        Test.stopTest();

        // Assertions
        Assert.areEqual(1, result.tenors.size(), 'Should return only 1 row (Duplicate deleted)');
        
        // Verify DB deletion
        Integer count = [SELECT COUNT() FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c = :oli.Id];
        Assert.areEqual(1, count, 'Database should be cleaned of duplicates');
    }

    /**
     * Fetching data for strict types (Linear/Bullet) should delete invalid middle rows.
     */
    @isTest
    static void testGetTenorsData_StrictStructureCleanup() {
        OpportunityLineItem oli = [SELECT Id, gf_initial_date__c, gf_maturity_date__c FROM OpportunityLineItem LIMIT 1];
        
        // 1. Set to strict structure
        oli.gf_amortization_type__c = 'Linear';
        update oli;

        // 2. Create Start, Middle, and End rows
        DMT_Opportunity_Tenor__c startRow = new DMT_Opportunity_Tenor__c(DMT_Opportunity_Product__c=oli.Id, gf_tenor_date__c=oli.gf_initial_date__c, gj_nominal_amount_db__c=10);
        DMT_Opportunity_Tenor__c midRow   = new DMT_Opportunity_Tenor__c(DMT_Opportunity_Product__c=oli.Id, gf_tenor_date__c=oli.gf_initial_date__c.addDays(5), gj_nominal_amount_db__c=10);
        DMT_Opportunity_Tenor__c endRow   = new DMT_Opportunity_Tenor__c(DMT_Opportunity_Product__c=oli.Id, gf_tenor_date__c=oli.gf_maturity_date__c, gj_nominal_amount_db__c=10);
        
        insert new List<DMT_Opportunity_Tenor__c>{startRow, midRow, endRow};

        Test.startTest();
        DMT_TableTenors.TenorInitData result = DMT_TableTenors.getTenorsData(oli.Id);
        Test.stopTest();

        // Assertions: Middle row should be gone
        Assert.areEqual(2, result.tenors.size(), 'Should only have Start and End rows for Linear');
        
        List<DMT_Opportunity_Tenor__c> dbTenors = [SELECT Id FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c = :oli.Id];
        Assert.areEqual(2, dbTenors.size(), 'Middle row should be deleted from DB');
    }

    /**
     * Syncing should deduplicate input payload (prevent inserting double rows).
     */
    @isTest
    static void testSyncTenors_DeduplicatePayload() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        // Prepare JSON Payload with 2 rows having the SAME DATE
        List<Map<String, Object>> tenorRows = new List<Map<String, Object>>();

        Map<String, Object> rowA = new Map<String, Object>();
        rowA.put('gf_tenor_date__c', String.valueOf(Date.today()));
        rowA.put('gj_nominal_amount_db__c', 100);
        tenorRows.add(rowA);

        Map<String, Object> rowB = new Map<String, Object>();
        rowB.put('gf_tenor_date__c', String.valueOf(Date.today())); // Duplicate Date
        rowB.put('gj_nominal_amount_db__c', 200);
        tenorRows.add(rowB);

        Map<String, Object> payloadMap = new Map<String, Object>();
        payloadMap.put('oppLineItemId', oli.Id);
        payloadMap.put('tenorData', tenorRows);

        Test.startTest();
        DMT_TableTenors.syncTenors(JSON.serialize(payloadMap));
        Test.stopTest();

        // Assertions
        List<DMT_Opportunity_Tenor__c> finalTenors = [SELECT Id, gj_nominal_amount_db__c FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c = :oli.Id];
        Assert.areEqual(1, finalTenors.size(), 'Should only save 1 record per date');
    }
}