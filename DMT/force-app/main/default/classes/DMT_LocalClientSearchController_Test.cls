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
        insert acc;

        Local_Client__c lc = new Local_Client__c(
             Name = 'Test company Search',
            Cib_Client__c = acc.Id,
            Alpha_code__c = 'ES123'
        );
        insert lc;
    }

    // ─── searchLocalClients ───────────────────────────────────────────

    @isTest
    static void testSearchByName_Positive() {
        Test.startTest();
        List<Local_Client__c> results = DMT_LocalClientSearchController.searchLocalClients('Test company', null);
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should return results searching by Name');
    }

    @isTest
    static void testSearchByAlphaCode_Positive() {
        Test.startTest();
        List<Local_Client__c> results = DMT_LocalClientSearchController.searchLocalClients('ES123', null);
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should return results searching by Alpha_code__c');
    }

    @isTest
    static void testSearchByFiscalId_Positive() {
        Test.startTest();
        List<Local_Client__c> results = DMT_LocalClientSearchController.searchLocalClients('B12345678', null);
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should return results searching by DES_ID_Fiscal__c');
    }

    @isTest
    static void testSearchWithEntityId_Positive() {
        Test.startTest();
        List<Local_Client__c> results = DMT_LocalClientSearchController.searchLocalClients('Test', 'ES123');
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should return results with entityId filter');
    }

    @isTest
    static void testSearchWithEntityId_NoMatch() {
        Test.startTest();
        List<Local_Client__c> results = DMT_LocalClientSearchController.searchLocalClients('Test', 'XX999');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return no results when entityId does not match');
    }

    @isTest
    static void testSearchNoResults_Positive() {
        Test.startTest();
        List<Local_Client__c> results = DMT_LocalClientSearchController.searchLocalClients('ZZZNOMATCH', null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list when no match');
    }

    @isTest
    static void testSearchWithNullEntityId_Positive() {
        Test.startTest();
        List<Local_Client__c> results = DMT_LocalClientSearchController.searchLocalClients('Test', 'null');
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should work when entityId is string null');
    }

    @isTest
    static void testSearchWithUndefinedEntityId_Positive() {
        Test.startTest();
        List<Local_Client__c> results = DMT_LocalClientSearchController.searchLocalClients('Test', 'undefined');
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should work when entityId is string undefined');
    }

    @isTest
    static void testSearchWithEmptyEntityId_Positive() {
        Test.startTest();
        List<Local_Client__c> results = DMT_LocalClientSearchController.searchLocalClients('Test', '');
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should work when entityId is empty string');
    }

    // ─── getLocalClientById ───────────────────────────────────────────

    @isTest
    static void testGetLocalClientById_Positive() {
        Local_Client__c lc = [SELECT Id FROM Local_Client__c LIMIT 1];

        Test.startTest();
        Local_Client__c result = DMT_LocalClientSearchController.getLocalClientById(lc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a record');
        System.assertEquals(lc.Id, result.Id, 'Should return the correct record');
    }

    @isTest
    static void testGetLocalClientById_Negative() {
        Test.startTest();
        try {
            Local_Client__c result = DMT_LocalClientSearchController.getLocalClientById('001000000000000AAA');
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage(), 'Should throw exception for non-existent Id');
        }
        Test.stopTest();
    }
}