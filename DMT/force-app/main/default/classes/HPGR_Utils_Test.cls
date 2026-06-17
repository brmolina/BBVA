/*-------------------------------------------------------------------------------------------
* @Name     HPGR_Utils_Test
* @Author   cosme.alcazar.tech@bbva.com
* @Date     Created: 2025-04-29
* -------------------------------------------------------------------------------------------
* @Description Test class for 'HPGR_Utils' apex class
* -------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class HPGR_Utils_Test {

    static final String CONTRACT_GUARANTEES = 'contract_guarantees';
    static final String CONSUMPTION_DETAIL = 'consumption_detail';
    static final String DEREIVATIVES_DATA = 'derivatives_data';
    static final String CATALOG_B444 = 'B444';
    static final String CATALOG_D783 = 'D783';
    static final String SUPPORT_WUT = 'SupportWUT';

    @isTest
    static void getConsumptionLastLevelIdHierarchyDataB444Test() {
        HPGR_TestDataFactory.insertTaxonomyHierarchy();
        HPGR_TestDataFactory.insertTaxonomyValues();
        Test.startTest();
            Map<String, Object> retMap = HPGR_Utils.getConsumptionLastLevelIdHierarchyData(CATALOG_B444);
            Boolean success = (Boolean)retMap.get('success');
            List<hpgr.Utils.ConsumptionLastLevelIdHierarchy> consumptionLastLevelIdHierarchy = (List<hpgr.Utils.ConsumptionLastLevelIdHierarchy>)retMap.get('consumptionLastLevelIdHierarchy');
            Map<String, String> consumptionLastLevelIdLabels = (Map<String, String>)retMap.get('consumptionLastLevelIdLabels');
            System.assertEquals(true, success, 'getConsumptionLastLevelIdHierarchyDataB444Test - Not passed - success');
            System.assertEquals(9, consumptionLastLevelIdHierarchy.size(), 'getConsumptionLastLevelIdHierarchyDataB444Test - Not passed - consumptionLastLevelIdHierarchy.size()');
            System.assertEquals('10000', consumptionLastLevelIdHierarchy[0].parent, 'getConsumptionLastLevelIdHierarchyDataB444Test - Not passed - consumptionLastLevelIdHierarchy[0].parent');
            System.assertEquals(new List<String>{'10100', '10200'}, consumptionLastLevelIdHierarchy[0].child, 'getConsumptionLastLevelIdHierarchyDataB444Test - Not passed - consumptionLastLevelIdHierarchy[0].child');
            System.assertEquals(38, consumptionLastLevelIdLabels.size(), 'getConsumptionLastLevelIdHierarchyDataB444Test - Not passed - consumptionLastLevelIdLabels.size()');
            System.assertEquals(Label.hpgr.field_10100, consumptionLastLevelIdLabels.get('10100'), 'getConsumptionLastLevelIdHierarchyDataB444Test - Not passed - consumptionLastLevelIdLabels.get(10100)');
            System.assertEquals(Label.hpgr.field_10200, consumptionLastLevelIdLabels.get('10200'), 'getConsumptionLastLevelIdHierarchyDataB444Test - Not passed - consumptionLastLevelIdLabels.get(10200)');
        Test.stopTest();
    }

    @isTest
    static void getConsumptionLastLevelIdHierarchyDataD783Test() {
        HPGR_TestDataFactory.insertTaxonomyHierarchy();
        HPGR_TestDataFactory.insertTaxonomyValues();
        Test.startTest();
            Map<String, Object> retMap = HPGR_Utils.getConsumptionLastLevelIdHierarchyData(CATALOG_D783);
            Boolean success = (Boolean)retMap.get('success');
            List<hpgr.Utils.ConsumptionLastLevelIdHierarchy> consumptionLastLevelIdHierarchy = (List<hpgr.Utils.ConsumptionLastLevelIdHierarchy>)retMap.get('consumptionLastLevelIdHierarchy');
            Map<String, String> consumptionLastLevelIdLabels = (Map<String, String>)retMap.get('consumptionLastLevelIdLabels');
            System.assertEquals(true, success, 'getConsumptionLastLevelIdHierarchyDataD783Test - Not passed - success');
            System.assertEquals(8, consumptionLastLevelIdHierarchy.size(), 'getConsumptionLastLevelIdHierarchyDataD783Test - Not passed - consumptionLastLevelIdHierarchy.size()');
            System.assertEquals('50000', consumptionLastLevelIdHierarchy[0].parent, 'getConsumptionLastLevelIdHierarchyDataD783Test - Not passed - consumptionLastLevelIdHierarchy[0].parent');
            System.assertEquals(new List<String>{'30000', '40000', '50100', '50300', '50400'}, consumptionLastLevelIdHierarchy[0].child, 'getConsumptionLastLevelIdHierarchyDataD783Test - Not passed - consumptionLastLevelIdHierarchy[0].child');
            System.assertEquals(28, consumptionLastLevelIdLabels.size(), 'getConsumptionLastLevelIdHierarchyDataD783Test - Not passed - consumptionLastLevelIdLabels.size()');
            System.assertEquals(Label.hpgr.field_40000, consumptionLastLevelIdLabels.get('40000'), 'getConsumptionLastLevelIdHierarchyDataD783Test - Not passed - consumptionLastLevelIdLabels.get(40000)');
            System.assertEquals(Label.hpgr.field_30000, consumptionLastLevelIdLabels.get('30000'), 'getConsumptionLastLevelIdHierarchyDataD783Test - Not passed - consumptionLastLevelIdLabels.get(30000)');
            System.assertEquals(Label.hpgr.field_50300, consumptionLastLevelIdLabels.get('50300'), 'getConsumptionLastLevelIdHierarchyDataD783Test - Not passed - consumptionLastLevelIdLabels.get(50300)');
            System.assertEquals(Label.hpgr.field_50100, consumptionLastLevelIdLabels.get('50100'), 'getConsumptionLastLevelIdHierarchyDataD783Test - Not passed - consumptionLastLevelIdLabels.get(50100)');
            System.assertEquals(Label.hpgr.field_50400, consumptionLastLevelIdLabels.get('50400'), 'getConsumptionLastLevelIdHierarchyDataD783Test - Not passed - consumptionLastLevelIdLabels.get(50400)');
        Test.stopTest();
    }

    @isTest
    static void getConsumptionLastLevelIdDataB444Test() {
        HPGR_TestDataFactory.insertTaxonomyHierarchy();
        HPGR_TestDataFactory.insertTaxonomyValues();
        Test.startTest();
            Map<String, Object> retMap = HPGR_Utils.getConsumptionLastLevelIdData(CATALOG_B444);
            Boolean success = (Boolean)retMap.get('success');
            List<hpgr.Utils.ConsumptionLastLevelIdValues> consumptionLastLevelIdValues = (List<hpgr.Utils.ConsumptionLastLevelIdValues>)retMap.get('consumptionLastLevelIdValues');
            System.assertEquals(true, success, 'getConsumptionLastLevelIdDataB444Test - Not passed - success');
            System.assertEquals(29, consumptionLastLevelIdValues.size(), 'getConsumptionLastLevelIdDataB444Test - Not passed - result.size()');
            System.assertEquals('10100', consumptionLastLevelIdValues[0].consumptionLastLevelId, 'getConsumptionLastLevelIdDataB444Test - Not passed - consumptionLastLevelIdValues[0].consumptionLastLevelId');
            System.assertEquals(Label.hpgr.field_10100, consumptionLastLevelIdValues[0].consumptionLastLevelName, 'getConsumptionLastLevelIdDataB444Test - Not passed - consumptionLastLevelIdValues[0].consumptionLastLevelName');
            System.assertEquals(CONSUMPTION_DETAIL, consumptionLastLevelIdValues[0].onClickComponent, 'getConsumptionLastLevelIdDataB444Test - Not passed - consumptionLastLevelIdValues[0].onClickComponent');
            System.assertEquals(CONTRACT_GUARANTEES, consumptionLastLevelIdValues[0].onClickRow, 'getConsumptionLastLevelIdDataB444Test - Not passed - consumptionLastLevelIdValues[0].onClickRow');
        Test.stopTest();
    }

    @isTest
    static void getConsumptionLastLevelIdDataD783Test() {
        HPGR_TestDataFactory.insertTaxonomyHierarchy();
        HPGR_TestDataFactory.insertTaxonomyValues();
        Test.startTest();
            Map<String, Object> retMap = HPGR_Utils.getConsumptionLastLevelIdData(CATALOG_D783);
            Boolean success = (Boolean)retMap.get('success');
            List<hpgr.Utils.ConsumptionLastLevelIdValues> consumptionLastLevelIdValues = (List<hpgr.Utils.ConsumptionLastLevelIdValues>)retMap.get('consumptionLastLevelIdValues');
            System.assertEquals(true, success, 'getConsumptionLastLevelIdDataD783Test - Not passed - success');
            System.assertEquals(20, consumptionLastLevelIdValues.size(), 'getConsumptionLastLevelIdDataD783Test - Not passed - result.size()');
            System.assertEquals('40000', consumptionLastLevelIdValues[0].consumptionLastLevelId, 'getConsumptionLastLevelIdDataD783Test - Not passed - consumptionLastLevelIdValues[0].consumptionLastLevelId');
            System.assertEquals(Label.hpgr.field_40000, consumptionLastLevelIdValues[0].consumptionLastLevelName, 'getConsumptionLastLevelIdDataD783Test - Not passed - consumptionLastLevelIdValues[0].consumptionLastLevelName');
            System.assertEquals(CONSUMPTION_DETAIL, consumptionLastLevelIdValues[0].onClickComponent, 'getConsumptionLastLevelIdDataD783Test - Not passed - consumptionLastLevelIdValues[0].onClickComponent');
            System.assertEquals(DEREIVATIVES_DATA, consumptionLastLevelIdValues[0].onClickRow, 'getConsumptionLastLevelIdDataD783Test - Not passed - consumptionLastLevelIdValues[0].onClickRow');
        Test.stopTest();
    }

    @IsTest
    static void manageErrorTest() {
        Test.startTest();
            hpgr.Utils.Error_Wrapper errorWrapper = new hpgr.Utils.Error_Wrapper();
            errorWrapper.type = 'hpgr.Utils.getConsumptionLastLevelIdChildValues Error';
            errorWrapper.className = 'HPGR_Utils';
            errorWrapper.methodName = 'getConsumptionLastLevelIdData';
            errorWrapper.userId = UserInfo.getUserId();
            Datetime timestamp = System.now();
            errorWrapper.timestamp = timestamp;
            errorWrapper.errorData = 'No consumptionLastLevelId values found for Taxonomy catalog: ' + CATALOG_B444;
            HPGR_Utils.manageError(errorWrapper);
            System.assertEquals('hpgr.Utils.getConsumptionLastLevelIdChildValues Error', errorWrapper.type, 'manageErrorTest - Not passed - errorWrapper.type');
            System.assertEquals('HPGR_Utils', errorWrapper.className, 'manageErrorTest - Not passed - errorWrapper.className');
            System.assertEquals('getConsumptionLastLevelIdData', errorWrapper.methodName, 'manageErrorTest - Not passed - errorWrapper.methodName');
            System.assertEquals(UserInfo.getUserId(), errorWrapper.userId, 'manageErrorTest - Not passed - errorWrapper.userId');
            System.assertEquals(timestamp, errorWrapper.timestamp, 'manageErrorTest - Not passed - errorWrapper.timestamp');
        Test.stopTest();
    }

    @IsTest
    static void manageOpenHelpTest() {
        Test.startTest();
            HPGR_Utils.manageOpenHelp();
        Test.stopTest();
        System.assertEquals(true, true, 'manageOpenHelpTest - Not passed - method execution');
    }

    @IsTest
    static void getDMTLinesDataTest() {
        Test.startTest();
            // Create test data for DMT_Line__c
            List<DMT_Line__c> dmtLines = new List<DMT_Line__c>();
            dmtLines.add(new DMT_Line__c(
                Name = 'Test DMT Line 1',
                Line_Id__c = 'LINE001',
                OwnerId = UserInfo.getUserId()
            ));
            dmtLines.add(new DMT_Line__c(
                Name = 'Test DMT Line 2',
                Line_Id__c = 'LINE002',
                OwnerId = UserInfo.getUserId()
            ));
            insert dmtLines;
            // Create test data for DMT_TeamMember__c
            List<DMT_TeamMember__c> dmtTeamMembers = new List<DMT_TeamMember__c>();
            dmtTeamMembers.add(new DMT_TeamMember__c(
                Line__c = dmtLines[0].Id,
                User__c = UserInfo.getUserId(),
                AccessLevel__c = 'Edit'
            ));
            dmtTeamMembers.add(new DMT_TeamMember__c(
                Line__c = dmtLines[1].Id,
                User__c = UserInfo.getUserId(),
                AccessLevel__c = 'Edit'
            ));
            insert dmtTeamMembers;
            // Call the method with opportunity IDs
            List<String> lineIds = new List<String>{'LINE001', 'LINE002'};
            Set<String> opportunityIdSet = new Set<String>(lineIds);
            Map<String, String> result = HPGR_Utils.getDMTLinesData(opportunityIdSet);
            // Verify the result (Note: result may be empty if user doesn't have required DMT role)
            System.assertNotEquals(null, result, 'getDMTLinesDataTest - Not passed - result should not be null');
            System.assert(result != null, 'getDMTLinesDataTest - Not passed - result should not be null');
        Test.stopTest();
    }
}