/**
* @description Test class for Arc_Gen_Traceability.
*/
@isTest
private class Arc_Gen_Traceability_Test {
    /**
    * @description Make test data for test methods.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c arceAnalysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('arceAnalysis', null, groupAccount.accId);
        insert arceAnalysis;

        final arce__Account_has_Analysis__c accHasAn = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceAnalysis.Id, groupAccount.accId, null);
        insert accHasAn;
    }

    /**
    * @description Validates genAuditAttr with 4 params returns a correctly populated map.
    */
    @isTest static void testGenAuditAttrFourParams() {
        Test.startTest();
        final Map<String, String> result = Arc_Gen_Traceability.genAuditAttr('Title', 'approve', 'Comments', 'AnalysisId');
        Test.stopTest();

        Assert.isTrue(
            'Title' == result.get('title') && 'approve' == result.get('style') &&
            'Comments' == result.get('comments') && 'AnalysisId' == result.get('analysisId') &&
            'Arc_Gen_Traceability' == result.get('actionAuditType'),
            'All genAuditAttr fields should be correctly populated'
        );
    }

    /**
    * @description Validates genAuditAttr with 5 params sets custom actionAuditType.
    */
    @isTest static void testGenAuditAttrFiveParams() {
        Test.startTest();
        final Map<String, String> result = Arc_Gen_Traceability.genAuditAttr('Title', 'sanction', 'Comments', 'AId', 'CustomType');
        Test.stopTest();

        Assert.areEqual('CustomType', result.get('actionAuditType'), 'actionAuditType should match custom value');
    }

    /**
    * @description Validates genAuditDetailAttr returns a map with content, format, and display info.
    */
    @isTest static void testGenAuditDetailAttr() {
        Test.startTest();
        final Map<String, String> result = Arc_Gen_Traceability.genAuditDetailAttr('content', '1', 'Title', 'Embedded');
        Test.stopTest();

        Assert.isTrue(
            'content' == result.get('content') && 'HTML' == result.get('contentFormat') &&
            '1' == result.get('displayOrder') && 'Embedded' == result.get('displayType'),
            'All genAuditDetailAttr fields should be correctly populated'
        );
    }

    /**
    * @description Validates createTrace returns an audit record with the expected name.
    */
    @isTest static void testCreateTraceReturnsRecord() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr('Test Title', 'approve', 'Test Comment', analysis.Id);
        final Map<String, String> addInfo = new Map<String, String>{
            'ambit' => '1',
            'stage' => '2',
            'status' => '3',
            'action' => 'testAction'
        };

        Test.startTest();
        final dwp_cvad__Action_Audit__c result = Arc_Gen_Traceability.createTrace(analysis.Id, auditAttr, addInfo);
        Test.stopTest();

        Assert.isTrue(result != null && 'Test Title' == result.dwp_cvad__action_audit_name__c, 'createTrace should return a record with the expected name');
    }

    /**
    * @description Validates buildTraceEvent returns a record without inserting it.
    */
    @isTest static void testBuildTraceEventUninserted() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr('Build Title', 'sanction', 'Build Comment', analysis.Id);
        final Map<String, String> addInfo = new Map<String, String>();

        Test.startTest();
        final dwp_cvad__Action_Audit__c result = Arc_Gen_Traceability.buildTraceEvent(analysis.Id, auditAttr, addInfo);
        Test.stopTest();

        Assert.isTrue(result != null && result.Id == null, 'buildTraceEvent should return a non-null uninserted record');
    }

    /**
    * @description Validates saveTrace inserts and returns a record with a valid Id.
    */
    @isTest static void testSaveTraceInsertsRecord() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr('Save Title', 'propose', 'Save Comment', analysis.Id);
        final Map<String, String> addInfo = new Map<String, String>();

        Test.startTest();
        final dwp_cvad__Action_Audit__c result = Arc_Gen_Traceability.saveTrace(analysis.Id, auditAttr, addInfo);
        Test.stopTest();

        Assert.isNotNull(result.Id, 'saveTrace should insert and return record with Id');
    }

    /**
    * @description Validates createTraceDetail returns a detail record linked to the audit.
    */
    @isTest static void testCreateTraceDetailReturnsRecord() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr('Title', 'approve', 'Comment', analysis.Id);
        final dwp_cvad__Action_Audit__c audit = Arc_Gen_Traceability.saveTrace(analysis.Id, auditAttr, new Map<String, String>());

        final Map<String, String> detailAttr = Arc_Gen_Traceability.genAuditDetailAttr('Detail content', '1', 'Detail Title', 'Embedded');

        Test.startTest();
        final dwp_cvad__Action_Audit_Detail__c result = Arc_Gen_Traceability.createTraceDetail(audit.Id, detailAttr);
        Test.stopTest();

        Assert.isTrue(result != null && audit.Id == result.dwp_cvad__action_audit_id__c, 'createTraceDetail should return a record linked to the audit');
    }

    /**
    * @description Validates saveTraceDetail inserts and returns a detail record with a valid Id.
    */
    @isTest static void testSaveTraceDetailInsertsRecord() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr('Title', 'approve', 'Comment', analysis.Id);
        final dwp_cvad__Action_Audit__c audit = Arc_Gen_Traceability.saveTrace(analysis.Id, auditAttr, new Map<String, String>());

        final Map<String, String> detailAttr = Arc_Gen_Traceability.genAuditDetailAttr('Detail content', '1', 'Detail Title', 'Link');

        Test.startTest();
        final dwp_cvad__Action_Audit_Detail__c result = Arc_Gen_Traceability.saveTraceDetail(audit.Id, detailAttr);
        Test.stopTest();

        Assert.isNotNull(result.Id, 'saveTraceDetail should insert and return record with Id');
    }
}