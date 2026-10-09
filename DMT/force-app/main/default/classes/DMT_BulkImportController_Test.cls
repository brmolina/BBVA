@isTest
public class DMT_BulkImportController_Test {

    @TestSetup
    static void makeData() {
        insert new Account(
            Name             = 'Test Bulk Import Client',
            g_customer_id__c = 'ES0182000125513'
        );
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
        DMT_Line__c line = new DMT_Line__c(
            Name          = 'Existing Line Test',
            Line_Id__c    = 'CTRLTEST010',
            DMT_Origin__c = 'BulkImport'
        );
        insert line;

        List<DMT_Line__c> result = DMT_BulkImportController.getExistingLines(
            new List<String>{ 'CTRLTEST010', 'NONEXISTENT' }
        );

        Assert.areEqual(1, result.size(), 'Should return only the matching line');
        Assert.areEqual('CTRLTEST010', result[0].Line_Id__c);
    }

    @isTest
    static void testGetExistingTermsForLinesReturnsMatches() {
        DMT_Line__c line = new DMT_Line__c(
            Name          = 'Parent Line for Terms',
            Line_Id__c    = 'CTRLTEST011',
            DMT_Origin__c = 'BulkImport'
        );
        insert line;
        insert new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Line__c = line.Id, DMT_RiskLineTermId__c = 'CTRLTEST011-T01'),
            new DMT_Risk_Line_Term__c(DMT_Line__c = line.Id, DMT_RiskLineTermId__c = 'CTRLTEST011-T02')
        };

        List<DMT_Risk_Line_Term__c> result = DMT_BulkImportController.getExistingTermsForLines(
            new List<String>{ 'CTRLTEST011' }
        );

        Assert.areEqual(2, result.size(), 'Should return both terms linked to the matching line, not be capped by lineIds.size()');
    }

    @isTest
    static void testQueryCreatedLinesReturnsMatches() {
        DMT_Line__c line = new DMT_Line__c(
            Name          = 'Created Line Query Test',
            Line_Id__c    = 'CTRLTEST012',
            DMT_Origin__c = 'BulkImport'
        );
        insert line;

        List<DMT_Line__c> result = DMT_BulkImportController.queryCreatedLines(
            new List<String>{ 'CTRLTEST012' }
        );

        Assert.areEqual(1, result.size());
        Assert.areEqual('CTRLTEST012', result[0].Line_Id__c);
    }

    @isTest
    static void testQueryCreatedTermsReturnsMatches() {
        DMT_Line__c line = new DMT_Line__c(
            Name          = 'Parent Line for Term Query',
            Line_Id__c    = 'CTRLTEST013',
            DMT_Origin__c = 'BulkImport'
        );
        insert line;
        DMT_Risk_Line_Term__c term = new DMT_Risk_Line_Term__c(
            DMT_Line__c           = line.Id,
            DMT_RiskLineTermId__c  = 'CTRLTEST013-T01'
        );
        insert term;

        List<DMT_Risk_Line_Term__c> result = DMT_BulkImportController.queryCreatedTerms(
            new List<String>{ 'CTRLTEST013-T01' }
        );

        Assert.areEqual(1, result.size());
        Assert.areEqual('CTRLTEST013-T01', result[0].DMT_RiskLineTermId__c);
    }

    @isTest
    static void testSubmitProductsEnqueuesBatch() {
        DMT_Line__c parentLine = new DMT_Line__c(
            Name          = 'Parent Line for Controller Test',
            Line_Id__c    = 'CTRLTEST002',
            DMT_Origin__c = 'BulkImport'
        );
        insert parentLine;

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
        DMT_Line__c line = new DMT_Line__c(
            Name                  = 'Update Line Status Test',
            Line_Id__c            = 'CTRLTEST020',
            DMT_Origin__c         = 'BulkImport',
            Status__c             = 'Draft',
            g_line_status_type__c = 'PR',
            RecordTypeId          = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId(),
            // CompulsoryAmountLastLevel requires both set before an OtherProducts line can reach Proposal
            Amount__c             = 100000,
            DMT_LastLevelId__c    = '20200'
        );
        insert line;
        // CheckAmountsInLine (before-save flow) requires the products' total to cover the line's Amount__c
        insert new DMT_Risk_Line_Term__c(DMT_Line__c = line.Id, DMT_Amount__c = 100000);

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