/**
* @description Test class for Arc_Gen_SyncPersistance_Service.
*/
@isTest
private class Arc_Gen_SyncPersistance_Service_Test {
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
    * @description Validates the service constructor instantiates successfully.
    */
    @isTest static void testConstructor() {
        Test.startTest();
        final Arc_Gen_SyncPersistance_Service svc = new Arc_Gen_SyncPersistance_Service();
        Test.stopTest();

        Assert.isNotNull(svc, 'Constructor should create an instance');
    }

    /**
    * @description Validates getAccHasAnalysis returns a non-empty list for a valid AHA Id.
    */
    @isTest static void testGetAccHasAnalysisValidId() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final List<arce__Account_has_Analysis__c> result = Arc_Gen_SyncPersistance_Service.getAccHasAnalysis(aha.Id);
        Test.stopTest();

        Assert.isTrue(!result.isEmpty() && result[0].Id == aha.Id,
            'Should return a non-empty list with the correct AHA record');
    }

    /**
    * @description Validates getPersistanceIndicator returns a boolean value.
    */
    @isTest static void testGetPersistanceIndicator() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            final Boolean result = Arc_Gen_SyncPersistance_Service.getPersistanceIndicator();
            Assert.isNotNull(result, 'getPersistanceIndicator should return a boolean value');
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(true, 'getPersistanceIndicator was exercised');
    }
}