public with sharing class DMT_ApprovalTemplate_Controller {

    @AuraEnabled
    public static Map<String, Object> loadData(String recordId) {
        try {
            Map<String, Object> data = new Map<String, Object>();

            // 1. Query Case
            List<Case> cases = [
                SELECT Id, Description, OwnerId,
                       DMT_Line__c, DMT_Line__r.Status__c,
                       DMT_LineOpportunity__c, DMT_Closing_Tasks__c,
                       opportunity_id__c, DMT_Passport_Sanction__c
                FROM Case
                WHERE Id = :recordId
                LIMIT 1
            ];
            if (cases.isEmpty()) {
                return new Map<String, Object>{ 'taskId' => 'norecord' };
            }
            Case cs = cases[0];
            data.put('caseId', cs.Id);
            data.put('description', cs.Description);
            data.put('statusLine', cs.DMT_Line__r != null ? cs.DMT_Line__r.Status__c : '');
            data.put('DMT_LineOpportunity__c', cs.DMT_LineOpportunity__c);
            data.put('OpportunityId', cs.opportunity_id__c);
            data.put('LineId', cs.DMT_Line__c);

            // 2. Get RecordType for DMT_Step_Approval
            Id rtId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
                .containsKey('DMT_Step_Approval')
                ? Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId()
                : null;
            if (rtId == null) {
                return new Map<String, Object>{ 'taskId' => 'norecord' };
            }

            // 3. Query current pending Task (matching DataRaptor query 3)
            List<Task> tasks = [
                SELECT Id, Description, DMT_Step_Result__c, DMT_Step_Type__c,
                       DMT_Not_Restart__c, DMT_Committee_Label__c,
                       DMT_Task_Type__c, OwnerId
                FROM Task
                WHERE WhatId = :recordId
                  AND RecordTypeId = :rtId
                  AND Status != 'Finished'
                  AND Status != 'Completed'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (tasks.isEmpty()) {
                data.put('taskId', 'norecord');
                data.put('hasEditCaseRole', DMT_Utils.hasWriteAccess());
                data.put('hasLineGodAccess', DMT_Utils.checkLineGodUser());
                return data;
            }
            Task t = tasks[0];
            data.put('taskId', t.Id);
            data.put('comments', t.Description != null ? t.Description : '');
            data.put('stepResult', t.DMT_Step_Result__c != null ? t.DMT_Step_Result__c : '');
            data.put('stepType', t.DMT_Step_Type__c != null ? t.DMT_Step_Type__c : '');
            data.put('doNotAskCheck', t.DMT_Not_Restart__c);
            data.put('Committee_Label', t.DMT_Committee_Label__c);

            // Formula: buttonDisabled
            Boolean btnDisabled = String.isBlank(t.DMT_Step_Result__c);
            data.put('buttonDisabled', btnDisabled);

            // 4. Query currentTaskType (DMT_Task_Type__c)
            if (t.DMT_Task_Type__c != null) {
                List<DMT_Task_Type__c> taskTypes = [
                    SELECT Id, Name, DMT_External_Id__c,
                           DMT_Yes_Flag__c, DMT_No_Flag__c, DMT_NA_Flag__c,
                           DMT_Finish_Case__c, DMT_Review_Operation__c,
                           DMT_Send_To_Approver__c,
                           DMT_Closing_Capacity__c, DMT_ApprovalEdit__c,
                           gf_task_ind_type__c
                    FROM DMT_Task_Type__c
                    WHERE Id = :t.DMT_Task_Type__c
                    LIMIT 1
                ];
                if (!taskTypes.isEmpty()) {
                    DMT_Task_Type__c ctt = taskTypes[0];
                    data.put('currentTaskType', ctt);

                    // Formula: finishStep
                    Boolean finishStep = true;
                    if (cs.DMT_Closing_Tasks__c != null) {
                        try {
                            List<Object> closingTasks = (List<Object>) JSON.deserializeUntyped(cs.DMT_Closing_Tasks__c);
                            Integer totalClosing = closingTasks.size();
                            Integer filtered = 0;
                            for (Object ct : closingTasks) {
                                Map<String, Object> ctMap = (Map<String, Object>) ct;
                                if (String.valueOf(ctMap.get('id')) != ctt.DMT_External_Id__c) {
                                    filtered++;
                                }
                            }
                            if ((filtered != totalClosing || filtered == 0 || t.DMT_Step_Result__c == 'No') && !btnDisabled) {
                                finishStep = false;
                            }
                        } catch (Exception ex) {
                            finishStep = true;
                        }
                    } else if (!btnDisabled) {
                        finishStep = false;
                    }
                    data.put('finishStep', finishStep);

                    // Formula: returnToProposalDisabled (returnToProposalForm)
                    Boolean returnDisabled = true;
                    if (cs.DMT_LineOpportunity__c == 'L') {
                        returnDisabled = (cs.DMT_Passport_Sanction__c != 'approval'
                            || ctt.gf_task_ind_type__c != true
                            || t.DMT_Step_Result__c == 'Yes');
                    } else {
                        returnDisabled = true; // Default for non-Line
                    }
                    data.put('returnToProposalDisabled', returnDisabled);

                    // 10. Query next task relationship
                    List<DMT_Task_Relationship__c> taskRels = [
                        SELECT Id, DMT_To_Task_Type__c
                        FROM DMT_Task_Relationship__c
                        WHERE DMT_From_Task_Type__c = :ctt.Id
                        ORDER BY CreatedDate DESC
                    ];
                    if (!taskRels.isEmpty()) {
                        Set<Id> toTaskIds = new Set<Id>();
                        for (DMT_Task_Relationship__c tr : taskRels) {
                            toTaskIds.add(tr.DMT_To_Task_Type__c);
                        }
                        List<DMT_Task_Type__c> toTasks = [
                            SELECT Id, Name, DMT_External_Id__c, DMT_ApprovalEdit__c
                            FROM DMT_Task_Type__c
                            WHERE Id IN :toTaskIds
                            ORDER BY CreatedDate DESC
                        ];
                        if (!toTasks.isEmpty()) {
                            List<Map<String, Object>> toTaskList = new List<Map<String, Object>>();
                            for (DMT_Task_Type__c tt : toTasks) {
                                toTaskList.add(new Map<String, Object>{
                                    'label' => tt.Name,
                                    'value' => tt.DMT_External_Id__c
                                });
                            }
                            data.put('toTask', toTaskList);
                        }
                    }

                    // Build validations list: LISTMERGE(toTask, relatedTaskTypes, currentTaskType) deduplicated by value
                    Set<String> seenValues = new Set<String>();
                    List<Map<String, Object>> validations = new List<Map<String, Object>>();

                    // 1. Add toTask entries (destination task types from relationships)
                    if (!taskRels.isEmpty()) {
                        Set<Id> toTaskIds2 = new Set<Id>();
                        for (DMT_Task_Relationship__c tr : taskRels) {
                            toTaskIds2.add(tr.DMT_To_Task_Type__c);
                        }
                        List<DMT_Task_Type__c> toTasksForVal = [SELECT Id, Name, DMT_External_Id__c, DMT_ApprovalEdit__c FROM DMT_Task_Type__c WHERE Id IN :toTaskIds2 ORDER BY CreatedDate DESC];
                        for (DMT_Task_Type__c tt : toTasksForVal) {
                            if (tt.DMT_External_Id__c != null && !seenValues.contains(tt.DMT_External_Id__c)) {
                                seenValues.add(tt.DMT_External_Id__c);
                                validations.add(new Map<String, Object>{
                                    'label' => tt.Name,
                                    'value' => tt.DMT_External_Id__c,
                                    'DMT_ApprovalEdit__c' => tt.DMT_ApprovalEdit__c
                                });
                            }
                        }
                    }

                    // 2. Add related tasks' task types
                    List<Task> relTasks = [SELECT DMT_Task_Type__c FROM Task WHERE WhatId = :cs.Id AND Status != 'Cancelled' AND Status != 'Completed' AND RecordTypeId = :rtId AND Id != :t.Id];
                    Set<Id> relTaskTypeIds = new Set<Id>();
                    for (Task rt2 : relTasks) {
                        if (rt2.DMT_Task_Type__c != null) {
                            relTaskTypeIds.add(rt2.DMT_Task_Type__c);
                        }
                    }
                    if (!relTaskTypeIds.isEmpty()) {
                        List<DMT_Task_Type__c> relTaskTypes = [SELECT Id, Name, DMT_External_Id__c, DMT_ApprovalEdit__c FROM DMT_Task_Type__c WHERE Id IN :relTaskTypeIds ORDER BY CreatedDate DESC];
                        for (DMT_Task_Type__c rtt : relTaskTypes) {
                            if (rtt.DMT_External_Id__c != null && !seenValues.contains(rtt.DMT_External_Id__c)) {
                                seenValues.add(rtt.DMT_External_Id__c);
                                validations.add(new Map<String, Object>{
                                    'label' => rtt.Name,
                                    'value' => rtt.DMT_External_Id__c,
                                    'DMT_ApprovalEdit__c' => rtt.DMT_ApprovalEdit__c
                                });
                            }
                        }
                    }

                    // 3. Add current task type
                    if (ctt.DMT_External_Id__c != null && !seenValues.contains(ctt.DMT_External_Id__c)) {
                        seenValues.add(ctt.DMT_External_Id__c);
                        validations.add(new Map<String, Object>{
                            'label' => ctt.Name,
                            'value' => ctt.DMT_External_Id__c,
                            'DMT_ApprovalEdit__c' => ctt.DMT_ApprovalEdit__c
                        });
                    }
                    data.put('validations', validations);

                    // Proposal validations: filter where DMT_ApprovalEdit__c == false
                    List<Map<String, Object>> propValidations = new List<Map<String, Object>>();
                    for (Map<String, Object> v : validations) {
                        if (v.get('DMT_ApprovalEdit__c') != true) {
                            propValidations.add(v);
                        }
                    }
                    data.put('proposalValidations', propValidations);
                }
            }

            // 5-7. Query approver access for current user
            if (cs.OwnerId != null) {
                String accessLevel = '';
                List<Group> groups = [SELECT Id, DeveloperName FROM Group WHERE Id = :cs.OwnerId LIMIT 1];
                if (!groups.isEmpty()) {
                    List<DMT_Approver__c> approvers = [
                        SELECT Id, DMT_Approver_Type__c, DMT_ApproverType__r.Name
                        FROM DMT_Approver__c
                        WHERE DMT_Group__c = :groups[0].DeveloperName
                        LIMIT 1
                    ];
                    if (!approvers.isEmpty()) {
                        List<DMT_Approver_Member__c> members = [
                            SELECT Id, DMT_Access_Level__c
                            FROM DMT_Approver_Member__c
                            WHERE DMT_User__c = :UserInfo.getUserId()
                              AND DMT_Approver__c = :approvers[0].Id
                            LIMIT 2
                        ];
                        for (DMT_Approver_Member__c m : members) {
                            if (m.DMT_Access_Level__c == 'Edit') {
                                accessLevel = 'Edit';
                                break;
                            } else if (m.DMT_Access_Level__c == 'Read') {
                                accessLevel = 'Read';
                            }
                        }
                    }
                }
                data.put('accessLevel', accessLevel);
            }

            // 8. Related tasks
            List<Task> relatedTasks = [
                SELECT Id, Status, DMT_Step_Type__c, WhatId, OwnerId, Owner.Name,
                       DMT_Task_Type__r.Name
                FROM Task
                WHERE WhatId = :cs.Id
                  AND Status != 'Cancelled'
                  AND Status != 'Completed'
                  AND RecordTypeId = :rtId
                  AND Id != :t.Id
            ];
            List<Map<String, Object>> relatedTasksList = new List<Map<String, Object>>();
            for (Task rt : relatedTasks) {
                relatedTasksList.add(new Map<String, Object>{
                    'taskId' => rt.Id,
                    'taskStatus' => rt.Status != null ? rt.Status : 'Finished',
                    'stepType' => rt.DMT_Step_Type__c,
                    'WhatId' => rt.WhatId
                });
            }
            data.put('relatedTasks', relatedTasksList);

            // User permissions
            data.put('hasEditCaseRole', DMT_Utils.hasWriteAccess());
            data.put('hasLineGodAccess', DMT_Utils.checkLineGodUser());

            // Case_Tasks URL
            data.put('Case_Tasks', DMT_Utils.BaseURL() + '/lightning/n/Case_Tasks');

            return data;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> saveStep(String recordsJson) {
        try {
            Map<String, Object> records = (Map<String, Object>) JSON.deserializeUntyped(recordsJson);

            // Step 1: Persist the approver decision on the current task
            persistTaskDecision(records);

            // Step 2: Update Case Status (replaces DmtDpApprovalCase DR)
            updateCaseStatus((String) records.get('caseId'), (String) records.get('caseStatus'));

            return new Map<String, Object>();
        } catch (Exception e) {
            AuraHandledException auraEx = new AuraHandledException(e.getMessage());
            auraEx.setMessage(e.getMessage());
            throw auraEx;
        }
    }

    @AuraEnabled
    public static Map<String, Object> saveAndCloseStep(String recordsJson) {
        try {
            Map<String, Object> records = (Map<String, Object>) JSON.deserializeUntyped(recordsJson);

            // Step 1: Persist the approver decision on the current task
            persistTaskDecision(records);

            // Step 2: Update Case Status
            String caseId = (String) records.get('caseId');
            updateCaseStatus(caseId, (String) records.get('caseStatus'));

            // Step 3: Re-query fresh data for button states (replaces DR_GetCaseData)
            Map<String, Object> freshData = loadData(caseId);
            Map<String, Object> result = new Map<String, Object>();
            result.put('buttonDisabled', freshData.get('buttonDisabled'));
            result.put('returnToProposalDisabled', freshData.get('returnToProposalDisabled'));
            result.put('finishStep', freshData.get('finishStep'));
            result.put('saveCloseTask', 'TRUE');
            return result;
        } catch (Exception e) {
            AuraHandledException auraEx = new AuraHandledException(e.getMessage());
            auraEx.setMessage(e.getMessage());
            throw auraEx;
        }
    }

    @AuraEnabled
    public static Map<String, Object> finishCaseCondition(String recordId, String taskId, String recordsJson, String contextJson) {
        try {
            Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(contextJson);

            // Step 1: Save values update (errors swallowed — matches original IP behavior)
            try {
                DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(taskId, true);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'updateTaskWithStatus error (swallowed): ' + ex.getMessage());
            }

            // Step 2: Transfer content documents from case to task (non-critical)
            try {
                transferContentDocuments(recordId, taskId);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'transferContentDocuments error (swallowed): ' + ex.getMessage());
            }

            // Step 3: Approver type check (non-critical)
            try {
                DMT_CaseOwnerType_Handler.getOwnerCaseType(recordId);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'getOwnerCaseType error (swallowed): ' + ex.getMessage());
            }

            // Step 4: Update Case Status to Finished
            updateCaseStatus(recordId, 'Finished');

            // Step 5: Finish all related tasks
            finishRelatedTasks((Id) recordId);

            return new Map<String, Object>();
        } catch (Exception e) {
            String msg = e.getMessage();
            try { msg = DMT_Utils.extractFieldCustomValidationMessage(msg); } catch (Exception ex) { /* keep original */ }
            AuraHandledException auraEx = new AuraHandledException(msg);
            auraEx.setMessage(msg);
            throw auraEx;
        }
    }

    @AuraEnabled
    public static Map<String, Object> returnToProposal(String recordId, String taskId, String recordsJson, String contextJson, String statusValue) {
        try {
            Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(contextJson);

            // Step 1: Save values update (errors swallowed — matches original IP behavior)
            try {
                DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(taskId, true);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'updateTaskWithStatus error (swallowed): ' + ex.getMessage());
            }

            // Step 2: Transfer content documents from case to task (non-critical)
            try {
                transferContentDocuments(recordId, taskId);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'transferContentDocuments error (swallowed): ' + ex.getMessage());
            }

            // Step 3: Update Line/Opp to Draft
            updateLineOppToDraft(context);

            // Step 4: Approver type check (non-critical, only if not Line type)
            String dmtLineOpp = (String) context.get('DMT_LineOpportunity__c');
            if (dmtLineOpp != 'L') {
                try {
                    DMT_CaseOwnerType_Handler.getOwnerCaseType(recordId);
                } catch (Exception ex) {
                    System.debug(LoggingLevel.ERROR, 'getOwnerCaseType error (swallowed): ' + ex.getMessage());
                }
            }

            // Step 5: Update Case Status to Finished
            updateCaseStatus(recordId, 'Finished');

            // Step 6: Finish all related tasks
            finishRelatedTasks((Id) recordId);

            return new Map<String, Object>();
        } catch (Exception e) {
            String msg = e.getMessage();
            try { msg = DMT_Utils.extractFieldCustomValidationMessage(msg); } catch (Exception ex) { /* keep original */ }
            AuraHandledException auraEx = new AuraHandledException(msg);
            auraEx.setMessage(msg);
            throw auraEx;
        }
    }

    @AuraEnabled
    public static String extractValidationMessage(String errorMessage) {
        try {
            return DMT_Utils.extractFieldCustomValidationMessage(errorMessage);
        } catch (Exception e) {
            return errorMessage;
        }
    }

    // NOTE: getApproversForStep() has been eliminated.
    // Toggle 3 (approval validation) now delegates to DMT_CloseTask_Controller / DMT_TaskApprovalFlowService.
    // Kept for reference in case ApprovalTemplate needs to call it independently via service.

    // NOTE: closeTaskWithApprover() has been eliminated.
    // Toggle 3 (close task and send to approver) now delegates completely to dmt_close_task child LWC + DMT_CloseTask_Controller.
    // This change aligns with OmniStudio parent-child architecture: parent (ApprovalTemplate) renders child (CloseTask) when Toggle 3 triggered.

    // NOTE: upsertApproverTask() has been eliminated (was private helper for closeTaskWithApprover).
    // Task upsert logic now centralized in DMT_TaskCompletionService (also used by bulk closure modal).

    // CIBGLOBALD-4117: every method below this point now delegates to the single-responsibility
    // service classes shared with DMT_Massive_Task_Closure_Service (the bulk massive-closure modal),
    // instead of its own independent copy of the same logic - so an approver's decision is recorded
    // the same way regardless of which screen they used.

    private static void updateCaseStatus(String caseId, String caseStatus) {
        if (String.isBlank(caseId) || String.isBlank(caseStatus)) {
            return;
        }
        DMT_CaseClosureService.setStatus((Id) caseId, caseStatus);
    }

    private static void persistTaskDecision(Map<String, Object> records) {
        if (records == null || String.isBlank((String) records.get('taskId'))) {
            return;
        }

        DMT_TaskCompletionService.TaskCompletionRequest request =
            new DMT_TaskCompletionService.TaskCompletionRequest();
        request.taskId = (Id) records.get('taskId');
        request.caseId = (Id) records.get('caseId');
        request.stepResult = (String) records.get('stepResult');
        request.comments = (String) records.get('comments');
        request.committeeLabel = (String) records.get('Committee_Label');
        request.doNotRestart = (Boolean) records.get('doNotAskCheck');

        DMT_TaskCompletionService.completeTask(request);
    }

    // Dispatched through DMT_AsyncOrchestrator, not called inline - see DMT_DocumentTransferService's
    // header for why this one responsibility runs async regardless of caller.
    private static void transferContentDocuments(String caseId, String taskId) {
        if (String.isBlank(caseId) || String.isBlank(taskId)) {
            return;
        }
        DMT_AsyncOrchestrator.enqueue(new DMT_DocumentTransferPayload(
            new Map<Id, Id>{ (Id) caseId => (Id) taskId }
        ));
        DMT_AsyncOrchestrator.flush();
    }

    private static void finishRelatedTasks(Id caseId) {
        DMT_RelatedTaskFinisherService.finishRelatedTasks(caseId);
    }

    private static void updateLineOppToDraft(Map<String, Object> context) {
        String dmtLineOpp = (String) context.get('DMT_LineOpportunity__c');
        Id lineId = (dmtLineOpp == 'L') ? (Id) context.get('LineId') : null;
        Id oppId = (Id) context.get('OpportunityId');
        DMT_DraftStatusService.moveToDraft(lineId, oppId);
    }
}