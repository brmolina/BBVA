---
name: cibglobald-4157-memory
description: CIBGLOBALD-4157 - restrict LWC dmt_bulk_import access to DMT_Line_God only (remove ConsultationIT)
metadata:
  node_type: memory
  type: project
  originSessionId: b9d4ff02-9f6b-47c2-acec-441eeffee71a
  modified: 2026-10-07T08:27:31.871Z
---

**Ticket goal (from user, 2026-10-07):** in LWC `dmt_bulk_import`, remove access for `ConsultationIT`; leave access only for `DMT_Line_God`.

**Retrieved from DMT_TCM_DEV (2026-10-07, fresh):** LWC `dmt_bulk_import` (the name is snake_case, `dmtBulkImport` does not exist), ApexClass `DMT_BulkImportController`, CustomPermission `DMT_Line_God` and `ConsultationIT`. Permission sets `ConsultationIT`, `DMT_Access` and `DMT_Integration_Analytics` were already local (retrieved earlier, NOT re-retrieved today).

**Findings:**
- Gate is client-side only: `dmt_bulk_import.js:11-12` imports `@salesforce/customPermission/DMT_Line_God` and `.../ConsultationIT`; line 140 `get hasAccess() { return hasDMTLineGod || hasConsultationIT; }`. The no-access message in `dmt_bulk_import.html:354` mentions both permissions.
- `DMT_BulkImportController.cls` has no custom-permission check.
- Both custom permissions already exist, so no permission set check is needed.
- **Catch:** custom permission `DMT_Line_God` is itself enabled in permission sets `ConsultationIT`, `DMT_Access` and `DMT_Integration_Analytics`. Many active users have these (DMT_Access and DMT_Integration_Analytics each have 20+ assignees in DMT_TCM_DEV). So dropping `hasConsultationIT` from the LWC alone barely restricts anything: ConsultationIT-set users also get DMT_Line_God via that same set.

**Pending:** user decision on approach (see chat). No code edited yet. No deploy done.
**Possible common elements (ANS):** permission set / custom permission changes would be shared elements. LWC-only change is probably N1 at most; re-evaluate at wrap-up.

**Update 2026-10-07 (context from user):** goal is NOT to restrict. ConsultationIT = read-only across all projects; DMT_ReadOnly = read-only permission set for DMT only. Controller runs system mode; the batch `DMT_BulkImportBatch` publishes platform event `DMT_BulkImportProgress__e` via `EventBus.publish(evt)` in `publishProgress()` (line ~214-229). Concern: ConsultationIT users lack event Create, so publish may throw. User's proposal: keep LWC visible-to-ConsultationIT removed (hide via !ConsultationIT) OR make the publish system-mode and just remove event Create from ConsultationIT set.
- Org query: ConsultationIT permission set has Create=true AND Read=true on `DMT_BulkImportProgress__e` in DMT_TCM_DEV (local copy was stale; re-retrieved fresh 2026-10-07, 387-line git diff of drift vs the old snapshot).
- Retrieved: DMT_BulkImportBatch, DMT_BulkImportProgress__e object, fresh ConsultationIT permission set.
- User idea (not for now): push per-ticket branches to a PERSONAL GitHub as history. I flagged BBVA code confidentiality/policy risk; user decides. Nothing pushed.

**Research 2026-10-07 - can EventBus.publish run in system mode?** Official Salesforce docs (developer.salesforce.com platform events guide) returned HTTP 403 to WebFetch and the PDF failed on cert, so verbatim text NOT obtained. Search snippets say publishing requires Create permission on the event; user confirmed the exception occurs in practice. No source found for a system-mode switch on EventBus.publish. Do not claim otherwise without proof. Definitive check = System.runAs test or manual test in DMT_TCM_DEV with a ConsultationIT-only user. User states ConsultationIT must NOT have event Create (user will revert it in the org; user deploys). Local ConsultationIT.permissionset file has 387-line drift from fresh retrieve: do not stage it.

