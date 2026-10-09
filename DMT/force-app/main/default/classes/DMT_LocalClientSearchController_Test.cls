@isTest
public with sharing class DMT_LocalClientSearchController_Test {

    @TestSetup
    static void setupData() {
        Account acc = new Account();
        acc.account_client__c = 'N';
        acc.Advising__c = false;
        acc.BBVA_Entity__c = 'BBVA SA';
        acc.BillingCity = 'MADRID';
        acc.BillingCountry = 'ES';
        acc.BillingPostalCode = '28033';
        acc.BillingState = 'MADRID';
        acc.BillingStreet = 'AV GRAN Test DE HORTALEZA 0321';
        acc.CurrencyIsoCode = 'EUR';
        acc.DES_Activity__c = 'NDA';
        acc.Name = 'Test company Search';
        acc.DES_ID_Fiscal__c = 'B12345678';
        acc.g_customer_id__c = 'ES123';
        insert acc;
    }

    // ─── searchLocalClients ───────────────────────────────────────────

    @isTest
    static void testSearchByName_Positive() {
        Account account = [SELECT Id FROM Account WHERE g_customer_id__c = 'ES123' LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ account.Id });

        Test.startTest();
        List<Account> results = DMT_LocalClientSearchController.searchLocalClients('Test company', null);
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should return results searching by Name');
    }

    @isTest
    static void testSearchByAlphaCode_Positive() {
        Account account = [SELECT Id FROM Account WHERE g_customer_id__c = 'ES123' LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ account.Id });

        Test.startTest();
        List<Account> results = DMT_LocalClientSearchController.searchLocalClients('ES123', null);
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should return results searching by g_customer_id__c');
    }

    @isTest
    static void testSearchByFiscalId_Positive() {
        Account account = [SELECT Id FROM Account WHERE g_customer_id__c = 'ES123' LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ account.Id });

        Test.startTest();
        List<Account> results = DMT_LocalClientSearchController.searchLocalClients('B12345678', null);
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should return results searching by DES_ID_Fiscal__c');
    }

    @isTest
    static void testSearchWithEntityId_Positive() {
        Account account = [SELECT Id FROM Account WHERE g_customer_id__c = 'ES123' LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ account.Id });

        Test.startTest();
        List<Account> results = DMT_LocalClientSearchController.searchLocalClients('Test', 'ES123');
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should return results with entityId filter');
    }

    @isTest
    static void testSearchWithEntityId_NoMatch() {
        Account account = [SELECT Id FROM Account WHERE g_customer_id__c = 'ES123' LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ account.Id });

        Test.startTest();
        List<Account> results = DMT_LocalClientSearchController.searchLocalClients('Test', 'XX999');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return no results when entityId does not match');
    }

    @isTest
    static void testSearchNoResults_Positive() {
        Test.setFixedSearchResults(new List<Id>());

        Test.startTest();
        List<Account> results = DMT_LocalClientSearchController.searchLocalClients('ZZZNOMATCH', null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list when no match');
    }

    @isTest
    static void testSearchWithNullEntityId_Positive() {
        Account account = [SELECT Id FROM Account WHERE g_customer_id__c = 'ES123' LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ account.Id });

        Test.startTest();
        List<Account> results = DMT_LocalClientSearchController.searchLocalClients('Test', 'null');
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should work when entityId is string null');
    }

    @isTest
    static void testSearchWithUndefinedEntityId_Positive() {
        Account account = [SELECT Id FROM Account WHERE g_customer_id__c = 'ES123' LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ account.Id });

        Test.startTest();
        List<Account> results = DMT_LocalClientSearchController.searchLocalClients('Test', 'undefined');
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should work when entityId is string undefined');
    }

    @isTest
    static void testSearchWithEmptyEntityId_Positive() {
        Account account = [SELECT Id FROM Account WHERE g_customer_id__c = 'ES123' LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ account.Id });

        Test.startTest();
        List<Account> results = DMT_LocalClientSearchController.searchLocalClients('Test', '');
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should work when entityId is empty string');
    }

    // ─── getLocalClientById ───────────────────────────────────────────

    @isTest
    static void testGetLocalClientById_Positive() {
        Account account = [SELECT Id FROM Account WHERE g_customer_id__c = 'ES123' LIMIT 1];

        Test.startTest();
        Account result = DMT_LocalClientSearchController.getLocalClientById(account.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a record');
        System.assertEquals(account.Id, result.Id, 'Should return the correct record');
    }

    @isTest
    static void testGetLocalClientById_Negative() {
        Test.startTest();
        Account result = DMT_LocalClientSearchController.getLocalClientById('001000000000000AAA');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for a non-existent Account');
    }
}