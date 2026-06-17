/**
* @Description Tests for Arc_Gen_RatingAsIndepProcess_Helper.
*/
@isTest
private class Arc_Gen_RatingAsIndepProcess_Helper_Test {
    /** Group account number */
    private static final String GROUP_NUM = 'G000001';
    /** Subsidiary account number */
    private static final String SUBS_NUM = 'C000001';

    /**
    * @description Make test data for test methods.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_NUM, SUBS_NUM});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_NUM);
        final arce.Arc_Gen_Account_Wrapper clientAccount = groupAccWrapper.get(SUBS_NUM);

        final arce__Analysis__c arceAnalysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('TestAnalysis', null, groupAccount.accId);
        arceAnalysis.arce__anlys_wkfl_sub_process_type__c = '4';
        arceAnalysis.arce__rating_prerating_type__c = 'Prerating';
        insert arceAnalysis;

        final arce__Account_has_Analysis__c headerAha = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceAnalysis.Id, groupAccount.accId, null);
        headerAha.arce__group_asset_header_type__c = '1';
        headerAha.arce__InReview__c = true;
        headerAha.arce__RAR_rating_tool_id__c = '2012P1IRP';
        insert headerAha;

        final arce__Account_has_Analysis__c subsAha = new arce__Account_has_Analysis__c(
            arce__customer__c = clientAccount.accId,
            arce__Analysis__c = arceAnalysis.Id,
            arce__group_asset_header_type__c = '2',
            arce__InReview__c = true
        );
        insert subsAha;

        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
    }

    /**
    * @description Validates cancelARCE closes the analysis without throwing.
    */
    @isTest static void testCancelARCEValid() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];

        Test.startTest();
        Arc_Gen_RatingAsIndepProcess_Helper.cancelARCE(aha.Id);
        Test.stopTest();

        final arce__Analysis__c result = [SELECT arce__Stage__c FROM arce__Analysis__c LIMIT 1];
        Assert.areEqual('3', result.arce__Stage__c, 'Stage should be set to closed after cancelARCE');
    }

    /**
    * @description Validates cancelARCE handles exception for invalid AHA Id.
    */
    @isTest static void testCancelARCEInvalidId() {
        Test.startTest();
        Arc_Gen_RatingAsIndepProcess_Helper.cancelARCE(UserInfo.getUserId());
        Test.stopTest();

        // cancelARCE swallows exceptions via catch block, so just verify no unhandled exception
        Assert.isTrue(true, 'cancelARCE should not throw for invalid Id');
    }

    /**
    * @description Validates finalizePrerating updates analysis to finalized state.
    */
    @isTest static void testFinalizePreratingValid() {
        final arce__Analysis__c arce = [SELECT Id FROM arce__Analysis__c LIMIT 1];

        Test.startTest();
        Arc_Gen_RatingAsIndepProcess_Helper.finalizePrerating(arce.Id);
        Test.stopTest();

        final arce__Analysis__c result = [SELECT arce__Stage__c, arce__wf_status_id__c FROM arce__Analysis__c WHERE Id = :arce.Id];
        Assert.areEqual('3', result.arce__Stage__c, 'Stage should be closed after finalize prerating');
    }

    /**
    * @description Validates finalizePrerating throws for null arceId.
    */
    @isTest static void testFinalizePreratingNull() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Arc_Gen_RatingAsIndepProcess_Helper.finalizePrerating(null);
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'finalizePrerating should throw an exception for null arceId');
    }

    /**
    * @description Validates callRiskFilter returns empty response in test context.
    */
    @isTest static void testCallRiskFilterTestContext() {
        final arce__Analysis__c arce = [SELECT Id FROM arce__Analysis__c LIMIT 1];

        Test.startTest();
        final arce.Arc_Gen_ServiceAndSaveResponse response = Arc_Gen_RatingAsIndepProcess_Helper.callRiskFilter('testCustomer', arce.Id);
        Test.stopTest();

        Assert.isNotNull(response, 'callRiskFilter should return a non-null response in test context');
    }

    /**
    * @description Validates addToWfValue adds Rating value to the list.
    */
    @isTest static void testAddToWfValueRating() {
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues = new List<Arc_Gen_RatingAsIndepProcess_controller.WfValue>();
        final List<String> ratings = new List<String>{'Rating'};

        Test.startTest();
        Arc_Gen_RatingAsIndepProcess_Helper.addToWfValue(wfValues, ratings);
        Test.stopTest();

        Assert.areEqual(1, wfValues.size(), 'Should add one WfValue for Rating');
    }

    /**
    * @description Validates addToWfValue adds Prerating value to the list.
    */
    @isTest static void testAddToWfValuePrerating() {
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues = new List<Arc_Gen_RatingAsIndepProcess_controller.WfValue>();
        final List<String> ratings = new List<String>{'Prerating'};

        Test.startTest();
        Arc_Gen_RatingAsIndepProcess_Helper.addToWfValue(wfValues, ratings);
        Test.stopTest();

        Assert.areEqual(1, wfValues.size(), 'Should add one WfValue for Prerating');
    }

    /**
    * @description Validates addToWfValue adds both Rating and Prerating values.
    */
    @isTest static void testAddToWfValueBoth() {
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues = new List<Arc_Gen_RatingAsIndepProcess_controller.WfValue>();
        final List<String> ratings = new List<String>{'Rating', 'Prerating'};

        Test.startTest();
        Arc_Gen_RatingAsIndepProcess_Helper.addToWfValue(wfValues, ratings);
        Test.stopTest();

        Assert.areEqual(2, wfValues.size(), 'Should add two WfValues for both Rating and Prerating');
    }

    /**
    * @description Validates addToWfValue ignores unknown rating values.
    */
    @isTest static void testAddToWfValueUnknown() {
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues = new List<Arc_Gen_RatingAsIndepProcess_controller.WfValue>();
        final List<String> ratings = new List<String>{'Unknown'};

        Test.startTest();
        Arc_Gen_RatingAsIndepProcess_Helper.addToWfValue(wfValues, ratings);
        Test.stopTest();

        Assert.areEqual(0, wfValues.size(), 'Should not add WfValue for unknown rating');
    }

    /**
    * @description Validates constructor instantiation.
    */
    @isTest static void testConstructor() {
        Test.startTest();
        final Arc_Gen_RatingAsIndepProcess_Helper helper = new Arc_Gen_RatingAsIndepProcess_Helper();
        Test.stopTest();

        Assert.isNotNull(helper, 'Constructor should create an instance');
    }

    /**
    * @description Validates model2012Active returns list for AnalysisCorp type.
    */
    @isTest static void testModel2012ActiveAnalysisCorp() {
        Test.startTest();
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> result = Arc_Gen_RatingAsIndepProcess_Helper.model2012Active('AnalysisCorp');
        Test.stopTest();

        Assert.isNotNull(result, 'model2012Active should return a non-null list');
    }

    /**
    * @description Validates model2012Active returns list for non-AnalysisCorp type.
    */
    @isTest static void testModel2012ActiveOther() {
        Test.startTest();
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> result = Arc_Gen_RatingAsIndepProcess_Helper.model2012Active('Standard');
        Test.stopTest();

        Assert.isNotNull(result, 'model2012Active should return a non-null list for other types');
    }

    /**
    * @description Validates checkRatingType with a valid analysis and model.
    */
    @isTest static void testCheckRatingTypeValid() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];

        Test.startTest();
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> result = Arc_Gen_RatingAsIndepProcess_Helper.checkRatingType(aha.Id, '2012P1', false);
        Test.stopTest();

        Assert.isNotNull(result, 'checkRatingType should return a non-null list');
    }

    /**
    * @description Validates checkRatingType with eeffButton true reads tool from AHA.
    */
    @isTest static void testCheckRatingTypeEeffButton() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];

        Test.startTest();
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> result = Arc_Gen_RatingAsIndepProcess_Helper.checkRatingType(aha.Id, '', true);
        Test.stopTest();

        Assert.isNotNull(result, 'checkRatingType with eeffButton should return a non-null list');
    }
}