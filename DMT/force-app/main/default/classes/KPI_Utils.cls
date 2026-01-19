public with sharing class KPI_Utils {
    private static iaso__GBL_integration_service__mdt integrationService;

    public static HttpResponse callService(String serviceName, Map<String, Object> initialRequest) {
        Map<String, Object> request = (initialRequest == null) ? new Map<String, Object>() : initialRequest;
        request.put('userId', [SELECT FederationIdentifier FROM User WHERE Id = :UserInfo.getUserId()].FederationIdentifier);
        final String requestStr = JSON.serialize(request);
        HttpResponse response;

        integrationService = [SELECT iaso__Mock_LTA__c, iaso__Http_Method__c, iaso__Retrieve_Mock_LTA__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName = :serviceName WITH USER_MODE];

        if (Test.isRunningTest() || integrationService.iaso__Retrieve_Mock_LTA__c) {
            response = getMock(serviceName);
        } else {
            response = iaso.GBL_Integration_GenericService.invoke(serviceName, requestStr);
        }

        System.debug('SERVICE: ' + serviceName);
        System.debug('REQUEST: ' + requestStr);
        System.debug('STATUS: ' + response.getStatusCode());
        System.debug('RESPONSE: ' + response.getBody());

        return response;
    }

    public static HttpResponse getMock(String serviceName) {
        final HttpResponse response = new HttpResponse();

        switch on integrationService.iaso__Http_Method__c {
            when 'POST' {
                response.setStatusCode(201);
                response.setStatus('Created');
            }
            when 'PUT', 'DELETE' {
                response.setStatusCode(204);
                response.setStatus('No Content');
            }
            when else {
                response.setStatusCode(200);
                response.setStatus('OK');
            }
        }
        if (integrationService.iaso__Mock_LTA__c != null) {
            response.setBody(integrationService.iaso__Mock_LTA__c);
        }

        return response;
    }
}