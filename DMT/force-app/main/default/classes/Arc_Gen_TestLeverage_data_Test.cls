/**
* @description Test class for Arc_Gen_TestLeverage_data.
*/
@isTest
private class Arc_Gen_TestLeverage_data_Test {
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
        aha.arce__ll_before_adj_ind_type__c = '1';
        aha.arce__ll_before_adj_clsfn_type__c = 'FS';
        aha.arce__ll_after_adj_ind_type__c = '1';
        aha.arce__ll_after_adj_clsfn_type__c = 'FS';
        insert aha;
    }

    /**
    * @description Validates SaveResult wrapper properties are accessible and store values correctly.
    */
    @isTest static void testSaveResultWrapper() {
        Test.startTest();
        final Arc_Gen_TestLeverage_data.SaveResult sr = new Arc_Gen_TestLeverage_data.SaveResult();
        sr.status = 'SUCCESS';
        sr.message = 'Test message';
        Test.stopTest();

        Assert.isTrue(sr.status == 'SUCCESS' && sr.message == 'Test message', 'SaveResult properties should store values correctly');
    }

    /**
    * @description Validates getAccountHasAnalysis returns a valid AHA record for a given Id.
    */
    @isTest static void testGetAccountHasAnalysisValidId() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_TestLeverage_data dataInstance = new Arc_Gen_TestLeverage_data();

        Test.startTest();
        final arce__Account_has_Analysis__c result = dataInstance.getAccountHasAnalysis(aha.Id);
        Test.stopTest();

        Assert.isTrue(result != null && result.Id == aha.Id, 'Should return a valid AHA record with the correct Id');
    }

    /**
    * @description Validates getLeveragedResults returns a valid AHA record with leveraged data.
    */
    @isTest static void testGetLeveragedResultsValidId() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_TestLeverage_data dataInstance = new Arc_Gen_TestLeverage_data();

        Test.startTest();
        final arce__Account_has_Analysis__c result = dataInstance.getLeveragedResults(aha.Id);
        Test.stopTest();

        Assert.isTrue(result != null && result.Id == aha.Id, 'Should return a valid AHA record with leveraged results and matching Id');
    }
}