/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AsyncPersistance_Controller
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
@RestResource(urlMapping='/RenewCallback/createAssessmentsNotifyResult/v1/*')
global class Arc_Gen_AsyncPersistance_Controller {
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
    private Arc_Gen_AsyncPersistance_Controller() {}
    /**
    *-------------------------------------------------------------------------------
    * @description Web service Post method
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 20/08/2020
    * @param void
    * @return void
    * @example restApexService()
    **/
    @HttpPost
    global static void restApexService() {
        final RestRequest request = RestContext.request;
        final RestResponse response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');
        try {
            final String riskAssessmentId = request.params.get('risk-assessment-id');
            final String participantId = request.params.get('participant-id');
            Arc_Gen_AsyncPersistance_Service.processCallback(request.requestbody.tostring(),riskAssessmentId,participantId);
            response.responseBody = Blob.valueOf('{ "RenewResponse" : "OK","riskAssessmentId":"'+riskAssessmentId+'","participantId":"'+participantId+'" }');
            response.statusCode = 200;
        } catch(Arc_Gen_AsyncPersistance_Helper.InvalidParametersException e) {
            response.responseBody = Blob.valueOf('{"messages":['+e.getMessage()+']}');
            response.statusCode = 400;
        } catch(Arc_Gen_AsyncPersistance_Helper.ApexServerException e) {
            response.responseBody = Blob.valueOf('{"messages":['+e.getMessage()+']}');
            response.statusCode = 500;
        }
    }
}