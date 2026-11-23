# CIBGLOBALD-4851 - Implementation plan by stages

Each stage ends deployed to DMT_TCM_DEV (dry-run first), tested, and recorded in the ticket memory before the next starts.
Baseline for rollback: CIBGLOBALD-4851-org-original/ (rollback = remove only our edits from the CURRENT org copy).

## Decisions in force
- Header-driven columns with aliases; only org-required columns are required; absent column = field untouched.
- Client_Code__c is the only client column, resolved against g_customer_id__c and DES_Group_Code__c; unresolved = row rejected. Golden_Code__c filled = Golden line.
- Children: when a line's RLT (or LPI) file comes, delete ALL its RLT (or LPI) and insert the file rows. No matching. Duplicates inserted as they come.
- Lines file first; two child tables + drop zones (LPI only for Treasury); child rows for a line not in the Lines table are rejected; wrong zone = LightningConfirm warning; new file replaces the table; SF rows show Will Be Deleted; per-row delete.
- One Process button. DML per chunk of lines: one mixed insert (new lines, RLT, LPI, parents first via Line_Id__c reference), one update (existing lines), one mixed delete (old RLT, LPI). Savepoint per chunk, fallback line by line: a line and its children are all-or-nothing.
- DMT_BulkImportBatch without sharing.
- Non-Draft lines (Diego, 2026-11-13): move to Draft, apply the changes, then return the line to its previous status, or to the status given in g_line_status_type__c when that column has a value.
- Approval restart: mimic CIBGLOBALD-4811. Preview check (DMT_ApprovalChangeStep_Handler.previewCompareUnsavedChanges) before Process, result shown in a TOAST only (no dialog); when only children change on a Ready to close line, a no-change Line update so the trigger re-compares against the closed tasks' snapshots.
- Status change mechanism (user, 2026-11-18): REUSE DMT_BatchSanctionAMIWEB (the Update Line Status logic) and JUMP straight to the target status, one line per transaction. No step-by-step walk.

## Org facts for the non-Draft path (DMT_TCM_DEV code, read 2026-11-13)
- Gate: DMT_Line_Helper.restartApprovalTasksOnLineResubmission (TreasurySettlement + OtherProducts only):
  1. Draft -> Proposal with old DMT_DateToProposal__c set -> 'passport' Cases
  2. Proposal -> Approval -> 'approval' Cases
  3. Ready to close -> Ready to close (not only the edit lock taken) -> 'readytoclose' Cases
  Going back to Draft is no checkpoint. Entering Ready to close from Approval is no checkpoint.
- VR AvoidEditNotDraft (blocked when not Draft, except Desktop Integration / System Administrator profiles, DMT_Allow_Approval_Edit__c, DMT_Cancel__c): Name, Booking_Geography__c, CurrencyIsoCode, Start_Date__c, DvP_Amount__c, FD_Amount__c, Repos_Limit__c, Repos_Limit_6M__c, First_Breakclause__c, Breakclause_Frequency__c, Waiver__c, Client__c, Amount__c, DMT_LastLevelId__c.
- VR Go_through_each_step (same profile bypass, NOT bypassed by DMT_Line_God): Approval only from Proposal / Ready to close / Closed; Ready to close only from Approval / Closed; Closed only from Ready to close (or Approval when not PE). A jump past Proposal fails for users without those profiles (accepted: error reported per line in the Update Line Status email).
- VR NotBackFromApproval / DMT_NotEditCloseLine: bypassed by DMT_Line_God.
- DMT_Line_Helper.enqueueAutoWorkflowOnStatusChange (4477): every entry into Proposal / Approval / Ready to close starts the auto-start feature Cases that do not exist yet (async).
- Check: DMT_ApprovalChangeStep_Handler.previewCompareUnsavedChanges(recordId, caseTypeToCheck, unsavedValues, unsavedRows); unsavedRows {objectApiName, rowId, values}, new row = no rowId, deleted row = deleted true. One record per call.
- Child-only recheck: DMT_ApprovalChangeStep_Helper.recheckReadyToCloseLine (no-change Line update, only when Ready to close).

