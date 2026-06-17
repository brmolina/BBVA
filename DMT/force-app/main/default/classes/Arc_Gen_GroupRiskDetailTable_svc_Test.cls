/**
* @Description Test class for Arc_Gen_GroupRiskDetailTable_service.
*/
@isTest
private class Arc_Gen_GroupRiskDetailTable_svc_Test {
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
        accHasAn.arce__magnitude_unit_type__c = '3';
        accHasAn.arce__last_approved_amount__c = 100;
        accHasAn.arce__outstanding_amount__c = 50;
        accHasAn.arce__current_formalized_amount__c = 75;
        accHasAn.arce__current_proposed_local_amount__c = 90;
        insert accHasAn;
    }

    /**
    * @description Validates the service constructor instantiates successfully.
    */
    @isTest static void testConstructor() {
        Test.startTest();
        final Arc_Gen_GroupRiskDetailTable_service svc = new Arc_Gen_GroupRiskDetailTable_service();
        Test.stopTest();

        Assert.isNotNull(svc, 'Constructor should create an instance');
    }

    /**
    * @description Validates setupRiskTable returns a JSON result for a group header AHA.
    */
    @isTest static void testSetupRiskTableGroupHeader() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__group_asset_header_type__c,
            arce__magnitude_unit_type__c, arce__Analysis__c FROM arce__Account_has_Analysis__c LIMIT 1];

        final arce__limits_exposures__c limEx = new arce__limits_exposures__c(
            arce__account_has_analysis_id__c = aha.Id,
            arce__last_approved_amount__c = 200,
            arce__outstanding_amount__c = 100,
            arce__current_formalized_amount__c = 150,
            arce__current_proposed_amount__c = 180
        );
        insert limEx;

        Test.startTest();
        final String result = Arc_Gen_GroupRiskDetailTable_service.setupRiskTable(limEx, aha);
        Test.stopTest();

        Assert.isTrue(result != null && result.contains('status'), 'setupRiskTable should return a non-null JSON string containing status field');
    }

    /**
    * @description Validates configGroupRiskDetail returns a non-null, non-editable configuration table.
    */
    @isTest static void testConfigGroupRiskDetail() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final Arc_Gen_DwpTableWrapper_Controller.Configuration_Table config =
            Arc_Gen_GroupRiskDetailTable_service.configGroupRiskDetail(aha.Id);
        Test.stopTest();

        Assert.isTrue(config != null && config.mapHeader != null && config.editable == false,
            'Config should be non-null, have a header, and be non-editable');
    }

    /**
    * @description Validates configLeveragedGpTable returns a non-null, non-editable configuration table.
    */
    @isTest static void testConfigLeveragedGpTable() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final Arc_Gen_DwpTableWrapper_Controller.Configuration_Table config =
            Arc_Gen_GroupRiskDetailTable_service.configLeveragedGpTable(aha.Id);
        Test.stopTest();

        Assert.isTrue(config != null && config.mapHeader != null && config.editable == false,
            'Config should be non-null, have a header, and be non-editable');
    }
}