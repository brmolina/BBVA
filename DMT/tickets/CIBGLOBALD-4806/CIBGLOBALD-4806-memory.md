---
name: CIBGLOBALD-4806
description: "Client Data on Group-level Opps compares against Group (AccountId) instead of Main Holder; Client Type must come from HPG not Account.Segment; investigation stage"
metadata:
  type: project
---

# CIBGLOBALD-4806 - Client Data compare uses Main Holder; Client Type from HPG

Started 2026-11-04. Team branch: feature/CIBGLOBALD-4806-dmt-bugfix-comparacion-incorrecta-de-client-data-en-opportunities-creadas-a. Personal branch: 4806.

## Requirement (pasted by user)
1. Group-level Opp (AccountId = Group, client data fetched from selected Main Holder and stored in DMT_Opportunity_Client__c). Client Data component then compares using Opportunity.AccountId (Group) -> artificial differences. Fix: use the Main Holder stored on DMT_Opportunity_Client__c for query/compare; keep Customer/Subsidiary behaviour; review HPG / client-data update calls.
2. Client Type at Opp creation comes from Account.Segment; must come from HPG response (Customer-level: the customer; Group-level: Main Holder). Keep existing Client Type field. Client Data must use same criterion. Confirm HPG attribute + mapping to Client Type values.
QA: Group opp + Main Holder -> no artificial diffs; real changes detected; Client Type = HPG value for Customer and Main Holder; HPG wins over Segment; no regressions.

## User hints
Entry point probably dmt_page. User unsure what Main Holder is (Account? Opp client item with toggle?).

## Findings (2026-11-04, fresh org retrieve DMT_TCM_DEV to scratchpad, no local edits)
- No LWC named dmt_page in the org. Creation = LWC dmtNewOpportunityModal -> DMT_CreateOpportunityService.createOpportunity. Client Data = LWC dmt_opp_client -> DMT_OpportunityClientController.getOpportunityClientContext / getMainHolderData.
- Client Type = DMT_Opportunity_Client__c.Counterpart__c (field label Counterpart, LWC label 'Client Type', picklist Corporates, Financial Institutions, Fin Inst-B, Fin Inst-I, Promotor, Pub Inst, SME, Small Ent, Sov, XXXX).
- Main Holder = Custom_Association_Opportunity__c.g_customer_id__c (alpha code). At creation (Group flow) it is NOT picked by the user: resolveClientByEntific picks the first HPG client of the group in the Booking Geography country that exists in SF (resolvedClientId); assoc.g_customer_id__c = that Account.g_customer_id__c; also DMT_Custom_Association_ClientOpportunity__c.DMT_Client__c = resolvedClientId. In Client Data the user can change it (main holder toggle in the client table -> getMainHolderData). Opportunity.DMT_Main_Holder_Name__c is a denormalized name (DMT_OpportunityGroupHolderService).
- Creation (group): HPG via DMT_HPG_Utils.getCustomerHPGS(clientId=resolvedClientId, customerId=resolveHpgCustomerId(resolvedClientId) = Local_Client__c.Alpha_code__c unless RT Prospect_Subsidiary), Counterpart = resolveSegmentLabel(resolvedClient.DES_Segment__c) ('00004'/blank -> ' ', unknown -> raw code), comparison account from Group clientId.
- Client Data (group): resolveClientId() ALWAYS returns opp.AccountId (Group). HPG via fetchClientInitialData(clientId=Group, 'Y/N', page 1 size 5000, customerId=assoc alpha) then filter row by customerId. Original Counterpart = SEGMENT_TO_COUNTERPART(opp.Account.DES_Segment__c) = GROUP segment ('00004' -> '', unknown -> null) -> certain artificial diff on Client Type. Other possible diff: customerId mismatch (Local_Client alpha vs Account.g_customer_id__c). getMainHolderData builds new client with Counterpart from Group segment too, Scoring default 0.
- resolveMainHolderClientId (used by clone) also returns opp.AccountId via resolveClientId.
- HPG classification candidates in DMT_HPG_GlobalPosition.Data: customerSegmentName (unused anywhere in DMT code; mock has no value). customerCounterpartiesCodesDesc is 'Star Code' (rating-like), not client type. Real values need a live read-only probe or tech lead.
- Exception logging in DMT_CreateOpportunityService uses DES_Exception_Utils.logException (anti-pattern per rules).