## Status rules (approved by Diego 2026-11-16, 'parece todo bien')
1. New lines: created in Draft. g_line_status_type__c not blank and != DR -> the Update Line Status logic runs automatically after the load. Blank or DR -> stay Draft.
2. Existing line not in Draft + blocked-field change: to Draft + apply; code blank -> update status to the line's original status; code given -> that status. Final status Proposal -> Draft -> Proposal may reopen (passport Cases): check before Process, toast only when something will reopen.
3. Products only: status kept; Ready to close -> check + toast when features reopen (recheckReadyToCloseLine after the child DML).
4. Closed line modified: Draft, or the file code (automatic, like the button).
5. g_line_status_type__c column absent -> field untouched; column present and blank -> field cleared.
6. (Diego, 2026-11-16) Target status of a line sent to Draft = the value of g_line_status_type__c AFTER the load (file value when the column comes, otherwise the value already stored); only when that is blank -> the original Status__c.

## Non-Draft rules and who moves the status (user, 2026-11-13, corrected 2026-11-18)
- Go to Draft ONLY when the file changes a blocked field (value differs from the org) or the code points to another status. Children only = status kept, no Draft.
- After Process, automatic (DMT_BatchSanctionAMIWEB load mode, jump, scope 1): new lines with a code != DR (Diego rule 1); lines the load sent to Draft, back to the code's status or their previous status.
- Existing lines already in Draft before the load, with a code: the Update Line Status button (ticket requirement 3, production behaviour). The button is also the retry for automatic moves that failed (the line stays Draft with its code; AMIWEB only picks Draft lines, so no line runs twice). A line going back to its previous status without code cannot be retried by the button: load it again.
- No dialog. Reopen check before Process, toast only: 'passport' when the final status is Proposal; 'readytoclose' when a line stays in Ready to close with a change (line or products), followed by the no-change Line update.
- 2026-11-18 drift corrected: stage 4 was first built with a new step-by-step batch (DMT_BulkImportStatusBatch) and an extra 'approval' check, following the old 'walking the steps' line of this plan instead of the later agreement (jump, reuse). Replaced the same day; the class was deleted from the org.

## Stage 0 - Confirm in the org (dry-run throwaway test, runAs BBVA Standard User + DMT_Line_God, nothing saved)
- The step walk per original status (Proposal, Approval, Ready to close, Closed) passes all VRs and the cost per line (SOQL, DML, CPU, queueables).
- The check returns the same features the trigger then restarts.

## Stage 0 results (2026-11-16, dry-run probe scratchpad/probe4851b/DMT_Probe4851b_Test, runAs QA SOPORTE-FUNCIONAL = BBVA Standard User + DMT_Access; nothing saved)
- Check = trigger on Draft -> Proposal: Proposal line ESCD26LIN00002786ES, Name changed: check 3 features, real (as admin) 3 tasks cancelled + 3 new.
- Legacy snapshots (DMT_TrackedComponents__c blank) reopen even with no change: round trip with no edit reopened all 3; the check says the same (A2). Expected framework behaviour.
- Cost of one line Draft -> Proposal with restart: 76 SOQL / 19 DML; without restart ~40 SOQL / 10 DML. Check: 9 SOQL per line per Case type. -> automatic status update = 1 line per transaction; the check runs per line from the LWC (own transaction each).
- Status jumps as BBVA Standard User: Draft -> Proposal OK; Draft -> Approval / Ready to close / Closed BLOCKED by Go_through_each_step (Closed also by AvoidEditNotDraft). Same for the existing button.
- Draft -> Proposal FAILS for that user ('An error occurred while trying to update the Date to Proposal field of the Line', AfterCreateLine fault) when the line's RLTs were replaced by a bare row (no product data); passes with complete RLT rows (copies of real rows) and with DMT_Allow_Approval_Edit__c. Cause: a blocked field changes transiently inside the AfterCreateLine nested update (AvoidEditNotDraft, admin profile bypass); likely the last-level chain (AfterCreateLine Update_LastLevel_Id on RLTs -> RLT flow -> line DMT_LastLevelId__c). Exact field not pinned. CORRECTION: product taxonomy is NOT the cause (the line's real RLTs and the user's sample have it blank). The user's sample file (4 RLT + 5 LPI replacing all 16 children) passes Draft -> Proposal as BBVA Standard User (A9). The failing case kept the 9 old LPIs and had ONE bare Derivatives RLT: an inconsistent set, cause not identified; Process must report the flow error per line.
- No permission set bypasses Go_through_each_step: the formula checks only $Profile (System Administrator, Desktop Integration) and DMT_Cancel__c. Moving to Draft first does not help: Draft -> Approval is exactly the blocked jump.
- Ready to close, products only: the test line's snapshots track 'Client;Line Info' (no products) -> no reopen. The check flagged 'Client' = HPG callout rating (checked live by the preview only when no Salesforce change; the trigger defers it to DMT_CalloutTrackableCheckPayload, async).

