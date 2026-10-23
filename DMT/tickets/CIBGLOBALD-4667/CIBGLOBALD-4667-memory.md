---
name: cibglobald-4667
description: Add Group/Subsidiary badge to client search results in the clone modal (Lines and Opportunities); investigation stage
metadata:
  node_type: memory
  type: project
  originSessionId: 9a987690-b8f1-462b-9f7a-17099593157d
  modified: 2026-10-19T08:14:57.320Z
---

# CIBGLOBALD-4667 - differentiate Groups vs Subsidiaries in the clone modal

Branch name in the BBVA repo: feature/CIBGLOBALD-4667-dmt-diferenciar-visualmente-groups-y-subsidiaries-en-el-modal-de-clonacion (personal repo branch should be `4667`).
Session started 2026-10-19 while the personal repo was checked out on branch 4630 with uncommitted 4630 work (do not mix).

## Requirement (pasted by the user)
- The client search in the clone modal returns Groups and Subsidiaries with no visual cue; only the client ID tells them apart.
- Add a discreet label/badge next to the record name: `Group` or `Subsidiary`. Label-based (no colours/shading). Same design as the current modal.
- Applies to cloning Lines (dmt_line__c) and Opportunities (DMT record type).
- QA: open clone modal of a Line, search Groups and Subsidiaries, each result shows its label; repeat for Opportunities; selection and clone keep working unchanged.

## User hints
- Start from dmt_opp_tab, dmt_line(s)_tab and dmt_custom_path (most likely: the Clone button is on the highlights panel via the custom path component).
- Single clone button, not bulk. Need to know if the controller behind it is used elsewhere and whether bulkification is needed (probably not).
- Can use DMT_TCM_DEV in the browser (record pages of dmt_line__c and Opportunity DMT RT).

## Status
- Investigation just started. Nothing changed yet.

## Findings (2026-10-19, org = DMT_TCM_DEV, fresh retrieve to scratchpad)
- The Clone button is NOT in dmt_custom_path / dmt_opp_tab / dmt_lines_tab (no 'clone' in them). It is a quick action that launches a screen flow:
  - Line: QuickAction DMT_Line__c.Clone_Line -> Flow DMT_Clone_Line -> screen CloneLineScreen -> LWC c:dmt_search_record_info (outputs clientId, isSubsidiary).
  - Opportunity: QuickAction Opportunity.CloneOppAction -> Flow Clone_Opportunity -> screen CloneOpportunityScreen1 -> LWC c:dmt_localClient_picker (outputs clientId). Then Flow DMT_Clone_Opp_Data -> Apex DMT_OpportunityCloneUtil.
- Both LWCs call DMT_Client_Selector.searchClient(searchTerm): SOSL FIND term* IN ALL FIELDS RETURNING Account(Id, Name, DES_Group_Code__c, g_customer_id__c). Returns the same Account list for both.
- dmt_localClient_picker is ALSO embedded as customlwc in ~27 cfGuarantorsModalFields_*_BBVA FlexCard definitions (Guarantor modal) -> a badge there would show in the guarantor modal too unless made opt-in.
- dmt_search_record_info already derives Group/Subsidiary in handleSelect: isSubsidiary = !DES_Group_Code__c && g_customer_id__c !== null. Results are filtered to rows with group code or customer id.
- Data check: DES_Group_Code__c != null covers RTs Group, Prospect_Group, SubGroup, SupraGroup, Shared_management_Group (+3 odd commercial-client rows); DES_Group_Code__c = null with g_customer_id__c != null are all Subsidiaries (Subsidiary_Commercial_Client, Prospect_Subsidiary, BEC manual, 3 New_Commercial_Client with null structure type).
- Local flows are stale vs org (diff differs); local LWC copies were refreshed by retrieve (dmt_custom_path_line.js changed locally by that retrieve).
- Not bulk: one quick action = one flow interview = one search per keystroke; no bulkification needed for the search. Clone Apex (DMT_OpportunityCloneUtil) is invocable from flows and was not analysed yet.
- Open questions sent to user: badge label for SubGroup/SupraGroup/Shared Mgmt; scope for Guarantor modal; branch handling (repo is on 4630 with uncommitted work).

