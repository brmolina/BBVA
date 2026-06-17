public with sharing class ONB_RiskStateController {
    @AuraEnabled
    public static Id getOrCreateExternalContact(Id onboardingId, String clientType) {
        if (onboardingId == null) return null;

        Id existingExternalContactId = getExternalContactRisk(onboardingId, clientType);
        if (existingExternalContactId != null) {
            return existingExternalContactId;
        }

        Id newExternalContactId = createExternalContact(onboardingId, clientType);

        return newExternalContactId;
    }
    //Metodo que busca al Contacto externo
    public static Id getExternalContactRisk(Id onboardingId, String clientType){
        List<ONB_External_Contact__c> externalContactExisting = [
            SELECT Id
            FROM ONB_External_Contact__c
            WHERE OnboardingId__c = :onboardingId
            AND Type__c = :clientType
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        if (!externalContactExisting.isEmpty()) {
            return externalContactExisting[0].Id;
        }
        return null;
    }
    //Metodo que crea el Contacto externo
    public static Id createExternalContact(Id onboardingId, String clientType){
        ONB_External_Contact__c externalContact = new ONB_External_Contact__c();
        externalContact.Type__c = clientType;
        externalContact.OnboardingId__c = onboardingId;
        insert externalContact;
        return externalContact.Id;
    }
}