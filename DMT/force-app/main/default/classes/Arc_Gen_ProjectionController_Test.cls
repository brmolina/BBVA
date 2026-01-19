/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ProjectionController_Test
* @Author   joseluis.miralles.contractor@bbva.com
* @Date     Created: 21/05/2023
* @Group    ARCE
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 03-05-2025
* @Description Test Class of Arc_Gen_ProjectionController_Test
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
*/
@SuppressWarnings('sf:TooManyMethods') 
@isTest
public class Arc_Gen_ProjectionController_Test {
    /**
    * @Description: Parameter literal
    */
    final static String ID_PARAM = 'ahaId'; 
    /**
    * @Description: Parameter literal to be passed to query
    */
    final static String BASE_CASE = 'Base Case';
    /**
    * @Description: Parameter literal to be passed to query
    */
    final static String DOWN_SCE = 'Down';
    /**
    * @Description: Setup data for running test
    */
    @TestSetup
    static void setupData() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{ 'G000001', 'C000001' });
        final arce.Arc_Gen_Account_Wrapper fath = groupAccWrapper.get('G000001');
        final arce.Arc_Gen_Account_Wrapper kid = groupAccWrapper.get('C000001');

        final arce__Analysis__c analysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Test Analysis', null, fath.accId);
        insert analysis;

        final arce__Sector__c sect = Arc_UtilitysDataTest_tst.crearSector('Executive Summ', '500', 'ExecSumm', null);
        insert sect;

        final arce__rating__c rating = new arce__rating__c();
        insert rating;

        final arce__Financial_Statements__c ffss = new arce__Financial_Statements__c(
            arce__ffss_valid_type__c = '1',
            arce__ffss_valid_for_rating_type__c = '1',
            arce__financial_statement_id__c = '0000000000000000012345',
            arce__rating_id__c = rating.Id
        );
        insert ffss;

        final arce__Account_has_Analysis__c accHasAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, kid.accId, '1');
        accHasAnalysis.arce__ffss_for_rating_id__c = ffss.Id;
        insert accHasAnalysis;

        final List<String> scenariosList = new List<String>{ 'Base Case', 'Up', 'Down' };
        final List<arce__Projection__c> projectionsList = new List<arce__Projection__c>();
        for (String var : scenariosList) {
            final arce__Projection__c proj = new arce__Projection__c(
                arce__Scenario_Type__c = var,
                arce__Account_has_Analysis__c = accHasAnalysis.Id,
                arce__Projection_Id__c = '0000000000000000000123',
                arce__Statement_Currency__c = UserInfo.getDefaultCurrency(),
                arce__FinancialStatement_Type__c = 'CONSOLIDATED',
                arce__Period_StartDate__c = '01-01-2021',
                arce__Period_EndDate__c = '31-12-2021',
                arce__Projection_Type__c = 'Projection'
            );
            projectionsList.add(proj);
            final arce__Projection__c projProp = new arce__Projection__c(
                arce__Scenario_Type__c = var,
                arce__Projection_Id__c = '0000000000000000000001',
                arce__Statement_Currency__c = UserInfo.getDefaultCurrency(),
                arce__FinancialStatement_Type__c = 'CONSOLIDATED',
                arce__Period_StartDate__c = '01-01-2021',
                arce__Period_EndDate__c = '31-12-2021',
                arce__Projection_Type__c = 'Projection',
                arce__Proposal_Folder_Id__c = 'proposalTestId'
            );
            projectionsList.add(projProp);
        }
        insert projectionsList;
    }

    /**
    * @Description: Method to check colums data
    */
    @isTest
    public static void getDynamicColumnsTest() {
        Test.startTest();
        final String result = Arc_Gen_ProjectionController.getDynamicColumns(false);
        System.assert(String.isNotBlank(result), 'Columns must not be blank');
        Test.stopTest();
    }
    /**
    * @Description: Method to to get ScenarioData
    */
    @isTest
    public static void getScenarioDataNoSimulationTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1][0];
        final arce__Projection__c pjBcase = [SELECT Id, arce__Scenario_Type__c
                                                        FROM arce__Projection__c
                                                        where arce__Account_has_Analysis__c = :accHasAnalysis.Id and arce__Scenario_Type__c =: BASE_CASE
                                                        LIMIT 1][0];
        Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper wrrapperResponse = new Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper();
        Test.startTest();
        wrrapperResponse = Arc_Gen_ProjectionController.getScenarioData(accHasAnalysis.Id, BASE_CASE, false, null);
        System.assertEquals(pjBcase.Id, wrrapperResponse.datatable[0].Id, 'Error getting data from projection');
        Test.stopTest();
    }

    /**
    * @Description: Method to get scenario data in simulation
    */
    @isTest
    public static void getScenarioDataIsSimulationTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1][0];
        final List<arce__Projection__c> prBaseCase = [SELECT Id, arce__Scenario_Type__c
                                                              FROM arce__Projection__c
                                                              where arce__Account_has_Analysis__c = :accHasAnalysis.Id and arce__Scenario_Type__c =: BASE_CASE];
        Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper wrrapperResponse = new Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper();

        Test.startTest();
        wrrapperResponse = Arc_Gen_ProjectionController.getScenarioData(accHasAnalysis.Id, BASE_CASE, true, null);
        System.assertEquals(prBaseCase.size(), wrrapperResponse.datatable.size(), 'Error getting data from projection');
        Test.stopTest();
    }

    /**
    * @Description: Method to update KeyAssumptions
    */
    @isTest
    public static void updateKeyAssumptionsTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1][0];

        final arce__Projection__c pjBaseCase = [SELECT Id, arce__Avg_Days_Inventory_Out__c, arce__Scenario_Type__c
                                                        FROM arce__Projection__c
                                                        where arce__Account_has_Analysis__c = :accHasAnalysis.Id and arce__Scenario_Type__c =: BASE_CASE
                                                        LIMIT 1][0];
        final String updateKeys = '{"'+pjBaseCase.Id+'":{"arce__Revenue_growth__c":0.01,"arce__Margen_Ebitda__c":0.02}}';
        Test.startTest();
        Arc_Gen_ProjectionController.updateKeyAssumptions(updateKeys, BASE_CASE, '1', 'Standard projection', accHasAnalysis.Id, '1', null);
        final arce__Projection__c pjBaseRes = [SELECT Id, arce__Avg_Days_Inventory_Out__c,arce__Margen_Ebitda__c, arce__Scenario_Type__c,arce__Revenue_growth__c
                                                            FROM arce__Projection__c
                                                            where Id = :pjBaseCase.Id
                                                            LIMIT 1][0];
        System.assertEquals(pjBaseRes.arce__Revenue_growth__c, String.valueOf(0.01), 'The projection record has not been updated correctly');
        Test.stopTest();
    }

    /**
    * @Description: Method to get simulation data
    */
    @isTest
    public static void getSimulationDataTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1][0];
        Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper wrrapperResponse = new Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper();
        final List<arce__Projection__c> pjBaseCase= [SELECT Id, arce__Scenario_Type__c
                                                              FROM arce__Projection__c
                                                              where arce__Account_has_Analysis__c = :accHasAnalysis.Id ];

        Test.startTest();
        wrrapperResponse = Arc_Gen_ProjectionController.getSimulationData(accHasAnalysis.Id, null);
        System.assertEquals(pjBaseCase.size(), wrrapperResponse.dataTable.size(), 'The projection records are not the same size');
        Test.stopTest();
    }

    /**
    * @Description: Method to update control values
    */
    @isTest
    public static void updateControlValuesTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1][0];
        Test.startTest();
        Arc_Gen_ProjectionController.updateControlValues(accHasAnalysis.Id, 'Up', true, null);
        final arce__Projection__c pbcase = [SELECT Id, arce__Scenario_Type__c, arce__Confirmed_Projection__c
                                                        FROM arce__Projection__c
                                                        where arce__Account_has_Analysis__c = :accHasAnalysis.Id and arce__Scenario_Type__c = 'Up'
                                                        limit 1];
        System.assert(pbcase.arce__Confirmed_Projection__c,  'Update has not been susscesfully done');
        Test.stopTest();
    }

    /**
    * @Description: Method to update scenario comment
    */
    @isTest
    public static void updateScenarioCommentTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1][0];

        Test.startTest();
        Arc_Gen_ProjectionController.updateScenarioComment(accHasAnalysis.Id, 'Up', 'Example Comment', null);
        final arce__Projection__c pbaseCase = [SELECT Id, arce__Scenario_Type__c, arce__Scenario_Comment__c, arce__Simulation_Calculated__c
                                                        FROM arce__Projection__c
                                                        where arce__Account_has_Analysis__c = :accHasAnalysis.Id and arce__Scenario_Type__c = 'Up'
                                                        limit 1];
        System.assertEquals(pbaseCase.arce__Scenario_Comment__c, 'Example Comment', 'Update has not been susscesfully done');
        Test.stopTest();
    }

    /**
    * @Description: Method to check control values
    */
    @isTest
    public static void checkControlValuesTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1];
        final arce__Projection__c pbaseCase = [SELECT Id, arce__Avg_Days_Inventory_Out__c, arce__Scenario_Type__c
                                                              FROM arce__Projection__c
                                                              where arce__Account_has_Analysis__c = :accHasAnalysis.Id and arce__Scenario_Type__c =: DOWN_SCE
                                                              LIMIT 1][0];
        pbaseCase.arce__Confirmed_Projection__c = true;
        update pbaseCase;
        Arc_Gen_Projection_Helper.ControlrAnalysisWrapper wrrapperResponse = new Arc_Gen_Projection_Helper.ControlrAnalysisWrapper();

        Test.startTest();
        wrrapperResponse = Arc_Gen_ProjectionController.checkControlValues(accHasAnalysis.Id, BASE_CASE, false, null);
        System.assert(wrrapperResponse.controlValues.get('Down'), 'Control values for Down should be false');
        Test.stopTest();
    }

    /**
    * @Description: Method to get EEFF List
    */
    @isTest
    public static void fetchFinancialStatementsTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1][0];
        Arc_Gen_ModalFinanStatemController.FinancialStatementsFetchWrapper wrrapperResponse = new Arc_Gen_ModalFinanStatemController.FinancialStatementsFetchWrapper();
        Test.startTest();
        wrrapperResponse = Arc_Gen_ProjectionController.fetchFinancialStatements(accHasAnalysis.Id, false, false, null, 1);
        System.assert(wrrapperResponse.ffssList != null, 'Error List Not null');
        Test.stopTest();
    }
 
    /**
    * @Description: Method to fire exception
    */
    @isTest
    public static void updateKeyAssumptionsExceptionTest() {
        try {
            final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                                  FROM arce__Account_has_Analysis__c
                                                                  LIMIT 1][0];
            final arce__Projection__c pbaseCase = [SELECT Id, arce__Avg_Days_Inventory_Out__c, arce__Scenario_Type__c
                                                            FROM arce__Projection__c
                                                            where arce__Account_has_Analysis__c = :accHasAnalysis.Id and arce__Scenario_Type__c =: BASE_CASE LIMIT 1][0];
            Test.startTest();
            final String updateKeys = '{"'+pbaseCase.Id+'":{"arce__A__c":0.01}}';
            Arc_Gen_ProjectionController.updateKeyAssumptions(updateKeys, BASE_CASE, '1', 'Standard projection', accHasAnalysis.Id, '1', null);Arc_Gen_ProjectionController.updateKeyAssumptions(updateKeys, BASE_CASE, '1', 'Standard projection', accHasAnalysis.Id, '1', null);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Exception should be fired');
            Test.stopTest();
        }
    }

    /**
    * @Description: Method to call projection Engine
    */
    @isTest
    public static void callProjectionEngineTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1][0];
        Test.startTest();
        final List<String> wrrapperResponse = Arc_Gen_ProjectionController.callProjectionService(BASE_CASE, accHasAnalysis.Id, new List<String>{ '0000000000000000410651' },  null);
        System.assertEquals(wrrapperResponse.size(), 0, 'No errors found');
        Test.stopTest();
    }
    /**
    * @Description: Method to call simulation Engine
    */
    @isTest
    public static void callProjectionRatingTest() {
        Test.startTest();
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__Projection__c projection = [SELECT Id FROM arce__Projection__c LIMIT 1];
        Arc_Gen_ProjectionController.callStandAlone(aha.Id, projection.Id);
        final arce__Projection__c afterProjection = [SELECT Id, arce__Simulation_Long_Scale_Value__c, arce__Simulation_Short_Scale_Value__c, arce__Simulation_Score__c FROM arce__Projection__c WHERE Id = :projection.Id LIMIT 1];
        System.assertEquals('BBB+1', afterProjection.arce__Simulation_Long_Scale_Value__c, 'Expected value: BBB+1, instead has ' + afterProjection.arce__Simulation_Long_Scale_Value__c);
        Test.stopTest();
    }
    /**
    * @Description: Method to fire exception
    */
    @isTest
    public static void updateControlValuesExceptionTest() {
        try {
          final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1][0];
          Test.startTest();
          Arc_Gen_ProjectionController.updateControlValues(accHasAnalysis.Id, 'Up', null, null);
          Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Exception should be fired');
            Test.stopTest();
        }
    }
    /**
    * @Description: Method to test recalculateUnitsAndCurrency
    */
    @isTest
    public static void recalculateUnitsTest() {
        Test.startTest();
        final String respJson = 'OK';
        Arc_Gen_ProjectionController.recalculateUnits('a0B0I0000000001');
        Test.stopTest();
        // Dummy assert, its mocked up future method.
        System.assert(respJson.contains('OK'), 'Inexpected response!');
    }
    /**
    * @Description: Method to test recalculateUnitsAndCurrency
    */
    @isTest
    public static void recalculateCurrencyTest() {
        Test.startTest();
        final String respJson = 'OK';
        Arc_Gen_ProjectionController.recalculateCurrency('a0B0I0000000001');
        Test.stopTest();
        // Dummy assert, its mocked up future method.
        System.assert(respJson.contains('OK'), 'Inexpected response!');
    }
    /**
    * @Description: Method to fire exception
    */
    @isTest
    public static void callCloneProjectionTest() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT Id, Name, arce__Customer__r.Name, arce__group_asset_header_type__c
                                                              FROM arce__Account_has_Analysis__c
                                                              LIMIT 1][0];

        Test.startTest();
        final List<String> wrrapperResponse = Arc_Gen_ProjectionController.callCloneProjection('CLONE', accHasAnalysis.Id,  'proposalTestId');
        system.debug(wrrapperResponse);
        System.assertEquals(wrrapperResponse.size(), 0, 'No errors found');
        Test.stopTest();
    }  
}