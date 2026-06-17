public without sharing class DMT_LineConcurrencyController {
    @AuraEnabled(cacheable=false) // IMPORTANTE: cacheable=false
    public static String getLineLockStatus(Id recordId) {
        return [SELECT DMT_Line_Lock__c FROM DMT_Line__c WHERE Id = :recordId LIMIT 1].DMT_Line_Lock__c;
    }
}