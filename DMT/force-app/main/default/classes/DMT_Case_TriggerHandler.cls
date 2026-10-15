/**
 * CIBGLOBALD-4374 - Approval Case automation, replaces the record-triggered flow Case_After_Trigger_Flow.
 *
 * Called from SER_Case_TRIGGER (the only Case trigger). Every operation receives the whole
 * Trigger.new collection and runs a fixed number of queries and DML statements whatever the number
 * of Cases:
 *
 *  after insert (Approval Cases)
 *    - approver group members become team members of the Case Line / Opportunity.
 *  after update (Approval Cases)
 *    - Status moved to Finished / Pending:
 *        . Finished on a Line in Approval stamps DMT_Line__c.DMT_Approval_Date__c;
 *        . attachments of the Case move to the current Task (see moveAttachmentsToCurrentTask).
 *    - approver group members become team members (same as insert);
 *    - the next approval Case is started when a Case closes with result Yes
 *      (DMT_Case_Steps_Controller.startNextCaseApprovals).
 *
 * The flow branch Finished_to_Pending required $Record.IsDeleted = true in an after-save context,
 * which never happens, so it is intentionally not ported.
 */
public without sharing class DMT_Case_TriggerHandler {

    private static final String STATUS_IN_PROGRESS = 'In Progress';

    public static void afterInsert(List<Case> newCases) {
        List<Case> approvalCases = filterApprovalCases(newCases);
        if (approvalCases.isEmpty()) {
            return;
        }
        scheduleTeamMembers(approvalCases);
        DMT_AsyncOrchestrator.flush();
    }

    public static void afterUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
        List<Case> approvalCases = filterApprovalCases(newCases);
        if (approvalCases.isEmpty() || oldMap == null) {
            return;
        }

        List<Case> statusChanged = new List<Case>();
        for (Case approvalCase : approvalCases) {
            Case oldCase = oldMap.get(approvalCase.Id);
            Boolean movedToFinishedOrPending = approvalCase.Status != oldCase?.Status
                && (approvalCase.Status == DMT_Constants.FINISHED || approvalCase.Status == DMT_Constants.PENDING);
            if (movedToFinishedOrPending) {
                statusChanged.add(approvalCase);
            }
        }

        try {
            stampApprovalDateOnLines(statusChanged);
            moveAttachmentsToCurrentTask(statusChanged);
        } catch (Exception e) {
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
                'DMT_Case_TriggerHandler', 'afterUpdate', 'DMT', 'Case'
            ));
        }

        scheduleTeamMembers(approvalCases);
        DMT_Case_Steps_Controller.startNextCaseApprovals(approvalCases, oldMap);
        DMT_AsyncOrchestrator.flush();
    }

    private static List<Case> filterApprovalCases(List<Case> cases) {
        List<Case> approvalCases = new List<Case>();
        if (cases == null || cases.isEmpty()) {
            return approvalCases;
        }
        Id approvalRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get(DMT_Constants.CASE_RT_APPROVAL)?.getRecordTypeId();
        for (Case caseRecord : cases) {
            if (approvalRecordTypeId != null && caseRecord.RecordTypeId == approvalRecordTypeId) {
                approvalCases.add(caseRecord);
            }
        }
        return approvalCases;
    }

    private static void scheduleTeamMembers(List<Case> approvalCases) {
        List<DMT_TeamMember_Service.CaseRequest> requests = new List<DMT_TeamMember_Service.CaseRequest>();
        for (Case approvalCase : approvalCases) {
            requests.add(new DMT_TeamMember_Service.CaseRequest(approvalCase.Id, false));
        }
        DMT_TeamMember_Service.scheduleCaseRequests(requests);
    }

    /**
     * Flow element Update_Approval_Date_Line: a Case finished while its Line is in Approval stamps the
     * approval date of the Line. One query for the Lines and one update.
     */
    private static void stampApprovalDateOnLines(List<Case> statusChanged) {
        Set<Id> lineIds = new Set<Id>();
        for (Case approvalCase : statusChanged) {
            if (approvalCase.Status == DMT_Constants.FINISHED && approvalCase.DMT_Line__c != null) {
                lineIds.add(approvalCase.DMT_Line__c);
            }
        }
        if (lineIds.isEmpty()) {
            return;
        }

        List<DMT_Line__c> linesToUpdate = new List<DMT_Line__c>();
        for (DMT_Line__c line : [SELECT Id FROM DMT_Line__c WHERE Id IN :lineIds AND Status__c = :DMT_Constants.APPROVAL]) {
            linesToUpdate.add(new DMT_Line__c(Id = line.Id, DMT_Approval_Date__c = Datetime.now()));
        }
        if (!linesToUpdate.isEmpty()) {
            update linesToUpdate;
        }
    }

    /**
     * Flow elements GetCurrentcaseattachment ... Delete_attachment_from_case: when a Case changes to
     * Finished or Pending, its attachments are copied to the Task that is currently open on it
     * (In Progress or Completed) and removed from the Case. The Task owner is switched to the running
     * user while the attachments are created and put back to the original owner afterwards, as the
     * flow did. Queries: attachments and Tasks, once for all the Cases.
     */
    private static void moveAttachmentsToCurrentTask(List<Case> statusChanged) {
        if (statusChanged.isEmpty()) {
            return;
        }
        Set<Id> caseIds = new Map<Id, Case>(statusChanged).keySet();

        Map<Id, List<Attachment>> attachmentsByCaseId = new Map<Id, List<Attachment>>();
        for (Attachment attachment : [
            SELECT Id, Name, Body, ContentType, Description, ParentId
            FROM Attachment
            WHERE ParentId IN :caseIds
        ]) {
            if (!attachmentsByCaseId.containsKey(attachment.ParentId)) {
                attachmentsByCaseId.put(attachment.ParentId, new List<Attachment>());
            }
            attachmentsByCaseId.get(attachment.ParentId).add(attachment);
        }
        if (attachmentsByCaseId.isEmpty()) {
            return;
        }

        Map<Id, Task> currentTaskByCaseId = new Map<Id, Task>();
        for (Task task : [
            SELECT Id, WhatId, OwnerId
            FROM Task
            WHERE WhatId IN :attachmentsByCaseId.keySet()
            AND (Status = :STATUS_IN_PROGRESS OR Status = :DMT_Constants.COMPLETED)
            ORDER BY CreatedDate DESC
        ]) {
            if (!currentTaskByCaseId.containsKey(task.WhatId)) {
                currentTaskByCaseId.put(task.WhatId, task);
            }
        }
        if (currentTaskByCaseId.isEmpty()) {
            return;
        }

        Id runningUserId = UserInfo.getUserId();
        List<Task> tasksToTake = new List<Task>();
        List<Task> tasksToRestore = new List<Task>();
        List<Attachment> attachmentsToInsert = new List<Attachment>();
        List<Attachment> attachmentsToDelete = new List<Attachment>();

        for (Id caseId : currentTaskByCaseId.keySet()) {
            Task currentTask = currentTaskByCaseId.get(caseId);
            tasksToTake.add(new Task(Id = currentTask.Id, OwnerId = runningUserId));
            tasksToRestore.add(new Task(Id = currentTask.Id, OwnerId = currentTask.OwnerId));
            for (Attachment source : attachmentsByCaseId.get(caseId)) {
                Attachment copy = source.clone(false, true, false, false);
                copy.ParentId = currentTask.Id;
                copy.OwnerId = runningUserId;
                attachmentsToInsert.add(copy);
                attachmentsToDelete.add(source);
            }
        }

        update tasksToTake;
        insert attachmentsToInsert;
        delete attachmentsToDelete;
        update tasksToRestore;
    }
}
