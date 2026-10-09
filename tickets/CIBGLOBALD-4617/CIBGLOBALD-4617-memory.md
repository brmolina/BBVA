---
name: cibglobald-4617
description: Replace DMT_Task__e and Passport__ChangeEvent platform events used by dmt_passport / dmt_passport_opportunity LWCs (PROD hit ~50k event delivery limit)
metadata:
  node_type: memory
  type: project
  originSessionId: d5824936-a9a0-40b5-9160-3ec896d83ab4
  modified: 2026-10-08T09:53:47.633Z
---

# CIBGLOBALD-4617 - replace Platform Events used by Passport (8 SP)

Branch for this ticket not yet created (session started on branch `4157`; per repo convention create `4617` from main when starting edits).

## What the ticket asks
Both Passport LWCs (`dmt_passport` = Lines, `dmt_passport_opportunity` = Opportunities) subscribe via lightning/empApi to `/event/DMT_Task__e` and `/data/Passport__ChangeEvent`. PROD hit ~50k delivered events/24h. Replace with something that does not consume event deliveries, keep: (1) semaforos/Feature status refresh when Tasks change, (2) Obsolete warning when Passport__c flips DMT_Is_Obsoleted_Passport_Save__c. Then clean up: stop publishing DMT_Task__e, remove CIB_skip_platform_event__c bypass logic if unused elsewhere, remove subscriptions, remove CDC for Passport__c, check no other consumers. QA in Lines + Opps, multi-user.

## Findings (verified 2026-10-08 against fresh retrieve of DMT_TCM_DEV, local == org)
- Publishers of DMT_Task__e: (a) `DTM_Task_Helper.processTask` (note DTM typo), called from `Task.trigger` after insert/after update for EVERY Task in the org (no record-type filter), one event per transaction with comma-joined Ids, skipped if `CIB_Bypass__c.CIB_skip_platform_event__c`; (b) `DMT_ApprovalChangeStep_Helper.restartTasksForRecord` publishes Operation 'CASE_UPDATE' with Line/Opp Id (CIBGLOBALD-4117).
- Subscribers: only the two LWCs (grep over force-app). No Apex trigger on the event. External subscribers unknown (ask).
- CDC: `PlatformEventChannelMember ChangeEvents_Passport_ChangeEvent` (channel ChangeEvents) is enabled in DMT_TCM_DEV; no custom PlatformEventChannel.
- `CIB_skip_platform_event__c` is referenced only by DTM_Task_Helper + its field meta + permission sets (CIB_ prefix = shared across teams -> common element).
- Obsolete is set backend-side: flows `AfterCreateLine`, `AfterCreateOpportunity` (ObsoletePasspport), and `DMT_Passport_Handler.markAsObsolete` (Apex, async path from `DMT_Passport_TriggerHelper` -> DMT_PassportPayload).
- LWCs read Passport via LDS `getRecord` on passportId (fields Obsolete + JSON); events only call `getRecordNotifyChange` / `refreshApex` to force re-read. LDS has no server push.
- dmt_passport Task handler: refreshApex(getInformationPassport) then, if event task Id is in this.tasksId (or CASE_UPDATE with this lineId/oppId), executeSafeSync('TASK_UPDATED'). dmt_passport_opportunity: on ANY task event calls refreshAllWires + getCurrentStepFromFeaturesOpp; MODIFY with comma list + checkStatusReadyToClose -> triggerReadytoclosePassportRefresh after 5s.
- Delivery amplification: delivered = events x open subscribed tabs, and each tab subscribes to both channels and filters client-side.
- Sandbox PlatformEventUsageMetric works (Name='PLATFORM_EVENTS_DELIVERED'); sandbox volumes tiny (<500/day).

## Decisions (2026-10-08)
- User chose: keep DMT_Task__e but FILTERED (option A) + visibility-aware subscription + no Passport CDC subscription. No polling for now. Nothing is deleted (object, CDC channel member, CIB_skip_platform_event__c all stay; bypass still honored by new code).
- No subscriber-side filtering exists in empApi: every subscriber gets every event; levers = publish less, subscribe less.
- DMTPRE2 not authenticated on this machine (only DMT DEV, DMT_TCM_DEV); user said not to ask them to run queries.
- Branch `4617` created from `4157` (NOT main: main lacks the org-sync commit a7138a54, so diffs would be noisy).

