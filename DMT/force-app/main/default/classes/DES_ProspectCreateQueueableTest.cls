/**
 * @description Test class for DES_ProspectCreateQueueable.
 *              The callout is always mocked to 201 OK in test context (via Test.isRunningTest()
 *              in DES_Arc_ProspectController.callCreateProspect). The chaining test uses 2 records
 *              to trigger the overflow path; the chained job itself does not execute synchronously,
 *              so only the first record is asserted to be updated.
 * @author      Borja Lorenzo Adajas
 * @date        2026-05-21
 */
@IsTest(testFor='ApexClass:DES_ProspectCreateQueueable')
private class DES_ProspectCreateQueueableTest {

    // ──────────────────────────────────────────────────────────────────────────
    // Test data setup
    // ──────────────────────────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        final DES_UtilTestClass util = new DES_UtilTestClass();
        final Account acc = util.createClient();
        acc.gf_customer_prospect_id__c = 'TEST_PROSPECT_001';
        acc.DES_ID_Fiscal__c = 'B12345678';
        insert acc;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // execute
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void execute_toUpdateTrue_setsProspectCreatedStatus() {
        // execute — toUpdate=true, callout returns 201 → DES_Prospect_status__c is set
        // Arrange
        final Account acc = [
            SELECT Id, Name, DES_ID_Fiscal__c, gf_customer_prospect_id__c, DES_Prospect_status__c
            FROM Account LIMIT 1
        ];
        final List<DES_Arc_ProspectController.WrapperService> wraps =
            new List<DES_Arc_ProspectController.WrapperService>{
                new DES_Arc_ProspectController.WrapperService(acc, '', true)
            };

        // Act
        Test.startTest();
        System.enqueueJob(new DES_ProspectCreateQueueable(wraps));
        Test.stopTest();

        // Assert
        final Account updated = [SELECT DES_Prospect_status__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(
            Label.Prospect_created,
            updated.DES_Prospect_status__c,
            'Prospect status should be set to Prospect_created when callout succeeds and toUpdate is true'
        );
    }

    @IsTest
    static void execute_toUpdateFalse_doesNotSetStatus() {
        // execute — toUpdate=false → status must not change even when callout succeeds
        // Arrange
        final Account acc = [
            SELECT Id, Name, DES_ID_Fiscal__c, gf_customer_prospect_id__c, DES_Prospect_status__c
            FROM Account LIMIT 1
        ];
        final List<DES_Arc_ProspectController.WrapperService> wraps =
            new List<DES_Arc_ProspectController.WrapperService>{
                new DES_Arc_ProspectController.WrapperService(acc, '', false)
            };

        // Act
        Test.startTest();
        System.enqueueJob(new DES_ProspectCreateQueueable(wraps));
        Test.stopTest();

        // Assert
        final Account unchanged = [SELECT DES_Prospect_status__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(
            null,
            unchanged.DES_Prospect_status__c,
            'Prospect status should not be set when toUpdate is false'
        );
    }

    @IsTest
    static void execute_emptyWrapList_noExceptionThrown() {
        // execute — empty wrap list should complete without exception or side effects
        // Act
        Test.startTest();
        System.enqueueJob(new DES_ProspectCreateQueueable(
            new List<DES_Arc_ProspectController.WrapperService>()
        ));
        Test.stopTest();

        // Assert
        final Account unchanged = [SELECT DES_Prospect_status__c FROM Account LIMIT 1];
        System.assertEquals(
            null,
            unchanged.DES_Prospect_status__c,
            'No account should be modified when the wrap list is empty'
        );
    }

    @IsTest
    static void execute_overBatchSize_chainsRemainingRecords() {
        // execute — 2 wraps (> BATCH_SIZE=1): first record is processed, 2nd is deferred
        //           to a chained job that does not execute synchronously in test context.
        // Arrange
        final DES_UtilTestClass util = new DES_UtilTestClass();
        final Account acc2 = util.createClient();
        acc2.Name = 'Chain Prospect 2';
        acc2.gf_customer_prospect_id__c = 'CHAIN_002';
        acc2.DES_ID_Fiscal__c = 'B10000002';
        insert acc2;

        final List<Account> allAccounts = [
            SELECT Id, Name, DES_ID_Fiscal__c, gf_customer_prospect_id__c, DES_Prospect_status__c
            FROM Account
        ];
        System.assertEquals(2, allAccounts.size(), 'There should be exactly 2 accounts for this test');

        final List<DES_Arc_ProspectController.WrapperService> wraps =
            new List<DES_Arc_ProspectController.WrapperService>();
        for (Account a : allAccounts) {
            wraps.add(new DES_Arc_ProspectController.WrapperService(a, '', true));
        }

        // Act
        Test.startTest();
        System.enqueueJob(new DES_ProspectCreateQueueable(wraps));
        Test.stopTest();

        // Assert — first record processed; 2nd deferred to chained job (not executed in test)
        final Integer processedCount = [
            SELECT COUNT()
            FROM Account
            WHERE DES_Prospect_status__c = :Label.Prospect_created
        ];
        System.assertEquals(
            1,
            processedCount,
            'Exactly 1 account should be updated in the first execution'
        );

        final Integer deferredCount = [
            SELECT COUNT()
            FROM Account
            WHERE DES_Prospect_status__c = null
        ];
        System.assertEquals(
            1,
            deferredCount,
            'The second account should remain unprocessed until the chained job runs'
        );
    }
}