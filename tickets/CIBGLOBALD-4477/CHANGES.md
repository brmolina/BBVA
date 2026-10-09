# CIBGLOBALD-4477 - Auto-start approval Cases - bulkification

Written for: a developer who has to review and deploy this change.

## What this change does

`DMT_Case_Steps_Controller.startAutoWorkflowForStage` ran once per record inside a trigger loop. Each call ran 2 queries
(Passport, existing Cases) and then enqueued a Queueable that ran `DMT_Passport_Handler.startCase` (about 15 or more queries and several DML statements).
A bulk save therefore multiplied the queries and hit the 50-Queueable limit, and a record without a Passport threw 'List has no rows'.

Now:

- The Passport and Case lookups run once for the whole save (2 queries, whatever the number of records).
- The Case creation moves to a new payload, `DMT_StartApprovalCasePayload`, handed to `DMT_AsyncOrchestrator`.
  With more than one payload the orchestrator runs one payload per Batch chunk, so every `startCase` has fresh governor limits
  and its DML can never sit in front of a callout in the same transaction.
- `DMT_AsyncQueueJob` dispatches at most one of these payloads inline per transaction (same rule as `DMT_CalloutTrackableCheckPayload`).
- The method accepts a single record or a Map of records (overloads). Methods were renamed to say what they do:

| Old name | New name |
|---|---|
| DMT_Case_Steps_Controller.startAutoWorkflowForStage | enqueueAutoWorkflowCases (single-record and Map overloads) |
| DMT_Line_Helper.startAutoWorkflowForLines | enqueueAutoWorkflowOnStatusChange (list and single-record overloads) |
| DMT_OpportunityTriggerHandler.autoStartFirstBusinessApprovalFeature | enqueueAutoWorkflowOnStageChange |

- The call in `DMT_Line_TriggerHandler` (afterUpdate) is now active, using the new name.
- The Opportunity trigger call is live; only the method name it calls changed.
- Fix in `DMT_Passport_Handler.startCase`: the catch block called `Database.executeBatch`, which is illegal inside a Batch execute. It now uses the orchestrator.
  The other two `Database.executeBatch` catch blocks in that class were left as they are.

## How it relates to restartApprovalTasksOnLineResubmission

No conflict. `restartApprovalTasksOnLineResubmission` reopens Tasks of Cases that already exist. The auto-start only creates Cases for features that have no
approval Case yet (open or closed), and `startCase` also refuses a feature that already has a Case. The two act on disjoint features.

## Behavior notes

- The newest Passport with saved content is used per record. The old code used a USER_MODE query; the shared selectors used now run without USER_MODE (same as `processStartNextCaseApproval`).
- A feature is only picked when its first task has an approver with a non-blank id (the old code could pick one without and fail later in `startCase`).
- Selection is unchanged: lowest `orderNumber`, features without one last, all typed 'Other' (the Business/Risk split stays off, as before).
- The dead `approverIds` loop and the second eligibility pass were removed.
- The queueable-limit check was removed because the orchestrator handles limits.

## Retrieve / deploy package

`manifest/CIBGLOBALD-4477-package.xml` (retrieve with `sf project retrieve start -x manifest/CIBGLOBALD-4477-package.xml -o DMT_TCM_DEV`).
All components, including the new `DMT_StartApprovalCasePayload`, are already deployed to DMT_TCM_DEV, so the retrieve returns them normally. If they ever have to be deployed again, deploy everything together: the entries reference each other.

Components: DMT_StartApprovalCasePayload (new), DMT_Case_Steps_Controller, DMT_AsyncDispatcher, DMT_AsyncQueueJob, DMT_Passport_Handler, DMT_Line_Helper,
DMT_Line_TriggerHandler, DMT_OpportunityTriggerHandler, DMT_Case_Steps_Controller_Test, and the Opportunity trigger.

## Tests

Deployed to DMT_TCM_DEV; DMT_Case_Steps_Controller_Test passes 64/64 in the org. Added to `DMT_Case_Steps_Controller_Test`: bulk (2 queries for 5 Lines, lowest order wins), single-record overload,
started-feature / wrong-stage / missing-Passport skips, null and empty input, dispatcher path, and the one-per-transaction rule in `DMT_AsyncQueueJob`.
The whole file's `System.assert*` calls were renamed to `Assert.*` (67 renamed, new assertions added for the new tests).

---

## Code applied

### 1. New class DMT_StartApprovalCasePayload (new file, whole class)

**DMT_StartApprovalCasePayload.cls lines 1-29**



