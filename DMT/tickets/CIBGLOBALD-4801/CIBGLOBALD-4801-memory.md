---
name: cibglobald-4801
description: "ROLLED BACK in DMT_TCM_DEV 2026-11-12, ticket will NOT be delivered; was: required Passport features (requiredType Y + requiredStatus) block the move to Ready to close"
metadata:
  node_type: memory
  type: project
  originSessionId: 8907f21a-cf11-4f5f-a8f5-fdc58447b029
  modified: 2026-11-10T11:08:44.573Z
---

**Ticket:** feature/CIBGLOBALD-4801-dmt-bugfix-validacion-de-features-requeridas-por-passport-al-avanzar-a-ready.
Automatic move Approval -> Ready to close must also check every Passport feature mandatory for RTC (any sanction), not only approval features.
Session started 2026-11-10. Shared tree was on branch 4811 with another session's WIP: investigated from scratchpad retrieves only,
no branch created yet (personal repo branch will be `4801`).

**JSON attribute names (verified in data):** requiredType ('Y'/'N'/null; ticket's 'requiredInd' does not exist), requiredStatus
(uppercase: 'READY TO CLOSE', 'CLOSED WON', 'APPROVAL'), requiredColorCapability, requiredColorWorkflow (';' lists, e.g. GRE;RED;GRA),
colorLogicalOperatorType (AND/OR/null), stateName = capability color. DMTPRE2 real case: passport-sanction feature 226 Asset Allocation
Validation, Y + READY TO CLOSE (Opp 006KI000005evvHYAQ). DEV data has almost no Y+RTC (2 approval features).

**Auto-advance paths (DEV org 2026-11-10):**
- Opp: Case_After_Trigger_Flow action StartNextCaseAutomatization -> DMT_Case_Steps_Controller.startNextCaseApproval (invocable, loops
  requests) -> processStartNextCaseApproval -> moveStatusToReadyToClose(oppId) at 2 sites: auto-workflow branch (no pending auto/manual
  approval features) and the else branch (no next approval feature). No required-feature check at all.
- Line: DMT_Line_Helper.avoidPassingApproval (before update, size 1) -> checkApprovalValidation(lineId) -> Status__c = Ready to close
  (Approval, template != OP). Approval features only.
- Manual Opp path already gated: dmt_custom_path_opp / hvsc_oppClosingFlow -> DMT_FeaturesController.validateSemaphoreRulesForStageChange
  (requiredType Y + color config + requiredStatus match, DMT_Semaphore_Logic.evaluate; workflow color from getCurrentStepFromFeaturesOpp,
  no Case + tasks = YEL). Fails OPEN on exception. Opp only.

**DEV vs DMTPRE2 drift (dependency for user to merge at work):**
- PRE2 DMT_Case_Steps_Controller (Jimmy 2026-11-04) has `else if (isOppContext && checkApprovalValidation(contextId))` and an Opp-aware
  checkApprovalValidation(contextId) (inline SOQL with Tasks subquery, '006' prefix, DES_Exception_Utils.logException). No ticket marker.
  DEV (Luis Miguel 2026-10-23) has the Line-only version and no guard. Origin branch unknown.
- PRE2 Opportunity trigger calls BOTH enqueueAutoWorkflowOnStageChange (4477) and legacy autoStartFirstBusinessApprovalFeature
  (removed by our 4477 in DEV) -> possible double first-Case start on Proposal -> Approval in PRE2.
- DMT_FeaturesController: DEV adds validateStageAdvanceRequirements + debug; DMT_Semaphore_Logic identical.
Scratchpad retrieves: .../scratchpad/DMT_TCM_DEV and .../scratchpad/DMTPRE2 (session 8907f21a).

**Decisions 2026-11-10 (user):** branch 4801 created from main (tree was on main, 4811 merged). Lines IN scope. Required feature
not met = block, server and front end alike (fail closed). DMT_TCM_DEV is the source of truth (ignore PRE2-only checkApprovalValidation
version). User wants logic centralized in Apex, not flow. User asked whether 'semaphore' is English -> proposed traffic light naming.
Extra facts: Case has only SER_Case_TRIGGER (Globals, shared) besides Case_After_Trigger_Flow (5 Apex actions: team member x2,
4615 closure context, StartNextCaseAutomatization, DMT_ApprovalChangeStep_Helper). dmt_custom_path_line has NO required-feature check
(Opp path has validateTrafficLightForStage -> validateSemaphoreRulesForStageChange + validateStageAdvanceRequirements).

**Decisions round 2 (user, 2026-11-10):** NO new class just for naming, NO renames at all (flow invocable untouched, Case_After_Trigger_Flow
not touched, validateSemaphoreRulesForStageChange keeps its name so hvsc_oppClosingFlow is not touched), no re-trigger automation: a blocked
automatic move just does nothing; user moves manually later and the same gate lets it through. Gate logic inside existing classes
(DMT_Semaphore_Logic / controllers), 4 paths (auto Opp moveStatusToReadyToClose, auto Line avoidPassingApproval, dmt_custom_path_opp,
dmt_custom_path_line), fail closed. Full cleanup of touched methods as 'Enhancement to existing process' (C = yes). Do not over-polish.
Explained to user: 'last approval' only counts passportSanction approval; required non-approval features (PRE2 feature 226, sanction
passport, Y + READY TO CLOSE) are ignored -> that is the bug.

**Status (older):** findings + anti-patterns + proposal sent to user; waiting answers (Line scope, fail-open vs closed, what happens when blocked,
which checkApprovalValidation version is the base).

**Known possible issue (user 2026-11-10: record only, NOT in commit message nor ticket note):** auto move to RTC only runs when an
APPROVAL Case closes. If the last required feature to turn green is a non-approval one (e.g. sanction passport), nothing auto-moves;
the user moves manually (gate passes). Not part of the ticket.

**IMPLEMENTATION 2026-11-10 (branch 4801, manifest DMT/tickets/CIBGLOBALD-4801/CIBGLOBALD-4801-package.xml):**
- DMT_Semaphore_Logic: RecordFeatureData + loadFeatureData(Set<Id>) (2 SOQL via DMT_Case_Steps_Selector, without sharing, newest Passport),
  getPassportFeatures, getBlockingFeatureNames(features, cases, targetStatus) (Y + color rule + requiredStatus match, Closed==Closed Won,
  latest Case per feature, no Case + tasks = YEL), areApprovalFeaturesApproved (only approval features WITH tasks: DEV 191 / PRE2 38 approval
  features have none), resolveWorkflowColor moved here from DMT_FeaturesController (+ Finished without result = GRA, as the LWC).
- DMT_Case_Steps_Selector: getApprovalCasesByLineIds/OpportunityIds + Tasks subquery (latest DMT_Step_Approval).
- DMT_FeaturesController.validateSemaphoreRulesForStageChange: same signature, delegates, works for Line Ids too, fail closed (log via
  DMT_AsyncOrchestrator + AuraHandledException).
- DMT_Case_Steps_Controller: processStartNextCaseApproval cheap checks first (no SOQL on unrelated Case saves; Task query removed), single
  context, newest Case per feature, constants, toTaskMaps helper, Spanish debugs removed; moveStatusToReadyToClose(Passport, cases) = approval
  check + gate, no query; checkApprovalValidation lean (2 SOQL, was ~7), Opp or Line.
- DMT_Line_Helper.avoidPassingApproval: one load -> flag + gate (still triggerSize == 1, behaviour kept).
- LWCs: dmt_custom_path_opp toast text; dmt_custom_path_line validateTrafficLightForStage in updateStatus, handleModalSave (PE RTC),
  saveModal (Closed Won/Lost).
- Tests: FeaturesController_test (factory helpers, Assert, English, 7 new), Case_Steps_Controller_Test (Assert x6, English, fixtures with tasks,
  4 auto-move tests), Line_TriggerHandler_Test (2 avoidPassingApproval tests).
- Deploys DEV: 0AfgN000003WLh7SAG (8 comps, RunSpecified FeaturesController_test + Case_Steps_Controller_Test 93/93, Succeeded);
  0AfgN000003WLyrSAG (DMT_Line_Helper + Line_TriggerHandler_Test, NoTestRun, Succeeded; Fernando changed Line_Helper 11:05 UTC today).
  Tests after: 138/139; only failure DMT_Line_Helper_test.testDeposConsolidatedLineUsesSelectedDepoLentProduct (fails in org BEFORE our change).
  Org == local verified (only EOF newline, stripped locally).
- Test data DEV: Opp 006gN000009xTVZQA2 + Line a5ugN00000025LNQAY moved to Approval, Passports a6UgN0000003srtUAA / a6UgN0000003uLpUAI
  set to features 48012 (approval) + 48011 (passport, Y, READY TO CLOSE, wf GRE). Backup: scratchpad passport_backup_4801.json.
  Cases: Opp approval 500gN00000Ex9nKQAR, Line approval 500gN00000Ex9nLQAR. Auto negative PASSED (Opp stays Approval with INFO debug,
  Line stays Approval, validation flag true). Positive script scratchpad s2_auto_positive.apex.
- 2026-11-10 later: marker line above processStartNextCaseApproval; deploy 0AfgN000003WLveSAG (controller + 3 tests, 76/76, Succeeded). Org == local ALL SAME.
- TESTS PASSED (DEV): auto negative (Opp + Line stay Approval), auto positive (48011 green -> both Ready to close), browser negative
  (toast on Opp + Line path), browser positive (Opp -> RTC; Line -> passed gate, then path LWC auto-close took it to Closed Won, existing).
  Evidence (4 jpg) in DMT/tickets/CIBGLOBALD-4801/ (never commit). Test records end state: Opp RTC, Line Closed Won, test Cases ZZ_TEST_4801.
- Repo: DMT_Features_Selector and DMT_Line_TriggerHandler show modified only from the org retrieve (not ours, not in manifest).
- NEXT: user stages / commits; then commit message + Spanish technical note; ANS: none (all DMT_).
- 2026-11-11: user back to finish. Org check: our code intact; DMT_Line_Helper redeployed by Alejandro Munoz 2026-11-10 14:20 UTC WITH our 2 markers
  (local refreshed from org). User test data reset (scratchpad s4_user_test_setup.apex): Opp 006gN000009xTVZQA2 + Line a5ugN00000025LNQAY in
  Approval, Passport features 48014 (approval, approver 10) + 48013 (passport, Y, READY TO CLOSE, wf GRE), no Cases. Green step script:
  s5_make_required_feature_green.apex. Gave user step-by-step UI test.
- 2026-11-11: USER UI TEST PASSED on Opp 006gN000009xTVZQA2: path blocked (toast), approval 48014 approved (Case 07185346) -> stayed Approval,
  48013 requested + approved from the Opp card (Request shows for mandatory features in Approval: existing dmt_passport_opportunity logic,
  not ours) (Case 07185347) -> path move to RTC OK. Line UI test skipped by user (other Line approval implementations in DEV). Line card shows
  workflow light only when a Case exists (dmt_passport_child hasSFtask, existing). Line re-checks on ANY Case Finished in Approval
  (Case_After_Trigger_Flow 'Update to finish in approval line' stamps DMT_Approval_Date__c). NEXT: user staging -> commit msg + Spanish note.
- 2026-11-11: user renamed the LWC import alias to validateTrafficLightRulesForStageChange (Apex name unchanged); I fixed its doc comment,
  redeploy 0AfgN000003WzUrSAK Succeeded. User staged (company repo). Commit message + ticket comment 1 (technical note) saved in
  DMT/tickets/CIBGLOBALD-4801/. Next: personal repo commit and push when the user says.
**2026-11-12 (personal repo):** worktree leftovers committed on branch 4801 (b93e0640, incl. org drift DMT_Features_Selector, 4836 lines in Line_Helper, 4709 in Line_TriggerHandler), merged to main (f009385e), pushed.

**ROLLBACK 2026-11-12 (user: ticket will not be delivered anymore):** rebuilt from the pre-4801 baseline (scratchpad baseline, now saved in
DMT/tickets/CIBGLOBALD-4801/CIBGLOBALD-4801-org-original/); org copy before rollback saved in CIBGLOBALD-4801-org-before-rollback-2026-11-12/.
8 files restored from baseline as is; DMT_Line_Helper = org copy with only the avoidPassingApproval block back to baseline (keeps Alejandro's
2 hunks); dmt_custom_path_opp.js = org copy with only the 2 toast lines back (keeps the 2026-11-11 16:10 deploy that dropped the
validateStageAdvanceRequirements import and a commented toast). Only our own classes referenced DMT_Semaphore_Logic (MetadataComponentDependency).
Deployed from temp project scratchpad/rb4801 with --ignore-conflicts (tracking only; org check showed no change since retrieve), NoTestRun:
0AfgN000003XbjrSAC Succeeded. Tests after: 125/126, only DMT_Line_Helper_test.testcreateConsolidatedLine (validation rule, also failed before
the rollback). Org == rollback files, no 4801 marker in org. Personal repo (main) still holds the 4801 code: not synced (shared tree), waiting
for the user. DEV test data left: Opp 006gN000009xTVZQA2 (RTC), Line a5ugN00000025LNQAY, ZZ_TEST_4801 Cases, Passports with test JSON.
- 2026-11-12 Jorge: Opp stage path showed 'Error validating traffic light rules.' (no Passport). Cause NOT 4801: the 2026-11-11 16:10 UTC deploy
  of dmt_custom_path_opp (under Bruno's user, source unknown, likely IDE deploy of a copy without the method) removed the import of
  validateStageAdvanceRequirements while line ~346 still calls it -> ReferenceError -> LWC fallback toast. The 4801 rollback kept that copy.
  User OK -> restored the 2 import lines (same as pre-4801 baseline), deploy 0AfgN000003XsccSAC Succeeded, org == fix. Pre-fix copy in
  DMT/tickets/CIBGLOBALD-4801/CIBGLOBALD-4801-org-before-import-fix-2026-11-12/.
- **PARKED 2026-11-12 (user):** stays rolled back in DEV. Jorge's 'Error validating traffic light rules.' was NOT the 4801 code: the
  single-component deploy 0AfgN000003XAgPSAW (2026-11-11 16:10:14 UTC, Bruno's user, no session recorded it) removed the
  validateStageAdvanceRequirements import from dmt_custom_path_opp. Import fixed today (0AfgN000003XsccSAC). If they report more errors,
  decide then: redeploying 4801 = files in CIBGLOBALD-4801-org-before-rollback-2026-11-12/ (keep the import fix), same org check first.
