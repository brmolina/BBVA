public with sharing class PRF_Utils {

    public static HttpResponse callService(String serviceName, Map<String, Object> request) {
        final String requestStr = JSON.serialize(request);
        HttpResponse response;
        if (Test.isRunningTest()) {
            response = getMock(serviceName);
        } else {
            response = iaso.GBL_Integration_GenericService.invoke(serviceName, requestStr);
        }

        return response;
    }

    public static HttpResponse getMock(String serviceName) {
        final HttpResponse response = new HttpResponse();
        final iaso__GBL_integration_service__mdt serviceDetails = [SELECT iaso__Mock_LTA__c , iaso__Http_Method__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName =:serviceName LIMIT 1];
        final String responseBody = (String)serviceDetails.get('iaso__Mock_LTA__c');
        final String requestMethod = (String)serviceDetails.get('iaso__Http_Method__c');
        response.setStatus('OK');
        if (serviceName == 'PRF_CreateUser' || serviceName == 'PRF_UpdateUser') {
            response.setStatusCode(204);
        }else {
            response.setStatusCode(requestMethod == 'GET' ? 200 : 201);
        }
        response.setBody(responseBody);
        return response;
    }

    public static String getFederationIdentifier() {
        final Id userId = UserInfo.getUserId();
        return [SELECT FederationIdentifier FROM User WHERE Id = :userId LIMIT 1].FederationIdentifier;
    }

    public static Map<String,Object> handleServiceError(Map<String,Object> responseBodyErrorMap){
        Map<String,Object> returnMap = new Map<String,Object>();
        String responseSerialize = JSON.serialize(responseBodyErrorMap.get('messages'));
        final Map<String, Object> responseMap1 = (Map<String, Object>) JSON.deserializeUntyped(responseSerialize.substring(1, responseSerialize.length() -1));
        final String response = (String)responseMap1.get('message');
        returnMap.put('success', false);
        returnMap.put('errorMessage', 'An error ocurred meanwhile calling the service, please try again later.' + ' ' + response);
        return returnMap;
    }
    

}