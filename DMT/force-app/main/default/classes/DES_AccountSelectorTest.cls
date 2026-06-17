/**
 * @description Test class for DES_AccountSelector.
 * @author      Borja Lorenzo Adajas
 * @date        2026-05-21
 */
@IsTest(testFor='ApexClass:DES_AccountSelector')
private class DES_AccountSelectorTest {

    // ──────────────────────────────────────────────────────────────────────────
    // Test data setup
    // ──────────────────────────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        final DES_UtilTestClass util = new DES_UtilTestClass();

        final Account acc1 = util.createClient();
        acc1.Name = 'Selector Test Account 1';
        acc1.DES_ID_Fiscal__c = 'B11111111';
        acc1.gf_customer_prospect_id__c = 'SELECTOR_001';

        final Account acc2 = util.createClient();
        acc2.Name = 'Selector Test Account 2';
        acc2.DES_ID_Fiscal__c = 'B22222222';
        acc2.gf_customer_prospect_id__c = 'SELECTOR_002';

        insert new List<Account>{ acc1, acc2 };
    }

    // ──────────────────────────────────────────────────────────────────────────
    // getByIds
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void getByIds_matchingIds_returnsAllAccounts() {
        // getByIds — all ids match existing records → all are returned
        // Arrange
        final List<Id> ids = new List<Id>(
            new Map<Id, Account>([SELECT Id FROM Account]).keySet()
        );

        // Act
        Test.startTest();
        final List<Account> result = DES_AccountSelector.getByIds(ids);
        Test.stopTest();

        // Assert
        System.assertEquals(ids.size(), result.size(), 'All matching accounts should be returned');
    }

    @IsTest
    static void getByIds_partialMatch_returnsOnlyMatchingAccounts() {
        // getByIds — only one of the two accounts is queried → single record returned
        // Arrange
        final Account acc = [SELECT Id FROM Account LIMIT 1];
        final List<Id> ids = new List<Id>{ acc.Id };

        // Act
        Test.startTest();
        final List<Account> result = DES_AccountSelector.getByIds(ids);
        Test.stopTest();

        // Assert
        System.assertEquals(1, result.size(), 'Only the queried account should be returned');
        System.assertEquals(acc.Id, result[0].Id, 'The returned account Id should match the queried Id');
    }

    @IsTest
    static void getByIds_emptyList_returnsEmptyList() {
        // getByIds — empty input list → empty result, no exception
        // Arrange
        final List<Id> ids = new List<Id>();

        // Act
        Test.startTest();
        final List<Account> result = DES_AccountSelector.getByIds(ids);
        Test.stopTest();

        // Assert
        System.assertEquals(0, result.size(), 'An empty id list should return no records');
    }

    @IsTest
    static void getByIds_unknownIds_returnsEmptyList() {
        // getByIds — ids that do not correspond to any account → empty result
        // Arrange
        final List<Id> ids = new List<Id>{ '001000000000000AAA' };

        // Act
        Test.startTest();
        final List<Account> result = DES_AccountSelector.getByIds(ids);
        Test.stopTest();

        // Assert
        System.assertEquals(0, result.size(), 'Non-existent ids should return no records');
    }
}