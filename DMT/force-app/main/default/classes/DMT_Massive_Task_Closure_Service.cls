/**
 * CIBGLOBALD-4117 - bulkified entry point for closing multiple approval tasks/cases at once (the
 * massive-closure modal):
 *
 *   1. Resolve tracked fields     - DMT_ApprovalChangeStep_Handler.resolveTrackedFieldsForItems/
 *                                    resolveChildSectionsForItems
 *   2. Build the snapshot JSON    - DMT_TaskSnapshotService.buildSnapshotJson
 *   3. Record the decision        - DMT_TaskCompletionService
 *   4. Finish other open tasks    - DMT_RelatedTaskFinisherService
 *   5. Close the case             - DMT_CaseClosureService
 *   6. Move Line/Opp to Draft     - DMT_DraftStatusService (only when requested)
 *   7. Move documents to the task - DMT_DocumentTransferService, async via DMT_AsyncOrchestrator
 *   8. Stamp business-approver date - DMT_CaseOwnerType_Handler.getOwnerCaseTypes
 **/
public without sharing class DMT_Massive_Task_Closure_Service {

    // ─────────────────────────────────────────────────────────────────────────
    // Public data contracts (exposed to @AuraEnabled controller)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * One item per selected task coming from the LWC modal component.
     * taskId / caseId: record identifiers.
     * result   : resolved label (Yes/No/N/A) → stored in Task.DMT_Step_Result__c.
     * comments : free text                   → stored in Task.Description.
     */
    public class ClosurePayload {
        @AuraEnabled public Id     taskId;
        @AuraEnabled public Id     caseId;
        @AuraEnabled public String result;
        @AuraEnabled public String comments;
        @AuraEnabled public String committeeLabel;
        @AuraEnabled public Boolean updateToDraft;
    }

    /** Light result envelope returned to the LWC. */
    public class ClosureResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String  errorMessage;
        public ClosureResult() { this.success = true; }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Entry point
    // ─────────────────────────────────────────────────────────────────────────

    public static ClosureResult confirmMassiveClosure(List<ClosurePayload> payloads) {
        ClosureResult closureResult = new ClosureResult();
        try {
            if (payloads == null || payloads.isEmpty()) {
                throw new AuraHandledException('No tasks were provided for massive closure.');
            }

            // ── 1. Collect IDs ────────────────────────────────────────────
            Set<Id> taskIds  = new Set<Id>();
            Set<Id> caseIds  = new Set<Id>();
            Map<Id, ClosurePayload> payloadByTaskId = new Map<Id, ClosurePayload>();
            Boolean shouldUpdateToDraft = false;
            // First task selected per case (used for doc re-linking)
            Map<Id, Id> taskIdByCaseId = new Map<Id, Id>();

            for (ClosurePayload p : payloads) {
                if (p == null || p.taskId == null) {
                    continue;
                }

                taskIds.add(p.taskId);
                payloadByTaskId.put(p.taskId, p);
                if (p.updateToDraft == true) {
                    shouldUpdateToDraft = true;
                }

                if (p.caseId == null) {
                    continue;
                }

                caseIds.add(p.caseId);
                if (!taskIdByCaseId.containsKey(p.caseId)) {
                    taskIdByCaseId.put(p.caseId, p.taskId);
                }
            }

            if (taskIds.isEmpty()) {
                throw new AuraHandledException('No valid task IDs were provided for massive closure.');
            }

            // ── 2. Query tasks & cases ────────────────────────────────────
            Map<Id, Task> taskMap = new Map<Id, Task>([
                SELECT Id, OwnerId, WhatId, DMT_Task_Type__c, DMT_ViewStatusAtClose__c,
                       DMT_Step_Result__c, Description, Status, Subject,
                       RecordTypeId, DMT_Not_Restart__c
                FROM Task
                WHERE Id IN :taskIds
                WITH SYSTEM_MODE
            ]);

            for (Task t : taskMap.values()) {
                caseIds.add(t.WhatId);
                if (!taskIdByCaseId.containsKey(t.WhatId)) {
                    taskIdByCaseId.put(t.WhatId, t.Id);
                }
            }

            if (caseIds.isEmpty()) {
                throw new AuraHandledException('No valid case IDs were found for the selected tasks.');
            }

            // CIBGLOBALD-4117 - shared with the single-task freeze path (updateTaskWithStatus) and the
            // preview path (previewCompareTasksFromCase) via DMT_ApprovalChangeStep_Selector, instead
            // of a third hand-maintained copy of this query.
            Map<Id, Case> caseMap = DMT_ApprovalChangeStep_Selector.getCasesByIds(caseIds);

            // ── 3. Resolve Group → Approver → View ───────────────────────
            Set<Id> ownerIds = new Set<Id>();
            for (Task t : taskMap.values()) {
                if (t.OwnerId != null) ownerIds.add(t.OwnerId);
            }

            Map<Id, Group> groupById = new Map<Id, Group>([
                SELECT Id, DeveloperName
                FROM Group
                WHERE Type = :DMT_Constants.TYPE_GROUP_QUEUE
                  AND Id IN :ownerIds
                WITH SYSTEM_MODE
            ]);

            Set<String> groupNames = new Set<String>();
            for (Group g : groupById.values()) groupNames.add(g.DeveloperName);

            Map<String, DMT_Approver__c> approverByGroup = new Map<String, DMT_Approver__c>();
            for (DMT_Approver__c a : [
                SELECT Id, Approvers_View__c, Approvers_View_Treasury__c,
                       Approvers_View_Opportunity__c, DMT_Group__c,
                       DMT_ApproverType__r.Name
                FROM DMT_Approver__c
                WHERE DMT_Group__c IN :groupNames
                WITH SYSTEM_MODE
            ]) {
                approverByGroup.put(a.DMT_Group__c, a);
            }

            // ── 4. Determine view ID per task ─────────────────────────────
            Map<Id, Id> viewIdByTaskId = new Map<Id, Id>();
            Set<Id>     allViewIds     = new Set<Id>();

            for (Task t : taskMap.values()) {
                Case c           = caseMap.get(t.WhatId);
                Group g          = groupById.get(t.OwnerId);
                if (c == null || g == null) continue;
                DMT_Approver__c approver = approverByGroup.get(g.DeveloperName);
                if (approver == null) continue;
                Id viewId = DMT_ApprovalChangeStep_Handler.resolveApproverViewId(approver, c);
                if (viewId != null) {
                    viewIdByTaskId.put(t.Id, viewId);
                    allViewIds.add(viewId);
                }
            }

            // ── 5. One query for all DMT_Items__c across all views ────────
            Map<Id, List<DMT_Items__c>> itemsByViewId = new Map<Id, List<DMT_Items__c>>();
            for (DMT_Items__c item : [
                SELECT Id, DMT_Component_Item__c, DMT_View__c
                FROM DMT_Items__c
                WHERE DMT_View__c IN :allViewIds
                WITH SYSTEM_MODE
                ORDER BY Name ASC
            ]) {
                if (!itemsByViewId.containsKey(item.DMT_View__c)) {
                    itemsByViewId.put(item.DMT_View__c, new List<DMT_Items__c>());
                }
                itemsByViewId.get(item.DMT_View__c).add(item);
            }

            // ── 6. Resolve tracked fields and child sections per (view, record type) ──
            Map<String, DMT_ApprovalChangeStep_Handler.ItemFieldResolution> resolutionByKey = new Map<String, DMT_ApprovalChangeStep_Handler.ItemFieldResolution>();
            Map<Id, String> resolutionKeyByTaskId = new Map<Id, String>();
            Map<String, Set<String>> mergedFieldMap = new Map<String, Set<String>>();
            Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> lineChildSectionsByKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
            Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> oppChildSectionsByKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();

            for (Task t : taskMap.values()) {
                Case c = caseMap.get(t.WhatId);
                Id viewId = viewIdByTaskId.get(t.Id);
                if (c == null || viewId == null) continue;

                SObject lineOrOpportunityRecord;
                Id recordTypeId;
                String sObjectApiName;
                String geography = null;
                if (c.DMT_LineOpportunity__c == 'L') {
                    lineOrOpportunityRecord = c.DMT_Line__r;
                    recordTypeId = c.DMT_Line__r.RecordTypeId;
                    sObjectApiName = 'DMT_Line__c';
                    geography = c.DMT_Line__r.Booking_Geography__c;
                } else {
                    lineOrOpportunityRecord = c.opportunity_id__r;
                    recordTypeId = c.opportunity_id__r.RecordTypeId;
                    sObjectApiName = 'Opportunity';
                }
                String resolutionKey = viewId + '_' + recordTypeId + '_' + geography;
                resolutionKeyByTaskId.put(t.Id, resolutionKey);

                if (!resolutionByKey.containsKey(resolutionKey)) {
                    List<DMT_Items__c> itemsForView = itemsByViewId.containsKey(viewId) ? itemsByViewId.get(viewId) : new List<DMT_Items__c>();

                    DMT_ApprovalChangeStep_Handler.ItemFieldResolution resolution = DMT_ApprovalChangeStep_Handler.resolveTrackedFieldsForItems(itemsForView, lineOrOpportunityRecord, sObjectApiName);
                    resolutionByKey.put(resolutionKey, resolution);
                    for (String obj : resolution.fieldMapFromObject.keySet()) {
                        if (!mergedFieldMap.containsKey(obj)) mergedFieldMap.put(obj, new Set<String>());
                        mergedFieldMap.get(obj).addAll(resolution.fieldMapFromObject.get(obj));
                    }

                    Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> targetSectionMap = sObjectApiName == 'DMT_Line__c' ? lineChildSectionsByKey : oppChildSectionsByKey;
                    for (DMT_ApprovalChangeStep_Helper.ChildSection section : DMT_ApprovalChangeStep_Handler.resolveChildSectionsForItems(itemsForView, lineOrOpportunityRecord).values()) {
                        if (!targetSectionMap.containsKey(section.snapshotSectionKey)) {
                            targetSectionMap.put(section.snapshotSectionKey, section);
                        }
                    }
                }
            }

            // ── 7. Collect parent IDs per domain ──────────────────────────
            Set<Id> lineIds       = new Set<Id>();
            Set<Id> oppIds        = new Set<Id>();
            Set<Id> customAssocIds = new Set<Id>();
            for (Case c : caseMap.values()) {
                if (c.DMT_LineOpportunity__c == 'L' && c.DMT_Line__c != null) {
                    lineIds.add(c.DMT_Line__c);
                }
                if (c.DMT_LineOpportunity__c == 'O' && c.opportunity_id__c != null) {
                    oppIds.add(c.opportunity_id__c);
                }
                if (c.DMT_Line__r?.Custom_Association__c != null) {
                    customAssocIds.add(c.DMT_Line__r.Custom_Association__c);
                }
            }

            // ── 8. Bulk queries – one per object type ─────────────────────
            Map<Id, SObject>       lineMap          = bulkQueryById(
                'DMT_Line__c', mergedFieldMap, lineIds);
            Map<Id, List<SObject>> customAssocMap   = bulkQueryByLookup(
                'Custom_Association_Client__c', mergedFieldMap, 'Custom_Association__c', customAssocIds, 'Name ASC');
            Map<Id, SObject>       oppMap           = bulkQueryById(
                'Opportunity', mergedFieldMap, oppIds);

            // CIBGLOBALD-4117 - one bulk query per renderer-declared ChildSection whose rows hang
            // directly off the parent's own Id, keyed by snapshotSectionKey.
            Map<String, Map<Id, List<SObject>>> childListsBySectionKey = new Map<String, Map<Id, List<SObject>>>();
            for (DMT_ApprovalChangeStep_Helper.ChildSection section : lineChildSectionsByKey.values()) {
                if (section.parentValueField != 'Id') continue;
                childListsBySectionKey.put(section.snapshotSectionKey,
                    bulkQueryByLookup(section.childObjectApiName, mergedFieldMap, section.childLookupField, lineIds, section.orderBy));
            }
            for (DMT_ApprovalChangeStep_Helper.ChildSection section : oppChildSectionsByKey.values()) {
                if (section.parentValueField != 'Id') continue;
                childListsBySectionKey.put(section.snapshotSectionKey,
                    bulkQueryByLookup(section.childObjectApiName, mergedFieldMap, section.childLookupField, oppIds, section.orderBy));
            }

            // ── 9. Build DMT_TaskStatusWhenCompleted__c records ───────────
            List<DMT_TaskStatusWhenCompleted__c> statusToInsert = new List<DMT_TaskStatusWhenCompleted__c>();
            List<DMT_TaskStatusWhenCompleted__c> statusToUpdate = new List<DMT_TaskStatusWhenCompleted__c>();
            // Tasks that need their DMT_ViewStatusAtClose__c populated after insert
            List<Id> taskIdsNeedingLink = new List<Id>();

            // CIBGLOBALD-4117 - callout-tracked values are never fetched synchronously here (a
            // callout right here would throw "uncommitted work pending" the moment any caller's own
            // transaction already did DML before reaching this bulk action - the exact failure a
            // production ApprovalChangeStep integration procedure call hit for updateTaskWithStatus,
            // 2026-09-23). Instead, each task's callout-trackable component names are tracked here
            // and a freeze baseline is enqueued per task after the snapshot DML below, once its real
            // snapshot Id is known - see freezeCalloutTrackableBaseline().
            Map<Id, List<String>> calloutComponentsByTaskId = new Map<Id, List<String>>();
            Map<Id, Id> recordIdByTaskId = new Map<Id, Id>();

            for (Task t : taskMap.values()) {
                Case c       = caseMap.get(t.WhatId);
                Id   viewId  = viewIdByTaskId.get(t.Id);
                if (c == null || viewId == null) continue;

                DMT_ApprovalChangeStep_Handler.ItemFieldResolution resolution = resolutionByKey.get(resolutionKeyByTaskId.get(t.Id));

                Id recordId = c.DMT_LineOpportunity__c == 'L' ? c.DMT_Line__c : c.opportunity_id__c;
                if (recordId != null) {
                    List<String> calloutComponents = new List<String>();
                    for (String componentName : resolution.trackedComponentNames) {
                        if (DMT_RendererFactory.isCalloutTrackable(componentName)) {
                            calloutComponents.add(componentName);
                        }
                    }
                    if (!calloutComponents.isEmpty()) {
                        calloutComponentsByTaskId.put(t.Id, calloutComponents);
                        recordIdByTaskId.put(t.Id, recordId);
                    }
                }

                String snapshotJson = DMT_TaskSnapshotService.buildSnapshotJson(
                    c, resolution.fieldMapFromObject, lineMap, oppMap, customAssocMap,
                    lineChildSectionsByKey, oppChildSectionsByKey, childListsBySectionKey,
                    new Map<String, Object>()
                );

                DMT_TaskStatusWhenCompleted__c ts = new DMT_TaskStatusWhenCompleted__c(
                    DMT_ViewFieldStatusAtClose__c = snapshotJson,
                    Case__c                       = t.WhatId,
                    DMT_AllFieldsInStatus__c      = resolution.allFields,
                    DMT_TrackedComponents__c      = String.join(new List<String>(resolution.trackedComponentNames), ';')
                );

                if (t.DMT_ViewStatusAtClose__c != null) {
                    ts.Id = t.DMT_ViewStatusAtClose__c;
                    statusToUpdate.add(ts);
                } else {
                    statusToInsert.add(ts);
                    taskIdsNeedingLink.add(t.Id);
                }
            }

            if (!statusToUpdate.isEmpty()) {
                DMT_DmlUtils.updateMany(DMT_DmlUtils.withIdOnly(statusToUpdate), 'updateTaskStatus');
            }

            Map<Id, Id> newStatusIdByTaskId = new Map<Id, Id>();
            if (!statusToInsert.isEmpty()) {
                DMT_DmlUtils.insertMany(statusToInsert, 'insertTaskStatus');
                // Associate each inserted status record to the corresponding task
                for (Integer i = 0; i < taskIdsNeedingLink.size() && i < statusToInsert.size(); i++) {
                    newStatusIdByTaskId.put(taskIdsNeedingLink[i], statusToInsert[i].Id);
                }
            }

            // CIBGLOBALD-4117 - enqueue a callout-tracked baseline freeze for every task's own
            // snapshot now that its real Id is known (inserted or updated). Each is its own
            // separate async execution (fresh governor limits per payload), so this doesn't need to
            // de-dup by record - only every snapshot actually getting its own baseline matters here.
            for (Id taskId : calloutComponentsByTaskId.keySet()) {
                Id snapshotId = newStatusIdByTaskId.containsKey(taskId) ? newStatusIdByTaskId.get(taskId) : taskMap.get(taskId).DMT_ViewStatusAtClose__c;
                Id recordId = recordIdByTaskId.get(taskId);
                if (snapshotId == null || recordId == null) continue;

                for (String componentName : calloutComponentsByTaskId.get(taskId)) {
                    DMT_AsyncOrchestrator.enqueue(new DMT_CalloutTrackableFreezePayload(snapshotId, recordId, componentName));
                }
            }
            DMT_AsyncOrchestrator.flush();

            // ── 10. Update selected tasks: result/comments/status snapshot link ─
            // Single responsibility: DMT_TaskCompletionService.completeTasks - the single-task
            // approval screen (DMT_ApprovalTemplate_Controller) records an approver's decision
            // through this exact same method, so the two paths can never drift apart again.
            List<DMT_TaskCompletionService.TaskCompletionRequest> completionRequests = new List<DMT_TaskCompletionService.TaskCompletionRequest>();
            for (Task t : taskMap.values()) {
                ClosurePayload p = payloadByTaskId.get(t.Id);
                DMT_TaskCompletionService.TaskCompletionRequest req = new DMT_TaskCompletionService.TaskCompletionRequest();
                req.taskId = t.Id;
                req.stepResult = p.result;
                req.comments = p.comments;
                req.committeeLabel = p.committeeLabel;
                if (newStatusIdByTaskId.containsKey(t.Id)) {
                    req.viewStatusAtCloseId = newStatusIdByTaskId.get(t.Id);
                }
                completionRequests.add(req);
            }
            DMT_TaskCompletionService.completeTasks(completionRequests);

            // ── 11. Finish all open tasks on the same cases ────────────────
            DMT_RelatedTaskFinisherService.finishRelatedTasks(new List<Id>(caseIds));

            // ── 12. Close cases ───────────────────────────────────────────
            DMT_CaseClosureService.setStatuses(new List<Id>(caseIds), DMT_Constants.FINISHED);

            // ── 13. Update line / opportunity to Draft (IP parity) ────────
            // Execute only for flows equivalent to updateToDraft=true
            // (e.g. returnToProposal), not for modal option 1.
            if (shouldUpdateToDraft) {
                Set<Id> draftLineIds = new Set<Id>();
                Set<Id> draftOppIds = new Set<Id>();
                for (Case c : caseMap.values()) {
                    if (c == null) continue;
                    if (c.DMT_LineOpportunity__c == 'L') {
                        if (c.DMT_Line__c != null) draftLineIds.add(c.DMT_Line__c);
                        if (c.opportunity_id__c != null) draftOppIds.add(c.opportunity_id__c);
                    } else if (c.DMT_LineOpportunity__c == 'O') {
                        if (c.opportunity_id__c != null) draftOppIds.add(c.opportunity_id__c);
                    }
                }
                DMT_DraftStatusService.moveToDraft(new List<Id>(draftLineIds), new List<Id>(draftOppIds));
            }

            // ── 14. Move ContentDocumentLinks from case to task ───────────
            // Async via the shared engine, not a bespoke Queueable - see DMT_DocumentTransferPayload.
            if (!caseIds.isEmpty() && !taskIdByCaseId.isEmpty()) {
                DMT_AsyncOrchestrator.enqueue(new DMT_DocumentTransferPayload(taskIdByCaseId));
                DMT_AsyncOrchestrator.flush();
            }

            // ── 15. Update Business Approver date on Opportunity ──────────
            DMT_CaseOwnerType_Handler.getOwnerCaseTypes(new List<Id>(caseIds));

        } catch (Exception e) {
            closureResult.success      = false;
            closureResult.errorMessage = e.getMessage();
            System.enqueueJob(new DMT_LogExceptionQueueable(
                e.getMessage(), e.getStackTraceString(), e.getLineNumber(),
                e.getTypeName(), 'DMT_Massive_Task_Closure_Service',
                'confirmMassiveClosure', 'DMT', ''
            ));
        }

        return closureResult;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Resolves the approver view ID for a given case, mirroring
     * DMT_ApprovalChangeStep_Handler.getApproverViewId.
     */
    /**
     * Queries a single SObject type by Id, selecting only merged fields.
     * Returns Map<Id, SObject>.
     */
    private static Map<Id, SObject> bulkQueryById(
            String objectType,
            Map<String, Set<String>> mergedFieldMap,
            Set<Id> ids) {

        Map<Id, SObject> result = new Map<Id, SObject>();
        if (ids.isEmpty() || !mergedFieldMap.containsKey(objectType)) return result;

        String soql = 'SELECT Id,'
            + String.join(new List<String>(mergedFieldMap.get(objectType)), ',')
            + ' FROM ' + objectType + ' WHERE Id IN :ids';

        for (SObject rec : Database.query(soql, AccessLevel.SYSTEM_MODE)) {
            result.put((Id) rec.get('Id'), rec);
        }
        return result;
    }

    /**
     * Queries a child SObject type keyed by a (potentially cross-object)
     * lookup path.  Supports simple fields ('Line__c') and relationship
     * paths ('DMT_Opportunity_Product__r.OpportunityId').
     *
     * Returns Map<parentId, List<SObject>>.
     */
    private static Map<Id, List<SObject>> bulkQueryByLookup(
            String objectType,
            Map<String, Set<String>> mergedFieldMap,
            String lookupPath,
            Set<Id> parentIds,
            String orderBy) {

        Map<Id, List<SObject>> result = new Map<Id, List<SObject>>();
        if (parentIds.isEmpty() || !mergedFieldMap.containsKey(objectType)) return result;

        Boolean isCrossObject = lookupPath.contains('.');
        String  selectPath    = isCrossObject ? lookupPath : lookupPath;
        String  relName       = isCrossObject ? lookupPath.substringBefore('.') : null;
        String  relField      = isCrossObject ? lookupPath.substringAfter('.')  : null;

        List<String> selectedFields = new List<String>();
        for (String fieldName : mergedFieldMap.get(objectType)) {
            if (String.isBlank(fieldName)) {
                continue;
            }
            if (fieldName.endsWith('__r')) {
                continue;
            }
            if (isCrossObject && fieldName == relName) {
                continue;
            }
            selectedFields.add(fieldName);
        }

        String soql = 'SELECT Id,' + selectPath + ','
            + String.join(selectedFields, ',')
            + ' FROM ' + objectType
            + ' WHERE ' + lookupPath + ' IN :parentIds'
            + (String.isBlank(orderBy) ? '' : ' ORDER BY ' + orderBy);

        for (SObject rec : Database.query(soql, AccessLevel.SYSTEM_MODE)) {
            Id parentId;
            try {
                if (isCrossObject) {
                    SObject rel = rec.getSObject(relName);
                    parentId = rel != null ? (Id) rel.get(relField) : null;
                } else {
                    parentId = (Id) rec.get(lookupPath);
                }
            } catch (Exception ex) { continue; }

            if (parentId == null) continue;
            if (!result.containsKey(parentId)) result.put(parentId, new List<SObject>());
            result.get(parentId).add(rec);
        }
        return result;
    }

}