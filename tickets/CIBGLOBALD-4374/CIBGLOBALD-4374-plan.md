# CIBGLOBALD-4374 - SOQL optimization: manual Risk request and Draft -> Proposal

Status: PLAN (nothing implemented yet). Written 2026-10-14. Source of truth for code is the org: every
step starts with a fresh retrieve, our changes are applied on top, then handed back for the user to deploy.

## 1. Goal

`Too many SOQL queries: 101` must stop depending on the number of Cases / Tasks / Multiholder clients.

Acceptance (measured, not assumed):
- Manual Request of a Risk feature on a Multiholder Opportunity: SOQL count is the same for 1 and for N holders.
- Draft -> Proposal with 1 and with 50+ open Cases: SOQL count is the same.
- The same Cases / Tasks are generated, cancelled and relaunched as today (functional parity).

## 2. What was verified in the code (2026-10-14, org copy)

### 2.1 Manual Request path
`dmt_feature_with_workflow.startCase` (and `dmt_passport.startCase`) -> `DMT_Passport_Handler.startCase`
-> `startCaseInternal`:
1. ~6 selector queries (approver, task type, line by external id, opportunity, approval-edit tasks, cases by feature).
2. If Opportunity is in Approval and the approver type is Risk: `DMT_Passport_Helper.createSanctionFromOpp`
   launches flow `DMT_CreateLineFROMOppFeature` (synchronously, in the user transaction).
3. `createCase` (insert, plus a parent-Case query on renewals), `createTask` (insert via `DMT_WithoutSharingDAO`).
4. Case / Task triggers and flows fire (see 2.3).

### 2.2 Flow `DMT_CreateLineFROMOppFeature`
- ~13 lookups, no DML in loops (the multiholder loop only assigns, then one bulk create).
- Invocables: `DMT_OpportunityCodes` (HTTP callout through IASO, synchronous), `DMT_PassportProfitabilityProcessor.obtenerProfitability`
  (queries inside its request loop), `DMT_OppToSanctionUtils.createRiskLinesAndWarranties` (already bulk).
- DML: Line, `Custom_Association__c`, `Custom_Association_Client__c` list, Line update, Passport, `DMT_TeamMember__c` list,
  Opportunity update (`DMT_Sanction__c`).
- Side effects inside the same transaction: Opportunity after-update chain, Line after-update chain,
  Risk Line Term flow `BeforeCreateUpdateRiskLine` per created term.

### 2.3 Case / Task flows
- `Case_After_Trigger_Flow` (Approval Case only): create -> `DMT_CreateTeamMemberCase`; every update ->
  `DMT_CreateTeamMemberCase` + `DMT_Case_Steps_Controller.startNextCaseApproval`; Finished + Line in Approval -> stamps
  `DMT_Approval_Date__c` and moves Case attachments to the current Task. Branch `Finished_to_Pending` requires
  `IsDeleted = true` in an after-save update: looks unreachable (to confirm).
- `DMT_After_Task_Trigger` (`DMT_Step_Approval` Tasks): insert -> Asset Allocation flag on Opportunity, approval-edit team
  member creation; update to Completed / Cancelled / Finished -> stamps completed date and user on the Task itself,
  then three filtered `DMT_TeamMember__c` updates unless the Line is Closed Won.
- `DMT_CreateTeamMemberCase.processCase`: 5-6 SOQL and up to 3 DML per Case, sync when already async, otherwise one
  Queueable per Case (50-enqueue limit).
- `startNextCaseApproval`: 1 SOQL (`getTasksByCase`) per Case save before its closing guard, loops request by request,
  starts Cases with `System.enqueueJob(StartCaseQueueable)` instead of the orchestrator.

### 2.4 Draft -> Proposal
Opportunity after update (DMT RT): `restartApprovalTasksOnOpportunityResubmission` (4117, grouped queries; <10 records
sync via `restartTasksForRecord`, otherwise `DMT_RestartApprovalTasksPayload`), `enqueueAutoWorkflowOnStageChange`
(org version re-implemented by someone else: all eligible features enqueued; KEEP org behavior), snapshots,
notifications, `AfterCreateOpportunity` flow. The Case resets done by the restart fire the Case flow per Case
(2.3), which is where the per-Case cost enters.

### 2.5 Other duplicated team-member logic
- Flows creating / updating `DMT_TeamMember__c`: AfterCreateLine, AfterCreateOpportunity,
  DMT_Assign_Line_Participants_By_UO, DMT_Assign_Opportunity_Participants_By_UO (the last two duplicate the invocation
  already made by the first two), Case_After_Trigger_Flow, DMT_After_Task_Trigger, DMT_Approvers_Admin_Screen, DMT_Clone_Line.
