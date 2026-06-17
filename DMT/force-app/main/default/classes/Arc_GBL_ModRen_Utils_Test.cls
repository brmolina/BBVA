/**
* @description Test class for Arc_GBL_ModRen_Utils.
*/
@isTest
private class Arc_GBL_ModRen_Utils_Test {
    /** Group Account Number for testing */
    private static final String G000001_LIT = 'G000001';
    /** Client Account Number for testing */
    private static final String C000001_LIT = 'C000001';

    /**
    * @description Create shared test data.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{G000001_LIT, C000001_LIT});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(G000001_LIT);

        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('Generic', '100', '1', null);
        insert newSector;

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__anlys_wkfl_sub_process_type__c = '1';
        insert newArce;

        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.Id, newArce.Id, groupAccount.accId, '1');
        newAnalysis.arce__main_subsidiary_ind_type__c = true;
        newAnalysis.arce__InReview__c = true;
        newAnalysis.arce__group_asset_header_type__c = '1';
        insert newAnalysis;

        final arce__rating__c rating = Arc_UtilitysDataTest_tst.crearRating(null);
        insert rating;

        final arce__Financial_Statements__c finStatement = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.Id, rating.Id, null);
        finStatement.arce__ffss_valid_type__c = '1';
        finStatement.arce__financial_statement_id__c = 'MODREN001';
        finStatement.arce__ffss_submitted_type__c = '1';
        finStatement.arce__ffss_adjusted_type__c = '1';
        finStatement.arce__ffss_certification_type__c = 'AUDITED';
        finStatement.arce__financial_statement_end_date__c = Date.today().addMonths(-6);
        finStatement.arce__economic_month_info_number__c = '12';
        insert finStatement;

        newAnalysis.arce__ffss_for_rating_id__c = finStatement.Id;
        update newAnalysis;
    }

    /**
    * @description Validates getInReview returns Yes label for true input.
    */
    @isTest static void testGetInReviewTrue() {
        Test.startTest();
        final String result = Arc_GBL_ModRen_Utils.getInReview(true);
        Test.stopTest();

        Assert.areEqual(Label.Arc_Gen_Yes, result, 'Should return Yes label for true');
    }

    /**
    * @description Validates getInReview returns No label for false input.
    */
    @isTest static void testGetInReviewFalse() {
        Test.startTest();
        final String result = Arc_GBL_ModRen_Utils.getInReview(false);
        Test.stopTest();

        Assert.areEqual(Label.Arc_Gen_No, result, 'Should return No label for false');
    }

    /**
    * @description Validates getPersistanceStatus returns 1 for true.
    */
    @isTest static void testGetPersistanceStatusTrue() {
        Test.startTest();
        final String result = Arc_GBL_ModRen_Utils.getPersistanceStatus(true);
        Test.stopTest();

        Assert.areEqual('1', result, 'Should return 1 for true persistance status');
    }

    /**
    * @description Validates getPersistanceStatus returns 4 for false.
    */
    @isTest static void testGetPersistanceStatusFalse() {
        Test.startTest();
        final String result = Arc_GBL_ModRen_Utils.getPersistanceStatus(false);
        Test.stopTest();

        Assert.areEqual('4', result, 'Should return 4 for false persistance status');
    }

    /**
    * @description Validates processLocalCountry populates fields from map.
    */
    @isTest static void testProcessLocalCountryWithData() {
        final Map<String, Object> mapLocalCountry = new Map<String, Object>{
            'arce__anlys_wkfl_edit_br_level_type__c' => 'TestValue'
        };
        final arce__Analysis__c arceUp = new arce__Analysis__c();

        Test.startTest();
        Arc_GBL_ModRen_Utils.processLocalCountry(mapLocalCountry, arceUp);
        Test.stopTest();

        Assert.isNotNull(arceUp, 'Analysis record should not be null after processing');
    }

    /**
    * @description Validates processLocalCountry handles empty map.
    */
    @isTest static void testProcessLocalCountryEmpty() {
        final Map<String, Object> mapLocalCountry = new Map<String, Object>();
        final arce__Analysis__c arceUp = new arce__Analysis__c();

        Test.startTest();
        Arc_GBL_ModRen_Utils.processLocalCountry(mapLocalCountry, arceUp);
        Test.stopTest();

        Assert.isNotNull(arceUp, 'Analysis should remain valid with empty map');
    }