## Session 2026-10-19 (cont., Opus)
- Git: 4630 work committed locally on branch 4630 (135402b0, includes tickets/CIBGLOBALD-4630 + DMT/tickets/CIBGLOBALD-4630/CIBGLOBALD-4630-package.xml; manifest/package.xml restored to main's generic version). Push + merge to main was BLOCKED by the auto-mode classifier -> 4630 NOT pushed, NOT merged. Branch 4667 created from 4630 (so it contains the 4630 commit).
- Retrieved into project on 4667: DMT_HPG_Utils, DMT_LaunchDealManagementService, DMT_Client_Selector(+_Test), dmt_search_record_info, dmt_localClient_picker, dmt_highlight_panel, Deal Mgmt LWCs, the 3 clone flows, 2 quick actions (org sync diffs in flows, highlight_panel, Client_Selector_Test).
- Browser confirmed (Line a5ugN0000001eLBQAY, Opp 006KE000003QsIMYA0): Clone lives in dmt_highlight_panel dropdown -> opens quick action Clone_Line / CloneOppAction. Results show same standard:account icon + Name + code (G... or ES...). No type label. Nothing saved.
- Classification sources: DMT_LaunchDealManagementService: clientType = DES_Structure_Type__c == 'Subsidiary' ? 'client' : 'group'; resolveGroupAccountId treats Supragroup/Group/Subgroup/Shared Management Group as group nodes. DMT_HPG_Utils.buildClientGroupStructure: structure type Supragroup/Group/Subgroup + Prospect RTs; getGroupFromRecordCode throws PROSPECT_GROUP_NO_SUBSIDIARY ('Please generate a subsidiary for this prospect group before accessing Deal Management.') = the Deal Mgmt error the user remembered.
- Picklist DES_Structure_Type__c: Supragroup, Group, Subgroup, Subsidiary, Shared Management Group, Non Client, NIF Client, No Client.
- Data DMT_TCM_DEV: Subsidiary 10105 (9969 Subsidiary_Commercial_Client, 119 Prospect_Subsidiary, 17 BEC manual); Group 64 (16 Group, 48 Prospect_Group); Subgroup 22; Supragroup 3; Shared Mgmt 5; NIF Client 39 (no codes); null 3 (New_Commercial_Client, with g_customer_id). Code-based rule mismatches: BBVA Internal Contact (Subsidiary, code GRPBBVAINTERNAL) and non-disclosed (Subsidiary, GXXXXXXXXXXXXXX + ES0182XXXXXXXXX).
- Badge precedent: lightning-badge in dmt_highlight_panel and dmt_connect_operations. 'Basada en etiquetas' = text tag/badge (vs colours), not Custom Labels per se.
- Proposal: add DES_Structure_Type__c to searchClient SOSL; badge Subsidiary when 'Subsidiary', Group for Supragroup/Group/Subgroup/Shared Mgmt; others no badge (to confirm). Badge text via new Custom Labels. Picker shared with Guarantor FlexCards -> opt-in @api flag set by Clone_Opportunity flow (to confirm). Flow isSubsidiary logic left unchanged.

## Git done (2026-10-19)
- 4630 pushed, merged into main (721eb768), main pushed. 4667 has an org-sync commit, main merged in, pushed to origin/4667. Tree clean.

## Flow semantics (verified)
- Line flow DMT_Clone_Line uses isSubsidiary (from dmt_search_record_info) only to choose the code copied to the new Line: true -> Client_Code__c = g_customer_id__c; false -> Client_Code__c = DES_Group_Code__c (+ same-group / custom association logic). Client__c = selected Account Id either way.
- Opportunity flows (Clone_Opportunity, DMT_Clone_Opp_Data) do not use isSubsidiary at all.
- FlexCard GuarantorsModalFields v36 is active in OmniUiCard, but the live guarantor modal is LWC dmt_opp_product_modal_guarantor (4630); the clone button does not use any FlexCard. User: ignore FlexCards -> badge always on in dmt_localClient_picker, no Opp flow change.
- Re-asked user (explained): Q1 label for Supragroup/Subgroup/Shared Mgmt; Q2 no badge for NIF/blank; Q3 align isSubsidiary with structure type (affects 'non - disclosed' and 'BBVA Internal Contact').

## IMPLEMENTED + DEPLOYED (2026-10-19, branch 4667, DMT_TCM_DEV)
- Decisions: badge only (no flow/logic change). Subsidiary -> 'Subsidiary'; Supragroup/Group/Subgroup/Shared Management Group -> 'Group'; others (NIF Client, blank) no badge. FlexCards ignored. Reuse existing labels DES_STR_TYPE_Group / DES_STR_TYPE_Subsidiary (not modified).
- Files: classes/DMT_Client_Selector.cls (searchClient returns DES_Structure_Type__c); lwc/dmt_search_record_info (.js getClientTypeLabel + clientTypeLabel, .html lightning-badge); lwc/dmt_localClient_picker (same). Manifest DMT/tickets/CIBGLOBALD-4667/CIBGLOBALD-4667-package.xml (API 65.0).
- Pre-deploy org == pre-edit local for all 5 files. Dry-run Succeeded 5/5 DMT_Client_Selector_Test. Deploy Status Succeeded, 3 components, 5 tests, 0 errors. Post-deploy org == local.
- Browser verified (new tab, search 'Iberdrola'): Line clone (a5ugN0000001eLBQAY) and Opp clone (006KE000003QsIMYA0) show Group / Subsidiary; Subgroups IBERDROLA GENERACION MEXICO / RENOVABLES MEXICO show Group; selection still works. Nothing saved.
- Process lesson: user demands (1) fresh retrieve right before editing, (2) explicit list of exact files before any edit, (3) say if flow or LWC.
- Pending: user QA, commit (when user cleans tree), commit message + Spanish ticket note.
- 2026-10-19 follow-up: searchClient now search.query(searchQuery, AccessLevel.SYSTEM_MODE) + doc sentence (FLS must never block; sharing still with sharing). DES_Structure_Type__c read granted in all 7 DMT perm sets + all BBVA Desktop profiles anyway. Dry-run + deploy Succeeded 5/5, org == local; anonymous read-only call returned 182 rows with Group/Subsidiary values.

## CLOSED (2026-10-19)
- Committed on 4667, pushed, merged into main, main pushed. Commit message + Spanish ticket note in tickets/CIBGLOBALD-4667/. User retrieves and commits on the work computer. Pending only: user QA on the work side.
