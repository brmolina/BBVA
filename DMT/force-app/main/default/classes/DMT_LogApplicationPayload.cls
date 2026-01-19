public with sharing class DMT_LogApplicationPayload implements DMT_AsyncPayload {
    public List<iaso__GBL_Application_Log__c> logs {get; set;}
    public DMT_LogApplicationPayload(List<iaso__GBL_Application_Log__c> logs) {
        this.logs = logs;
    }
}