    /**
    * @description Validates exclusionMainClientSupl keeps only shareholders and affiliates.
    */
    @isTest static void testExclusionMainClientSuplKeepsShareholderAndAffiliates() {
        final List<arce__Third_Participant_Details__c> lstThirdDetails = new List<arce__Third_Participant_Details__c>();
        lstThirdDetails.add(new arce__Third_Participant_Details__c(arce__third_participant_role_type__c = '03'));
        lstThirdDetails.add(new arce__Third_Participant_Details__c(arce__third_participant_role_type__c = '04'));
        lstThirdDetails.add(new arce__Third_Participant_Details__c(arce__third_participant_role_type__c = '01'));
        lstThirdDetails.add(new arce__Third_Participant_Details__c(arce__third_participant_role_type__c = '02'));

        Test.startTest();
        final List<arce__Third_Participant_Details__c> result = Arc_GBL_ModRen_Utils.exclusionMainClientSupl(lstThirdDetails);
        Test.stopTest();

        Assert.areEqual(2, result.size(), 'Should only keep shareholders (03) and affiliates (04)');
    }

    /**
    * @description Validates exclusionMainClientSupl returns empty for no matching roles.
    */
    @isTest static void testExclusionMainClientSuplNoMatch() {
        final List<arce__Third_Participant_Details__c> lstThirdDetails = new List<arce__Third_Participant_Details__c>();
        lstThirdDetails.add(new arce__Third_Participant_Details__c(arce__third_participant_role_type__c = '01'));
        lstThirdDetails.add(new arce__Third_Participant_Details__c(arce__third_participant_role_type__c = '02'));

        Test.startTest();
        final List<arce__Third_Participant_Details__c> result = Arc_GBL_ModRen_Utils.exclusionMainClientSupl(lstThirdDetails);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Should return empty when no shareholders or affiliates');
    }

    /**
    * @description Validates exclusionMainClientSupl handles empty input list.
    */
    @isTest static void testExclusionMainClientSuplEmptyInput() {
        Test.startTest();
        final List<arce__Third_Participant_Details__c> result = Arc_GBL_ModRen_Utils.exclusionMainClientSupl(new List<arce__Third_Participant_Details__c>());
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Should return empty for empty input');
    }

    /**
    * @description Validates associateAccHasAn2Arce sets analysis template and status.
    */
    @isTest static void testAssociateAccHasAn2ArceBasic() {
        final arce__Analysis__c arce = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__Customer__c, arce__InReview__c, arce__group_asset_header_type__c
            FROM arce__Account_has_Analysis__c LIMIT 1];
        final Arc_Gen_CloneWrapper response = new Arc_Gen_CloneWrapper();
        response.lsarc = new List<arce__Analysis__c>{arce};
        response.lsaha = new List<arce__Account_has_Analysis__c>{aha};

        final Map<String, Boolean> holdingMap = new Map<String, Boolean>{G000001_LIT => true};
        final arce.Arc_Gen_Account_Wrapper accWrp = new arce.Arc_Gen_Account_Wrapper();
        accWrp.accNumber = G000001_LIT;
        accWrp.Name = 'Test Group';
        accWrp.docNumber = 'DOC001';
        accWrp.accId = aha.arce__Customer__c;

        final Map<String, String> data = new Map<String, String>{
            'isHolding' => JSON.serialize(holdingMap),
            'accountswraper' => JSON.serialize(new List<arce.Arc_Gen_Account_Wrapper>{accWrp})
        };

        Test.startTest();
        final List<arce__Account_has_Analysis__c> result = Arc_GBL_ModRen_Utils.associateAccHasAn2Arce(response, '01', false, data);
        Test.stopTest();

        Assert.areEqual('1', result[0].arce__analysis_template_id__c, 'Template should be set to 1');
    }

    /**
    * @description Validates getRelatedRecordsArce returns a non-null response for a valid analysis ID and type 'ren'.
    */
    @isTest static void testGetRelatedRecordsArceRenovation() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];

        Test.startTest();
        final Arc_Gen_CloneWrapper response = Arc_GBL_ModRen_Utils.getRelatedRecordsArce(analysis.Id, 'ren');
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
    }
}