## Implemented locally (uncommitted, unstaged, NOT deployed) - paths under DMT/force-app/main/default
- classes/DTM_Task_Helper.cls: processTask(newList, oldMap, operation); only RT DMT_Step_Approval Tasks whose WhatId is a Case; on update only if Status/OwnerId/DMT_Step_Result__c/DMT_Step_Type__c/DMT_Task_Type__c/DMT_UserClosedTask__c/DMT_Committee_Label__c changed; records__c = Line/Opp Ids; ops CREATE, MODIFY, MODIFY_MULTI (>1 Task same record), PASSPORT; new processPassportChange (JSON or Obsolete flag change). @TestVisible buildTaskEvents/buildPassportEvents.
- triggers/Task.trigger: passes null / Trigger.oldMap.
- classes/DMT_Passport_TriggerHandler.cls: afterUpdate calls DTM_Task_Helper.processPassportChange.
- classes/DMT_ApprovalChangeStep_Helper.cls: removed explicit CASE_UPDATE publish (Task trigger events now cover the reopen).
- lwc/dmt_passport/dmt_passport.js and lwc/dmt_passport_opportunity/dmt_passport_opportunity.js: only /event/DMT_Task__e, match on lineId/opportunityId, PASSPORT op refreshes passport record, unsubscribe when tab hidden + one catch-up refresh if hidden >30s; Opp 'Close Task' detection now uses MODIFY_MULTI.
- NEW classes/DTM_Task_Helper_Test.cls (+meta) - written but NOT run (no deploy allowed).
- manifest/CIBGLOBALD-4617-package.xml (deploy together: Apex + trigger + both LWCs).

## Pending / open
- User reviews git diff, org-diffs, deploys and runs tests themselves; QA in Lines + Opps; ANS draft at wrap-up (Task.trigger/DTM_Task_Helper = Task object shared trigger; DMT_Task__e payload semantics changed; likely Nivel 2).
- Known gap: no push when backend flips Obsolete via non-Passport-update path? (flows/markAsObsolete update Passport__c so trigger covers). Cases changed without Task DML are not covered.

## Destructive (2026-10-08)
- Only thing to delete in the org: PlatformEventChannelMember `ChangeEvents_Passport_ChangeEvent` (CDC for Passport__c; was NOT tracked in this repo, only listed in manifest/package-full.xml). Manifest: manifest/CIBGLOBALD-4617-destructiveChanges.xml (the deletion list, reason written inside). The user runs destructive deploys on the other laptop, not here. Dry run of the deletion on DMT_TCM_DEV succeeded.
- Must be deployed AFTER the new Apex + LWCs are live (old LWCs still subscribe to /data/Passport__ChangeEvent). DMT_Task__e and CIB_skip_platform_event__c stay (still used by the filtered flow).
- Dry-run of main package: compiles, 64/64 tests pass with DTM_Task_Helper_Test + DMT_ApprovalChangeStep_HelperTest + DMT_Passport_Handler_test + DMT_Passport_FeatureSync_test; Status Failed only due to 75% per-class coverage of DMT_ApprovalChangeStep_Helper (pre-existing; 7 existing Line/Opp tests also fail on baseline).

## Real tests in DMT_TCM_DEV (2026-10-08, after user deployed code + deleted the CDC member)
- Method: Node CometD listener on /event/DMT_Task__e (same as empApi) + anonymous Apex on my own T4617 data (Line, 3 Cases, Tasks, Passports, Opp), one transaction per scenario. All test data and my user-level CIB_Bypass__c row were deleted afterwards (verified 0 left).
- FINDING: in DMT_TCM_DEV, CIB_Bypass__c rows for profile 'BBVA Standard User' (~3,355 active users) and 'System Administrator' have CIB_skip_platform_event__c = true, so NO DMT_Task__e event is published for anyone there. QA in the sandbox needs that flag off for the tester (user-level row or profile). I did not touch the profile rows.
- Results (all as designed): non-approval Task 0 events; approval Task insert -> CREATE <Line/Opp id>; Description-only update 0; Status update -> MODIFY; 2 Tasks same Line in one update -> MODIFY_MULTI; reopen via restartTasksForRecord -> MODIFY, MODIFY, CREATE and no CASE_UPDATE (the extra MODIFY comes from a record-triggered Flow on Task re-updating the cancelled Task); Passport Obsolete flip and JSON change -> PASSPORT; same-value Passport re-save 0; bypass ON 0; Opp case Task CREATE/MODIFY and Opp Passport PASSPORT carry the Opportunity Id.
- NOT testable from CLI: everything in the two LWCs (subscribe/match/refresh, hidden-tab unsubscribe, catch-up, Obsolete warning UI, spinners), multi-user, real approver flows, Close Task 5s refresh in Opp, volume numbers.

