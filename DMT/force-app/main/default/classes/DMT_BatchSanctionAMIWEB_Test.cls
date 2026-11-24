@isTest
public with sharing class DMT_BatchSanctionAMIWEB_Test {

    // CIBGLOBALD-4851 - client of the Bulk Import test lines
    private static final String BULK_IMPORT_CLIENT_NAME = 'Bulk Import Status Client';
    // CIBGLOBALD-4851 - test data through DMT_UtilTestClass (DMT test architecture)
    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();

    @TestSetup
    static void setupTestData() {
        DMT_Test_DataFactory.generateTestSanctionLines();
        // CIBGLOBALD-4851 - Enhancement fix to existing process: a line needs a client to leave Draft
        // ('you must select at least a customer'); the Bulk Import mode tests failed in the org without it.
        DMT_UTIL.createAccount(new Map<Schema.SObjectField, Object>{ Account.Name => BULK_IMPORT_CLIENT_NAME });
    }

    private static Id bulkImportClientId() {
return [SELECT Id FROM Account WHERE Name = :BULK_IMPORT_CLIENT_NAME LIMIT 1].Id;
    }

    @isTest
    static void testBatchExecution() {
    
        DMT_BatchSanctionAMIWEB batch = new DMT_BatchSanctionAMIWEB();
        // CIBGLOBALD-4851 - Enhancement fix to existing process: the shared factory (generateTestSanctionLines) creates
        // the Risk Line Terms without DMT_Risk_Type__c and the line without Amount__c / DMT_LastLevelId__c, which the org
        // now requires to leave Draft ('Must provide the type of risk.', 'The amount and type of risk of the line are
        // mandatory'); the test failed in the org without them.
        // One risk type per term: the factory's term ranges overlap (0-3, 0-5, 0-7), which one risk type does not allow.
        List<String> riskTypes = new List<String>{ 'Derivatives', 'Depos', 'Equities', 'Singular', 'Repos' };
        List<DMT_Risk_Line_Term__c> terms = [SELECT Id FROM DMT_Risk_Line_Term__c WHERE DMT_Line__r.DMT_Origin__c = 'AMIWEB'];
        for (Integer i = 0; i < terms.size(); i++) {
            terms[i].DMT_Risk_Type__c = riskTypes[Math.mod(i, riskTypes.size())];
        }
        update terms;
        List<DMT_Line__c> nightlyLines = [SELECT Id FROM DMT_Line__c WHERE DMT_Origin__c = 'AMIWEB'];
        for (DMT_Line__c line : nightlyLines) {
            line.Amount__c          = 100000;
            line.DMT_LastLevelId__c = '20200';
        }
        update nightlyLines;

        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<DMT_Line__c> updatedLines = [SELECT Status__c, Closed__c, g_line_status_type__c, DMT_line_status_type__c FROM DMT_Line__c WHERE DMT_Origin__c = 'AMIWEB'];

        for (DMT_Line__c line : updatedLines) {
            Assert.areEqual(line.g_line_status_type__c, line.DMT_line_status_type__c, 'Status formula should be the same to informed value');
        }
    }

    @isTest
    static void testFinishMethod() {
        // Run the batch and check the finish method
        DMT_BatchSanctionAMIWEB batch = new DMT_BatchSanctionAMIWEB();

        Test.startTest();
        Id jobId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Check the email job
        AsyncApexJob job = [SELECT Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id = :jobId];
        
        Assert.areNotEqual(null, job, 'The AsyncApexJob task should exist.');
        Assert.areEqual('Completed', job.Status, 'The job status should be Completed.');
        Assert.areEqual(0, job.NumberOfErrors, 'There should be no errors in the batch.');
    }

    @isTest
    static void testBulkImportModeUpdatesOnlyLinesOfTheImport() {
        Id otherProductsRtId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId();
        List<DMT_Line__c> lines = new List<DMT_Line__c>{
            buildBulkImportLine('BITEST001', 'AP', otherProductsRtId),
            buildBulkImportLine('BITEST002', 'PR', otherProductsRtId),
            buildBulkImportLine('BITEST003', 'AP', otherProductsRtId),
            buildBulkImportLine('BITEST004', null, otherProductsRtId)
        };
        insert lines;
        insertMatchingRiskLineTerm(lines);

        Test.startTest();
            // BITEST003 belongs to another import, so it is not part of the set
            Id jobId = Database.executeBatch(new DMT_BatchSanctionAMIWEB(new Set<String>{ 'BITEST001', 'BITEST002', 'BITEST004' }), 50);
        Test.stopTest();

        Map<String, String> statusByLineId = new Map<String, String>();
        for (DMT_Line__c line : [SELECT Line_Id__c, Status__c FROM DMT_Line__c WHERE Line_Id__c LIKE 'BITEST%']) {
            statusByLineId.put(line.Line_Id__c, line.Status__c);
        }
        Assert.areEqual('Approval', statusByLineId.get('BITEST001'), 'AP code should move the line to Approval');
        Assert.areEqual('Proposal', statusByLineId.get('BITEST002'), 'PR code should move the line to Proposal');
        Assert.areEqual('Draft', statusByLineId.get('BITEST003'), 'Lines outside the import must not be updated');
        Assert.areEqual('Draft', statusByLineId.get('BITEST004'), 'Lines without a status code must stay in Draft');

        AsyncApexJob job = [SELECT Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId];
        Assert.areEqual('Completed', job.Status, 'The Bulk Import mode job should complete');
        Assert.areEqual(0, job.NumberOfErrors, 'The Bulk Import mode job should have no errors');
    }

    @isTest
    static void testBulkImportModeIgnoresNonBulkImportLines() {
        Id otherProductsRtId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId();
        DMT_Line__c manualLine = buildBulkImportLine('BITEST005', 'AP', otherProductsRtId);
        manualLine.DMT_Origin__c = 'Salesforce';
        insert manualLine;
        insertMatchingRiskLineTerm(new List<DMT_Line__c>{ manualLine });

        Test.startTest();
            Database.executeBatch(new DMT_BatchSanctionAMIWEB(new Set<String>{ 'BITEST005' }), 50);
        Test.stopTest();

        DMT_Line__c result = [SELECT Status__c FROM DMT_Line__c WHERE Line_Id__c = 'BITEST005'];
        Assert.areEqual('Draft', result.Status__c, 'Only BulkImport origin lines are updated in Bulk Import mode');
    }

    /**
     * @description CIBGLOBALD-4157 follow-up: Bulk Import mode must partial-save (Database.update
     * with allOrNone=false), not update-all-or-nothing. One line failing a validation rule/flow
     * (here: CompulsoryAmountLastLevel, missing Amount__c/DMT_LastLevelId__c) must be reported and
     * left as-is, without blocking a valid line in the same chunk.
     */
    @isTest
    static void testBulkImportModePartialSaveDoesNotBlockOtherLines() {
        Id otherProductsRtId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId();
        DMT_Line__c goodLine = buildBulkImportLine('BITEST006', 'PR', otherProductsRtId);
        // CIBGLOBALD-4851 - built through DMT_UtilTestClass (DMT test architecture)
        DMT_Line__c badLine = DMT_UTIL.buildLine(new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name                  => 'Bulk Import Status Test BITEST007',
            DMT_Line__c.Line_Id__c            => 'BITEST007',
            DMT_Line__c.DMT_Origin__c         => 'BulkImport',
            DMT_Line__c.Status__c             => 'Draft',
            DMT_Line__c.g_line_status_type__c => 'PR',
            DMT_Line__c.RecordTypeId          => otherProductsRtId
            // Amount__c and DMT_LastLevelId__c intentionally left blank - violates CompulsoryAmountLastLevel
        });
        insert new List<DMT_Line__c>{ goodLine, badLine };
        insertMatchingRiskLineTerm(new List<DMT_Line__c>{ goodLine });

        Test.startTest();
            Id jobId = Database.executeBatch(new DMT_BatchSanctionAMIWEB(new Set<String>{ 'BITEST006', 'BITEST007' }), 50);
        Test.stopTest();

        Map<String, String> statusByLineId = new Map<String, String>();
        for (DMT_Line__c line : [SELECT Line_Id__c, Status__c FROM DMT_Line__c WHERE Line_Id__c IN ('BITEST006', 'BITEST007')]) {
            statusByLineId.put(line.Line_Id__c, line.Status__c);
        }
        Assert.areEqual('Proposal', statusByLineId.get('BITEST006'), 'The valid line must still succeed despite the other line failing');
        Assert.areEqual('Draft', statusByLineId.get('BITEST007'), 'The invalid line must fail validation and stay Draft, not be silently pushed through');

        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :jobId];
        Assert.areEqual('Completed', job.Status, 'A per-row validation failure must not fail the whole batch job');
    }

    /**
     * @description CIBGLOBALD-4851 - Bulk Import load mode: each line goes straight to the target the load decided, with
     * or without a code (a line the load sent to Draft goes back to its previous status); lines outside the map are not
     * touched. Data through DMT_UtilTestClass (DMT test architecture).
     */
    @isTest
    static void testBulkImportLoadModeUsesTargetStatus() {
        Id otherProductsRtId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId();
        Id clientId = bulkImportClientId();
        List<DMT_Line__c> lines = new List<DMT_Line__c>();
        for (String lineId : new List<String>{ 'BITEST008', 'BITEST009', 'BITEST010' }) {
            lines.add(DMT_UTIL.buildLine(new Map<Schema.SObjectField, Object>{
                DMT_Line__c.Name                  => 'Bulk Import Load Test ' + lineId,
                DMT_Line__c.Line_Id__c            => lineId,
                DMT_Line__c.DMT_Origin__c         => 'BulkImport',
                DMT_Line__c.Status__c             => 'Draft',
                DMT_Line__c.g_line_status_type__c => lineId == 'BITEST009' ? 'PR' : null,
                DMT_Line__c.RecordTypeId          => otherProductsRtId,
                DMT_Line__c.Client__c             => clientId,
                DMT_Line__c.Amount__c             => 100000,
                DMT_Line__c.DMT_LastLevelId__c    => '20200'
            }));
        }
        insert lines;
        insertMatchingRiskLineTerm(lines);

        Test.startTest();
            Id jobId = Database.executeBatch(new DMT_BatchSanctionAMIWEB(new Map<String, String>{
                'BITEST008' => 'Proposal',  // no code: back to the status it had before the load
                'BITEST009' => 'Proposal'   // code PR
            }, 'job-amiweb-load'), 200); // a test runs one chunk; production uses scope 1 (DMT_BulkImportBatch.finish)
        Test.stopTest();

        Map<String, String> statusByLineId = new Map<String, String>();
        for (DMT_Line__c line : [SELECT Line_Id__c, Status__c FROM DMT_Line__c WHERE Line_Id__c IN ('BITEST008', 'BITEST009', 'BITEST010')]) {
            statusByLineId.put(line.Line_Id__c, line.Status__c);
        }
        Assert.areEqual('Proposal', statusByLineId.get('BITEST008'), 'A line without code goes to its target');
        Assert.areEqual('Proposal', statusByLineId.get('BITEST009'), 'A line with a code goes to its target');
        Assert.areEqual('Draft', statusByLineId.get('BITEST010'), 'A line outside the map is not touched');
        Assert.areEqual('Completed', [SELECT Status FROM AsyncApexJob WHERE Id = :jobId].Status, 'The load mode job completes');
        // CIBGLOBALD-4851 - progress and result for the screen (Phase STATUS, jobId of the load)
        DMT_BulkImportProgress__e result = DMT_BulkImportBatch.publishedEvents[DMT_BulkImportBatch.publishedEvents.size() - 1];
        Assert.areEqual('job-amiweb-load', result.Job_Id__c, 'Result published with the jobId of the load');
        Assert.areEqual(DMT_BulkImportBatch.PHASE_STATUS, result.Phase__c, 'Status phase');
        Assert.areEqual(DMT_BulkImportBatch.EVENT_COMPLETED, result.Status__c, 'The job reports its end');
        Assert.areEqual(2, result.Success_Count__c, 'Both lines of the map moved');
        Assert.areEqual(0, result.Error_Count__c, 'No failure');
    }

    // CIBGLOBALD-4851 - built through DMT_UtilTestClass (DMT test architecture); memory only, the caller inserts the list
    private static DMT_Line__c buildBulkImportLine(String lineId, String statusCode, Id recordTypeId) {
        return DMT_UTIL.buildLine(new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name                  => 'Bulk Import Status Test ' + lineId,
            DMT_Line__c.Line_Id__c            => lineId,
            DMT_Line__c.DMT_Origin__c         => 'BulkImport',
            DMT_Line__c.Status__c             => 'Draft',
            DMT_Line__c.g_line_status_type__c => statusCode,
            DMT_Line__c.RecordTypeId          => recordTypeId,
            DMT_Line__c.Client__c             => bulkImportClientId(),
            // CompulsoryAmountLastLevel requires both set before an OtherProducts line can reach Proposal
            DMT_Line__c.Amount__c             => 100000,
            DMT_Line__c.DMT_LastLevelId__c    => '20200'
        });
    }

    // CheckAmountsInLine (before-save flow, fires on any Status__c change for an "OL" template-type
    // line) requires DMT_RollupAmount__c (SUM of child DMT_Risk_Line_Term__c.DMT_Amount__c) >= the
    // line's own Amount__c. Give each line one term covering it so the batch's status update survives.
    private static void insertMatchingRiskLineTerm(List<DMT_Line__c> lines) {
        List<DMT_Risk_Line_Term__c> terms = new List<DMT_Risk_Line_Term__c>();
        for (DMT_Line__c line : lines) {
terms.add(DMT_UTIL.buildRiskLineTerm(new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.DMT_Line__c   => line.Id,
                DMT_Risk_Line_Term__c.DMT_Amount__c => 100000
            }));
        }
        insert terms;
    }

}