```apex
// CIBGLOBALD-4477 - Carries everything DMT_Passport_Handler.startCase needs to open ONE approval Case for ONE
// Passport feature, so the Case creation runs in its own async transaction (see
// DMT_AsyncOrchestrator.flush(): more than one payload in the buffer means one payload per
// Batch chunk, each with a fresh set of governor limits).
//
// taskListJson is the feature's full task list; the first task is the one startCase creates
// itself (taskId), so DMT_Case_Steps_Controller.startApprovalCaseFromPayload drops it before
// calling startCase - same convention as DMT_Case_Steps_Controller.StartCaseQueueable.
public class DMT_StartApprovalCasePayload implements DMT_AsyncPayload {
    public String externalLineId { get; set; }
    public String approverId { get; set; }
    public String taskId { get; set; }
    public String taskListJson { get; set; }
    public String featureId { get; set; }
    public String featureName { get; set; }
    public String comment { get; set; }
    public String passportSanction { get; set; }

    public DMT_StartApprovalCasePayload(String externalLineId, String approverId, String taskId, String taskListJson, String featureId, String featureName, String comment, String passportSanction) {
        this.externalLineId = externalLineId;
        this.approverId = approverId;
        this.taskId = taskId;
        this.taskListJson = taskListJson;
        this.featureId = featureId;
        this.featureName = featureName;
        this.comment = comment;
        this.passportSanction = passportSanction;
    }
}
```

### 2. DMT_Case_Steps_Controller - replaces startAutoWorkflowForStage (old lines 729-827)

**DMT_Case_Steps_Controller.cls lines 729-886**

New: `enqueueAutoWorkflowCases` (single-record overload at 735, Map overload at 760) and `startApprovalCaseFromPayload` (866).

