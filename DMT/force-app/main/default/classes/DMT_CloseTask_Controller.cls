/**
 * @description Facade controller for the close-task flow.
 * Delegates business logic to DMT_TaskApprovalFlowService for centralized management.
 * Maintains backward compatibility with legacy DTO names.
 * @author DMT Team | CIBGLOBALD-4025 | Refactored to Service Pattern
 */
public with sharing class DMT_CloseTask_Controller {
    
    /**
     * @description Loads the initial context required by the close-task LWC.
     * Delegates to DMT_TaskApprovalFlowService.getCloseTaskContext() and maps result.
     * @param recordId Case identifier used as the entry point for the flow.
     * @return DTO containing case, task, task type, and default selection data.
     */
    @AuraEnabled(cacheable=true)
    public static CloseTaskInitDTO getInitialData(Id recordId) {

        if (recordId == null) {
            throw new AuraHandledException('recordId is required.');
        }

        // Delegate to service
        DMT_TaskApprovalFlowService.CloseTaskContextDTO serviceResult = DMT_TaskApprovalFlowService.getCloseTaskContext(recordId);

        // Map service DTO to legacy DTO for backward compatibility
        CloseTaskInitDTO response = mapContextDTOToInitDTO(serviceResult);

        return response;
    }

    /**
     * @description Loads the approver options for the selected task step.
     * Delegates to DMT_TaskApprovalFlowService.getApproversForStep() and maps result.
     * @param recordId Case identifier used to resolve the current context.
     * @param stepSelected Selected task step external identifier.
     * @return DTO containing task type data, approvers, and visibility flags.
     */
    @AuraEnabled(cacheable=true)
    public static TaskSelectionDTO getTaskSelectionData(Id recordId, String stepSelected) {

        if (recordId == null) {
            throw new AuraHandledException('recordId is required.');
        }

        if (String.isBlank(stepSelected)) {
            throw new AuraHandledException('stepSelected is required.');
        }

        // Delegate to service
        DMT_TaskApprovalFlowService.TaskApproverSelectionDTO serviceResult = DMT_TaskApprovalFlowService.getApproversForStep(recordId, stepSelected);

        // Map service DTO to legacy DTO for backward compatibility
        TaskSelectionDTO response = mapApproverSelectionDTOToTaskSelectionDTO(serviceResult);

        return response;
    }

    /**
     * @description Executes the close-step flow: completes the current task, creates the
     * next approval task, snapshots its status, and moves the Case to the next owner.
     * Delegates to DMT_TaskApprovalFlowService.executeCloseTaskFlow() and maps result.
     * @param caseId Related case identifier.
     * @param currentTaskId Current task identifier.
     * @param stepSelected External identifier of the selected task type.
     * @param approverSelected External identifier of the selected approver.
     * @return Result DTO with the outcome and the new task id.
     */
    @AuraEnabled
    public static CloseTaskResult closeTask(Id caseId, Id currentTaskId, String stepSelected, String approverSelected) {

        // Delegate to service
        DMT_TaskApprovalFlowService.CloseTaskResultDTO serviceResult = DMT_TaskApprovalFlowService.executeCloseTaskFlow(
            caseId,
            currentTaskId,
            stepSelected,
            approverSelected
        );

        // Map service DTO to legacy DTO for backward compatibility
        CloseTaskResult response = mapCloseTaskResultDTO(serviceResult);

        return response;
    }

    // ====== DTO Mapping Methods (Backward Compatibility) ======

    /**
     * @description Maps service CloseTaskContextDTO to legacy CloseTaskInitDTO.
     */
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

        // Map TaskOptionDTO list
        result.validations = new List<TaskOptionDTO>();
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

        return result;
    }

    /**
     * @description Maps service TaskApproverSelectionDTO to legacy TaskSelectionDTO.
     */
    private static TaskSelectionDTO mapApproverSelectionDTOToTaskSelectionDTO(DMT_TaskApprovalFlowService.TaskApproverSelectionDTO serviceDTO) {
        TaskSelectionDTO result = new TaskSelectionDTO();

        result.taskTypeId = serviceDTO.taskTypeId;
        result.taskTypeName = serviceDTO.taskTypeName;
        result.externalId = serviceDTO.externalId;
        result.approverField = serviceDTO.approverField;
        result.approvalEdit = serviceDTO.approvalEdit;
        result.defaultApproverCode = serviceDTO.defaultApproverCode;
        result.showApprovers = serviceDTO.showApprovers;

        // Map ApproverOptionDTO list
        result.approvers = new List<ApproverOptionDTO>();
        for (DMT_TaskApprovalFlowService.ApproverOptionDTO serviceApprover : serviceDTO.approvers) {
            ApproverOptionDTO legacyApprover = new ApproverOptionDTO();
            legacyApprover.id = serviceApprover.id;
            legacyApprover.label = serviceApprover.label;
            legacyApprover.value = serviceApprover.value;
            legacyApprover.approverCode = serviceApprover.approverCode;
            legacyApprover.approverType = serviceApprover.approverType;
            result.approvers.add(legacyApprover);
        }

        return result;
    }

    /**
     * @description Maps service CloseTaskResultDTO to legacy CloseTaskResult.
     */
    private static CloseTaskResult mapCloseTaskResultDTO(DMT_TaskApprovalFlowService.CloseTaskResultDTO serviceDTO) {
        CloseTaskResult result = new CloseTaskResult();
        result.success = serviceDTO.success;
        result.newTaskId = serviceDTO.newTaskId;
        result.message = serviceDTO.message;
        return result;
    }

    /**
     * @description Initialization payload returned to the close-task LWC.
     */
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

    /**
     * @description Task option returned to the close-task LWC combobox.
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
     * @description Selected task payload used to render approvers and field visibility.
     */
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

    /**
     * @description Approver option returned to the close-task LWC combobox.
     */
    public class ApproverOptionDTO {

        @AuraEnabled public Id id;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String approverCode;
        @AuraEnabled public String approverType;
    }

    /**
     * @description Result payload for the close-step flow.
     */
    public class CloseTaskResult {

        @AuraEnabled public Boolean success;
        @AuraEnabled public Id newTaskId;
        @AuraEnabled public String message;
    }
}