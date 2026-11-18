@isTest
public with sharing class DMT_BatchSanctionAMIWEB_Test {

    @TestSetup
    static void setupTestData() {
        DMT_Test_DataFactory.generateTestSanctionLines();
    }

    @isTest
    static void testBatchExecution() {
    
        DMT_BatchSanctionAMIWEB batch = new DMT_BatchSanctionAMIWEB();

        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<DMT_Line__c> updatedLines = [SELECT Status__c, Closed__c, g_line_status_type__c, DMT_line_status_type__c FROM DMT_Line__c WHERE DMT_Origin__c = 'AMIWEB'];

        for (DMT_Line__c line : updatedLines) {
            System.assertEquals(line.g_line_status_type__c, line.DMT_line_status_type__c, 'Status formula should be the same to informed value');
        }
    }

    @isTest
    static void testFinishMethod() {
        // Ejecutar el batch y verificar el método finish
        DMT_BatchSanctionAMIWEB batch = new DMT_BatchSanctionAMIWEB();

        Test.startTest();
        Id jobId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verificar el envío del email
        AsyncApexJob job = [SELECT Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id = :jobId];
        
        System.assertNotEquals(null, job, 'The AsyncApexJob task should exist.');
        System.assertEquals('Completed', job.Status, 'The job status should be Completed.');
        System.assertEquals(0, job.NumberOfErrors, 'There should be no errors in the batch.');
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
        DMT_Line__c badLine = new DMT_Line__c(
            Name                  = 'Bulk Import Status Test BITEST007',
            Line_Id__c            = 'BITEST007',
            DMT_Origin__c         = 'BulkImport',
            Status__c              = 'Draft',
            g_line_status_type__c = 'PR',
            RecordTypeId          = otherProductsRtId
            // Amount__c and DMT_LastLevelId__c intentionally left blank - violates CompulsoryAmountLastLevel
        );
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

    private static DMT_Line__c buildBulkImportLine(String lineId, String statusCode, Id recordTypeId) {
        return new DMT_Line__c(
            Name                  = 'Bulk Import Status Test ' + lineId,
            Line_Id__c            = lineId,
            DMT_Origin__c         = 'BulkImport',
            Status__c             = 'Draft',
            g_line_status_type__c = statusCode,
            RecordTypeId          = recordTypeId,
            // CompulsoryAmountLastLevel requires both set before an OtherProducts line can reach Proposal
            Amount__c             = 100000,
            DMT_LastLevelId__c    = '20200'
        );
    }

    // CheckAmountsInLine (before-save flow, fires on any Status__c change for an "OL" template-type
    // line) requires DMT_RollupAmount__c (SUM of child DMT_Risk_Line_Term__c.DMT_Amount__c) >= the
    // line's own Amount__c. Give each line one term covering it so the batch's status update survives.
    private static void insertMatchingRiskLineTerm(List<DMT_Line__c> lines) {
        List<DMT_Risk_Line_Term__c> terms = new List<DMT_Risk_Line_Term__c>();
        for (DMT_Line__c line : lines) {
            terms.add(new DMT_Risk_Line_Term__c(
                DMT_Line__c   = line.Id,
                DMT_Amount__c = 100000
            ));
        }
        insert terms;
    }

}