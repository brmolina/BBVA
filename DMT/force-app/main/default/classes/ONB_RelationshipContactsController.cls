public with sharing class ONB_RelationshipContactsController {

    private static final Integer MAX_RESULTS = 200;

    @AuraEnabled(cacheable=true)
    public static List<ONB_External_Contact__c> getExternalContactsByOnboarding(Id onboardingId, String nonce) {
        List<ONB_External_Contact__c> relationships = new List<ONB_External_Contact__c> ();

        if (onboardingId == null){
            return relationships;
        }
        relationships =  [
            SELECT Id, Type__c, Name, Email__c
            FROM ONB_External_Contact__c
            WHERE OnboardingId__c = :onboardingId
            ORDER BY CreatedDate ASC
            LIMIT :MAX_RESULTS
        ];
        return relationships;
    }




    @AuraEnabled(cacheable=true)
    public static List<ONB_Onboarding_Contact_Relationship__c> getRelationshipContactsByOnboarding(Id onboardingId, String nonce) {
        List<ONB_Onboarding_Contact_Relationship__c> relationships = new List<ONB_Onboarding_Contact_Relationship__c> ();

        if (onboardingId == null){
            return relationships;
        }
        relationships =  [
            SELECT Id, UserId__c, ContactId__c, Relationship_Type__c, Email__c, OnboardingId__c, ONB_Contact_Type_State__c
            FROM ONB_Onboarding_Contact_Relationship__c
            WHERE OnboardingId__c = :onboardingId
            ORDER BY CreatedDate ASC
            LIMIT :MAX_RESULTS
        ];
        return relationships;
    }

    @AuraEnabled(cacheable=true)
    public static String getUserEmail(Id userId) {
        if (userId == null) return null;
        User u = [
            SELECT Email
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];
        return u.Email;
    }

    @AuraEnabled(cacheable=true)
    public static String getContactEmail(Id contactId) {
        if (contactId == null) return null;

        Contact c = [
            SELECT Email
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        return c.Email;
    }
}