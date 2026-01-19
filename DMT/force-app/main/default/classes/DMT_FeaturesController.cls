public with sharing class DMT_FeaturesController {
    
    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> loadFeatures(String recordId, String featureType) {
        try {
            List<DMT_Feature__c> features = DMT_Features_Selector.getFeatures(recordId, featureType);
            List<Map<String, Object>> records = new List<Map<String, Object>>();
            
            for (DMT_Feature__c feature : features) {
                Map<String, Object> featureData = new Map<String, Object>();
                featureData.put('Id', feature.Id);
                featureData.put('Name', feature.Name);
                featureData.put('gf_capability_engine_id_number__c', feature.gf_capability_engine_id_number__c);
                featureData.put('gf_feature_name_desc__c', feature.gf_feature_name_desc__c);
                featureData.put('gf_passport_sanction_feature_type_desc__c', feature.gf_passport_sanction_feature_type_desc__c);
                featureData.put('gf_feature_deal_type__c', feature.gf_feature_deal_type__c);
                featureData.put('gf_code_value_id__c', feature.gf_code_value_id__c);
                featureData.put('gf_global_feature_id_number__c', feature.gf_global_feature_id_number__c);
                
                Boolean isSelected = !feature.Selected_Features__r.isEmpty();
                featureData.put('isSelected', isSelected);
                featureData.put('selectedFeatureId', feature.Selected_Features__r.isEmpty() ? null : feature.Selected_Features__r[0].Id);
    
                records.add(featureData);
            }
            return records;
        } catch (Exception e) {
            throw new AuraHandledException('Error in DMT_FeaturesController.loadFeatures: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Id getPassportIdFromLineOrOpportunity(String lineOrOpportunityId) {
        Passport__c passport = DMT_Features_Selector.getPassportByLineOrOpportunity(lineOrOpportunityId);

        if (passport == null) {
            throw new AuraHandledException('Passport not found');
        }
        return passport.Id;
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getObligatoryFeatures(String lineOrOpportunityId) {
        List<Map<String, Object>> featuresList = new List<Map<String, Object>>();
        try {
            Passport__c passportRecord = DMT_Features_Selector.getPassportByLineOrOpportunity(lineOrOpportunityId);

            if (passportRecord.DMT_Passport_Save__c != null) {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(passportRecord.DMT_Passport_Save__c);
                if (data.containsKey('data')) {
                    Map<String, Object> dataMap = (Map<String, Object>) data.get('data');
                    if (dataMap.containsKey('features')) {
                        List<Object> rawFeatures = (List<Object>) dataMap.get('features');
                        for (Object featureObj : rawFeatures) {
                            featuresList.add((Map<String, Object>) featureObj);
                        }
                    }
                }
            }
        } catch (QueryException e) {
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_FeaturesController','getObligatoryFeatures','DMT',''));
        }
        return featuresList;
    }
}