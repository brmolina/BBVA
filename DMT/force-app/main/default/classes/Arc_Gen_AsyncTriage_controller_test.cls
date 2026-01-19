/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AsyncTriage_controller_test
* @Author   Ricardo Almanza Angeles  ricardo.almanza.contractor@bbva.com
* @Date     Created: 02/04/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class for webservice
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |02/04/2020 ricardo.almanza.contractor@bbva.com
*             Class creation.
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-08-11 manuelhugo.castillo.contractor@bbva.com
*             Update coverage
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-04-29 david.rivas.abad.contractor@bbva.com
*             Deleted variables that not used.
* |2021-05-13 otiliaramona.veres.contractor.capacitacion@bbva.com
*             Declared final some local variables
*             Fixed some string literal as static final string
*             Fixed name some local variables very short
*             Deleted unused variable 'analysis2'
*             Declared static final String with JSON value
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:NcssMethodCount')
@istest
public class Arc_Gen_AsyncTriage_controller_test {
    /**
    * @Description : String with value 'Test constructor'
    */
    static final String TEST_CONST = 'Test constructor';
    /**
    * @Description : String with value 'C000001'
    */
    static final String PART_ID = 'C000001';
    /**
    * @Description : String with value 'Value match succesfully'
    */
    static final String SUCCESS_ASSERT = 'Value match succesfully';
    /**
    * @Description : String with JSON value
    */
    static final String JSON_MSG = '{"data": {"controls": [{"id": "asynch","description": "Call Asynchronous Triage","isValid": false},{"id": "CT016","description": "The participant 174916181111 is LARGE_ENTERPRISES ","isValid": true}],"economicGroupParticipants": [{"id": "174916181111","participantType": {"id": "SUBSIDIARY"},"isInScope": true,"riskSegment": "ENTERPRISES","bank": {"id": "40012","branch": {"id": "9105"}},"analysisModelType": {"id": "H"},"rating": {"tool": {"id": "04127023712300000000"},"cyclicitySectorAxis": "1","modelType": {"id": "7023"}},"template": "1","financialStatement": {"id": "70232018120","currency": "MXN","period": {"unit": "MONTHS","number": 12},"unit": "UNITS","totalRevenues": {"amount": 480441000,"currency": "MXN"}},"primaryAnalysisType": "BOTTOM_UP"},{"id": "CAONlXcCA_uxyJ402AA_xw","participantType": {"id": "GROUP"},"isInScope": true,"riskSegment": "ENTERPRISES","template": "1","financialStatement": {"id": "0","currency": "MXN","period": {"unit": "MONTHS","number": 0},"unit": "MILLIONS","totalRevenues": {"amount": 0,"currency": "MXN"}},"primaryAnalysisType": "BOTTOM_UP"}]}}';

