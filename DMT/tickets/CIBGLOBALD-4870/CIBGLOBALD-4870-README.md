# CIBGLOBALD-4870 - dmt reinicio de casos cuando se cierra una tarea en Ready to close

Company branch: `feature/CIBGLOBALD-4870-dmt-reinicio-de-caos-cuando-se-cierra-una-tarea-en-ready-to-close`

## Bug

Opportunity in Ready to close, business readytoclose feature (e.g. Business Approval Confirmation - Global NBC): closing the
last task with the final decision leaves two tasks Cancelled (result Yes) and one new task Finished without result; the
traffic light goes grey. Reproduced natively in DMTPRE2 on 2026-11-10 (Opportunity 006KI000005e91HYAQ, Case 07182677).

Chain:
1. `DMT_ApprovalTemplate_Controller.finishCaseCondition` step 3 -> `DMT_CaseOwnerType_Handler.getOwnerCaseTypes` stamps
   `Opportunity.DMT_Bussiness_Approved_Date__c` (Business approver queues only, so risk features never hit it).
2. That Opportunity save in Ready to close runs the 4117 readytoclose checkpoint
   (`DMT_OpportunityTriggerHandler.restartApprovalTasksOnOpportunityResubmission`).
3. The release `DMT_SnapshotChildComparator` compares each child section with the fields of EVERY tracked component, not
   only the components of the task's view. Fields of other views (`DMT_AA_Industry__c`, `DMT_Group_Engagement_Plan__c` on
   `DMT_Opportunity_Client__c`) are missing in the frozen row, so the rows always differ: any Opportunity save restarts.
4. `restartTasksForRecord` cancels the tasks and creates a replacement; `finishCaseCondition` step 5
   (`finishRelatedTasks`) finishes the replacement without result.

Fix: the child comparison only uses the fields of the task's own components (`DMT_TaskStatusWhenCompleted__c.DMT_TrackedComponents__c`).
The code is the CIBGLOBALD-4811 version already in DMT_TCM_DEV, staged partially. The trigger handlers do not change.

## What to retrieve from DMT_TCM_DEV

- ApexClass `DMT_ApprovalChangeStep_Helper`
- ApexClass `DMT_SnapshotChildComparator`
- ApexClass `DMT_SnapshotChildComparatorTest`

## What to stage (search `CIBGLOBALD-4870`)

Every line to stage carries `CIBGLOBALD-4870`. A marker on a comment line covers the block right below it (up to the end
of that method or block). Lines without the marker belong to CIBGLOBALD-4811 only and must NOT be staged.

### DMT_ApprovalChangeStep_Helper (6 markers)
1. Interface `SnapshotChildComparator`: the `hasChanges(..., List<String> componentNames)` line. Do not stage the
   `changedComponents` line below it.
2. `isTaskStale`: stage only the line `return childComparator.hasChanges(recordId, snapshotJson, trackedComponentsForSnapshot(snapshot));`
   and the removal of the release line `return childComparator.hasChanges(recordId, snapshotJson);`. Do not stage the
   `changes` parameter, the `if (changes == null)` lines, `changedComponents` or the `valueChanged` call on the parent fields.
3. `valueChanged`: the whole method with its comment (new method).
4. `rowsDiffer` with 3 parameters: its body becomes `return rowsDiffer(frozenRows, liveRows, trackedFields, null);`.
   Stage the removal of the release body too.
5. `rowsDiffer` with 4 parameters: the whole method with its comment (new method).

### DMT_SnapshotChildComparator (17 markers)
1. The two member maps `fieldsBySectionRecordAndComponent` and `objectApiNameBySection`.
2. `forRecords(Map)` now delegates: `return forRecords(recordsById, null);`, plus the new header
   `forRecords(Map, List<String> componentNames)` with its comment. The rest of the method body is the release body plus the
   marked lines (componentFieldsBySectionAndRecordType map and its block, the loop header with `componentNames`,
   `componentFieldsByRecordId` and its `put`, and the two `comparator.….put` lines).
3. `hasChanges(..., componentNames)` with its comment, replacing the release `hasChanges(Id, Map)` (stage the removal).
4. `componentFields` and `sectionDiffers` (new methods).
5. Do NOT stage: `applyUnsavedRows`, `newRowPlaceholderId`, `changedComponents`.

### DMT_SnapshotChildComparatorTest (4 markers)
1. The two `comparator.hasChanges(queriedLine.Id, snapshotJson, null)` lines (replace the release 2-parameter calls).
2. The two asserts with `'Line Info'` (hasChanges false, forRecords null).
3. Do NOT stage: the `changedComponents` asserts, `testApplyUnsavedRowsComparesTheUnsavedValue`,
   `testApplyUnsavedRowsAddedAndDeletedRowsAreChanges`.

## Deploy / tests

- DMT_TCM_DEV: markers deployed 2026-11-10 (comments only, NoTestRun, Status Succeeded, org = local); tests
  DMT_SnapshotChildComparatorTest, DMT_ApprovalChangeStep_HelperTest, DMT_ApprovalChangeStep_test: 37/37 passed.
- With RunSpecifiedTests, `DMT_ApprovalChangeStep_Helper` needs coverage from more test classes than these three
  (32 % with them). Release validation runs the full suite.
- This partial version (release + marked lines) cannot be compiled in any org before the release validation:
  DMTPRE2 accepts no deploys and DMT_TCM_DEV holds the full 4811 code.

## DMTPRE2 validation (check-only, 2026-11-10)

The files in `expected-staged-result/` (release + the 4870 lines) were validated in DMTPRE2 with `--dry-run`:
Status Succeeded, 0 component errors, 58/58 tests passed (DMT_SnapshotChildComparatorTest, DMT_ApprovalChangeStep_HelperTest,
DMT_ApprovalChangeStep_test, DMT_OpportunityTriggerHandler_Test, DMT_Line_TriggerHandler_Test), no coverage warning.
Nothing was deployed. Use these test classes for the real deploy.
