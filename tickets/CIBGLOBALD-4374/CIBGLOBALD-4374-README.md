# CIBGLOBALD-4374 - SOQL optimization (manual Risk request and Draft -> Proposal)

**Status: PARKED (2026-10-15).** The tech lead asked to park the ticket after receiving the proposal. Work is
committed on branch `4374` of this repository and was NOT merged to `main`. Nothing was ever deployed for real;
only check-only validations were run.

## What the ticket asks

Remove `Too many SOQL queries: 101` so the consumption no longer depends on the number of Cases, Tasks or
Multiholder clients in (1) the manual Risk request done from the Passport LWCs and (2) the Draft -> Proposal
stage change with many open Cases. Measure before/after. Keep generated/cancelled/relaunched Cases and Tasks
functionally identical.

## Where everything is

| What | File |
|---|---|
| Technical proposal for the tech lead (Spanish, two alternatives, impacts, risks, rollout) | `CIBGLOBALD-4374-propuesta-tecnica.html` (standalone) and `CIBGLOBALD-4374-propuesta-tecnica-artifact.html` (publishable variant) |
| Running implementation log (flow -> Apex map, decisions, findings, validation results) | `CIBGLOBALD-4374-implementation-log.md` |
| Full plan written before implementing | `CIBGLOBALD-4374-plan.md` |
| Memory of the whole investigation (findings round by round, decisions with dates) | `CIBGLOBALD-4374-memory.md` |
| Commit message draft for the work repository (no double quotes, no trailer) | `CIBGLOBALD-4374-commit-message.txt` |
| Original (org) copies of every file that was modified, taken right after the fresh retrieve of 2026-10-14 | `baseline-org-2026-10-14/` |
| Component list used for the check-only validations | `DMT/manifest/CIBGLOBALD-4374-package.xml` |

## State of the work

- **Alternative A (implemented, validated):** migrate `Case_After_Trigger_Flow`, `DMT_After_Task_Trigger` and
  `DMT_CreateLineFROMOppFeature` to Apex (`DMT_Case_TriggerHandler`, `DMT_Task_TriggerHandler`,
  `DMT_SanctionLine_Service`), centralize team members in `DMT_TeamMember_Service`, async Risk request,
  `DMT_CalloutPayload` marker, bulk next-case start. Flows are deactivated through `FlowDefinition`
  (`activeVersionNumber` 0) in the same deployment as the trigger hooks.
- **Alternative B (not implemented separately):** the same code WITHOUT the two trigger handlers and their
  hooks (`SER_Case_TRIGGER`, `Task.trigger`), without `DMT_SanctionLine_Service` (and the
  `DMT_Passport_Helper` change that calls it) and without the FlowDefinition deactivation. The flows keep
  calling the bulkified invocables. One small extra change is needed: make the invocable
  `startNextCaseApproval` call `startNextCaseApprovals` (bulk) instead of looping request by request.
- **Validation (check-only, nothing saved):** 215 tests, 213 pass. The 2 failures
  (`...startsMatchingFeature`, `...opportunityMatchesStageSanctionWithFixedQueries`) already fail on the unchanged
  code. 6 tests of `DMT_OppToSanctionUtilsTest` also fail without our changes.
- **Not done:** real deployment, before/after debug logs, the final Spanish technical comment of the ticket.

## Decisions that were pending when it was parked

1. Scope: A (migrate flows), B (leave the flows), or B now and A later (the proposal recommends B first).
2. Whether all team member creators stay in this ticket or only the Case and Task flows.
3. Acceptance of the asynchronous Risk request.
4. For A: acceptance of one call each in the shared triggers `SER_Case_TRIGGER` and `Task`.

## How to resume

1. `git checkout 4374` (the work is on that branch; `main` does not contain it).
2. Retrieve everything in scope again from the org (the org is the source of truth and others work in it):
   classes `DMT_Async*`, `DMT_*Payload*`, `DMT_Passport*`, `DMT_Case_Steps*`, `DMT_CreateTeamMember*`,
   `DMT_AssignParticipantsByUO*`, `DMT_cloneParticipant*`, `DMT_RenewLineService*`, `DMT_TeamMember*`,
   `DMT_OppToSanction*`, `DMT_Test_DataFactory*`, `DTM_Task_Helper*`, `SER_CaseTriggerHandler`; triggers
   `Task`, `SER_Case_TRIGGER`, `Opportunity`; the three flows and the lwc `dmt_passport*`, `dmt_feature*`.
3. Compare the fresh org copies with `baseline-org-2026-10-14/`: any difference is someone else's change made
   while this was parked and must be merged into our versions before anything is deployed.
4. Re-run the check-only validation (the user authorizes it at that moment):
   `sf project deploy start --dry-run --target-org DMT_TCM_DEV --manifest manifest/CIBGLOBALD-4374-package.xml
   --test-level RunSpecifiedTests --tests <list in the implementation log> --wait 90`. A run takes about
   8 to 10 minutes.
5. Take the before/after debug logs (Multiholder Risk request, Draft -> Proposal with many Cases) and fill the
   measured numbers into the final comment.

## Things worth remembering

- Setting a flow file to `Obsolete` does NOT stop the active version; use `FlowDefinition`.
- `Account.DES_Client_Type__c` is a formula; set `DES_Structure_Type__c` in test data.
- `Custom_Association_Client__c.Alpha_Code__c` is not writeable.
- The new test rule: test data comes from `DMT_Test_DataFactory` (documented in the global CLAUDE.md).
- Behaviors found but not decided: the Line dead end for non-Subsidiary clients without Multiholder, the
  unreachable `Finished_to_Pending` branch, duplicated participant assignment by UO, and the org re-implementation
  of the auto-start that can pick a blank Passport.
