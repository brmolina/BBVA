# CIBGLOBALD-4811 - Restart warning driven by the real restart gate

## Principle (user, 2026-10-29)
Warn only when the save / stage change would really reopen features, using the SAME comparison as the trigger. Nothing is saved
to check. OK -> the normal save / stage update runs and the trigger reopens as today. Cancel -> nothing is saved, the user is
back where they were (tab: edit mode with the typed values; path: stage unchanged). A failing check logs and lets the action go on.

## The three trigger checkpoints (Opp and Line are identical since 4117 / 10-19)
| Checkpoint | When | Cases checked (Case.DMT_Passport_Sanction__c) | UI action that causes it |
|---|---|---|---|
| 1 | Draft -> Proposal, old DMT_DateToProposal__c set (resubmission) | passport | stage path |
| 2 | Proposal -> Approval | approval | stage path |
| 3 | any save while already in Ready to close | readytoclose | tab save |
Opportunity: DMT_OpportunityTriggerHandler.restartApprovalTasksOnOpportunityResubmission (L551), record type DMT_Opportunity only,
StageName. Line: DMT_Line_Helper.restartApprovalTasksOnLineResubmission, record types TreasurySettlement / OtherProducts only
(Sanction never), Status__c. Conditions read from oldMap: 1 = old Draft AND new Proposal AND old DMT_DateToProposal__c != null;
2 = old Proposal AND new Approval; 3 = old Ready to close AND new Ready to close. Cases: Opportunity by opportunity_id__c, Line by
its lookup, filtered by DMT_Passport_Sanction__c. Any other transition or stage (entering Ready to close, tab saves in
Draft / Proposal / Approval, Sanction Lines, non-DMT Opportunities) reopens nothing -> no warning.
The rule moves to one shared method used by both triggers and the preview, so the LWC never re-implements it.

## Already reopened -> no second warning
Which tasks can be reopened is decided by the gate's task filter (getRestartableTasks): Status != Cancelled AND
DMT_Not_Restart__c = false AND DMT_ViewStatusAtClose__c != null. A reopen cancels the stale tasks and creates ONE replacement
per Case with DMT_ViewStatusAtClose__c = null (createResetTask), Case back to Pending. So a second save finds no reopenable task
on that Case: no reopen and, because the preview uses the same filter, no warning. A new snapshot exists only when an approver
closes the replacement task (updateTaskWithStatus); from then on changes warn again. An open task that DOES carry a snapshot
(frozen at creation by the approval flow) is reopenable, and the warning shows, exactly as the trigger would act.
Hence the preview must reuse the gate (task filter + snapshot compare), never compare snapshots on their own.

## Today's UI (org copies, 2026-10-29)
- dmt_custom_path_line (L263): when leaving Draft with DMT_DateToProposal__c set, calls the legacy
  DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase and shows an info toast (no Cancel). Missed in 4117: it still uses
  the old comparison over ALL Cases, so after the 10-19 checkpoint split it lists approval Cases at Draft -> Proposal that the
  trigger no longer reopens, and shows nothing at Proposal -> Approval.
- dmt_custom_path_opp: no warning.
- Tabs: only dmt_opp_client warns, without comparing (stage Ready to close + an open readytoclose Case). Line tabs: none.

## Phase 1 - stage path, Opportunity and Line (checkpoints 1 and 2)
No change tracking needed: at a stage change the data is already saved; the only change is the target stage.
Backend:
- DMT_ApprovalChangeStep_Helper: extract `findStaleTasks(...)` from restartStaleApprovalTasks (trigger behaviour unchanged) and add
  the shared stage rule `sanctionForStageChange(oldStage, newStage, oldDateToProposal)`; DMT_OpportunityTriggerHandler and
  DMT_Line_Helper use it instead of their inline conditions.
