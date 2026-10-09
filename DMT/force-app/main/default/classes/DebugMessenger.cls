public class DebugMessenger {
    public static void send(String message, String sourceClass) {
        Debug_Message__e debugEvent = new Debug_Message__e(
            Message__c = message,
            Source__c = sourceClass,
            Timestamp__c = System.now()
        );
        EventBus.publish(debugEvent);
    }

    public static void sendIntegrationInvocation(String endpoint, String requestBody, String sourceClass) {
        send(
            'Endpoint: ' + endpoint +
            '\nRequest body: ' + requestBody +
            '\nStack trace: ' + getStackTrace(),
            sourceClass
        );
    }

    private static String getStackTrace() {
        try {
            throw new CalloutException('Debug stack trace capture');
        } catch (Exception ex) {
            return ex.getStackTraceString();
        }
    }
}