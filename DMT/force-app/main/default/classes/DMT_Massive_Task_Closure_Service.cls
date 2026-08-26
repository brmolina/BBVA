/**
 * @description Service class for massive task closure over multiple cases/tasks.
 *              Bulkified Apex equivalent of the Approver_UpdateStep Integration
 *              Procedure running with modalType = "finishcase":
 *
 *              1. updateTaskWithStatus  – snapshot line/opp data to
 *                 DMT_TaskStatusWhenCompleted__c (one record per task, bulk)
 *              2. Complete tasks        – Status = Completed, DMT_Step_Result__c,
 *                 Description
 *              3. Finish related tasks  – all other open tasks on the same cases
 *                 (mirrors FinishAllRelatedTasks in the IP FinishCase block)
 *              4. Close cases           – Status = Finished
 *              5. Update line/opp draft  – mirror UpdateLineOppToDraft from the IP
 *              6. Move documents        – ContentDocumentLink from case → task
 *              7. Business-approver date – DMT_Bussiness_Approved_Date__c on Opp
 *                 when applicable
 *
 * @author      GitHub Copilot
 * @last modified on  : 05-28-2026
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

            Map<Id, Case> caseMap = new Map<Id, Case>([
                SELECT Id, OwnerId, DMT_Line__c, opportunity_id__c,
                       DMT_Line__r.Custom_Association__c,
                       DMT_Line__r.RecordType.DeveloperName,
                       DMT_LineOpportunity__c,
                       opportunity_id__r.RecordType.DeveloperName,
                       DMT_Passport_Sanction__c
                FROM Case
                WHERE Id IN :caseIds
                WITH SYSTEM_MODE
            ]);

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
                Id viewId = resolveViewId(approver, c);
                if (viewId != null) {
                    viewIdByTaskId.put(t.Id, viewId);
                    allViewIds.add(viewId);
                }
            }

            // ── 5. One query for all DMT_Items__c across all views ────────
            Map<Id, List<DMT_Items__c>> itemsByViewId = new Map<Id, List<DMT_Items__c>>();
            for (DMT_Items__c item : [
                SELECT Id, DMT_Campos_componente_Refact__c, DMT_View__c
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

            // ── 6. Build per-view fieldMaps and one merged fieldMap ───────
            Map<Id, Map<String, List<String>>> fieldMapByViewId = new Map<Id, Map<String, List<String>>>();
            Map<Id, String>                    allFieldsByViewId = new Map<Id, String>();
            Map<String, Set<String>>           mergedFieldMap    = new Map<String, Set<String>>();

            for (Id viewId : itemsByViewId.keySet()) {
                Map<String, List<String>> fm = new Map<String, List<String>>();
                String allF = '';
                for (DMT_Items__c item : itemsByViewId.get(viewId)) {
                    if (String.isBlank(item.DMT_Campos_componente_Refact__c)) continue;
                    for (String field : item.DMT_Campos_componente_Refact__c.split(';', 0)) {
                        List<String> parts = field.split('\\.', 2);
                        if (parts.size() < 2) continue;
                        String obj = parts[0];
                        String fld = parts[1];
                        if (!fm.containsKey(obj)) fm.put(obj, new List<String>());
                        if (!fm.get(obj).contains(fld)) {
                            fm.get(obj).add(fld);
                            allF += obj + '.' + fld + ';';
                        }
                        if (!mergedFieldMap.containsKey(obj)) mergedFieldMap.put(obj, new Set<String>());
                        mergedFieldMap.get(obj).add(fld);
                    }
                }
                fieldMapByViewId.put(viewId, fm);
                allFieldsByViewId.put(viewId, allF.removeEnd(';'));
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
            // LINE domain
            Map<Id, SObject>       lineMap          = bulkQueryById(
                'DMT_Line__c', mergedFieldMap, lineIds);
            Map<Id, List<SObject>> riskTermsByLine  = bulkQueryByLookup(
                'DMT_Risk_Line_Term__c',    mergedFieldMap, 'DMT_Line__c',         lineIds, 'DMT_Init_Term__c ASC');
            Map<Id, List<SObject>> customAssocMap   = bulkQueryByLookup(
                'Custom_Association_Client__c', mergedFieldMap, 'Custom_Association__c', customAssocIds, 'Name ASC');
            Map<Id, List<SObject>> currProvByLine   = bulkQueryByLookup(
                'DMT_Currency_Provision__c', mergedFieldMap, 'DMT_Risk_Line_Term__r.DMT_Line__c', lineIds, 'Name ASC');
            Map<Id, List<SObject>> warrantyByLine   = bulkQueryByLookup(
                'DMT_Warranty__c',           mergedFieldMap, 'DMT_Risk_Line_Term__r.DMT_Line__c', lineIds, 'Name ASC');
            Map<Id, List<SObject>> lineProductByLine = bulkQueryByLookup(
                'DMT_Line_Product_Item__c',  mergedFieldMap, 'Line__c',            lineIds, 'Name ASC');

            // OPPORTUNITY domain
            Map<Id, SObject>       oppMap           = bulkQueryById(
                'Opportunity', mergedFieldMap, oppIds);
            Map<Id, List<SObject>> tenorByOpp       = bulkQueryByLookup(
                'DMT_Opportunity_Tenor__c',    mergedFieldMap, 'DMT_Opportunity_Product__r.OpportunityId', oppIds, 'gj_nominal_amount_db__c ASC');
            Map<Id, List<SObject>> mitigantByOpp    = bulkQueryByLookup(
                'DMT_Opportunity_Mitigant__c', mergedFieldMap, 'DMT_Opportunity_Product__r.OpportunityId', oppIds, 'Mitigant_Type__c ASC');
            Map<Id, List<SObject>> oliByOpp         = bulkQueryByLookup(
                'OpportunityLineItem',         mergedFieldMap, 'OpportunityId',    oppIds, 'DMT_Deal_Amount_Tenors__c ASC');
            Map<Id, List<SObject>> oppClientByOpp   = bulkQueryByLookup(
                'DMT_Opportunity_Client__c',   mergedFieldMap, 'DMT_MDE_Opportunity__c', oppIds, 'Name ASC');
            Map<Id, List<SObject>> xsellByOpp       = bulkQueryByLookup(
                'DMT_X_Sell__c',               mergedFieldMap, 'Opportunity__c',   oppIds, 'Name ASC');

            // ── 9. Build DMT_TaskStatusWhenCompleted__c records ───────────
            List<DMT_TaskStatusWhenCompleted__c> statusToInsert = new List<DMT_TaskStatusWhenCompleted__c>();
            List<DMT_TaskStatusWhenCompleted__c> statusToUpdate = new List<DMT_TaskStatusWhenCompleted__c>();
            // Tasks that need their DMT_ViewStatusAtClose__c populated after insert
            List<Id> taskIdsNeedingLink = new List<Id>();

            for (Task t : taskMap.values()) {
                Case c       = caseMap.get(t.WhatId);
                Id   viewId  = viewIdByTaskId.get(t.Id);
                if (c == null || viewId == null) continue;

                String snapshotJson = buildTaskStatusJson(
                    c, fieldMapByViewId.get(viewId),
                    lineMap, riskTermsByLine, customAssocMap, currProvByLine,
                    warrantyByLine, lineProductByLine,
                    oppMap, tenorByOpp, mitigantByOpp, oliByOpp,
                    oppClientByOpp, xsellByOpp
                );

                DMT_TaskStatusWhenCompleted__c ts = new DMT_TaskStatusWhenCompleted__c(
                    DMT_ViewFieldStatusAtClose__c = snapshotJson,
                    Case__c                       = t.WhatId,
                    DMT_AllFieldsInStatus__c      = allFieldsByViewId.get(viewId)
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
                statusToUpdate = filterRecordsWithId(statusToUpdate);
                dmlUpdateMany(statusToUpdate, 'updateTaskStatus');
            }

            Map<Id, Id> newStatusIdByTaskId = new Map<Id, Id>();
            if (!statusToInsert.isEmpty()) {
                dmlInsertMany(statusToInsert, 'insertTaskStatus');
                // Associate each inserted status record to the corresponding task
                for (Integer i = 0; i < taskIdsNeedingLink.size() && i < statusToInsert.size(); i++) {
                    newStatusIdByTaskId.put(taskIdsNeedingLink[i], statusToInsert[i].Id);
                }
            }

            // ── 10. Update selected tasks: result/comments/status snapshot link ─
            List<Task> tasksToUpdate = new List<Task>();
            for (Task t : taskMap.values()) {
                ClosurePayload p = payloadByTaskId.get(t.Id);
                Task upd = new Task(
                    Id                 = t.Id,
                    DMT_Step_Result__c = p.result,
                    Description        = p.comments,
                    DMT_Committee_Label__c = p.committeeLabel
                );
                if (newStatusIdByTaskId.containsKey(t.Id)) {
                    upd.DMT_ViewStatusAtClose__c = newStatusIdByTaskId.get(t.Id);
                }
                tasksToUpdate.add(upd);
            }
            dmlUpdateMany(filterRecordsWithId(tasksToUpdate), 'updateTasks');

                        // ── 11. Finish all open tasks on the same cases ────────────────
            // Mirrors FinishAllRelatedTasks (DmtDpUpdateApproverTask) inside
            // the FinishCase conditional block of the Approver_UpdateStep IP.
            List<Task> relatedOpenTasks = [
                SELECT Id, Status
                FROM Task
                WHERE WhatId IN :caseIds
                  AND Status NOT IN ('Cancelled')
                WITH SYSTEM_MODE
            ];

            if (!relatedOpenTasks.isEmpty()) {
                List<Task> relatedToClose = new List<Task>();
                for (Task rt : relatedOpenTasks) {
                    relatedToClose.add(new Task(
                        Id     = rt.Id,
                        Status = DMT_Constants.FINISHED
                    ));
                }
                dmlUpdateMany(filterRecordsWithId(relatedToClose), 'finishRelatedTasks');
            }

            // ── 12. Close cases ───────────────────────────────────────────
            List<Case> casesToClose = new List<Case>();
            for (Id cId : caseIds) {
                casesToClose.add(new Case(Id = cId, Status = DMT_Constants.FINISHED));
            }
            dmlUpdateMany(filterRecordsWithId(casesToClose), 'closeCases');

            // ── 13. Update line / opportunity to Draft (IP parity) ────────
            // Execute only for flows equivalent to updateToDraft=true
            // (e.g. returnToProposal), not for modal option 1.
            if (shouldUpdateToDraft) {
                updateLineOppToDraft(caseMap);
            }

            // ── 14. Move ContentDocumentLinks from case to task ───────────
            // Run asynchronously so document issues never block the close.
            if (!caseIds.isEmpty() && !taskIdByCaseId.isEmpty()) {
                System.debug(LoggingLevel.INFO,
                    'DMT_Massive_Task_Closure_Service enqueue doc move - caseIds=' + caseIds.size() +
                    ', taskMap=' + taskIdByCaseId.size());
                System.enqueueJob(new DMT_Massive_Task_DocMoveQueueable(caseIds, taskIdByCaseId));
            }

            // ── 15. Update Business Approver date on Opportunity ──────────
            updateBusinessApproverDates(caseMap, groupById, approverByGroup);

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
    private static Id resolveViewId(DMT_Approver__c approver, Case c) {
        if (c.DMT_LineOpportunity__c == 'L') {
            String rt = c.DMT_Line__r?.RecordType?.DeveloperName;
            if (rt == 'OtherProducts')      return approver.Approvers_View__c;
            if (rt == 'TreasurySettlement') return approver.Approvers_View_Treasury__c;
        } else if (c.DMT_LineOpportunity__c == 'O') {
            if (c.opportunity_id__r?.RecordType?.DeveloperName == 'DMT_Opportunity') {
                return approver.Approvers_View_Opportunity__c;
            }
        }
        return null;
    }

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

    /**
     * Builds the JSON snapshot string for a single task/case pair, using
     * pre-fetched bulk data.  The structure matches the one produced by
     * DMT_ApprovalChangeStep_Handler.updateTaskWithStatus so that
     * compareTasksFromCase can compare them correctly.
     */
    private static String buildTaskStatusJson(
            Case c,
            Map<String, List<String>> fm,
            Map<Id, SObject>       lineMap,
            Map<Id, List<SObject>> riskTermsByLine,
            Map<Id, List<SObject>> customAssocMap,
            Map<Id, List<SObject>> currProvByLine,
            Map<Id, List<SObject>> warrantyByLine,
            Map<Id, List<SObject>> lineProductByLine,
            Map<Id, SObject>       oppMap,
            Map<Id, List<SObject>> tenorByOpp,
            Map<Id, List<SObject>> mitigantByOpp,
            Map<Id, List<SObject>> oliByOpp,
            Map<Id, List<SObject>> oppClientByOpp,
            Map<Id, List<SObject>> xsellByOpp) {

        Map<String, Object> snapshot = new Map<String, Object>();

        if (c.DMT_LineOpportunity__c == 'L') {
            Id lineId = c.DMT_Line__c;

            if (fm.containsKey('DMT_Line__c') && lineMap.containsKey(lineId)) {
                snapshot.put('line', lineMap.get(lineId));
            }
            if (fm.containsKey('DMT_Risk_Line_Term__c') && riskTermsByLine.containsKey(lineId)) {
                snapshot.put('riskLineList',
                    toIndexedMap(riskTermsByLine.get(lineId), fm.get('DMT_Risk_Line_Term__c')));
            }
            Id caId = c.DMT_Line__r?.Custom_Association__c;
            if (fm.containsKey('Custom_Association_Client__c')
                    && caId != null && customAssocMap.containsKey(caId)) {
                snapshot.put('customAssociationClientList',
                    toIdKeyMap(customAssocMap.get(caId)));
            }
            if (fm.containsKey('DMT_Currency_Provision__c') && currProvByLine.containsKey(lineId)) {
                snapshot.put('currencyProvisions',
                    toIdKeyMap(currProvByLine.get(lineId)));
            }
            if (fm.containsKey('DMT_Warranty__c') && warrantyByLine.containsKey(lineId)) {
                snapshot.put('warranties',
                    toIdKeyMap(warrantyByLine.get(lineId)));
            }
            if (fm.containsKey('DMT_Line_Product_Item__c') && lineProductByLine.containsKey(lineId)) {
                snapshot.put('lineProductItemList',
                    toIndexedMap(lineProductByLine.get(lineId), fm.get('DMT_Line_Product_Item__c')));
            }

        } else if (c.DMT_LineOpportunity__c == 'O') {
            Id oppId = c.opportunity_id__c;

            if (fm.containsKey('Opportunity') && oppMap.containsKey(oppId)) {
                snapshot.put('opportunity', oppMap.get(oppId));
            }
            if (fm.containsKey('DMT_Opportunity_Tenor__c') && tenorByOpp.containsKey(oppId)) {
                snapshot.put('opportunityTenor',
                    toIndexedMap(tenorByOpp.get(oppId), fm.get('DMT_Opportunity_Tenor__c')));
            }
            if (fm.containsKey('DMT_Opportunity_Mitigant__c') && mitigantByOpp.containsKey(oppId)) {
                snapshot.put('opportunityMitigant',
                    toIndexedMap(mitigantByOpp.get(oppId), fm.get('DMT_Opportunity_Mitigant__c')));
            }
            if (fm.containsKey('OpportunityLineItem') && oliByOpp.containsKey(oppId)) {
                snapshot.put('opportunityLineItem',
                    toIndexedMap(oliByOpp.get(oppId), fm.get('OpportunityLineItem')));
            }
            if (fm.containsKey('DMT_Opportunity_Client__c') && oppClientByOpp.containsKey(oppId)) {
                snapshot.put('opportunityClient',
                    toIdKeyMap(oppClientByOpp.get(oppId)));
            }
            if (fm.containsKey('DMT_X_Sell__c') && xsellByOpp.containsKey(oppId)) {
                snapshot.put('opportunityXSell',
                    toIdKeyMap(xsellByOpp.get(oppId)));
            }
        }

        return System.JSON.serialize(snapshot, true)
                    .replaceAll('"attributes":\\{[^\\}]*\\},?', '');
    }

    /**
     * Converts a list of SObjects to an integer-indexed map of field→value pairs.
     * Produces the same structure as the riskLineList/lineProductItemList etc. in
     * DMT_ApprovalChangeStep_Handler (Map<Integer, Map<String, Object>>).
     */
    private static Map<Integer, Map<String, Object>> toIndexedMap(
            List<SObject> records, List<String> fields) {
        Map<Integer, Map<String, Object>> result = new Map<Integer, Map<String, Object>>();
        Integer counter = 1;
        for (SObject rec : records) {
            Map<String, Object> attrs = new Map<String, Object>();
            for (String f : fields) {
                try { attrs.put(f, rec.get(f)); } catch (Exception ex) { /* skip cross-obj */ }
            }
            result.put(counter++, attrs);
        }
        return result;
    }

    /**
     * Converts a list of SObjects to a Map<Id, SObject> keyed by record Id.
     * Produces the same structure as customAssociationClientList / warranties etc.
     */
    private static Map<Id, SObject> toIdKeyMap(List<SObject> records) {
        Map<Id, SObject> result = new Map<Id, SObject>();
        for (SObject rec : records) result.put((Id) rec.get('Id'), rec);
        return result;
    }

    /**
     * Moves ContentDocumentLinks from each case to the associated task.
     * Mirrors the Extract → Delete → Load steps in the IP.
     */
    public static void moveContentDocumentLinksAsync(
            Set<Id> caseIds, Map<Id, Id> taskIdByCaseId) {
        if (caseIds == null || caseIds.isEmpty() || taskIdByCaseId == null || taskIdByCaseId.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'DMT_Massive_Task_Closure_Service moveContentDocumentLinksAsync skipped - empty input.');
            return;
        }

        Set<Id> validCaseIds = new Set<Id>();
        for (Id caseId : caseIds) {
            if (caseId != null && caseId.getSObjectType() == Case.SObjectType) {
                validCaseIds.add(caseId);
            }
        }

        Map<Id, Id> validTaskIdByCaseId = new Map<Id, Id>();
        for (Id caseId : taskIdByCaseId.keySet()) {
            Id taskId = taskIdByCaseId.get(caseId);
            if (caseId == null || taskId == null) {
                continue;
            }
            if (caseId.getSObjectType() != Case.SObjectType || taskId.getSObjectType() != Task.SObjectType) {
                continue;
            }
            validTaskIdByCaseId.put(caseId, taskId);
        }

        if (validCaseIds.isEmpty() || validTaskIdByCaseId.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'DMT_Massive_Task_Closure_Service moveContentDocumentLinksAsync skipped - no valid ids. '
                + 'validCaseIds=' + validCaseIds.size() + ', validTaskMap=' + validTaskIdByCaseId.size());
            return;
        }

        System.debug(LoggingLevel.INFO,
            'DMT_Massive_Task_Closure_Service moveContentDocumentLinksAsync start - validCaseIds=' + validCaseIds.size()
            + ', validTaskMap=' + validTaskIdByCaseId.size());

        Map<Id, List<ContentDocumentLink>> existingByCaseId = new Map<Id, List<ContentDocumentLink>>();
        for (ContentDocumentLink link : [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :validCaseIds
            WITH SYSTEM_MODE
        ]) {
            if (!existingByCaseId.containsKey(link.LinkedEntityId)) {
                existingByCaseId.put(link.LinkedEntityId, new List<ContentDocumentLink>());
            }
            existingByCaseId.get(link.LinkedEntityId).add(link);
        }

        if (existingByCaseId.isEmpty()) {
            return;
        }

        List<ContentDocumentLink> linksToDelete = new List<ContentDocumentLink>();
        for (List<ContentDocumentLink> caseLinks : existingByCaseId.values()) {
            linksToDelete.addAll(caseLinks);
        }

        Set<Id> targetTaskIds = new Set<Id>(validTaskIdByCaseId.values());
        if (targetTaskIds.isEmpty()) {
            return;
        }
        Map<String, Boolean> existingTaskLinks = new Map<String, Boolean>();
        for (ContentDocumentLink taskLink : [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :targetTaskIds
            WITH SYSTEM_MODE
        ]) {
            existingTaskLinks.put(String.valueOf(taskLink.LinkedEntityId) + ':' + String.valueOf(taskLink.ContentDocumentId), true);
        }

        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        for (Id caseId : existingByCaseId.keySet()) {
            Id targetTaskId = validTaskIdByCaseId.get(caseId);
            if (targetTaskId == null) {
                continue;
            }
            for (ContentDocumentLink old : existingByCaseId.get(caseId)) {
                String linkKey = String.valueOf(targetTaskId) + ':' + String.valueOf(old.ContentDocumentId);
                if (existingTaskLinks.containsKey(linkKey)) {
                    continue;
                }
                newLinks.add(new ContentDocumentLink(
                    ContentDocumentId = old.ContentDocumentId,
                    LinkedEntityId    = targetTaskId,
                    ShareType         = 'V',
                    Visibility        = 'InternalUsers'
                ));
            }
        }
        if (!newLinks.isEmpty()) {
            dmlInsertMany(newLinks, 'insertContentDocumentLinks');
        }

        if (!linksToDelete.isEmpty()) {
            dmlDeleteMany(linksToDelete, 'deleteCaseContentDocumentLinks');
        }
    }

    /**
     * Mirrors the UpdateLineOppToDraft conditional block from the IP.
     *
     * The OmniStudio version executes two post-actions against the same
     * DmtDrLoadSaveLineOppDraftStatus transform:
     *  - first with CancelValue = false
     *  - then with CancelValue = true
     *
     * To preserve the same side effects in Apex, the bulk update is executed
     * twice in the same order, but using one query per object type.
     */
    private static void updateLineOppToDraft(Map<Id, Case> caseMap) {
        Set<Id> lineIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();

        for (Case c : caseMap.values()) {
            if (c == null) {
                continue;
            }
            if (c.DMT_LineOpportunity__c == 'L') {
                if (c.DMT_Line__c != null) {
                    lineIds.add(c.DMT_Line__c);
                }
                if (c.opportunity_id__c != null) {
                    oppIds.add(c.opportunity_id__c);
                }
            } else if (c.DMT_LineOpportunity__c == 'O') {
                if (c.opportunity_id__c != null) {
                    oppIds.add(c.opportunity_id__c);
                }
            }
        }

        if (lineIds.isEmpty() && oppIds.isEmpty()) {
            return;
        }

        List<DMT_Line__c> lines = new List<DMT_Line__c>();
        for (DMT_Line__c line : [
            SELECT Id, Status__c, Allowed__c
            FROM DMT_Line__c
            WHERE Id IN :lineIds
            WITH SYSTEM_MODE
        ]) {
            lines.add(line);
        }

        List<Opportunity> opps = new List<Opportunity>();
        for (Opportunity opp : [
            SELECT Id, StageName, DMT_Cancel__c
            FROM Opportunity
            WHERE Id IN :oppIds
            WITH SYSTEM_MODE
        ]) {
            opps.add(opp);
        }

        if (!lines.isEmpty() || !opps.isEmpty()) {
            applyDraftUpdate(lines, opps, false);
            applyDraftUpdate(lines, opps, true);
        }
    }

    /**
     * Applies the draft-state values to the provided records.
     */
    private static void applyDraftUpdate(
            List<DMT_Line__c> lines,
            List<Opportunity> opps,
            Boolean cancelValue) {

        List<SObject> toUpdate = new List<SObject>();

        for (DMT_Line__c line : lines) {
            line.Status__c = 'Draft';
            line.Allowed__c = cancelValue;
            toUpdate.add(line);
        }

        for (Opportunity opp : opps) {
            opp.StageName = 'Draft';
            opp.DMT_Cancel__c = cancelValue;
            toUpdate.add(opp);
        }

        if (toUpdate.isEmpty()) {
            return;
        }

        dmlUpdateMany(toUpdate, 'updateLineOppToDraft_' + String.valueOf(cancelValue));
    }

    /**
     * For Opportunity cases (DMT_LineOpportunity__c = 'O') where the case
     * owner is a Business-type approver and the sanction is approval/readytoclose,
     * stamps DMT_Bussiness_Approved_Date__c = today on the linked Opportunity.
     * Mirrors DMT_CaseOwnerType_Handler.getOwnerCaseType.
     */
    private static void updateBusinessApproverDates(
            Map<Id, Case>           caseMap,
            Map<Id, Group>          groupById,
            Map<String, DMT_Approver__c> approverByGroup) {

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Set<Id> processed = new Set<Id>();

        for (Case c : caseMap.values()) {
            if (c.DMT_LineOpportunity__c != 'O' || c.opportunity_id__c == null) continue;
            if (processed.contains(c.opportunity_id__c)) continue;

            Group g = groupById.get(c.OwnerId);
            if (g == null) continue;
            DMT_Approver__c approver = approverByGroup.get(g.DeveloperName);
            if (approver == null) continue;

            Boolean isBusinessApprover = approver.DMT_ApproverType__r != null
                && 'Business'.equalsIgnoreCase(approver.DMT_ApproverType__r.Name);

            String sanction = c.DMT_Passport_Sanction__c;
            Boolean isAllowedSanction = !String.isBlank(sanction)
                && (sanction.equalsIgnoreCase('approval')
                    || sanction.equalsIgnoreCase('readytoclose'));

            if (isBusinessApprover && isAllowedSanction) {
                oppsToUpdate.add(new Opportunity(
                    Id                             = c.opportunity_id__c,
                    DMT_Bussiness_Approved_Date__c = Date.today()
                ));
                processed.add(c.opportunity_id__c);
            }
        }

        if (!oppsToUpdate.isEmpty()) {
            dmlUpdateMany(oppsToUpdate, 'updateBusinessApproverDates');
        }
    }

    /**
     * Internal DML wrappers for this class.
     * Keep all operations in SYSTEM_MODE and throw a contextual exception
     * when any row fails (parity with ensureSuccess semantics).
     */
    private static void dmlInsertMany(List<SObject> recordsToInsert, String operation) {
        if (recordsToInsert == null || recordsToInsert.isEmpty()) {
            return;
        }
        ensureDmlSuccess(
            Database.insert(recordsToInsert, AccessLevel.SYSTEM_MODE),
            operation
        );
    }

    private static void dmlUpdateMany(List<SObject> recordsToUpdate, String operation) {
        if (recordsToUpdate == null || recordsToUpdate.isEmpty()) {
            return;
        }
        ensureDmlSuccess(
            Database.update(recordsToUpdate, AccessLevel.SYSTEM_MODE),
            operation
        );
    }

    private static void dmlDeleteMany(List<SObject> recordsToDelete, String operation) {
        if (recordsToDelete == null || recordsToDelete.isEmpty()) {
            return;
        }
        ensureDmlDeleteSuccess(
            Database.delete(recordsToDelete, AccessLevel.SYSTEM_MODE),
            operation
        );
    }

    private static void ensureDmlSuccess(List<Database.SaveResult> results, String operation) {
        for (Integer index = 0; index < results.size(); index++) {
            Database.SaveResult result = results[index];
            if (result.isSuccess()) {
                continue;
            }
            throw new AuraHandledException(buildDmlErrorMessage(result.getErrors(), operation, index));
        }
    }

    private static void ensureDmlDeleteSuccess(List<Database.DeleteResult> results, String operation) {
        for (Integer index = 0; index < results.size(); index++) {
            Database.DeleteResult result = results[index];
            if (result.isSuccess()) {
                continue;
            }
            throw new AuraHandledException(buildDmlErrorMessage(result.getErrors(), operation, index));
        }
    }

    private static String buildDmlErrorMessage(Database.Error[] errors, String operation, Integer index) {
        String message = 'DMT_Massive_Task_Closure_Service ' + operation + ' failed [idx=' + index + ']: ';
        for (Database.Error errorItem : errors) {
            message += String.valueOf(errorItem.getStatusCode()) + ' - ' + errorItem.getMessage() + ' ';
        }
        return message;
    }

    /**
     * Removes records without Id before an update call to avoid MISSING_ARGUMENT errors.
     */
    private static List<SObject> filterRecordsWithId(List<SObject> records) {
        List<SObject> filtered = new List<SObject>();
        for (SObject rec : records) {
            if (rec != null && rec.get('Id') != null) {
                filtered.add(rec);
            }
        }
        return filtered;
    }
}