## Stage 1 - Parsing and Lines (LWC + Apex)
- LWC: header-driven parser with aliases, optional columns, CSV quoted values fixed; Treasury record type accepts the TL Lines file.
- Apex: client resolution (one pre-query on both code fields, reject unknown), Golden_Code__c, absent column = untouched, owner alias, without sharing.
- Test: OL Lines file regression + TL Lines file, new and existing lines (Draft only in this stage).

**Stage 1 DONE 2026-11-16 - deploy 0AfgN000003Z0ppSAC Succeeded (17/17 tests, org = local).** Files: DMT_BulkImportBatch, DMT_BulkImportBatch_Test, DMT_BulkImportController, DMT_BulkImportController_Test, LWC dmt_bulk_import (js). Manifest CIBGLOBALD-4851-package.xml.
- Batch: without sharing; LINE_FILE_FIELDS written only when the column is present (blank clears), typed by describe (dates yyyy-mm-dd / dd/mm/yyyy, decimal point or comma, TRUE/FALSE); client from Client_Code__c (customer or group code, one Account query per chunk, inline because Account sharing is Private); new line without client code or unknown code -> row rejected; new lines Draft, Status__c column ignored; DMT_Origin__c always BulkImport; owner from DMT_ID_User__c or 'owner User id_user__c'; rows rejected before the DML reported with the DML errors (addRowError).
- Controller: getExistingLines also returns the TL columns.
- LWC: quote-aware CSV parser (file + paste; tab, pipe, semicolon, comma; BOM); Lines file header-driven (only Line_Id__c required); previews show the file's columns; no backfill of blank cells; _hasLineChanges compares only present columns, typed; paste routing recognises a TL Lines file.
- Controller test: data via DMT_UtilTestClass; testUpdateLineStatusLaunchesBatch failed in the org already (line without client cannot leave Draft) -> Client__c added (Enhancement fix).

## Stage 2 - Child tables UI (LWC only, no DML change yet)
- After the Lines file: load existing RLT + LPI of those lines; two drop zones; wrong-zone warning; table replace on new file; Will Be Deleted rows; per-row delete; reject child rows of lines not in the table.

**Stage 2 DONE 2026-11-16 - deploy 0AfgN000003ZLz7SAG Succeeded (9/9 controller tests, controller 0/38 uncovered, org = local). Not browser-tested.**
- Controller: getExistingTermsForLines adds Id + DMT_Risk_Type__c; new getExistingProductItemsForLines (+ test).
- LWC: old Products step (products table, Create / Update Products button, pre-existing products link, products enrichment/compare, products progress) REMOVED; saving children comes with Process (stage 3). New Products card: Risk Line Terms table (always) + Line Product Items table (Treasury only); childState per zone {fileName, fileRows, sfRows, errors}; statuses New (file) / Will Be Deleted (SF record of a line with file rows) / Kept (other SF records); per-row 'Remove row' on New rows only; file replaces that zone's file rows; rows for lines not in the Lines table (or blank line id) rejected and listed (max 20 + count); wrong-zone LightningConfirm by column fingerprint (_detectFileType: gf_cutoff_date -> lines, LPI columns -> lpi, RLT columns -> rlt, Line_Id__c -> lines); paste routes the same way; old OL Lines file term columns become the RLT file rows; legacy 'DMT_Risk_Line_Term__c <field>' columns shown as <field>; Update Line Status amount pre-check uses the SF Risk Line Terms (_sfTermAmountForLine).
- Replace rule applied per line: Salesforce records are Will Be Deleted only for lines with >=1 row in that file.

