/**
* @description Test class for Arc_Gen_AutoRetailTableInsert_Helper.
*/
@isTest
private class Arc_Gen_AutoRetailTableInsert_Test {
    /**
    * @description Make test data for test methods.
    */
    @testSetup
    static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c arceAnalysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('arceAnalysis', null, groupAccount.accId);
        insert arceAnalysis;

        final arce__Account_has_Analysis__c accHasAn = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceAnalysis.Id, groupAccount.accId, null);
        insert accHasAn;

        final arce__autoretail_behavior_table__c tableObj = new arce__autoretail_behavior_table__c(
            arce__account_has_analysis_id__c = accHasAn.Id,
            arce__gf_company_name__c         = 'SetDataCompany',
            arce__gf_vehicle_brand_name__c   = 'SetDataBrand',
            arce__gf_product_status_type__c  = '1'
        );
        insert tableObj;
    }

    /**
    * @description Validates the helper constructor instantiates successfully.
    */
    @isTest
    static void testConstructor() {
        Test.startTest();
        final Arc_Gen_AutoRetailTableInsert_Helper helper = new Arc_Gen_AutoRetailTableInsert_Helper();
        Test.stopTest();

        Assert.isNotNull(helper, 'Constructor should create an instance');
    }

    /**
    * @description Validates YearData wrapper year1 fields are accessible and assignable.
    */
    @isTest
    static void testYearDataWrapperYear1Fields() {
        Test.startTest();
        final Arc_Gen_AutoRetailTableInsert_Helper.YearData yd = new Arc_Gen_AutoRetailTableInsert_Helper.YearData();
        yd.stockRotationYear1 = 'High';
        yd.totalUnitsYear1 = 100;
        yd.year1 = '2024';
        Test.stopTest();

        Assert.isTrue('High' == yd.stockRotationYear1 && yd.totalUnitsYear1 == 100 && '2024' == yd.year1,
            'YearData year1 fields should be correctly set');
    }

    /**
    * @description Validates setDataByYear creates a child record with all fields correctly populated.
    */
    @isTest
    static void testSetDataByYearFields() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__autoretail_behavior_table__c tableObj = [SELECT Id FROM arce__autoretail_behavior_table__c WHERE arce__account_has_analysis_id__c = :aha.Id LIMIT 1];

        Test.startTest();
        final arce__autoretail_behavior_by_year__c result =
            Arc_Gen_AutoRetailTableInsert_Helper.setDataByYear(tableObj.Id, 'High', 150, '2024');
        Test.stopTest();

        Assert.isTrue(
            'High' == result.arce__gf_stock_rotation_desc__c &&
            result.arce__gf_prd_typ_sold_units_number__c == 150 &&
            '2024' == result.arce__year_id__c,
            'setDataByYear should populate rotation, units, and year fields'
        );
    }

    /**
    * @description Validates getYearData returns a correctly populated wrapper from a valid map.
    */
    @isTest
    static void testGetYearDataValidInput() {
        final Map<String, Object> data = new Map<String, Object>{
            'stockRotationYear1' => 'High',
            'totalUnitsYear1'    => (Decimal)100,
            'year1'              => '2024',
            'stockRotationYear2' => 'Medium',
            'totalUnitsYear2'    => (Decimal)200,
            'year2'              => '2025'
        };

        Test.startTest();
        final Arc_Gen_AutoRetailTableInsert_Helper.YearData result =
            Arc_Gen_AutoRetailTableInsert_Helper.getYearData(data);
        Test.stopTest();

        Assert.isTrue('High' == result.stockRotationYear1 && result.totalUnitsYear1 == 100,
            'getYearData should return correctly populated year1 values');
    }

    /**
    * @description Validates validateField returns the original value for a valid non-empty text.
    */
    @isTest
    static void testValidateFieldValidText() {
        Test.startTest();
        final Object result = Arc_Gen_AutoRetailTableInsert_Helper.validateField('SomeText', 'text');
        Test.stopTest();

        Assert.areEqual('SomeText', result, 'validateField should return the value for valid text');
    }

    /**
    * @description Validates validateField throws InvalidParametersException for an empty text value.
    */
    @isTest
    static void testValidateFieldEmptyTextThrows() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Arc_Gen_AutoRetailTableInsert_Helper.validateField('', 'text');
        } catch (Arc_Gen_AutoRetailTableInsert_Helper.InvalidParametersException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw InvalidParametersException for empty text');
    }

    /**
    * @description Validates validateField throws InvalidParametersException for a null number.
    */
    @isTest
    static void testValidateFieldNullNumberThrows() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Arc_Gen_AutoRetailTableInsert_Helper.validateField(null, 'number');
        } catch (Arc_Gen_AutoRetailTableInsert_Helper.InvalidParametersException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw InvalidParametersException for null number');
    }

    /**
    * @description Validates validateField throws InvalidParametersException for a negative number.
    */
    @isTest
    static void testValidateFieldNegativeNumberThrows() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Arc_Gen_AutoRetailTableInsert_Helper.validateField((Decimal)-5, 'number');
        } catch (Arc_Gen_AutoRetailTableInsert_Helper.InvalidParametersException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw InvalidParametersException for negative number');
    }

    /**
    * @description Validates validateCompanyName does not throw when no duplicate company exists.
    */
    @isTest
    static void testValidateCompanyNameNoDuplicate() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Map<String, Object> data = new Map<String, Object>{
            'companyName' => 'UniqueCompany',
            'brandName'   => 'UniqueBrand',
            'tableType'   => '1',
            'ahaId'       => aha.Id
        };
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Arc_Gen_AutoRetailTableInsert_Helper.validateCompanyName(data);
        } catch (Arc_Gen_AutoRetailTableInsert_Helper.InvalidParametersException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isFalse(exceptionThrown, 'Should not throw when no duplicate company exists');
    }

    /**
    * @description Validates validateCompanyName throws when a duplicate company record exists.
    */
    @isTest
    static void testValidateCompanyNameDuplicateThrows() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        insert new arce__autoretail_behavior_table__c(
            arce__account_has_analysis_id__c = aha.Id,
            arce__gf_company_name__c         = 'DupCompany',
            arce__gf_vehicle_brand_name__c   = 'DupBrand',
            arce__gf_product_status_type__c  = '1'
        );
        final Map<String, Object> data = new Map<String, Object>{
            'companyName' => 'DupCompany',
            'brandName'   => 'DupBrand',
            'tableType'   => '1',
            'ahaId'       => aha.Id
        };
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Arc_Gen_AutoRetailTableInsert_Helper.validateCompanyName(data);
        } catch (Arc_Gen_AutoRetailTableInsert_Helper.InvalidParametersException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw InvalidParametersException for duplicate company');
    }

    /**
    * @description Validates insertTable inserts the table record and its two year child records.
    */
    @isTest
    static void testInsertTableCreatesYears() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__autoretail_behavior_table__c tableObj = new arce__autoretail_behavior_table__c(
            arce__account_has_analysis_id__c = aha.Id,
            arce__gf_company_name__c         = 'InsertCompany',
            arce__gf_vehicle_brand_name__c   = 'InsertBrand',
            arce__gf_product_status_type__c  = '1'
        );
        final Map<String, Object> data = new Map<String, Object>{
            'stockRotationYear1' => 'High',
            'totalUnitsYear1'    => (Decimal)100,
            'year1'              => '2024',
            'stockRotationYear2' => 'Medium',
            'totalUnitsYear2'    => (Decimal)200,
            'year2'              => '2025'
        };

        Test.startTest();
        Arc_Gen_AutoRetailTableInsert_Helper.insertTable(data, tableObj);
        Test.stopTest();

        final List<arce__autoretail_behavior_by_year__c> years = [
            SELECT Id FROM arce__autoretail_behavior_by_year__c
            WHERE arce__autoretail_behavior_table_id__c = :tableObj.Id
        ];
        Assert.isTrue(years.size() == 2, 'insertTable should create exactly 2 year child records');
    }

    /**
    * @description Validates updateTable updates the year child record values successfully.
    */
    @isTest
    static void testUpdateTableUpdatesValues() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__autoretail_behavior_table__c tableObj = new arce__autoretail_behavior_table__c(
            arce__account_has_analysis_id__c = aha.Id,
            arce__gf_company_name__c         = 'UpdateCompany',
            arce__gf_vehicle_brand_name__c   = 'UpdateBrand',
            arce__gf_product_status_type__c  = '1'
        );
        Arc_Gen_AutoRetailTableInsert_Helper.insertTable(
            new Map<String, Object>{
                'stockRotationYear1' => 'High',   'totalUnitsYear1' => (Decimal)100, 'year1' => '2024',
                'stockRotationYear2' => 'Medium', 'totalUnitsYear2' => (Decimal)200, 'year2' => '2025'
            },
            tableObj
        );
        final List<arce__autoretail_behavior_by_year__c> years = [
            SELECT Id FROM arce__autoretail_behavior_by_year__c
            WHERE arce__autoretail_behavior_table_id__c = :tableObj.Id
            ORDER BY arce__year_id__c ASC
        ];

        final Map<String, Object> updateData = new Map<String, Object>{
            'stockRotationYear1' => 'Low',    'totalUnitsYear1' => (Decimal)50,  'year1' => '2024',
            'stockRotationYear2' => 'High',   'totalUnitsYear2' => (Decimal)300, 'year2' => '2025',
            'standardYear1Id'    => years[0].Id,
            'standardYear2Id'    => years[1].Id
        };

        Test.startTest();
        Arc_Gen_AutoRetailTableInsert_Helper.updateTable(updateData, tableObj);
        Test.stopTest();

        final arce__autoretail_behavior_by_year__c updated = [
            SELECT arce__gf_prd_typ_sold_units_number__c
            FROM arce__autoretail_behavior_by_year__c
            WHERE Id = :years[0].Id
        ];
        Assert.areEqual(50, updated.arce__gf_prd_typ_sold_units_number__c,
            'updateTable should update year1 units to 50');
    }
}