- Preview entry = overload DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase(recordId, targetStage[, changes]) that
  delegates to the gate (no new controller class) -> FeatureChangeWrapper (featureName, taskToRecreate).
  Pre-check: no open task with a snapshot -> empty. Record + child rows read like the freeze does, then findStaleTasks.
  logPreviewFailure for the fail-open path (DMT_LogExceptionPayload).
- Org callers of previewCompareTasksFromCase (full Apex / LWC / Aura / VF / FlexiPage search, DMT_TCM_DEV 2026-10-30):
  dmt_custom_path_line.js L267 (live, on FlexiPage Sanction_Line_RP), dmt_custom_path_refactor.js L166 (deployed, not placed
  in any page or component), DMT_ApprovalChangeStep_test L155 / L189. DMT_Massive_Task_Closure_Service L109 and
  DMT_ApprovalChangeStep_Selector L14 only name it in comments (they share getCasesByIds). The one-argument signature cannot be
  deleted while dmt_custom_path_refactor imports it.
- Why the legacy body is not reused: it is a second comparison that disagrees with the gate (all Cases, no
  DMT_Passport_Sanction__c filter; returns unchanged Cases with changedFields null; own compare rules instead of tracked fields +
  DMT_SnapshotChildComparator; synchronous HPG callouts; compared values come from its own dynamic query, so passing the record in
  would not be enough). The gate already takes in-memory records (Trigger.new), so the record-in / query-if-null overload goes there.
Front end:
- dmt_custom_path_opp and dmt_custom_path_line: before the stage update, previewRestart(recordId, nextStage); features ->
  LightningConfirm listing them; OK -> stage update as today; Cancel -> stage unchanged.
- Remove the legacy toast from dmt_custom_path_line. The one-argument previewCompareTasksFromCase stays (dmt_custom_path_refactor
  still imports it) unless the user decides otherwise.
Test end to end before phase 2.

## Phase 2 - tab saves in Ready to close, field-only tabs (checkpoint 3)
Change tracking is half there: every Opp tab saves through the shared footer c-dmt_docked_form_footer (onsave -> tab.handleSave),
and dmt_opp_info / dmt_opp_client / dmt_opp_commercial_process_data already copy their fields when edit mode starts
(`_snapshot = { fields: this.fields.map(f => ({...f})) }`, used today to restore on Cancel). Field id = API name.
Change set = fields whose value differs from the _snapshot copy; empty -> no call, no warning. Apex overlays it on the stored
record and decides which fields are tracked (renderers), so no field-definition review is needed for these tabs.
- Shared JS module dmtRestartAwareSave (change set + check + confirm). Remove dmt_opp_client._confirmReadyToCloseModify and
  its getCasesByOpportunity call; inline edit path uses the module too.

## Phase 3 - tabs with child rows
Client selection (DMT_Opportunity_Client__c, DMT_Custom_Association_ClientOpportunity__c), Products (OLI, tenors, mitigants,
underlyings), Approval Process Data (business plans), Underwriting (sold orders), Line tabs that are editable in Ready to close.
Each needs its own change set for rows (changed / added / removed) and DMT_SnapshotChildComparator gets the in-memory overlay.
Saves that do not update the parent get `reopenConfirmed`: after OK they run `update new Opportunity(Id = ...)` at the end of
their own transaction so the trigger reopens (org metadata: an OLI save updates the Opportunity only on insert with amount,
delete, or deal amount / currency / notional / date changes - DMT_OpportunityLineItemHandler, flow
DMT_Set_Opp_Dates_From_Opp_Line_Items).

## Decisions 2026-10-30 (user)
- Entry point: previewCompareTasksFromCase(recordId, targetStage[, changes]) keeps its name; the body runs the gate (shared
  stage rule incl. record type, task filter, findStaleTasks). The legacy comparison loop goes.
- HPG callout-tracked values: compare the Salesforce data first. Any stale task found -> warn, no callout. None found ->
  callout (fetchLiveTrackedValues) and compare the callout-tracked values. Callout fails -> log, no warning. The callout is
  safe here: one record per call from the UI, unlike the bulk trigger, which defers it to async.
