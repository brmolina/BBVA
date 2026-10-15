/**
 * CIBGLOBALD-4374 - Approval step Task automation, replaces the record-triggered flow DMT_After_Task_Trigger.
 *
 * Called from Task.trigger. Only Tasks of the DMT_Step_Approval record type are processed, and every
 * operation takes the whole Trigger.new collection (fixed query / DML cost whatever the number of Tasks).
 *
 *  before update
 *    - a step closed (Completed / Cancelled) without DMT_UserClosedTask__c gets the closing user and
 *      date stamped. The flow did this with an update of the record itself AFTER the save, which
 *      fired every Task trigger and flow a second time; doing it before the save avoids that.
 *  after insert
 *    - task type 'Specialist Group Validation - Asset Allocation' on a Case with an Opportunity flags
 *      Opportunity.DMT_Has_Asset_Allocation__c;
 *    - task type with DMT_ApprovalEdit__c opens the edit grants (team members with sanctionEdit = true).
 *  after update
 *    - a step moved to Completed / Cancelled / Finished withdraws the approval-edit grants of its Line
 *      and Opportunity, unless the Line is Closed Won.
 */
public without sharing class DMT_Task_TriggerHandler {

    @TestVisible private static final String ASSET_ALLOCATION_TASK_TYPE = 'Specialist Group Validation - Asset Allocation';
    private static final String LINE_STATUS_CLOSED = 'Closed';
    private static final String LINE_CLOSED_WON = 'Won';

    public static void beforeUpdate(List<Task> newTasks, Map<Id, Task> oldMap) {
        if (newTasks == null || newTasks.isEmpty() || oldMap == null) {
            return;
        }
        List<Task> approvalTasks = filterApprovalTasks(newTasks);
        for (Task task : approvalTasks) {
            Task oldTask = oldMap.get(task.Id);
            if (oldTask != null && isClosedNow(task, oldTask)
                && task.Status != DMT_Constants.FINISHED
                && task.DMT_UserClosedTask__c == null) {
                task.DMT_Completed_Date_Time__c = Datetime.now();
                task.DMT_UserClosedTask__c = UserInfo.getUserId();
            }
        }
    }

    public static void afterInsert(List<Task> newTasks) {
        List<Task> approvalTasks = filterApprovalTasks(newTasks);
        if (approvalTasks.isEmpty()) {
            return;
        }

        Set<Id> caseIds = new Set<Id>();
        Set<Id> taskTypeIds = new Set<Id>();
        for (Task task : approvalTasks) {
            if (task.WhatId != null && task.WhatId.getSObjectType() == Case.SObjectType) {
                caseIds.add(task.WhatId);
            }
            if (task.DMT_Task_Type__c != null) {
                taskTypeIds.add(task.DMT_Task_Type__c);
            }
        }
        if (caseIds.isEmpty() || taskTypeIds.isEmpty()) {
            return;
        }

        Map<Id, Case> casesById = new Map<Id, Case>([
            SELECT Id, opportunity_id__c FROM Case WHERE Id IN :caseIds
        ]);
        Map<Id, DMT_Task_Type__c> taskTypesById = new Map<Id, DMT_Task_Type__c>([
            SELECT Id, Name, DMT_ApprovalEdit__c FROM DMT_Task_Type__c WHERE Id IN :taskTypeIds
        ]);

        Set<Id> assetAllocationOpportunityIds = new Set<Id>();
        Set<Id> approvalEditCaseIds = new Set<Id>();
        for (Task task : approvalTasks) {
            Case relatedCase = casesById.get(task.WhatId);
            DMT_Task_Type__c taskType = taskTypesById.get(task.DMT_Task_Type__c);
            if (relatedCase == null || taskType == null) {
                continue;
            }
            if (taskType.Name == ASSET_ALLOCATION_TASK_TYPE && relatedCase.opportunity_id__c != null) {
                assetAllocationOpportunityIds.add(relatedCase.opportunity_id__c);
            }
            if (taskType.DMT_ApprovalEdit__c == true) {
                approvalEditCaseIds.add(relatedCase.Id);
            }
        }

        if (!assetAllocationOpportunityIds.isEmpty()) {
            List<Opportunity> opportunities = new List<Opportunity>();
            for (Id opportunityId : assetAllocationOpportunityIds) {
                opportunities.add(new Opportunity(Id = opportunityId, DMT_Has_Asset_Allocation__c = true));
            }
            update opportunities;
        }

        if (!approvalEditCaseIds.isEmpty()) {
            List<DMT_TeamMember_Service.CaseRequest> requests = new List<DMT_TeamMember_Service.CaseRequest>();
            for (Id caseId : approvalEditCaseIds) {
                requests.add(new DMT_TeamMember_Service.CaseRequest(caseId, true));
            }
            DMT_TeamMember_Service.scheduleCaseRequests(requests);
            DMT_AsyncOrchestrator.flush();
        }
    }

    public static void afterUpdate(List<Task> newTasks, Map<Id, Task> oldMap) {
        if (oldMap == null) {
            return;
        }
        Set<Id> caseIds = new Set<Id>();
        for (Task task : filterApprovalTasks(newTasks)) {
            Task oldTask = oldMap.get(task.Id);
            if (oldTask != null && isClosedNow(task, oldTask)
                && task.WhatId != null && task.WhatId.getSObjectType() == Case.SObjectType) {
                caseIds.add(task.WhatId);
            }
        }
        if (caseIds.isEmpty()) {
            return;
        }

        Set<Id> lineIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        for (Case relatedCase : [
            SELECT Id, DMT_Line__c, opportunity_id__c, DMT_Line__r.Status__c, DMT_Line__r.Closed__c
            FROM Case
            WHERE Id IN :caseIds
        ]) {
            Boolean lineClosedWon = relatedCase.DMT_Line__r != null
                && relatedCase.DMT_Line__r.Status__c == LINE_STATUS_CLOSED
                && relatedCase.DMT_Line__r.Closed__c == LINE_CLOSED_WON;
            if (lineClosedWon) {
                continue;
            }
            if (relatedCase.DMT_Line__c != null) {
                lineIds.add(relatedCase.DMT_Line__c);
            }
            if (relatedCase.opportunity_id__c != null) {
                opportunityIds.add(relatedCase.opportunity_id__c);
            }
        }

        DMT_TeamMember_Service.syncApprovalEditAccess(lineIds, opportunityIds);
    }

    // Completed / Cancelled / Finished reached in this save.
    private static Boolean isClosedNow(Task newTask, Task oldTask) {
        Boolean closedStatus = newTask.Status == DMT_Constants.COMPLETED
            || newTask.Status == DMT_Constants.CANCELLED
            || newTask.Status == DMT_Constants.FINISHED;
        return closedStatus && newTask.Status != oldTask.Status;
    }

    private static List<Task> filterApprovalTasks(List<Task> tasks) {
        if (tasks == null || tasks.isEmpty()) {
            return new List<Task>();
        }
        List<Task> approvalTasks = DES_RecordType_Utils.filter((List<SObject>) tasks, 'Task', DMT_Constants.TASK_RT_APPROVAL_STEP);
        return approvalTasks == null ? new List<Task>() : approvalTasks;
    }
}
