/**
* @description Test class for Arc_Gen_AutoRetailBehaviorTable_Data.
*/
@isTest
private class Arc_Gen_AutoRetailBhvrTbl_Data_Test {
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
        accHasAn.arce__year_id__c = '2024';
        insert accHasAn;

        final arce__autoretail_behavior_table__c autoRetail = new arce__autoretail_behavior_table__c(
            arce__account_has_analysis_id__c = accHasAn.Id,
            arce__gf_company_name__c = 'TestCompany',
            arce__gf_vehicle_brand_name__c = 'TestBrand',
            arce__gf_product_status_type__c = '1'
        );
        insert autoRetail;
    }

    /**
    * @description Validates the data class constructor instantiates successfully.
    */
    @isTest static void testConstructor() {
        Test.startTest();
        final Arc_Gen_AutoRetailBehaviorTable_Data data = new Arc_Gen_AutoRetailBehaviorTable_Data();
        Test.stopTest();

        Assert.isNotNull(data, 'Constructor should create an instance');
    }

    /**
    * @description Validates getAutoRetailData returns records for a valid AHA.
    */
    @isTest static void testGetAutoRetailDataValidAha() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final List<arce__autoretail_behavior_table__c> result =
            Arc_Gen_AutoRetailBehaviorTable_Data.getAutoRetailData(aha.Id, '1', '2024', '2025');
        Test.stopTest();

        Assert.isFalse(result.isEmpty(), 'Should return auto retail records for valid AHA');
    }

    /**
    * @description Validates getAutoRetailData returns empty for a non-matching type.
    */
    @isTest static void testGetAutoRetailDataInvalidType() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final List<arce__autoretail_behavior_table__c> result =
            Arc_Gen_AutoRetailBehaviorTable_Data.getAutoRetailData(aha.Id, '99', '2024', '2025');
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Should return empty for non-matching type');
    }

    /**
    * @description Validates getRowById returns the specific auto retail row. */
    @isTest static void testGetRowByIdValidId() {
        final arce__autoretail_behavior_table__c autoRetail = [SELECT Id FROM arce__autoretail_behavior_table__c LIMIT 1];

        Test.startTest();
        final List<arce__autoretail_behavior_table__c> result =
            Arc_Gen_AutoRetailBehaviorTable_Data.getRowById(autoRetail.Id, '2024', '2025');
        Test.stopTest();

        Assert.isFalse(result.isEmpty(), 'Should return the specific row');
    }

    /**
    * @description Validates getByCompanyAndBrand returns matching records.
    */
    @isTest static void testGetByCompanyAndBrandMatch() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        final Map<String, Object> data = new Map<String, Object>{
            'companyName' => 'TestCompany',
            'brandName' => 'TestBrand',
            'tableType' => '1',
            'ahaId' => aha.Id
        };

        Test.startTest();
        final List<arce__autoretail_behavior_table__c> result =
            Arc_Gen_AutoRetailBehaviorTable_Data.getByCompanyAndBrand(data);
        Test.stopTest();

        Assert.isFalse(result.isEmpty(), 'Should return matching records');
    }

    /**
    * @description Validates getByCompanyAndBrand returns empty for non-matching data.
    */
    @isTest static void testGetByCompanyAndBrandNoMatch() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        final Map<String, Object> data = new Map<String, Object>{
            'companyName' => 'NonExistent',
            'brandName' => 'NonExistent',
            'tableType' => '1',
            'ahaId' => aha.Id
        };

        Test.startTest();
        final List<arce__autoretail_behavior_table__c> result =
            Arc_Gen_AutoRetailBehaviorTable_Data.getByCompanyAndBrand(data);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Should return empty for non-matching data');
    }

    /**
    * @description Validates deleteRecord successfully removes the auto retail record.
    */
    @isTest static void testDeleteRecordValidId() {
        final arce__autoretail_behavior_table__c autoRetail = [SELECT Id FROM arce__autoretail_behavior_table__c LIMIT 1];

        Test.startTest();
        Arc_Gen_AutoRetailBehaviorTable_Data.deleteRecord(autoRetail.Id);
        Test.stopTest();

        final List<arce__autoretail_behavior_table__c> remaining = [SELECT Id FROM arce__autoretail_behavior_table__c WHERE Id = :autoRetail.Id];
        Assert.isTrue(remaining.isEmpty(), 'Record should be deleted');
    }

    /**
    * @description Validates deleteRecord throws exception for an invalid row Id.
    */
    @isTest static void testDeleteRecordInvalidIdThrows() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__autoretail_behavior_table__c temp = new arce__autoretail_behavior_table__c(
            arce__account_has_analysis_id__c = aha.Id,
            arce__gf_company_name__c = 'TempCompany',
            arce__gf_vehicle_brand_name__c = 'TempBrand',
            arce__gf_product_status_type__c = '1'
        );
        insert temp;
        delete temp;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Arc_Gen_AutoRetailBehaviorTable_Data.deleteRecord(temp.Id);
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw exception when deleting an already-deleted record');
    }

    /**
    * @description Validates getPreviousSelectedYear returns the expected year from AHA.
    */
    @isTest static void testGetPreviousSelectedYear() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final arce__Account_has_Analysis__c result =
            Arc_Gen_AutoRetailBehaviorTable_Data.getPreviousSelectedYear(aha.Id);
        Test.stopTest();

        Assert.areEqual('2024', result.arce__year_id__c, 'Should return the previously selected year');
    }

    /**
    * @description Validates getAutoRetailToCopy returns records for valid AHA Ids.
    */
    @isTest static void testGetAutoRetailToCopyValidIds() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final List<arce__autoretail_behavior_table__c> result =
            Arc_Gen_AutoRetailBehaviorTable_Data.getAutoRetailToCopy(new Set<Id>{aha.Id});
        Test.stopTest();

        Assert.isFalse(result.isEmpty(), 'Should return auto retail records to copy');
    }
}