- dmt_custom_path_refactor: update its call to the new signature (passes the target stage). The record type rule lives in Apex
  (shared with the triggers), so any path calling the preview from any page follows the trigger rule (Sanction -> no warning).

- UX kept as it is today (user, 2026-10-30): stage change (path) = information only, the c-dmt_customtoast 'Features to Be
  Reopened' (feature, owner, fields), no Cancel; Ready to close tab save = confirmation (LightningConfirm, Cancel / OK) as the
  Client tab does today. The path calls the preview BEFORE the stage update (today both run at the same time, L267 / L412).
- Warning content: feature + owner + changed fields; field labels from the renderers' DMT_FormattingUtils.DisplayField (describe
  label fallback), child changes as the section name, HPG as the component name. isTaskStale collects differing keys with a
  stop-at-first switch (trigger keeps stopping at the first difference).

- Phase 1 findings 2026-10-30: @AuraEnabled cannot be overloaded, so previewCompareTasksFromCase changed signature to
  (recordId, targetStage) (the changes parameter arrives in phase 2). c-dmt_customtoast never existed in any template, so the Line
  toast never showed (only a console error); the tag is now in dmt_custom_path_line and dmt_custom_path_opp.
- Fix 3 (skip checkpoint 3 on lock-only updates) HELD until phase 3: a child-only save in Ready to close does not update the
  parent, and today the lock release is what fires the gate and reopens. Shipping it first would silently stop those reopens.

## Known behaviour left as is (user, 2026-10-30)
The warning covers saves made through the UI (path, tab Save). Any other update of an Opportunity / Line in Ready to close
(integrations, batches, record-triggered automations such as the OLI handler or flow DMT_Set_Opp_Dates_From_Opp_Line_Items when
they are not started by a tab save) still runs the trigger gate and reopens without a warning, as it does since 4117 / 10-19.
To revisit later.

## Anti-patterns found (phase 1 code, 2026-10-29)
User decision 2026-10-29: fix 1, 2, 3 (Enhancement to existing process), 5; leave 4; 6 and 7 go with the plan.
1. DMT_OpportunityTriggerHandler.restartApprovalTasksForOpportunities passes newOppsById.values() (every Opp in the trigger) to the
   gate instead of the qualifying ones; DMT_Line_Helper passes newLines. cloneRecords + mergeRelationshipFields (SOQL) then run
   on records that cannot match.
2. Sanction values hardcoded: 'approval' / 'readytoclose' (both triggers, DMT_ModalSaveController) and 'passport' although
   DMT_Constants.FEATURE_GC_PASSPORTSANCTION exists. No constant for approval / readytoclose.
3. Checkpoint 3 runs on every update in Ready to close, including the edit-lock writes (Opp lock field from dmt_opp_custom_page,
   DMT_LineController.setLineEditLock): 1 Case SOQL + gate each time edit mode opens or closes.
4. One Case query + gate run per checkpoint (3 calls); only bulk updates with mixed stages pay it, single UI saves hit one.
5. dmt_custom_path_line: debug console.log ('result JACG', 'JACG Entro aqui', 'nextStage'), stage literals; block being replaced.
6. DMT_ModalSaveController.getCasesByOpportunity is cacheable=true: after a reopen the cached answer is reused (removed in phase 2).
7. previewCompareTasksFromCase: second comparison implementation, nested loops, HPG callouts during a preview. Not deleted:
   dmt_custom_path_refactor still imports it (org check 2026-10-30); dmt_custom_path_line moves to the gate-based overload.

## Rules
Retrieve fresh before editing; anti-pattern list confirmed before coding (per phase); markers // CIBGLOBALD-4811; Assert class;
test data per DMT test architecture; deploy only DMT_TCM_DEV with RunSpecifiedTests, org vs local compare, Status line.
