# CIBGLOBALD-4374 - Implementation log (local, nothing deployed)

Running log used to build the final technical comment of the ticket. Every entry says what was
changed, where, and why. Counts are static counts from the source; measured numbers are added after the
before/after debug logs exist. Baseline copies of every modified file are in the session scratchpad
(`baseline/`), taken right after the fresh retrieve of 2026-10-14.

## 1. Migration map (flow element -> Apex)

| Before | After |
|---|---|
| Flow `Case_After_Trigger_Flow` (Approval Case create/update) | `DMT_Case_TriggerHandler.afterInsert / afterUpdate`, hooked in `SER_Case_TRIGGER` outside the `CIB_skip_trigger__c` block, guarded by `TriggerBypass.bypassTrigger` |
| Its `Create_Team_Member` / `Create_Team_Member_Case_Update` invocables | `DMT_TeamMember_Service.scheduleCaseRequests` -> `addApproversForCases` (one payload, `DMT_TeamMemberCasePayload`, instead of one Queueable per Case) |
| Its `StartNextCaseAutomatization` invocable (`startNextCaseApproval`) | `DMT_Case_Steps_Controller.startNextCaseApprovals` (bulk), single-Case method now evaluates in-memory criteria before any query |
| Its `Update_Approval_Date_Line` + attachment move | `DMT_Case_TriggerHandler.stampApprovalDateOnLines / moveAttachmentsToCurrentTask` |
| Its `Finished_to_Pending` branch (needs `IsDeleted = true` in after-save) | NOT ported: unreachable |
| Flow `DMT_After_Task_Trigger` | `DMT_Task_TriggerHandler` (`beforeUpdate`, `afterInsert`, `afterUpdate`), hooked in `Task.trigger` |
| Its self-update stamping `DMT_UserClosedTask__c` / `DMT_Completed_Date_Time__c` | before update stamping in the same save (no second trigger/flow pass) |
| Its three team member updates | `DMT_TeamMember_Service.syncApprovalEditAccess` (1 query, 1 update) |
| Flow `DMT_CreateLineFROMOppFeature` | `DMT_SanctionLine_Service.createFromOpportunity`; `DMT_Passport_Helper.createSanctionFromOpp` calls it |
| Manual Request (`DMT_Passport_Handler.startCase`) | synchronous validation, then one `DMT_StartApprovalCasePayload` for the Risk-in-Approval case (creates the Sanction Line); everything else stays synchronous (`startCaseNow`) |

The three flows are deactivated in the same deployment as the hooks through their FlowDefinition
(`activeVersionNumber` = 0). Setting `<status>Obsolete</status>` on the flow file was tried first and did NOT
stop the active version from running in the validation (the old flow still hit the SOQL limit).

## 2. Team members centralized

`DMT_TeamMember_Service` is now the only place that builds and saves `DMT_TeamMember__c` for the approval
process: `buildLineMember`, `buildOpportunityMember`, `insertMembers`, `updateMembers`, `deleteMembers`,
`addApproversForCases`, `syncApprovalEditAccess`, `assignParticipantsByOwnerUO`, `scheduleCaseRequests`.

