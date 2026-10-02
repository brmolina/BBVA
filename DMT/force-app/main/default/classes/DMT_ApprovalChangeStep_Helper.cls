/**
 * Approval-task restart ("case reopen") framework.
 *
 * Two entry points:
 *   restartStaleApprovalTasks() - the shared watch gate. Both trigger handlers call it to work out
 *                                 which open approval Tasks are stale and restart them.
 *   restartTasksForRecord()     - the DML step: cancel, recreate, reset the Case. Also reused by
 *                                 DMT_AsyncDispatcher for the async path.
 *
 * Which fields are watched is never defined here. It comes from the renderers via
 * DMT_RendererFactory - see DMT_ClientRenderer for the maintenance rules.
 */
global without sharing class DMT_ApprovalChangeStep_Helper {

    // RecordTypeId is re-assigned explicitly after the clone: clone() only carries fields that were
    // actually queried, and a caller that forgets to select it would otherwise get a replacement
    // task with a default record type, invisible to DMT_Case_Steps_Controller's RecordType-filtered
    // queries. This way it fails loudly instead.
    public static Task createResetTask(Task taskToReset){
        Task t = taskToReset.clone(false, true, false);
        t.Status = DMT_Constants.NOTSTARTED;
        t.Subject = 'Task';
        t.DMT_ViewStatusAtClose__c = null;
        t.RecordTypeId = taskToReset.RecordTypeId;
        return t;
    }

    public static Case createResetCase(Id caseId, Id ownerId){
        Case c = new Case();
        c.Id = caseId;
        c.OwnerId = ownerId;
        c.Status = DMT_Constants.PENDING;
        c.DMT_IsInRevision__c = false;
        return c;
    }

    @InvocableMethod(label='Update owner from case' description='Updates owner from cases via Flow')
    public static void updateOwnerFromCase(List<RequestFinishedCase> request){
        List<Case> casesToUpdate = new List<Case>();
        Case c = new Case();
        c.Id = request.get(0).caseId;
        c.OwnerId = request.get(0).owners;
        casesToUpdate.add(c);

        update casesToUpdate;
    }

    public class RequestFinishedCase {
        @InvocableVariable
        public Id caseId;
        @InvocableVariable
        public Id owners;
    }

    /**
     * Cancels the stale tasks for ONE record, creates their replacements and resets the related
     * Cases, as a single all-or-nothing group. recordId is a DMT_Line__c or an Opportunity Id -
     * there is no object-specific logic here.
     * Savepoint is per record on purpose: a failure rolls back only this record's restarts, never
     * another record's, and never the save that triggered it.
     */
    public static void restartTasksForRecord(Id recordId, List<Task> tasksToRestart) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Task> tasksToCreate = new List<Task>();
            // Keyed by Case Id because several stale tasks can share one Case, and a bulk update
            // containing the same Id twice throws "Duplicate id in list".
            Map<Id, Case> casesToResetByCaseId = new Map<Id, Case>();
            for (Task task : tasksToRestart) {
                task.Status = DMT_Constants.CANCELLED;
                tasksToCreate.add(createResetTask(task));
                Case resetCase = createResetCase(task.WhatId, task.OwnerId);
                casesToResetByCaseId.put(resetCase.Id, resetCase);
            }
            Database.update(tasksToRestart, AccessLevel.SYSTEM_MODE);
            Database.insert(tasksToCreate, AccessLevel.SYSTEM_MODE);
            Database.update(casesToResetByCaseId.values(), AccessLevel.SYSTEM_MODE);

            // Publishes the LINE/OPPORTUNITY Id, not a Task Id: dmt_passport.js only recognises
            // Task Ids it already knows, so it can never match a brand-new replacement task. It
            // does track the record Id, so this refreshes the traffic light reliably.
            EventBus.publish(new DMT_Task__e(Operation__c = 'CASE_UPDATE', records__c = String.valueOf(recordId)));
        } catch (Exception e) {
            Database.rollback(sp);
            logRestartFailure(e, 'Task', 'restartTasksForRecord');
        }
    }

    private static void logRestartFailure(Exception e, String objectName, String methodName) {
        logRestartFailure(e, objectName, methodName, 'DMT_ApprovalChangeStep_Helper');
    }

    // originClassName so the log points at the trigger handler that drove the restart, not at this
    // shared class.
    private static void logRestartFailure(Exception e, String objectName, String methodName, String originClassName) {
        DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
            e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
            originClassName, methodName, 'DMT', objectName
        ));
    }

    // Records restarted synchronously per transaction. Each one costs ~4 DML statements in
    // restartTasksForRecord against the shared 150 ceiling; at or above this the whole batch goes
    // async, which gets a fresh budget. Lower this as more child sections add per-record queries.
    private static final Integer SYNC_RESTART_RECORD_LIMIT = 35;

    // Implemented by DMT_SnapshotChildComparator. Returns true when a record's child rows no
    // longer match the frozen snapshot.
    public interface SnapshotChildComparator {
        Boolean hasChanges(Id recordId, Map<String, Object> snapshotJson);
    }

    /**
     * One child-record section of a snapshot: where the child rows live and how to reach them from
     * the record being watched. Declared by the component's own renderer - see
     * DMT_MultiObjectFieldTrackableRenderer.getChildSections().
     *
     * @param componentName      DMT_Items__c component supplying the fields ('Client', 'Products', ...)
     * @param snapshotSectionKey key holding these rows in DMT_ViewFieldStatusAtClose__c
     *                           (must match DMT_ApprovalChangeStep_Handler.SNAPSHOT_SECTION_TO_OBJECT)
     * @param childObjectApiName child SObject; also the key its fields sit under in getTrackedFieldsByObject()
     * @param childLookupField   field on the CHILD pointing back at the parent value
     * @param parentValueField   field on the PARENT holding the value to match. 'Id' for a direct
     *                           child; a lookup when the rows hang off an intermediate record, as a
     *                           Line's Client rows do via DMT_Line__c.Custom_Association__c
     */
    public class ChildSection {
        public final String componentName;
        public final String snapshotSectionKey;
        public final String childObjectApiName;
        public final String childLookupField;
        public final String parentValueField;

        public ChildSection(String componentName, String snapshotSectionKey, String childObjectApiName,
                            String childLookupField, String parentValueField) {
            this.componentName = componentName;
            this.snapshotSectionKey = snapshotSectionKey;
            this.childObjectApiName = childObjectApiName;
            this.childLookupField = childLookupField;
            this.parentValueField = parentValueField;
        }
    }

    /**
     * The shared watch gate. Finds the open approval Tasks for these Cases, compares each Task's
     * frozen snapshot against the record's current tracked fields, and restarts whatever is stale.
     *
     * Object-agnostic - both trigger handlers call this. Each caller keeps only what is genuinely
     * object-specific: which records qualify, and querying their Cases.
     *
     * Failures are caught and logged per task, so one bad snapshot never skips the rest and never
     * rolls back the save that triggered it.
     *
     * @param caseIdToRecordId   Case Id -> owning DMT_Line__c/Opportunity Id
     * @param records            the qualifying records as loaded by the trigger (Trigger.new)
     * @param snapshotSectionKey snapshot section holding this object's frozen fields ('line' or 'opportunity')
     * @param childComparator    child-record comparison, or null if this object has none
     * @param originClassName    calling class, for the failure log
     */
    public static void restartStaleApprovalTasks(
        Map<Id, Id> caseIdToRecordId,
        List<SObject> records,
        String snapshotSectionKey,
        SnapshotChildComparator childComparator,
        String originClassName
    ) {
        try {
            if (caseIdToRecordId == null || caseIdToRecordId.isEmpty() || records == null || records.isEmpty()) {
                return;
            }

            Map<Id, Task> tasksByViewStatusId = getRestartableTasks(caseIdToRecordId.keySet());
            if (tasksByViewStatusId.isEmpty()) {
                return;
            }

            Map<Id, DMT_TaskStatusWhenCompleted__c> snapshotsById = getSnapshots(tasksByViewStatusId.keySet());
            // Takes List<SObject>, not Map<Id, SObject>: List<DMT_Line__c> assigns to List<SObject>
            // in Apex, but Map<Id, DMT_Line__c> does not assign to Map<Id, SObject>.
            Map<Id, SObject> recordsById = new Map<Id, SObject>(recalculateFormulaFields(records, originClassName));

            // Grouped by record so each record's restarts stay one isolated DML group.
            Map<Id, List<Task>> tasksToRestartByRecordId = new Map<Id, List<Task>>();
            for (Task task : tasksByViewStatusId.values()) {
                try {
                    if (isTaskStale(task, snapshotsById, caseIdToRecordId, recordsById, snapshotSectionKey, childComparator)) {
                        Id recordId = caseIdToRecordId.get(task.WhatId);
                        if (!tasksToRestartByRecordId.containsKey(recordId)) {
                            tasksToRestartByRecordId.put(recordId, new List<Task>());
                        }
                        tasksToRestartByRecordId.get(recordId).add(task);
                    }
                } catch (Exception e) {
                    logRestartFailure(e, 'Task', 'restartStaleApprovalTasks', originClassName);
                }
            }

            dispatchRestarts(tasksToRestartByRecordId);
        } catch (Exception e) {
            logRestartFailure(e, 'Task', 'restartStaleApprovalTasks', originClassName);
        }
    }

    /**
     * Re-evaluates formula fields in memory before comparing. A formula on Trigger.new still holds
     * the value computed BEFORE this save, so a tracked formula whose inputs just changed would
     * compare as unchanged and never restart the task. DMT_Line__c.Client_Type__c and
     * Opportunity.DMT_Tenor__c are both tracked formulas.
     *
     * Operates on CLONES because Trigger.new is read-only in the after-update context this runs in.
     * Ids are preserved so the caller's map keys still line up. Costs no SOQL and no DML.
     */
    private static List<SObject> recalculateFormulaFields(List<SObject> records, String originClassName) {
        List<SObject> recalculated = new List<SObject>();
        for (SObject record : records) {
            recalculated.add(record.clone(true, true, false, false));
        }
        try {
            Formula.recalculateFormulas(recalculated);
        } catch (Exception e) {
            logRestartFailure(e, 'Formula', 'recalculateFormulaFields', originClassName);
            return records;
        }
        return recalculated;
    }

    private static Map<Id, Task> getRestartableTasks(Set<Id> caseIds) {
        Map<Id, Task> tasksByViewStatusId = new Map<Id, Task>();
        for (Task t : [
            // createResetTask() clones these records, and clone() only carries queried fields -
            // keep RecordTypeId and DMT_Task_Type__c in this SELECT.
            SELECT Id, WhatId, OwnerId, DMT_ViewStatusAtClose__c, DMT_Task_Type__c, RecordTypeId
            FROM Task
            WHERE WhatId IN :caseIds
            AND Status != :DMT_Constants.CANCELLED
            AND DMT_Not_Restart__c = false
        ]) {
            if (t.DMT_ViewStatusAtClose__c != null) {
                tasksByViewStatusId.put(t.DMT_ViewStatusAtClose__c, t);
            }
        }
        return tasksByViewStatusId;
    }

    private static Map<Id, DMT_TaskStatusWhenCompleted__c> getSnapshots(Set<Id> viewStatusIds) {
        return new Map<Id, DMT_TaskStatusWhenCompleted__c>([
            SELECT Id, DMT_ViewFieldStatusAtClose__c
            FROM DMT_TaskStatusWhenCompleted__c
            WHERE Id IN :viewStatusIds
        ]);
    }

    // True when the frozen snapshot no longer matches the record's current tracked fields, or its
    // child rows. Returns false (never restart) when the snapshot is missing, blank, or has no
    // section for this object, so older snapshots can't trigger a wave of spurious restarts.
    private static Boolean isTaskStale(
        Task task,
        Map<Id, DMT_TaskStatusWhenCompleted__c> snapshotsById,
        Map<Id, Id> caseIdToRecordId,
        Map<Id, SObject> recordsById,
        String snapshotSectionKey,
        SnapshotChildComparator childComparator
    ) {
        DMT_TaskStatusWhenCompleted__c snapshot = snapshotsById.get(task.DMT_ViewStatusAtClose__c);
        Id recordId = caseIdToRecordId.get(task.WhatId);
        if (snapshot == null || String.isBlank(snapshot.DMT_ViewFieldStatusAtClose__c) || recordId == null) {
            return false;
        }

        SObject record = recordsById.get(recordId);
        if (record == null) {
            return false;
        }

        Map<String, Object> snapshotJson = (Map<String, Object>) JSON.deserializeUntyped(snapshot.DMT_ViewFieldStatusAtClose__c);
        Map<String, Object> frozenFields = (Map<String, Object>) snapshotJson.get(snapshotSectionKey);
        if (frozenFields == null) {
            return false;
        }

        // Serialize/deserialize so both sides are JSON primitives. Comparing a native Date/Decimal
        // against its JSON-deserialized counterpart never returns equal via !=.
        Map<String, Object> liveFields = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(record));

        Id recordTypeId = (Id) record.get('RecordTypeId');
        for (String fieldName : DMT_RendererFactory.getTrackedFields(DMT_Constants.RENDERER_TRACKED_COMPONENTS, recordTypeId)) {
            if (liveFields.get(fieldName) != frozenFields.get(fieldName)) {
                return true;
            }
        }

        // Child-record fields don't live on the record, so they're compared separately.
        if (childComparator != null) {
            return childComparator.hasChanges(recordId, snapshotJson);
        }
        return false;
    }

    private static void dispatchRestarts(Map<Id, List<Task>> tasksToRestartByRecordId) {
        if (tasksToRestartByRecordId.size() < SYNC_RESTART_RECORD_LIMIT) {
            for (Id recordId : tasksToRestartByRecordId.keySet()) {
                restartTasksForRecord(recordId, tasksToRestartByRecordId.get(recordId));
            }
        } else {
            for (Id recordId : tasksToRestartByRecordId.keySet()) {
                DMT_AsyncOrchestrator.enqueue(new DMT_RestartApprovalTasksPayload(recordId, tasksToRestartByRecordId.get(recordId)));
            }
        }
    }

    /**
     * Row-matching rule for a snapshot's child-record sections. A different row count or a
     * different set of row Ids means a row was added or removed - a difference in itself. Otherwise
     * each matching row's tracked fields are compared.
     *
     * Both arguments must already be JSON-primitive shaped (from JSON.deserializeUntyped), not raw
     * SObjects - see the note in isTaskStale().
     */
    public static Boolean rowsDiffer(Map<String, Object> frozenRows, Map<String, Object> liveRows, List<String> trackedFields) {
        if (liveRows == null) {
            liveRows = new Map<String, Object>();
        }
        if (frozenRows.size() != liveRows.size() || !frozenRows.keySet().equals(liveRows.keySet())) {
            return true;
        }
        for (String recordId : frozenRows.keySet()) {
            Map<String, Object> frozenRow = (Map<String, Object>) frozenRows.get(recordId);
            Map<String, Object> liveRow = (Map<String, Object>) liveRows.get(recordId);
            for (String fieldName : trackedFields) {
                if (frozenRow.get(fieldName) != liveRow.get(fieldName)) {
                    return true;
                }
            }
        }
        return false;
    }
}