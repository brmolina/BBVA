/**
 * @description Primary orchestrator for DMT ApprovalTemplate workflow.
 * Handles data loading, step approval, and close-task flow execution.
 * Delegates queries to DMT_ApprovalTemplate_Selector and business logic to DMT_TaskApprovalFlowService.
 * @author DMT Team | CIBGLOBALD-REFACTOR | Phase 1: Clean Orchestration
 */
public with sharing class DMT_ApprovalTemplate_Controller {

    @AuraEnabled
    public static Map<String, Object> loadData(String recordId) {
        try {
            Map<String, Object> data = new Map<String, Object>();

            // 1. Query Case using Selector
            Case caseRecord = DMT_ApprovalTemplate_Selector.getCaseWithLineAndBasics((Id) recordId);
            if (caseRecord == null) {
                return new Map<String, Object>{ 'taskId' => 'norecord' };
            }
            data.put('caseId', caseRecord.Id);
            data.put('description', caseRecord.Description);
            data.put('statusLine', caseRecord.DMT_Line__r != null ? caseRecord.DMT_Line__r.Status__c : '');
            data.put('DMT_LineOpportunity__c', caseRecord.DMT_LineOpportunity__c);
            data.put('OpportunityId', caseRecord.opportunity_id__c);
            data.put('LineId', caseRecord.DMT_Line__c);

            // 2. Get RecordType for DMT_Step_Approval using Selector
            Id rtId = DMT_ApprovalTemplate_Selector.getDmtStepApprovalRecordTypeId();
            if (rtId == null) {
                return new Map<String, Object>{ 'taskId' => 'norecord' };
            }

            // 3. Query current pending Task using Selector
            Task currentTask = DMT_ApprovalTemplate_Selector.getCurrentPendingTask((Id) recordId, rtId);
            if (currentTask == null) {
                data.put('taskId', 'norecord');
                data.put('hasEditCaseRole', DMT_Utils.hasWriteAccess());
                data.put('hasLineGodAccess', DMT_Utils.checkLineGodUser());
                return data;
            }
            data.put('taskId', currentTask.Id);
            data.put('comments', currentTask.Description != null ? currentTask.Description : '');
            data.put('stepResult', currentTask.DMT_Step_Result__c != null ? currentTask.DMT_Step_Result__c : '');
            data.put('stepType', currentTask.DMT_Step_Type__c != null ? currentTask.DMT_Step_Type__c : '');
            data.put('doNotAskCheck', currentTask.DMT_Not_Restart__c);
            data.put('Committee_Label', currentTask.DMT_Committee_Label__c);

            // Formula: buttonDisabled
            Boolean isButtonDisabled = String.isBlank(currentTask.DMT_Step_Result__c);
            data.put('buttonDisabled', isButtonDisabled);

            // 4. Query currentTaskType using Selector
            if (currentTask.DMT_Task_Type__c != null) {
                DMT_Task_Type__c currentTaskType = DMT_ApprovalTemplate_Selector.getTaskType(currentTask.DMT_Task_Type__c);
                if (currentTaskType != null) {
                    data.put('currentTaskType', currentTaskType);

                    // Formula: finishStep
                    Boolean finishStep = computeFinishStep(currentTaskType, caseRecord, currentTask, isButtonDisabled);
                    data.put('finishStep', finishStep);

                    // Formula: returnToProposalDisabled
                    Boolean returnDisabled = computeReturnToProposalDisabled(currentTaskType, caseRecord, currentTask);
                    data.put('returnToProposalDisabled', returnDisabled);

                    // 10. Query next task relationship using Selector
                    List<DMT_Task_Relationship__c> taskRelationships = DMT_ApprovalTemplate_Selector.getTaskRelationships(currentTaskType.Id);
                    System.debug('taskRelationships: ' + taskRelationships);
                    System.debug('taskRelationships size=' + taskRelationships.size());
                    if (!taskRelationships.isEmpty()) {
                        Set<Id> destinationTaskTypeIds = new Set<Id>();
                        for (DMT_Task_Relationship__c taskRelationship : taskRelationships) {
                            System.debug('Default candidate: ' + taskRelationship.Id + ' toTask=' + taskRelationship.DMT_To_Task_Type__c + ' created=' + taskRelationship.CreatedDate);
                            if (taskRelationship.DMT_To_Task_Type__c != null) {
                                destinationTaskTypeIds.add(taskRelationship.DMT_To_Task_Type__c);
                            }
                        }
                        if (!destinationTaskTypeIds.isEmpty()) {
                            Map<Id, DMT_Task_Type__c> destinationTaskTypeById = new Map<Id, DMT_Task_Type__c>(
                                DMT_ApprovalTemplate_Selector.getTaskTypesByIds(destinationTaskTypeIds)
                            );
                            List<Map<String, Object>> destinationTaskOptions = new List<Map<String, Object>>();
                            Set<Id> seenDestinationTaskTypeIds = new Set<Id>();
                            for (DMT_Task_Relationship__c taskRelationship : taskRelationships) {
                                Id destinationTaskTypeId = taskRelationship.DMT_To_Task_Type__c;
                                if (destinationTaskTypeId == null || seenDestinationTaskTypeIds.contains(destinationTaskTypeId)) {
                                    continue;
                                }

                                DMT_Task_Type__c destinationTaskType = destinationTaskTypeById.get(destinationTaskTypeId);
                                if (destinationTaskType != null && destinationTaskType.DMT_External_Id__c != null) {
                                    seenDestinationTaskTypeIds.add(destinationTaskTypeId);
                                    destinationTaskOptions.add(new Map<String, Object>{
                                        'label' => destinationTaskType.Name,
                                        'value' => destinationTaskType.DMT_External_Id__c,
                                        'orderNumber' => taskRelationship.DMT_Order_Number__c
                                    });
                                }
                            }
                            if (!destinationTaskOptions.isEmpty()) {
                                data.put('toTask', destinationTaskOptions);
                            }
                        }
                    }

                    // Build validations list using Selector - deduplicated by value
                    List<Map<String, Object>> validations = buildValidationsList(currentTaskType, taskRelationships, caseRecord, rtId, currentTask.Id);
                    data.put('validations', validations);

                    // Proposal validations: filter where DMT_ApprovalEdit__c == false
                    List<Map<String, Object>> propValidations = new List<Map<String, Object>>();
                    for (Map<String, Object> validationOption : validations) {
                        if (validationOption.get('DMT_ApprovalEdit__c') != true) {
                            propValidations.add(validationOption);
                        }
                    }
                    data.put('proposalValidations', propValidations);
                }
            }

            // 5-7. Query approver access for current user using Selector
            resolveAccessLevel(caseRecord, data);

            // 8. Related tasks using Selector
            List<Task> relatedTasks = DMT_ApprovalTemplate_Selector.getRelatedTasksForCase((Id) recordId, rtId, currentTask.Id);
            List<Map<String, Object>> relatedTasksList = new List<Map<String, Object>>();
            for (Task relatedTask : relatedTasks) {
                relatedTasksList.add(new Map<String, Object>{
                    'taskId' => relatedTask.Id,
                    'taskStatus' => relatedTask.Status != null ? relatedTask.Status : 'Finished',
                    'stepType' => relatedTask.DMT_Step_Type__c,
                    'WhatId' => relatedTask.WhatId
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
            AuraHandledException auraException = new AuraHandledException(e.getMessage());
            auraException.setMessage(e.getMessage());
            throw auraException;
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
            AuraHandledException auraException = new AuraHandledException(e.getMessage());
            auraException.setMessage(e.getMessage());
            throw auraException;
        }
    }

    @AuraEnabled
    public static Map<String, Object> finishCaseCondition(String recordId, String taskId, String recordsJson, String contextJson) {
        try {
            Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(contextJson);

            // Step 1: Save values update (errors swallowed — matches original IP behavior)
            try {
                DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(taskId, true);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'updateTaskWithStatus error (swallowed): ' + e.getMessage());
            }

            // Step 2: Transfer content documents from case to task (non-critical)
            try {
                transferContentDocuments(recordId, taskId);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'transferContentDocuments error (swallowed): ' + e.getMessage());
            }

            // Step 3: Approver type check (non-critical)
            try {
                DMT_CaseOwnerType_Handler.getOwnerCaseType(recordId);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'getOwnerCaseType error (swallowed): ' + e.getMessage());
            }

            // Step 4: Update Case Status to Finished
            updateCaseStatus(recordId, 'Finished');

            // Step 5: Finish all related tasks
            finishRelatedTasks((Id) recordId);

            return new Map<String, Object>();
        } catch (Exception e) {
            String msg = e.getMessage();
            try { msg = DMT_Utils.extractFieldCustomValidationMessage(msg); } catch (Exception ignoredException) { /* keep original */ }
            AuraHandledException auraException = new AuraHandledException(msg);
            auraException.setMessage(msg);
            throw auraException;
        }
    }

    @AuraEnabled
    public static Map<String, Object> returnToProposal(String recordId, String taskId, String recordsJson, String contextJson, String statusValue) {
        try {
            Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(contextJson);

            // Step 1: Save values update (errors swallowed — matches original IP behavior)
            try {
                DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(taskId, true);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'updateTaskWithStatus error (swallowed): ' + e.getMessage());
            }

            // Step 2: Transfer content documents from case to task (non-critical)
            try {
                transferContentDocuments(recordId, taskId);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'transferContentDocuments error (swallowed): ' + e.getMessage());
            }

            // Step 3: Update Line/Opp to the return status
            updateReturnStatus(context, statusValue);

            // Clear the decision before closing the Case (4370).
            Database.update(
                new Task(Id = (Id) taskId, DMT_Step_Result__c = null),
                AccessLevel.SYSTEM_MODE
            );

            // Step 5: Update Case Status to Finished
            updateCaseStatus(recordId, 'Finished');

            // Step 6: Finish all related tasks
            finishRelatedTasks((Id) recordId);

            return new Map<String, Object>();
        } catch (Exception e) {
            String msg = e.getMessage();
            try { msg = DMT_Utils.extractFieldCustomValidationMessage(msg); } catch (Exception ignoredException) { /* keep original */ }
            AuraHandledException auraException = new AuraHandledException(msg);
            auraException.setMessage(msg);
            throw auraException;
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

    // NOTE: the legacy getApproversForStep(), closeTaskWithApprover(), and upsertApproverTask()
    // helpers were removed from this controller during the refactor.
    // Toggle 3 now flows through the parent ApprovalTemplate controller methods below,
    // the dmt_close_task child LWC, and DMT_TaskApprovalFlowService.
    // Task completion and task creation remain centralized in DMT_TaskCompletionService.

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

    private static void updateReturnStatus(Map<String, Object> context, String statusValue) {
        Boolean isLineProposal = statusValue == 'Proposal'
            && (String) context.get('DMT_LineOpportunity__c') == 'L'
            && context.get('LineId') != null;
        if (!isLineProposal) {
            updateLineOppToDraft(context);
            return;
        }
        Id lineId = (Id) context.get('LineId');
        DMT_DmlUtils.updateMany(new List<SObject>{ new DMT_Line__c(Id = lineId, Status__c = 'Proposal', Allowed__c = true) }, 'returnToProposal');
        DMT_DmlUtils.updateMany(new List<SObject>{ new DMT_Line__c(Id = lineId, Allowed__c = false) }, 'resetReturnToProposalAllowed');
    }

    private static void updateLineOppToDraft(Map<String, Object> context) {
        String dmtLineOpp = (String) context.get('DMT_LineOpportunity__c');
        Id lineId = (dmtLineOpp == 'L') ? (Id) context.get('LineId') : null;
        Id oppId = (Id) context.get('OpportunityId');
        DMT_DraftStatusService.moveToDraft(lineId, oppId);
    }

    // ====== NEW PUBLIC METHODS (Absorbed from DMT_CloseTask_Controller) ======

    /**
     * @description Gets initial data for Close Task modal.
     * Delegates to DMT_TaskApprovalFlowService for business logic.
     */
    @AuraEnabled(cacheable=true)
    public static CloseTaskInitDTO getCloseTaskInitialData(Id recordId) {
        if (recordId == null) {
            AuraHandledException ex = new AuraHandledException('recordId is required.');
            ex.setMessage('recordId is required.');
            throw ex;
        }
        DMT_TaskApprovalFlowService.CloseTaskContextDTO serviceResult = 
            DMT_TaskApprovalFlowService.getCloseTaskContext(recordId);
        return mapContextDTOToInitDTO(serviceResult);
    }

    /**
     * @description Gets approvers for selected step.
     * Delegates to DMT_TaskApprovalFlowService for business logic.
     */
    @AuraEnabled(cacheable=true)
    public static TaskSelectionDTO getCloseTaskApprovers(Id recordId, String stepSelected) {
        if (recordId == null) {
            AuraHandledException ex = new AuraHandledException('recordId is required.');
            ex.setMessage('recordId is required.');
            throw ex;
        }
        if (String.isBlank(stepSelected)) {
            AuraHandledException ex = new AuraHandledException('stepSelected is required.');
            ex.setMessage('stepSelected is required.');
            throw ex;
        }
        DMT_TaskApprovalFlowService.TaskApproverSelectionDTO serviceResult = 
            DMT_TaskApprovalFlowService.getApproversForStep(recordId, stepSelected);
        return mapApproverSelectionDTOToTaskSelectionDTO(serviceResult);
    }

    /**
     * @description Executes close task flow.
     * Delegates to DMT_TaskApprovalFlowService for business logic.
     */
    @AuraEnabled
    public static CloseTaskResult executeCloseTask(Id caseId, Id currentTaskId, String stepSelected, String approverSelected) {
        DMT_TaskApprovalFlowService.CloseTaskResultDTO serviceResult = 
            DMT_TaskApprovalFlowService.executeCloseTaskFlow(
                caseId,
                currentTaskId,
                stepSelected,
                approverSelected
            );
        return mapCloseTaskResultDTO(serviceResult);
    }

    private static Boolean computeFinishStep(DMT_Task_Type__c currentTaskType, Case caseRecord, Task currentTask, Boolean isButtonDisabled) {
        Boolean finishStep = true;
        if (caseRecord.DMT_Closing_Tasks__c != null) {
            try {
                List<Object> closingTasks = (List<Object>) JSON.deserializeUntyped(caseRecord.DMT_Closing_Tasks__c);
                Integer totalClosing = closingTasks.size();
                Integer filtered = 0;
                for (Object closingTaskEntry : closingTasks) {
                    Map<String, Object> closingTaskMap = (Map<String, Object>) closingTaskEntry;
                    if (String.valueOf(closingTaskMap.get('id')) != currentTaskType.DMT_External_Id__c) {
                        filtered++;
                    }
                }
                if ((filtered != totalClosing || filtered == 0 || currentTask.DMT_Step_Result__c == 'No') && !isButtonDisabled) {
                    finishStep = false;
                }
            } catch (Exception ex) {
                finishStep = true;
            }
        } else if (!isButtonDisabled) {
            finishStep = false;
        }
        return finishStep;
    }

    private static Boolean computeReturnToProposalDisabled(DMT_Task_Type__c currentTaskType, Case caseRecord, Task currentTask) {
        Boolean returnDisabled = true;
        if (caseRecord.DMT_LineOpportunity__c == 'L') {
            returnDisabled = (caseRecord.DMT_Passport_Sanction__c != 'approval'
                || currentTaskType.gf_task_ind_type__c != true);
        }
        return returnDisabled;
    }

    private static List<Map<String, Object>> buildValidationsList(DMT_Task_Type__c currentTaskType,
            List<DMT_Task_Relationship__c> taskRelationships, Case caseRecord, Id recordTypeId, Id currentTaskId) {
        Set<String> seenValues = new Set<String>();
        List<Map<String, Object>> validations = new List<Map<String, Object>>();

        // 1. Add toTask entries (destination task types from relationships)
        if (!taskRelationships.isEmpty()) {
            List<Id> destinationTaskTypeIds = new List<Id>();
            Set<Id> seenDestinationTaskTypeIds = new Set<Id>();
            for (DMT_Task_Relationship__c taskRelationship : taskRelationships) {
                if (taskRelationship.DMT_To_Task_Type__c != null && !seenDestinationTaskTypeIds.contains(taskRelationship.DMT_To_Task_Type__c)) {
                    seenDestinationTaskTypeIds.add(taskRelationship.DMT_To_Task_Type__c);
                    destinationTaskTypeIds.add(taskRelationship.DMT_To_Task_Type__c);
                }
            }
            if (!destinationTaskTypeIds.isEmpty()) {
                Map<Id, DMT_Task_Type__c> destinationTaskTypeById = new Map<Id, DMT_Task_Type__c>(
                    DMT_ApprovalTemplate_Selector.getTaskTypesByIds(new Set<Id>(destinationTaskTypeIds))
                );
                for (Id destinationTaskTypeId : destinationTaskTypeIds) {
                    DMT_Task_Type__c destinationTaskType = destinationTaskTypeById.get(destinationTaskTypeId);
                    if (destinationTaskType != null && destinationTaskType.DMT_External_Id__c != null && !seenValues.contains(destinationTaskType.DMT_External_Id__c)) {
                        seenValues.add(destinationTaskType.DMT_External_Id__c);
                        validations.add(new Map<String, Object>{
                            'label' => destinationTaskType.Name,
                            'value' => destinationTaskType.DMT_External_Id__c,
                            'DMT_ApprovalEdit__c' => destinationTaskType.DMT_ApprovalEdit__c
                        });
                    }
                }
            }
        }

        // 2. Add related tasks' task types
        List<Task> relatedTasks = DMT_ApprovalTemplate_Selector.getRelatedTasksForValidation(caseRecord.Id, recordTypeId, currentTaskId);
        List<Id> relatedTaskTypeIds = new List<Id>();
        Set<Id> seenRelatedTaskTypeIds = new Set<Id>();
        for (Task relatedTask : relatedTasks) {
            if (relatedTask.DMT_Task_Type__c != null && !seenRelatedTaskTypeIds.contains(relatedTask.DMT_Task_Type__c)) {
                seenRelatedTaskTypeIds.add(relatedTask.DMT_Task_Type__c);
                relatedTaskTypeIds.add(relatedTask.DMT_Task_Type__c);
            }
        }
        if (!relatedTaskTypeIds.isEmpty()) {
            Map<Id, DMT_Task_Type__c> relatedTaskTypeById = new Map<Id, DMT_Task_Type__c>(
                DMT_ApprovalTemplate_Selector.getTaskTypesByIds(new Set<Id>(relatedTaskTypeIds))
            );
            for (Id relatedTaskTypeId : relatedTaskTypeIds) {
                DMT_Task_Type__c relatedTaskType = relatedTaskTypeById.get(relatedTaskTypeId);
                if (relatedTaskType != null && relatedTaskType.DMT_External_Id__c != null && !seenValues.contains(relatedTaskType.DMT_External_Id__c)) {
                    seenValues.add(relatedTaskType.DMT_External_Id__c);
                    validations.add(new Map<String, Object>{
                        'label' => relatedTaskType.Name,
                        'value' => relatedTaskType.DMT_External_Id__c,
                        'DMT_ApprovalEdit__c' => relatedTaskType.DMT_ApprovalEdit__c
                    });
                }
            }
        }

        // 3. Add current task type
        if (currentTaskType.DMT_External_Id__c != null && !seenValues.contains(currentTaskType.DMT_External_Id__c)) {
            seenValues.add(currentTaskType.DMT_External_Id__c);
            validations.add(new Map<String, Object>{
                'label' => currentTaskType.Name,
                'value' => currentTaskType.DMT_External_Id__c,
                'DMT_ApprovalEdit__c' => currentTaskType.DMT_ApprovalEdit__c
            });
        }

        return validations;
    }

    // CIBGLOBALD-4117: every method below this point now delegates to the single-responsibility
    // service classes shared with DMT_Massive_Task_Closure_Service (the bulk massive-closure modal),
    // instead of its own independent copy of the same logic - so an approver's decision is recorded
    // the same way regardless of which screen they used.

    private static void resolveAccessLevel(Case caseRecord, Map<String, Object> data) {
        if (caseRecord.OwnerId == null) {
            data.put('accessLevel', '');
            return;
        }

        String accessLevel = '';
        Group ownerGroup = DMT_ApprovalTemplate_Selector.getGroupByOwnerId(caseRecord.OwnerId);
        if (ownerGroup != null) {
            List<DMT_Approver_Member__c> members = DMT_ApprovalTemplate_Selector.getApproverMembersByGroupAndUser(
                ownerGroup.DeveloperName,
                UserInfo.getUserId()
            );
            for (DMT_Approver_Member__c member : members) {
                if (member.DMT_Access_Level__c == 'Edit') {
                    accessLevel = 'Edit';
                    break;
                }
                if (member.DMT_Access_Level__c == 'Read') {
                    accessLevel = 'Read';
                }
            }
        }

        data.put('accessLevel', accessLevel);
    }

    private static CloseTaskInitDTO mapContextDTOToInitDTO(DMT_TaskApprovalFlowService.CloseTaskContextDTO serviceDTO) {
        CloseTaskInitDTO result = new CloseTaskInitDTO();
        result.caseId = serviceDTO.caseId;
        result.taskId = serviceDTO.taskId;
        result.taskName = serviceDTO.taskName;
        result.stepResult = serviceDTO.stepResult;
        result.comments = serviceDTO.comments;
        result.currentTaskTypeId = serviceDTO.currentTaskTypeId;
        result.currentTaskExternalId = serviceDTO.currentTaskExternalId;
        result.defaultStepSelected = serviceDTO.defaultStepSelected;
        result.defaultTaskTypeId = serviceDTO.defaultTaskTypeId;
        result.defaultRelationshipId = serviceDTO.defaultRelationshipId;
        result.accessLevel = serviceDTO.accessLevel;
        result.buttonDisabled = serviceDTO.buttonDisabled;
        result.hasRelatedApprovalTask = serviceDTO.hasRelatedApprovalTask;
        result.lineStatus = serviceDTO.lineStatus;
        result.lineOpportunityType = serviceDTO.lineOpportunityType;
        result.username = serviceDTO.username;

        result.validations = new List<TaskOptionDTO>();
        if (serviceDTO.validations != null) {
            for (DMT_TaskApprovalFlowService.TaskOptionDTO serviceOption : serviceDTO.validations) {
                TaskOptionDTO legacyOption = new TaskOptionDTO();
                legacyOption.id = serviceOption.id;
                legacyOption.value = serviceOption.value;
                legacyOption.label = serviceOption.label;
                legacyOption.isDefault = serviceOption.isDefault;
                legacyOption.approvalEdit = serviceOption.approvalEdit;
                legacyOption.approverField = serviceOption.approverField;
                result.validations.add(legacyOption);
            }
        }

        return result;
    }

    private static TaskSelectionDTO mapApproverSelectionDTOToTaskSelectionDTO(DMT_TaskApprovalFlowService.TaskApproverSelectionDTO serviceDTO) {
        TaskSelectionDTO result = new TaskSelectionDTO();
        result.taskTypeId = serviceDTO.taskTypeId;
        result.taskTypeName = serviceDTO.taskTypeName;
        result.externalId = serviceDTO.externalId;
        result.approverField = serviceDTO.approverField;
        result.approvalEdit = serviceDTO.approvalEdit;
        result.defaultApproverCode = serviceDTO.defaultApproverCode;
        result.showApprovers = serviceDTO.showApprovers;

        result.approvers = new List<ApproverOptionDTO>();
        if (serviceDTO.approvers != null) {
            for (DMT_TaskApprovalFlowService.ApproverOptionDTO serviceApprover : serviceDTO.approvers) {
                ApproverOptionDTO legacyApprover = new ApproverOptionDTO();
                legacyApprover.id = serviceApprover.id;
                legacyApprover.label = serviceApprover.label;
                legacyApprover.value = serviceApprover.value;
                legacyApprover.approverCode = serviceApprover.approverCode;
                legacyApprover.approverType = serviceApprover.approverType;
                result.approvers.add(legacyApprover);
            }
        }

        return result;
    }

    private static CloseTaskResult mapCloseTaskResultDTO(DMT_TaskApprovalFlowService.CloseTaskResultDTO serviceDTO) {
        CloseTaskResult result = new CloseTaskResult();
        result.success = serviceDTO.success;
        result.newTaskId = serviceDTO.newTaskId;
        result.message = serviceDTO.message;
        return result;
    }
        // ====== Helper Classes (DTOs) ======

    public class CloseTaskInitDTO {
        @AuraEnabled public Id caseId;
        @AuraEnabled public Id taskId;
        @AuraEnabled public String taskName;
        @AuraEnabled public String stepResult;
        @AuraEnabled public String comments;
        @AuraEnabled public String currentTaskTypeId;
        @AuraEnabled public String currentTaskExternalId;
        @AuraEnabled public String defaultStepSelected;
        @AuraEnabled public Id defaultTaskTypeId;
        @AuraEnabled public Id defaultRelationshipId;
        @AuraEnabled public List<TaskOptionDTO> validations;
        @AuraEnabled public String accessLevel;
        @AuraEnabled public Boolean buttonDisabled;
        @AuraEnabled public Boolean hasRelatedApprovalTask;
        @AuraEnabled public String lineStatus;
        @AuraEnabled public String lineOpportunityType;
        @AuraEnabled public String username;
    }

    public class TaskOptionDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean isDefault;
        @AuraEnabled public Boolean approvalEdit;
        @AuraEnabled public String approverField;
    }

    public class TaskSelectionDTO {
        @AuraEnabled public Id taskTypeId;
        @AuraEnabled public String taskTypeName;
        @AuraEnabled public String externalId;
        @AuraEnabled public String approverField;
        @AuraEnabled public Boolean approvalEdit;
        @AuraEnabled public List<ApproverOptionDTO> approvers;
        @AuraEnabled public String defaultApproverCode;
        @AuraEnabled public Boolean showApprovers;
    }

    public class ApproverOptionDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String approverCode;
        @AuraEnabled public String approverType;
    }

    public class CloseTaskResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Id newTaskId;
        @AuraEnabled public String message;
    }
    // ====== Private Helper Methods ======
}