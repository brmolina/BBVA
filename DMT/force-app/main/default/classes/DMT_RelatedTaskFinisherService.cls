/**
 * Single responsibility: once a Case's approval is done, finish every other still-open Task on it
 * (mirrors "FinishAllRelatedTasks" in the Approver_UpdateStep Integration Procedure's FinishCase
 * block). The set of tasks to finish and their target status are computed here, server-side, from
 * the Case itself - never taken from caller-supplied data, so every caller gets the same answer to
 * "which tasks are still open on this case" regardless of what the UI happened to have loaded.
 */
public with sharing class DMT_RelatedTaskFinisherService {

    public static void finishRelatedTasks(Id caseId) {
        finishRelatedTasks(new List<Id>{ caseId });
    }

    public static void finishRelatedTasks(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }

        List<Task> openTasks = [
            SELECT Id
            FROM Task
            WHERE WhatId IN :caseIds
              AND Status != :DMT_Constants.CANCELLED
            WITH SYSTEM_MODE
        ];
        if (openTasks.isEmpty()) {
            return;
        }

        List<Task> tasksToFinish = new List<Task>();
        for (Task t : openTasks) {
            tasksToFinish.add(new Task(Id = t.Id, Status = DMT_Constants.FINISHED));
        }
        DMT_DmlUtils.updateMany(tasksToFinish, 'finishRelatedTasks');
    }
}