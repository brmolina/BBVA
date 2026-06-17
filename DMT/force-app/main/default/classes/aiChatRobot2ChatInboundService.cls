@RestResource(urlMapping='/ai/callback')
global with sharing class aiChatRobot2ChatInboundService {
    
    @HttpPost
    global static void receiveCallback() {
        try {
            RestRequest req = RestContext.request;
            String body = req.requestBody.toString();
            RestResponse res = RestContext.response;
            res.statusCode = 202; // Accepted (asynchronous)
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf('{"status":"accepted"}');
        } catch (Exception e) {
            RestContext.response.statusCode = 500;
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf('{"error":"' + e.getMessage() + '"}');
        }
    }
}