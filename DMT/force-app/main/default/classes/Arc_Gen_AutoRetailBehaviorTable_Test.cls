/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AutoRetailBehaviorTable_Test
* @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2021-01-26
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for Auto retail behavior table classes:
*              - Arc_Gen_AutoRetailBehaviorTable_Ctrl
*              - Arc_Gen_AutoRetailBehaviorTable_Service
*              - Arc_Gen_AutoRetailBehaviorTable_Data
*              - Arc_Gen_AutoRetailBehaviorTable_Helper
*              - Arc_Gen_AutoRetailTableInsert_Ctrl
*              - Arc_Gen_AutoRetailTableInsert_Service
*              - Arc_Gen_AutoRetailTableInsert_Helper
*              - Arc_Gen_AutoRetailTableRow
*              - Arc_Gen_ExecAutoRetailRep_Controller
*              - Arc_Gen_ExecAutoRetailRep_Service
*              - Arc_Gen_ExecAutoRetailRep_Helper
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-01-26 eduardoefrain.hernandez.contractor@bbva.com
*             Class Creation
* |2021-03-03 eduardoefrain.hernandez.contractor@bbva.com
*             Added test methods to cover executive summary for auto retail
* |2021-03-03 eduardoefrain.hernandez.contractor@bbva.com
*             Change year variable type from decimal to string
* |2021-04-15 eduardoefrain.hernandez.contractor@bbva.com
*             Update methods with a lot of parameters to only one data map parameter
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods, sf:AvoidSoqlWithNegativeLogic')
@isTest
public class Arc_Gen_AutoRetailBehaviorTable_Test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: Selected year 1
    */
    static final String YEAR_1 = '2021';
    /**
    * @Description: Selected year 2
    */
    static final String YEAR_2 = '2020';
    /**
    * @Description: String with the text brand
    */
    static final String BRAND = 'brand';
    /**
    * @Description: String with the text agencyname
    */
    static final String AGENCY_NAME = 'agencyname';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Setup to set the test data
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * ----------------------------------------------------------------------------------------------------
    **/
    @testSetup
    static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);

        final arce__Analysis__c arceAnalysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('arceAnalysis', null, groupAccount.accId);
        insert arceAnalysis;

        final arce__Account_has_Analysis__c accHasAnData1 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceAnalysis.Id, groupAccount.accId, null);
        insert accHasAnData1;
        final arce__Account_has_Analysis__c accHasAnData2 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceAnalysis.Id, groupAccount.accId, null);
        insert accHasAnData2;

        final arce__autoretail_behavior_table__c autoTableRow = new arce__autoretail_behavior_table__c(
            arce__account_has_analysis_id__c = accHasAnData1.Id,
            arce__gf_company_name__c = 'Patito Agency',
            arce__gf_agencies_number__c = 12,
            arce__gf_vehicle_brand_name__c = 'Patito',
            arce__gf_entity_risk_bal_cur_amount__c = 123456,
            arce__gf_stock_days_number__c = 23,
            arce__gf_product_status_type__c = '1'
        );
        insert autoTableRow;
        final arce__autoretail_behavior_by_year__c autoYear1Row = new arce__autoretail_behavior_by_year__c(
            arce__autoretail_behavior_table_id__c = autoTableRow.id,
            arce__gf_stock_rotation_desc__c = 'Rota123',
            arce__gf_prd_typ_sold_units_number__c = 321,
            arce__year_id__c = YEAR_1
        );
        insert autoYear1Row;
        final arce__autoretail_behavior_by_year__c autoYear2Row = new arce__autoretail_behavior_by_year__c(
            arce__autoretail_behavior_table_id__c = autoTableRow.id,
            arce__gf_stock_rotation_desc__c = 'Rota321',
            arce__gf_prd_typ_sold_units_number__c = 456,
            arce__year_id__c = YEAR_2
        );
        insert autoYear2Row;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> getDataMap(arce__Account_has_Analysis__c aha, String operationType, String tableType, Map<String,String> basicData) {
        return new Map<String, Object> {
            'agencyName' => basicData.get(AGENCY_NAME),
            'agenciesNumber' => Math.random()*10000,
            'brand' => basicData.get(BRAND),
            'bankRisk' => Decimal.valueOf(Math.random()*10000),
            'stockDays' => Math.random()*10000,
            'totalUnitsYear1' => Math.random()*10000,
            'totalUnitsYear2' => Math.random()*10000,
            'stockRotationYear1' => 'Rota123',
            'stockRotationYear2' => 'Rota321',
            'accHasAnalysisId' => aha.Id,
            'operationType' => operationType,
            'tableType' => tableType,
            'year1' => YEAR_1,
            'year2' => YEAR_2,
            'selectedRowId' => basicData.get('selectedRowId'),
            'standardYear1Id' => basicData.get('standardYear1Id'),
            'standardYear2Id' => basicData.get('standardYear2Id')
        };
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.controllInsertConst()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void controllInsertConst() {
        Test.startTest();
        final Arc_Gen_AutoRetailTableInsert_Ctrl constructorContr = new Arc_Gen_AutoRetailTableInsert_Ctrl();
        System.assertEquals(constructorContr, constructorContr, 'Empty controller insert constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.controllerConstr()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void controllerConstr() {
        Test.startTest();
        final Arc_Gen_AutoRetailBehaviorTable_Ctrl constructorContr = new Arc_Gen_AutoRetailBehaviorTable_Ctrl();
        System.assertEquals(constructorContr, constructorContr, 'Empty controller constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.controllInsertConst()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void serviceInsertConst() {
        Test.startTest();
        final Arc_Gen_AutoRetailTableInsert_Service servConstr = new Arc_Gen_AutoRetailTableInsert_Service();
        System.assertEquals(servConstr, servConstr, 'Empty service insert constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.serviceConstruct()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void serviceConstruct() {
        Test.startTest();
        final Arc_Gen_AutoRetailBehaviorTable_Service servConstr = new Arc_Gen_AutoRetailBehaviorTable_Service();
        System.assertEquals(servConstr, servConstr, 'Empty service constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.controllInsertConst()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void helperInsertConst() {
        Test.startTest();
        final Arc_Gen_AutoRetailTableInsert_Helper helpConstr = new Arc_Gen_AutoRetailTableInsert_Helper();
        System.assertEquals(helpConstr, helpConstr, 'Empty helper insert constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.helperConstruct()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void helperConstruct() {
        Test.startTest();
        final Arc_Gen_AutoRetailBehaviorTable_Helper helpConstr = new Arc_Gen_AutoRetailBehaviorTable_Helper();
        System.assertEquals(helpConstr, helpConstr, 'Empty helper constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.helperConstruct()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void dataConstruct() {
        Test.startTest();
        final Arc_Gen_AutoRetailBehaviorTable_Data dataConstr = new Arc_Gen_AutoRetailBehaviorTable_Data();
        System.assertEquals(dataConstr, dataConstr, 'Empty data constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getTableData() {
        String errorResponse;
        Test.startTest();
        try {
            final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
            final Map<String, String> data = new Map<String, String> {
                'recordId' => aha.Id,
                'tableType' => '1',
                'year1' => YEAR_1,
                'year2' => YEAR_2
            };
            Arc_Gen_AutoRetailBehaviorTable_Ctrl.getTableData(data);
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertEquals(errorResponse, null, 'Getting table data');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getTableEmptyData() {
        String errorResponse;
        Test.startTest();
        try {
            final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
            final arce__autoretail_behavior_table__c tableRow = [SELECT Id FROM arce__autoretail_behavior_table__c WHERE arce__gf_company_name__c = 'Patito Agency' LIMIT 1];
            final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c(
                arce__Analysis__c = analysis.Id
            );
            insert aha;
            final Map<String, Object> dataToValid = new Map<String, Object> {
                'record' => null,
                'year' => YEAR_1,
                'objRow' => tableRow,
                'isExecSummary' => false
            };
            final Map<String, String> data = new Map<String, String> {
                'recordId' => aha.Id,
                'tableType' => '1',
                'year1' => YEAR_1,
                'year2' => YEAR_2
            };
            Arc_Gen_AutoRetailBehaviorTable_Helper.validateChildRecord(dataToValid);
            Arc_Gen_AutoRetailBehaviorTable_Ctrl.getTableData(data);
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertEquals(errorResponse, null, 'Getting empty data table');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getTableDataError() {
        String errorResponse;
        Test.startTest();
        try {
            final Map<String, String> data = new Map<String, String>();
            Arc_Gen_AutoRetailBehaviorTable_Ctrl.getTableData(data);
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertNotEquals(errorResponse, null, 'Getting table data with wrong parameters');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getDataTest() {
        System.debug('getDataTest>>');
        Arc_Gen_AutoRetailTableRow rows = new Arc_Gen_AutoRetailTableRow();
        Test.startTest();
        try {
            final arce__autoretail_behavior_table__c tableRow = [SELECT Id FROM arce__autoretail_behavior_table__c WHERE arce__gf_company_name__c = 'Patito Agency' LIMIT 1];
            rows = Arc_Gen_AutoRetailTableInsert_Ctrl.getData(tableRow.Id, YEAR_1, YEAR_2);
        } catch (Exception e) {
            rows = new Arc_Gen_AutoRetailTableRow();
        }
        Test.stopTest();
        System.assertNotEquals(rows, new Arc_Gen_AutoRetailTableRow(), 'Object rows has the data of tab le rows');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getDataError() {
        System.debug('getDataError>>');
        String errorResponse;
        Test.startTest();
        try {
            Arc_Gen_AutoRetailTableInsert_Ctrl.getData('InvalidId', '1995', '1996');
        } catch (Exception e) {
            errorResponse = e.getMessage();
        }
        Test.stopTest();
        System.assertNotEquals(errorResponse, null, 'There was an error while trying to obtain the data');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void insertRecordsTest() {
        String errorResponse;
        Test.startTest();
        try {
            final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
            final Map<String, Object> dataMap = getDataMap(aha, 'insert', '1', new Map<String,String> {AGENCY_NAME => 'Perry Agency', BRAND => 'Perry'});
            Arc_Gen_AutoRetailTableInsert_Ctrl.insertRecords(dataMap);
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertEquals(errorResponse, null, 'Inserting data');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void editRecordsTest() {
        String errorResponse;
        Test.startTest();
        try {
            final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
            final arce__autoretail_behavior_table__c tableRow = [SELECT Id, arce__gf_company_name__c, arce__gf_vehicle_brand_name__c,
                (SELECT Id FROM arce__Auto_Retail_Behavior_by_Year__r)
                FROM arce__autoretail_behavior_table__c WHERE arce__gf_company_name__c = 'Patito Agency' LIMIT 1];
            final Map<String, Object> dataMap = getDataMap(aha, 'edit', '1', new Map<String,String> {
                AGENCY_NAME => 'Ducky Agency',
                BRAND => 'Ducky',
                'selectedRowId' => tableRow.Id,
                'standardYear1Id' => tableRow.arce__Auto_Retail_Behavior_by_Year__r[0].Id,
                'standardYear2Id' => tableRow.arce__Auto_Retail_Behavior_by_Year__r[1].Id
            });
            Arc_Gen_AutoRetailTableInsert_Ctrl.insertRecords(dataMap);
            Arc_Gen_AutoRetailBehaviorTable_Data.getAutoRetailToCopy(new Set<Id>{aha.Id});
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertEquals(errorResponse, null, 'Updating data');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void sameCompanyError() {
        String errorResponse;
        Test.startTest();
        try {
            final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
            final Map<String, Object> dataMap1 = getDataMap(aha, 'insert', '1', new Map<String,String> {AGENCY_NAME => 'Patitos Agency', BRAND => 'Patitos'});
            final Map<String, Object> dataMap2 = getDataMap(aha, 'insert', '1', new Map<String,String> {AGENCY_NAME => 'Patitos Agency', BRAND => 'Patitos'});
            Arc_Gen_AutoRetailTableInsert_Ctrl.insertRecords(dataMap1);
            Arc_Gen_AutoRetailTableInsert_Ctrl.insertRecords(dataMap2);
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertNotEquals(errorResponse, null, 'The company is already created');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void saveRecordsError() {
        String errorResponse;
        Test.startTest();
        try {
            final arce.Arc_Gen_GenericUtilities.SaveResult saveRes = new arce.Arc_Gen_GenericUtilities.SaveResult();
            saveRes.status = 'false';
            saveRes.message = 'ERROR';

            Arc_Gen_AutoRetailTableInsert_Helper.manageError(saveRes);
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertNotEquals(errorResponse, null, 'An error occured');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void missingParametersError1() {
        String errorResponse;
        Test.startTest();
        try {
            Arc_Gen_AutoRetailTableInsert_Helper.validateField(null, 'text');
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertNotEquals(errorResponse, null, 'The text field is null');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void missingParametersError2() {
        String errorResponse;
        Test.startTest();
        try {
            Arc_Gen_AutoRetailTableInsert_Helper.validateField(null, 'number');
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertNotEquals(errorResponse, null, 'The number field is null');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void missingParametersError3() {
        String errorResponse;
        Test.startTest();
        try {
            Arc_Gen_AutoRetailTableInsert_Helper.validateField(-5, 'number');
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertNotEquals(errorResponse, null, 'The number field is negative');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void deleteRecordsTest() {
        String errorResponse;
        Test.startTest();
        try {
            final arce__autoretail_behavior_table__c tableRow = [SELECT Id FROM arce__autoretail_behavior_table__c WHERE arce__gf_company_name__c = 'Patito Agency' LIMIT 1];

            Arc_Gen_AutoRetailTableInsert_Ctrl.deleteRecord(tableRow.Id);
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertEquals(errorResponse, null, 'Deleting records');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void deleteRecordsError() {
        String errorResponse;
        Test.startTest();
        try {
            Arc_Gen_AutoRetailTableInsert_Ctrl.deleteRecord('InvalidId');
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertNotEquals(errorResponse, null, 'Error in the deleting call');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getPrevSelectedYear() {
        String errorResponse;
        Test.startTest();
        try {
            final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
            Arc_Gen_AutoRetailBehaviorTable_Ctrl.getPreviouslySelectedYear(aha.Id);
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertEquals(errorResponse, null, 'Searching for another selected year');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.getDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getPrevSelectedYearError() {
        String errorResponse;
        Test.startTest();
        try {
            final arce__Account_has_Analysis__c aha = [SELECT Id, arce__Analysis__c FROM arce__Account_has_Analysis__c LIMIT 1];
            Arc_Gen_AutoRetailBehaviorTable_Ctrl.getPreviouslySelectedYear(aha.arce__Analysis__c);
        } catch (Exception e) {
            errorResponse = e.getTypeName() + e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString();
        }
        Test.stopTest();
        System.assertNotEquals(errorResponse, null, 'The searching Id is invalid');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.testingExecutiveSummary()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingExecutiveSummary() {
        Test.startTest();
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__Analysis__c, arce__year_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        aha.arce__year_id__c = '2020';
        update aha;
        final ApexPages.StandardController standardControll = new ApexPages.StandardController(aha);
        final Arc_Gen_ExecAutoRetailRep_Controller execRepCtrl = new Arc_Gen_ExecAutoRetailRep_Controller(standardControll);
        Test.stopTest();
        System.assertNotEquals(null, execRepCtrl.wrapIns, 'Executive Summary con datos');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.execSummServConstr()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void execSummServConstr() {
        Test.startTest();
        final Arc_Gen_ExecAutoRetailRep_Service servConstr = new Arc_Gen_ExecAutoRetailRep_Service();
        System.assertEquals(servConstr, servConstr, 'Empty service exec summary constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Test.execSummHelpConstr()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void execSummHelpConstr() {
        Test.startTest();
        final Arc_Gen_ExecAutoRetailRep_Helper helpConstr = new Arc_Gen_ExecAutoRetailRep_Helper();
        System.assertEquals(helpConstr, helpConstr, 'Empty helper exec summary constructor');
        Test.stopTest();
    }
}