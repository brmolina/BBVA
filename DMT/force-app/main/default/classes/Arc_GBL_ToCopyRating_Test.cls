/**
* @description Test class for Arc_GBL_ToCopyRating.
*/
@isTest
private class Arc_GBL_ToCopyRating_Test {
    /**
    * @description Make test data for test methods.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c arceAnalysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('arceAnalysis', null, groupAccount.accId);
        insert arceAnalysis;

        final arce__Account_has_Analysis__c headerAha = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceAnalysis.Id, groupAccount.accId, null);
        headerAha.arce__group_asset_header_type__c = '1';
        headerAha.arce__main_subsidiary_ind_type__c = false;
        headerAha.arce__InReview__c = false;
        headerAha.arce__anlys_wkfl_cnsld_ffss_type__c = '1';
        insert headerAha;

        final arce__Account_has_Analysis__c matrixAha = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceAnalysis.Id, groupAccount.accId, null);
        matrixAha.arce__group_asset_header_type__c = '2';
        matrixAha.arce__main_subsidiary_ind_type__c = true;
        matrixAha.arce__InReview__c = false;
        matrixAha.arce__anlys_wkfl_cnsld_ffss_type__c = '2';
        insert matrixAha;
    }

    /**
    * @description Validates getMatrix returns the matching AHA record.
    */
    @isTest static void testGetMatrixMatchingAha() {
        final List<arce__Account_has_Analysis__c> ahaList = [SELECT Id, arce__main_subsidiary_ind_type__c,
            arce__InReview__c, arce__anlys_wkfl_cnsld_ffss_type__c, arce__group_asset_header_type__c
            FROM arce__Account_has_Analysis__c];
        Id matrixId;
        for (arce__Account_has_Analysis__c aha : ahaList) {
            if (aha.arce__group_asset_header_type__c == '2') {
                matrixId = aha.Id;
            }
        }

        final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> wrappers = new List<arce.Arc_Gen_Account_Has_Analysis_Wrapper>();
        for (arce__Account_has_Analysis__c aha : ahaList) {
            final arce.Arc_Gen_Account_Has_Analysis_Wrapper wrp = new arce.Arc_Gen_Account_Has_Analysis_Wrapper();
            wrp.ahaObj = aha;
            wrappers.add(wrp);
        }

        final Arc_GBL_ToCopyRating toCopy = new Arc_GBL_ToCopyRating();

        Test.startTest();
        final arce__Account_has_Analysis__c result = toCopy.getMatrix(wrappers, matrixId);
        Test.stopTest();

        Assert.areEqual(matrixId, result.Id, 'Should return the matching matrix AHA');
    }

    /**
    * @description Validates getMatrix returns an empty AHA record when no match found.
    */
    @isTest static void testGetMatrixNoMatch() {
        final List<arce__Account_has_Analysis__c> ahaList = [SELECT Id, arce__main_subsidiary_ind_type__c,
            arce__InReview__c, arce__anlys_wkfl_cnsld_ffss_type__c, arce__group_asset_header_type__c
            FROM arce__Account_has_Analysis__c];

        final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> wrappers = new List<arce.Arc_Gen_Account_Has_Analysis_Wrapper>();
        for (arce__Account_has_Analysis__c aha : ahaList) {
            final arce.Arc_Gen_Account_Has_Analysis_Wrapper wrp = new arce.Arc_Gen_Account_Has_Analysis_Wrapper();
            wrp.ahaObj = aha;
            wrappers.add(wrp);
        }

        final Arc_GBL_ToCopyRating toCopy = new Arc_GBL_ToCopyRating();

        Test.startTest();
        final arce__Account_has_Analysis__c result = toCopy.getMatrix(wrappers, UserInfo.getUserId());
        Test.stopTest();

        Assert.areEqual(null, result.Id, 'Should return empty AHA when no match found');
    }

    /**
    * @description Validates getHeader returns the header AHA (group_asset_header = 1).
    */
    @isTest static void testGetHeaderGroupHeader() {
        final List<arce__Account_has_Analysis__c> ahaList = [SELECT Id, arce__group_asset_header_type__c,
            arce__main_subsidiary_ind_type__c, arce__InReview__c, arce__anlys_wkfl_cnsld_ffss_type__c
            FROM arce__Account_has_Analysis__c];

        Id headerId;
        final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> wrappers = new List<arce.Arc_Gen_Account_Has_Analysis_Wrapper>();
        for (arce__Account_has_Analysis__c aha : ahaList) {
            final arce.Arc_Gen_Account_Has_Analysis_Wrapper wrp = new arce.Arc_Gen_Account_Has_Analysis_Wrapper();
            wrp.ahaObj = aha;
            wrappers.add(wrp);
            if (aha.arce__group_asset_header_type__c == '1') {
                headerId = aha.Id;
            }
        }

        final Arc_GBL_ToCopyRating toCopy = new Arc_GBL_ToCopyRating();

        Test.startTest();
        final arce__Account_has_Analysis__c result = toCopy.getHeader(wrappers, ahaList[0].Id);
        Test.stopTest();

        Assert.areEqual(headerId, result.Id, 'Should return the header AHA (group_asset_header = 1)');
    }

    /**
    * @description Validates doCopy returns false when no rating data is available.
    */
    @isTest static void testDoCopyNoRating() {
        final arce__Account_has_Analysis__c matrix = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2' LIMIT 1];
        final arce__Account_has_Analysis__c header = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];

        final Arc_GBL_ToCopyRating toCopy = new Arc_GBL_ToCopyRating();

        Test.startTest();
        final Boolean result = toCopy.doCopy(matrix, header);
        Test.stopTest();

        Assert.areEqual(false, result, 'doCopy should return false when no rating data');
    }
}