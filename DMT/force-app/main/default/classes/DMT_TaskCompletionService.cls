/**
 * Single responsibility: apply an approver's decision to a Task - result, comments, committee
 * label, and (when the approval is routing to a next step rather than finishing) status and owner.
 * Every field on the request is optional except taskId; a null field means "don't touch it," so the
 * same method serves both callers cleanly: the bulk massive-closure flow only ever sets
 * result/comments/committee label on an existing task, while the single-task approval screen also
 * sets status/owner/task type and can leave taskId blank to create the next step's task.
 *
 * Every entry point that records an approver's decision on a Task - the bulk massive-closure modal,
 * the single-task approval screen, and any future caller - must call this same class and method.
 */
public with sharing class DMT_TaskCompletionService {

    public class TaskCompletionRequest {
        public Id taskId;              // null => insert a new task
        public Id recordTypeId;        // left untouched when null - applies on update too
        public String subject;         // left untouched when null; defaults to 'Task' only when inserting
        public Id caseId;              // WhatId
        public String stepResult;      // DMT_Step_Result__c
        public String comments;        // Description
        public String committeeLabel;  // DMT_Committee_Label__c
        public Boolean doNotRestart;   // DMT_Not_Restart__c
        public Id taskTypeId;          // DMT_Task_Type__c - already resolved by the caller
        public Id ownerId;             // OwnerId (e.g. next approver's queue) - already resolved by the caller
        public String status;          // Status - left untouched when null
        public Id viewStatusAtCloseId; // DMT_ViewStatusAtClose__c - the freeze snapshot link
    }

    public static void completeTask(TaskCompletionRequest request) {
        completeTasks(new List<TaskCompletionRequest>{ request });
    }

    public static void completeTasks(List<TaskCompletionRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        List<Task> toInsert = new List<Task>();
        List<Task> toUpdate = new List<Task>();

        for (TaskCompletionRequest req : requests) {
            if (req == null) {
                continue;
            }
            Task t = new Task();
            if (req.caseId != null) t.WhatId = req.caseId;
            if (req.stepResult != null) t.DMT_Step_Result__c = req.stepResult;
            if (req.comments != null) t.Description = req.comments;
            if (req.committeeLabel != null) t.DMT_Committee_Label__c = req.committeeLabel;
            if (req.doNotRestart != null) t.DMT_Not_Restart__c = req.doNotRestart;
            if (req.taskTypeId != null) t.DMT_Task_Type__c = req.taskTypeId;
            if (req.ownerId != null) t.OwnerId = req.ownerId;
            if (req.status != null) t.Status = req.status;
            if (req.viewStatusAtCloseId != null) t.DMT_ViewStatusAtClose__c = req.viewStatusAtCloseId;
            if (req.recordTypeId != null) t.RecordTypeId = req.recordTypeId;
            if (req.subject != null) t.Subject = req.subject;

            if (req.taskId != null) {
                t.Id = req.taskId;
                toUpdate.add(t);
            } else {
                if (String.isBlank(t.Subject)) {
                    t.Subject = 'Task';
                }
                toInsert.add(t);
            }
        }

        DMT_DmlUtils.updateMany(toUpdate, 'completeTasks_update');
        DMT_DmlUtils.insertMany(toInsert, 'completeTasks_insert');
    }
}