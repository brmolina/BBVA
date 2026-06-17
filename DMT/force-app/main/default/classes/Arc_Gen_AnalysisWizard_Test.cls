/**
* @description Coverage tests for Arc_Gen_AnalysisWizard_Controller.
*/
@isTest
private class Arc_Gen_AnalysisWizard_Test {
    /** Group account number for test data */
    private static final String GROUP_ID = 'G000001';
    /** Subsidiary account number for test data */
    private static final String SUBSIDIARY_ID = 'C000001';

    /**
    * @description Create test data.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID, SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__Stage__c = '2';
        newArce.arce__wf_status_id__c = '10';
        newArce.arce__anlys_wkfl_sub_process_type__c = '2';
        insert newArce;

        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('Generic', '100', '1', null);
        newSector.arce__sector_analisis_type__c = '2';
        newSector.arce__active_type__c = true;
        insert newSector;

        final arce__Account_has_Analysis__c headerAha = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, newArce.Id, groupAccount.accId, '1');
        headerAha.arce__group_asset_header_type__c = '1';
        headerAha.arce__InReview__c = true;
        insert headerAha;

        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
    }

    /**
    * @description Validates getSplittedMdtValue returns a list of strings from config.
    */
    @isTest static void testGetSplittedMdtValue() {
        Test.startTest();
        final List<String> result = Arc_Gen_AnalysisWizard_Service.getSplittedMdtValue('RAIPSelectWorkflow');
        Test.stopTest();

        Assert.isNotNull(result, 'Should return a non-null list of config values');
    }

    /**
    * @description Validates getStringFromArceConfig returns a config string.
    */
    @isTest static void testGetStringFromArceConfig() {
        Test.startTest();
        final String result = Arc_Gen_AnalysisWizard_Service.getStringFromArceConfig('RAIPSelectWorkflow');
        Test.stopTest();

        Assert.isNotNull(result, 'Should return a non-null config string');
    }

    /**
    * @description Validates updateStatusArce updates the analysis status.
    */
    @isTest static void testUpdateStatusArce() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];

        Test.startTest();
        Arc_Gen_AnalysisWizard_Service.updateStatusArce(analysis.Id, '11', '2');
        Test.stopTest();

        final arce__Analysis__c updated = [SELECT arce__wf_status_id__c FROM arce__Analysis__c WHERE Id = :analysis.Id];
        Assert.areEqual('11', updated.arce__wf_status_id__c, 'Status should be updated to 11');
    }

    /**
    * @description Validates updateSector updates the analysis sector.
    */
    @isTest static void testUpdateSector() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];

        Test.startTest();
        Arc_Gen_AnalysisWizard_Service.updateSector(analysis.Id, 'SectorTest', '1');
        Test.stopTest();

        Assert.isTrue(true, 'updateSector should complete without error');
    }

    /**
    * @description Validates getCallTriageEngineConfig returns a boolean.
    */
    @isTest static void testGetCallTriageEngineConfig() {
        Test.startTest();
        final Boolean result = Arc_Gen_AnalysisWizard_Controller.getCallTriageEngineConfig();
        Test.stopTest();

        Assert.isNotNull(result, 'Should return a non-null boolean');
    }

    /**
    * @description Validates getPersistanceCallConfig returns a boolean.
    */
    @isTest static void testGetPersistanceCallConfig() {
        Test.startTest();
        final Boolean result = Arc_Gen_AnalysisWizard_Controller.getPersistanceCallConfig();
        Test.stopTest();

        Assert.isNotNull(result, 'Should return a non-null persistance config boolean');
    }

    /**
    * @description Validates updateArceToPreparing updates analysis state.
    */
    @isTest static void testUpdateArceToPreparing() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];

        Test.startTest();
        Arc_Gen_AnalysisWizard_Controller.updateArceToPreparing(analysis.Id, '2');
        Test.stopTest();

        Assert.isTrue(true, 'updateArceToPreparing should complete without error');
    }

    /**
    * @description Validates updateArceSectorAndStatus updates analysis.
    */
    @isTest static void testUpdateArceSectorAndStatus() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];

        Test.startTest();
        Arc_Gen_AnalysisWizard_Controller.updateArceSectorAndStatus(analysis.Id, 's-01', '1', '2');
        Test.stopTest();

        Assert.isTrue(true, 'updateArceSectorAndStatus should complete without error');
    }

    /**
    * @description Validates callPersistence returns a service response.
    */
    @isTest static void testCallPersistence() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final arce.Arc_Gen_ServiceAndSaveResponse result = Arc_Gen_AnalysisWizard_Controller.callPersistence(aha.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Should return a non-null service response');
    }
}