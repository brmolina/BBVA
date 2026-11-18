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
- Approval restart: mimic CIBGLOBALD-4811. Preview check (DMT_ApprovalChangeStep_Handler.previewCompareUnsavedChanges) and LightningConfirm warning before Process; when only children change, a no-change Line update so the trigger re-compares against the closed tasks' snapshots.

## Org facts for the non-Draft path (DMT_TCM_DEV code, read 2026-11-13)
- Gate: DMT_Line_Helper.restartApprovalTasksOnLineResubmission (TreasurySettlement + OtherProducts only):
  1. Draft -> Proposal with old DMT_DateToProposal__c set -> 'passport' Cases
  2. Proposal -> Approval -> 'approval' Cases
  3. Ready to close -> Ready to close (not only the edit lock taken) -> 'readytoclose' Cases
  Going back to Draft is no checkpoint. Entering Ready to close from Approval is no checkpoint.
- VR AvoidEditNotDraft (blocked when not Draft, except Desktop Integration / System Administrator profiles, DMT_Allow_Approval_Edit__c, DMT_Cancel__c): Name, Booking_Geography__c, CurrencyIsoCode, Start_Date__c, DvP_Amount__c, FD_Amount__c, Repos_Limit__c, Repos_Limit_6M__c, First_Breakclause__c, Breakclause_Frequency__c, Waiver__c, Client__c, Amount__c, DMT_LastLevelId__c.
- VR Go_through_each_step (same profile bypass, NOT bypassed by DMT_Line_God): Approval only from Proposal / Ready to close / Closed; Ready to close only from Approval / Closed; Closed only from Ready to close (or Approval when not PE). So Draft back to Approval = Draft -> Proposal -> Approval; back to Ready to close = Draft -> Proposal -> Approval -> Ready to close (one update per step).
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

## Non-Draft rules (user, 2026-11-13)
- Go to Draft ONLY when the file changes a blocked field (value differs from the org). Children only = status kept, no Draft.
- Return to the previous status or to g_line_status_type__c, walking the steps.
- Before Process: per affected line the LWC builds the payload (line values from the file, RLT/LPI rows: deleted + new) and calls the check for each checkpoint the line will pass: Proposal = passport; Approval = passport + approval; Ready to close = passport + approval + readytoclose (the last one also when only children change, followed by recheckReadyToCloseLine). Proposal / Approval with children only: no checkpoint, nothing reopens.
- No confirm dialog: Process goes ahead, a toast lists the features that will reopen.

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

## Stage 3 - Process (Apex batch rewrite)
- One Process call sends lines + children; batch chunked by line; the 3 statements; savepoint per chunk with line-by-line fallback; server re-checks Line_Ids; result per line; progress event per chunk after the result is final, COMPLETED at finish.
- Test: errors mid-chunk keep the old children (no loss), counts per line, limits at 50 lines.

## Stage 4 - Non-Draft lines (rules above)
- Draft only for blocked-field changes; apply; walk back to the previous status or g_line_status_type__c.
- Check per line before Process + toast; recheckReadyToCloseLine for Ready to close lines with child-only changes.

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

## Stage 6 - Tests, manifest, wrap-up
- Test classes per DMT test architecture (Factory-first, createX/buildX, overrides, audit). Manifest in the ticket folder. Playwright E2E with screenshots in the ticket folder (not committed).
