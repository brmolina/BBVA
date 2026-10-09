@isTest
public with sharing class DMT_FinancialsNewController_Test {

    @TestSetup
    static void makeData() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        List<DMT_Opportunity_Business_Plan__c> records = new List<DMT_Opportunity_Business_Plan__c>();
        Integer currentYear = Date.today().year();

        // Financial record for Opportunity (GLOBAL)
        DMT_Opportunity_Business_Plan__c oppRec = new DMT_Opportunity_Business_Plan__c();
        oppRec.DMT_Opportunity__c = opp.Id;
        oppRec.DMT_Client__c = opp.AccountId;
        oppRec.DMT_Year__c = String.valueOf(currentYear);
        oppRec.DMT_Booking_Geography__c = 'GLOBAL';
        oppRec.DMT_Revenues_number__c = 1000;
        oppRec.DMT_EBITDA_number__c = 500;
        oppRec.DMT_EBIT_number__c = 300;
        oppRec.DMT_Net_Income_number__c = 200;
        oppRec.DMT_Free_Cash_Flow_number__c = 150;
        oppRec.DMT_Debt_EBITDA_number__c = 2.5;
        oppRec.DMT_Net_Debt_EBITDA_number__c = 1.8;
        records.add(oppRec);

        // Financial record for Client (GLOBAL) — separate record without Opportunity
        DMT_Opportunity_Business_Plan__c clientRec = new DMT_Opportunity_Business_Plan__c();
        clientRec.DMT_Client__c = opp.AccountId;
        clientRec.DMT_Year__c = String.valueOf(currentYear - 1);
        clientRec.DMT_Booking_Geography__c = 'GLOBAL';
        clientRec.DMT_Revenues_number__c = 900;
        clientRec.DMT_EBITDA_number__c = 450;
        records.add(clientRec);

        insert records;
    }

    @isTest
    static void testGetFinancialsByOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<DMT_Opportunity_Business_Plan__c> results =
            DMT_FinancialsNewController.getFinancialsByOpportunity(opp.Id);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return financial records for opportunity');
        System.assertEquals('GLOBAL', results[0].DMT_Booking_Geography__c, 'Should only return GLOBAL records');
        System.assertEquals(1000, results[0].DMT_Revenues_number__c, 'Revenues should match');
    }

    @isTest
    static void testGetFinancialsByClient() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<DMT_Opportunity_Business_Plan__c> results =
            DMT_FinancialsNewController.getFinancialsByClient(acc.Id);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return financial records for client');
        for (DMT_Opportunity_Business_Plan__c rec : results) {
            System.assertEquals('GLOBAL', rec.DMT_Booking_Geography__c, 'Should only return GLOBAL records');
        }
    }

    @isTest
    static void testGetFinancialsAccountComparison() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<DMT_Opportunity_Business_Plan__c> results =
            DMT_FinancialsNewController.getFinancialsAccountComparison(acc.Id);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return comparison records');
    }

    @isTest
    static void testSaveFinancials_Update() {
        DMT_Opportunity_Business_Plan__c existing = [
            SELECT Id, DMT_Revenues_number__c
            FROM DMT_Opportunity_Business_Plan__c
            WHERE DMT_Revenues_number__c = 1000
            LIMIT 1
        ];

        existing.DMT_Revenues_number__c = 2000;
        String jsonPayload = JSON.serialize(new List<DMT_Opportunity_Business_Plan__c>{ existing });

        Test.startTest();
        DMT_FinancialsNewController.saveFinancials(jsonPayload);
        Test.stopTest();

        DMT_Opportunity_Business_Plan__c updated = [
            SELECT DMT_Revenues_number__c FROM DMT_Opportunity_Business_Plan__c WHERE Id = :existing.Id
        ];
        System.assertEquals(2000, updated.DMT_Revenues_number__c, 'Revenue should be updated');
    }

    @isTest
    static void testSaveFinancials_Insert() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Integer nextYear = Date.today().year() + 1;

        DMT_Opportunity_Business_Plan__c newRec = new DMT_Opportunity_Business_Plan__c();
        newRec.DMT_Opportunity__c = opp.Id;
        newRec.DMT_Client__c = opp.AccountId;
        newRec.DMT_Year__c = String.valueOf(nextYear);
        newRec.DMT_Booking_Geography__c = 'GLOBAL';
        newRec.DMT_Revenues_number__c = 3000;
        newRec.DMT_EBITDA_number__c = 1500;

        String jsonPayload = JSON.serialize(new List<DMT_Opportunity_Business_Plan__c>{ newRec });

        Test.startTest();
        DMT_FinancialsNewController.saveFinancials(jsonPayload);
        Test.stopTest();

        List<DMT_Opportunity_Business_Plan__c> inserted = [
            SELECT DMT_Revenues_number__c, DMT_Year__c
            FROM DMT_Opportunity_Business_Plan__c
            WHERE DMT_Year__c = :String.valueOf(nextYear)
              AND DMT_Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, inserted.size(), 'Should insert one new record');
        System.assertEquals(3000, inserted[0].DMT_Revenues_number__c, 'Revenue should match');
    }

    @isTest
    static void testSaveFinancials_BlankJson() {
        Test.startTest();
        DMT_FinancialsNewController.saveFinancials('');
        DMT_FinancialsNewController.saveFinancials(null);
        Test.stopTest();
        // No exception expected — blank/null should be a no-op
    }

    @isTest
    static void testGetFinancialsByOpportunity_NoRecords() {
        // Use a fake ID that won't match any records
        Test.startTest();
        List<DMT_Opportunity_Business_Plan__c> results =
            DMT_FinancialsNewController.getFinancialsByOpportunity('006000000000000AAA');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for non-existent opportunity');
    }
}