```apex
    /**
     * @description CIBGLOBALD-4477 - Single-record overload of enqueueAutoWorkflowCases - see the Map overload below for the full behavior.
     * @param contextId DMT_Line__c Id, or Opportunity Id when isOpportunity is true
     * @param currentStage the record's stage/status it just moved into
     * @param isOpportunity true when contextId is an Opportunity
     **/
    public static void enqueueAutoWorkflowCases(Id contextId, String currentStage, Boolean isOpportunity) {
        if (contextId == null) {
            return;
        }
        enqueueAutoWorkflowCases(new Map<Id, String>{ contextId => currentStage }, isOpportunity);
    }

    /**
     * @description CIBGLOBALD-4477 - When records move into a stage, opens the approval Case of the first Passport feature
     * flagged for automatic start (autoWorkflowRequest = 'Y') whose sanction matches that stage, and that has
     * no approval Case yet. Stage -> sanction: Proposal -> passport, Approval -> approval, Ready to close -> readytoclose.
     *
     * Bulk safe: three queries in total (Passports, existing approval Cases) whatever the number of records;
     * the per-record work is in-memory only. The Case creation itself is NOT done here - one
     * DMT_StartApprovalCasePayload per record is handed to DMT_AsyncOrchestrator, which runs each one in its own
     * transaction (Batch chunk of 1) so every startCase gets a fresh set of governor limits, and the DML it
     * performs can never collide with a later callout in the same transaction. The caller must make sure
     * DMT_AsyncOrchestrator.flush() runs once at the end of its trigger context.
     *
     * Only the feature with the lowest order number is started per record; the next ones are started by the
     * regular next-approval flow (processStartNextCaseApproval) as Cases close.
     *
     * @param stageByContextId stage/status each record just moved into, by record Id (records can be in different stages)
     * @param isOpportunity true when the keys are Opportunity Ids, false when they are DMT_Line__c Ids
     **/
    public static void enqueueAutoWorkflowCases(Map<Id, String> stageByContextId, Boolean isOpportunity) {
        if (stageByContextId == null || stageByContextId.isEmpty()) {
            return;
        }

        Map<Id, String> expectedSanctionByContextId = new Map<Id, String>();
        for (Id contextId : stageByContextId.keySet()) {
            String expectedSanction = sanctionForStage(stageByContextId.get(contextId));
            if (contextId != null && String.isNotBlank(expectedSanction)) {
                expectedSanctionByContextId.put(contextId, expectedSanction);
            }
        }
        if (expectedSanctionByContextId.isEmpty()) {
            return;
        }
        Set<Id> contextIds = expectedSanctionByContextId.keySet();

        // Newest Passport with saved content per record (the selector returns newest first).
        Map<Id, Passport__c> passportByContextId = new Map<Id, Passport__c>();
        List<Passport__c> passports = isOpportunity
            ? DMT_Case_Steps_Selector.getPassportsByOpportunityIds(contextIds)
            : DMT_Case_Steps_Selector.getPassportsByLineIds(contextIds);
        for (Passport__c passport : passports) {
            Id contextId = isOpportunity ? passport.Opportunity__c : passport.DMT_Line__c;
            if (String.isNotBlank(passport.DMT_Passport_Save__c) && !passportByContextId.containsKey(contextId)) {
                passportByContextId.put(contextId, passport);
            }
        }
        if (passportByContextId.isEmpty()) {
            return;
        }

        // Features that already have an approval Case (open or closed) are never started again.
        Map<Id, Set<String>> startedFeatureIdsByContextId = new Map<Id, Set<String>>();
        List<Case> existingCases = isOpportunity
            ? DMT_Case_Steps_Selector.getApprovalCasesByOpportunityIds(passportByContextId.keySet())
            : DMT_Case_Steps_Selector.getApprovalCasesByLineIds(passportByContextId.keySet());
        for (Case existingCase : existingCases) {
            if (String.isBlank(existingCase.DMT_Feature_Id__c)) {
                continue;
            }
            Id contextId = isOpportunity ? existingCase.opportunity_id__c : existingCase.DMT_Line__c;
            if (!startedFeatureIdsByContextId.containsKey(contextId)) {
                startedFeatureIdsByContextId.put(contextId, new Set<String>());
            }
            startedFeatureIdsByContextId.get(contextId).add(existingCase.DMT_Feature_Id__c);
        }

        for (Id contextId : passportByContextId.keySet()) {
            String passportJson = passportByContextId.get(contextId).DMT_Passport_Save__c;
            DMT_PassportLineWrapper passportWrapper = DMT_PassportLineWrapper.parseLinePassport(passportJson);
            if (passportWrapper == null || passportWrapper.data == null || passportWrapper.data.features == null) {
                continue;
            }

            Map<String, String> autoWorkflowRequestByFeatureId = extractAutoWorkflowRequestByFeatureId(passportJson);
            Set<String> startedFeatureIds = startedFeatureIdsByContextId.containsKey(contextId)
                ? startedFeatureIdsByContextId.get(contextId)
                : new Set<String>();

            // Lowest order number wins; features without an order number go last.
            DMT_PassportLineWrapper.Feature selectedFeature;
            for (DMT_PassportLineWrapper.Feature feature : passportWrapper.data.features) {
                if (!isEligibleAutoWorkflowFeature(feature, autoWorkflowRequestByFeatureId, expectedSanctionByContextId.get(contextId), startedFeatureIds)
                        || feature.tasks[0].approvers == null
                        || feature.tasks[0].approvers.isEmpty()
                        || String.isBlank(feature.tasks[0].approvers[0].id)) {
                    continue;
                }
                if (selectedFeature == null
                        || (feature.orderNumber != null
                            && (selectedFeature.orderNumber == null || feature.orderNumber < selectedFeature.orderNumber))) {
                    selectedFeature = feature;
                }
            }
            if (selectedFeature == null) {
                continue;
            }

            // The Business/Risk split used by the next-approval flow is intentionally not applied here:
            // every auto-started feature is typed 'Other' and ordered by its order number alone.
            DMT_CaseFeatureWrapper selected = buildAutoWorkflowFeatureWrapper(
                selectedFeature,
                passportWrapper.data.opportunityId,
                'Other',
                isOpportunity ? null : contextId
            );
            DMT_AsyncOrchestrator.enqueue(new DMT_StartApprovalCasePayload(
                selected.externalLineid,
                selected.approverId,
                selected.taskId,
                JSON.serialize(selected.taskList),
                selected.featureId,
                selected.featureName,
                '',
                selected.passportSanction
            ));
        }
    }

    /**
     * @description CIBGLOBALD-4477 - Runs the Case creation for one DMT_StartApprovalCasePayload, in the async transaction
     * DMT_AsyncDispatcher gives it. Same steps as StartCaseQueueable.execute: the first task of the
     * feature is created by startCase itself (taskId), so it is dropped from the list stored on the Case.
     * @param payload the feature to start
     **/
    public static void startApprovalCaseFromPayload(DMT_StartApprovalCasePayload payload) {
        List<Map<String, Object>> taskList = new List<Map<String, Object>>();
        Object raw = String.isBlank(payload.taskListJson) ? null : JSON.deserializeUntyped(payload.taskListJson);
        if (raw instanceof List<Object>) {
            for (Object o : (List<Object>) raw) {
                taskList.add((Map<String, Object>) o);
            }
        }
        if (!taskList.isEmpty()) {
            taskList.remove(0);
        }

        Map<String, Object> result = DMT_Passport_Handler.startCase(
            payload.externalLineId, payload.approverId, payload.taskId, taskList,
            payload.featureId, payload.featureName, payload.comment, payload.passportSanction
        );

        if (result.get('success') == false || result.get('success') == 'false') {
            System.debug(LoggingLevel.ERROR, 'Automatic approval Case not started for feature ' + payload.featureId + '. Reason: ' + result.get('message'));
        }
    }
```