- Apex: DMT_CreateTeamMemberCase, DMT_CreateTeamMemberApprover, DMT_AssignParticipantsByUO,
  DMT_cloneParticipantForLineFromFlow, DMT_RenewLineService.
- Read / delete only: DMT_BeforeCreateLine, DMT_CreateLineFROMOppFeature, Clone_Opportunity, DMT_DeleteGodLines, DMT_DeleteOpportunity.

### 2.6 Async framework (as is)
`DMT_AsyncOrchestrator.flush` -> Batch (size 1) when more than one payload or queueable used, else Queueable;
`DMT_AsyncQueueJob` pushes more than 5 payloads back to Batch and hardcodes "one `DMT_CalloutTrackableCheckPayload`
per transaction". Org async budget `DailyAsyncApexExecutions` max 852,400.

## 3. Target design

### 3.1 Single team member service - `DMT_TeamMember_Service`
Bulk-only API (collections in, one query per object, one DML per operation). Planned methods (names provisional):
- `addApproversForCases(Set<Id> caseIds, Boolean sanctionEdit)` - replaces `DMT_CreateTeamMemberCase.processCase`.
- `syncApprovalEditAccess(...)` - the three team member updates of `DMT_After_Task_Trigger`.
- `assignParticipantsByOwnerUO(Set<Id> recordIds)` - replaces `DMT_AssignParticipantsByUO` body (the invocable stays as a thin
  wrapper until its flows are retired).
- `createForApproverMembers(...)` - replaces `DMT_CreateTeamMemberApprover` body.
- `cloneForLine(...)` - replaces `DMT_cloneParticipantForLineFromFlow` / `DMT_RenewLineService` team member part.
Existing invocable classes keep their signatures and delegate, so flows not in scope keep working.
`DMT_CreateTeamMemberCase` as a Queueable disappears: the work runs in the caller transaction when already bulk/async,
otherwise through a payload on `DMT_AsyncOrchestrator`.

### 3.2 Case handling in `SER_Case_TRIGGER`
New DMT hook placed OUTSIDE the `CIB_skip_trigger__c` block, guarded only by `TriggerBypass.bypassTrigger`, restricted
to Approval record type (decision 2026-10-14; can be moved into the custom-setting block later). Handler
`DMT_Case_TriggerHandler` (extends the existing `DMT_TriggerHandler` pattern) replaces `Case_After_Trigger_Flow`:
- afterInsert: `DMT_TeamMember_Service.addApproversForCases`.
- afterUpdate: same, plus Finished-in-Approval-Line stamping and attachment move (bulk), plus next-case start.

### 3.3 Task handling in `Task.trigger`
DMT hooks next to the existing `DTM_Task_Helper` calls (outside the bypass block, same as today). Handler `DMT_Task_TriggerHandler`
replaces `DMT_After_Task_Trigger`. The self-stamp of completed date / user moves to BEFORE update (no after-save
self-update, which currently re-fires triggers and flows).

### 3.4 Next-case start bulkified
`startNextCaseApproval` logic moves to a service method taking all closed Cases at once: one Tasks query, one Passports
query, one Cases query, one approver-type query for the whole batch; the starts are enqueued as payloads
(`DMT_StartApprovalCasePayload`) through the orchestrator, not `System.enqueueJob`. The retired-flow invocable remains
as a wrapper while the flow exists.

### 3.5 Sanction Line service - replaces `DMT_CreateLineFROMOppFeature`
`DMT_SanctionLine_Service.createFromOpportunities(Set<Id> oppIds)`:
1. One query set for Opportunities, Accounts, existing Sanction / OtherProducts lines, record types (cached), Opportunity
   clients, custom associations (+ clients), products, participants.
2. Callout for the line code (`DMT_OpportunityCodes`) is the FIRST operation and the ONLY callout of the transaction; DML
   only after it (avoids uncommitted-work with the IASO log).
3. One insert per object: Line, Custom_Association__c, Custom_Association_Client__c, Passport, DMT_TeamMember__c
   (through `DMT_TeamMember_Service`), Risk Line Terms / Warranties / Currency Provisions (reuse
   `DMT_OppToSanctionUtils`), then one Line update and one Opportunity update.
4. Profitability values read once per Opportunity (new bulk method next to `obtenerProfitability`).
The flow stays in the org (retired by the user) once the Apex path is live.

### 3.6 Async Risk request
- `startCase` keeps a SYNCHRONOUS pre-validation (approver, task type, feature already started, approval-edit block) so
  the user sees those errors immediately.
- The heavy part (sanction Line creation, Case, Task) is enqueued as a payload through `DMT_AsyncOrchestrator`.
- Success feedback: no new event. The Task insert already publishes `DMT_Task__e` (`CREATE`, keyed by Opportunity Id),
  which the Passport LWCs consume.
