public with sharing class AccountRelationshipTriggerHandler {
    public AccountRelationshipTriggerHandler() {

    }

    public void applyMappings(List<dwp_acmh__GBL_Account_Relationship__c> relationships) {
        if (relationships == null || relationships.isEmpty()) return;

        for (dwp_acmh__GBL_Account_Relationship__c relationship : relationships) {
            // Apply mappings to each relationship record
            KSAG_Migration_Mapping.applyMappings(relationship, 'dwp_acmh__GBL_Account_Relationship__c');
        }
    }
}