Delegating callers: `DMT_CreateTeamMemberCase` (no longer Queueable), `DMT_AssignParticipantsByUO`
(body moved), `DMT_CreateTeamMemberApprover`, `DMT_cloneParticipantForLineFromFlow`, `DMT_RenewLineService`.
Flows that still create participants directly (not migrated, outside this ticket's flows):
`AfterCreateLine`, `AfterCreateOpportunity`, `DMT_Clone_Line`, `DMT_Approvers_Admin_Screen`
(the last three call the Apex above), plus the duplicated `DMT_Assign_*_Participants_By_UO` flows.

## 3. Async and callouts

- `DMT_CalloutPayload` marker interface (extends `DMT_AsyncPayload`) on payloads that can make a callout:
  `DMT_CalloutTrackableCheckPayload`, `DMT_StartApprovalCasePayload`. `DMT_AsyncQueueJob` and
  `DMT_AsyncBatchJob` dispatch at most one marked payload per transaction and re-buffer the rest.
  Candidates still unmarked (decision pending): `DMT_PassportPayload`, `DMT_DynamicMapperPayload`,
  `DMT_SnapshotPayload`, `DMT_CoreDocumentsUploadPayload`, `DMT_ConsumptionReassignPayload`,
  `DMT_IntegrationRetryPayload`, `DMT_CalloutTrackableFreezePayload`.
- Next approval Case start no longer uses `System.enqueueJob(StartCaseQueueable)`; it enqueues a
  `DMT_StartApprovalCasePayload`. The invocable and the Case handler flush the orchestrator.
- Failure of a queued Request: `DMT_Case_Steps_Controller.startApprovalCaseFromPayload` publishes
  `DMT_Task__e` with `Operation__c = REQUEST_FAILED` (`DTM_Task_Helper.publishRequestFailed`); both
  Passport LWCs show an error and stop the spinner. No new platform event.
- The line code callout (`DMT_OpportunityCodes`) is the first operation of `DMT_SanctionLine_Service`,
  before any DML, and is the only callout of that transaction.

## 4. Behavior to review (found while porting)

1. Client that is not a Subsidiary and has NO Multiholder association: the flow created the Line and ended
   with no risk lines, Passport, participants or Opportunity link, returning no Line Id. Ported as is
   (`createFromOpportunity` returns null). Looks like an unintended flow dead end.
2. `Case_After_Trigger_Flow` attachment move assigned the loop record (with its Id) to a Create Records
   element; cloned attachments are used instead. Same intent, safer mechanics.
3. `enqueueAutoWorkflowOnStageChange` (org version, all eligible features enqueued) was left untouched.
4. Standalone flows `DMT_Assign_Line_Participants_By_UO` / `DMT_Assign_Opportunity_Participants_By_UO`
   still duplicate the call made by `AfterCreateLine` / `AfterCreateOpportunity`. Not removed: reachability of
   every path was not verified.
5. `Task.trigger` hooks honor `TriggerBypass.bypassTrigger` only (the flows ignored both bypasses).

## 5. Tests

New: `DMT_TeamMember_ServiceTest`, `DMT_Case_TriggerHandlerTest`, `DMT_Task_TriggerHandlerTest`,
`DMT_SanctionLine_ServiceTest`. Data comes from `DMT_Test_DataFactory`; added there (and in
`DMT_Test_DataFactoryBuild`): `buildTeamMember`, `buildAttachment`, `generateTeamMemberForLine`,
`generateTeamMemberForOpportunity`, `generateTeamMembers`, `generateUsers`,
`generateApproverMemberForApprover`, `generateTaskType`, `generateApprovalTask`, `generateSanctionLine`,
`generateAttachment`. ## 5b. Check-only deployment results (DMT_TCM_DEV, 2026-10-14, nothing saved in the org)

Manifest components plus 15 test classes (the new ones and the existing ones of every class touched):
215 tests, 213 pass.

Fixed during the dry runs:
- `Custom_Association_Client__c.Alpha_Code__c` is not writeable: the assignment was removed (the flow
  assignment to it had no effect; `Alpha_Code_Client__c` carries the value).
- `Account.DES_Client_Type__c` is a formula: the tests set `DES_Structure_Type__c` instead.
- Flow deactivation moved from flow status to FlowDefinition (see section 1).
- Multiholder association test data needed `gf_customer_group_id__c`.

The 2 failing tests are NOT caused by this change. Running them against the unchanged org code (before this
work) gave: `testOpportunityHandlerEnqueueAutoWorkflowOnStageChange_startsMatchingFeature` failed 3 of 3
runs and `testEnqueueAutoWorkflowCases_opportunityMatchesStageSanctionWithFixedQueries` failed 2 of 3.
Likely cause: the org version of `enqueueAutoWorkflowCasesForContext` takes the newest Passport of the
Opportunity even when its saved JSON is blank (our 4477 version skipped blank ones), and the
AfterCreateOpportunity flow creates a second, blank Passport with the same CreatedDate. Left as is (org
behavior is the source of truth); worth a look by whoever owns that change.

Also failing in the org before this work, outside this change: the 6 tests of `DMT_OppToSanctionUtilsTest`
(`bbva_prtcp_tranche_amount__c` not queried by the test data).


## 6. Open

- Baseline and after debug logs to fill in the measured SOQL / DML numbers.
- Tech lead confirmation of the scope (all team member creators in this ticket).
