/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AsyncPersistance_Test
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 31/08/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class that covers the following apex classes:
*              Arc_Gen_AsyncPersistance_Controller, Arc_Gen_AsyncPersistance_Service, Arc_Gen_AsyncPersistance_Helper
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |31/08/2020 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_AsyncPersistance_Test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test group
    */
    static final string ENCRYPTED_GROUP = 'EcxqPKmyRSc';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * @Description: String with URI
    */
    static final String URI_STRING = '/services/apexrest/RenewCallback/createAssessmentsNotifyResult/v1';
    /**
    * @Description: String with Risk assessmente
    */
    static final String RISK_ASSESS_PARAM = 'risk-assessment-id';
    /**
    * @Description: String with participant id
    */
    static final String PART_ID_PARAM = 'participant-id';
    /**
    * @Description: String with POST
    */
    static final String POST_METHOD = 'POST';
    /**
    * @Description: String with the participant number
    */
    private static String participantNumber;
    /**
    * @Description: static logic that sets participantNumber
    */
    static {
        if(Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('EncryptionFlag')[0].arce__Value1__c)) {
            participantNumber = ENCRYPTED_GROUP;
        } else {
            participantNumber = GROUP_ID;
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method for Arc_Gen_AsyncPersistance_Test
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 31/08/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.setup()
    * --------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void setup() {
        arce.Arc_UtilitiesToTest_tst.enableBypass();
        Arc_UtilitysDataTest_tst.setupAcccounts();

        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);

        final arce__Analysis__c noVigorArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        noVigorArce.arce__anlys_wkfl_sub_process_type__c = '2';
        noVigorArce.arce__anlys_wkfl_sanction_rslt_type__c = '1';
        noVigorArce.arce__Stage__c = '3';
        noVigorArce.arce__analysis_risk_expiry_date__c = System.today() - 1;
        noVigorArce.ownerId = System.UserInfo.getUserId();
        insert noVigorArce;

        final arce__Account_has_Analysis__c ahaNoVigor1 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, noVigorArce.Id, groupAccount.accId, '1');
        insert ahaNoVigor1;

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__anlys_wkfl_sub_process_type__c = '1';
        newArce.ownerId = System.UserInfo.getUserId();
        insert newArce;

        final arce__Account_has_Analysis__c accHasAnalysisG = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, newArce.Id, groupAccount.accId, '1');
        insert accHasAnalysisG;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 31/08/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.emptyControllConst()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void emptyControllConst() {
        Test.startTest();
        final Arc_Gen_AsyncPersistance_Controller constructorContr = new Arc_Gen_AsyncPersistance_Controller();
        System.assertEquals(constructorContr, constructorContr, 'Empty controller constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 31/08/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.emptyServConst()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void emptyServConst() {
        Test.startTest();
        final Arc_Gen_AsyncPersistance_Service constructorServ = new Arc_Gen_AsyncPersistance_Service();
        System.assertEquals(constructorServ, constructorServ, 'Empty Service constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 31/08/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.emptyServHelper()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void emptyServHelper() {
        Test.startTest();
        final Arc_Gen_AsyncPersistance_Helper constructorHelp = new Arc_Gen_AsyncPersistance_Helper();
        System.assertEquals(constructorHelp, constructorHelp, 'Empty Helper constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 31/08/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.testingCallbackOK()
    * --------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testingCallbackOK() {
        Test.startTest();
        final arce__Account_has_Analysis__c relatedAha = [SELECT Id,Name FROM arce__Account_has_Analysis__c WHERE arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c = '2' LIMIT 1];
        final arce__Account_has_Analysis__c currentAha = [SELECT Id,Name FROM arce__Account_has_Analysis__c WHERE arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c = '1' LIMIT 1];

        final String myJSON = '{"relatedAssessment":{"id":"'+relatedAha.Name+'"},"result":{"id":"OK","messages":[{"id":"1234","description":"Currenciesnotinformed."}]}}';
        final RestRequest request = new RestRequest();
        final RestResponse response = new RestResponse();
        request.requestUri = URI_STRING;
        request.addParameter(RISK_ASSESS_PARAM, currentAha.Name);
        request.addParameter(PART_ID_PARAM, participantNumber);
        request.httpMethod = POST_METHOD;
        request.requestBody = Blob.valueof(myJSON);
        RestContext.request = request;
        RestContext.response = response;

        Arc_Gen_AsyncPersistance_Controller.restApexService();
        System.assertEquals(200, RestContext.response.statusCode, 'Status 200 ok');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 31/08/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.callbackUriError()
    * --------------------------------------------------------------------------------------
    **/
    @IsTest
    static void callbackUriError() {
        final arce__Account_has_Analysis__c relatedAha = [SELECT Id,Name FROM arce__Account_has_Analysis__c WHERE arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c = '2' LIMIT 1];
        final arce__Account_has_Analysis__c currentAha = [SELECT Id,Name FROM arce__Account_has_Analysis__c WHERE arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c = '1' LIMIT 1];

        final String myJSON = '{"relatedAssessment":{"id":"'+relatedAha.Name+'"},"result":{"id":"OK","messages":[{"id":"1234","description":"Currenciesnotinformed."}]}}';
        final RestRequest request = new RestRequest();
        final RestResponse response = new RestResponse();
        request.requestUri = URI_STRING;
        request.addParameter(RISK_ASSESS_PARAM, currentAha.Name);
        request.httpMethod = POST_METHOD;
        request.requestBody = Blob.valueof(myJSON);
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        Arc_Gen_AsyncPersistance_Controller.restApexService();
        System.assertEquals(400, RestContext.response.statusCode, 'Status 400 missing params');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 31/08/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.badRiskAssessment()
    * --------------------------------------------------------------------------------------
    **/
    @IsTest
    static void badRiskAssessment() {
        Test.startTest();
        final arce__Account_has_Analysis__c relatedAha = [SELECT Id,Name FROM arce__Account_has_Analysis__c WHERE arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c = '2' LIMIT 1];

        final String myJSON = '{"relatedAssessment":{"id":"'+relatedAha.Name+'"},"result":{"id":"OK","messages":[{"id":"1234","description":"Currenciesnotinformed."}]}}';
        final RestRequest request = new RestRequest();
        final RestResponse response = new RestResponse();
        request.requestUri = URI_STRING;
        request.addParameter(RISK_ASSESS_PARAM, '1234567890');
        request.addParameter(PART_ID_PARAM, participantNumber);
        request.httpMethod = POST_METHOD;
        request.requestBody = Blob.valueof(myJSON);
        RestContext.request = request;
        RestContext.response = response;

        Arc_Gen_AsyncPersistance_Controller.restApexService();
        System.assertEquals(400, RestContext.response.statusCode, 'Status 400 invalid params');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 31/08/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.badRequestBody()
    * --------------------------------------------------------------------------------------
    **/
    @IsTest
    static void badRequestBody() {
        Test.startTest();
        final arce__Account_has_Analysis__c currentAha = [SELECT Id,Name FROM arce__Account_has_Analysis__c WHERE arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c = '1' LIMIT 1];

        final String myJSON = '{}';
        final RestRequest request = new RestRequest();
        final RestResponse response = new RestResponse();
        request.requestUri = URI_STRING;
        request.addParameter(RISK_ASSESS_PARAM, currentAha.Name);
        request.addParameter(PART_ID_PARAM, participantNumber);
        request.httpMethod = POST_METHOD;
        request.requestBody = Blob.valueof(myJSON);
        RestContext.request = request;
        RestContext.response = response;

        Arc_Gen_AsyncPersistance_Controller.restApexService();
        System.assertEquals(500, RestContext.response.statusCode, 'Status 500 internal server error');
        Test.stopTest();
    }
}