## Bypass turned off (2026-10-08, user's explicit instruction)
- The profile bypass was on because of a last-minute firefighter solution; user confirmed it can be off. I misread 'unset the custom setting' first (only removed my own temp row), then cleared CIB_skip_platform_event__c on both rows: System Administrator profile (PT1 row a065800001bRglWAAS) and BBVA Standard User (a06KE000000VgZrYAK). Other fields untouched (skip_trigger stays true on the admin row). Verified 0 rows with the flag true in DMT_TCM_DEV. DMT_TCM_DEV now publishes DMT_Task__e for all users, so QA there is possible.
- Lesson: when the user says 'turn it off / unset it', apply it to the real setting, do not narrow it to a private workaround.

## Browser test findings (2026-10-09)
- Lights follow the CASE status (Pending/In Progress yellow, Finished+Yes green, Finished+No red, Finished without result grey), not the Task status. Event fires on Task changes (watched fields), not on Case-only changes.
- User tested Line a5uKE000000GtK8YAK (ST11, Case 500KE000001MzK1YAK, Tasks 00TKE000002mJUw2AM / replacement 00TKE000002mPaP2AU) with visible tab + DevTools: events ARRIVE (3 TASK_UPDATED refreshes matching MODIFY/MODIFY/CREATE) but the ST11 light stayed stale; hard reload showed correct colour. Server data was correct afterwards.
- ROOT CAUSE (user hypothesis, confirmed in metadata): DMT_Task__e had publishBehavior=PublishImmediately, so the event is delivered before the transaction commits and the Passport reads old data (explains the Opp 5s 'wait for commit' timeout and the original CASE_UPDATE workaround). Fix: PublishAfterCommit in objects/DMT_Task__e (edited locally, added to CIBGLOBALD-4617-package.xml as CustomObject, dry run OK). Not yet deployed (asked user).
- Also fixed: hiddenAt when the Passport loads in a background tab (both LWCs, deployed to DMT_TCM_DEV 2026-10-09 after retrieve+compare).
- Test tab of the extension is in a hidden window: it never receives events (visibility hidden), use the user's visible tab for event tests.
- Sandbox permission: classifier blocks Apex DML on shared records unless the user approves; user approved explicitly (sandbox is free to mess with).

## Test status (2026-10-09, user watching visible tabs in DMT_TCM_DEV)
- PASSED live without reload: Line ST11 reject (red), reopen (yellow), reject again (red), reopen (yellow) after DMT_Task__e switched to PublishAfterCommit (deployed). Opp OPP - Global Banker Advisory reject (red) + reopen (yellow). Opp Obsolete warning appears and disappears live. CometD listener confirmed events published after commit.
- NOT yet done: Line Obsolete warning visually (page too tall), full chain Opp field edit -> flow -> obsolete -> warning, hidden-tab >30s catch-up, Close Task MODIFY_MULTI refresh on Opp in Ready to close, two users, regression (Request/close/reactivate), multi-user.
- Docs: tickets/CIBGLOBALD-4617/deployment-notes.md (order + manual step for the CDC channel member, which is not tracked in git).

## Committed and pushed (2026-10-09)
- Commit 6649cbc0 on branch 4617 pushed to origin (github brmolina/BBVA) with the 9 code files, 2 manifests, tickets/CIBGLOBALD-4617/ (CHANGES.md with line numbers, commit-message.txt, deployment-notes.md, memory.md) and tickets/CIBGLOBALD-4157/memory.md. NOT merged to main yet (user did not ask).
- Left uncommitted on purpose (other work in the tree): ticket 4477 files (DMT_StartApprovalCasePayload, DMT_AsyncDispatcher/QueueJob, Case_Steps_Controller(+Test), Line/Opportunity handlers+trigger, Passport_Handler, manifest 4477, tickets/CIBGLOBALD-4477), org drift from others (customMetadata HighlightPanel, form renderer, lineInfo, TaskApprovalFlowService, ApprovalDataController, LineController, LinesBulkActionController) and manifests 3779/4295.
- ANS: 2 Si (modifies shared Task trigger behavior; affects platform event limits) => Nivel 2; draft given in chat.
- Post-deploy manual steps: delete Passport in Setup > Change Data Capture; uncheck CIB_skip_platform_event__c on every CIB Bypass row.
