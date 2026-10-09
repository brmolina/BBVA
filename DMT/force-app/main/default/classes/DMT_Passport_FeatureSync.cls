/**
* ────────────────────────────────────────────────────────────────────
* Sync of Approval Cases/Tasks with the Workflow Features received from Passport
* ────────────────────────────────────────────────────────────────────
* @author      javier.angulo.fernandez.contractor@bbva.com
* @version     1.0
* @created     2026-10-01
* ────────────────────────────────────────────────────────────────────
* @changes
* CIBGLOBALD-4507
* ────────────────────────────────────────────────────────────────────
*/
public without sharing class DMT_Passport_FeatureSync {

    /**
     * @description Called from Passport__c after update. After each new passport response:
     * - Feature no longer received: cancels the active tasks of its open case and finishes the case.
     * - Feature received again: reopens the case finished by this logic and recreates its last cancelled task as Not Started.
     */
    public static void sync(List<Passport__c> newPassports, Map<Id, Passport__c> oldMap) {
        Savepoint sp;
        try {
            Map<Id, Set<String>> featuresByOppId = new Map<Id, Set<String>>();
            Map<Id, Set<String>> featuresByLineId = new Map<Id, Set<String>>();

            for (Passport__c passport : newPassports) {
                Passport__c oldPassport = oldMap.get(passport.Id);
                if (String.isBlank(passport.DMT_Passport_Save__c) || passport.DMT_Passport_Save__c == oldPassport.DMT_Passport_Save__c) {
                    continue;
                }

                // Passport without features (or malformed) = do nothing
                Set<String> currentIds = extractFeatureIds(passport.DMT_Passport_Save__c);
                if (currentIds.isEmpty()) {
                    continue;
                }

                if (passport.Opportunity__c != null) {
                    featuresByOppId.put(passport.Opportunity__c, currentIds);
                } else if (passport.DMT_Line__c != null) {
                    featuresByLineId.put(passport.DMT_Line__c, currentIds);
                }
            }

            if (featuresByOppId.isEmpty() && featuresByLineId.isEmpty()) {
                return;
            }

            Id approvalRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(DMT_Constants.CASE_RT_APPROVAL).getRecordTypeId();
            Set<Id> oppIds = featuresByOppId.keySet();
            Set<Id> lineIds = featuresByLineId.keySet();
            Set<Id> casesToCloseIds = new Set<Id>();
            Set<Id> casesToReopenIds = new Set<Id>();

            // Cases with opportunity are only compared against the opportunity passport (they can also have the sanction line informed)
            for (Case c : [SELECT Id, Status, DMT_Feature_Id__c, DMT_Line__c, opportunity_id__c, DMT_Closed_By_Passport__c
                           FROM Case
                           WHERE RecordTypeId = :approvalRtId AND DMT_Feature_Id__c != null
                           AND (opportunity_id__c IN :oppIds OR (DMT_Line__c IN :lineIds AND opportunity_id__c = null))]) {
                Set<String> currentIds = c.opportunity_id__c != null ? featuresByOppId.get(c.opportunity_id__c) : featuresByLineId.get(c.DMT_Line__c);
                Boolean featurePresent = currentIds.contains(c.DMT_Feature_Id__c);

                if (!featurePresent && c.Status != DMT_Constants.FINISHED) {
                    casesToCloseIds.add(c.Id);
                } else if (featurePresent && c.Status == DMT_Constants.FINISHED && c.DMT_Closed_By_Passport__c) {
                    casesToReopenIds.add(c.Id);
                }
            }

            if (casesToCloseIds.isEmpty() && casesToReopenIds.isEmpty()) {
                return;
            }

            Id stepRtId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(DMT_Constants.TASK_RT_APPROVAL_STEP).getRecordTypeId();
            Set<Id> caseIds = new Set<Id>(casesToCloseIds);
            caseIds.addAll(casesToReopenIds);
            List<Task> tasksToCancel = new List<Task>();
            Map<Id, Task> lastCancelledTaskByCaseId = new Map<Id, Task>();

            for (Task t : [SELECT Id, WhatId, Status, OwnerId, RecordTypeId, DMT_Task_Type__c, Subject, DMT_Committee_Label__c, DMT_Not_Restart__c
                           FROM Task
                           WHERE RecordTypeId = :stepRtId AND WhatId IN :caseIds
                           ORDER BY CreatedDate DESC, Id DESC]) {
                if (casesToCloseIds.contains(t.WhatId)) {
                    if (t.Status != DMT_Constants.COMPLETED && t.Status != DMT_Constants.FINISHED && t.Status != DMT_Constants.CANCELLED) {
                        tasksToCancel.add(new Task(Id = t.Id, Status = DMT_Constants.CANCELLED));
                    }
                } else if (t.Status == DMT_Constants.CANCELLED && !lastCancelledTaskByCaseId.containsKey(t.WhatId)) {
                    lastCancelledTaskByCaseId.put(t.WhatId, t);
                }
            }

            List<Case> casesToUpdate = new List<Case>();
            List<Task> tasksToCreate = new List<Task>();

            for (Id caseId : casesToCloseIds) {
                casesToUpdate.add(new Case(Id = caseId, Status = DMT_Constants.FINISHED, DMT_Closed_By_Passport__c = true));
            }

            for (Id caseId : casesToReopenIds) {
                casesToUpdate.add(new Case(Id = caseId, Status = DMT_Constants.PENDING, DMT_Closed_By_Passport__c = false));

                Task lastTask = lastCancelledTaskByCaseId.get(caseId);
                if (lastTask != null) {
                    tasksToCreate.add(new Task(
                        WhatId = caseId,
                        RecordTypeId = lastTask.RecordTypeId,
                        OwnerId = lastTask.OwnerId,
                        DMT_Task_Type__c = lastTask.DMT_Task_Type__c,
                        Subject = lastTask.Subject,
                        DMT_Committee_Label__c = lastTask.DMT_Committee_Label__c,
                        DMT_Not_Restart__c = lastTask.DMT_Not_Restart__c,
                        Status = DMT_Constants.NOTSTARTED
                    ));
                }
            }

            sp = Database.setSavepoint();
            if (!tasksToCancel.isEmpty()) {
                update tasksToCancel;
            }
            if (!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
            if (!tasksToCreate.isEmpty()) {
                insert tasksToCreate;
            }
        } catch (Exception e) {
            if (sp != null) {
                Database.rollback(sp);
            }
            System.debug(LoggingLevel.ERROR, 'Error in DMT_Passport_FeatureSync.sync: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            DES_Exception_Utils.logException(e, 'DMT_Passport_FeatureSync', 'sync', 'DMT', '');
        }
    }

    /**
     * @description Returns the feature ids (data.features[].id) of a passport JSON. Empty set if blank, malformed or without features.
     */
    @TestVisible
    private static Set<String> extractFeatureIds(String passportJson) {
        Set<String> featureIds = new Set<String>();
        if (String.isBlank(passportJson)) {
            return featureIds;
        }

        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(passportJson);
            Map<String, Object> dataMap = (Map<String, Object>) root.get('data');
            if (dataMap == null || !(dataMap.get('features') instanceof List<Object>)) {
                return featureIds;
            }

            for (Object featureObj : (List<Object>) dataMap.get('features')) {
                if (featureObj instanceof Map<String, Object>) {
                    Object featureId = ((Map<String, Object>) featureObj).get('id');
                    if (featureId != null) {
                        featureIds.add(String.valueOf(featureId));
                    }
                }
            }
        } catch (Exception e) {
            featureIds.clear();
        }

        return featureIds;
    }
}