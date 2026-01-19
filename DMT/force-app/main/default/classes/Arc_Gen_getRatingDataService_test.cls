/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingStudiosUpdateTable
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 28/10/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Tests the classes getRatingDataService and RatingVariablesTable
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |28/10/2019 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |23/7/2019 eduardoefrain.hernandez.contractor@bbva.com
*             Added comments, localism and updates test coverage
* |26/9/2019 javier.soto.carrascosa@bbva.com
*             Remove incorrect test method
* |21/10/2019 eduardoefrain.hernandez.contractor@bbva.com
*             Update test coverage for studies and overlay
* |28/10/2019 eduardoefrain.hernandez.contractor@bbva.com
*             Add static service parameters
* |2019-12-02 german.sanchez.perez.contractor@bbva.com | franciscojavier.bueno@bbva.com
*             Api names modified with the correct name on business glossary
* |2020-01-08 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |24/01/2020 juanmanuel.perez.ortiz.contractor@bbva.com
*             Remove logic static parameters to ASO services
* |2020-04-03 cesaroctavio.villanueva.cebal@bbva.com
*             Added value to correctly validate service class
* |2020-04-14 mariohumberto.ramirez.contractor@bbva.com
*             update test class
* |2020-04-28 eduardoefrain.hernandez.contractor@bbva.com
*             Add testingNoAdjustments test method
* |2020-06-25 juanmanuel.perez.ortiz.contractor@bbva.com
*             Added test method called getOverrideVariableTest
* |2020-06-29 mariohumberto.ramirez.contractor@bbva.com
*             Deleted testingsetupRatingPrev2 and testingsetupRatingPrev3 methods
* |2020-07-02 eduardoefrain.hernandez.contractor@bbva.com
*             Add adjustments testing without iaso metadata mocks
* |2020-07-07 juanmanuel.perez.ortiz.contractor@bbva.com
*             Create constants called CALCULATION and RESPONSE500 and remove unused variables
* |17/09/2020 eduardoefrain.hernandez.contractor@bbva.com
*             Add testGetAnalysisError, testQualitativeQuestions methods
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-02-02 luisdavid.rivera.ortiz@bbva.com
*             Eliminated unused fields
* |2021-04-07 joseluis.garcia4.contractor@bbva.com
*             Remove tests that are not needed.
* |2021-05-14 joseluis.garcia4.contractor@bbva.com
*             Fix test.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
@isTest
public class Arc_Gen_getRatingDataService_test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with literal CALCULATION
    */
    static final string CALCULATION = 'CALCULATION';
    /**
    * @Description: String with literal 500
    */
    static final string RESPONSE_500 = '500';
    /**
    * @Description: 'Analysis Test' literal
    */
    static final string ANALISIS_LIT = 'Analysis Test';
    /**
    * @Description: 'UserAdmin' literal
    */
    static final string USERADM_LIT = 'UserAdmin';
    /**
    * @Description: 'XME0514' literal
    */
    static final string XME0514_LIT = 'XME0514';
    /**
    * @Description: FFSSERROR Final String
    */
    static final String FFSSERROR = '{"messages":[{"code":"missingData","message":"Unable to call detail of financial statement service","parameters":[],"type":"CRITICAL"}]}';
    /**
    * @Description: TIMEOUTERROR Final String
    */
    static final String TIMEOUTERROR = '{"messages":[{"code":"errorRestConnector","message":"Se ha producido un error en el conector REST: Hard timeout reached. Request aborted [Service execution timeout: 120000 ms - Elapsed time: 10046 ms - Remaining time: 109954 ms - Min remaining time: 5 ms][Invocation timeout: 10000 ms].","parameters":[{"name":"Hard timeout reached. Request aborted [Service execution timeout: 120000 ms - Elapsed time: 10046 ms - Remaining time: 109954 ms - Min remaining time: 5 ms][Invocation timeout: 10000 ms]"}],"type":"FATAL"}]}';
    /**
    * @Description: RISKASSESSERROR Final String
    */
    static final String RISKASSESSERROR = '{"messages":[{"code":"missingData","message":"Unable to call risk-assessment service","parameters":[],"type":"CRITICAL"}]}';
    /**
    * @Description: CUSTOMERERROR Final String
    */
    static final String CUSTOMERERROR = '{"messages":[{"code":"missingData","message":"Unable to call customer service","parameters":[],"type":"CRITICAL"},{"code":"invalidLocalCalculation","message":"Unable to call local services","parameters":[],"type":"CRITICAL"}]}';
    /**
    * @Description: PERSISTERROR Final String
    */
    static final String PERSISTERROR = '{"messages":[{"code":"missingData","message":"Unable to persist rating","parameters":[],"type":"CRITICAL"}]}';
    /**
    * @Description: BUSINESSAGENTERR Final String
    */
    static final String BUSINESSAGENTERR = '{"messages":[{"code":"mandatoryParametersMissingExplicit","message":"Parámetros obligatorios no informados: businessAgent.id","parameters":[{"name":"businessAgent.id"}],"type":"FATAL"}]}';
    /**
    * @Description: BRANCHIDERROR Final String
    */
    static final String BRANCHIDERROR = '{"messages":[{"code":"mandatoryParametersMissingExplicit","message":"Parámetros obligatorios no informados: bank.branch.id","parameters":[{"name":"bank.branch.id"}],"type":"FATAL"}]}';
    /**
    * @Description: BRANCHLEVELERROR Final String
    */
    static final String BRANCHLEVELERROR = '{"messages":[{"code":"mandatoryParametersMissingExplicit","message":"Parámetros obligatorios no informados: bank.branch.level.id","parameters":[{"name":"bank.branch.level.id"}],"type":"FATAL"}]}';
    /**
    * @Description: BANKIDERROR Final String
    */
    static final String BANKIDERROR = '{"messages":[{"code":"mandatoryParametersMissingExplicit","message":"Parámetros obligatorios no informados: bank.id","parameters":[{"name":"bank.id"}],"type":"FATAL"}]}';
    /**
    * @Description: OTHERPARAMERROR Final String
    */
    static final String OTHERPARAMERROR = '{"messages":[{"code":"mandatoryParametersMissingExplicit","message":"Parámetros obligatorios no informados: bank.id","parameters":[{"name":"sector.id"}],"type":"FATAL"}]}';
    /**
    * @Description: OVERRIDEERROR Final String
    */
    static final String OVERRIDEERROR = '{"messages":[{"code":"invalidLocalCalculation","message":"Unable to calculate override","parameters":[],"type":"CRITICAL"}]}';

    /**
    * --------------------------------------------------------------------------------------
    * @Description setup test
    * --------------------------------------------------------------------------------------
    * @Author   javier.soto.carrascosa@bbva.com
    * @Date     Created: 2020-01-08
    * @param void
    * @return void
    * @example setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
    Arc_UtilitysDataTest_tst.setupAcccounts();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method to setup a service response
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020-06-09
    * @param void
    * @return void
    * @example setResponse()
    * --------------------------------------------------------------------------------------
    **/
    private static arce.Arc_Gen_getIASOResponse.serviceResponse setResponse(String serviceCode, Map<String, Object> serviceResponse) {
        final arce.Arc_Gen_getIASOResponse.serviceResponse response = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        response.serviceCode = serviceCode;
        response.serviceResponse = serviceResponse;
        return response;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param String name - Name of the arce
    * @return  arce__Analysis__c
    * @example setAnalysis(String name)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Analysis__c setAnalysis(String name) {
        final arce__Analysis__c analysis = new arce__Analysis__c(
            Name = name
        );
        insert analysis;
        return analysis;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param String clientId - Id of the account
    * @param String analysisId - Id of the arce
    * @param String validFs - Id of valid FS
    * @return arce__Account_has_Analysis__c
    * @example setAnalyzedClient(String clientId,String analysisId,String validFs)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c setAnalyzedClient(String clientId,String analysisId,String validFs) {
        final arce__Account_has_Analysis__c analyzedClient = new arce__Account_has_Analysis__c(
            arce__Customer__c = clientId,
            arce__Analysis__c = analysisId,
            arce__ffss_for_rating_id__c = validFs,
            arce__branch_id__c = '0002',
            arce__RAR_rating_tool_id__c = '2012IRP'
        );
        insert analyzedClient;
        return analyzedClient;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param String accName - Name of the account
    * @param String accNumber - Number of the account
    * @param String analysisName - Name of the arce
    * @param String validFs - Id of valid FS
    * @return arce__Account_has_Analysis__c
    * @example getAnalyzedClient(String accName,String accNumber,String analysisName,String validFs)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c getAnalyzedClient(String accNumber,String analysisName,String validFs) {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{accNumber});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(accNumber);
        final arce__Analysis__c analysis = setAnalysis(analysisName);
        final arce__Account_has_Analysis__c accHasAn = setAnalyzedClient(groupAccount.accId,analysis.Id,validFs);
        return accHasAn;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param String ratingId - Id of the rating
    * @param String validInd - Valid indicator
    * @return arce__Financial_Statements__c
    * @example setFFSS(String ratingId, String validInd)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Financial_Statements__c setFFSS(String ratingId, String validInd) {
        final arce__Financial_Statements__c ffss = new arce__Financial_Statements__c(
            arce__ffss_valid_type__c = validInd,
            arce__ffss_valid_for_rating_type__c = validInd,
            arce__financial_statement_id__c = '70252018129',
            arce__rating_id__c = ratingId
        );
        insert ffss;
        return ffss;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return arce__rating__c
    * @example setRating()
    * --------------------------------------------------------------------------------------
    **/
    public static arce__rating__c setRating() {
        final arce__rating__c rating = new arce__rating__c();
        insert rating;
        return rating;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param String analysisId - arce id
    * @param String ratingId - id of the rating
    * @return arce__rating_variables_detail__c
    * @example setRatingVariable(String analysisId,String ratingId)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__rating_variables_detail__c setRatingVariable(String analysisId,String ratingId) {
        final arce__rating_variables_detail__c ratingVariable = new arce__rating_variables_detail__c(
            arce__account_has_analysis_id__c = analysisId,
            arce__rating_id__c = ratingId,
            arce__rating_modifier_adj_type__c = 'OVERRIDE'
        );
        insert ratingVariable;
        return ratingVariable;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example getCustomerDataTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getCustomerDataTest() {
        final arce__Account_has_Analysis__c accHasAn = getAnalyzedClient(GROUP_ID,ANALISIS_LIT,null);
        test.startTest();
        final Arc_Gen_getRatingDataService_controller.clientData customerData = Arc_Gen_getRatingDataService_controller.getCustomerData(accHasAn.Id);
        System.assertEquals(GROUP_ID, customerData.customerId, 'This obtains the externalid of the client');
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingFiancialAlertRating()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingFiancialAlertRating() {
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        final User userAdmin = Arc_UtilitysDataTest_tst.crearUsuario(USERADM_LIT,System.Label.Cls_arce_ProfileSystemAdministrator,'');
        userAdmin.federationIdentifier = XME0514_LIT;
        //userAdmin.ID_User__c = 'uniqUser0514';
        userAdmin.ID_User__C = String.valueOf((Math.random()*100000));
        insert userAdmin;
        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
        final arce__rating__c rating = setRating();
        final arce__Financial_Statements__c ffss = setFFSS(rating.Id, '1');
        final arce__Account_has_Analysis__c accHasAn = getAnalyzedClient(GROUP_ID,ANALISIS_LIT,ffss.Id);
        test.startTest();
        System.runAs(userAdmin) {
            final String mockResp = Arc_Gen_GetRatingMocks.getRatingMock(true,true,true);
            response = Arc_Gen_getRatingDataService_controller.setupRating(accHasAn.Id, accHasAn.arce__Customer__c, mockResp);
            Arc_Gen_RatingVariablesTable_controller.getDataTable(rating.Id);
            Arc_Gen_RatingVariablesTable_controller.getQualitativeTable(rating.Id);
        }
        System.debug('financialAlert response '+response);
        System.assertEquals('true', response.saveStatus, 'The DML status were successful, the response is true');
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingStageRating()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingStageRating() {
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        final User userAdmin = Arc_UtilitysDataTest_tst.crearUsuario(USERADM_LIT,System.Label.Cls_arce_ProfileSystemAdministrator,'');
        userAdmin.federationIdentifier = XME0514_LIT;
        //userAdmin.ID_User__c = 'uniqUser0514';
        userAdmin.ID_User__C = String.valueOf((Math.random()*100000));
        insert userAdmin;
        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
        final arce__rating__c rating = setRating();
        final arce__Financial_Statements__c ffss = setFFSS(rating.Id, '1');
        final arce__Account_has_Analysis__c accHasAn = getAnalyzedClient(GROUP_ID,ANALISIS_LIT,ffss.Id);
        setRatingVariable(accHasAn.Id,rating.Id);
        test.startTest();
        System.runAs(userAdmin) {
            final String mockResp = Arc_Gen_GetRatingMocks.getRatingMock(true,true,false);
            response = Arc_Gen_getRatingDataService_controller.setupRating(accHasAn.Id, accHasAn.arce__Customer__c, mockResp);
            Arc_Gen_RatingVariablesTable_controller.getDataTable(rating.Id);
            Arc_Gen_RatingVariablesTable_controller.getQualitativeTable(rating.Id);
        }
        System.debug('stage response '+response);
        System.assertEquals('true', response.saveStatus, 'The DML status were successful, the response is true');
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingStageRating()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingNoAdjustments() {
        arce.Arc_Gen_ServiceAndSaveResponse resp = new arce.Arc_Gen_ServiceAndSaveResponse();
        final User admin = Arc_UtilitysDataTest_tst.crearUsuario(USERADM_LIT,System.Label.Cls_arce_ProfileSystemAdministrator,'');
        admin.federationIdentifier = 'XME0213';
        //userAdmin.ID_User__c = 'uniqUser0514';
        //Subir cambio
        admin.ID_User__C = String.valueOf((Math.random()*100000));
        insert admin;
        final List<sObject> iasoConfig = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoConfig;
        final arce__rating__c rating = setRating();
        final arce__Financial_Statements__c ffss = setFFSS(rating.Id, '1');
        final arce__Account_has_Analysis__c aha = getAnalyzedClient(GROUP_ID,ANALISIS_LIT,ffss.Id);
        setRatingVariable(aha.Id,rating.Id);
        test.startTest();
        System.runAs(admin) {
            final String mockResp = Arc_Gen_GetRatingMocks.getRatingMock(false,false,false);
            resp = Arc_Gen_getRatingDataService_controller.setupRating(aha.Id, aha.arce__Customer__c, mockResp);
            Arc_Gen_RatingVariablesTable_controller.getDataTable(rating.Id);
            Arc_Gen_RatingVariablesTable_controller.getQualitativeTable(rating.Id);
        }
        System.assertEquals('true', resp.saveStatus, 'The DML status were successful, the response is true');
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingRatingNoValid()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingRatingNoValid() {
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        final User userAdmin = Arc_UtilitysDataTest_tst.crearUsuario(USERADM_LIT,System.Label.Cls_arce_ProfileSystemAdministrator,'');
        userAdmin.federationIdentifier = XME0514_LIT;
        userAdmin.ID_User__C = String.valueOf((Math.random()*100000));
        insert userAdmin;
        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
        final arce__rating__c rating = setRating();
        final arce__Financial_Statements__c ffss = setFFSS(rating.Id, '2');
        final arce__Account_has_Analysis__c accHasAn = getAnalyzedClient(GROUP_ID,ANALISIS_LIT,ffss.Id);
        setRatingVariable(accHasAn.Id,rating.Id);
        test.startTest();
        System.runAs(userAdmin) {
            final String mockResp = Arc_Gen_GetRatingMocks.getRatingMock(true,true,false);
            response = Arc_Gen_getRatingDataService_controller.setupRating(accHasAn.Id, accHasAn.arce__Customer__c, mockResp);
            Arc_Gen_RatingVariablesTable_controller.getDataTable(rating.Id);
            Arc_Gen_RatingVariablesTable_controller.getQualitativeTable(rating.Id);
        }
        System.assertNotEquals('200', response.serviceCode, 'The DML status were unsuccessful, the response is false');
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingCalloutError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingCalloutError() {
        final arce__Account_has_Analysis__c accHasAn = getAnalyzedClient(GROUP_ID,null,null);
        test.startTest();
        final arce.Arc_Gen_ServiceAndSaveResponse response = Arc_Gen_getRatingDataService_controller.setupRating(accHasAn.Id,accHasAn.arce__Customer__c,'Error');
        System.assertEquals('false', response.saveStatus, 'The response of the save record');
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingDML()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingDML() {
        final arce.Arc_Gen_RatingGlobal_data locator = new arce.Arc_Gen_RatingGlobal_data();
        arce.Arc_Gen_RatingGlobal_data.saveResult result = new arce.Arc_Gen_RatingGlobal_data.saveResult();
        final String longName = '12345678901234567890121234567890123456789012123456789012345678901212345678901234567890121234567890123456789012';
        final List<arce__analysis__c> arceIns = new List<arce__analysis__c>{new arce__analysis__c(Name = longName)};
        final List<arce__analysis__c> arceUpd = new List<arce__analysis__c>{new arce__analysis__c(Name='Test1')};
        insert arceUpd;
        arceUpd[0].Name = longName;
        test.startTest();
        result = locator.insertRecords(arceIns);
        locator.updateRecords(arceUpd);
        System.assertEquals('false', result.status, 'The DML status is wrong because of null parameter, the response is false');
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingStageRating()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void errorManagement() {
        test.startTest();
        final String response = JSON.serialize(arce.Arc_Gen_RatingErrorManagement.processErrorData(setResponse(RESPONSE_500, (Map<String, Object>)JSON.deserializeUntyped(FFSSERROR)), CALCULATION));
        arce.Arc_Gen_RatingErrorManagement.processErrorData(setResponse(RESPONSE_500, (Map<String, Object>)JSON.deserializeUntyped(TIMEOUTERROR)), CALCULATION);
        arce.Arc_Gen_RatingErrorManagement.processErrorData(setResponse(RESPONSE_500, (Map<String, Object>)JSON.deserializeUntyped(RISKASSESSERROR)), CALCULATION);
        arce.Arc_Gen_RatingErrorManagement.processErrorData(setResponse(RESPONSE_500, (Map<String, Object>)JSON.deserializeUntyped(CUSTOMERERROR)), CALCULATION);
        arce.Arc_Gen_RatingErrorManagement.processErrorData(setResponse(RESPONSE_500, (Map<String, Object>)JSON.deserializeUntyped(PERSISTERROR)), CALCULATION);
        arce.Arc_Gen_RatingErrorManagement.processErrorData(setResponse(RESPONSE_500, (Map<String, Object>)JSON.deserializeUntyped(BUSINESSAGENTERR)), CALCULATION);
        arce.Arc_Gen_RatingErrorManagement.processErrorData(setResponse(RESPONSE_500, (Map<String, Object>)JSON.deserializeUntyped(BRANCHIDERROR)), CALCULATION);
        arce.Arc_Gen_RatingErrorManagement.processErrorData(setResponse(RESPONSE_500, (Map<String, Object>)JSON.deserializeUntyped(BRANCHLEVELERROR)), CALCULATION);
        arce.Arc_Gen_RatingErrorManagement.processErrorData(setResponse(RESPONSE_500, (Map<String, Object>)JSON.deserializeUntyped(BANKIDERROR)), CALCULATION);
        arce.Arc_Gen_RatingErrorManagement.processErrorData(setResponse(RESPONSE_500, (Map<String, Object>)JSON.deserializeUntyped(OTHERPARAMERROR)), 'VALIDATION');
        arce.Arc_Gen_RatingErrorManagement.processErrorData(setResponse(RESPONSE_500, (Map<String, Object>)JSON.deserializeUntyped(OVERRIDEERROR)), 'OVERRIDE');
        System.assertNotEquals('', response, 'Error message that the user views');
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingConstructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void errorManagmntConst() {
        Test.startTest();
        final arce.Arc_Gen_RatingErrorManagement constructor = new arce.Arc_Gen_RatingErrorManagement();
        System.assertEquals(constructor, constructor,'Empty helper constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for getOverrideVariable
    * --------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @param void
    * @return void
    * @example getOverrideVariableTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getOverrideVariableTest() {
        arce__rating_variables_detail__c testVariable = new arce__rating_variables_detail__c();
        final User userAdmin = Arc_UtilitysDataTest_tst.crearUsuario(USERADM_LIT,System.Label.Cls_arce_ProfileSystemAdministrator,'');
        userAdmin.federationIdentifier = XME0514_LIT;
        userAdmin.ID_User__C = String.valueOf((Math.random()*100000));  
        insert userAdmin;
        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;
        final arce__rating__c rating = setRating();
        final arce__Financial_Statements__c ffss = setFFSS(rating.Id, '1');
        ffss.arce__previous_valid__c = false;
        final arce__Account_has_Analysis__c accHasAn = getAnalyzedClient(GROUP_ID,'54321',ffss.Id);
        ffss.arce__account_has_analysis_id__c = accHasAn.Id;
        update ffss;
        final arce__rating_variables_detail__c testVariable1 = setRatingVariable(accHasAn.Id,rating.Id);
        test.startTest();
        System.runAs(userAdmin) {
            testVariable = arce.Arc_Gen_RatingGlobal_data.getOverrideVariable(accHasAn.Id);
        }
        system.assertEquals(testVariable1.Id, testvariable.Id, 'id match succesfully');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testGetAnalysis()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGetAnalysisError() {
        final arce__rating__c rating = setRating();
        String response;
        test.startTest();
        try {
            response = JSON.serialize(Arc_Gen_getRatingDataService_controller.getAnalysis(rating.Id));
        } catch (Exception e) {
            response = 'ERROR';
        }

        System.assertEquals('ERROR', response, 'Retrieved arce');
        test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testQualitativeQuestions()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testQualitativeQuestions() {
        test.startTest();
        final String response;
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('s-01', '100', 's-01', null);
        insert newSector;
        final arce__rating__c rating = setRating();
        final arce__Financial_Statements__c ffss = setFFSS(rating.Id, '1');
        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__anlys_wkfl_sub_process_type__c = '2';
        insert newArce;
        final arce__Account_has_Analysis__c accHasAn = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, 's-01');
        accHasAn.arce__ffss_for_rating_id__c = ffss.Id;
        insert accHasAn;
        try {
            final arce__Analysis__c arceVar = Arc_Gen_getRatingDataService_controller.getAnalysis(accHasAn.Id);
            response = JSON.serialize(Arc_Gen_getRatingDataService_controller.validationQualitativeQuestion(accHasAn.Id, arceVar));
        } catch (Exception e) {
            response = e.getMessage();
        }

        System.assertNotEquals(null, response, 'Retrieved arce');
        test.stopTest();
    }
}