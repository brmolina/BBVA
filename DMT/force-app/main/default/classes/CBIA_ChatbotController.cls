public with sharing class CBIA_ChatbotController {
    @AuraEnabled
    public static CBIA_ServiceResponse sendMessage(Map<String, Object> requestBody) {
        CBIA_ServiceResponse response;
        try {
            response = CBIA_ChatbotService.postMessage(requestBody);
        } catch (Exception e) {
            response = CBIA_Utils.treatException(e);
        }
        return response;
    }

    @AuraEnabled
    public static CBIA_ServiceResponse giveMessageFeedback(Map<String, Object> requestBody) {
        CBIA_ServiceResponse response;
        try {
            response = CBIA_ChatbotService.postMessageFeedback(requestBody);
        } catch (Exception e) {
            response = CBIA_Utils.treatException(e);
        }
        return response;
    }
}