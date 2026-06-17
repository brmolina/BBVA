/**
* @description Test class for Arc_Gen_FinStatDetails_Service.
*/
@isTest
private class Arc_Gen_FinStatDetails_Service_Test {
    /**
    * @description Make test data for test methods.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> accWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = accWrapper.get('G000001');

        final arce__Analysis__c analysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('testAnalysis', null, groupAccount.accId);
        insert analysis;

        final arce__Account_has_Analysis__c aha = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, analysis.Id, groupAccount.accId, null);
        insert aha;

        final arce__rating__c rating = new arce__rating__c();
        insert rating;

        final arce__Financial_Statements__c ffss = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, aha.Id, rating.Id, null);
        ffss.arce__ffss_certification_type__c = 'AUDITED';
        insert ffss;
    }

    /**
    * @description Validates setNumberOfEmployees updates the employee count on the AHA record.
    */
    @isTest static void testSetNumberOfEmployeesValid() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        Arc_Gen_FinStatDetails_Service.setNumberOfEmployees(aha.Id, 250);
        Test.stopTest();

        final arce__Account_has_Analysis__c updated = [SELECT arce__employees_number__c FROM arce__Account_has_Analysis__c WHERE Id = :aha.Id];
        Assert.areEqual(250, updated.arce__employees_number__c, 'Employees number should be updated to 250');
    }

    /**
    * @description Validates setFFSSAuditData sets qualification to 1 when audited with qualification.
    */
    @isTest static void testSetFFSSAuditDataWithQualification() {
        final arce__Financial_Statements__c ffss = [SELECT Id, arce__ffss_certification_type__c FROM arce__Financial_Statements__c LIMIT 1];

        final Arc_Gen_ModalFinanStatemController.Audit auditData = new Arc_Gen_ModalFinanStatemController.Audit();
        auditData.auditor = new Arc_Gen_ModalFinanStatemController.Auditor();
        auditData.auditor.name = 'Test Auditor';
        auditData.auditor.opinion = 'Clean opinion';
        auditData.auditor.hasQualification = 'S';

        Test.startTest();
        Arc_Gen_FinStatDetails_Service.setFFSSAuditData(ffss, auditData);
        Test.stopTest();

        final arce__Financial_Statements__c updated = [SELECT arce__ffss_auditor_name__c, arce__ffss_auditor_qlfn_type__c FROM arce__Financial_Statements__c WHERE Id = :ffss.Id];
        Assert.isTrue(updated.arce__ffss_auditor_name__c == 'Test Auditor' && updated.arce__ffss_auditor_qlfn_type__c == '1',
            'Auditor name should be set and qualification should be 1 for audited with qualification');
    }

    /**
    * @description Validates setFFSSAuditData sets qualification to 2 when audited without qualification.
    */
    @isTest static void testSetFFSSAuditDataNoQualification() {
        final arce__Financial_Statements__c ffss = [SELECT Id, arce__ffss_certification_type__c FROM arce__Financial_Statements__c LIMIT 1];

        final Arc_Gen_ModalFinanStatemController.Audit auditData = new Arc_Gen_ModalFinanStatemController.Audit();
        auditData.auditor = new Arc_Gen_ModalFinanStatemController.Auditor();
        auditData.auditor.name = 'Test Auditor 2';
        auditData.auditor.opinion = 'Clean';
        auditData.auditor.hasQualification = 'N';

        Test.startTest();
        Arc_Gen_FinStatDetails_Service.setFFSSAuditData(ffss, auditData);
        Test.stopTest();

        final arce__Financial_Statements__c updated = [SELECT arce__ffss_auditor_qlfn_type__c FROM arce__Financial_Statements__c WHERE Id = :ffss.Id];
        Assert.areEqual('2', updated.arce__ffss_auditor_qlfn_type__c, 'Auditor qualification should be 2 for audited without qualification');
    }

    /**
    * @description Validates setFFSSAuditData handles null audit data gracefully.
    */
    @isTest static void testSetFFSSAuditDataNullInput() {
        final arce__Financial_Statements__c ffss = [SELECT Id, arce__ffss_certification_type__c FROM arce__Financial_Statements__c LIMIT 1];

        Test.startTest();
        Arc_Gen_FinStatDetails_Service.setFFSSAuditData(ffss, null);
        Test.stopTest();

        final arce__Financial_Statements__c updated = [SELECT arce__ffss_auditor_qlfn_type__c FROM arce__Financial_Statements__c WHERE Id = :ffss.Id];
        Assert.isNotNull(updated.arce__ffss_auditor_qlfn_type__c, 'Auditor qualification should be set even for null audit data');
    }
}