- Failure feedback: a new `Operation__c` value on the SAME event (for example `REQUEST_FAILED`, `records__c` = Opportunity
  Id) and the error persisted where the LWC can read it (field on Passport / Opportunity, to be chosen). The user
  messages stay in the existing exception log.
- Batch execution is one payload per transaction, so a callout payload never shares a transaction with another callout.

### 3.7 Callout-aware payloads
Marker interface on the payload classes (small), not on the large service classes: `DMT_CalloutPayload`. `DMT_AsyncQueueJob`
and `DMT_AsyncBatchJob` enforce one callout payload per transaction generically; the 4117 special case becomes one
implementer. Optional guard at the single choke point (`DMT_HPG_Utils.callService`) counting callouts per transaction.
Where a large class mixes callout and non-callout work, split only the callout entry point into its own class.

### 3.8 Naming
New code is English and consistent: Automation (not Automatization), Sanction, Approval, no Spanglish. The flow element
`StartNextCaseAutomatization` disappears with the flow; typos listed in the ticket notes are not carried over. Existing
object and field API names are not renamed.

## 4. Flow -> Apex migration map

| Flow element | Replaced by |
|---|---|
| Case_After_Trigger_Flow: Create_Team_Member / _Case_Update | `DMT_TeamMember_Service.addApproversForCases` |
| Case_After_Trigger_Flow: StartNextCaseAutomatization | `DMT_NextCaseStart_Service` + payloads (3.4) |
| Case_After_Trigger_Flow: Update_Approval_Date_Line, attachment move | `DMT_Case_TriggerHandler` bulk methods |
| Case_After_Trigger_Flow: Get_First_Task ... Update_Case_Owner (Finished_to_Pending) | NOT ported until confirmed reachable |
| DMT_After_Task_Trigger: asset allocation, approval-edit, team member updates, user stamp | `DMT_Task_TriggerHandler` (+ team member service) |
| DMT_CreateLineFROMOppFeature | `DMT_SanctionLine_Service` (3.5) |
| DMT_Assign_Line_Participants_By_UO / DMT_Assign_Opportunity_Participants_By_UO | removed as duplicates after verifying AfterCreateLine / AfterCreateOpportunity reach the same call on every path |

## 5. Work packages (order)

0. Retrieve everything again (classes, triggers, flows, LWCs, `DMT_Test_DataFactory`); capture baseline debug logs
   (user) for: manual Risk request on Multiholder Opportunity, Draft -> Proposal with many Cases.
1. `DMT_Test_DataFactory`: add team member, multiholder association, approval Case / Task helpers needed below.
2. `DMT_TeamMember_Service` + tests; existing invocable classes delegate.
3. `DMT_Case_TriggerHandler` + `SER_Case_TRIGGER` hook + tests (parity of every branch of the flow).
4. `DMT_Task_TriggerHandler` + `Task.trigger` hook + tests.
5. Next-case start bulkification + tests.
6. `DMT_SanctionLine_Service` + tests; `DMT_Passport_Helper.createSanctionFromOpp` calls it.
7. Async Risk request (pre-validation, payload, failure feedback) + LWC changes + tests.
8. Callout payload interface + queue / batch changes + tests.
9. Measurement after, comparison with baseline; Spanish technical ticket comment.

Each package is delivered locally with the list of touched files; the user diffs, stages and deploys (deploys are only
run by Claude when the user names the elements at that moment).

## 6. Cutover and risks

- Flows and Apex must never run together: the Apex hook and the flow deactivation (status change of the flow files in
  the same deployment) go live in ONE deployment, otherwise team members / Cases would be processed twice.
- Execution order changes: record-triggered flows run after the Apex after-triggers; handlers will run in the trigger.
  Parity tests must cover create / update of Case and Task for each branch.
- Flows ignore `CIB_skip_trigger__c`; the DMT hook keeps ignoring it on purpose (decision above).
- `SER_Case_TRIGGER` is not a `DMT_` component: the hook is a single call; mention in the commit message if ANS review is needed.
- Fault paths of the flows (`Custom_error_*`) must be mapped to equivalent error handling, not silently dropped.
- LWC behavior change (async Risk request): coordinate toast / spinner text with the user.
- The re-implemented org `enqueueAutoWorkflowOnStageChange` is kept as is (no changes in this ticket).
- Per-record cost unknown until baseline logs exist; plan numbers are static counts from the source.

## 7. Open points

1. Confirmation from the tech lead on scope (all team member creators in this ticket).
2. Reachability of the `Finished_to_Pending` branch of the Case flow.
3. Where the persisted failure message of an async Risk request is stored (Passport vs Opportunity field).
4. Baseline debug logs from the user.
