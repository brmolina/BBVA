/**
 * @description Tests of DMT_BulkImportController. CIBGLOBALD-4851: preview queries, status context and value rules,
 * Process, job state and Update Line Status.
 */
@isTest
public class DMT_BulkImportController_Test {

    // test data through DMT_UtilTestClass (DMT test architecture)
    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();

    @TestSetup
    static void makeData() {
DMT_UTIL.createAccount(new Map<Schema.SObjectField, Object>{
            Account.Name             => 'Test Bulk Import Client',
            Account.g_customer_id__c => 'ES0182000125513'
        });
    }

    // Process: one unit per line (DMT_BulkImportBatch.UNIT_*)
    @isTest
    static void testProcessImportCreatesLine() {
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
String unitsJson = JSON.serialize(new List<Map<String, Object>>{
            new Map<String, Object>{ DMT_BulkImportBatch.UNIT_LINE => rows[0], DMT_BulkImportBatch.UNIT_ROW_NUMBER => 2 }
        });
        String jobId = 'job-ctrl-test-001';

        Test.startTest();
String returned = DMT_BulkImportController.processImport(unitsJson, jobId, 'TreasurySettlement');
        Test.stopTest();

Assert.isNotNull(returned, 'processImport returns the batch job Id');
Map<String, Object> state = DMT_BulkImportController.getJobState(returned);
Assert.areEqual('Completed', state.get('status'), 'The screen reads the job state');
        List<DMT_Line__c> created = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = 'CTRLTEST001'];
        Assert.areEqual(1, created.size(), 'One line should have been created by the batch');
    }

    // profile and client type per client code for the LWC stay-in-Draft check
    @isTest
    static void testGetStatusContext() {
        Map<String, Object> context = DMT_BulkImportController.getStatusContext(
            new List<String>{ 'es0182000125513', 'NONEXISTENT', ' ' }
        );

        Assert.areEqual([SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name, context.get('profileName'),
                        'Running user profile');
        Map<String, String> clientTypeByCode = (Map<String, String>) context.get('clientTypeByCode');
        Assert.areEqual(1, clientTypeByCode.size(), 'Only the code found is returned');
        Assert.isTrue(clientTypeByCode.containsKey('ES0182000125513'), 'Codes are returned in upper case');
        Map<String, String> recordTypeByCode = (Map<String, String>) context.get('clientRecordTypeByCode');
        Assert.isTrue(recordTypeByCode.containsKey('ES0182000125513'), 'Client record type by code');
        // the value checks of the save, by table and field, and the term picklist values
        Map<String, Object> rules = (Map<String, Object>) context.get('fileValueRules');
        Map<String, Object> fieldTypes = (Map<String, Object>) rules.get('fieldTypes');
        Map<String, String> lineTypes = (Map<String, String>) fieldTypes.get('line');
        Assert.areEqual('date', lineTypes.get('Start_Date__c'), 'Start_Date__c is checked as a date');
        Assert.areEqual('number', lineTypes.get('FD_Amount__c'), 'FD_Amount__c is checked as a number');
        Assert.areEqual('boolean', lineTypes.get('Waiver__c'), 'Waiver__c is checked as a checkbox');
        Assert.isFalse(lineTypes.containsKey('Name'), 'Text columns are not checked');
        Assert.areEqual('boolean', ((Map<String, String>) fieldTypes.get('lpi')).get('DMT_FDRestriction__c'), 'Line Product Item checkbox');
        Map<String, List<String>> termDays = (Map<String, List<String>>) rules.get('termDays');
        Assert.isTrue(termDays.get('DMT_Init_Term__c').contains('0'), 'Term picklist values');
    }

    // no custom association: empty list (the query runs and returns nothing)
    @isTest
    static void testGetCustomAssociationClientsWithoutAssociation() {
        DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name => 'No Association Line', DMT_Line__c.Line_Id__c => 'CTRLTEST030', DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
        Assert.isTrue(DMT_BulkImportController.getCustomAssociationClients(new List<String>{ 'CTRLTEST030' }).isEmpty(),
                      'A line without custom association has no clients');
    }

    @isTest
    static void testGetExistingLinesReturnsMatches() {
DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{
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
DMT_Line__c line = DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name          => 'Parent Line for Terms',
            DMT_Line__c.Line_Id__c    => 'CTRLTEST011',
            DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
insert new List<DMT_Risk_Line_Term__c>{
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

    // Line Product Items of the loaded lines are listed by Line_Id__c
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
DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{
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
DMT_Line__c line = DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name          => 'Parent Line for Term Query',
            DMT_Line__c.Line_Id__c    => 'CTRLTEST013',
            DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
DMT_UTIL.createRiskLineTermRecord(new Map<Schema.SObjectField, Object>{
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
static void testProcessImportReplacesTerms() { // products only: the line is not updated
DMT_Line__c line = DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name          => 'Parent Line for Controller Test',
            DMT_Line__c.Line_Id__c    => 'CTRLTEST002',
            DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
DMT_UTIL.createRiskLineTermRecord(new Map<Schema.SObjectField, Object>{ // replaced by the file row
            DMT_Risk_Line_Term__c.DMT_Line__c           => line.Id,
            DMT_Risk_Line_Term__c.DMT_RiskLineTermId__c => 'CTRLTEST002-OLD'
        });

        // unit: line without changes, one Risk Line Terms file row
        Map<String, Object> term = new Map<String, Object>{
            'DMT_RiskLineTermId__c' => 'CTRLTEST002-T01',
            'DMT_Init_Term__c'      => '0',
            'DMT_End_Term__c'       => '365',
            'DMT_Amount__c'         => '250000.0'
        };
        String unitsJson = JSON.serialize(new List<Map<String, Object>>{
            new Map<String, Object>{
                DMT_BulkImportBatch.UNIT_LINE        => new Map<String, Object>{ 'Line_Id__c' => 'CTRLTEST002' },
                DMT_BulkImportBatch.UNIT_ROW_NUMBER  => 2,
                DMT_BulkImportBatch.UNIT_UPDATE_LINE => false,
                DMT_BulkImportBatch.UNIT_RLT         => new List<Object>{ term }
            }
        });
        String jobId = 'job-ctrl-test-002';

        Test.startTest();
            String returned = DMT_BulkImportController.processImport(unitsJson, jobId, 'TreasurySettlement');
        Test.stopTest();

Assert.isNotNull(returned, 'processImport returns the batch job Id');
        List<DMT_Risk_Line_Term__c> terms = [SELECT DMT_RiskLineTermId__c FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :line.Id];
        Assert.areEqual(1, terms.size(), 'The old term is deleted and the file row inserted');
        Assert.areEqual('CTRLTEST002-T01', terms[0].DMT_RiskLineTermId__c, 'The remaining term is the file row');
    }

    @isTest
    static void testUpdateLineStatusLaunchesBatch() {
DMT_Line__c line = DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name                  => 'Update Line Status Test',
            DMT_Line__c.Line_Id__c            => 'CTRLTEST020',
            DMT_Line__c.DMT_Origin__c         => 'BulkImport',
            DMT_Line__c.Status__c             => 'Draft',
            DMT_Line__c.g_line_status_type__c => 'PR',
            DMT_Line__c.RecordTypeId          => Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId(),
            // CompulsoryAmountLastLevel requires both set before an OtherProducts line can reach Proposal
            DMT_Line__c.Amount__c             => 100000,
            DMT_Line__c.DMT_LastLevelId__c    => '20200',
            // Enhancement fix to existing process: a line needs a client to leave Draft
            // ('you must select at least a customer'); the test failed in the org without it.
            DMT_Line__c.Client__c             => [SELECT Id FROM Account WHERE g_customer_id__c = 'ES0182000125513' LIMIT 1].Id
        });
        // CheckAmountsInLine (before-save flow) requires the products' total to cover the line's Amount__c
DMT_UTIL.createRiskLineTermRecord(new Map<Schema.SObjectField, Object>{
            DMT_Risk_Line_Term__c.DMT_Line__c   => line.Id,
            DMT_Risk_Line_Term__c.DMT_Amount__c => 100000
        });

        Test.startTest();
String asyncJobId = DMT_BulkImportController.updateLineStatus(new List<String>{ 'CTRLTEST020' }, 'job-ctrl-020');
        Test.stopTest();

        Assert.isNotNull(asyncJobId, 'updateLineStatus should return the batch job Id');
        DMT_Line__c updatedLine = [SELECT Status__c FROM DMT_Line__c WHERE Line_Id__c = 'CTRLTEST020'];
        Assert.areEqual('Proposal', updatedLine.Status__c, 'The line should be moved to the status informed in the file');
        // the screen gets the result with its jobId
        DMT_BulkImportProgress__e result = DMT_BulkImportBatch.publishedEvents[DMT_BulkImportBatch.publishedEvents.size() - 1];
        Assert.areEqual('job-ctrl-020', result.Job_Id__c, 'Result published with the jobId of the screen');
        Assert.areEqual(DMT_BulkImportBatch.PHASE_STATUS, result.Phase__c, 'Status phase');
        Assert.areEqual(DMT_BulkImportBatch.EVENT_COMPLETED, result.Status__c, 'The job reports its end');
        Assert.areEqual(1, result.Success_Count__c, 'One line moved');
        // The screen finds a status job of this user started from the given job on
        Assert.areEqual(asyncJobId, DMT_BulkImportController.getStatusJobAfterLoad(asyncJobId), 'Status job found');
    }

    @isTest
    static void testUpdateLineStatusRejectsEmptyList() {
        Boolean thrown = false;
        try {
DMT_BulkImportController.updateLineStatus(new List<String>(), 'job-ctrl-021');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'An empty list of lines should be rejected');
    }
}