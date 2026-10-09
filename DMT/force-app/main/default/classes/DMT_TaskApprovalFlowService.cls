/**
 * @description Servicio centralizado para la lógica de cierre de task y selección de approver.
 * Reutilizado por Close Task LWC y ApprovalTemplate Controller.
 * Reemplaza duplicación de lógica entre DMT_CloseTask_Controller y DMT_ApprovalTemplate_Controller.
 * @author DMT Team | Centralización Toggle 3
 */
public with sharing class DMT_TaskApprovalFlowService {

    /**
     * @description Obtiene contexto completo para el flujo de cierre de task.
     * Lógica extraída de DMT_CloseTask_Controller.getInitialData().
     * @param recordId Case identifier usado como entry point
     * @return DTO con contexto completo para cargar UI de cierre
     */
    @AuraEnabled(cacheable=true)
    public static CloseTaskContextDTO getCloseTaskContext(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('recordId is required.');
        }

        CloseTaskContextDTO response = new CloseTaskContextDTO();

        // CASE + CURRENT TASK
        Case caseRecord = DMT_ApprovalTemplate_Selector.getCaseWithCurrentTask(recordId);
        if (caseRecord == null) {
            throw new AuraHandledException('Case not found.');
        }

        response.caseId = caseRecord.Id;
        response.lineStatus = caseRecord.DMT_Line__r != null ? caseRecord.DMT_Line__r.Status__c : null;
        response.lineOpportunityType = caseRecord.DMT_LineOpportunity__c;
        response.username = UserInfo.getUserName();

        Task currentTask = caseRecord.Tasks.isEmpty() ? null : caseRecord.Tasks[0];
        if (currentTask == null) {
            throw new AuraHandledException('No active Task found.');
        }

        response.taskId = currentTask.Id;
        response.stepResult = currentTask.DMT_Step_Result__c;
        response.comments = currentTask.Description;
        response.buttonDisabled = String.isBlank(currentTask.DMT_Step_Result__c);

        // CURRENT TASK TYPE
        DMT_Task_Type__c currentTaskType = DMT_ApprovalTemplate_Selector.getTaskType(currentTask.DMT_Task_Type__c);
        if (currentTaskType == null) {
            throw new AuraHandledException('Current Task Type not found.');
        }

        response.currentTaskTypeId = currentTaskType.Id;
        response.currentTaskExternalId = currentTaskType.DMT_External_Id__c;
        response.taskName = currentTaskType.Name;

        // TASK RELATIONSHIPS
        List<DMT_Task_Relationship__c> relationships = DMT_ApprovalTemplate_Selector.getTaskRelationships(currentTaskType.Id);

        // DEFAULT RELATIONSHIP
        DMT_Task_Relationship__c defaultRelationship = resolveDefaultRelationship(relationships);

        if (defaultRelationship != null) {
            response.defaultRelationshipId = defaultRelationship.Id;
            response.defaultTaskTypeId = defaultRelationship.DMT_To_Task_Type__c;
        }

        // TASK TYPE IDs
        Set<Id> nextTaskTypeIds = new Set<Id>();

        for (DMT_Task_Relationship__c relationship : relationships) {
            if (relationship.DMT_To_Task_Type__c != null) {
                nextTaskTypeIds.add(relationship.DMT_To_Task_Type__c);
            }
        }

        // NEXT TASK TYPES
        List<DMT_Task_Type__c> nextTaskTypes = DMT_ApprovalTemplate_Selector.getTaskTypesByIds(nextTaskTypeIds);
        Map<Id, DMT_Task_Type__c> taskTypeById = new Map<Id, DMT_Task_Type__c>(nextTaskTypes);

        // OPTIONS
        response.validations = new List<TaskOptionDTO>();
        Set<Id> processedTaskTypes = new Set<Id>();

        for (DMT_Task_Relationship__c relationship : relationships) {
            Id targetId = relationship.DMT_To_Task_Type__c;

            if (targetId == null || processedTaskTypes.contains(targetId)) {
                continue;
            }

            DMT_Task_Type__c taskType = taskTypeById.get(targetId);

            if (taskType == null) {
                continue;
            }

            TaskOptionDTO option = buildTaskOption(taskType, targetId == response.defaultTaskTypeId);
            response.validations.add(option);
            processedTaskTypes.add(targetId);
        }

        // DEFAULT STEP SELECTED
        if (response.defaultTaskTypeId != null && taskTypeById.containsKey(response.defaultTaskTypeId)) {
            response.defaultStepSelected = taskTypeById.get(response.defaultTaskTypeId).DMT_External_Id__c;
        }

        // ACCESS LEVEL
        response.accessLevel = resolveAccessLevel(caseRecord);

        // RELATED APPROVAL TASK
        response.hasRelatedApprovalTask = hasRelatedApprovalTask(caseRecord, currentTask);

        return response;
    }

    /**
     * @description Obtiene approvers para un step seleccionado.
     * Lógica extraída de DMT_CloseTask_Controller.getTaskSelectionData().
     * @param recordId Case identifier para resolver contexto actual
     * @param stepSelected External identifier del task type seleccionado
     * @return DTO con approvers y configuración de visibilidad
     */
    @AuraEnabled(cacheable=true)
    public static TaskApproverSelectionDTO getApproversForStep(Id recordId, String stepSelected) {
        if (recordId == null) {
            throw new AuraHandledException('recordId is required.');
        }

        if (String.isBlank(stepSelected)) {
            throw new AuraHandledException('stepSelected is required.');
        }

        // SELECTED TASK TYPE
        DMT_Task_Type__c selectedTaskType = DMT_ApprovalTemplate_Selector.getTaskTypeByExternalId(stepSelected);

        if (selectedTaskType == null) {
            throw new AuraHandledException('Selected Task Type not found.');
        }

        TaskApproverSelectionDTO response = new TaskApproverSelectionDTO();
        response.taskTypeId = selectedTaskType.Id;
        response.taskTypeName = selectedTaskType.Name;
        response.externalId = selectedTaskType.DMT_External_Id__c;
        response.approverField = selectedTaskType.DMT_Approver_Field__c;
        response.approvalEdit = selectedTaskType.DMT_ApprovalEdit__c;

        // APPROVERS
        List<DMT_Approver__c> approvers = DMT_ApprovalTemplate_Selector.getApproversForTaskType(selectedTaskType.Id);

        response.approvers = new List<ApproverOptionDTO>();

        for (DMT_Approver__c approver : approvers) {
            ApproverOptionDTO option = new ApproverOptionDTO();
            option.id = approver.Id;
            option.label = approver.Name;
            option.value = approver.DMT_External_Id__c;
            option.approverCode = approver.DMT_Approver_Code__c;
            option.approverType = approver.DMT_Approver_Type__c;

            response.approvers.add(option);
        }

        // DEFAULT APPROVER
        Case caseRecord = DMT_ApprovalTemplate_Selector.getCaseWithCurrentTask(recordId);
        response.defaultApproverCode = resolveDefaultApprover(caseRecord, selectedTaskType);
        Task currentTask = (caseRecord != null && !caseRecord.Tasks.isEmpty()) ? caseRecord.Tasks[0] : null;
        Boolean relatedTaskExists = hasRelatedApprovalTask(caseRecord, currentTask);
        response.showApprovers = !(relatedTaskExists && selectedTaskType.DMT_ApprovalEdit__c == true && caseRecord.DMT_Line__r != null && caseRecord.DMT_Line__r.Status__c == 'Approval' );

        return response;
    }

    /**
     * @description Ejecuta el flujo completo de cierre de task:
     * 1. Snapshots current task status
     * 2. Completes current task
     * 3. Resolves approver group
     * 4. Creates next approval task
     * 5. Snapshots new task status
     * 6. Moves case to next owner
     * Lógica extraída de DMT_CloseTask_Controller.closeTask().
     * @param caseId Related case identifier
     * @param currentTaskId Current task identifier
     * @param stepSelected External identifier del task type seleccionado
     * @param approverSelected External identifier del approver seleccionado
     * @return DTO con resultado y new task id
     */
    @AuraEnabled
    public static CloseTaskResultDTO executeCloseTaskFlow(
        Id caseId,
        Id currentTaskId,
        String stepSelected,
        String approverSelected
    ) {
        validateCloseTaskRequest(caseId, currentTaskId, stepSelected, approverSelected);

        Savepoint savepointToken = Database.setSavepoint();

        try {
            // STEP 1: UpdateValuesToTask
            updateValuesToTask(currentTaskId);

            // STEP 2: CompleteCurrentTask
            completeCurrentTask(currentTaskId);

            // APPROVER + GROUP (resolved once and reused)
            Group ownerGroup = resolveApproverGroup(approverSelected);

            // STEP 3: CreateNewTask
            Id newTaskId = createNewTask(caseId, ownerGroup, stepSelected);

            // STEP 4: UpdateNewTaskStatus
            updateNewTaskStatus(newTaskId);

            // STEP 5: UpdateCaseOwner
            updateCaseOwner(caseId, ownerGroup);

            CloseTaskResultDTO result = new CloseTaskResultDTO();
            result.success = true;
            result.newTaskId = newTaskId;
            result.message = 'Close Task executed successfully.';

            return result;

        } catch (Exception e) {
            Database.rollback(savepointToken);
            throw new AuraHandledException('Error executing Close Task: ' + e.getMessage());
        }
    }

    // ====== Private Helper Methods ======

    /**
     * @description Snapshots current task status before close
     */
    private static void updateValuesToTask(Id currentTaskId) {
        if (currentTaskId == null) {
            throw new AuraHandledException('currentTaskId is required.');
        }
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(String.valueOf(currentTaskId), true);
    }

    /**
     * @description Marks current task as Completed
     */
    private static void completeCurrentTask(Id taskId) {
        if (taskId == null) {
            throw new AuraHandledException('currentTaskId is required.');
        }

        DMT_TaskCompletionService.TaskCompletionRequest request =
            new DMT_TaskCompletionService.TaskCompletionRequest();
        request.taskId = taskId;
        request.status = 'Completed';

        DMT_TaskCompletionService.completeTask(request);
    }

    /**
     * @description Resolves owner Group for approver, validating existence and Group link
     */
    private static Group resolveApproverGroup(String approverExternalId) {
        DMT_Approver__c approver = DMT_ApprovalTemplate_Selector.getApproverByExternalId(approverExternalId);

        if (approver == null) {
            throw new AuraHandledException('Approver not found: ' + approverExternalId);
        }

        if (String.isBlank(approver.DMT_Group__c)) {
            throw new AuraHandledException('Approver does not have DMT_Group__c.');
        }

        Group ownerGroup = DMT_ApprovalTemplate_Selector.getGroupByDeveloperName(approver.DMT_Group__c);

        if (ownerGroup == null) {
            throw new AuraHandledException('Group not found: ' + approver.DMT_Group__c);
        }

        return ownerGroup;
    }

    /**
     * @description Creates next approval Task for selected step and approver
     */
    private static Id createNewTask(Id caseId, Group ownerGroup, String stepSelected) {
        DMT_Task_Type__c taskType = DMT_ApprovalTemplate_Selector.getTaskTypeByExternalId(stepSelected);

        if (taskType == null) {
            throw new AuraHandledException('Task Type not found: ' + stepSelected);
        }

        Schema.RecordTypeInfo recordTypeInfo = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval');

        if (recordTypeInfo == null) {
            throw new AuraHandledException('Record Type DMT_Step_Approval does not exist.');
        }

        DMT_TaskCompletionService.TaskCompletionRequest request =
            new DMT_TaskCompletionService.TaskCompletionRequest();
        request.recordTypeId = recordTypeInfo.getRecordTypeId();
        request.subject = 'Task';
        request.caseId = caseId;
        request.status = 'Not Started';
        request.ownerId = ownerGroup.Id;
        request.taskTypeId = taskType.Id;

        DMT_TaskCompletionService.completeTask(request);

        List<Task> createdTasks = [
            SELECT Id
            FROM Task
            WHERE WhatId = :caseId
              AND OwnerId = :ownerGroup.Id
              AND RecordTypeId = :recordTypeInfo.getRecordTypeId()
              AND DMT_Task_Type__c = :taskType.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (createdTasks.isEmpty()) {
            throw new AuraHandledException('Created Task could not be resolved after insert.');
        }

        return createdTasks[0].Id;
    }

    /**
     * @description Snapshots new task status
     */
    private static void updateNewTaskStatus(Id newTaskId) {
        if (newTaskId == null) {
            throw new AuraHandledException('Task Id is required.');
        }
        DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(String.valueOf(newTaskId), false);
    }

    /**
     * @description Moves Case to next approver's owner group
     */
    private static void updateCaseOwner(Id caseId, Group ownerGroup) {
        update new Case(Id = caseId, Status = 'Pending', OwnerId = ownerGroup.Id);
    }

    /**
     * @description Validates close-task request payload before execution
     */
    private static void validateCloseTaskRequest(Id caseId, Id currentTaskId, String stepSelected, String approverSelected) {
        if (caseId == null) {
            throw new AuraHandledException('Case Id is required.');
        }

        if (currentTaskId == null) {
            throw new AuraHandledException('Current Task Id is required.');
        }

        if (String.isBlank(stepSelected)) {
            throw new AuraHandledException('You must select a Task.');
        }

        if (String.isBlank(approverSelected)) {
            throw new AuraHandledException('You must select an Approver.');
        }
    }

    /**
     * @description Builds combobox option for task type
     */
    private static TaskOptionDTO buildTaskOption(DMT_Task_Type__c taskType, Boolean isDefault) {
        TaskOptionDTO option = new TaskOptionDTO();
        option.id = taskType.Id;
        option.label = taskType.Name;
        option.value = taskType.DMT_External_Id__c;
        option.isDefault = isDefault;
        option.approvalEdit = taskType.DMT_ApprovalEdit__c;
        option.approverField = taskType.DMT_Approver_Field__c;
        return option;
    }

    /**
     * @description Resolves default relationship using lowest order number and latest creation date as tiebreaker
     */
    private static DMT_Task_Relationship__c resolveDefaultRelationship(List<DMT_Task_Relationship__c> relationships) {
        if (relationships == null || relationships.isEmpty()) {
            return null;
        }

        DMT_Task_Relationship__c defaultRelationship = relationships[0];

        for (DMT_Task_Relationship__c relationship : relationships) {
            if (relationship == null || relationship.DMT_Order_Number__c == null) {
                continue;
            }

            if (defaultRelationship == null || defaultRelationship.DMT_Order_Number__c == null) {
                defaultRelationship = relationship;
                continue;
            }

            if (relationship.DMT_Order_Number__c < defaultRelationship.DMT_Order_Number__c) {
                defaultRelationship = relationship;
                continue;
            }

            if (
                relationship.DMT_Order_Number__c == defaultRelationship.DMT_Order_Number__c &&
                relationship.CreatedDate > defaultRelationship.CreatedDate
            ) {
                defaultRelationship = relationship;
            }
        }

        return defaultRelationship;
    }

    /**
     * @description Resolves current user's access level for case owner group
     */
    private static String resolveAccessLevel(Case caseRecord) {
        Group ownerGroup = DMT_ApprovalTemplate_Selector.getGroupByOwnerId(caseRecord.OwnerId);

        if (ownerGroup == null) {
            return '';
        }

        List<DMT_Approver_Member__c> members = DMT_ApprovalTemplate_Selector.getApproverMembersByGroupAndUser(
            ownerGroup.DeveloperName,
            UserInfo.getUserId()
        );

        String result = '';

        for (DMT_Approver_Member__c member : members) {
            if (member.DMT_Access_Level__c == 'Edit') {
                return 'Edit';
            }

            if (member.DMT_Access_Level__c == 'Read') {
                result = 'Read';
            }
        }

        return result;
    }

    /**
     * @description Determines whether there is another open approval task for the same line
     */
    private static Boolean hasRelatedApprovalTask(Case caseRecord, Task currentTask) {
        if (caseRecord == null || caseRecord.DMT_Line__c == null) {
            return false;
        }

        List<Case> relatedCases = DMT_ApprovalTemplate_Selector.getOpenCasesByLine(caseRecord.DMT_Line__c);

        Set<Id> caseIds = new Set<Id>();

        for (Case record : relatedCases) {
            caseIds.add(record.Id);
        }

        List<Task> relatedTasks = DMT_ApprovalTemplate_Selector.getRelatedLineTasks(
            caseIds,
            currentTask != null ? currentTask.Id : null
        );

        return !relatedTasks.isEmpty();
    }

    /**
     * @description Approver lookup fields supported on DMT_Task_Type__c.DMT_Approver_Field__c
     */
    private static final Set<String> APPROVER_LOOKUP_FIELDS = new Set<String>{
        'DMT_Approver__c',
        'DMT_ApproverGlobalBanker__c',
        'DMT_Booking_Unit_Risk_Analyst__c'
    };

    /**
     * @description Resolves default approver code for selected task type
     */
    private static String resolveDefaultApprover(Case caseRecord, DMT_Task_Type__c taskType) {
        if (caseRecord == null || taskType == null || !APPROVER_LOOKUP_FIELDS.contains(taskType.DMT_Approver_Field__c)) {
            return null;
        }

        SObject record = caseRecord.DMT_LineOpportunity__c == 'O'
            ? (SObject) DMT_ApprovalTemplate_Selector.getOpportunity(caseRecord.opportunity_id__c)
            : (SObject) DMT_ApprovalTemplate_Selector.getLine(caseRecord.DMT_Line__c);

        if (record == null) {
            return null;
        }

        String relationshipName = taskType.DMT_Approver_Field__c.replace('__c', '__r');
        SObject approverRecord = record.getSObject(relationshipName);

        return approverRecord != null ? (String) approverRecord.get('DMT_Approver_Code__c') : null;
    }
    /**
     * @description Contexto completo para el flujo de cierre de task
     * (equivalente a DMT_CloseTask_Controller.CloseTaskInitDTO)
     */
    public class CloseTaskContextDTO {
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

    /**
     * @description DTO de opciones para combobox de task
     */
    public class TaskOptionDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean isDefault;
        @AuraEnabled public Boolean approvalEdit;
        @AuraEnabled public String approverField;
    }

    /**
     * @description Selección de task y approvers
     * (equivalente a DMT_CloseTask_Controller.TaskSelectionDTO)
     */
    public class TaskApproverSelectionDTO {
        @AuraEnabled public Id taskTypeId;
        @AuraEnabled public String taskTypeName;
        @AuraEnabled public String externalId;
        @AuraEnabled public String approverField;
        @AuraEnabled public Boolean approvalEdit;
        @AuraEnabled public List<ApproverOptionDTO> approvers;
        @AuraEnabled public String defaultApproverCode;
        @AuraEnabled public Boolean showApprovers;
    }

    /**
     * @description DTO de opciones para combobox de approver
     */
    public class ApproverOptionDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String approverCode;
        @AuraEnabled public String approverType;
    }

    /**
     * @description Resultado del cierre de task
     * (equivalente a DMT_CloseTask_Controller.CloseTaskResult)
     */
    public class CloseTaskResultDTO {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Id newTaskId;
        @AuraEnabled public String message;
    }

}