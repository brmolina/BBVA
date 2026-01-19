/*------------------------------------------------------------------
* @File Name: Arc_Gen_NewModalFinanStatemController.cls
* @Author:        ARCE Team
* @Group:      	  ARCE - BBVA Bancomer
* @Description:   Controller to modal Arc_Gen_NewModalFinanStatem.
* @Changes :
* Methods to get and process FinancialStatemnt from ASO

*_______________________________________________________________________________________
*Version    Date           Author                               Description
*1.0        10/12/2023     ARCE TEAM   							Creación.
-----------------------------------------------------------------------------------------*/
@isTest
public with sharing class Arc_Gen_NewModalFinanStatemCon_Test {
    /*
    * @Description STRPARAM0
    */
    private static final String STRPARAM0 = '{ "id" : "70202017129", "submitType" : "1", "validType" : "1", "adjustedType" : "1", "cerType" : "AUDITED", "dateType" : "2"}';
    /*
    * @Description STRPARAM1
    */
    private static final String STRPARAM1 = '{ "id" : "70202018131", "submitType" : "1", "validType" : "1", "adjustedType" : "2", "cerType" : "AUDITED", "dateType" : "0"}';
    /*
    * @Description STRPARAM2
    */
    private static final String STRPARAM2 = '{ "id" : "70202018130", "submitType" : "1", "validType" : "1", "adjustedType" : "2", "cerType" : "FISCAL", "dateType" : "0"}';
    /*
    * @Description STRPARAM3
    */
    private static final String STRPARAM3 = '{ "id" : "70202018133", "submitType" : "1", "validType" : "1", "adjustedType" : "2", "cerType" : "TRADE_REGISTRY", "dateType" : "0"}';
    /*
    * @Description STRPARAM5
    */
    private static final String STRPARAM5 = '{ "id" : "70202018132", "submitType" : "1", "validType" : "1", "adjustedType" : "2", "cerType" : "AUDITED", "dateType" : "2"}';
    /*
    * @Description CASHFLOW_LIT
    */
    private static final String CASHFLOW_LIT ='cash_flow_analysis';
    /*
    * @Description G000001_LIT
    */
    private static final String G000001_LIT ='G000001';
    /*
    * @Description C000001_LIT
    */
    private static final String C000001_LIT ='C000001';
    /**
    * --------------------------------------------------------------------------------------
    * @Description setup method
    * --------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_ModalFinanStatemController_test.setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{G000001_LIT, C000001_LIT});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(G000001_LIT);
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(C000001_LIT);

        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('Generic', '100', '1', null);
        insert newSector;

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        insert newArce;

        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        newAnalysis.arce__main_subsidiary_ind_type__c = false;
        insert newAnalysis;
        Arc_UtilitysDataTest_tst.newExtensionForAHA(newAnalysis);

        final arce__Account_has_Analysis__c newChildAcc = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, childAccount.accId, '1');
        newChildAcc.arce__main_subsidiary_ind_type__c = false;
        insert newChildAcc;
        Arc_UtilitysDataTest_tst.newExtensionForAHA(newChildAcc);

        final arce__rating__c rating = Arc_UtilitysDataTest_tst.crearRating(null);
        insert rating;

        final arce__Financial_Statements__c finStatement0 = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.id, rating.id, null);
        Arc_UtilitysDataTest_tst.setupFFSS(finStatement0, STRPARAM0);

        final arce__Financial_Statements__c finStatement1 = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.id, rating.id, null);
        Arc_UtilitysDataTest_tst.setupFFSS(finStatement1, STRPARAM1);

        final arce__Financial_Statements__c finStatement2 = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.id, rating.id, null);
        Arc_UtilitysDataTest_tst.setupFFSS(finStatement2, STRPARAM2);

        final arce__Financial_Statements__c finStatement3 = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.id, rating.id, null);
        Arc_UtilitysDataTest_tst.setupFFSS(finStatement3, STRPARAM3);

        final arce__Financial_Statements__c finStatement4 = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.id, rating.id, null);
        finStatement4.arce__ffss_valid_type__c = '1';
        finStatement4.arce__financial_statement_id__c = 'dummyFFSS';

        final arce__Financial_Statements__c finStatement5 = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.id, rating.id, null);
        Arc_UtilitysDataTest_tst.setupFFSS(finStatement5, STRPARAM5);

        final List<arce__Financial_Statements__c> lstFFSS = new List<arce__Financial_Statements__c>();
        lstFFSS.add(finStatement0);
        lstFFSS.add(finStatement1);
        lstFFSS.add(finStatement2);
        lstFFSS.add(finStatement3);
        lstFFSS.add(finStatement4);
        lstFFSS.add(finStatement5);
        insert lstFFSS;

        final arce__Data_Collections__c dataCollection = Arc_UtilitysDataTest_tst.crearDataCollection('Cash Flow Analysis', CASHFLOW_LIT, '04');
        dataCollection.arce__collection_code_term__c = 'workingCapital';
        insert dataCollection;

        final arce__Table_Content_per_Analysis__c tableCAnalysis = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(newAnalysis.id, dataCollection.id, CASHFLOW_LIT, '2017');
        insert tableCAnalysis;

        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;

        final arce__Overlay__c overlay = new arce__Overlay__c();
        overlay.arce__Account_has_AnalysisId__c = newAnalysis.Id;
        insert overlay;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description test testGetDynamicColumns
    * --------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example testGetDynamicColumns()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGetDynamicColumns() {
        Test.startTest();
        final String response = Arc_Gen_NewModalFinanStatemController.dynamicColumnsRTC();
        System.assert(!String.isEmpty(response), 'Wrong response');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description test method
    * --------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example testFetchAccounts()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testFetchAccounts() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT arce__financial_statement_id__c FROM arce__Account_has_Analysis__c limit 1];
        final arce__Financial_Statements__c finStatement = [SELECT arce__financial_statement_id__c FROM arce__Financial_Statements__c limit 1];
        Test.startTest();
        final Arc_Gen_ModalFinanStatemController.FinancialStatementsFetchWrapper analysisResponse =
        Arc_Gen_NewModalFinanStatemController.fetchFinancialStatements(accHasAnalysis.id, true, null, null);
        system.assertEquals(finStatement.arce__financial_statement_id__c,
            analysisResponse.ffssList[0].arce__financial_statement_id__c, 'testFetchAccounts Id do not match');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method
    * --------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example testFetchAccountsFail()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testFetchAccountsFail() {
        Test.startTest();
        try {
            Arc_Gen_NewModalFinanStatemController.fetchFinancialStatements(null, false, null, null);
            System.assert(false, 'The call to the above method must have thrown an exception.');
        } catch(Exception ex) {
            System.debug('testFetchAccountsFail failed ex ' + ex);
        }
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method
    * --------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example testFetchAccountsTriageStep()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testFetchAccountsTriageStep() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT arce__financial_statement_id__c FROM arce__Account_has_Analysis__c limit 1];
        final arce__Financial_Statements__c finStatement = [SELECT arce__financial_statement_id__c FROM arce__Financial_Statements__c limit 1];
        Test.startTest();
        final Arc_Gen_ModalFinanStatemController.FinancialStatementsFetchWrapper analysisResponse =
        Arc_Gen_NewModalFinanStatemController.fetchFinancialStatements(accHasAnalysis.id, true, '000000', null);
        system.assertEquals(finStatement.arce__financial_statement_id__c,
            analysisResponse.ffssList[0].arce__financial_statement_id__c, 'testFetchAccounts Id do not match');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method
    * --------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example testFetchFinancialRatingTool()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testFetchFinancialRatingTool() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT arce__financial_statement_id__c FROM arce__Account_has_Analysis__c limit 1];
        final arce__Financial_Statements__c finStatement = [SELECT arce__financial_statement_id__c FROM arce__Financial_Statements__c limit 1];
        Test.startTest();
        Arc_Gen_NewModalFinanStatemController.getSplittedMdtValue('RatioEngine_Error_Pos');
        final Arc_Gen_ModalFinanStatemController.FinancialStatementsFetchWrapper analysisResponse =
        Arc_Gen_NewModalFinanStatemController.fetchFinancialStatements(accHasAnalysis.id, true, '000000', null);
        system.assertEquals(finStatement.arce__financial_statement_id__c,
            analysisResponse.ffssList[0].arce__financial_statement_id__c, 'testFetchAccounts Id do not match');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description call testAddToWfValue test method
    * --------------------------------------------------------------------------------------
    * @Author  isabel.ascaso.contractor@bbva.com
    * @Date    19/12/2023
    * @param   void
    * @return  void
    * @example testAddToWfValue()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testAddToWfValue() {
        Test.startTest();
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues = new List<Arc_Gen_RatingAsIndepProcess_controller.WfValue>();
        Arc_Gen_NewModalFinanStatemController.addToWfValue(wfValues,new List<String>{Arc_Gen_NewModalFinanStatemController.RATING_LABEL, 'Prerating'});
        System.assertEquals(2, wfValues.size(), 'Error testAddToWfValue');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description call testAddToWfValue test method
    * --------------------------------------------------------------------------------------
    * @Author  isabel.ascaso.contractor@bbva.com
    * @Date    19/12/2023
    * @param   void
    * @return  void
    * @example testisRating()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testisRating() {
        Test.startTest();
        final Boolean isRating = Arc_Gen_NewModalFinanStatemController.isRating('2012P1','Corp');
        System.assert(isRating, 'Error isRating');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description call testCallEngineFinancialState test method
    * --------------------------------------------------------------------------------------
    * @Author  isabel.ascaso.contractor@bbva.com
    * @Date    22/02/2024
    * @param   void
    * @return  void
    * @example testCallEngineFinancialState()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testCallEngineFinancialState() {
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT id, arce__financial_statement_id__c FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Financial_Statements__c> finStatement = [SELECT arce__financial_statement_id__c, arce__Order__c FROM arce__Financial_Statements__c LIMIT 2];
        final List<String> finStatList = new List<String>{finStatement[0].arce__financial_statement_id__c};
        Test.startTest();
        final Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse response = Arc_Gen_NewModalFinanStatemController.callEngineFinancialState(accHasAnalysis.Id,finStatement, finStatList, true, false, '', '['+finStatement[0].arce__financial_statement_id__c+']');
        System.assertEquals('Success', response.ratiosStatus, 'The engine financial State failed');
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description call testCallEngineFinancialState test method
    * --------------------------------------------------------------------------------------
    * @Author  isabel.ascaso.contractor@bbva.com
    * @Date    22/02/2024
    * @param   void
    * @return  void
    * @example testGetVariablesButton()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGetVariablesButton() {
        final arce__Analysis__c analysis = [SELECT id FROM arce__Analysis__c limit 1];
        final arce__Account_has_Analysis__c accHasAnalysis = [SELECT id, arce__financial_statement_id__c FROM arce__Account_has_Analysis__c limit 1];
        Test.startTest();
        final Map<String,String> response = Arc_Gen_NewModalFinanStatemController.getVariablesButton(analysis.Id);
        System.assertEquals(accHasAnalysis.Id, response.get('accHasAnalysisId'), 'The variable id is incorrect');
        Test.stopTest();
    }
}