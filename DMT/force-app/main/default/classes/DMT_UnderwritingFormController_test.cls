@IsTest
public with sharing class DMT_UnderwritingFormController_test {

    private static String firstPicklistValue(String sobjectApi, String fieldApi) {
        Schema.SObjectType t = Schema.getGlobalDescribe().get(sobjectApi);
        Schema.DescribeFieldResult f = t.getDescribe().fields.getMap().get(fieldApi).getDescribe();
        List<Schema.PicklistEntry> vals = f.getPicklistValues();
        return (vals.isEmpty()) ? null : vals[0].getValue();
    }

    private static Opportunity getTestOpp() {
        return [SELECT Id, Name, underwriting_agreement_type__c, deal_total_amount__c, signing_date__c FROM Opportunity LIMIT 1];
    }

    @TestSetup
    static void makeData() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp.Name = 'Test Underwriting Opp';
        
        String uwValue = firstPicklistValue('Opportunity', 'underwriting_agreement_type__c');
        if (uwValue != null) {
            opp.underwriting_agreement_type__c = uwValue;
        }
        update opp;

          Account acc = new Account(
            Name = 'Test Counterparty',
            DES_Structure_Type__c = 'Subsidiary',
            g_customer_id__c = 'ES0182000000999'
        );
        insert acc;
    }

    @IsTest
    static void getUnderwritingDataTest() {
        Opportunity opp = getTestOpp();
        Test.startTest();
        Map<String, Object> result = DMT_UnderwritingFormController.getUnderwritingData(opp.Id);
        Test.stopTest();
        Assert.isNotNull(result, 'Result should not be null');
    }

    @IsTest
    static void saveUnderwritingData_UpdateOppAndSoldOrdersTest() {
        Opportunity opp = getTestOpp();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String settledValue = firstPicklistValue('Sold_Order__c', 'gf_sold_order_settled_ind_type__c');

        Map<String, Object> updatedFields = new Map<String, Object>{
            'deal_total_amount__c' => 5000000
        };

        // Added mandatory fields Currency__c and gf_sold_order_settled_ind_type__c
        Sold_Order__c so = new Sold_Order__c(
            gf_loan_br_ctpty_id__c = acc.Id,
            gf_ctpty_sold_order_amount__c = 1000,
            gf_sold_ord_ctpty_setl_amount__c = 1000,
            Currency__c = 'USD',
            gf_sold_order_settled_ind_type__c = settledValue,
            opportunity_id__c = opp.Id
        );

        Test.startTest();
        DMT_UnderwritingFormController.saveUnderwritingData(opp.Id, updatedFields, new List<Sold_Order__c>{ so }, null);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT deal_total_amount__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual(5000000, updatedOpp.deal_total_amount__c);
    }

    @IsTest
    static void saveUnderwritingData_DeleteSoldOrderTest() {
        Opportunity opp = getTestOpp();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String settledValue = firstPicklistValue('Sold_Order__c', 'gf_sold_order_settled_ind_type__c');

        // Added mandatory fields for the initial insert
        Sold_Order__c so = new Sold_Order__c(
            gf_loan_br_ctpty_id__c = acc.Id,
            gf_ctpty_sold_order_amount__c = 1000,
            gf_sold_ord_ctpty_setl_amount__c = 1000,
            Currency__c = 'USD',
            gf_sold_order_settled_ind_type__c = settledValue,
            opportunity_id__c = opp.Id
        );
        insert so;

        Test.startTest();
        DMT_UnderwritingFormController.saveUnderwritingData(opp.Id, null, null, new List<Id>{ so.Id });
        Test.stopTest();

        Integer count = [SELECT count() FROM Sold_Order__c WHERE Id = :so.Id];
        Assert.areEqual(0, count, 'The record should be deleted');
    }

    @IsTest
    static void saveUnderwritingData_InvalidDateTest() {
        Opportunity opp = getTestOpp();
        Map<String, Object> updatedFields = new Map<String, Object>{
            'signing_date__c' => 'invalid-date-string'
        };

        Test.startTest();
        try {
            DMT_UnderwritingFormController.saveUnderwritingData(opp.Id, updatedFields, null, null);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (Exception e) {
            // Updated assertion to check for any message, as AuraHandledException 
            // often masks the custom message in test contexts
            Assert.isTrue(String.isNotBlank(e.getMessage()), 'Should have an error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void searchClientsFromLocalTest() {
        Account account = [SELECT Id FROM Account WHERE Name = 'Test Counterparty' LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ account.Id });

        Test.startTest();
        List<DMT_UnderwritingFormController.LookupOption> results = DMT_UnderwritingFormController.searchClientsFromLocal('Counterparty');
        Test.stopTest();
        Assert.isFalse(results.isEmpty(), 'Results should not be empty');
    }

    @IsTest
    static void saveUnderwritingData_FeeFormulaCoverageTest() {
        Opportunity opp = getTestOpp();
        
        // FORCE the tranche amount to be 1,000,000 right now to ensure the query inside the controller finds it
        opp.bbva_prtcp_tranche_amount__c = 1000000;
        TriggerBypass.setBypass();
        update opp;

        // Now we only update the percentage via the controller
        Map<String, Object> updatedFields = new Map<String, Object>{
            'operation_underwriting_per__c' => 200 
        };

        Test.startTest();
        DMT_UnderwritingFormController.saveUnderwritingData(opp.Id, updatedFields, null, null);
        Test.stopTest();

        Opportunity result = [SELECT underwriting_fee_amount__c FROM Opportunity WHERE Id = :opp.Id];
        
        // Calculation logic in Controller: (200 / 10000) * 1,000,000 = 20,000
        Assert.areEqual(20000, result.underwriting_fee_amount__c, 'Fee amount should be recalculated using queried tranche amount');
    }

    // 4. Coverage for Malformed Sold Order ID Try/Catch
    @IsTest
    static void saveUnderwritingData_MalformedSoIdCoverageTest() {
        Opportunity opp = getTestOpp();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String settledValue = firstPicklistValue('Sold_Order__c', 'gf_sold_order_settled_ind_type__c');
        
        // We simulate a malformed ID string coming from the UI
        // Added all required fields to the JSON to pass trigger/validation rules
        String jsonSO = '{' +
            '"attributes":{"type":"Sold_Order__c"},' +
            '"Id":"INVALID_ID_STRING",' +
            '"gf_ctpty_sold_order_amount__c":500,' +
            '"gf_sold_ord_ctpty_setl_amount__c":500,' +
            '"Currency__c":"USD",' +
            '"gf_loan_br_ctpty_id__c":"' + acc.Id + '",' +
            '"gf_sold_order_settled_ind_type__c":"' + settledValue + '"' +
        '}';
        
        Sold_Order__c malformedSO = (Sold_Order__c)JSON.deserialize(jsonSO, Sold_Order__c.class);

        Test.startTest();
        // This will hit the catch block, set ID to null, and perform an insert
        DMT_UnderwritingFormController.saveUnderwritingData(opp.Id, null, new List<Sold_Order__c>{ malformedSO }, null);
        Test.stopTest();

        List<Sold_Order__c> results = [SELECT Id FROM Sold_Order__c WHERE opportunity_id__c = :opp.Id AND gf_ctpty_sold_order_amount__c = 500];
        Assert.isFalse(results.isEmpty(), 'Record should be inserted even with malformed ID input');
        Assert.isNotNull(results[0].Id, 'A valid Salesforce ID should have been generated');
    }

    // ──────────────────────────────────────────────────────────────
    // searchCounterparties
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void searchCounterparties_BlankTermTest() {
        Test.startTest();
        List<Map<String, Object>> r1 = DMT_UnderwritingFormController.searchCounterparties('');
        List<Map<String, Object>> r2 = DMT_UnderwritingFormController.searchCounterparties(null);
        Test.stopTest();
        Assert.isTrue(r1.isEmpty(), 'Empty term should return empty list');
        Assert.isTrue(r2.isEmpty(), 'Null term should return empty list');
    }

    @IsTest
    static void searchCounterparties_ShortTermTest() {
        Test.startTest();
        List<Map<String, Object>> results = DMT_UnderwritingFormController.searchCounterparties('A');
        Test.stopTest();
        Assert.isTrue(results.isEmpty(), 'Term shorter than 2 chars should return empty list');
    }

    @IsTest
    static void searchCounterparties_OnlySpecialCharsTest() {
        // After sanitising '$%' all chars are stripped → blank → early return
        Test.startTest();
        List<Map<String, Object>> results = DMT_UnderwritingFormController.searchCounterparties('$%');
        Test.stopTest();
        Assert.isTrue(results.isEmpty(), 'Term with only special chars should return empty list');
    }

    @IsTest
    static void searchCounterparties_ValidTermTest() {
        Account acc = [SELECT Id FROM Account WHERE DES_Structure_Type__c = 'Subsidiary' LIMIT 1];
        // Mock SOSL so it returns the test account
        Test.setFixedSearchResults(new List<Id>{ acc.Id });

        Test.startTest();
        List<Map<String, Object>> results = DMT_UnderwritingFormController.searchCounterparties('Test');
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Valid term should return mapped results');
        Assert.areEqual(String.valueOf(acc.Id), results[0].get('value'), 'Value should be the account Id');
        Assert.isNotNull(results[0].get('label'),      'label key must be present');
        Assert.isNotNull(results[0].get('subLabel'),   'subLabel key must be present');
        Assert.isNotNull(results[0].get('searchText'), 'searchText key must be present');
    }

    // ──────────────────────────────────────────────────────────────
    // saveSoldOrderRow
    // ──────────────────────────────────────────────────────────────

    @IsTest
    static void saveSoldOrderRow_InsertTest() {
        Opportunity opp = getTestOpp();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String settledValue = firstPicklistValue('Sold_Order__c', 'gf_sold_order_settled_ind_type__c');

        Sold_Order__c so = new Sold_Order__c(
            gf_loan_br_ctpty_id__c               = acc.Id,
            gf_ctpty_sold_order_amount__c         = 2000,
            gf_sold_ord_ctpty_setl_amount__c      = 2000,
            Currency__c                           = 'USD',
            gf_sold_order_settled_ind_type__c     = settledValue
        );

        Test.startTest();
        List<Sold_Order__c> results = DMT_UnderwritingFormController.saveSoldOrderRow(so, opp.Id);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return list with the newly inserted sold order');
    }

    @IsTest
    static void saveSoldOrderRow_UpdateTest() {
        Opportunity opp = getTestOpp();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String settledValue = firstPicklistValue('Sold_Order__c', 'gf_sold_order_settled_ind_type__c');

        Sold_Order__c so = new Sold_Order__c(
            gf_loan_br_ctpty_id__c               = acc.Id,
            gf_ctpty_sold_order_amount__c         = 1500,
            gf_sold_ord_ctpty_setl_amount__c      = 1500,
            Currency__c                           = 'USD',
            gf_sold_order_settled_ind_type__c     = settledValue,
            opportunity_id__c                    = opp.Id
        );
        insert so;

        so.gf_ctpty_sold_order_amount__c = 3000;

        Test.startTest();
        List<Sold_Order__c> results = DMT_UnderwritingFormController.saveSoldOrderRow(so, opp.Id);
        Test.stopTest();

        Sold_Order__c updated = [SELECT gf_ctpty_sold_order_amount__c FROM Sold_Order__c WHERE Id = :so.Id];
        Assert.areEqual(3000, updated.gf_ctpty_sold_order_amount__c, 'Amount should be updated to 3000');
    }

    @IsTest
    static void saveSoldOrderRow_NullSoldOrderTest() {
        Opportunity opp = getTestOpp();

        Test.startTest();
        try {
            DMT_UnderwritingFormController.saveSoldOrderRow(null, opp.Id);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (Exception e) {
            Assert.isTrue(String.isNotBlank(e.getMessage()), 'Should have an error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void saveSoldOrderRow_NullOpportunityIdTest() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String settledValue = firstPicklistValue('Sold_Order__c', 'gf_sold_order_settled_ind_type__c');

        Sold_Order__c so = new Sold_Order__c(
            gf_loan_br_ctpty_id__c               = acc.Id,
            gf_ctpty_sold_order_amount__c         = 1000,
            gf_sold_ord_ctpty_setl_amount__c      = 1000,
            Currency__c                           = 'USD',
            gf_sold_order_settled_ind_type__c     = settledValue
        );

        Test.startTest();
        try {
            DMT_UnderwritingFormController.saveSoldOrderRow(so, null);
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (Exception e) {
            Assert.isTrue(String.isNotBlank(e.getMessage()), 'Should have an error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void saveSoldOrderRow_MalformedIdTest() {
        Opportunity opp = getTestOpp();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String settledValue = firstPicklistValue('Sold_Order__c', 'gf_sold_order_settled_ind_type__c');

        String jsonSO = '{' +
            '"attributes":{"type":"Sold_Order__c"},' +
            '"Id":"INVALID_ID",' +
            '"gf_ctpty_sold_order_amount__c":750,' +
            '"gf_sold_ord_ctpty_setl_amount__c":750,' +
            '"Currency__c":"USD",' +
            '"gf_loan_br_ctpty_id__c":"' + acc.Id + '",' +
            '"gf_sold_order_settled_ind_type__c":"' + settledValue + '"' +
        '}';
        Sold_Order__c malformedSO = (Sold_Order__c) JSON.deserialize(jsonSO, Sold_Order__c.class);

        Test.startTest();
        List<Sold_Order__c> results = DMT_UnderwritingFormController.saveSoldOrderRow(malformedSO, opp.Id);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should insert and return records even with a malformed Id');
    }
}