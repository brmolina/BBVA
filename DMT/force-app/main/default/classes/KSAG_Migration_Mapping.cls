public with sharing class KSAG_Migration_Mapping {

    private static Map<String,Map<String, Map<String, String>>> objectFieldValueMappings= new Map<String,Map<String, Map<String, String>>>();

    /**
     * Public entry point to apply mappings to an Account.
     * Loads metadata only once.
     */
    public static void applyMappings(SObject recordToMap, String targetObject) {
        if (objectFieldValueMappings.isEmpty() ) {
            List<KSAG_Migration_Mapping__mdt> metadataRecords = queryCustomMetadata();
            buildMappings(metadataRecords);
        }
        applyToAccount(recordToMap, targetObject);
    }

    /**
     * Queries the Custom Metadata.
     * Split for testability.
     */
    private static List<KSAG_Migration_Mapping__mdt> queryCustomMetadata() {
        return [
            SELECT Field_Name__c, Mapped_Values__c, Object__c
            FROM KSAG_Migration_Mapping__mdt where Object__c != null
        ];
    }

    /**
     * Builds the internal mapping from metadata records.
     */
    public static void buildMappings(List<KSAG_Migration_Mapping__mdt> records) {
        for(KSAG_Migration_Mapping__mdt mapping : records){
            
            if (String.isBlank(mapping.Mapped_Values__c) || String.isBlank(mapping.Field_Name__c)) {
                continue;
            }

            try {
                Map<String, Object> rawMap = (Map<String, Object>) JSON.deserializeUntyped(mapping.Mapped_Values__c);
                Map<String, String> strMap = new Map<String, String>();
                for (String key : rawMap.keySet()) {
                    strMap.put(key, String.valueOf(rawMap.get(key)));
                }
                if(objectFieldValueMappings.get(mapping.Object__c) != null){
                    objectFieldValueMappings.get(mapping.Object__c).put(mapping.Field_Name__c, strMap);
                }
                else{
                    Map<String, Map<String, String>> fieldValueMappings = new Map<String, Map<String, String>>();
                    fieldValueMappings.put(mapping.Field_Name__c, strMap);
                    objectFieldValueMappings.put(mapping.Object__c,fieldValueMappings);
                }
            } catch (Exception e) {
                System.debug('Failed to parse mapping for field: ' + mapping.Field_Name__c + ', error: ' + e.getMessage());
            }
                
        }
    }

    /**
     * Applies the value mappings to an Account record.
     */
    private static void applyToAccount(SObject recordToMap, String targetObject) {
        if (objectFieldValueMappings == null || objectFieldValueMappings.isEmpty()) return;
        if (objectFieldValueMappings.get(targetObject) == null || objectFieldValueMappings.get(targetObject).isEmpty()) return;
        Map<String, Map<String, String>> fieldValueMappings = objectFieldValueMappings.get(targetObject);
        for (String fieldName : fieldValueMappings.keySet()) {
            Map<String, String> valueMap = fieldValueMappings.get(fieldName);
            Object oldValue = recordToMap.get(fieldName);
            if (oldValue != null) {
                String newValue = valueMap.get(String.valueOf(oldValue));
                if (newValue != null) {
                    recordToMap.put(fieldName, newValue);
                }
            }
        }
    }
}