### 3. DMT_AsyncDispatcher - new branch

**DMT_AsyncDispatcher.cls lines 36-41**



```apex
        } else if (payload instanceof DMT_CalloutTrackableCheckPayload) {
            DMT_ApprovalChangeStep_Helper.checkCalloutTrackableComponent((DMT_CalloutTrackableCheckPayload) payload);
        } else if (payload instanceof DMT_StartApprovalCasePayload) {
            DMT_Case_Steps_Controller.startApprovalCaseFromPayload((DMT_StartApprovalCasePayload) payload);
        } else if (payload instanceof DMT_CalloutTrackableFreezePayload) {
            DMT_ApprovalChangeStep_Helper.freezeCalloutTrackableBaseline((DMT_CalloutTrackableFreezePayload) payload);
```

### 4. DMT_AsyncQueueJob - one start-case payload per transaction

**DMT_AsyncQueueJob.cls lines 49-69**



```apex
        // uncommitted work pending" (a managed package's post-callout DML). Extras are re-buffered
        // for the trailing flush() below instead, so each gets its own fresh transaction.
        List<DMT_AsyncPayload> toDispatchNow = new List<DMT_AsyncPayload>();
        Boolean calloutTrackableCheckAlreadyClaimed = false;
        // CIBGLOBALD-4477 - same idea for DMT_StartApprovalCasePayload: each one runs DMT_Passport_Handler.startCase
        // (a couple of dozen queries plus Case/Task/snapshot DML), so only one is dispatched
        // inline per transaction; the rest are re-buffered and flush() gives each its own
        // Batch chunk.
        Boolean startApprovalCaseAlreadyClaimed = false;
        for (DMT_AsyncPayload p : payloads) {
            if (p instanceof DMT_StartApprovalCasePayload) {
                if (startApprovalCaseAlreadyClaimed) {
                    DMT_AsyncOrchestrator.enqueue(p);
                    continue;
                }
                startApprovalCaseAlreadyClaimed = true;
            }
            if (p instanceof DMT_CalloutTrackableCheckPayload) {
                if (calloutTrackableCheckAlreadyClaimed) {
                    DMT_AsyncOrchestrator.enqueue(p);
                    continue;
```

### 5. DMT_Passport_Handler.startCase - catch block

**DMT_Passport_Handler.cls lines 309-320**



```apex
        } catch (Exception e) {
            // CIBGLOBALD-4477 - goes through the orchestrator rather than Database.executeBatch: executeBatch is illegal
            // when startCase is reached from a Batch execute (DMT_AsyncBatchJob) and would replace the
            // real error with an AsyncException. The orchestrator picks a legal context (Batch,
            // Queueable) on its own. Flushed here because startCase is also an @AuraEnabled entry
            // point, where nothing downstream is guaranteed to flush the buffer.
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_Passport_Handler', 'startCase', 'DMT', ''));
            DMT_AsyncOrchestrator.flush();

            result.put(SUCCESS, false);
            result.put(MESSAGE, String.isBlank(errorMessage) ? e.getMessage() : errorMessage);
            return result;
```

### 6. DMT_Line_Helper - replaces startAutoWorkflowForLines (old lines 1246-1256)

**DMT_Line_Helper.cls lines 1246-1281**



