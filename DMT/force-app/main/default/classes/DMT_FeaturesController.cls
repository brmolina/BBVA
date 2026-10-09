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

    /*
    // DEPRECATED: sustituido por DMT_Semaphore_Logic + validateSemaphoreRulesForStageChange (dmt_custom_path_opp)
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
    }*/

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> validateSemaphoreRulesForStageChange(String opportunityId, String targetStatus) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('isValid', true);
        result.put('incompleteFeatures', new List<String>());

        try {

            if ('Closed Lost'.equalsIgnoreCase(targetStatus)) {
                return result;
            }
            List<Map<String, Object>> features = getObligatoryFeatures(opportunityId);
            if (features == null || features.isEmpty()) {
                return result;
            }

            // Quedarnos solo con las features cuya regla aplica a este cambio de estado concreto
            List<Map<String, Object>> applicableFeatures = new List<Map<String, Object>>();
            List<String> featureIdsWithTasks = new List<String>();

            for (Map<String, Object> feature : features) {
                String requiredType = (String) feature.get('requiredType');
                String reqColorCap  = (String) feature.get('requiredColorCapability');
                String reqColorWF   = (String) feature.get('requiredColorWorkflow');

                // Incluir si tiene config de semáforo nueva O si es obligatoria por el campo legado
                Boolean hasNewSemaphoreConfig = String.isNotBlank(reqColorCap) || String.isNotBlank(reqColorWF);
                Boolean isMandatory = 'Y'.equalsIgnoreCase(requiredType) && hasNewSemaphoreConfig;
                if (!isMandatory) continue;

                // Solo evaluar si la regla aplica al targetStatus recibido
                String featureRequiredStatus = (String) feature.get('requiredStatus');
                if (featureRequiredStatus == null) {
                    continue;
                }

                Boolean matchesTargetStatus = featureRequiredStatus.equalsIgnoreCase(targetStatus);

                // Caso especial: si se avanza a Closed Won, aceptamos también que el JSON envíe requiredStatus = "Closed" (sin distinguir Won/Lost) como equivalente.
                // No aplica a Closed Lost.
                if (!matchesTargetStatus && 'Closed Won'.equalsIgnoreCase(targetStatus)) {
                    matchesTargetStatus = 'Closed'.equalsIgnoreCase(featureRequiredStatus);
                }

                if (!matchesTargetStatus) {
                    continue;
                }

                applicableFeatures.add(feature);

                List<Object> tasks = (List<Object>) feature.get('tasks');
                if (tasks != null && !tasks.isEmpty()) {
                    featureIdsWithTasks.add((String) feature.get('id'));
                }
            }

            if (applicableFeatures.isEmpty()) {
                return result;
            }

            // Resolver el color de Workflow usando la MISMA fuente que ya pinta el color
            // en el LWC del Passport (DMT_Case_Steps_Controller es "without sharing"),
            // para evitar que las reglas de sharing del usuario oculten Cases que sí existen.
            Map<String, String> featureToWorkflowColor = new Map<String, String>();
            Opportunity opp = DMT_Features_Selector.getOpportunityExternalIdById(opportunityId);
            String oppExternalId = opp != null ? opp.DMT_Opp_Id__c : null;

            if (!featureIdsWithTasks.isEmpty() && String.isNotBlank(oppExternalId)) {
                List<DMT_Case_Steps_Controller.WRAPPER_Step> steps =
                    DMT_Case_Steps_Controller.getCurrentStepFromFeaturesOpp(featureIdsWithTasks, oppExternalId);

                // Aplanar igual que hace el LWC: Closed/Finished usan subitems, el resto se usa directamente
                List<DMT_Case_Steps_Controller.WRAPPER_Step> flattenedSteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
                for (DMT_Case_Steps_Controller.WRAPPER_Step step : steps) {
                    Boolean isClosedOrFinished = step.itemKey == 'Closed' || step.itemKey == 'Finished';
                    if (isClosedOrFinished && step.subitems != null) {
                        flattenedSteps.addAll(step.subitems);
                    } else {
                        flattenedSteps.add(step);
                    }
                }

                for (DMT_Case_Steps_Controller.WRAPPER_Step step : flattenedSteps) {
                    if (step.featureId != null) {
                        featureToWorkflowColor.put(step.featureId, resolveWorkflowColor(step.caseStatus, step.rawresult));
                    }
                }
            }

            // Evaluar cada feature aplicable contra su regla de semáforo
            List<String> blockingFeatureNames = new List<String>();

            for (Map<String, Object> feature : applicableFeatures) {
                String featureId   = (String) feature.get('id');
                String stateName   = (String) feature.get('stateName');
                String reqColorCap = (String) feature.get('requiredColorCapability');
                String reqColorWF  = (String) feature.get('requiredColorWorkflow');
                List<Object> tasks = (List<Object>) feature.get('tasks');

                DMT_Semaphore_Logic.SemaphoreRule rule = new DMT_Semaphore_Logic.SemaphoreRule();
                rule.requiredColorCapability  = reqColorCap;
                rule.requiredColorWorkflow    = reqColorWF;
                rule.colorLogicalOperatorType = (String) feature.get('colorLogicalOperatorType');
                String currentCapabilityColor = DMT_Semaphore_Logic.normalizeToShortColor(stateName);

                // Cuando no hay Case en Salesforce para la feature
                // sin Case + tiene tasks = YEL.
                String rawWorkflowColor;
                if (featureToWorkflowColor.containsKey(featureId)) {
                    rawWorkflowColor = featureToWorkflowColor.get(featureId);
                } else if (tasks != null && !tasks.isEmpty()) {
                    rawWorkflowColor = 'YEL';
                } else {
                    rawWorkflowColor = null;
                }
                String currentWorkflowColor = DMT_Semaphore_Logic.normalizeToShortColor(rawWorkflowColor);

                System.debug('SEMAPHORE_DEBUG feature=' + feature.get('name')
                                + ' stateName=' + stateName
                                + ' currentCapabilityColor=' + currentCapabilityColor
                                + ' requiredColorCapability=' + reqColorCap
                                + ' currentWorkflowColor=' + currentWorkflowColor
                                + ' requiredColorWorkflow=' + reqColorWF
                                + ' operator=' + rule.colorLogicalOperatorType);

                Boolean isBlocking = !DMT_Semaphore_Logic.evaluate(rule, currentCapabilityColor, currentWorkflowColor);

                System.debug('SEMAPHORE_DEBUG result isBlocking=' + isBlocking);

                if (isBlocking) {
                    blockingFeatureNames.add((String) feature.get('name'));
                }
            }

            if (!blockingFeatureNames.isEmpty()) {
                result.put('isValid', false);
                result.put('incompleteFeatures', blockingFeatureNames);
            }

            return result;

        } catch (Exception e) {
            System.enqueueJob(new DMT_LogExceptionQueueable(
                e.getMessage(), e.getStackTraceString(), e.getLineNumber(),
                e.getTypeName(), 'DMT_FeaturesController', 'validateSemaphoreRulesForStageChange', 'DMT', ''
            ));
            result.put('isValid', true);
            return result;
        }
    }

    /**
     * Deriva el color de Workflow desde el status del Case y el resultado de la Task más reciente.
     */
    @TestVisible
    private static String resolveWorkflowColor(String caseStatus, String rawResult) {
        if ('Finished'.equals(caseStatus)) {
            if ('No'.equals(rawResult)) return 'RED';
            if ('Yes'.equals(rawResult)) return 'GRE';
            return null;
        }
        if ('Pending'.equals(caseStatus) || 'In Progress'.equals(caseStatus)) {
            return 'YEL';
        }
        return null;
    }
}