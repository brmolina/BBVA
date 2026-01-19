/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AsyncTriage_controller
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 06/12/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Apex Rest web service to listen the triage asynchronous callback
* The URL is /services/apexrest/TriageCallback/createNotifyResult/v1?risk-assessment-id=01234567890&participant-id=G0012345
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |28/10/2019 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |22/03/2021 joseluis.garcia4.contractor@bbva.com
*             Change async triage response code to 201, according to API definition.
* |01/03/2022 francisco.munoz.torres.contractor@bbva.com
*             Check triage results before send ok response
* -----------------------------------------------------------------------------------------------
*/
@RestResource(urlMapping='/TriageCallback/createNotifyResult/v1/*')
global class Arc_Gen_AsyncTriage_controller {
    /**
    *-------------------------------------------------------------------------------
    * @description Web service Post method
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 06/12/2019
    * @param void
    * @return void
    * @example apiService()
    **/
    @TestVisible
    private Arc_Gen_AsyncTriage_controller() {}
    /**
    *-------------------------------------------------------------------------------
    * @description Web service Post method
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 06/12/2019
    * @param void
    * @return void
    * @example apiService()
    **/
    @HttpPost
    global static void apiService() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');
        try {
            String riskAssessmentId = request.params.get('risk-assessment-id');
            String participantId = request.params.get('participant-id');
            System.debug('riskAssessmentId '+riskAssessmentId);
            System.debug('participantId '+participantId);
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(request.requestbody.tostring());
            Arc_Gen_Triage_helper.TriageResponse triageResp = Arc_Gen_AsyncTriage_service.processCallback(requestMap,riskAssessmentId,participantId);
            if(triageResp.response.saveStatus == 'true') {
              response.responseBody = Blob.valueOf('{ "TriageResponse" : "OK","riskAssessmentId":"'+riskAssessmentId+'","participantId":"'+participantId+'" }');
              response.statusCode = 201;
            } else {
              response.responseBody = Blob.valueOf('{"messages":['+triageResp.response.saveMessage+']}');
              response.statusCode = 500;
            }
        } catch(Arc_Gen_AsyncTriage_helper.InvalidParametersException e) {
            response.responseBody = Blob.valueOf('{"messages":['+e.getMessage()+']}');
            response.statusCode = 400;
        }
    }
}