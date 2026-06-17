public with sharing class DMT_Features_Selector {

    public static List<DMT_Feature__c> getFeatures(String recordId, String featureType) {
        if (featureType != '' ) {
            return [
            SELECT Id, Name, gf_capability_engine_id_number__c, gf_code_value_id__c, gf_feature_name_desc__c,gf_active_feature_ind_type__c, 
                   gf_passport_sanction_feature_type_desc__c, gf_feature_deal_type__c, gf_global_feature_id_number__c,
                   (SELECT Id, Feature__c, Name, Line__c, Opportunity__c 
                    FROM Selected_Features__r 
                    WHERE Line__c = :recordId OR Opportunity__c = :recordId),g_entific_id__c
            FROM DMT_Feature__c
            WHERE (gf_operation_type_name__c = 'LIN' AND gf_feature_deal_type__c = :featureType)
               OR gf_operation_type_name__c = 'ALL'
            ];
        } else {
            return [
            SELECT Id, Name, gf_capability_engine_id_number__c, gf_code_value_id__c, gf_feature_name_desc__c, gf_active_feature_ind_type__c,
                   gf_passport_sanction_feature_type_desc__c, gf_feature_deal_type__c, gf_global_feature_id_number__c,
                   (SELECT Id, Feature__c, Name, Line__c, Opportunity__c 
                    FROM Selected_Features__r 
                    WHERE Line__c = :recordId OR Opportunity__c = :recordId),g_entific_id__c
            FROM DMT_Feature__c
            WHERE gf_operation_type_name__c = 'ALL'
               OR gf_operation_type_name__c = 'OPP'
            ];
        }
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

    public static Opportunity getOpportunityExternalIdById(String opportunityId) {
        List<Opportunity> opportunities = [
            SELECT DMT_Opp_Id__c
            FROM Opportunity
            WHERE Id = :opportunityId
            WITH USER_MODE
            LIMIT 1
        ];
        return opportunities.isEmpty() ? null : opportunities[0];
    }

    public static List<Case> getCasesByOpportunityExternalIdAndFeatureIds(String oppExternalId, List<String> featureIds) {
        if (String.isBlank(oppExternalId) || featureIds == null || featureIds.isEmpty()) {
            return new List<Case>();
        }

        String caseQuery = 'SELECT Id, DMT_Feature_Id__c, Status FROM Case '
            + 'WHERE Opportunity_Id__r.DMT_Opp_Id__c = \''
            + String.escapeSingleQuotes(oppExternalId) + '\' '
            + 'AND DMT_Feature_Id__c IN (\''
            + String.escapeSingleQuotes(String.join(featureIds, '\',\'')) + '\')';

        return (List<Case>) DMT_WithoutSharingDAO.query(caseQuery, 'Case');
    }

    public static List<Task> getWorkflowTasksByCaseIds(Set<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return new List<Task>();
        }

        return [
            SELECT Id, WhatId, DMT_Step_Result__c
            FROM Task
            WHERE WhatId IN :caseIds
            AND RecordType.DeveloperName = 'DMT_Step_Approval'
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];
    }

    public static List<DMT_Taxonomy_Values__c> getFeatureTypes(){
        return [SELECT Id, DMT_Catalog__c, DMT_Name_EN__c, DMT_Name__c, DMT_Value__c FROM DMT_Taxonomy_Values__c DMT_Taxonomy_Values__c where DMT_Catalog__c = 'I221'];
    }
}