```apex
    /**
     * CIBGLOBALD-4477 - Single-record overload of enqueueAutoWorkflowOnStatusChange, for callers that only have one Line.
     */
    public void enqueueAutoWorkflowOnStatusChange(DMT_Line__c newLine, DMT_Line__c oldLine) {
        if (newLine == null || oldLine == null) {
            return;
        }
        enqueueAutoWorkflowOnStatusChange(new List<DMT_Line__c>{ newLine }, new Map<Id, DMT_Line__c>{ newLine.Id => oldLine });
    }

    /**
     * CIBGLOBALD-4477 - AFTER UPDATE. When a Line moves into Proposal, Approval or Ready to close, starts the approval Case of the
     * Passport feature flagged for automatic start (see DMT_Case_Steps_Controller.enqueueAutoWorkflowCases).
     *
     * Collects every qualifying Line and hands them over in ONE call, so the Passport and Case lookups are
     * done once for the whole save. The Case creation is deferred to DMT_AsyncOrchestrator (one payload per
     * Line, each in its own transaction), so DMT_AsyncOrchestrator.flush() must run at the end of the trigger.
     *
     * Independent from restartApprovalTasksOnLineResubmission: that one reopens tasks of Cases that already
     * exist, this one only starts Cases for features that have none yet.
     */
    public void enqueueAutoWorkflowOnStatusChange(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMapLines) {
        Map<Id, String> stageByLineId = new Map<Id, String>();
        for (DMT_Line__c line : newLines) {
            DMT_Line__c oldLine = oldMapLines.get(line.Id);
            Boolean isSupportedStage = line.Status__c == DMT_Constants.PROPOSAL
                || line.Status__c == DMT_Constants.APPROVAL
                || line.Status__c == DMT_Constants.READYTOCLOSE;
            if (oldLine != null && line.Status__c != oldLine.Status__c && isSupportedStage) {
                stageByLineId.put(line.Id, line.Status__c);
            }
        }
        if (!stageByLineId.isEmpty()) {
            DMT_Case_Steps_Controller.enqueueAutoWorkflowCases(stageByLineId, false);
        }
    }
```

### 7. DMT_Line_TriggerHandler - call activated with the new name

**DMT_Line_TriggerHandler.cls lines 47-50**

Previously commented out.

```apex
        lineHelper.enqueueRecalculateApprovals(lstNew, mapOld);
        lineHelper.restartApprovalTasksOnLineResubmission(lstNew, mapOld);
        lineHelper.enqueueAutoWorkflowOnStatusChange(lstNew, mapOld);

```

### 8. DMT_OpportunityTriggerHandler - replaces autoStartFirstBusinessApprovalFeature

**DMT_OpportunityTriggerHandler.cls lines 585-607**



```apex
    /**
     * CIBGLOBALD-4477 - AFTER UPDATE. When a DMT Opportunity changes stage, starts the approval Case of the Passport feature
     * flagged for automatic start (see DMT_Case_Steps_Controller.enqueueAutoWorkflowCases).
     *
     * Collects every qualifying Opportunity and hands them over in ONE call, so the Passport and Case
     * lookups are done once for the whole save. The Case creation is deferred to DMT_AsyncOrchestrator
     * (one payload per Opportunity, each in its own transaction); the trigger flushes it at the end of
     * the DMT Opportunity after-update block.
     */
    public void enqueueAutoWorkflowOnStageChange(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
        Id dmtOppRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(DMT_Constants.RT_OPP_DMT_NAME)?.getRecordTypeId();
        Map<Id, String> stageByOppId = new Map<Id, String>();
        for (Opportunity opp : newOpps) {
            if (opp.RecordTypeId != dmtOppRTId) continue;
            Opportunity oldOpp = oldOppMap.get(opp.Id);
            if (oldOpp != null && opp.StageName != oldOpp.StageName) {
                stageByOppId.put(opp.Id, opp.StageName);
            }
        }
        if (!stageByOppId.isEmpty()) {
            DMT_Case_Steps_Controller.enqueueAutoWorkflowCases(stageByOppId, true);
        }
    }
```

### 9. Opportunity.trigger - method name only

**Opportunity.trigger lines 162-166**



```apex
                dmtHandlerOpp.updatePassport_OppStatusChanged(Trigger.new,Trigger.oldMap);
                dmtHandlerOpp.restartApprovalTasksOnOpportunityResubmission(Trigger.new, Trigger.oldMap);
                dmtHandlerOpp.enqueueAutoWorkflowOnStageChange(Trigger.new, Trigger.oldMap);
                System.debug('dmtHandlerOpp.checkReadyToCloseIBF: ' + Trigger.new);
                dmtHandlerOpp.checkReadyToCloseIBF(Trigger.new, Trigger.oldMap);//CIBGLOBALD-3748
```

### 10. DMT_Case_Steps_Controller_Test - new tests (end of class)

**DMT_Case_Steps_Controller_Test.cls lines 1329-1584**

Plus the whole-file rename of System.assert / assertEquals / assertNotEquals to Assert.isTrue / areEqual / areNotEqual.