## Probes 2026-11-04 (user-authorized read-only anonymous Apex in DMT_TCM_DEV, no DML; scripts in session scratchpad)
- Branch 4806 created from main (user OK; tree was on 4811 clean; switch back to 4811 when resuming it).
- Raw HPG DMT_HPG_GlobalPosition body has NO customerSegmentName. Client Type attribute = **ratingSystemId** (in wrapper). Values over IBERDROLA+ACCIONA groups (1746 rows): Corporates 323, SME 46, Small Ent 282, Fin Inst 9, Fin Inst B 19, Fin Inst I 3, Prom 1, XXXX 1063. Catalog D971 (source of Client Type options in dmt_opp_client) = Corporates, Fin Inst, Fin Inst-B, Fin Inst-I, Prom, Pub Inst, Small Ent, SME, Sov, XXXX -> identical except 'Fin Inst B'/'Fin Inst I' need hyphen. Counterpart__c picklist is unrestricted (stores 'Fin Inst').
- QA example: IBERDROLA INMOBILIARIA S.A. (001KE000008FV9JYAW, ES0182002102678) DES_Segment__c 00005 (Corporates) but HPG ratingSystemId = SME. CEOLICA HISPANIA (ES0182001888094) = Corporates both.
- Creation path vs Client Data path return the same HPG values for the main holder (Client Data fetches whole group 549/1197 rows with group clientId then filters by alpha; single-customer call returns 1 row).
- getOpportunityClientContext on 006gN000009waluQAA (fresh Group opp IBERDROLA EBN 0311): all equal except CAMN (current F.41.10.01 code from activityMinimumLevelCodeId vs original resolved by A521 name; A521 has no 'Residential' entry / F.41.10.01) -> pre-existing catalog/CAMN issue, not group specific. Counterpart original from Group segment (equal in DEV since all 00005).
- Cloned group opps 006gN000009XhCIQA0 and 006gN000009lr26QAA: DMT_Opportunity_Client__c.Custom_Association__c points to the SOURCE opp association (a7JKE000000GnK52AK of 006KE000003QsIMYA0, a7JKE000000GnTv2AK of 006KE000003Qve6YAC) -> resolveAssociationClient finds nothing -> Client Data shows empty Main Holder/current values. Clone bug (DMT_OpportunityCloneUtil?), scope question. lr26 also has a 2nd Opp Client with null association.
- Third segment map: DMT_HPG_MainTableCustomController.calculateSegment (00003 -> 'FINS', not in D971), used in saveOpportunityClients for secondary clients.
- Questions open to user: fallback when ratingSystemId blank/not in D971; clone association bug in scope; CAMN in scope; replace calculateSegment too.

## User decisions (2026-11-04)
1. Client Type fallback when HPG ratingSystemId blank / not in D971: keep today's behaviour (Segment mapping).
2. Clone association bug: fix it in this ticket (clone is also a creation).
3. CAMN: user to look at Opp 006gN000009waluQAA Client Data tab before deciding.
4. Scope = creation (new + clone) only, not display/client-table save; calculateSegment documented as known possible issue, not changed.
5. Move DES_Exception_Utils.logException in DMT_CreateOpportunityService to DMT_AsyncOrchestrator + DMT_LogExceptionPayload.
- 2026-11-04 tech lead message: Client Type is inferred from HPG Rating Tool: gf_rating_system_id -> ratingSystemId (no longer Account Segment). Confirms probe finding.
- CAMN: recommended OUT of scope (different cause: creation saves HPG code activityMinimumLevelCodeId, Client Data compares A521 matched by HPG description since the 'CAMBIO A521' change; A521 misses entries). Awaiting user OK.

