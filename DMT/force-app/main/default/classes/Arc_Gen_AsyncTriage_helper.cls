/**
  * @File Name          : Arc_Gen_AsyncTriage_helper.cls
  * @Description        :
  * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
  * @Group              :
  * @Last Modified By   : manuelhugo.castillo.contractor@bbva.com
  * @Last Modified On   : 10/09/2020
  * @Modification Log   : Remove methods deprecated
  * Ver    Date			Author      		    					Modification
  * 1.0    23/03/2020   ChangeMeIn@UserSettingsUnder.SFDoc     		Initial Version
  * 1.2    10/09/2020   manuelhugo.castillo.contractor@bbva.com 	Remove methods deprecated
**/
public class Arc_Gen_AsyncTriage_helper {
    /**
    *-------------------------------------------------------------------------------
    * @description Web service helper
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 03/04/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncTriage_helper()
    **/
    @TestVisible
    private Arc_Gen_AsyncTriage_helper() {}
    /**
    * @Description: Service response identificator
    */
    public final static String ECONOMIC_PART = 'economicGroupParticipants';
    /**
    * @Description: Service response identificator
    */
    public final static String CALCULATION_REQUEST = 'calculationRequest';
    /**
    * @Description: Service response identificator
    */
    public final static String URL_MISSING_PARAMS = 'Required parameters are missing';
    /**
    * @Description: Service response identificator
    */
    public final static String MISSING_PARAMS_CODE = 'TR004001';
    public class TR004001Error {
        /**
        * @Description: Participant Group or subsidiary number
        */
        public String code {get;set;}
        /**
        * @Description: Participant Group or subsidiary number
        */
        public String message {get;set;}
        /**
        * @Description: Participant Group or subsidiary number
        */
        public List<Object> parameters {get;set;}
    }
    public class InvalidParametersException extends Exception {}

    /**
*-------------------------------------------------------------------------------
* @description Method that calls the triage service and returns the processed response
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param String parameters - JSON with the input parameters
* @param String analysisId - Id of the parent ARCE
* @return triageResponse - Wrapper with all required responses of the service
* @example public static triageResponse setupTriageService(String analysisId, String parameters)
**/
    public static TR004001Error setErrorResponse(String code, String message, List<Object>parameters) {
        TR004001Error errorResponse = new TR004001Error();
        errorResponse.code = code;
        errorResponse.message = message;
        errorResponse.parameters = parameters;
        Return errorResponse;
    }
    /**
*-------------------------------------------------------------------------------
* @description Method that calls the triage service and returns the processed response
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param String parameters - JSON with the input parameters
* @param String analysisId - Id of the parent ARCE
* @return triageResponse - Wrapper with all required responses of the service
* @example public static triageResponse setupTriageService(String analysisId, String parameters)
**/
    public static Arc_Gen_Triage_helper.TriageResponse reviewURLParams(String riskAssessmentId, String participantId) {
        List<String> nullParams = new List<String>();
        Arc_Gen_Triage_helper.TriageResponse ret;
        if(riskAssessmentId == NULL) {
            nullParams.add('risk-assessment-id');
        }
        if(participantId == NULL) {
            nullParams.add('participant-id');
        }
        if(nullParams.isEmpty()) {
            ret = new Arc_Gen_Triage_helper.TriageResponse();
        }
        else {
            List<Map<String,String>> nullParamsList = new List<Map<String,String>>();
            for(String st : nullParams) {
                Map<String,String> nullParamMap = new Map<String,String>();
                nullParamMap.put('name',st);
                nullParamsList.add(nullParamMap);
            }
            throw new InvalidParametersException(Json.serializePretty(setErrorResponse(MISSING_PARAMS_CODE, URL_MISSING_PARAMS, nullParamsList), true));
        }
        return ret;
    }
    /**
*-------------------------------------------------------------------------------
* @description Method that calls the triage service and returns the processed response
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 12/8/2019
* @param String parameters - JSON with the input parameters
* @param String analysisId - Id of the parent ARCE
* @return triageResponse - Wrapper with all required responses of the service
* @example public static triageResponse setupTriageService(String analysisId, String parameters)
**/
    public static List<Map<String,String>> checkForNulls(String name, Object data, List<Map<String,String>> nullDataList) {
        if(data == Null || data == '') {
            Map<String,String> nullMap = new Map<String,String>{'name' => name};
            nullDataList.add(nullMap);
        }
        Return nullDataList;
    }
}