public with sharing class DMT_Features_Selector {

    public static List<DMT_Feature__c> getFeatures(String recordId, String featureType) {
        return [
            SELECT Id, Name, gf_capability_engine_id_number__c, gf_code_value_id__c, gf_feature_name_desc__c, 
                   gf_passport_sanction_feature_type_desc__c, gf_feature_deal_type__c, gf_global_feature_id_number__c,
                   (SELECT Id, Feature__c, Name, Line__c, Opportunity__c 
                    FROM Selected_Features__r 
                    WHERE Line__c = :recordId OR Opportunity__c = :recordId)
            FROM DMT_Feature__c
            WHERE (gf_operation_type_name__c = 'LIN' AND gf_feature_deal_type__c = :featureType)
               OR gf_operation_type_name__c = 'ALL'
               OR gf_operation_type_name__c = 'OPP'
        ];
    }

    public static Passport__c getPassportByLineOrOpportunity(String lineOrOpportunityId) {
        List<Passport__c> passports = [
            SELECT Id, DMT_Passport_Save__c, DMT_Line__c 
            FROM Passport__c 
            WHERE DMT_Line__c = :lineOrOpportunityId
               OR Opportunity__c = :lineOrOpportunityId
            LIMIT 1
        ];
        return passports.isEmpty() ? null : passports[0];
    }
}