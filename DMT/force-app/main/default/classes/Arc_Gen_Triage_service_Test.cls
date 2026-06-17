/**
* @description Test class for Arc_Gen_Triage_service.
*/
@isTest
private class Arc_Gen_Triage_service_Test {
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
        accHasAn.arce__group_asset_header_type__c = '1';
        insert accHasAn;
    }

    /**
    * @description Validates service constants (ECONOMIC_PART, CALCULATION_REQUEST, etc.) are correct.
    */
    @isTest static void testConstantsCorrect() {
        Test.startTest();
        final String econPart = Arc_Gen_Triage_service.ECONOMIC_PART;
        final String calcReq = Arc_Gen_Triage_service.CALCULATION_REQUEST;
        final String svcName = Arc_Gen_Triage_service.SERVICENAME;
        final String bankId = Arc_Gen_Triage_service.BANKID;
        Test.stopTest();

        Assert.isTrue(
            'economicGroupParticipants' == econPart && 'calculationRequest' == calcReq &&
            'triageEngine' == svcName && '0001' == bankId,
            'All service constants should match their expected values'
        );
    }

    /**
    * @description Validates getAnalysisData returns analysis records for a valid Id.
    */
    @isTest static void testGetAnalysisDataValidId() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];

        Test.startTest();
        final List<arce__Analysis__c> result = Arc_Gen_Triage_service.getAnalysisData(analysis.Id);
        Test.stopTest();

        Assert.isTrue(!result.isEmpty() && analysis.Id == result[0].Id, 'Should return non-empty list with the correct analysis record');
    }
}