**Status 2026-10-07 (end of session part 1):**
- DEPLOYED to DMT_TCM_DEV (user-authorized): PermissionSet ConsultationIT with event DMT_BulkImportProgress__e allowCreate=false (org verified Create=false, Read=true). Local ConsultationIT file then `git checkout`ed back to snapshot (so local file does not show the change; user re-retrieves at work).
- No read-only custom permission existed (org has only DMT_Access, DMT_Line_God, DMT_Not_Approval_Required). DMT_ReadOnly set only grants DMT_Access custom perm.
- LOCAL EDITS, NOT DEPLOYED (deploy denied by the auto-mode classifier): new customPermissions/DMT_Read_Only.customPermission-meta.xml; permissionsets/DMT_ReadOnly.permissionset-meta.xml (+customPermissions DMT_Read_Only after DMT_Access, line ~1123); lwc/dmt_bulk_import js line 13 import of DMT_Read_Only, line 141 `hasAccess = hasDMTLineGod && !hasConsultationIT && !hasDMTReadOnly`; html line 354 message now only mentions DMT Line God.
- Pending: user runs/authorizes deploy of CustomPermission:DMT_Read_Only + PermissionSet:DMT_ReadOnly + LWC dmt_bulk_import (order: custom permission, permission set, then LWC); verify DMT_ReadOnly users; then user retrieves at work, stages, commits.
- ANS: touches shared elements (ConsultationIT and DMT_ReadOnly permission sets, new custom permission) - re-evaluate and draft ANSReview at commit time.

**Update 2026-10-07 11:04:** user ran the combined deploy (CustomPermission DMT_Read_Only + PermissionSet DMT_ReadOnly + LWC dmt_bulk_import) in DMT_TCM_DEV. Verified by query: custom permission exists; LWC LastModified 09:03 UTC by user. manifest/package.xml written (CustomPermission, PermissionSet ConsultationIT + DMT_ReadOnly, LightningComponentBundle), API 65.0. Pending: user retrieves at work, stages, commits; ANSReview draft at commit time; functional test with users (Line_God only, ConsultationIT, DMT_ReadOnly).

**Test classes check 2026-10-07:** DMT_BulkImportBatch_Test and DMT_BulkImportController_Test exist in org (retrieved, untouched). Neither references runAs, permission sets, custom permissions, ConsultationIT/Line_God/Profile, or the event. No Apex changed in this ticket, so no test update needed. User decided NOT to create the ANSReview Jira now (is reverting own never-released changes); do not draft it unless asked.

**Git 2026-10-07:** created local branch `feature/CIBGLOBALD-4157-bulk-import-access` (user wrote 4117, assumed typo for 4157). Per-ticket named manifest: `DMT/manifest/CIBGLOBALD-4157-package.xml` (convention: `manifest/<TICKET>-package.xml`; the generic tracked `manifest/package.xml` was restored to its snapshot). Nothing committed yet: waiting for explicit go-ahead. Local ConsultationIT file is at the snapshot (does not show allowCreate=false); optionally re-retrieve it fresh before committing so branch history reflects the org.

**Git naming:** branch renamed to `4157` (number only, user preference for personal repo). Manifest file name kept as CIBGLOBALD-4157-package.xml unless user says otherwise. User asked about scrubbing ticket names/comments from code to obscure origin; I declined the code scrub (see chat).

**Git 2026-10-07:** committed 00a273eb on branch 4157 (CIBGLOBALD-4157 restrict Bulk Import LWC...). origin = github.com/brmolina/BBVA.git exists (personal backup; I had wrongly said there was no remote). `git push -u origin 4157` was DENIED by auto-mode classifier (Out-of-Place Publication): user must push or allow it. Project .claude/settings.json created with git/sf-read allow rules (no push, no deploy).

