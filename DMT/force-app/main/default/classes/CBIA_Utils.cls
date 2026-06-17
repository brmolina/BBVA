public with sharing class CBIA_Utils {
    private static iaso__GBL_integration_service__mdt integrationService;
    private static String serviceName;
    private static Map<String, Object> request;

    public static HttpResponse callService(String initialServiceName, Map<String, Object> initialRequest) {
        serviceName = initialServiceName;
        request = (initialRequest == null) ? new Map<String, Object>() : initialRequest;
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

    @TestVisible private static HttpResponse callService(String initialServiceName, Map<String, Object> initialRequest, HttpResponse customResponse) {
        HttpResponse unusedResponse = callService(initialServiceName, initialRequest);
        return customResponse;
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
    
    public static Map<String, Object> buildRequest(Map<String, Object> queryParameters, Map<String, Object> requestBody) {
        Map<String, Object> request = new Map<String, Object>();

        if (requestBody != null) {
            request.put('payload', JSON.serialize(requestBody));
        }

        return request;
    }
    
    public static CBIA_ServiceResponse processResponse(HttpResponse response, List<Integer> expectedStatusCodes) {
        CBIA_ServiceResponse toReturn = new CBIA_ServiceResponse();
        Map<String, Object> jsonResponse;

        if ((response.getBody().startsWith('{') && response.getBody().endsWith('}')) || (response.getBody().startsWith('[') && response.getBody().endsWith(']'))) {
            jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        }

        if (expectedStatusCodes.contains(response.getStatusCode())) {
            if (jsonResponse != null) {
                toReturn.isError = false;
                toReturn.data = jsonResponse.get('data');
            } else {
                toReturn.isError = false;
                toReturn.data = response.getBody();
            }
        } else {
            toReturn.isError = true;
            toReturn.errorMessage = 'The service returns an unexpected HTTP status code: ' + response.getStatusCode() + ' ' + response.getStatus();

            Map<String, Object> errorDetails = new Map<String, Object>();
            errorDetails.put('responseHttpStatusCode', response.getStatusCode());
            errorDetails.put('responseHttpStatus', response.getStatus());
            errorDetails.put('responseBody', response.getBody());
            toReturn.errorDetails = errorDetails;
        }

        return toReturn;
    }

    public static CBIA_ServiceResponse treatException(Exception e) {
        CBIA_ServiceResponse response = buildErrorServiceResponse(e);
        logExceptionInDebugLogs(e);
        logExceptionLocally(e);

        return response;
    }

    private static CBIA_ServiceResponse buildErrorServiceResponse(Exception e) {
        CBIA_ServiceResponse response = new CBIA_ServiceResponse();

        response.isError = true;
        response.errorMessage = 'Apex exception: ' + e.getMessage();

        Map<String, Object> errorDetails = new Map<String, Object>();
        errorDetails.put('exception', e + '');
        if (e.getCause() != null) {
            errorDetails.put('cause', e.getCause() + '');
        }
        errorDetails.put('stackTrace', e.getStackTraceString());
        response.errorDetails = errorDetails;

        return response;
    }

    private static void logExceptionInDebugLogs(Exception e) {
        System.debug(e);
        if (e.getCause() != null) {
            System.debug(e.getTypeName() + ' was caused by ' + e.getCause());
        }
        System.debug('Stack trace:\n' + e.getStackTraceString());
    }

    private static void logExceptionLocally(Exception e) {
        try {
            DES_Exception_Utils.logException(e, null, null, 'CIBIA', null);
        } catch (Exception ignored) {
            return;
        }
    }
}