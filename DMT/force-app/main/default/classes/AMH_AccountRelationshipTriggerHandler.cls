public with sharing class AMH_AccountRelationshipTriggerHandler {
    public AMH_AccountRelationshipTriggerHandler() {

    }

    public void applyMappings(List<AMH_GBL_Account_Relationship__c> relationships) {
        if (relationships == null || relationships.isEmpty()) return;

        for (AMH_GBL_Account_Relationship__c relationship : relationships) {
            // Apply mappings to each relationship record
            KSAG_Migration_Mapping.applyMappings(relationship, 'AMH_GBL_Account_Relationship__c');
        }
    }
}