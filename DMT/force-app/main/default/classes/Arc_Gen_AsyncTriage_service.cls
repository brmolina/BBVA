/**
  * @File Name          : Arc_Gen_AsyncTriage_service.cls
  * @Description        :
  * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
  * @Group              :
  * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
  * @Last Modified On   : 2/4/2020 16:00:49
  * @Modification Log   :
  * Ver       Date            Author      		    Modification
  * 1.0    20/3/2020   Ricardo Almanza     Initial Version
  * 1.0    24/7/2020   Ricardo Almanza     Fix async call processCallback
  * 1.1    27/8/2020   Manuel Perez        Change parameter value
  * 1.1    23/9/2020   Sai Jordana         Added arce. namespace to all classes that are now in the arce-dependencies package
**/
@SuppressWarnings('sf:PreserveStackTrace')
public class Arc_Gen_AsyncTriage_service {
    /**
    *-------------------------------------------------------------------------------
    * @description Web service service
    --------------------------------------------------------------------------------
    * @author ricardo.almanza.contractor@bbva.com
    * @date 03/04/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncTriage_service()
    **/
    @TestVisible
    private Arc_Gen_AsyncTriage_service() {}
    /**
    * @Description: Service response identificator
    */
    public final static String INVALID_PARAMETERS = 'Invalid parameters';
    /**
    * @Description: Service response identificator
    */
    public final static String INVALID_PARAMS_CODE = 'TR004002';
    /**
    *-------------------------------------------------------------------------------
    * @description Method that process the service error responses
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param Map<String, Object> responseMap
    * @return String - The error string
    * @example public static String processErrorData(Map<String, Object> responseMap)
    **/
    public static Arc_Gen_Triage_helper.TriageResponse processCallback(Map<String, Object> responseMap, String riskAssessmentId, String participantId) {
        Arc_Gen_AsyncTriage_helper.reviewURLParams(riskAssessmentId, participantId);
        arce__Analysis__c arceVar = new arce__Analysis__c();
        Arc_Gen_Triage_helper.TriageResponse ret;
        try {
            arceVar = arce.Arc_Gen_ArceAnalysis_Data.getArceByRiskAssessm(new List<String>{riskAssessmentId}).get(0);
        } catch(ListException e) {
            System.debug('e '+e.getStackTraceString());
            throw new Arc_Gen_AsyncTriage_helper.InvalidParametersException(Json.serializePretty(Arc_Gen_AsyncTriage_helper.setErrorResponse(INVALID_PARAMS_CODE,INVALID_PARAMETERS,null),true));
        }
        try {
            ret = Arc_Gen_Triage_helper.setupTriageService(arceVar, responseMap, 'callback');
        } catch (Exception e) {
            throw new Arc_Gen_AsyncTriage_helper.InvalidParametersException(Json.serializePretty(Arc_Gen_AsyncTriage_helper.setErrorResponse(INVALID_PARAMS_CODE,INVALID_PARAMETERS,null),true));
        }
        return ret;
    }
}