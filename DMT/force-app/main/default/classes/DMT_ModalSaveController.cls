public with sharing class DMT_ModalSaveController {

    @TestVisible private static Boolean throwTestException = false;
    @TestVisible private class ForcedException extends Exception {}

    @AuraEnabled(cacheable=true)
    public static List<Case> getCasesByOpportunity(String opportunityId) {
        try {
            if (throwTestException) {
                throw new ForcedException('Forced exception for test coverage');
            }
            
            // Added IsClosed = false to ensure we only trigger the warning 
            // if there is an OPEN case for the Ready To Close feature. CIBGLOBALD-3331
            return [
                SELECT Id, CaseNumber, Status 
                FROM Case 
                WHERE Opportunity_Id__c = :opportunityId 
                  AND DMT_Passport_Sanction__c = 'readytoclose'
                  AND IsClosed = false
                WITH SYSTEM_MODE
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving cases: ' + e.getMessage());
        }
    }
}