**Stage 3 DONE 2026-11-18 - deploy 0AfgN000003aZiHSAU Succeeded (21/21: batch 17/328 uncovered, controller 0/32), LWC follow-up 0AfgN000003aYawSAE. Playwright E2E OK.**
- Controller: processImport(unitsJson, jobId, recordTypeName) replaces submitLines / submitProducts; batch size UNITS_PER_CHUNK = 10.
- Batch: one unit per line {line, rowNumber, updateLine, rlt?, lpi?}; key present = replace that object for the line. Per chunk: user + existing line + client queries, old children (2 queries), then delete old children -> insert [new lines, RLT, LPI] (children by Line_Id__c reference) -> update existing lines, under a savepoint; failure -> rollback and line by line (records cloned for the retry). Child fields whitelisted (RLT_FILE_FIELDS, LPI_FILE_FIELDS), typed by putValue. Unit rejected before DML (client, invalid value) -> whole line and its products untouched. Old products path (processProducts, buildTerm, IMPORT_TYPE_LINES/PRODUCTS) removed.
- LWC: Process button (replaces Create / Update Lines); units built from lines + child file rows; products-only lines sent with updateLine false; after the run the child tables reload from Salesforce, file rows kept only for failed lines; unsubscribe fixed (empApi callback, Enhancement fix).
- Tests: units() helper for the line tests; new tests: replace products of an existing line, new line with products, failed line keeps old products while the other line saves, full chunk of 10 lines.
- E2E (Playwright, DMT_TCM_DEV): TEST26LIN00008860ES 6 RLT + 5 LPI replaced by 2 RLT + 2 LPI, TEST4851PW01 1 RLT; both lines No Changes (products-only units); 0 failed.

## Stage 3 - Process (Apex batch rewrite)
- One Process call sends lines + children; batch chunked by line; the 3 statements; savepoint per chunk with line-by-line fallback; server re-checks Line_Ids; result per line; progress event per chunk after the result is final, COMPLETED at finish.
- Test: errors mid-chunk keep the old children (no loss), counts per line, limits at 50 lines.

## Stage 4 - Non-Draft lines (rules above)
- Draft only for blocked-field changes; apply; walk back to the previous status or g_line_status_type__c.
- Check per line before Process + toast; recheckReadyToCloseLine for Ready to close lines with child-only changes.