## Implemented + deployed (2026-11-04, branch 4806)
- DMT_CreateOpportunityService: constant CLIENT_TYPE_TAXONOMY_CATALOG 'D971'; new public resolveClientTypeFromHpg(Data) (ratingSystemId, 'Fin Inst X' -> 'Fin Inst-X', validated via DMT_Passport_Selector.getTaxonomyValuesByCatalogAndValues; org selector does NOT select DMT_Active__c, so no active filter); buildOpportunityClient Counterpart = HPG value else segmentLabel (covers new opp + both clone paths that rebuild the client).
- DMT_OpportunityClientController: resolveClientId -> Main Holder Account via new findMainHolderAccount(alpha) (USER_MODE, per-transaction cache mainHolderAccountsById), fallback opp.AccountId; buildOriginalRecord Counterpart original = HPG value else Segment of that same client; buildDmtClientFromOriginal Counterpart = original Counterpart. resolveMainHolderClientId has no callers (checked org).
- DMT_OpportunityCloneUtil: same-account branch inserts the cloned Opp Client after the cloned association and sets Custom_Association__c = cloned association.
- Tests: DMT_CreateOpportunityServiceTest new testBuildOpportunityClient_ClientTypeFromHpg (D971 via DMT_Test_DataFactory.generateTaxonomyValue); DMT_OpportunityCloneUtilTest clonesGroupOpportunityToSameGroup asserts the cloned client association. DMT_OpportunityClientControllerTest untouched (64 System.assert left).
- Org check before deploy: unchanged vs baseline. Dry run Succeeded 46/46; deploy 0AfgN000003TLAdSAO Status Succeeded 46/46 (RunSpecifiedTests: 3 test classes); org == local for the 5 classes.
- Post-deploy probe 006gN000009waluQAA: clientId = Main Holder 001KE000008FV9JYAW, Counterpart original SME vs stored Corporates (record created under old Segment rule; new opps store SME).
- Logging: user decided 2026-11-04 to keep DES_Exception_Utils (bugfix = minimum change). Not mentioned as a change.
- Known issues for the note (not fixed): CAMN code vs A521 description; calculateSegment in client-table save (00003 -> FINS); existing records keep their old Client Type.
- Baseline (pre-change org retrieve) copies in session scratchpad baseline/.

## Evidence (2026-11-04, Sonnet subagents)
- Bug (DMTPRE2, read-only): clone bug reproduced on 006KK000003LE3uYAG (same-group IBERDROLA clone of 006KI000005e5FEYAY, client points to source association a7JKI000000L1yt2AC, Client Data all empty) -> CIBGLOBALD-4806-bug-clone.jpg. Client Type bug partial on 006KI000005ePpGYAU (Group seg 00001 Sov, Main Holder 00006 Fin Inst-B; warning on Client Type but HPG service down) -> CIBGLOBALD-4806-bug-clienttype.jpg. In PRE2 the clone has no association of its own at all (older clone code).
- Fix (DMT_TCM_DEV): new Group opp 006gN000009yYrHQAU 'CIBGLOBALD-4806 fix evidence' (Deal Management > New Opportunity, IBERDROLA, ES, ES0182): Main Holder ES0182002102678, Counterpart SME, own association; Client Data Client Type SME no warning, only CAMN warning (known issue) -> -fix-clienttype.jpg. Clone 006gN000009ybnVQAQ (same group): client -> own association a7JgN000001vbv7UAA, fields filled -> -fix-clone.jpg. All PASS.
- Account page 'New Opportunity' quick action (Account.New_Opportunity_Group) Country dropdown stayed empty (not ours).
- Next: wrap-up (per-file staging list, then commit msg + Spanish note after user confirms staging).