    static testMethod void  updateNoParamTest() {
        final Arc_Gen_AsyncTriage_controller reqst = new Arc_Gen_AsyncTriage_controller();
        final Arc_Gen_AsyncTriage_helper hlpr = new Arc_Gen_AsyncTriage_helper();
        system.assertNotEquals(null, hlpr, TEST_CONST);
        final String jsonMsg=JSON.serialize(reqst);
        Test.startTest();
        final RestRequest req = new RestRequest();
        final RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/DemoUrl';  //Request URL
        req.httpMethod = 'POST';//HTTP Request Type
        req.requestBody = Blob.valueof(jsonMsg);
        RestContext.request = req;
        RestContext.response= res;
        try {
            Arc_Gen_AsyncTriage_controller.apiService();
        } catch(Arc_Gen_AsyncTriage_helper.InvalidParametersException e) {
            system.assertNotEquals(e, null, 'Invalid Parameter Val');
        }
        Test.stopTest();
    }
    static testMethod void  updatePartParamTest() {
        final Arc_Gen_AsyncTriage_controller reqst=new Arc_Gen_AsyncTriage_controller();
        final String jsonMsg=JSON.serialize(reqst);
        Test.startTest();
        final RestRequest req = new RestRequest();
        final RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TriageCallback/createNotifyResult/v1';  //Request URL
        req.addParameter('risk-assessment-id', 'dummy');
        req.addParameter('participant-id', PART_ID);
        req.httpMethod = 'POST';//HTTP Request Type
        req.requestBody = Blob.valueof(jsonMsg);
        RestContext.request = req;
        RestContext.response= res;
        final Arc_Gen_AsyncTriage_controller astc = new Arc_Gen_AsyncTriage_controller();
        system.assertNotEquals(null, astc, TEST_CONST);
        final Arc_Gen_Triage_helper agth = new Arc_Gen_Triage_helper();
        system.assertNotEquals(null, agth, TEST_CONST);
        final Arc_Gen_Triage_data agtd = new Arc_Gen_Triage_data();
        system.assertNotEquals(null, agtd, TEST_CONST);
        try {
            Arc_Gen_AsyncTriage_controller.apiService();
        } catch(Arc_Gen_AsyncTriage_helper.InvalidParametersException e) {
            system.assertNotEquals(e, null, 'Invalid Parameter Val');
        }
        Test.stopTest();
    }
    static testMethod void  updateParamTest() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String> {'G000001',PART_ID});
        final arce.Arc_Gen_Account_Wrapper fath = groupAccWrapper.get('G000001');
        final arce.Arc_Gen_Account_Wrapper kid = groupAccWrapper.get(PART_ID);
        Final arce__limits_typology__c limits1 = Arc_UtilitysDataTest_tst.crearLimitTypology(System.Label.Arc_Gen_ExecRepTipologyTCR, null, null);
        limits1.arce__risk_typology_level_id__c = 'TP_0006';
        limits1.arce__risk_typology_level_type__c = '1';
        limits1.arce__Typology_Order__c = 1;
        Insert limits1;
        final arce__limits_typology__c ll1 = Arc_UtilitysDataTest_tst.crearLimitTypology(System.Label.Arc_Gen_ExecRepTipologyTCR+'1', null, null);
        ll1.arce__risk_typology_level_id__c = 'TP_0003';
        ll1.arce__risk_typology_level_type__c = '1';
        ll1.arce__Typology_Order__c = 1;
        Insert ll1;
        final arce__limits_typology__c ll2 = Arc_UtilitysDataTest_tst.crearLimitTypology('Ll2', ll1.Id, null);
        Insert ll2;
        final arce__limits_typology__c lll1 = Arc_UtilitysDataTest_tst.crearLimitTypology(System.Label.Arc_Gen_ExecRepTipologyTCR+'2', null, null);
        lll1.arce__risk_typology_level_id__c = 'TP_0013';
        lll1.arce__risk_typology_level_type__c = '1';
        lll1.arce__Typology_Order__c = 1;
        Insert lll1;
        final arce__limits_typology__c lll2 = Arc_UtilitysDataTest_tst.crearLimitTypology('Ll2', lll1.Id, null);
        Insert lll2;
        Final arce__limits_typology__c limits2 = Arc_UtilitysDataTest_tst.crearLimitTypology('L2', limits1.Id, null);
        Insert limits2;
        Final arce__Analysis__c analysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Test Analysis', null, fath.accId);
        Insert analysis;
        Final arce__Sector__c sect = Arc_UtilitysDataTest_tst.crearSector('Executive Summ', '500', 'ExecSumm', null);
        Insert sect;
        Final arce__Account_has_Analysis__c accHasAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, kid.accId, '1');
        Insert accHasAnalysis;
        final arce__limits_exposures__c lim1 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,limits1.Id);
        Insert lim1;
        final arce__limits_exposures__c lim2 = Arc_UtilitysDataTest_tst.crearLimitExposures(lim1.Id,null,accHasAnalysis.Id,limits2.Id);
        Insert lim2;
        final arce__limits_exposures__c lim3 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,ll1.Id);
        Insert lim3;
        final arce__limits_exposures__c lim4 = Arc_UtilitysDataTest_tst.crearLimitExposures(lim3.Id,null,accHasAnalysis.Id,ll2.Id);
        Insert lim4;
        final arce__limits_exposures__c lim5 = Arc_UtilitysDataTest_tst.crearLimitExposures(null,null,accHasAnalysis.Id,lll1.Id);
        Insert lim5;
        final arce__limits_exposures__c lim6 = Arc_UtilitysDataTest_tst.crearLimitExposures(lim5.Id,null,accHasAnalysis.Id,lll2.Id);
        Insert lim6;
        final arce__limits_exposures__c mod = Arc_UtilitysDataTest_tst.crearLimitExposures(lim2.Id,null,accHasAnalysis.Id,null);
        mod.arce__curr_apprv_deleg_dchan_amount__c = 1;
        mod.arce__currency_id__c = 'MXN';
        Insert mod;
        Final arce__Data_Collections__c colls = Arc_UtilitysDataTest_tst.crearDataCollection('E.B.I.T.D.A.', 'Income_Statement','03');
        Insert colls;
        Final arce__Table_Content_per_Analysis__c tblCont = Arc_UtilitysDataTest_tst.crearTableContentAnalysis(accHasAnalysis.Id, colls.Id, 'Income_Statement','2019');
        tblCont.arce__collection_order_type__c='3200';
        Insert tblCont;
        Test.startTest();
        final arce__Account_Has_Analysis__c aha = [Select Id, Name, arce__Analysis__c from arce__Account_has_Analysis__c LIMIT 1];
        final RestRequest req = new RestRequest();
        final RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TriageCallback/createNotifyResult/v1';  //Request URL
        req.addParameter('risk-assessment-id', aha.Name);
        req.addParameter('participant-id', PART_ID);
        req.httpMethod = 'POST';//HTTP Request Type
        req.requestBody = Blob.valueof(JSON_MSG);
        RestContext.request = req;
        RestContext.response= res;
        try {
            Arc_Gen_AsyncTriage_controller.apiService();
        } catch(Arc_Gen_AsyncTriage_helper.InvalidParametersException e) {
            system.assertNotEquals(e, null, 'Invalid Parameter Val');
        }
        Test.stopTest();
    }
    static testMethod void getPortfolioValueCase1Test() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getPortfolioValue('SOVEREIGNS');
        system.assertEquals(result, '1', SUCCESS_ASSERT);
        Test.stopTest();
    }
    static testMethod void getPortfolioValueCase2Test() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getPortfolioValue('FINANCIAL_INSTITUTIONS');
        system.assertEquals(result, '2', SUCCESS_ASSERT);
        Test.stopTest();
    }
    static testMethod void getPortfolioValueCase3Test() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getPortfolioValue('SPECIALIZED_LENDING');
        system.assertEquals(result, '4', SUCCESS_ASSERT);
        Test.stopTest();
    }
    static testMethod void getPortfolioValueCase4Test() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getPortfolioValue('REAL_ESTATE_DEVELOPERS');
        system.assertEquals(result, '6', SUCCESS_ASSERT);
        Test.stopTest();
    }
    static testMethod void getPortfolioValueCase5Test() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getPortfolioValue('SMALL_OR_MEDIUM_SIZE_COMPANIES');
        system.assertEquals(result, '8', SUCCESS_ASSERT);
        Test.stopTest();
    }
}