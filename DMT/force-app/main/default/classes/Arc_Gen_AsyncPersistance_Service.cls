/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AsyncPersistance_Service
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
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_AsyncPersistance_Service {
    /**
    *-------------------------------------------------------------------------------
    * @description Web service Post method
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 20/08/2020
    * @param void
    * @return void
    * @example apiService()
    **/
    @TestVisible
    private Arc_Gen_AsyncPersistance_Service() {}
    /**
    *-------------------------------------------------------------------------------
    * @description Method that process the service error responses
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 20/08/2020
    * @param Map<String, Object> responseMap
    * @return String - The error string
    * @example public static String processErrorData(Map<String, Object> responseMap)
    **/
    public static void processCallback(String requestbody, String riskAssessmentId, String participantId) {
        /*
        * Validate if the URI data is complete
        */
        Arc_Gen_AsyncPersistance_Helper.checkURLParams(riskAssessmentId, participantId);
        /*
        * Validate if the given URL parameters already exists
        */
        final String decryptedClient = arce.Arc_Gen_CallEncryptService.getDecryptedGroup(new List<String>{participantId}).get(0);
        final arce__Account_has_Analysis__c accHasAnalysis = Arc_Gen_AsyncPersistance_Helper.checkIfDataExists(riskAssessmentId, decryptedClient);
        /*
        * Process request body
        */
        try {
            final Map<String, Object> responseDataMap = Arc_Gen_AsyncPersistance_Helper.getResponseValuesMap(requestbody);
            Arc_Gen_AsyncPersistance_Helper.processResponse(responseDataMap, accHasAnalysis);
        } catch (Exception e) {
            Arc_Gen_AsyncPersistance_Helper.throwCustomExcept(e.getMessage());
        }
    }
}