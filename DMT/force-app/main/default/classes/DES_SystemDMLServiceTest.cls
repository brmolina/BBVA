/**
 * @description Test class for DES_SystemDMLService.
 *              Each DML method (delete, insert, update) gets an individual test for its
 *              main path. No-op paths (null/empty list) are grouped in a single method
 *              per operation since they share the same simple guard logic.
 * @author      Borja Lorenzo Adajas
 * @date        2026-05-21
 */
@IsTest(testFor='ApexClass:DES_SystemDMLService')
private class DES_SystemDMLServiceTest {

    // ──────────────────────────────────────────────────────────────────────────
    // Test data setup
    // ──────────────────────────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        final DES_UtilTestClass util = new DES_UtilTestClass();
        final Account acc = util.createClient();
        insert acc;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // deleteRecords
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void deleteRecords_withRecords_deletesSuccessfully() {
        // deleteRecords — lista con registros
        final List<Account> accounts = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        DES_SystemDMLService.deleteRecords(accounts);
        Test.stopTest();

        final Integer remaining = [SELECT COUNT() FROM Account WHERE Id = :accounts[0].Id];
        System.assertEquals(0, remaining, 'Record should have been deleted successfully');
    }

    @IsTest
    static void deleteRecords_noOp_nullAndEmptyList() {
        // deleteRecords — lista vacía y null no deben lanzar excepción
        Test.startTest();
        DES_SystemDMLService.deleteRecords(new List<SObject>());
        DES_SystemDMLService.deleteRecords(null);
        Test.stopTest();

        final Integer remaining = [SELECT COUNT() FROM Account];
        System.assertEquals(1, remaining, 'No records should be deleted when passing null or empty list');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // insertRecords
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void insertRecords_withRecords_insertsSuccessfully() {
        // insertRecords — lista con registros
        final DES_UtilTestClass util = new DES_UtilTestClass();
        final Account newAcc = util.createClient();
        newAcc.Name = 'Insert Test Account';

        Test.startTest();
        DES_SystemDMLService.insertRecords(new List<SObject>{ newAcc });
        Test.stopTest();

        final List<Account> inserted = [SELECT Id FROM Account WHERE Name = 'Insert Test Account'];
        System.assertEquals(1, inserted.size(), 'Record should have been inserted successfully');
    }

    @IsTest
    static void insertRecords_noOp_nullAndEmptyList() {
        // insertRecords — lista vacía y null no deben lanzar excepción
        final Integer countBefore = [SELECT COUNT() FROM Account];

        Test.startTest();
        DES_SystemDMLService.insertRecords(new List<SObject>());
        DES_SystemDMLService.insertRecords(null);
        Test.stopTest();

        final Integer countAfter = [SELECT COUNT() FROM Account];
        System.assertEquals(countBefore, countAfter, 'No records should be inserted when passing null or empty list');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // updateRecords
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void updateRecords_withRecords_updatesSuccessfully() {
        // updateRecords — lista con registros
        final Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        acc.Name = 'Updated Name';

        Test.startTest();
        DES_SystemDMLService.updateRecords(new List<SObject>{ acc });
        Test.stopTest();

        final Account updated = [SELECT Name FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Updated Name', updated.Name, 'Record name should have been updated successfully');
    }

    @IsTest
    static void updateRecords_noOp_nullAndEmptyList() {
        // updateRecords — lista vacía y null no deben lanzar excepción
        final Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        final String originalName = acc.Name;

        Test.startTest();
        DES_SystemDMLService.updateRecords(new List<SObject>());
        DES_SystemDMLService.updateRecords(null);
        Test.stopTest();

        final Account unchanged = [SELECT Name FROM Account WHERE Id = :acc.Id];
        System.assertEquals(originalName, unchanged.Name, 'Record should not be modified when passing null or empty list');
    }
}