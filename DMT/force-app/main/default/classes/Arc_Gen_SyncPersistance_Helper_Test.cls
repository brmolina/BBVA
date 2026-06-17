/**
* @description Test class for Arc_Gen_SyncPersistance_Helper.
*/
@isTest
private class Arc_Gen_SyncPersistance_Helper_Test {
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
    * @description Validates the helper constructor instantiates successfully.
    */
    @isTest static void testConstructor() {
        Test.startTest();
        final Arc_Gen_SyncPersistance_Helper helper = new Arc_Gen_SyncPersistance_Helper();
        Test.stopTest();

        Assert.isNotNull(helper, 'Constructor should create an instance');
    }

    /**
    * @description Validates processResponse wraps a valid service response correctly.
    */
    @isTest static void testProcessResponseValid() {
        final arce.Arc_Gen_getIASOResponse.ServiceResponse svcResp = new arce.Arc_Gen_getIASOResponse.ServiceResponse();
        svcResp.serviceCode = '200';
        svcResp.serviceMessage = 'Success';
        svcResp.serviceResponse = new Map<String, Object>{'key' => 'value'};

        Test.startTest();
        final arce.Arc_Gen_ServiceAndSaveResponse result = Arc_Gen_SyncPersistance_Helper.processResponse(svcResp);
        Test.stopTest();

        Assert.isTrue(result.serviceCode == '200' && result.serviceMessage == 'Success',
            'Service code should be 200 and message should be Success');
    }

    /**
    * @description Validates setEventType returns RENEWAL for subprocess 1.
    */
    @isTest static void testSetEventTypeRenewal() {
        Test.startTest();
        final String result = Arc_Gen_SyncPersistance_Helper.setEventType('1');
        Test.stopTest();

        Assert.areEqual('RENEWAL', result, 'Subprocess 1 should map to RENEWAL');
    }

    /**
    * @description Validates setEventType returns NEW for subprocess 2.
    */
    @isTest static void testSetEventTypeNew() {
        Test.startTest();
        final String result = Arc_Gen_SyncPersistance_Helper.setEventType('2');
        Test.stopTest();

        Assert.areEqual('NEW', result, 'Subprocess 2 should map to NEW');
    }

    /**
    * @description Validates setEventType returns EDIT for subprocess 3.
    */
    @isTest static void testSetEventTypeEdit() {
        Test.startTest();
        final String result = Arc_Gen_SyncPersistance_Helper.setEventType('3');
        Test.stopTest();

        Assert.areEqual('EDIT', result, 'Subprocess 3 should map to EDIT');
    }

    /**
    * @description Validates setEventType returns null for unknown subprocess.
    */
    @isTest static void testSetEventTypeUnknown() {
        Test.startTest();
        final String result = Arc_Gen_SyncPersistance_Helper.setEventType('99');
        Test.stopTest();

        Assert.areEqual(null, result, 'Unknown subprocess should return null');
    }

    /**
    * @description Validates ServiceParameters wrapper fields are accessible and assignable.
    */
    @isTest static void testServiceParametersFields() {
        Test.startTest();
        final Arc_Gen_SyncPersistance_Helper.ServiceParameters params = new Arc_Gen_SyncPersistance_Helper.ServiceParameters();
        params.riskAssessmentId = 'RA001';
        params.participantId = 'P001';
        params.relatedAssessment = 'RA002';
        params.eventType = 'RENEWAL';
        params.participantType = 'GROUP';
        Test.stopTest();

        Assert.isTrue(params.riskAssessmentId == 'RA001' && params.participantType == 'GROUP',
            'Fields should be set correctly');
    }

    /**
    * @description Validates updateStatus sets persistance status to 1 for success code.
    */
    @isTest static void testUpdateStatusSuccessCode() {
        final arce__Account_has_Analysis__c accHasAn = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        Arc_Gen_SyncPersistance_Helper.updateStatus('200', accHasAn.Id);
        Test.stopTest();

        final arce__Account_has_Analysis__c result = [SELECT arce__persistance_callback_status_type__c
            FROM arce__Account_has_Analysis__c WHERE Id = :accHasAn.Id];
        Assert.areEqual('1', result.arce__persistance_callback_status_type__c,
            'Persistance status should be set to 1 for success code');
    }
}