public with sharing class DMT_Passport_TriggerHelper {

    public static void processPassportIntegrationPayload(List<Passport__c> passports) {
        Set<Id> lineIds = new Set<Id>();
        for (Passport__c p : passports) {
            if (p.DMT_Line__c != null) {
                lineIds.add(p.DMT_Line__c);
            }
        }

        if (lineIds.isEmpty()) {
            return;
        }

        Id sanctionRTId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('Sanction')?.getRecordTypeId();

        Map<Id, DMT_Line__c> parentLines = new Map<Id, DMT_Line__c>([SELECT Id, Client__c, RecordTypeId FROM DMT_Line__c WHERE Id IN :lineIds AND RecordTypeId = :sanctionRTId WITH SYSTEM_MODE]);

        for (Passport__c p : passports) {
            DMT_Line__c line = parentLines.get(p.DMT_Line__c);
            
            if (line != null) {
                DMT_AsyncOrchestrator.enqueue(new DMT_PassportPayload(line.Id, line.Client__c, 'DMTO_EvaluationLine')
                );
            }
        }
    }
}