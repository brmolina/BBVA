public class CBIA_ServiceResponse {
    /** The content of the service response */
    @AuraEnabled public Object data;
    /** Indicates that something has gone wrong. It covers from unexpected HTTP status codes to Apex exceptions */
    @AuraEnabled public Boolean isError;
    /** A brief error message. It should not be shown to non-technical users */
    @AuraEnabled public String errorMessage;
    /** A map of error parameter names and values. It should be serialized into non-pretty-printed JSON for easy transmission and analysis */
    @AuraEnabled public Map<String, Object> errorDetails;
}