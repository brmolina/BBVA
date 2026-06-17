/**
* @Description Test class for Arc_Gen_TestLeverage_service.
*/
@isTest
private class Arc_Gen_TestLeverage_service_Test {
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
        accHasAn.arce__currency_id__c = 'EUR';
        accHasAn.arce__current_proposed_amount__c = 10000000;
        accHasAn.arce__employees_number__c = 500;
        accHasAn.arce__smes_eur_comuty_defn_type__c = '1';
        accHasAn.arce__magnitude_unit_type__c = '3';
        insert accHasAn;
    }

    /**
    * @description Validates validate1 returns true for a non-null input.
    */
    @isTest static void testValidate1NonNull() {
        Test.startTest();
        final Boolean result = Arc_Gen_TestLeverage_service.validate1('1');
        Test.stopTest();

        Assert.areEqual(true, result, 'validate1 should return true for non-null value');
    }

    /**
    * @description Validates validate1 returns false for null input.
    */
    @isTest static void testValidate1Null() {
        Test.startTest();
        final Boolean result = Arc_Gen_TestLeverage_service.validate1(null);
        Test.stopTest();

        Assert.areEqual(false, result, 'validate1 should return false for null value');
    }

    /**
    * @description Validates validate2 returns true for value '1'.
    */
    @isTest static void testValidate2One() {
        Test.startTest();
        final Boolean result = Arc_Gen_TestLeverage_service.validate2('1');
        Test.stopTest();

        Assert.areEqual(true, result, 'validate2 should return true for value 1');
    }

    /**
    * @description Validates validate2 returns false for value != '1'.
    */
    @isTest static void testValidate2Two() {
        Test.startTest();
        final Boolean result = Arc_Gen_TestLeverage_service.validate2('2');
        Test.stopTest();

        Assert.areEqual(false, result, 'validate2 should return false for value != 1');
    }

    /**
    * @description Validates validate3 returns gross financial debt for before adjustment.
    */
    @isTest static void testValidate3DebtBefore() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__gross_financial_debt_amount__c, arce__ll_adj_debt_amount__c,
            arce__ebitda_interest_number__c, arce__ll_adj_ebitda_amount__c FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final Double result = Arc_Gen_TestLeverage_service.validate3('debt', 'before', aha);
        Test.stopTest();

        Assert.areEqual(aha.arce__gross_financial_debt_amount__c, result, 'Should return gross financial debt for before');
    }

    /**
    * @description Validates validate3 returns adjusted EBITDA for after adjustment.
    */
    @isTest static void testValidate3EbitdaAfter() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__gross_financial_debt_amount__c, arce__ll_adj_debt_amount__c,
            arce__ebitda_interest_number__c, arce__ll_adj_ebitda_amount__c FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final Double result = Arc_Gen_TestLeverage_service.validate3('ebitda', 'after', aha);
        Test.stopTest();

        Assert.areEqual(aha.arce__ll_adj_ebitda_amount__c, result, 'Should return adjusted ebitda for after');
    }

    /**
    * @description Validates getValidRatings returns the expected set of valid rating codes.
    */
    @isTest static void testGetValidRatingsExpectedSet() {
        Test.startTest();
        final Set<String> ratings = Arc_Gen_TestLeverage_service.getValidRatings();
        Test.stopTest();

        Assert.isTrue(ratings.contains('AAA') && ratings.contains('BBB-'), 'Valid ratings should contain AAA and BBB-');
    }

    /**
    * @description Validates getDivFactor returns 1000000 for millions unit.
    */
    @isTest static void testGetDivFactorMillions() {
        Test.startTest();
        final Double result = Arc_Gen_TestLeverage_service.getDivFactor('1');
        Test.stopTest();

        Assert.areEqual(1000000, result, 'DivFactor for unit 1 should be 1000000');
    }

    /**
    * @description Validates getDivFactor returns 1000 for thousands unit.
    */
    @isTest static void testGetDivFactorThousands() {
        Test.startTest();
        final Double result = Arc_Gen_TestLeverage_service.getDivFactor('2');
        Test.stopTest();

        Assert.areEqual(1000, result, 'DivFactor for unit 2 should be 1000');
    }

    /**
    * @description Validates getDivFactor returns 1 for units.
    */
    @isTest static void testGetDivFactorUnits() {
        Test.startTest();
        final Double result = Arc_Gen_TestLeverage_service.getDivFactor('3');
        Test.stopTest();

        Assert.areEqual(1, result, 'DivFactor for unit 3 should be 1');
    }

    /**
    * @description Validates getDivFactor returns 1 for unknown unit codes.
    */
    @isTest static void testGetDivFactorDefault() {
        Test.startTest();
        final Double result = Arc_Gen_TestLeverage_service.getDivFactor('99');
        Test.stopTest();

        Assert.areEqual(1, result, 'DivFactor for unknown unit should default to 1');
    }

    /**
    * @description Validates leverageTestTrue sets before-adjustment indicator and classification.
    */
    @isTest static void testLeverageTestTrueBefore() {
        arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();

        Test.startTest();
        aha = Arc_Gen_TestLeverage_service.leverageTestTrue(aha, 'before', 'FS');
        Test.stopTest();

        Assert.isTrue('1' == aha.arce__ll_before_adj_ind_type__c && 'FS' == aha.arce__ll_before_adj_clsfn_type__c, 'Before adj indicator should be 1 and classification FS');
    }

    /**
    * @description Validates leverageTestTrue sets after-adjustment indicator and classification.
    */
    @isTest static void testLeverageTestTrueAfter() {
        arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();

        Test.startTest();
        aha = Arc_Gen_TestLeverage_service.leverageTestTrue(aha, 'after', 'R6');
        Test.stopTest();

        Assert.isTrue('1' == aha.arce__ll_after_adj_ind_type__c && 'R6' == aha.arce__ll_after_adj_clsfn_type__c, 'After adj indicator should be 1 and classification R6');
    }

    /**
    * @description Validates leverageTestFalse sets before-adjustment indicator to 2.
    */
    @isTest static void testLeverageTestFalseBefore() {
        arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();

        Test.startTest();
        aha = Arc_Gen_TestLeverage_service.leverageTestFalse(aha, 'before');
        Test.stopTest();

        Assert.isTrue('2' == aha.arce__ll_before_adj_ind_type__c && aha.arce__ll_before_adj_clsfn_type__c == null, 'Before adj indicator should be 2 and classification null');
    }

    /**
    * @description Validates leverageTestFalse sets after-adjustment indicator to 2.
    */
    @isTest static void testLeverageTestFalseAfter() {
        arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();

        Test.startTest();
        aha = Arc_Gen_TestLeverage_service.leverageTestFalse(aha, 'after');
        Test.stopTest();

        Assert.isTrue('2' == aha.arce__ll_after_adj_ind_type__c && aha.arce__ll_after_adj_clsfn_type__c == null, 'After adj indicator should be 2 and classification null');
    }

    /**
    * @description Validates clearTestLeveragedResults resets leverage fields on AHA record.
    */
    @isTest static void testClearLeveragedResults() {
        arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        aha.arce__ll_before_adj_ind_type__c = '1';
        aha.arce__ll_before_adj_clsfn_type__c = 'FS';
        update aha;

        Test.startTest();
        Arc_Gen_TestLeverage_service.clearTestLeveragedResults(aha.Id);
        Test.stopTest();

        final arce__Account_has_Analysis__c result = [SELECT arce__ll_before_adj_ind_type__c, arce__ll_before_adj_clsfn_type__c,
            arce__anlys_wkfl_sbanlys_status_type__c FROM arce__Account_has_Analysis__c WHERE Id = :aha.Id];
        Assert.isTrue(result.arce__ll_before_adj_ind_type__c == null && '1' == result.arce__anlys_wkfl_sbanlys_status_type__c, 'Should clear before adj indicator and reset status to 1');
    }

    /**
    * @description Validates clearTestLeveragedResultsAnalysis resets all AHAs for a given analysis.
    */
    @isTest static void testClearLeveragedResultsAnalysis() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__Analysis__c = :analysis.Id LIMIT 1];
        aha.arce__ll_after_adj_ind_type__c = '1';
        update aha;

        Test.startTest();
        Arc_Gen_TestLeverage_service.clearTestLeveragedResultsAnalysis(analysis.Id);
        Test.stopTest();

        final arce__Account_has_Analysis__c result = [SELECT arce__ll_after_adj_ind_type__c, arce__arce_ctmr_flag__c
            FROM arce__Account_has_Analysis__c WHERE Id = :aha.Id];
        Assert.isTrue(result.arce__ll_after_adj_ind_type__c == null && result.arce__arce_ctmr_flag__c == false, 'Should clear after adj indicator and customer flag');
    }

    /**
    * @description Validates setupLeverageVariables returns a correct wrapper for before adjustment.
    */
    @isTest static void testSetupLeverageVariablesBefore() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__currency_id__c,
            arce__ffss_for_rating_id__r.arce__rating_final__c, arce__employees_number__c,
            arce__current_proposed_amount__c, arce__Analysis__r.arce__controlled_by_sponsor_type__c,
            arce__smes_eur_comuty_defn_type__c, arce__gross_financial_debt_amount__c,
            arce__ebitda_interest_number__c, arce__ll_adj_debt_amount__c,
            arce__ll_adj_ebitda_amount__c, arce__magnitude_unit_type__c
            FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final Arc_Gen_TestLeverage_service.leverageVariables result =
            Arc_Gen_TestLeverage_service.setupLeverageVariables(aha, 'before', 1.0);
        Test.stopTest();

        Assert.isNotNull(result, 'setupLeverageVariables should return a non-null wrapper');
    }

    /**
    * @description Validates setupLeverageVariables returns a correct wrapper for after adjustment.
    */
    @isTest static void testSetupLeverageVariablesAfter() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__currency_id__c,
            arce__ffss_for_rating_id__r.arce__rating_final__c, arce__employees_number__c,
            arce__current_proposed_amount__c, arce__Analysis__r.arce__controlled_by_sponsor_type__c,
            arce__smes_eur_comuty_defn_type__c, arce__gross_financial_debt_amount__c,
            arce__ebitda_interest_number__c, arce__ll_adj_debt_amount__c,
            arce__ll_adj_ebitda_amount__c, arce__magnitude_unit_type__c
            FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final Arc_Gen_TestLeverage_service.leverageVariables result =
            Arc_Gen_TestLeverage_service.setupLeverageVariables(aha, 'after', 1.0);
        Test.stopTest();

        Assert.isNotNull(result, 'setupLeverageVariables should return a non-null wrapper for after');
    }

    /**
    * @description Validates calculateLeverage sets status to 3 when risk is below threshold.
    */
    @isTest static void testCalculateLeverageBelowRisk() {
        arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();
        final Arc_Gen_TestLeverage_service.leverageVariables leverage = new Arc_Gen_TestLeverage_service.leverageVariables();
        leverage.risk = 1.0;
        leverage.rating = 'BBB';
        leverage.financialSponsor = false;
        leverage.smeIndicator = false;
        leverage.debt = 100;
        leverage.ebitda = 50;
        leverage.debtOverEbitda = 2;
        leverage.calculateType = 'before';

        Test.startTest();
        aha = Arc_Gen_TestLeverage_service.calculateLeverage(leverage, aha);
        Test.stopTest();

        Assert.areEqual('2', aha.arce__ll_before_adj_ind_type__c, 'Risk below 5M should result in leverage test false');
    }

    /**
    * @description Validates calculateLeverage sets FS for valid rating and financial sponsor.
    */
    @isTest static void testCalculateLeverageFinancialSponsor() {
        arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();
        final Arc_Gen_TestLeverage_service.leverageVariables leverage = new Arc_Gen_TestLeverage_service.leverageVariables();
        leverage.risk = 10.0;
        leverage.rating = 'AAA';
        leverage.financialSponsor = true;
        leverage.smeIndicator = false;
        leverage.debt = 100;
        leverage.ebitda = 50;
        leverage.debtOverEbitda = 2;
        leverage.calculateType = 'before';

        Test.startTest();
        aha = Arc_Gen_TestLeverage_service.calculateLeverage(leverage, aha);
        Test.stopTest();

        Assert.areEqual('FS', aha.arce__ll_before_adj_clsfn_type__c, 'Financial sponsor with valid rating should classify as FS');
    }

    /**
    * @description Validates calculateLeverage for R6 classification with high debt/ebitda ratio.
    */
    @isTest static void testCalculateLeverageR6Classification() {
        arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();
        final Arc_Gen_TestLeverage_service.leverageVariables leverage = new Arc_Gen_TestLeverage_service.leverageVariables();
        leverage.risk = 10.0;
        leverage.rating = 'BB+';
        leverage.financialSponsor = false;
        leverage.smeIndicator = false;
        leverage.debt = 700;
        leverage.ebitda = 100;
        leverage.debtOverEbitda = 7;
        leverage.calculateType = 'after';

        Test.startTest();
        aha = Arc_Gen_TestLeverage_service.calculateLeverage(leverage, aha);
        Test.stopTest();

        Assert.areEqual('R6', aha.arce__ll_after_adj_clsfn_type__c, 'Debt/EBITDA > 6 should classify as R6');
    }

    /**
    * @description Validates calculateLeverage for R4 classification with moderate debt/ebitda ratio.
    */
    @isTest static void testCalculateLeverageR4Classification() {
        arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();
        final Arc_Gen_TestLeverage_service.leverageVariables leverage = new Arc_Gen_TestLeverage_service.leverageVariables();
        leverage.risk = 10.0;
        leverage.rating = 'BB+';
        leverage.financialSponsor = false;
        leverage.smeIndicator = false;
        leverage.debt = 500;
        leverage.ebitda = 100;
        leverage.debtOverEbitda = 5;
        leverage.calculateType = 'before';

        Test.startTest();
        aha = Arc_Gen_TestLeverage_service.calculateLeverage(leverage, aha);
        Test.stopTest();

        Assert.areEqual('R4', aha.arce__ll_before_adj_clsfn_type__c, 'Debt/EBITDA between 4 and 6 should classify as R4');
    }

    /**
    * @description Validates calculateLeverage for SME indicator bypass.
    */
    @isTest static void testCalculateLeverageSMEBypass() {
        arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();
        final Arc_Gen_TestLeverage_service.leverageVariables leverage = new Arc_Gen_TestLeverage_service.leverageVariables();
        leverage.risk = 10.0;
        leverage.rating = 'BB+';
        leverage.financialSponsor = false;
        leverage.smeIndicator = true;
        leverage.debt = 500;
        leverage.ebitda = 100;
        leverage.debtOverEbitda = 5;
        leverage.calculateType = 'before';

        Test.startTest();
        aha = Arc_Gen_TestLeverage_service.calculateLeverage(leverage, aha);
        Test.stopTest();

        Assert.areEqual('2', aha.arce__ll_before_adj_ind_type__c, 'SME should result in leverage test false');
    }

    /**
    * @description Validates validate3 returns debt for before adjustment.
    */
    @isTest static void testValidate3DebtAfter() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__gross_financial_debt_amount__c, arce__ll_adj_debt_amount__c,
            arce__ebitda_interest_number__c, arce__ll_adj_ebitda_amount__c FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final Double result = Arc_Gen_TestLeverage_service.validate3('debt', 'after', aha);
        Test.stopTest();

        Assert.areEqual(aha.arce__ll_adj_debt_amount__c, result, 'Should return adjusted debt for after');
    }

    /**
    * @description Validates validate3 returns ebitda for before adjustment.
    */
    @isTest static void testValidate3EbitdaBefore() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__gross_financial_debt_amount__c, arce__ll_adj_debt_amount__c,
            arce__ebitda_interest_number__c, arce__ll_adj_ebitda_amount__c FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final Double result = Arc_Gen_TestLeverage_service.validate3('ebitda', 'before', aha);
        Test.stopTest();

        Assert.areEqual(aha.arce__ebitda_interest_number__c, result, 'Should return ebitda for before');
    }

    /**
    * @description Validates leverageTestResponse wrapper fields are accessible.
    */
    @isTest static void testLeverageTestResponseWrapper() {
        Test.startTest();
        final Arc_Gen_TestLeverage_service.leverageTestResponse resp = new Arc_Gen_TestLeverage_service.leverageTestResponse();
        resp.status = 'true';
        resp.message = 'Success';
        resp.leveragedVariables = new List<String>{'1', 'FS', '2', ''};
        Test.stopTest();

        Assert.areEqual('true', resp.status, 'Status should be assignable');
    }

    /**
    * @description Validates leverageVariables wrapper fields are accessible.
    */
    @isTest static void testLeverageVariablesWrapper() {
        Test.startTest();
        final Arc_Gen_TestLeverage_service.leverageVariables vars = new Arc_Gen_TestLeverage_service.leverageVariables();
        vars.noEmployees = 100;
        vars.risk = 5000000;
        vars.rating = 'BBB+';
        vars.calculateType = 'before';
        Test.stopTest();

        Assert.areEqual('BBB+', vars.rating, 'Rating should be assignable');
    }

    /**
    * @description Validates setupLeverage returns a non-null response for a valid AHA Id.
    */
    @isTest static void testSetupLeverage() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final Arc_Gen_TestLeverage_service.leverageTestResponse response = Arc_Gen_TestLeverage_service.setupLeverage(aha.Id);
        Test.stopTest();

        Assert.isNotNull(response, 'setupLeverage should return a non-null response');
    }
}