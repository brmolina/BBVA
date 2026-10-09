/**
 * Approval-task restart ("case reopen") framework.
 *
 * Three entry points:
 *   restartStaleApprovalTasks()       - the shared watch gate. Both trigger handlers call it to
 *                                       work out which open approval Tasks are stale and restart
 *                                       them, via the cheap synchronous SObject-field comparison.
 *   restartTasksForRecord()           - the DML step: cancel, recreate, reset the Case. Also reused
 *                                       by DMT_AsyncDispatcher for the async path.
 *   checkCalloutTrackableComponent()  - the async fallback for data sourced from a live
 *                                       external service callout, never a persisted field. Callouts
 *                                       are illegal in the trigger context restartStaleApprovalTasks
 *                                       runs in, so this only ever runs from DMT_AsyncDispatcher,
 *                                       and only after the synchronous comparison found no change
 *                                       (local-first, callout as fallback) - see
 *                                       enqueueCalloutTrackableChecks().
 *
 * Which fields are watched is never defined here. It comes from the renderers via
 * DMT_RendererFactory - see DMT_ClientRenderer for the maintenance rules.
 *
 * CIBGLOBALD-4117: which components are even eligible for a given task is scoped per snapshot via
 * DMT_TaskStatusWhenCompleted__c.DMT_TrackedComponents__c - see trackedComponentsForSnapshot().
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
     * Cancels the stale tasks for ONE record and resets the related Cases, as a single
     * all-or-nothing group. recordId is a DMT_Line__c or an Opportunity Id - there is no
     * object-specific logic here.
     * CIBGLOBALD-4117 - every stale task passed in gets cancelled, but exactly ONE replacement task
     * is created per Case (cloned from that Case's oldest stale task), even when several of that
     * Case's tasks were independently found stale. Previously created one replacement per
     * cancelled task, flooding the Case with duplicates whenever more than one of its tasks went
     * stale at once.
     * Savepoint is per record on purpose: a failure rolls back only this record's restarts, never
     * another record's, and never the save that triggered it.
     */
    public static void restartTasksForRecord(Id recordId, List<Task> tasksToRestart) {
        Savepoint sp = Database.setSavepoint();
        try {
            // Keyed by Case Id because several stale tasks can share one Case, and a bulk update
            // containing the same Id twice throws "Duplicate id in list". Every task for a Case
            // gets cancelled, but only ONE replacement is created per Case - cloned from that
            // Case's oldest stale task - not one replacement per cancelled task.
            Map<Id, Case> casesToResetByCaseId = new Map<Id, Case>();
            Map<Id, Task> oldestTaskByCaseId = new Map<Id, Task>();
            for (Task task : tasksToRestart) {
                task.Status = DMT_Constants.CANCELLED;
                Case resetCase = createResetCase(task.WhatId, task.OwnerId);
                casesToResetByCaseId.put(resetCase.Id, resetCase);

                Task oldestSoFar = oldestTaskByCaseId.get(task.WhatId);
                if (oldestSoFar == null || task.CreatedDate < oldestSoFar.CreatedDate) {
                    oldestTaskByCaseId.put(task.WhatId, task);
                }
            }
            List<Task> tasksToCreate = new List<Task>();
            for (Task oldestTask : oldestTaskByCaseId.values()) {
                tasksToCreate.add(createResetTask(oldestTask));
            }
            Database.update(tasksToRestart, AccessLevel.SYSTEM_MODE);
            Database.insert(tasksToCreate, AccessLevel.SYSTEM_MODE);
            Database.update(casesToResetByCaseId.values(), AccessLevel.SYSTEM_MODE);

            // CIBGLOBALD-4617 - no explicit event here anymore: the cancelled and the replacement
            // Tasks go through Task.trigger -> DTM_Task_Helper, which already publishes one
            // DMT_Task__e keyed by this Line / Opportunity Id, so open Passports refresh the traffic
            // light without a second event.
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
    // restartTasksForRecord against the shared 150 ceiling - at 35 that was already ~140,
    // dangerously close before counting whatever else the same trigger transaction does (other
    // Opportunity/Line trigger logic, future additions to restartTasksForRecord itself). Lowered
    // to 10 (2026-09-22) for a real safety margin as this framework keeps growing - correctness is
    // unaffected either way, since 10+ just means the exact same restartTasksForRecord call
    // happens a few seconds later via the async path instead of inline.
    private static final Integer SYNC_RESTART_RECORD_LIMIT = 10;

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
     * @param childObjectApiName child SObject; also the key its fields sit under in getTrackedFieldsByObject()
     * @param childLookupField   field on the CHILD pointing back at the parent value
     * @param parentValueField   field on the PARENT holding the value to match. 'Id' for a direct
     *                           child; a lookup when the rows hang off an intermediate record, as a
     *                           Line's Client rows do via DMT_Line__c.Custom_Association__c
     * @param orderBy            SQL ORDER BY clause for the child query
     */
    public class ChildSection {
        public final String componentName;
        public final String snapshotSectionKey;
        public final String childObjectApiName;
        public final String childLookupField;
        public final String parentValueField;
        public final String orderBy;

        public ChildSection(String componentName, String snapshotSectionKey, String childObjectApiName,
                            String childLookupField, String parentValueField) {
            this(componentName, snapshotSectionKey, childObjectApiName, childLookupField, parentValueField, null);
        }

        public ChildSection(String componentName, String snapshotSectionKey, String childObjectApiName,
                            String childLookupField, String parentValueField, String orderBy) {
            this.componentName = componentName;
            this.snapshotSectionKey = snapshotSectionKey;
            this.childObjectApiName = childObjectApiName;
            this.childLookupField = childLookupField;
            this.parentValueField = parentValueField;
            this.orderBy = orderBy;
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
            Map<Id, SObject> recordsById = new Map<Id, SObject>(cloneRecords(records));
            mergeRelationshipFields(recordsById, originClassName);

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
                    } else {
                        enqueueCalloutTrackableChecks(task, snapshotsById, caseIdToRecordId);
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

    // Clones so mergeRelationshipFields can call SObject.putSObject() on them - Trigger.new records
    // are read-only for field writes in an after-update context, which is the only context this
    // runs in. Ids are preserved so the caller's map keys still line up.
    private static List<SObject> cloneRecords(List<SObject> records) {
        List<SObject> cloned = new List<SObject>();
        for (SObject record : records) {
            cloned.add(record.clone(true, true, false, false));
        }
        return cloned;
    }

    // CIBGLOBALD-4117 - populates relationship-traversal fields ('Client__r.Name') Trigger.new does
    // not carry.
    private static void mergeRelationshipFields(Map<Id, SObject> recordsById, String originClassName) {
        if (recordsById.isEmpty()) {
            return;
        }

        Map<String, Set<String>> fieldsByRelationship = new Map<String, Set<String>>();
        for (SObject record : recordsById.values()) {
            for (String fieldName : DMT_RendererFactory.getTrackedFields(DMT_RendererFactory.getTrackedComponentNames(), record)) {
                if (!fieldName.contains('.')) {
                    continue;
                }
                List<String> parts = fieldName.split('\\.', 2);
                String relationshipName = parts[0];
                if (!fieldsByRelationship.containsKey(relationshipName)) {
                    fieldsByRelationship.put(relationshipName, new Set<String>());
                }
                fieldsByRelationship.get(relationshipName).add(parts[1]);
            }
        }
        if (fieldsByRelationship.isEmpty()) {
            return;
        }

        String objectApiName = recordsById.values()[0].getSObjectType().getDescribe().getName();
        try {
            List<String> selectFields = new List<String>{ 'Id' };
            for (String relationshipName : fieldsByRelationship.keySet()) {
                for (String relatedField : fieldsByRelationship.get(relationshipName)) {
                    selectFields.add(relationshipName + '.' + relatedField);
                }
            }
            Set<Id> recordIds = recordsById.keySet();
            String query = 'SELECT ' + String.join(selectFields, ', ') + ' FROM ' + objectApiName + ' WHERE Id IN :recordIds';
            for (SObject queried : Database.query(String.escapeSingleQuotes(query))) {
                SObject record = recordsById.get((Id) queried.get('Id'));
                for (String relationshipName : fieldsByRelationship.keySet()) {
                    SObject related = queried.getSObject(relationshipName);
                    if (related != null) {
                        record.putSObject(relationshipName, related);
                    }
                }
            }
        } catch (Exception e) {
            logRestartFailure(e, objectApiName, 'mergeRelationshipFields', originClassName);
        }
    }

    private static Map<Id, Task> getRestartableTasks(Set<Id> caseIds) {
        Map<Id, Task> tasksByViewStatusId = new Map<Id, Task>();
        for (Task t : [
            // createResetTask() clones these records, and clone() only carries queried fields -
            // keep RecordTypeId and DMT_Task_Type__c in this SELECT. CreatedDate is needed by
            // restartTasksForRecord to pick the single oldest task per Case to clone.
            SELECT Id, WhatId, OwnerId, DMT_ViewStatusAtClose__c, DMT_Task_Type__c, RecordTypeId, CreatedDate
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
            SELECT Id, DMT_ViewFieldStatusAtClose__c, DMT_TrackedComponents__c
            FROM DMT_TaskStatusWhenCompleted__c
            WHERE Id IN :viewStatusIds
        ]);
    }

    // CIBGLOBALD-4117 - components to compare for one snapshot, scoped to DMT_TrackedComponents__c.
    @TestVisible
    private static List<String> trackedComponentsForSnapshot(DMT_TaskStatusWhenCompleted__c snapshot) {
        if (String.isBlank(snapshot.DMT_TrackedComponents__c)) {
            return DMT_RendererFactory.getTrackedComponentNames();
        }
        List<String> scopedComponents = new List<String>();
        for (String componentName : snapshot.DMT_TrackedComponents__c.split(';', 0)) {
            if (DMT_RendererFactory.getTrackedComponentNames().contains(componentName)) {
                scopedComponents.add(componentName);
            }
        }
        return scopedComponents;
    }

    // CIBGLOBALD-4117 - local-first, callout-as-fallback: only reached when the cheap,
    // synchronous SObject-field comparison above found no change for this task. Callouts are
    // illegal here (trigger context), so any callout-tracked component the task's view has is
    // deferred to DMT_AsyncDispatcher via the same async orchestrator used for the sync-limit
    // overflow case - see checkCalloutTrackableComponent() for the async side.
    // CIBGLOBALD-4117 - enqueues a single chain starter, not one payload per callout-trackable
    // component - see DMT_CalloutTrackableCheckPayload's header.
    private static void enqueueCalloutTrackableChecks(
        Task task,
        Map<Id, DMT_TaskStatusWhenCompleted__c> snapshotsById,
        Map<Id, Id> caseIdToRecordId
    ) {
        DMT_TaskStatusWhenCompleted__c snapshot = snapshotsById.get(task.DMT_ViewStatusAtClose__c);
        Id recordId = caseIdToRecordId.get(task.WhatId);
        if (snapshot == null || String.isBlank(snapshot.DMT_ViewFieldStatusAtClose__c) || recordId == null) {
            return;
        }
        List<String> calloutTrackableComponents = new List<String>();
        for (String componentName : trackedComponentsForSnapshot(snapshot)) {
            if (DMT_RendererFactory.isCalloutTrackable(componentName)) {
                calloutTrackableComponents.add(componentName);
            }
        }
        if (calloutTrackableComponents.isEmpty()) {
            return;
        }
        // Apex's List has no subList() - build the tail manually.
        List<String> remaining = new List<String>();
        for (Integer i = 1; i < calloutTrackableComponents.size(); i++) {
            remaining.add(calloutTrackableComponents[i]);
        }
        DMT_AsyncOrchestrator.enqueue(new DMT_CalloutTrackableCheckPayload(recordId, task.Id, calloutTrackableComponents[0], remaining));
    }

    /**
     * CIBGLOBALD-4117 - async half of capturing a callout-tracked baseline. Runs from
     * DMT_AsyncDispatcher (Batchable/Queueable context, callouts always allowed there), so it never
     * hits "uncommitted work pending" regardless of what the freeze caller's own transaction already
     * did - a real production case (the ApprovalChangeStep integration procedure does DML before
     * invoking updateTaskWithStatus) that no unit test calling updateTaskWithStatus directly could
     * ever have exercised. Merges the live fetch into the already-frozen snapshot's
     * calloutTrackedValues section and updates it - a short window where the snapshot has no
     * baseline yet is harmless, since the watch gate only ever reads it on a later, separate save.
     */
    public static void freezeCalloutTrackableBaseline(DMT_CalloutTrackableFreezePayload payload) {
        DMT_CalloutTrackableRenderer renderer = DMT_RendererFactory.getCalloutTrackableRenderer(payload.componentName);
        if (renderer == null) {
            return;
        }

        DMT_TaskStatusWhenCompleted__c snapshot = [
            SELECT Id, DMT_ViewFieldStatusAtClose__c
            FROM DMT_TaskStatusWhenCompleted__c
            WHERE Id = :payload.snapshotId
        ];
        if (String.isBlank(snapshot.DMT_ViewFieldStatusAtClose__c)) {
            return;
        }

        Map<String, Object> snapshotJson = (Map<String, Object>) JSON.deserializeUntyped(snapshot.DMT_ViewFieldStatusAtClose__c);
        Map<String, Object> calloutTrackedValuesByComponent = (Map<String, Object>) snapshotJson.get('calloutTrackedValues');
        if (calloutTrackedValuesByComponent == null) {
            calloutTrackedValuesByComponent = new Map<String, Object>();
            snapshotJson.put('calloutTrackedValues', calloutTrackedValuesByComponent);
        }

        SObject recordShell = payload.recordId.getSObjectType().newSObject(payload.recordId);
        calloutTrackedValuesByComponent.put(payload.componentName, renderer.fetchLiveTrackedValues(recordShell));

        snapshot.DMT_ViewFieldStatusAtClose__c = JSON.serialize(snapshotJson);
        update snapshot;
    }

    /**
     * CIBGLOBALD-4117 - async half of the callout-tracked check. Runs from
     * DMT_AsyncDispatcher (Batchable/Queueable context, callouts allowed), never from a trigger.
     * Re-fetches the frozen callout-tracked values from the snapshot and compares them against a
     * fresh live fetch; restarts the one task this payload was raised for if they differ.
     */
    public static void checkCalloutTrackableComponent(DMT_CalloutTrackableCheckPayload payload) {
        // CIBGLOBALD-4117 - a component's own fetchLiveTrackedValues() (or the SOQL above it) can
        // throw for reasons that have nothing to do with the remaining components in the chain (a
        // transient callout/limit issue, a bug in one renderer). DMT_AsyncQueueJob.execute() already
        // catches and logs whatever escapes this method, but it never resumes the chain on our
        // behalf - so without this try/catch, one failing component silently strands every component
        // listed after it for this restart cycle, found live 2026-09-25 on the first 5-long chain
        // (see project memory: chain stalled after 3 of 5 hops, twice, no error surfaced on the job).
        // Logging + continuing here matches this method's own no-renderer/no-baseline branches, which
        // already treat "can't compare this one" as a reason to move on, never to stop.
        try {
            checkCalloutTrackableComponentOrThrow(payload);
        } catch (Exception e) {
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
                'DMT_ApprovalChangeStep_Helper', 'checkCalloutTrackableComponent', 'DMT', payload.componentName
            ));
            continueCalloutTrackableCheckChain(payload);
        }
    }

    // CIBGLOBALD-4117 - test-only seam to simulate one specific component's check throwing mid-chain,
    // so a test can prove the chain still reaches whatever component was listed after it.
    @TestVisible private static String forceExceptionForComponentNameForTest = null;

    private static void checkCalloutTrackableComponentOrThrow(DMT_CalloutTrackableCheckPayload payload) {
        if (Test.isRunningTest() && payload.componentName == forceExceptionForComponentNameForTest) {
            throw new AuraHandledException('CIBGLOBALD-4117 forced test exception for ' + payload.componentName);
        }
        DMT_CalloutTrackableRenderer renderer = DMT_RendererFactory.getCalloutTrackableRenderer(payload.componentName);
        if (renderer == null) {
            continueCalloutTrackableCheckChain(payload);
            return;
        }

        List<Task> tasks = [
            SELECT Id, WhatId, OwnerId, DMT_ViewStatusAtClose__c, DMT_Task_Type__c, RecordTypeId
            FROM Task
            WHERE Id = :payload.taskId AND Status != :DMT_Constants.CANCELLED AND DMT_Not_Restart__c = false
        ];
        if (tasks.isEmpty() || tasks[0].DMT_ViewStatusAtClose__c == null) {
            return;
        }
        Task task = tasks[0];

        DMT_TaskStatusWhenCompleted__c snapshot = [
            SELECT Id, DMT_ViewFieldStatusAtClose__c
            FROM DMT_TaskStatusWhenCompleted__c
            WHERE Id = :task.DMT_ViewStatusAtClose__c
        ];
        if (String.isBlank(snapshot.DMT_ViewFieldStatusAtClose__c)) {
            return;
        }

        Map<String, Object> snapshotJson = (Map<String, Object>) JSON.deserializeUntyped(snapshot.DMT_ViewFieldStatusAtClose__c);
        Map<String, Object> calloutTrackedValuesByComponent = (Map<String, Object>) snapshotJson.get('calloutTrackedValues');
        Map<String, Object> frozenValues = calloutTrackedValuesByComponent != null
            ? (Map<String, Object>) calloutTrackedValuesByComponent.get(payload.componentName)
            : null;
        // No frozen baseline for this component (e.g. it was frozen before this POC existed, or by
        // a freeze path that doesn't capture callout data yet) - nothing to compare against, so
        // this never restarts. Same "err toward no false restart on missing data" rule as isTaskStale.
        if (frozenValues == null) {
            continueCalloutTrackableCheckChain(payload);
            return;
        }

        SObject recordShell = payload.recordId.getSObjectType().newSObject(payload.recordId);
        Map<String, Object> liveValues = renderer.fetchLiveTrackedValues(recordShell);
        // Serialize/deserialize so both sides are JSON primitives - same discipline as isTaskStale,
        // comparing a native Date/Decimal against its JSON-deserialized counterpart never returns
        // equal via !=.
        Map<String, Object> liveValuesAsJson = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(liveValues));

        for (String fieldName : frozenValues.keySet()) {
            if (normalizeBlank(frozenValues.get(fieldName)) != normalizeBlank(liveValuesAsJson.get(fieldName))) {
                restartTasksForRecord(payload.recordId, new List<Task>{ task });
                // CIBGLOBALD-4117 - abort the chain: this task is already restarting.
                return;
            }
        }

        continueCalloutTrackableCheckChain(payload);
    }

    // CIBGLOBALD-4117 - advances the chain to the next component, each hop in its own transaction -
    // see DMT_CalloutTrackableCheckPayload's header.
    private static void continueCalloutTrackableCheckChain(DMT_CalloutTrackableCheckPayload payload) {
        if (payload.remainingComponentNames.isEmpty()) {
            return;
        }
        // Apex's List has no subList() - build the tail manually.
        List<String> nextRemaining = new List<String>();
        for (Integer i = 1; i < payload.remainingComponentNames.size(); i++) {
            nextRemaining.add(payload.remainingComponentNames[i]);
        }
        DMT_AsyncOrchestrator.enqueue(new DMT_CalloutTrackableCheckPayload(
            payload.recordId, payload.taskId, payload.remainingComponentNames[0], nextRemaining
        ));
        DMT_AsyncOrchestrator.flush();
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

        for (String fieldName : DMT_RendererFactory.getTrackedFields(trackedComponentsForSnapshot(snapshot), record)) {
            if (valueAt(liveFields, fieldName) != valueAt(frozenFields, fieldName)) {
                return true;
            }
        }

        // Child-record fields don't live on the record, so they're compared separately.
        if (childComparator != null) {
            return childComparator.hasChanges(recordId, snapshotJson);
        }
        return false;
    }

    // CIBGLOBALD-4117 - reads a tracked field's value from a JSON-primitive-shaped map.
    private static Object valueAt(Map<String, Object> fields, String fieldName) {
        Object value;
        if (!fieldName.contains('.')) {
            value = fields.get(fieldName);
        } else {
            List<String> parts = fieldName.split('\\.', 2);
            Object nested = fields.get(parts[0]);
            value = (nested instanceof Map<String, Object>) ? ((Map<String, Object>) nested).get(parts[1]) : null;
        }
        return normalizeBlank(value);
    }

    // CIBGLOBALD-4117 - blank strings normalize to null before any comparison in this class.
    private static Object normalizeBlank(Object value) {
        return (value instanceof String && String.isBlank((String) value)) ? null : value;
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

    // CIBGLOBALD-4117 - row-matching rule for a snapshot's child-record sections.
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
                if (normalizeBlank(frozenRow.get(fieldName)) != normalizeBlank(liveRow.get(fieldName))) {
                    return true;
                }
            }
        }
        return false;
    }
}