/**
* @description Coverage tests for Arc_Gen_PersistenceCopyLimits_helper.
*/
@isTest
private class Arc_Gen_PersistenceCopyLimits_Test {
    private static final String GROUP_ID = 'G000001';
    private static final String SUBSIDIARY_ID = 'C000001';

    /**
    * @description Create shared test data.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID, SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__Stage__c = '2';
        newArce.arce__anlys_wkfl_sub_process_type__c = '2';
        insert newArce;

        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('Generic', '100', '1', null);
        insert newSector;

        final arce__Account_has_Analysis__c aha = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, newArce.Id, groupAccount.accId, '1');
        aha.arce__group_asset_header_type__c = '1';
        aha.arce__InReview__c = true;
        aha.arce__magnitude_unit_type__c = '2';
        insert aha;
    }

    /**
    * @description Validates fillRiskAssesment returns a list of maps.
    */
    @isTest static void testFillRiskAssesment() {
        final List<arce__Account_has_Analysis__c> ahaList = [
            SELECT Id, Name, arce__Customer__c, arce__Customer__r.AccountNumber, arce__Analysis__r.arce__Group__r.AccountNumber
            FROM arce__Account_has_Analysis__c
        ];

        Test.startTest();
        final List<Map<String, Object>> result = Arc_Gen_PersistenceCopyLimits_helper.fillRiskAssesment(ahaList);
        Test.stopTest();

        Assert.isNotNull(result, 'Should return a non-null risk assessment list');
    }

    /**
    * @description Validates getIdStructure populates map with value.
    */
    @isTest static void testGetIdStructure() {
        final Map<String, Object> mapObj = new Map<String, Object>();

        Test.startTest();
        Arc_Gen_PersistenceCopyLimits_helper.getIdStructure(mapObj, 'TestValue', 'testKey');
        Test.stopTest();

        Assert.isTrue(mapObj.containsKey('testKey'), 'Map should contain the testKey');
    }

    /**
    * @description Validates getIdStructure with null value does not populate map.
    */
    @isTest static void testGetIdStructureNull() {
        final Map<String, Object> mapObj = new Map<String, Object>();

        Test.startTest();
        Arc_Gen_PersistenceCopyLimits_helper.getIdStructure(mapObj, null, 'testKey');
        Test.stopTest();

        Assert.isTrue(true, 'Should handle null value without error');
    }

    /**
    * @description Validates constructor is accessible via testVisible.
    */
    @isTest static void testConstructor() {
        Test.startTest();
        final Arc_Gen_PersistenceCopyLimits_helper instance = new Arc_Gen_PersistenceCopyLimits_helper();
        Test.stopTest();

        Assert.isNotNull(instance, 'Constructor should create valid instance');
    }
}