public with sharing class DMT_ProfitabilityMigrationBatch implements Database.Batchable<Opportunity>, Database.Stateful {

    public Integer processedCount = 0;
    public Integer successCount = 0;
    public Integer errorCount = 0;
    public List<String> errorMessages = new List<String>();

    public Iterable<Opportunity> start(Database.BatchableContext bc) {
        return [
            SELECT Id
            FROM Opportunity
            WHERE Id IN (
                SELECT Opportunity__c
                FROM Passport__c
                WHERE Opportunity__c != null
            )
        ];
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity opportunityRecord : scope) {
            opportunityIds.add(opportunityRecord.Id);
        }

        List<Passport__c> passports = [
            SELECT Id, Opportunity__c, DMT_Passport_Save__c
            FROM Passport__c
            WHERE Opportunity__c IN :opportunityIds
        ];

        for (Passport__c passport : passports) {
            if (String.isBlank(passport.DMT_Passport_Save__c)) {
                continue;
            }

            processedCount++;

            try {
                DMT_PassportProfitabilityProcessor.updateProfitabilityFields(
                    passport.Opportunity__c,
                    passport.DMT_Passport_Save__c
                );
                successCount++;
            } catch (Exception e) {
                errorCount++;
                errorMessages.add(
                    'Passport ' + passport.Id + ': ' + e.getMessage()
                );
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'DMT_ProfitabilityMigrationBatch finished. Processed=' + processedCount +
            ', Success=' + successCount +
            ', Errors=' + errorCount
        );

        for (String errorMessage : errorMessages) {
            System.debug(LoggingLevel.ERROR, errorMessage);
        }
    }
}