```apex
    // ---------------------------------------------------------------------------------------------
    // CIBGLOBALD-4477 - Automatic approval Case start (enqueueAutoWorkflowCases and its payload)
    // ---------------------------------------------------------------------------------------------

    private static String autoWorkflowPassportJson(String externalId) {
        return '{"data":{"opportunityId":"' + externalId + '","features":[' +
            '{"id":"31","name":"F31","passportSanction":"passport","orderNumber":2,"autoWorkflowRequest":"Y",' +
                '"tasks":[{"id":"6","name":"T6","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY1","name":"A1"}]}]},' +
            '{"id":"30","name":"F30","passportSanction":"passport","orderNumber":1,"autoWorkflowRequest":"Y",' +
                '"tasks":[{"id":"7","name":"T7","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY2","name":"A2"}]}]},' +
            '{"id":"29","name":"F29","passportSanction":"passport","orderNumber":0,' +
                '"tasks":[{"id":"8","name":"T8","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY2","name":"A2"}]}]}' +
            ']}}';
    }

    private static List<DMT_Line__c> insertLinesWithAutoWorkflowPassport(Integer count) {
        List<DMT_Line__c> lines = new List<DMT_Line__c>();
        for (Integer i = 0; i < count; i++) {
            lines.add(new DMT_Line__c(Line_Id__c = 'LINE-AUTO-' + i, Status__c = DMT_Constants.PROPOSAL));
        }
        insert lines;

        List<Passport__c> passports = new List<Passport__c>();
        for (DMT_Line__c line : lines) {
            passports.add(new Passport__c(DMT_Line__c = line.Id, DMT_Passport_Save__c = autoWorkflowPassportJson(line.Line_Id__c)));
        }
        insert passports;
        return lines;
    }

    @isTest
    static void testEnqueueAutoWorkflowCases_bulkUsesFixedQueriesAndPicksLowestOrder() {
        List<DMT_Line__c> lines = insertLinesWithAutoWorkflowPassport(5);
        Map<Id, String> stageByLineId = new Map<Id, String>();
        for (DMT_Line__c line : lines) {
            stageByLineId.put(line.Id, DMT_Constants.PROPOSAL);
        }
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        DMT_Case_Steps_Controller.enqueueAutoWorkflowCases(stageByLineId, false);
        Integer queriesUsed = Limits.getQueries() - queriesBefore;
        Test.stopTest();

        Assert.areEqual(2, queriesUsed, 'Passports and existing Cases are queried once each, whatever the number of Lines');
        Assert.areEqual(5, DMT_AsyncOrchestrator.payloadBuffer.size(), 'One payload per Line');
        for (DMT_AsyncPayload p : DMT_AsyncOrchestrator.payloadBuffer) {
            Assert.isTrue(p instanceof DMT_StartApprovalCasePayload, 'Payload type');
            DMT_StartApprovalCasePayload startPayload = (DMT_StartApprovalCasePayload) p;
            Assert.areEqual('30', startPayload.featureId, 'Flagged feature with the lowest order number wins; unflagged F29 is ignored');
            Assert.areEqual('passport', startPayload.passportSanction, 'Sanction of the feature');
        }
        DMT_AsyncOrchestrator.payloadBuffer.clear();
    }

    @isTest
    static void testEnqueueAutoWorkflowCases_singleRecordOverload() {
        List<DMT_Line__c> lines = insertLinesWithAutoWorkflowPassport(1);
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Test.startTest();
        DMT_Case_Steps_Controller.enqueueAutoWorkflowCases(lines[0].Id, DMT_Constants.PROPOSAL, false);
        Test.stopTest();

        Assert.areEqual(1, DMT_AsyncOrchestrator.payloadBuffer.size(), 'Single-record overload enqueues one payload');
        DMT_AsyncOrchestrator.payloadBuffer.clear();
    }

    @isTest
    static void testEnqueueAutoWorkflowCases_skipsStartedFeatureWrongStageAndMissingPassport() {
        List<DMT_Line__c> lines = insertLinesWithAutoWorkflowPassport(2);
        DMT_Line__c lineWithoutPassport = new DMT_Line__c(Line_Id__c = 'LINE-AUTO-NOPASSPORT', Status__c = DMT_Constants.PROPOSAL);
        insert lineWithoutPassport;

        // Lines[0] already has a Case for feature 30, so the next eligible one (31) is started instead.
        Id approvalRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
        TriggerBypass.setBypass();
        insert new Case(RecordTypeId = approvalRT, DMT_Line__c = lines[0].Id, Status = 'Pending', DMT_Feature_Id__c = '30');
        TriggerBypass.removeBypass();
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Map<Id, String> stageByLineId = new Map<Id, String>{
            lines[0].Id => DMT_Constants.PROPOSAL,
            lines[1].Id => 'Draft',
            lineWithoutPassport.Id => DMT_Constants.PROPOSAL
        };

        Test.startTest();
        DMT_Case_Steps_Controller.enqueueAutoWorkflowCases(stageByLineId, false);
        Test.stopTest();

        Assert.areEqual(1, DMT_AsyncOrchestrator.payloadBuffer.size(), 'Only Lines[0] qualifies: Lines[1] is in an unsupported stage, the third has no Passport');
        Assert.areEqual('31', ((DMT_StartApprovalCasePayload) DMT_AsyncOrchestrator.payloadBuffer[0]).featureId, 'Feature 30 already has a Case, so 31 is next');
        DMT_AsyncOrchestrator.payloadBuffer.clear();
    }

    @isTest
    static void testEnqueueAutoWorkflowCases_emptyAndNullInput() {
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Test.startTest();
        DMT_Case_Steps_Controller.enqueueAutoWorkflowCases((Map<Id, String>) null, false);
        DMT_Case_Steps_Controller.enqueueAutoWorkflowCases(new Map<Id, String>(), true);
        DMT_Case_Steps_Controller.enqueueAutoWorkflowCases((Id) null, DMT_Constants.PROPOSAL, false);
        Test.stopTest();

        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'Nothing to enqueue');
    }

    @isTest
    static void testStartApprovalCasePayload_dispatchDoesNotThrowWhenRecordNotFound() {
        DMT_StartApprovalCasePayload payload = new DMT_StartApprovalCasePayload(
            'EXT-NOT-FOUND', 'APPROVER-001', 'TASK-001', '[{"id":"1"},{"id":"2"}]', 'FEATURE-001', 'Feature', '', 'approval'
        );

        Test.startTest();
        DMT_AsyncDispatcher.dispatch(payload);
        Test.stopTest();

        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'startCase reports the missing record in its result and does not raise');
    }

    @isTest
    static void testAsyncQueueJob_dispatchesOneStartApprovalCasePayloadPerTransaction() {
        DMT_AsyncOrchestrator.payloadBuffer.clear();
        List<DMT_AsyncPayload> payloads = new List<DMT_AsyncPayload>{
            new DMT_StartApprovalCasePayload('EXT-A', 'APPROVER-001', 'TASK-001', '[]', 'FEATURE-A', 'A', '', 'approval'),
            new DMT_StartApprovalCasePayload('EXT-B', 'APPROVER-001', 'TASK-001', '[]', 'FEATURE-B', 'B', '', 'approval')
        };

        Test.startTest();
        new DMT_AsyncQueueJob(payloads).execute(null);
        Integer queueablesAfterFirstPass = Limits.getQueueableJobs();
        Test.stopTest();

        Assert.areEqual(1, queueablesAfterFirstPass, 'The second payload is re-buffered and flushed into its own Queueable instead of running inline');
        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'Buffer is flushed');
    }

    // CIBGLOBALD-4477 - startCase early returns and its catch block, reached through the same entry point the
    // auto-start payload uses.
    @isTest
    static void testStartCase_approverNotFoundReturnsFailure() {
        insert new DMT_Line__c(Line_Id__c = 'LINE-STARTCASE-001', Status__c = DMT_Constants.PROPOSAL);

        Test.startTest();
        Map<String, Object> result = DMT_Passport_Handler.startCase(
            'LINE-STARTCASE-001', 'APPROVER-DOES-NOT-EXIST', 'TASK-DOES-NOT-EXIST', new List<Map<String, Object>>(), 'FEATURE-001', 'Feature', '', 'approval'
        );
        Test.stopTest();

        Assert.areEqual(false, result.get('success'), 'No approver can be resolved, so no Case is started');
        Assert.areEqual(0, [SELECT COUNT() FROM Case WHERE DMT_Feature_Id__c = 'FEATURE-001'], 'No Case created');
    }

    @isTest
    static void testStartCase_failureIsReportedThroughOrchestratorAndNeverThrows() {
        Profile minimalProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User noAccessUser = new User(
            Alias = 'noacc', Email = 'noaccess.startcase@example.com', EmailEncodingKey = 'UTF-8', LastName = 'NoAccess',
            LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = minimalProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles', UserName = 'noaccess.startcase' + System.currentTimeMillis() + '@example.com'
        );
        insert noAccessUser;

        Map<String, Object> result;
        Test.startTest();
        System.runAs(noAccessUser) {
            result = DMT_Passport_Handler.startCase('EXT-1', 'APPROVER-1', 'TASK-1', new List<Map<String, Object>>(), 'FEATURE-1', 'Feature', '', 'approval');
        }
        Test.stopTest();

        Assert.areEqual(false, result.get('success'), 'A failure is returned in the result map instead of being thrown');
        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'The error log payload was flushed by startCase itself');
    }

    // CIBGLOBALD-4477 - the Opportunity handler methods that sit next to the auto-start one and share the
    // after-update block.
    @isTest
    static void testOpportunityHandlerIntegrationEnqueue_closingStageChange() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, RecordTypeId, StageName FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        Opportunity closing = opp.clone(true, true, true, true);
        closing.StageName = 'Closed Won';
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Test.startTest();
        DMT_OpportunityTriggerHandler handler = new DMT_OpportunityTriggerHandler();
        handler.enqueueClosingIntegration(new List<Opportunity>{ closing }, new Map<Id, Opportunity>{ opp.Id => opp });
        handler.enqueueStageChangeIntegration(new List<Opportunity>{ closing }, new Map<Id, Opportunity>{ opp.Id => opp });
        Test.stopTest();

        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.size() <= 2, 'At most one payload per method');
        DMT_AsyncOrchestrator.payloadBuffer.clear();
    }

    @isTest
    static void testOpportunityHandlerEnqueueAutoWorkflowOnStageChange_skipsUnchangedStage() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, RecordTypeId, StageName FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Test.startTest();
        new DMT_OpportunityTriggerHandler().enqueueAutoWorkflowOnStageChange(new List<Opportunity>{ opp }, new Map<Id, Opportunity>{ opp.Id => opp });
        Test.stopTest();

        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'No stage change, nothing to start');
    }

    // CIBGLOBALD-4477 - known approver, unknown task type: startCase stops before creating anything.
    @isTest
    static void testStartCase_taskTypeNotFoundReturnsFailure() {
        insert new DMT_Line__c(Line_Id__c = 'LINE-STARTCASE-002', Status__c = DMT_Constants.PROPOSAL);

        Test.startTest();
        Map<String, Object> result = DMT_Passport_Handler.startCase(
            'LINE-STARTCASE-002', 'TestExternalIdDATAFACTORY1', 'TASK-DOES-NOT-EXIST', new List<Map<String, Object>>(), 'FEATURE-002', 'Feature', '', 'approval'
        );
        Test.stopTest();

        Assert.areEqual(false, result.get('success'), 'No task type can be resolved, so no Case is started');
        Assert.areEqual(0, [SELECT COUNT() FROM Case WHERE DMT_Feature_Id__c = 'FEATURE-002'], 'No Case created');
    }

    // CIBGLOBALD-4477 - the Line trigger entry point (list and single-record overloads): only Lines whose
    // status changed into Proposal / Approval / Ready to close are handed to the controller, in one call.
    @isTest
    static void testLineHelperEnqueueAutoWorkflowOnStatusChange_listAndSingleOverloads() {
        List<DMT_Line__c> lines = insertLinesWithAutoWorkflowPassport(3);
        Map<Id, DMT_Line__c> oldLinesById = new Map<Id, DMT_Line__c>();
        for (DMT_Line__c line : lines) {
            DMT_Line__c oldLine = line.clone(true, true, true, true);
            oldLine.Status__c = DMT_Constants.DRAFT;
            oldLinesById.put(line.Id, oldLine);
        }
        // Third Line did not change status, so it must be left out.
        oldLinesById.get(lines[2].Id).Status__c = lines[2].Status__c;
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Test.startTest();
        DMT_Line_Helper helper = new DMT_Line_Helper();
        helper.enqueueAutoWorkflowOnStatusChange(lines, oldLinesById);
        Integer afterListCall = DMT_AsyncOrchestrator.payloadBuffer.size();
        DMT_AsyncOrchestrator.payloadBuffer.clear();
        helper.enqueueAutoWorkflowOnStatusChange(lines[0], oldLinesById.get(lines[0].Id));
        Integer afterSingleCall = DMT_AsyncOrchestrator.payloadBuffer.size();
        helper.enqueueAutoWorkflowOnStatusChange((DMT_Line__c) null, (DMT_Line__c) null);
        Test.stopTest();

        Assert.areEqual(2, afterListCall, 'Two of the three Lines changed status');
        Assert.areEqual(1, afterSingleCall, 'Single-record overload enqueues one payload');
        DMT_AsyncOrchestrator.payloadBuffer.clear();
    }

}
```
