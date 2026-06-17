public with sharing class DMT_FeaturesController {
    
    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> loadFeatures(String recordId, String featureType) {
        try {
            List<DMT_Feature__c> features = DMT_Features_Selector.getFeatures(recordId, featureType);
            List<DMT_Taxonomy_Values__c> featureTypes = DMT_Features_Selector.getFeatureTypes();
            List<Map<String, Object>> records = new List<Map<String, Object>>();
            Map<String, String> featureTypeValueToName = new Map<String, String>();

            for (DMT_Taxonomy_Values__c featureTypeRecord : featureTypes) {
                if (featureTypeRecord.DMT_Value__c != null) {
                    featureTypeValueToName.put((featureTypeRecord.DMT_Value__c).toLowerCase(), featureTypeRecord.DMT_Name__c);
                }
            }
            System.debug('Feature Type Value to Name Map: ' + featureTypeValueToName);
            for (DMT_Feature__c feature : features) {
                Map<String, Object> featureData = new Map<String, Object>();
                String featureTypeName = featureTypeValueToName.containsKey(feature.gf_passport_sanction_feature_type_desc__c)
                    ? featureTypeValueToName.get(feature.gf_passport_sanction_feature_type_desc__c)
                    : feature.gf_passport_sanction_feature_type_desc__c;

                featureData.put('Id', feature.Id);
                featureData.put('Name', feature.Name);
                featureData.put('gf_capability_engine_id_number__c', feature.gf_capability_engine_id_number__c);
                featureData.put('gf_feature_name_desc__c', feature.gf_feature_name_desc__c);
                featureData.put('gf_passport_sanction_feature_type_desc__c', featureTypeName);
                featureData.put('gf_feature_deal_type__c', feature.gf_feature_deal_type__c);
                featureData.put('gf_code_value_id__c', feature.gf_code_value_id__c);
                featureData.put('gf_global_feature_id_number__c', feature.gf_global_feature_id_number__c);
                featureData.put('gf_active_feature_ind_type__c', feature.gf_active_feature_ind_type__c);
                featureData.put('g_entific_id__c', feature.g_entific_id__c );
                
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

     //Añadido para el caso de uso específico de validar características obligatorias en oportunidades cerradas ganadas
    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getObligatoryFeaturesClosedWon(String lineOrOpportunityId) {
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
                            Map<String, Object> feature = (Map<String, Object>) featureObj;
                            String requiredType    = (String) feature.get('requiredType');
                            String passportSanction = (String) feature.get('passportSanction');

                            // Solo features obligatorias Y de tipo passport (proposal)
                            if ('Y'.equals(requiredType)) {
                                featuresList.add(feature);
                            }
                        }
                        System.debug('Obligatory Features for Closed Won: ' + featuresList);
                    }
                }
            }
        } catch (QueryException e) {
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_FeaturesController','getObligatoryFeaturesClosedWon','DMT',''));
        }
        return featuresList;
    }

   @AuraEnabled(cacheable=false)
    public static Map<String, Object> validateFeaturesForClosedWon(String opportunityId) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('isValid', true);
        result.put('incompleteFeatures', new List<Map<String, String>>());

        try {
            List<Map<String, Object>> obligatoryFeatures = getObligatoryFeaturesClosedWon(opportunityId);

            if (obligatoryFeatures == null || obligatoryFeatures.isEmpty()) {
                return result;
            }

            // ── 1. Obtener el ID externo de la Opportunity ─────────────────────────
            Opportunity opp = DMT_Features_Selector.getOpportunityExternalIdById(opportunityId);
            String oppExternalId = opp != null ? opp.DMT_Opp_Id__c : null;

            // ── 2. Recoger los IDs de features que tienen tasks ────────────────────
            List<String> featureIdsWithTasks = new List<String>();
            for (Map<String, Object> feature : obligatoryFeatures) {
                List<Object> tasks = (List<Object>) feature.get('tasks');
                if (tasks != null && !tasks.isEmpty()) {
                    featureIdsWithTasks.add((String) feature.get('id'));
                }
            }

            // ── 3. Consultar Cases y su Task más reciente ──────────────────────────
            // featureId → caseStatus / rawresult
            Map<String, String> featureToCaseStatus = new Map<String, String>();
            Map<String, String> featureToRawResult  = new Map<String, String>();

            if (!featureIdsWithTasks.isEmpty() && String.isNotBlank(oppExternalId)) {
                List<Case> cases = DMT_Features_Selector.getCasesByOpportunityExternalIdAndFeatureIds(
                    oppExternalId,
                    featureIdsWithTasks
                );

                if (!cases.isEmpty()) {
                    Set<Id> caseIds = new Set<Id>();
                    Map<Id, String> caseToFeature = new Map<Id, String>();
                    Map<Id, String> caseToStatus  = new Map<Id, String>();

                    for (Case c : cases) {
                        caseIds.add(c.Id);
                        caseToFeature.put(c.Id, c.DMT_Feature_Id__c);
                        caseToStatus.put(c.Id, c.Status);
                    }

                    // Task más reciente por Case (mismo criterio que getCurrentStepsFromCases)
                    List<Task> workflowTasks = DMT_Features_Selector.getWorkflowTasksByCaseIds(caseIds);

                    Map<Id, Task> latestTaskPerCase = new Map<Id, Task>();
                    for (Task t : workflowTasks) {
                        if (!latestTaskPerCase.containsKey(t.WhatId)) {
                            latestTaskPerCase.put(t.WhatId, t); // Primera = más reciente
                        }
                    }

                    for (Id caseId : latestTaskPerCase.keySet()) {
                        String featureId = caseToFeature.get(caseId);
                        featureToCaseStatus.put(featureId, caseToStatus.get(caseId));
                        featureToRawResult.put(featureId, latestTaskPerCase.get(caseId).DMT_Step_Result__c);
                    }
                }
            }

            // ── 4. Evaluar cada feature obligatoria ───────────────────────────────
            List<Map<String, String>> incompleteFeatures = new List<Map<String, String>>();

            for (Map<String, Object> feature : obligatoryFeatures) {
                String featureId = (String) feature.get('id');
                String stateName = (String) feature.get('stateName');
                List<Object> tasks = (List<Object>) feature.get('tasks');
                Boolean isIncomplete = false;

                // Capability roja: stateName RED en el JSON del passport
                if ('RED'.equals(stateName)) {
                    isIncomplete = true;
                }

                // Workflow rojo: Case Finished + resultado No (misma lógica que getWorkflowColor en LWC)
                if (!isIncomplete && tasks != null && !tasks.isEmpty()) {
                    String caseStatus = featureToCaseStatus.get(featureId);
                    String rawResult  = featureToRawResult.get(featureId);
                    if ('Finished'.equals(caseStatus) && 'No'.equals(rawResult)) {
                        isIncomplete = true;
                    }
                }

                if (isIncomplete) {
                    Map<String, String> incompleteFeature = new Map<String, String>();
                    incompleteFeature.put('id', featureId);
                    incompleteFeature.put('name', (String) feature.get('name'));
                    incompleteFeature.put('stateName', stateName);
                    incompleteFeature.put('requiredType', (String) feature.get('requiredType'));
                    incompleteFeatures.add(incompleteFeature);
                }
            }

            if (!incompleteFeatures.isEmpty()) {
                result.put('isValid', false);
                result.put('incompleteFeatures', incompleteFeatures);
            }

            return result;

        } catch (Exception e) {
            System.enqueueJob(new DMT_LogExceptionQueueable(
                e.getMessage(), e.getStackTraceString(), e.getLineNumber(),
                e.getTypeName(), 'DMT_FeaturesController', 'validateFeaturesForClosedWon', 'DMT', ''
            ));
            result.put('isValid', true);
            return result;
        }
    }
}