@IsTest
public with sharing class DMT_Client_Selector_Test {

    @TestSetup
    static void setup() {
        DMT_Test_DataFactory.generateTestTreasuryLines();

        Account testAccount = [
            SELECT Id, DES_Group_Code__c
            FROM Account
            WHERE Name = 'Test company 1'
            LIMIT 1
        ];

        // Necesario para probar getStructureTypeByGroupCode
        // y la primera rama de getAccountRecordCode.
        if (String.isBlank(testAccount.DES_Group_Code__c)) {
            testAccount.DES_Group_Code__c = 'TEST_GROUP_CODE';
            update testAccount;
        }
    }

    @IsTest
    static void testSearchClient() {
        Account testAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test company 1'
            LIMIT 1
        ];

        // Los resultados SOSL deben fijarse expresamente en los tests.
        Test.setFixedSearchResults(new Id[] { testAccount.Id });

        Test.startTest();
        List<Account> clients =
            DMT_Client_Selector.searchClient('Test');
        Test.stopTest();

        System.assertEquals(
            1,
            clients.size(),
            'Debe devolver la cuenta configurada para el resultado SOSL'
        );

        System.assertEquals(
            testAccount.Id,
            clients[0].Id,
            'Debe devolver la cuenta esperada'
        );
    }

    @IsTest
    static void testSearchClientBlank() {
        Test.startTest();
        List<Account> clients =
            DMT_Client_Selector.searchClient('');
        Test.stopTest();

        System.assertEquals(
            0,
            clients.size(),
            'No debe devolver cuentas si el término está vacío'
        );
    }

    @IsTest
    static void testGetAccountById() {
        Account testAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test company 1'
            LIMIT 1
        ];

        Test.startTest();
        Account result =
            DMT_Client_Selector.getAccountById(testAccount.Id);
        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'Debe devolver una cuenta'
        );

        System.assertEquals(
            testAccount.Id,
            result.Id,
            'Debe devolver la cuenta solicitada'
        );
    }

    @IsTest
    static void testGetStructureTypeByGroupCode() {
        Account testAccount = [
            SELECT Id, DES_Group_Code__c
            FROM Account
            WHERE Name = 'Test company 1'
            LIMIT 1
        ];

        Test.startTest();
        Account result =
            DMT_Client_Selector.getStructureTypeByGroupCode(
                testAccount.DES_Group_Code__c
            );
        Test.stopTest();

        System.assertEquals(
            testAccount.Id,
            result.Id,
            'Debe devolver la cuenta correspondiente al código de grupo'
        );
    }

    @IsTest
    static void testGetAccountRecordCodeWithGroupCode() {
        Account testAccount = [
            SELECT Id, DES_Group_Code__c
            FROM Account
            WHERE Name = 'Test company 1'
            LIMIT 1
        ];

        Test.startTest();
        String recordCode =
            DMT_Client_Selector.getAccountRecordCode(testAccount.Id);
        Test.stopTest();

        System.assertEquals(
            testAccount.DES_Group_Code__c,
            recordCode,
            'Debe devolver el código de grupo de la cuenta'
        );
    }
}