**Stage 4 DONE 2026-11-18 - deploy 0AfgN000003aw5NSAQ Succeeded (29/29: batch 21/379, AMIWEB 8/68, controller 0/32 uncovered). DMT_BulkImportStatusBatch (+_Test) deleted from the org (0AfgN000003awF3SAI). Playwright E2E OK.**
- Controller without sharing (preview must see every line / product the load saves or deletes; Line and Account Private).
- DMT_BulkImportBatch.planStatus (Diego's rules): new line + code != DR -> target = code's status; existing non-Draft line with a BLOCKED_OUTSIDE_DRAFT change or a code pointing to another status -> saved in Draft, target = code's status (code after the load) or its previous status; Closed without code stays Draft; existing Draft lines untouched (button). finish -> DMT_BatchSanctionAMIWEB(Map<Line_Id__c, target>) scope 1 (not launched in tests; lastStatusTargets @TestVisible). Products only on a Ready to close line -> no-change Line update in the same update statement. Child VRs AvoidEditNotDraft fire only on child UPDATE (ISCHANGED LastModifiedDate): delete + insert not blocked.
- DMT_BatchSanctionAMIWEB: new constructor (Map target status by Line_Id__c): Draft BulkImport lines of the map, status from the map (works without code), same partial save / log / email. Nightly and button modes unchanged.
- DMT_BatchSanctionAMIWEB_Test: System.assert -> Assert; new testBulkImportLoadModeUsesTargetStatus (DMT_UtilTestClass data); Enhancement fix to existing process: 3 tests already failed in the org (no client on the Bulk Import lines; factory terms without DMT_Risk_Type__c and line without Amount__c / DMT_LastLevelId__c for the nightly test) -> fixed in our test class only (shared factory not touched). Remaining manual line inserts in the pre-existing methods (buildBulkImportLine, badLine) left as they were.
- LWC: Status Change column (_statusPlan); 4811 check before Process: passport (target Proposal) and readytoclose (staying in Ready to close); warning toast; info toast after Process with the lines moving automatically.
- E2E: TEST4851PW01 Proposal + rename + blank code -> Draft -> Proposal (jump); new TEST4851PW03 code PR -> Proposal; one AMIWEB job, 2 lines, 0 errors. Reopen toast not exercised: TL lines in DEV have no feature Cases.

## Stage 5 - Update Line Status button for TL
- Verify DMT_BatchSanctionAMIWEB Bulk Import mode with TL lines (already no record type filter) and how it fits with the Stage 4 restore.

## Stage 7 - Add OU (new requirement 4, 2026-11-16) - questions sent to Diego
- OU = User.DES_LevelUO_10__c (label 'UO - Nivel10'), 8-digit code (e.g. 00008125); DEV: up to ~25 active users per OU.
- Write roles: User.DMT_User_Role__c (';' list) matched to DES_User_Roles__mdt.DES_Role_Developer_Name__c, DES_Access_Level__c = 'Read/Write' (same logic as DMT_Utils.hasWriteAccess, current user only). DEV: 7 Read/Write, 2 ReadOnly (DMT_OnlyLines, DMT_Read_Only).
- Participant = DMT_TeamMember__c (Line__c, User__c, AccessLevel__c Edit/Read/All, DMT_ApprovalEdit__c, Team_Role__c). Existing data has duplicate Line+User rows.
- Already in the org: DMT_AssignParticipantsByUO (Javier Angulo, 2026-09) called on Line create (AfterCreateLine + DMT_Assign_Line_Participants_By_UO): OWNER's UO active users -> Edit, Read upgraded to Edit, owner skipped, NO role filter, NO Approval Edit. DEV: the 9 BulkImport lines have 0 participants.
- Independent of the load; no impact on stages 1-6.
- Diego's answers (2026-11-16):
  1. The OU code is typed in; one OU per load.
  2. Lines = the ones just processed on that same screen.
  3. Javier's automatic assignment is another development (Opportunities): leave it, build a NEW method.
  4. Existing participant: Read -> Edit + Approval Edit; All stays All + Approval Edit.
  5. The line Owner is added as participant too (needs Approval Edit to edit in Closed Won). ALWAYS, even when not in the OU or without a write role (user, 2026-11-16).
  6. Team_Role__c = 'User-Defined'.
  7. Result: one message, 'X users added to all the lines of the load'. X includes the line owners (user, 2026-11-16).
- Test OU from Diego: 00025828. DEV: 14 users, 11 active, all with DMT_Riesgos Global;DMT_Negocio Local (Read/Write) -> 11 expected. DMTPRE2: same, 11 active.

**Stage 7 DONE 2026-11-19 - deploy 0AfgN000003bDRBSA2 Succeeded (12/12: OU batch 4/65, controller 1/48 uncovered). Playwright E2E OK.**
- DMT_BulkImportController.addOuParticipants(ouCode, lineIds): blank OU / OU without write users -> error, nothing added; returns distinct users added (OU users + line owners); launches DMT_BulkImportOuParticipantsBatch (scope 20 lines).
- DMT_BulkImportOuParticipantsBatch (new): writeUsersOfOu = active users with DES_LevelUO_10__c = OU and a DMT_User_Role__c role whose DES_User_Roles__mdt access is Read/Write (no role hardcoded, DMT_Utils.splitString). Per line: OU users + owner (User owners only). New participant Edit + Approval Edit + User-Defined; existing (every copy) Read/blank -> Edit, Edit/All kept, Approval Edit true; others untouched. Row failures logged. 'All' participants cannot be created through the share flow on DMT_TeamMember__c (Read/Edit only): the batch never creates them, only keeps them.
- LWC: OU code input + Add OU button after Process, lines = importedLineIds (non-failed); locked after one success (one OU per load), unlocked by the next Process / Start Over; toast 'X users added to all the lines of the load.'
- E2E: OU 00025828 on TEST4851PW01 / PW03 -> 12 participants each (11 OU users + owner), Edit / Approval Edit / User-Defined; second run no duplicates. Evidence DMT_TCM_DEV-add-ou-users-added-toast-CIBGLOBALD-4851.jpg.

## Stage 6 - Tests, manifest, wrap-up
- Test classes per DMT test architecture (Factory-first, createX/buildX, overrides, audit). Manifest in the ticket folder. Playwright E2E with screenshots in the ticket folder (not committed).
