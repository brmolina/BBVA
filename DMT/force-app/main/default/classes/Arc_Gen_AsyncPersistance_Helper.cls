/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AsyncPersistance_Helper
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 20/08/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Apex Rest web service to listen the renew asynchronous callback
* The URL is /services/apexrest/RenewCallback/createAssessmentsNotifyResult/v1?risk-assessment-id=01234567890&participant-id=G0012345
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |20/08/2020 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |02/10/2020 eduardoefrain.hernandez.contractor@bbva.com
*             Fix error response for "parameters list" - Changed List<Object> to Map<String, string>
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_AsyncPersistance_Helper {
    /**
    *-------------------------------------------------------------------------------
    * @description Web service service
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 20/08/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Helper()
    **/
    @TestVisible
    private Arc_Gen_AsyncPersistance_Helper() {}

    /**
    * @Description: Missing parameters error description
    */
    public final static String URL_MISSING_PARAMS = 'Required parameters are missing';
    /**
    * @Description: Risk assessment not found error description string
    */
    public final static String INVALID_RISKASS = 'Risk Assessment Not Found';
    /**
    * @Description: Invalid particiant error
    */
    public final static String INVALID_PART = 'Participant Not Found';
    /**
    * @Description: Service code of missing parameters
    */
    public final static String MISSING_PARAMS_CODE = 'TR004001';
    /**
    * @Description: String description of invalid parameters
    */
    public final static String INVALID_PARAMETERS = 'Invalid parameters';
    /**
    * @Description: Service code of invalid parameters
    */
    public final static String INVALID_PARAMS_CODE = 'TR004002';
    /**
    * @Description: String of service key "relatedAssessment"
    */
    public final static String BODY_ASSESSMENT = 'relatedAssessment';
    /**
    * @Description: String with value "result"
    */
    public final static String BODY_RESULT = 'result';
    /**
    * @Description: String with value "messages"
    */
    public final static String BODY_MESSAGES = 'messages';
    /**
    * @Description: String with value "Apex server error"
    */
    public final static String APEX_ERROR = 'Apex server error';
    /**
    * @Description: String with value "name"
    */
    public final static String NAME_S = 'name';
    /**
    *-------------------------------------------------------------------------------
    * @description Web service missing mandatory parameters error
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 20/08/2020
    * @example errorResponse()
    **/
    public class ErrorResponse {
        /**
        * @Description: Error code
        */
        public String code {get;set;}
        /**
        * @Description: Error message
        */
        public String message {get;set;}
        /**
        * @Description: List of parameters with errors
        */
        public List<Object> parameters {get;set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Web service missing mandatory parameters error
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 20/08/2020
    * @example MissingParametersException()
    **/
    public class ApexServerException extends Exception {}
    /**
    *-------------------------------------------------------------------------------
    * @description Web service missing mandatory parameters error
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 20/08/2020
    * @example InvalidParametersException()
    **/
    public class InvalidParametersException extends Exception {}
    /**
    *-------------------------------------------------------------------------------
    * @description Verifies if the given parameters are from valid records in salesforce
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 20/08/2020
    * @param String riskAssessmentId - JSON with the input parameters
    * @param String participantId - JSON with the input parameters
    * @return arce__Account_has_Analysis__c - record that matches with the riskAssessmentId
    * @example checkIfDataExists()
    **/
    public static arce__Account_has_Analysis__c checkIfDataExists(String riskAssessmentId, String participantId) {
        arce__Account_has_Analysis__c accHasAnalysis = new arce__Account_has_Analysis__c();
        final Map<String, String> missingParamsList = new Map<String, String>();
        try {
            accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAhaByRiskAssessment(new List<String>{riskAssessmentId}).get(0);
        } catch(ListException e) {
            missingParamsList.put(NAME_S, Arc_Gen_AsyncPersistance_Helper.INVALID_RISKASS);
        }
        if(participantId != 'NA' && arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{participantId}).isEmpty()) {
            missingParamsList.put(NAME_S, Arc_Gen_AsyncPersistance_Helper.INVALID_PART);
        }
        if(!missingParamsList.isEmpty()) {
            throw new Arc_Gen_AsyncPersistance_Helper.InvalidParametersException(Json.serializePretty(setErrorResponse(INVALID_PARAMS_CODE,INVALID_PARAMETERS,new List<Object>{missingParamsList}),true));
        }
        return accHasAnalysis;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Set a map with the given data and check if are null
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 20/08/2020
    * @param String requestbody - String of the JSON response
    * @return Map<String, Object> - Map of the values of the response
    * @example getResponseValuesMap(String requestbody)
    **/
    public static Map<String, Object> getResponseValuesMap(String requestbody) {
        if(String.isBlank(requestbody) || requestbody == '{}') {
            throwCustomExcept(System.Label.Cls_arce_Persistance_Error_BadRequestBody);
        }
        final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(requestbody);
        final Map<String, Object> requestData = new Map<String, Object>();
        final Object assessmentObject = checkNullObject((Object)responseMap.get(BODY_ASSESSMENT));
        final Map<String, Object> assessmentMap = (Map<String, Object>)assessmentObject;
        final Object resultObject = checkNullObject((Object)responseMap.get(BODY_RESULT));
        final Map<String, Object> resultMap = (Map<String, Object>)resultObject;
        final List<Object> resultMsgList = (List<Object>)resultMap.get(BODY_MESSAGES);
        final Map<String, Object> resultMsgMap = (Map<String, Object>)resultMsgList[0];
        requestData.put('relAssessmentId', checkNullObject(assessmentMap.get('id')));
        requestData.put('resultId', checkNullObject(resultMap.get('id')));
        requestData.put('resultMessageId', checkNullObject(resultMsgMap.get('id')));
        requestData.put('resultMessageDesc', resultMsgMap.get('description'));

        return requestData;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Process the callback response
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 01/09/2020
    * @param Map<String, Object> responseMap - Generalized map of the JSON response
    * @param arce__Account_has_Analysis__c accHasAnalysis - Standard Id of the accHasAnaliysis
    * @return void
    * @example processResponse(Map<String, Object> responseMap, arce__Account_has_Analysis__c accHasAnalysis)
    **/
    public static void processResponse(Map<String, Object> responseMap, arce__Account_has_Analysis__c accHasAnalysis) {
        final String resultId = (String)responseMap.get('resultId');
        final String relatedAssessment = (String)responseMap.get('relAssessmentId');
        checkIfDataExists(relatedAssessment, 'NA');
        accHasAnalysis.arce__persistance_callback_status_type__c = resultId == arce.Arc_Gen_Constants.OK_S ? arce.Arc_Gen_Constants.TWO_S : arce.Arc_Gen_Constants.THREE_S;
        arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(new List<arce__Account_has_Analysis__c>{accHasAnalysis});
        final arce__persistanceCallbackEvent__e callbackEvt = new arce__persistanceCallbackEvent__e(
            arce__AccountHasAnalysisId__c = accHasAnalysis.Id,
            arce__Status__c = resultId
        );
        EventBus.publish(callbackEvt);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Web service missing mandatory parameters error
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 20/08/2020
    * @param Object bodyObject - JSON with the input parameters
    * @return Object
    * @example processRequestBody()
    **/
    private static Object checkNullObject(Object bodyObject) {
        if(bodyObject == null) {
            throw new InvalidParametersException(Json.serializePretty(setErrorResponse(MISSING_PARAMS_CODE, URL_MISSING_PARAMS, null), true));
        }
        return bodyObject;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that calls the triage service and returns the processed response
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 20/08/2020
    * @param String riskAssessmentId - JSON with the input parameters
    * @param String participantId - Id of the parent ARCE
    * @return void
    * @example checkURLParams(String riskAssessmentId, String participantId)
    **/
    public static void checkURLParams(String riskAssessmentId, String participantId) {
        final List<String> nullParams = new List<String>();
        if(riskAssessmentId == NULL || riskAssessmentId == '') {
            nullParams.add('risk-assessment-id');
        }
        if(participantId == NULL || participantId == '') {
            nullParams.add('participant-id');
        }
        if(!nullParams.isEmpty()) {
            final List<Map<String,String>> nullParamsList = new List<Map<String,String>>();
            for(String st : nullParams) {
                final Map<String,String> nullParamMap = new Map<String,String>();
                nullParamMap.put('name',st);
                nullParamsList.add(nullParamMap);
            }
            throw new InvalidParametersException(Json.serializePretty(setErrorResponse(MISSING_PARAMS_CODE, URL_MISSING_PARAMS, nullParamsList), true));
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that calls the triage service and returns the processed response
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 20/08/2020
    * @param String code - JSON with the input parameters
    * @param String message - Id of the parent ARCE
    * @param List<Object> parameters - List of parameters
    * @return triageResponse - Wrapper with all required responses of the service
    * @example public static triageResponse setupTriageService(String analysisId, String parameters)
    **/
    public static ErrorResponse setErrorResponse(String code, String message, List<Object> parameters) {
        final ErrorResponse errorResp = new ErrorResponse();
        errorResp.code = code;
        errorResp.message = message;
        errorResp.parameters = parameters;
        Return errorResp;
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     20/08/2020
    * @param    String message - Message that will be passed to the front by an exception
    * @return   void
    * @example  public static date throwAuraExcept(String message)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static void throwCustomExcept(String message) {
        final ApexServerException customError = new ApexServerException(message);
        customError.setMessage(Json.serializePretty(Arc_Gen_AsyncTriage_helper.setErrorResponse(
            Arc_Gen_AsyncPersistance_Helper.APEX_ERROR,message,null),true));
        throw customError;
    }
}