public with sharing class CBIA_ChatbotService {
    public static CBIA_ServiceResponse postMessage(Map<String, Object> requestBody) {
        Map<String, Object> request = CBIA_Utils.buildRequest(null, requestBody);
        HttpResponse response = CBIA_Utils.callService('CBIA_PostMessage', request);
        return CBIA_Utils.processResponse(response, new List<Integer>{201});
    }

    public static CBIA_ServiceResponse postMessageFeedback(Map<String, Object> requestBody) {
        Map<String, Object> request = CBIA_Utils.buildRequest(null, requestBody);
        HttpResponse response = CBIA_Utils.callService('CBIA_PostMessageFeedback', request);
        CBIA_ServiceResponse srvResponse = CBIA_Utils.processResponse(response, new List<Integer>{201});

        if (((Map<String, Object>) srvResponse.data).get('status') == 'KO') {
            srvResponse.isError = true;
            srvResponse.errorMessage = 'The service returns an error response';
            srvResponse.errorDetails = new Map<String, Object>{'responseBody' => response.getBody()};
        }

        return srvResponse;
    }
}