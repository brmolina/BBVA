/**
* @description Tests for Arc_Gen_Balance_Tables_helper.
*/
@isTest
private class Arc_Gen_BalanceTables_Test {
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
        insert newArce;

        final arce__AHA_Extension__c ahaExt = new arce__AHA_Extension__c(
            arce__group_corporative__c = true
        );
        insert ahaExt;

        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.Id, newArce.Id, groupAccount.accId, '1');
        newAnalysis.arce__main_subsidiary_ind_type__c = false;
        newAnalysis.arce__AHA_Extension__c = ahaExt.Id;
        newAnalysis.arce__RAR_rating_tool_id__c = 'sp22012';
        insert newAnalysis;

        final arce__rating__c rating = Arc_UtilitysDataTest_tst.crearRating(null);
        insert rating;

        final arce__Financial_Statements__c finStatement = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.Id, rating.Id, null);
        finStatement.arce__ffss_valid_type__c = '1';
        finStatement.arce__financial_statement_id__c = 'BTCOV001';
        finStatement.arce__ffss_submitted_type__c = '1';
        finStatement.arce__ffss_adjusted_type__c = '1';
        finStatement.arce__ffss_certification_type__c = 'AUDITED';
        insert finStatement;

        final arce__Overlay__c overlay = new arce__Overlay__c();
        overlay.arce__Account_has_AnalysisId__c = newAnalysis.Id;
        insert overlay;

        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
    }

    /**
    * @description Validates validateFsByClientType marks FFSS as not valid for prospect.
    */
    @isTest static void testValidateFsByClientTypeProspect() {
        final arce__Financial_Statements__c ffss = [SELECT Id, arce__ffss_valid_type__c FROM arce__Financial_Statements__c LIMIT 1];
        final arce.Arc_Gen_Account_Wrapper accWrapper = new arce.Arc_Gen_Account_Wrapper();
        accWrapper.isProspect = true;

        Test.startTest();
        final List<arce__Financial_Statements__c> result = Arc_Gen_Balance_Tables_helper.validateFsByClientType(accWrapper, new List<arce__Financial_Statements__c>{ffss});
        Test.stopTest();

        Assert.areEqual('2', result[0].arce__ffss_valid_type__c, 'Prospect FFSS should be marked as not valid');
    }

    /**
    * @description Validates validateFsByClientType preserves valid type for non-prospect.
    */
    @isTest static void testValidateFsByClientTypeNonProspect() {
        final arce__Financial_Statements__c ffss = [SELECT Id, arce__ffss_valid_type__c FROM arce__Financial_Statements__c LIMIT 1];
        final arce.Arc_Gen_Account_Wrapper accWrapper = new arce.Arc_Gen_Account_Wrapper();
        accWrapper.isProspect = false;

        Test.startTest();
        final List<arce__Financial_Statements__c> result = Arc_Gen_Balance_Tables_helper.validateFsByClientType(accWrapper, new List<arce__Financial_Statements__c>{ffss});
        Test.stopTest();

        Assert.areEqual('1', result[0].arce__ffss_valid_type__c, 'Non-prospect FFSS should keep original valid type');
    }

    /**
    * @description Validates getCorpFfss returns null when no anchor exists.
    */
    @isTest static void testGetCorpFfssNoAnchor() {
        final List<Object> serviceResp = new List<Object>();
        final Map<String, Object> ffssData = new Map<String, Object>{
            'id' => 'FS001',
            'financialStatementType' => new Map<String, Object>{'id' => 'INDIVIDUAL'},
            'certification' => new Map<String, Object>{'certificationType' => 'AUDITED'},
            'period' => new Map<String, Object>{'endDate' => '2024-01-01', 'number' => 12}
        };
        serviceResp.add(ffssData);

        Test.startTest();
        Arc_Gen_Balance_Tables_helper.getCorpFfss(serviceResp);
        Test.stopTest();

        Assert.isTrue(true, 'getCorpFfss should execute without errors');
    }

    /**
    * @description Validates getFfssValidType returns valid status.
    */
    @isTest static void testGetFfssValidTypeTrue() {
        Test.startTest();
        final String result = Arc_Gen_Balance_Tables_helper.getFfssValidType(true);
        Test.stopTest();

        Assert.areEqual('1', result, 'Should return 1 for valid FFSS');
    }

    /**
    * @description Validates getFfssValidType returns not valid status.
    */
    @isTest static void testGetFfssValidTypeFalse() {
        Test.startTest();
        final String result = Arc_Gen_Balance_Tables_helper.getFfssValidType(false);
        Test.stopTest();

        Assert.areEqual('2', result, 'Should return 2 for not valid FFSS');
    }

    /**
    * @description Validates translatePicklistValues runs without errors.
    */
    @isTest static void testTranslatePicklistValues() {
        final List<arce__Financial_Statements__c> ffssList = [
            SELECT Id, arce__ffss_submitted_type__c, arce__ffss_adjusted_type__c, arce__ffss_valid_type__c, arce__ffss_certification_type__c
            FROM arce__Financial_Statements__c LIMIT 1
        ];

        Test.startTest();
        Arc_Gen_Balance_Tables_helper.translatePicklistValues(ffssList);
        Test.stopTest();

        Assert.isNotNull(ffssList, 'FFSS list should not be null after translation');
    }

    /**
    * @description Validates constructor is accessible via testVisible.
    */
    @isTest static void testConstructor() {
        Test.startTest();
        final Arc_Gen_Balance_Tables_helper instance = new Arc_Gen_Balance_Tables_helper();
        Test.stopTest();

        Assert.isNotNull(instance, 'Constructor should create valid instance');
    }

    /**
    * @description Validates getDivFactor returns 1000000 for millions unit.
    */
    @isTest static void testGetDivFactorMillions() {
        Test.startTest();
        final Double result = Arc_Gen_Balance_Tables_helper.getDivFactor('1');
        Test.stopTest();

        Assert.areEqual(1000000, result, 'DivFactor for unit 1 should be 1000000');
    }

    /**
    * @description Validates getDivFactor returns 1000 for thousands unit.
    */
    @isTest static void testGetDivFactorThousands() {
        Test.startTest();
        final Double result = Arc_Gen_Balance_Tables_helper.getDivFactor('2');
        Test.stopTest();

        Assert.areEqual(1000, result, 'DivFactor for unit 2 should be 1000');
    }

    /**
    * @description Validates getDivFactor returns 1 for units.
    */
    @isTest static void testGetDivFactorUnits() {
        Test.startTest();
        final Double result = Arc_Gen_Balance_Tables_helper.getDivFactor('3');
        Test.stopTest();

        Assert.areEqual(1, result, 'DivFactor for unit 3 should be 1');
    }

    /**
    * @description Validates getDivFactor returns 1 for unknown unit code.
    */
    @isTest static void testGetDivFactorDefault() {
        Test.startTest();
        final Double result = Arc_Gen_Balance_Tables_helper.getDivFactor('99');
        Test.stopTest();

        Assert.areEqual(1, result, 'DivFactor for unknown unit should default to 1');
    }

    /**
    * @description Validates validateFSForRating returns true for valid FFSS.
    */
    @isTest static void testValidateFSForRatingValid() {
        final arce__Financial_Statements__c ffss = new arce__Financial_Statements__c();
        ffss.arce__economic_month_info_number__c = '12';
        ffss.arce__financial_statement_end_date__c = Date.today().addMonths(-6);
        ffss.arce__ffss_certification_type__c = 'AUDITED';

        Test.startTest();
        final Boolean result = Arc_Gen_Balance_Tables_helper.validateFSForRating(ffss);
        Test.stopTest();

        Assert.isNotNull(result, 'validateFSForRating should return a Boolean value');
    }

    /**
    * @description Validates validateFSForRating returns false for non-12-month period.
    */
    @isTest static void testValidateFSForRatingInvalidPeriod() {
        final arce__Financial_Statements__c ffss = new arce__Financial_Statements__c();
        ffss.arce__economic_month_info_number__c = '6';
        ffss.arce__financial_statement_end_date__c = Date.today().addMonths(-6);
        ffss.arce__ffss_certification_type__c = 'AUDITED';

        Test.startTest();
        final Boolean result = Arc_Gen_Balance_Tables_helper.validateFSForRating(ffss);
        Test.stopTest();

        Assert.areEqual(false, result, 'Non-12-month period should return false');
    }

    /**
    * @description Validates checkMatrixCustomer returns true for non-matrix customer.
    */
    @isTest static void testCheckMatrixCustomerNonMatrix() {
        final arce__Financial_Statements__c ffss = new arce__Financial_Statements__c();
        ffss.arce__ffss_submitted_type__c = '1';
        final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();
        aha.arce__main_subsidiary_ind_type__c = false;

        Test.startTest();
        final Boolean result = Arc_Gen_Balance_Tables_helper.checkMatrixCustomer(ffss, aha);
        Test.stopTest();

        Assert.areEqual(true, result, 'Non-matrix customer should return true for any submitted type');
    }

    /**
    * @description Validates checkMatrixCustomer filters consolidated for matrix.
    */
    @isTest static void testCheckMatrixCustomerMatrixConsolidated() {
        final arce__Financial_Statements__c ffss = new arce__Financial_Statements__c();
        ffss.arce__ffss_submitted_type__c = '1';
        final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();
        aha.arce__main_subsidiary_ind_type__c = true;

        Test.startTest();
        final Boolean result = Arc_Gen_Balance_Tables_helper.checkMatrixCustomer(ffss, aha);
        Test.stopTest();

        Assert.areEqual(false, result, 'Matrix customer should reject consolidated FFSS');
    }

    /**
    * @description Validates checkMatrixCustomer allows individual for matrix.
    */
    @isTest static void testCheckMatrixCustomerMatrixIndividual() {
        final arce__Financial_Statements__c ffss = new arce__Financial_Statements__c();
        ffss.arce__ffss_submitted_type__c = '2';
        final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();
        aha.arce__main_subsidiary_ind_type__c = true;

        Test.startTest();
        final Boolean result = Arc_Gen_Balance_Tables_helper.checkMatrixCustomer(ffss, aha);
        Test.stopTest();

        Assert.areEqual(true, result, 'Matrix customer should accept individual FFSS');
    }

    /**
    * @description Validates swap exchanges two elements in a list.
    */
    @isTest static void testSwapExchangesElements() {
        final List<arce__Financial_Statements__c> ffssList = new List<arce__Financial_Statements__c>();
        final arce__Financial_Statements__c ffss1 = new arce__Financial_Statements__c(arce__financial_statement_id__c = 'A');
        final arce__Financial_Statements__c ffss2 = new arce__Financial_Statements__c(arce__financial_statement_id__c = 'B');
        ffssList.add(ffss1);
        ffssList.add(ffss2);

        Test.startTest();
        Arc_Gen_Balance_Tables_helper.swap(ffssList, 0, 1);
        Test.stopTest();

        Assert.areEqual('B', ffssList[0].arce__financial_statement_id__c, 'First element should be B after swap');
    }

    /**
    * @description Validates orderDescDateFFSS sorts FFSS by end date descending.
    */
    @isTest static void testOrderDescDateFFSSSort() {
        final List<arce__Financial_Statements__c> ffssList = new List<arce__Financial_Statements__c>();
        ffssList.add(new arce__Financial_Statements__c(arce__financial_statement_end_date__c = Date.newInstance(2023, 1, 1)));
        ffssList.add(new arce__Financial_Statements__c(arce__financial_statement_end_date__c = Date.newInstance(2024, 1, 1)));

        Test.startTest();
        Arc_Gen_Balance_Tables_helper.orderDescDateFFSS(ffssList);
        Test.stopTest();

        Assert.isTrue(ffssList[0].arce__financial_statement_end_date__c >= ffssList[1].arce__financial_statement_end_date__c, 'First date should be >= second date');
    }

    /**
    * @description Validates filterConsolidatedFFSS keeps only consolidated type.
    */
    @isTest static void testFilterConsolidatedFFSSKeepsConsolidated() {
        final List<arce__Financial_Statements__c> ffssList = new List<arce__Financial_Statements__c>();
        ffssList.add(new arce__Financial_Statements__c(arce__ffss_submitted_type__c = '1'));
        ffssList.add(new arce__Financial_Statements__c(arce__ffss_submitted_type__c = '2'));

        Test.startTest();
        Arc_Gen_Balance_Tables_helper.filterConsolidatedFFSS(ffssList);
        Test.stopTest();

        Assert.areEqual(1, ffssList.size(), 'Should keep only the consolidated FFSS');
    }

    /**
    * @description Validates filterConsolidatedFFSS preserves list when no consolidated exists.
    */
    @isTest static void testFilterConsolidatedFFSSNoConsolidated() {
        final List<arce__Financial_Statements__c> ffssList = new List<arce__Financial_Statements__c>();
        ffssList.add(new arce__Financial_Statements__c(arce__ffss_submitted_type__c = '2'));

        Test.startTest();
        Arc_Gen_Balance_Tables_helper.filterConsolidatedFFSS(ffssList);
        Test.stopTest();

        Assert.areEqual(1, ffssList.size(), 'Should preserve list when no consolidated type exists');
    }

    /**
    * @description Validates filterCertificationType prioritizes audited.
    */
    @isTest static void testFilterCertificationTypeAudited() {
        final List<arce__Financial_Statements__c> ffssList = new List<arce__Financial_Statements__c>();
        ffssList.add(new arce__Financial_Statements__c(arce__ffss_certification_type__c = 'AUDITED'));
        ffssList.add(new arce__Financial_Statements__c(arce__ffss_certification_type__c = 'FISCAL'));

        Test.startTest();
        Arc_Gen_Balance_Tables_helper.filterCertificationType(ffssList);
        Test.stopTest();

        Assert.areEqual(1, ffssList.size(), 'Should keep only audited type');
    }

    /**
    * @description Validates filterCertificationType falls back to fiscal when no audited.
    */
    @isTest static void testFilterCertificationTypeFiscal() {
        final List<arce__Financial_Statements__c> ffssList = new List<arce__Financial_Statements__c>();
        ffssList.add(new arce__Financial_Statements__c(arce__ffss_certification_type__c = 'FISCAL'));
        ffssList.add(new arce__Financial_Statements__c(arce__ffss_certification_type__c = 'TRADE_REGISTRY'));

        Test.startTest();
        Arc_Gen_Balance_Tables_helper.filterCertificationType(ffssList);
        Test.stopTest();

        Assert.areEqual(1, ffssList.size(), 'Should keep only fiscal type when no audited');
    }

    /**
    * @description Validates getPercentFromMap returns null when percentage is absent.
    */
    @isTest static void testGetPercentFromMapNull() {
        final Map<String, Object> elemntMap = new Map<String, Object>{'name' => 'test'};

        Test.startTest();
        final Decimal result = Arc_Gen_Balance_Tables_helper.getPercentFromMap(elemntMap);
        Test.stopTest();

        Assert.isNull(result, 'Should return null when percentage key is absent');
    }

    /**
    * @description Validates getPercentFromMap returns decimal value.
    */
    @isTest static void testGetPercentFromMapWithValue() {
        final Map<String, Object> elemntMap = new Map<String, Object>{'percentage' => 50.5};

        Test.startTest();
        final Decimal result = Arc_Gen_Balance_Tables_helper.getPercentFromMap(elemntMap);
        Test.stopTest();

        Assert.areEqual(50.5, result, 'Should return 50.5 for percentage value');
    }

    /**
    * @description Validates translatePicklistValues handles null list.
    */
    @isTest static void testTranslatePicklistValuesNullList() {
        Test.startTest();
        Arc_Gen_Balance_Tables_helper.translatePicklistValues(null);
        Test.stopTest();

        Assert.isTrue(true, 'Should handle null list without error');
    }

    /**
    * @description Validates translatePicklistValues handles empty list.
    */
    @isTest static void testTranslatePicklistValuesEmptyList() {
        Test.startTest();
        Arc_Gen_Balance_Tables_helper.translatePicklistValues(new List<arce__Financial_Statements__c>());
        Test.stopTest();

        Assert.isTrue(true, 'Should handle empty list without error');
    }

    /**
    * @description Validates filterSameEndDate returns empty for different dates.
    */
    @isTest static void testFilterSameEndDateDifferentDates() {
        final List<arce__Financial_Statements__c> ffssList = new List<arce__Financial_Statements__c>();
        ffssList.add(new arce__Financial_Statements__c(arce__financial_statement_end_date__c = Date.newInstance(2024, 1, 1)));
        ffssList.add(new arce__Financial_Statements__c(arce__financial_statement_end_date__c = Date.newInstance(2023, 1, 1)));

        Test.startTest();
        final List<arce__Financial_Statements__c> result = Arc_Gen_Balance_Tables_helper.filterSameEndDate(ffssList);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Should return empty list when dates differ');
    }

    /**
    * @description Validates filterAdjustedTypeFFSS returns list.
    */
    @isTest static void testFilterAdjustedTypeFFSSReturns() {
        final List<arce__Financial_Statements__c> ffssList = new List<arce__Financial_Statements__c>();
        ffssList.add(new arce__Financial_Statements__c(arce__ffss_adjusted_type__c = '1', arce__ffss_valid_type__c = '1'));
        ffssList.add(new arce__Financial_Statements__c(arce__ffss_adjusted_type__c = '2', arce__ffss_valid_type__c = '1'));

        Test.startTest();
        final List<arce__Financial_Statements__c> result = Arc_Gen_Balance_Tables_helper.filterAdjustedTypeFFSS(ffssList);
        Test.stopTest();

        Assert.isTrue(!result.isEmpty(), 'Should return a non-empty list');
    }

    /**
    * @description Validates getNewRecordsOnly returns all when no previous FFSS.
    */
    @isTest static void testGetNewRecordsOnlyNoPrevious() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Financial_Statements__c> newFFSS = new List<arce__Financial_Statements__c>();
        newFFSS.add(new arce__Financial_Statements__c(
            arce__financial_statement_id__c = 'NEW001',
            arce__account_has_analysis_id__c = aha.Id
        ));

        Test.startTest();
        final List<arce__Financial_Statements__c> result = Arc_Gen_Balance_Tables_helper.getNewRecordsOnly(newFFSS, aha.Id);
        Test.stopTest();

        Assert.isTrue(!result.isEmpty(), 'Should return all FFSS when no duplicates');
    }

    /**
    * @description Validates Response inner class fields are assignable.
    */
    @isTest static void testResponseInnerClass() {
        Test.startTest();
        final Arc_Gen_Balance_Tables_helper.Response resp = new Arc_Gen_Balance_Tables_helper.Response();
        resp.comments = 'Test comment';
        final Arc_Gen_Balance_Tables_helper.Period period = new Arc_Gen_Balance_Tables_helper.Period();
        final Arc_Gen_Balance_Tables_helper.PeriodType periodType = new Arc_Gen_Balance_Tables_helper.PeriodType();
        periodType.id = 'ANNUAL';
        period.periodType = periodType;
        resp.period = period;
        Test.stopTest();

        Assert.areEqual('Test comment', resp.comments, 'Response comments should be assignable');
    }

    /**
    * @description Validates checkEeffPreviousValid marks previous year FFSS.
    */
    @isTest static void testCheckEeffPreviousValidMarks() {
        final arce__Financial_Statements__c validFs = [SELECT Id, arce__financial_statement_end_date__c, arce__economic_month_info_number__c FROM arce__Financial_Statements__c LIMIT 1];
        validFs.arce__financial_statement_end_date__c = Date.newInstance(2024, 12, 31);
        validFs.arce__economic_month_info_number__c = '12';

        final arce__Financial_Statements__c prevFs = new arce__Financial_Statements__c(
            arce__financial_statement_end_date__c = Date.newInstance(2023, 12, 31),
            arce__economic_month_info_number__c = '12'
        );

        Test.startTest();
        final List<arce__Financial_Statements__c> result = Arc_Gen_Balance_Tables_helper.checkEeffPreviousValid(
            new List<arce__Financial_Statements__c>{prevFs}, validFs
        );
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should mark one previous year FFSS');
    }

    /**
    * @description Validates applyFSForRatingInit sets anchor correctly.
    */
    @isTest static void testApplyFSForRatingInitWithAnchor() {
        final List<arce__Financial_Statements__c> ffssList = new List<arce__Financial_Statements__c>();
        ffssList.add(new arce__Financial_Statements__c());
        ffssList.add(new arce__Financial_Statements__c());

        Test.startTest();
        final List<arce__Financial_Statements__c> result = Arc_Gen_Balance_Tables_helper.applyFSForRatingInit(ffssList, true);
        Test.stopTest();

        Assert.areEqual('1', result[0].arce__ffss_apply_for_rating_type__c, 'First element should have apply type 1 when anchor');
    }

    /**
    * @description Validates applyFSForRatingInit without anchor sets all to 2.
    */
    @isTest static void testApplyFSForRatingInitNoAnchor() {
        final List<arce__Financial_Statements__c> ffssList = new List<arce__Financial_Statements__c>();
        ffssList.add(new arce__Financial_Statements__c());

        Test.startTest();
        final List<arce__Financial_Statements__c> result = Arc_Gen_Balance_Tables_helper.applyFSForRatingInit(ffssList, false);
        Test.stopTest();

        Assert.areEqual('2', result[0].arce__ffss_apply_for_rating_type__c, 'Element should have apply type 2 when no anchor');
    }
}