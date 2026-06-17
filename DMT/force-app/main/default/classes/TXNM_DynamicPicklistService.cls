public with sharing class TXNM_DynamicPicklistService {

    public static TXNM_Taxonomy_mapping__mdt taxonomyMapping = new TXNM_Taxonomy_mapping__mdt();
    public static List<TXNM_Taxonomy__b> taxonomyRecords = new List<TXNM_Taxonomy__b>();
    public static List<TXNM_DynamicPicklistHandler.PickValue> picklistValues = new List<TXNM_DynamicPicklistHandler.PickValue>();

    // inner classes to ease flow and deserialize

    public class ObjectFieldMapping {
        public String targetObject {get;set;}
        public String targetField  {get;set;}
    }
    @future(callout=true)
    public static void createDynamicPicklistValues(String taxonomyCode, String serializedMdt) {
        try {
            TXNM_Taxonomy_mapping__mdt metadataConfig = (TXNM_Taxonomy_mapping__mdt) JSON.deserialize(serializedMdt, TXNM_Taxonomy_mapping__mdt.class);
            taxonomyMapping = metadataConfig;
            retrieveRecords(taxonomyCode);
            if (taxonomyRecords.size() > 0) {
                setPicklistValues();
                List<ObjectFieldMapping> formattedMappings = formatTaxonomyMappings();
                for (ObjectFieldMapping objectAndField : formattedMappings) {
                    updatePicklist(objectAndField);
                }
            }
        } catch (Exception e) {
            throw e; // Re-throw the exception to ensure the flow is aware of the failure
        }
    }

    public static void retrieveRecords(String taxonomyCode) {
        if (!Test.isRunningTest()) {
            taxonomyRecords = [SELECT ValueLabel__c, ValueApiName__c from TXNM_Taxonomy__b WHERE TaxonomyCode__c = :taxonomyCode AND LastModifiedDate__c = TODAY WITH SECURITY_ENFORCED];
            // IF ANY LIST IS NULL, THROW ERROR
        }
    }

    public static void setPicklistValues() {
        for (TXNM_Taxonomy__b taxo : taxonomyRecords) {
            picklistValues.add(new TXNM_DynamicPicklistHandler.PickValue(taxo.ValueApiName__c, taxo.ValueLabel__c, false));
        }
    }

    public static List<ObjectFieldMapping> formatTaxonomyMappings() {
        // Deserialize JSON into a strongly-typed list
        List<ObjectFieldMapping> formattedMappings = (List<ObjectFieldMapping>) JSON.deserialize(taxonomyMapping.Objects_and_fields__c,List<ObjectFieldMapping>.class);
        return formattedMappings;
    }

    public static void updatePicklist(ObjectFieldMapping objectAndField) {
        TXNM_DynamicPicklistHandler.replaceAllValuesOnFieldAndAssignAllRecordTypes(objectAndField.targetObject,objectAndField.targetField,picklistValues);
    }
}