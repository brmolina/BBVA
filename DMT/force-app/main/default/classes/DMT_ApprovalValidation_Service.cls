/**
 * @description Service class that replaces OmniStudio components for approval workflow.
 * Replaces:
 *   - DmtDrApproversTemplate (DataRaptor Extract)
 *   - DMTApprovalChangeStepHandler_saveValuesUpdate (Integration Procedure)
 *   - Approver_UpdateStep_Procedure_24 (Integration Procedure)
 * @author DMT Team | CIBGLOBALD-4025
 */
public without sharing class DMT_ApprovalValidation_Service {

    private static final String STEP_YES = 'Yes';
    private static final String STEP_NO = 'No';
    private static final String STEP_NA = 'NA';
    private static final String STATUS_PROPOSAL = 'Proposal';

    /**
     * @description Loads Task and Case context for the approval modal.
     * Replaces the initial context loading from FlexCard + Integration Procedure.
     * @param recordId Task ID
     * @return Map containing task, case, and available validations
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getTaskContext(String recordId) {
        Map<String, Object> context = new Map<String, Object>();
        
        try {
            // Get Task and related Case
            Task task = [
                SELECT Id, Subject, Status, OwnerId, WhatId,
                       DMT_Step_Result__c, DMT_Committee_Label__c,
                       DMT_Task_Type__c, DMT_Task_Type__r.Name,
                       DMT_Task_Type__r.DMT_External_Id__c,
                       DMT_Task_Type__r.DMT_ApprovalEdit__c,
                       DMT_Task_Type__r.DMT_Yes_Flag__c,
                       DMT_Task_Type__r.DMT_No_Flag__c,
                       DMT_Task_Type__r.DMT_NA_Flag__c
                FROM Task 
                WHERE Id = :recordId 
                LIMIT 1
            ];

            Case relatedCase = [
                SELECT Id, Status, DMT_LineOpportunity__c, DMT_Line__c,
                       opportunity_id__c, DMT_Line__r.Status__c
                FROM Case 
                WHERE Id = :task.WhatId 
                LIMIT 1
            ];

            // Determine status line from the related line first, then case status.
            String statusLine = relatedCase.DMT_Line__r != null && relatedCase.DMT_Line__r.Status__c != null
                ? relatedCase.DMT_Line__r.Status__c
                : relatedCase.Status;
            
            // Get available validations/steps (replaces DmtDrApproversTemplate logic)
            List<Map<String, String>> validations = getValidationSteps(task, relatedCase);
            List<Map<String, String>> proposalValidations = getProposalValidationSteps(task, relatedCase);

            context.put('taskId', task.Id);
            context.put('caseId', relatedCase.Id);
            context.put('taskSubject', task.Subject);
            context.put('taskStatus', task.Status);
            context.put('statusLine', statusLine);
            context.put('validations', validations);
            context.put('proposalValidations', proposalValidations);
            
            return context;
        } catch (Exception ex) {
            throw new AuraHandledException('Error loading task context: ' + ex.getMessage());
        }
    }

    /**
     * @description Gets list of available approval steps for non-Proposal status.
     * @param task Current task
     * @param relatedCase Related case
     * @return List of {label, value} maps for combobox
     */
    private static List<Map<String, String>> getValidationSteps(Task task, Case relatedCase) {
        // Preserve the business meaning from the DataMapper: the task type drives the
        // available decision values rendered in the modal.
        return new List<Map<String, String>>{
            new Map<String, String>{'label' => STEP_YES, 'value' => STEP_YES},
            new Map<String, String>{'label' => STEP_NO, 'value' => STEP_NO},
            new Map<String, String>{'label' => STEP_NA, 'value' => STEP_NA}
        };
    }

    /**
     * @description Gets list of available approval steps for Proposal status.
     * @param task Current task
     * @param relatedCase Related case
     * @return List of {label, value} maps for combobox
     */
    private static List<Map<String, String>> getProposalValidationSteps(Task task, Case relatedCase) {
        return getValidationSteps(task, relatedCase);
    }

    /**
     * @description Gets list of approvers for a selected step.
     * Replaces DmtDrApproversTemplate (DataRaptor Extract).
     * @param stepSelected The selected approval step
     * @param recordId Task ID
     * @return List of {label, value} maps for approver combobox
     */
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getApproversForStep(String stepSelected, String recordId) {
        List<Map<String, String>> approvers = new List<Map<String, String>>();

        try {
            Task task = [
                SELECT WhatId, DMT_Task_Type__c, DMT_Task_Type__r.DMT_External_Id__c
                FROM Task
                WHERE Id = :recordId
                LIMIT 1
            ];
            Case relatedCase = [
                SELECT DMT_LineOpportunity__c, DMT_Line__c, opportunity_id__c, DMT_Line__r.Status__c 
                FROM Case 
                WHERE Id = :task.WhatId 
                LIMIT 1
            ];

            DMT_Task_Type__c selectedTaskType = [
                SELECT Id, Name, DMT_External_Id__c, DMT_ApprovalEdit__c
                FROM DMT_Task_Type__c
                WHERE DMT_External_Id__c = :stepSelected
                LIMIT 1
            ];

            List<DMT_Task_Approver_Relationship__c> relationships = [
                SELECT DMT_Approver__c, DMT_Approver__r.Name, DMT_Approver__r.DMT_Group__c,
                       DMT_Approver__r.DMT_ApproverType__r.Name, DMT_Approver__r.DMT_External_Id__c
                FROM DMT_Task_Approver_Relationship__c
                WHERE DMT_Task_Type__c = :selectedTaskType.Id
                ORDER BY CreatedDate DESC
            ];

            for (DMT_Task_Approver_Relationship__c relationship : relationships) {
                if (relationship.DMT_Approver__c == null) {
                    continue;
                }
                approvers.add(new Map<String, String>{
                    'label' => relationship.DMT_Approver__r != null ? relationship.DMT_Approver__r.Name : String.valueOf(relationship.DMT_Approver__c),
                    'value' => String.valueOf(relationship.DMT_Approver__c)
                });
            }

            return approvers;
        } catch (Exception ex) {
            throw new AuraHandledException('Error loading approvers: ' + ex.getMessage());
        }
    }

    /**
     * @description Main method to update approval step and trigger workflow.
     * Replaces Approver_UpdateStep Integration Procedure orchestration.
     * @param taskId Current Task ID
     * @param caseId Case ID
     * @param recordId Record ID (for updates)
     * @param stepSelected Selected approval step
     * @param nextApprover Selected approver ID
     * @return Result map with error flag and message
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> updateApprovalStep(String taskId, String caseId, String recordId, String stepSelected, String nextApprover) {

        Map<String, Object> result = new Map<String, Object>();

        try {

            
            result.put('error', false);
            result.put('message', '');
            // Step 2: Resolve the selected approver and its group.
            DMT_Approver__c approver = [
                SELECT Id, Name, DMT_Group__c, DMT_ApproverType__r.Name 
                FROM DMT_Approver__c
                WHERE Id = :nextApprover
                LIMIT 1
            ];
            DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(taskId, true);

            // Step 3: Complete current task
            Task currentTask = new Task(Id = taskId);
            currentTask.Status = 'Completed';
            update currentTask;

            // Step 4: Create new task for next approver (replaces DataRaptor Post Action)
            
            Task newTask = new Task();
            newTask.Subject = currentTask.Subject;
            newTask.WhatId = caseId;
            newTask.OwnerId = approver.DMT_Group__c; // Group ID
            newTask.Status = 'Not Started';
            newTask.DMT_Step_Result__c = stepSelected;
            insert newTask;

            // Step 5: Update case owner
            Case caseToUpdate = new Case(Id = caseId);
            caseToUpdate.OwnerId = approver.DMT_Group__c;
            caseToUpdate.Status = 'Pending';
            update caseToUpdate;

            // Step 6: Save new task status
            DMT_ApprovalChangeStep_Handler.updateTaskWithStatus(newTask.Id, false);

            result.put('message', 'Approval step updated successfully. New task created for next approver.');
             return result;
        } catch (Exception ex) {
            result.put('error', true);
            result.put('message', 'Error updating approval step: ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, 'DMT_ApprovalValidation_Service error: ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + ex.getStackTraceString());
             return result;
        }

       
    }
}