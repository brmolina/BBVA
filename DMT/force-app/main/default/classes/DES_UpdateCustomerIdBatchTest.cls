/**
 * @description Test class for DES_UpdateCustomerIdBatch.
 *
 *              Covered scenarios:
 *                1. Batch recomputes g_customer_id__c when it was cleared (direct country).
 *                2. Batch derives country from parent account via participant_id__c.
 *                3. Batch leaves an already-correct value untouched.
 *                4. Batch falls back to the owner's ISO-3 DES_Country__c field.
 *                5. Batch skips the record when no country source is available.
 *
 * @author      Global Desktop
 * @date        2026-06-01
 */
@IsTest
private class DES_UpdateCustomerIdBatchTest {

    private static final Id SUBSIDIARY_RT_ID = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();

    private static final Id GROUP_RT_ID = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();

    // ─────────────────────────────────────────────────────────────────────────
    // Helper
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Builds (but does not insert) a user with the given ISO-3 country.
     * DES_Country__c may be null to simulate an owner without a country.
     * Uses the two-parameter createUser variant (same pattern as DES_ProspectServiceTest)
     * to avoid the Desktop_Utils dependency present in the single-parameter overload.
     */
    private static User buildUser(String iso3Country) {
        final DES_UtilTestClass util = new DES_UtilTestClass();
        String suffix = (iso3Country != null ? iso3Country.toLowerCase() : 'nocountry')
                        + '@desupdatebatch.test';
        User u = util.createUser(util.createProfile(), suffix);
        u.DES_Country__c = iso3Country;
        return u;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Batch recomputes g_customer_id__c from a direct country after it was cleared
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testBatch_updatesCustomerId_whenDirectCountryAndValueCleared() {
        Account sub = new Account(
            Name                             = 'UT Sub Direct Country',
            RecordTypeId                     = SUBSIDIARY_RT_ID,
            DES_Country_of_Management_OLD__c = 'ES',
            DES_ID_Fiscal__c                 = 'UT-FISCAL-001'
        );
        insert sub;

        // Read the AutoNumber sequence that was assigned on insert.
        sub = [SELECT Id, DES_Sequence__c FROM Account WHERE Id = :sub.Id];
        String expectedId = 'ES' + 'P' + sub.DES_Sequence__c;   // e.g. 'ESP0000000001'

        // Corrupt g_customer_id__c without changing the country.
        // The Before-Update trigger condition requires the country to have CHANGED before
        // it resets g_customer_id__c, so this update leaves it null.
        update new Account(Id = sub.Id, g_customer_id__c = null);

        Test.startTest();
        Database.executeBatch(new DES_UpdateCustomerIdBatch(), 200);
        Test.stopTest();

        Account result = [SELECT g_customer_id__c FROM Account WHERE Id = :sub.Id];
        System.assertEquals(
            expectedId,
            result.g_customer_id__c,
            'Batch must recompute g_customer_id__c using the ES entific prefix and the account sequence'
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Batch derives country from parent account via participant_id__c
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testBatch_updatesCustomerId_whenCountryInheritedFromParent() {
        // Insert parent WITHOUT a country so the Before-Insert trigger
        // (populateProspectSubsidiaryCountryFromParent) cannot copy it to the subsidiary.
        Account parent = new Account(
            Name             = 'UT Parent Group',
            RecordTypeId     = GROUP_RT_ID,
            DES_ID_Fiscal__c = 'UT-FISCAL-010'
        );
        insert parent;

        Account sub = new Account(
            Name              = 'UT Sub Inherits Country',
            RecordTypeId      = SUBSIDIARY_RT_ID,
            participant_id__c = parent.Id,
            DES_ID_Fiscal__c  = 'UT-FISCAL-011'
            // DES_Country_of_Management_OLD__c intentionally blank
        );
        insert sub;

        // Verify the subsidiary has no g_customer_id__c yet (no country at insert time).
        sub = [SELECT Id, DES_Sequence__c, g_customer_id__c FROM Account WHERE Id = :sub.Id];
        System.assertEquals(
            null,
            sub.g_customer_id__c,
            'g_customer_id__c should be null before the batch runs'
        );

        // Now give the parent a country.  The subsidiary trigger will NOT fire for this,
        // so the subsidiary's g_customer_id__c stays null.
        update new Account(Id = parent.Id, DES_Country_of_Management_OLD__c = 'MX');

        String expectedId = 'MX' + 'P' + sub.DES_Sequence__c;

        Test.startTest();
        Database.executeBatch(new DES_UpdateCustomerIdBatch(), 200);
        Test.stopTest();

        Account result = [SELECT g_customer_id__c FROM Account WHERE Id = :sub.Id];
        System.assertEquals(
            expectedId,
            result.g_customer_id__c,
            'Batch must inherit country MX from the parent account and compute g_customer_id__c'
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Batch leaves an already-correct value untouched
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testBatch_preservesCustomerId_whenAlreadyCorrect() {
        Account sub = new Account(
            Name                             = 'UT Sub Already Correct',
            RecordTypeId                     = SUBSIDIARY_RT_ID,
            DES_Country_of_Management_OLD__c = 'ES',
            DES_ID_Fiscal__c                 = 'UT-FISCAL-020'
        );
        insert sub;

        // The After-Insert trigger should have set g_customer_id__c correctly already.
        sub = [SELECT Id, DES_Sequence__c, g_customer_id__c FROM Account WHERE Id = :sub.Id];
        String valueBeforeBatch = sub.g_customer_id__c;

        Test.startTest();
        Database.executeBatch(new DES_UpdateCustomerIdBatch(), 200);
        Test.stopTest();

        Account result = [SELECT g_customer_id__c FROM Account WHERE Id = :sub.Id];
        System.assertEquals(
            valueBeforeBatch,
            result.g_customer_id__c,
            'Batch must not alter a g_customer_id__c that is already correct'
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. Batch falls back to the account owner's ISO-3 DES_Country__c
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testBatch_updatesCustomerId_whenOwnerIso3CountryFallback() {
        // ESP (ISO-3) → ES (ISO-2) → entific ES0182 → prefix ES
        User testUser = buildUser('ESP');
        insert testUser;

        Account sub;
        System.runAs(testUser) {
            sub = new Account(
                Name             = 'UT Sub Owner Fallback',
                RecordTypeId     = SUBSIDIARY_RT_ID,
                DES_ID_Fiscal__c = 'UT-FISCAL-030'
                // No DES_Country_of_Management_OLD__c, no participant_id__c
            );
            insert sub;
        }

        // No country on the account → trigger skips → g_customer_id__c still null.
        sub = [SELECT Id, DES_Sequence__c FROM Account WHERE Id = :sub.Id];
        String expectedId = 'ES' + 'P' + sub.DES_Sequence__c;

        Test.startTest();
        Database.executeBatch(new DES_UpdateCustomerIdBatch(), 200);
        Test.stopTest();

        Account result = [SELECT g_customer_id__c FROM Account WHERE Id = :sub.Id];
        System.assertEquals(
            expectedId,
            result.g_customer_id__c,
            'Batch must derive country from owner DES_Country__c=ESP → ISO-2 ES → prefix ES'
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5. Batch skips the record when no country source is available
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testBatch_skipsAccount_whenNoCountryAvailable() {
        // Owner with no DES_Country__c, account with no country and no parent.
        User testUser = buildUser(null);
        insert testUser;

        Account sub;
        System.runAs(testUser) {
            sub = new Account(
                Name             = 'UT Sub No Country',
                RecordTypeId     = SUBSIDIARY_RT_ID,
                DES_ID_Fiscal__c = 'UT-FISCAL-040'
            );
            insert sub;
        }

        Test.startTest();
        Database.executeBatch(new DES_UpdateCustomerIdBatch(), 200);
        Test.stopTest();

        Account result = [SELECT g_customer_id__c FROM Account WHERE Id = :sub.Id];
        System.assertEquals(
            null,
            result.g_customer_id__c,
            'Batch must leave g_customer_id__c null when no country can be resolved'
        );
    }
}