@isTest
public class DMT_BulkImportController_Test {

    // CIBGLOBALD-4851 - test data through DMT_UtilTestClass (DMT test architecture)
    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();

    @TestSetup
    static void makeData() {
        DMT_UTIL.createAccount(new Map<Schema.SObjectField, Object>{ // CIBGLOBALD-4851
            Account.Name             => 'Test Bulk Import Client',
            Account.g_customer_id__c => 'ES0182000125513'
        });
    }

    @isTest
    static void testSubmitLinesEnqueuesBatch() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Line_Id__c'             => 'CTRLTEST001',
                'Name'                   => 'Controller Test Line',
                'Client_Code__c'         => 'ES0182000125513',
                'Booking_Geography__c'   => 'ES',
                'Start_Date__c'          => '2026-01-01',
                'End_Date__c'            => '2027-01-01',
                'CurrencyIsoCode'        => 'EUR',
                'DMT_LastLevelId__c'     => '20200',
                'owner User id_user__c'  => '',
                'DMT_Risk_Line_Term__c DMT_Amount__c' => '500000.0'
            }
        };
        String rowsJson = JSON.serialize(rows);
        String jobId = 'job-ctrl-test-001';

        Test.startTest();
            String returned = DMT_BulkImportController.submitLines(rowsJson, jobId, 'TreasurySettlement');
        Test.stopTest();

        Assert.areEqual(jobId, returned, 'submitLines should return the provided jobId');
        List<DMT_Line__c> created = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = 'CTRLTEST001'];
        Assert.areEqual(1, created.size(), 'One line should have been created by the batch');
    }

    @isTest
    static void testGetExistingLinesReturnsMatches() {
        DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{ // CIBGLOBALD-4851
            DMT_Line__c.Name          => 'Existing Line Test',
            DMT_Line__c.Line_Id__c    => 'CTRLTEST010',
            DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });

        List<DMT_Line__c> result = DMT_BulkImportController.getExistingLines(
            new List<String>{ 'CTRLTEST010', 'NONEXISTENT' }
        );

        Assert.areEqual(1, result.size(), 'Should return only the matching line');
        Assert.areEqual('CTRLTEST010', result[0].Line_Id__c);
    }

    @isTest
    static void testGetExistingTermsForLinesReturnsMatches() {
        DMT_Line__c line = DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{ // CIBGLOBALD-4851
            DMT_Line__c.Name          => 'Parent Line for Terms',
            DMT_Line__c.Line_Id__c    => 'CTRLTEST011',
            DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
        insert new List<DMT_Risk_Line_Term__c>{ // CIBGLOBALD-4851
            DMT_UTIL.buildRiskLineTerm(new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.DMT_Line__c => line.Id, DMT_Risk_Line_Term__c.DMT_RiskLineTermId__c => 'CTRLTEST011-T01'
            }),
            DMT_UTIL.buildRiskLineTerm(new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.DMT_Line__c => line.Id, DMT_Risk_Line_Term__c.DMT_RiskLineTermId__c => 'CTRLTEST011-T02'
            })
        };

        List<DMT_Risk_Line_Term__c> result = DMT_BulkImportController.getExistingTermsForLines(
            new List<String>{ 'CTRLTEST011' }
        );

        Assert.areEqual(2, result.size(), 'Should return both terms linked to the matching line, not be capped by lineIds.size()');
    }

    // CIBGLOBALD-4851 - Line Product Items of the loaded lines are listed by Line_Id__c
    @isTest
    static void testGetExistingProductItemsForLinesReturnsMatches() {
        DMT_Line__c line = DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name          => 'Parent Line for Product Items',
            DMT_Line__c.Line_Id__c    => 'CTRLTEST014',
            DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
        DMT_UTIL.createLineProductItemRecord(new Map<Schema.SObjectField, Object>{
            DMT_Line_Product_Item__c.Line__c               => line.Id,
            DMT_Line_Product_Item__c.Product_Code_Value__c => 'CTRLTEST014-P01'
        });

        List<DMT_Line_Product_Item__c> result = DMT_BulkImportController.getExistingProductItemsForLines(
            new List<String>{ 'CTRLTEST014', 'NONEXISTENT' }
        );

        Assert.areEqual(1, result.size(), 'Should return only the product item of the matching line');
        Assert.areEqual('CTRLTEST014', result[0].Line__r.Line_Id__c);
    }

    @isTest
    static void testQueryCreatedLinesReturnsMatches() {
        DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{ // CIBGLOBALD-4851
            DMT_Line__c.Name          => 'Created Line Query Test',
            DMT_Line__c.Line_Id__c    => 'CTRLTEST012',
            DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });

        List<DMT_Line__c> result = DMT_BulkImportController.queryCreatedLines(
            new List<String>{ 'CTRLTEST012' }
        );

        Assert.areEqual(1, result.size());
        Assert.areEqual('CTRLTEST012', result[0].Line_Id__c);
    }

    @isTest
    static void testQueryCreatedTermsReturnsMatches() {
        DMT_Line__c line = DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{ // CIBGLOBALD-4851
            DMT_Line__c.Name          => 'Parent Line for Term Query',
            DMT_Line__c.Line_Id__c    => 'CTRLTEST013',
            DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
        DMT_UTIL.createRiskLineTermRecord(new Map<Schema.SObjectField, Object>{ // CIBGLOBALD-4851
            DMT_Risk_Line_Term__c.DMT_Line__c           => line.Id,
            DMT_Risk_Line_Term__c.DMT_RiskLineTermId__c => 'CTRLTEST013-T01'
        });

        List<DMT_Risk_Line_Term__c> result = DMT_BulkImportController.queryCreatedTerms(
            new List<String>{ 'CTRLTEST013-T01' }
        );

        Assert.areEqual(1, result.size());
        Assert.areEqual('CTRLTEST013-T01', result[0].DMT_RiskLineTermId__c);
    }

    @isTest
    static void testSubmitProductsEnqueuesBatch() {
        DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{ // CIBGLOBALD-4851
            DMT_Line__c.Name          => 'Parent Line for Controller Test',
            DMT_Line__c.Line_Id__c    => 'CTRLTEST002',
            DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });

        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Line_Id__c'                             => 'CTRLTEST002',
                'DMT_RiskLineTermId__c'                  => 'CTRLTEST002-T01',
                'Name'                                   => 'Controller Test Term',
                'DMT_Risk_Line_Term__c DMT_Init_Term__c' => '2026-01-01',
                'DMT_Risk_Line_Term__c DMT_End_Term__c'  => '2027-01-01',
                'DMT_Risk_Line_Term__c DMT_Amount__c'    => '250000.0',
                'CurrencyIsoCode'                        => 'EUR',
                'owner User id_user__c'                  => ''
            }
        };
        String rowsJson = JSON.serialize(rows);
        String jobId = 'job-ctrl-test-002';

        Test.startTest();
            String returned = DMT_BulkImportController.submitProducts(rowsJson, jobId);
        Test.stopTest();

        Assert.areEqual(jobId, returned, 'submitProducts should return the provided jobId');
        List<DMT_Risk_Line_Term__c> terms = [SELECT Id FROM DMT_Risk_Line_Term__c WHERE DMT_RiskLineTermId__c = 'CTRLTEST002-T01'];
        Assert.areEqual(1, terms.size(), 'One risk line term should have been created by the batch');
    }

    @isTest
    static void testUpdateLineStatusLaunchesBatch() {
        DMT_Line__c line = DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{ // CIBGLOBALD-4851
            DMT_Line__c.Name                  => 'Update Line Status Test',
            DMT_Line__c.Line_Id__c            => 'CTRLTEST020',
            DMT_Line__c.DMT_Origin__c         => 'BulkImport',
            DMT_Line__c.Status__c             => 'Draft',
            DMT_Line__c.g_line_status_type__c => 'PR',
            DMT_Line__c.RecordTypeId          => Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId(),
            // CompulsoryAmountLastLevel requires both set before an OtherProducts line can reach Proposal
            DMT_Line__c.Amount__c             => 100000,
            DMT_Line__c.DMT_LastLevelId__c    => '20200',
            // CIBGLOBALD-4851 - Enhancement fix to existing process: a line needs a client to leave Draft
            // ('you must select at least a customer'); the test failed in the org without it.
            DMT_Line__c.Client__c             => [SELECT Id FROM Account WHERE g_customer_id__c = 'ES0182000125513' LIMIT 1].Id
        });
        // CheckAmountsInLine (before-save flow) requires the products' total to cover the line's Amount__c
        DMT_UTIL.createRiskLineTermRecord(new Map<Schema.SObjectField, Object>{ // CIBGLOBALD-4851
            DMT_Risk_Line_Term__c.DMT_Line__c   => line.Id,
            DMT_Risk_Line_Term__c.DMT_Amount__c => 100000
        });

        Test.startTest();
            String asyncJobId = DMT_BulkImportController.updateLineStatus(new List<String>{ 'CTRLTEST020' });
        Test.stopTest();

        Assert.isNotNull(asyncJobId, 'updateLineStatus should return the batch job Id');
        DMT_Line__c updatedLine = [SELECT Status__c FROM DMT_Line__c WHERE Line_Id__c = 'CTRLTEST020'];
        Assert.areEqual('Proposal', updatedLine.Status__c, 'The line should be moved to the status informed in the file');
    }

    @isTest
    static void testUpdateLineStatusRejectsEmptyList() {
        Boolean thrown = false;
        try {
            DMT_BulkImportController.updateLineStatus(new List<String>());
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'An empty list of lines should be rejected');
    }
}