**NEW PLAN 2026-10-07 (supersedes the !ConsultationIT / !DMT_Read_Only approach):** gate Bulk Import by: System Administrator OR DMT_Line_God OR new custom permission `DMT_BulkImportAccess`. Grant the new custom permission AND allowCreate=true on `DMT_BulkImportProgress__e` to the permission sets the user will get confirmed (user is asking the team which PSs may bulk import). Waiting for that list.
- Catch flagged to user: ConsultationIT, DMT_Access and DMT_Integration_Analytics all grant DMT_Line_God, so keeping Line_God in the OR still lets ConsultationIT users in (and the publish fails without event Create). A custom permission cannot detect System Administrator profile (needs getRecord User.Profile.Name or Apex). Already deployed and now probably redundant: custom permission DMT_Read_Only + DMT_ReadOnly PS entry + LWC !hasDMTReadOnly.
- Org refresh (full-ish retrieve) started in background 2026-10-07 via 6 wildcard manifests (apex, ui, automation, security, config, objects) in scratchpad/refresh; log scratchpad/refresh/refresh.log. Check results before analysis; nothing committed from it yet.

**PLAN v3 2026-10-07 (supersedes v2, new custom permission DROPPED):** gate = DMT_Line_God (+ keep !ConsultationIT). Org query (SetupEntityAccess) shows DMT_Line_God is granted by: System Administrator profile, DMT_Access, DMT_Integration_Analytics, ConsultationIT. DMT_Access custom perm is granted by many more sets (incl. DMT_ReadOnly, DMT_Approver_Configuration, DMT_CommercialActivity, DMT_Limit_Test, ConsultationIT). Event DMT_BulkImportProgress__e Create: only sysadmin profile + one other profile + (reverted) ConsultationIT; permission sets DMT_Access and DMT_Integration_Analytics have NO event permission. So to make it work: add event allowCreate=true to DMT_Access and DMT_Integration_Analytics (NOT to every set that merely has the DMT_Access custom permission: that would include ConsultationIT and DMT_ReadOnly). Pending: user confirmation, cleanup of DMT_Read_Only (local + deploy + destructive delete) after background retrieve finishes.

**Org refresh 2026-10-07 13:12-13:23:** full wildcard retrieve finished (6 batches OK; ~791 files with real content diffs, ~3000 new files, rest line-ending noise). Working tree on branch 4157 is dirty with ~6100 entries. `git add DMT` + commit was DENIED by the auto-mode classifier (Data Exfiltration, bulk employer metadata to a repo that is pushed to personal GitHub). Not committed. User must commit/push it himself or decide to skip. Local DMT_ReadOnly and dmt_bulk_import now equal the org versions again (they still reference DMT_Read_Only), so the cleanup edits still have to be redone.
Pending decision from user: option 1 (!ConsultationIT in LWC) vs option 2 (Apex canBulkImport() using isCreateable on the event + test); then allowCreate on DMT_Access and DMT_Integration_Analytics; delete DMT_Read_Only.

**FINAL PLAN v4 2026-10-07 (user decision):** gate = `hasDMTLineGod` ONLY (no !ConsultationIT, no new custom permission). Event allowCreate=true added to permission sets DMT_Access and DMT_Integration_Analytics (the only sets with God besides ConsultationIT and the sysadmin profile). DMT_Read_Only custom permission removed.
- LOCAL edits done (all fresh-retrieved first): dmt_bulk_import.js (imports of ConsultationIT and DMT_Read_Only removed, hasAccess = hasDMTLineGod), DMT_ReadOnly (DMT_Read_Only entry removed), DMT_Access and DMT_Integration_Analytics (+event objectPermissions, allowCreate=true), customPermissions/DMT_Read_Only file deleted locally. Manifest: manifest/CIBGLOBALD-4157-package.xml updated; destructive: manifest/CIBGLOBALD-4157-destructive/{destructiveChanges.xml,package.xml}.
- DEPLOY DENIED by classifier (Modify Shared Resources): user must run (1) sf project deploy start -x manifest/CIBGLOBALD-4157-package.xml -o DMT_TCM_DEV --ignore-conflicts, then (2) destructive: sf project deploy start --manifest manifest/CIBGLOBALD-4157-destructive/package.xml --post-destructive-changes manifest/CIBGLOBALD-4157-destructive/destructiveChanges.xml -o DMT_TCM_DEV. Org check: only DMT_ReadOnly referenced DMT_Read_Only.
- Known consequence (user accepted): ConsultationIT-only users also have DMT_Line_God, so they see the screen; without event Create the publish still fails for them.
- Commit of the org sync (6000 files) was denied; still uncommitted.
