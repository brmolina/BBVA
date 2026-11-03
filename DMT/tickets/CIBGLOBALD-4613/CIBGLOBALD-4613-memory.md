---
name: cibglobald-4613
description: Passport General Validations (Variadito) fixes - Opp User-Defined tenor check only for One-Off products; MX Treasury restriction without amount in Depos/Repos/Derivatives tables
metadata:
  node_type: memory
  type: project
  originSessionId: e2e3c3bd-5f29-491b-9407-f65486a65b76
  modified: 2026-10-29T11:20:34.505Z
---

Branch (jira): feature/CIBGLOBALD-4613-dmt-bugfix-correcciones-en-global-validations-variadito-para-lines-y. Personal repo branch: 4613 (not created yet; tree was on main/4726 owned by other sessions on 2026-10-26).

## Ticket (pasted 2026-10-26)
1. Opp Passport General Validations: 'All User-Defined tenors have a Payment Date' must not show/compute for Line products; One-Off keeps current logic; mixed Opp considers only One-Off products. (Ticket names DMT_LineFeatureGenCons_Calc, but the message lives in DMT_OppFeatureGenCons_Calc L197-209.)
2. Treasury Lines MX: operational restriction checked without the matching amount must give at least YELLOW; review mapping Available Products checks -> MX amount tables (Derivatives, Depos, Repos); other geographies unchanged.

## Findings (org DMT_TCM_DEV, 2026-10-26)
- Variadito = General Validations list of the passport (DMT_Passport_Helper L942 Line -> DMT_LineFeatureGenCons_Calc.checkValidations; L978 Opp -> DMT_OppFeatureGenCons_Calc.checkValidations).
- OpportunityLineItem.DMT_Line_Oneoffdeal__c picklist: 'Line' / 'One-off deal' / blank (46 rows blank). Existing code (getMissingMandatoryFieldsForPassport) treats only 'Line' as line. Line products are always Bullet in data, so the check is always GREEN noise for them.
- MX template = LWC dmtRiskTablesLine + Apex DMT_RiskTablesLineController (not the riskTablesLine FlexCard). MX shows: Derivatives amount table + Derivatives Restrictions products table, Depos table + Depos Restrictions, Repos table + Repos Restrictions; Equities hidden for MX; FD/DvP amounts from currency input.
- Mapping product -> table comes from DMT_OperationalRestrictionsTRSR__mdt layout2 flags (only MX_2 records have them): DMT_Derivatives_layout2__c IRSW/FOEX/CCSW/DBIC/BOSP/EQSP; DMT_Depos_layout2__c DELE; DMT_Repos_layout2__c REAC/REPA. The 'derivativesLine' checkbox (LPI DMT_DerivativeRestriction__c) means 'line enabled in that table'.
- Amounts: DMT_Risk_Line_Term__c by DMT_Risk_Type__c Derivatives/Depos/Repos (controller comment: total stored in first term).
- Existing Line checks: noSettlementAmount (FD/DvP checkbox vs FD_Amount__c/DvP_Amount__c, all geos), deriRestricNOFdDvp. No check for Derivatives/Depos/Repos amount. restricGreaterTerm compares every LPI Max_Tenor_WC__c vs Derivatives terms only (wrong for MX DELE/REAC/REPA).
- DMT_Passport_Selector.getOperationalRestrictionMDT does not select the layout2 fields.
- Tests: DMT_LineFeatureGenCons_Calc_test, DMT_OppFeatureGenCons_Calc_Test (org only, not in local repo), DMT_Line_Helper_test covers Line calc.
- Local DMT_Passport_Helper differs from org (org modified 2026-10-26 10:14); retrieve before any edit.

## Decisions (user, 2026-10-26)
- Amount filled in = at least one DMT_Risk_Line_Term__c of the mapped type with DMT_Amount__c > 0.
- Fix restricGreaterTerm in this ticket: layout2 Depos/Repos products compared with Depos/Repos terms (metadata-driven, other geos unchanged).
- New MX amount validation = ONE combined entry, yellow, listing product (table).
- Opp: no One-Off product -> validation not added; blank DMT_Line_Oneoffdeal__c counts as One-Off (same as existing isLineProduct rule).

## Implementation (branch 4613, 2026-10-26)
- DMT_OppFeatureGenCons_Calc: new @TestVisible userDefinedTenorsValidation(productsMap, tenorsMap) (null when no One-Off product) + isLineProduct(oli) helper.
- DMT_LineFeatureGenCons_Calc: TreasurySettlement branch loads DMT_Passport_Selector.getRiskLineTermsByLine; new restricGreaterTerm(lpis, terms, mapOpRestric) (old 2-arg delegates); new restrictionWithoutAmount (null when no layout2 restriction); getRestrictionRiskType, isLayout2Restriction.
- DMT_Passport_Selector: layout2 fields in getOperationalRestrictionMDT; new getRiskLineTermsByLine.
- Labels: dmt_cl_FeatureRestrictionAmountTitle / Green / Yellow.
- Tests: 4 new in DMT_LineFeatureGenCons_Calc_test (in-memory CMDT + DMT_UTIL.buildLineProductItem/buildRiskLineTerm), 4 new in DMT_OppFeatureGenCons_Calc_Test; Assert class in both files; fixed pre-existing org failure testCheckValidationsAllConditions (clientsGroup now mirrors the factory client).
- Manifest DMT/tickets/CIBGLOBALD-4613/CIBGLOBALD-4613-package.xml.

## Deploy
- DMT_TCM_DEV deploy 0AfgN000003O0mmSAC Succeeded, 216/216. Selector needs extra tests for 75%: --tests DMT_LineFeatureGenCons_Calc_test DMT_OppFeatureGenCons_Calc_Test DMT_Passport_Helper_test DMT_Passport_Handler_test DMT_Line_Helper_test DMT_Passport_FeatureSync_test DMT_Passport_CalloutQueueableTest DMT_GetCreationParameters_Test DMT_OpportunityProductsControllerTest DMT_TaxonomyMultipleProductsTest. Org retrieve matches local (test classes differ only by EOF newline).

## Test records DMT_TCM_DEV
- Opp Line only 006KE000002oZuIYAU; One-Off User-Defined 006KE000002ouTdYAI; mixed 006KE000003QudyYAC.
- MX lines: a5uKE000000GwwKYAS (Depos/Repos enabled no amount -> yellow), a5uKE000000GwPGYA0 (FX/CCS no Derivatives terms -> yellow), a5uKE000000Gw1TYAS (green), a5ugN0000001eD7QAI (Approval; DELE maturity 3 > Depos 2 -> maturity yellow). ES a5uKE000000Gx3uYAC (no new entry).
- Evidence PNGs + 4613-apex-validation-results.txt in DMT/tickets/CIBGLOBALD-4613/.
- HPG down intermittently: passport Calculate fails with NPE in DMT_HPG_MainTableCustomController.fetchInitialData L198; retry later.

## Amortization Type finding (2026-10-26, corrected)
- Org picklist gf_amortization_type__c = Custom/Lineal/Bullet (unchanged since 2025-09-23) is NOT what the UI uses. LWC dmt_opp_product_details_schedule (fields.js) offers its own options Bullet / Amortizing (value Linear) / User-Defined; field unrestricted, so 'User-Defined' saves (last created 2026-10-08). No 'Custom' record exists. User-Defined is NOT removed: no tech lead question needed.
- Field locked + shown as Bullet when the product is a 'double product': DMT_OpportunityProductsController.isDoubleProduct (taxonomy gf_catalog_atrb_val13_name__c = DOBLES, Leasing). Stored value can still be User-Defined (older records).
- Non-double One-Off User-Defined products for a yellow test: Opportunity IBERDROLA 2026 006KE000002ooDlYAI (Renting, Preguarantees).
- User testing step by step: use case 1 (Line only) and 2 (One-Off) confirmed by user.

## How the passport gets its General Validations (verified in code 2026-10-26)
- Only on Calculate: DMT_Passport_Handler.buttonCallPassport -> DMT_Passport_Helper.setPayloadPassport -> handleOpportunityPayload / handleLinePayload -> calculateFeatureGenConsOpp / calculateFeatureGenCons -> *FeatureGenCons_Calc.checkValidations. Result goes in the request to the external Passport service; its response is saved in Passport__c.DMT_Passport_Save__c (Helper L1142). Page load (getInformationPassport) only renders that saved JSON. Calculate also needs HPG (getLastDay, getGroupFromClientAccount).
- Tenor and MX restriction rules use only Salesforce data; rating/client rows use HPG data (clientsGroup).
- Proof without the UI: anonymous Apex with savepoint + DML + checkValidations + rollback (DMT/tickets/CIBGLOBALD-4613/4613-opp-tenor-scenarios-dml.apex/.txt). Opp 006KE000002ooDlYAI has 0 Opportunity clients; its Calculate fails with external 00000010#INVALID COMBINATION OF PARAMETERS.
- User allowed DML in DMT_TCM_DEV for testing (2026-10-26).

## On-screen Opp proof (2026-10-27, Opp 006KE000002ouTdYAI, PASSPORT-5992 a6UKE000000L2WV2A0)
- Baseline green -> tenor a6tKE00000002VdYAI date null -> YELLOW 'Tenors Payment Date is missing' -> Leasing 00kKE000003AOF8YAO set to Line -> row not shown -> restored (One-off deal, 2026-08-18) -> green. Snapshot compare: no field differences. Evidence 4613-opp-ui-1..4 PNGs.
- GOTCHA: DMT_TableTenors.getTenorsData AUTO-CLEANUP deletes tenors with null Payment Date whenever the product schedule loads (Opportunity page reload); syncTenors does the same on save. Calculate from the Passport record page (does not load the schedule). Deleted tenor was undeleted + restored.

## On-screen MX proof (2026-10-27, line a5uKE000000GwwKYAS, PASSPORT-6477 a6UKE000000L5db2AC)
- User confirmed MX use case A (yellow with Reverse Repo, Repo, Depo Lent).
- Depos term a5vKE000000L3jgYAC = 500000 -> Depo Lent drops off; Repos term a5vKE000000L3jiYAC = 300000 -> GREEN; both restored to null (compare vs snapshot = no diff), recalculated -> original yellow. Evidence 4613-mx-ui-1-depos-amount.png, 4613-mx-ui-2-repos-amount-green.png.
- Editing a risk term flags the passport 'Template values have been modified' (touches Passport LastModifiedDate); Calculate must be clicked again after that.
- PASSPORT-6417 (a6UKE000000L4Y12AK, line a5uKE000000GwPGYA0) recalculated 10:57: YELLOW 'FX (Derivatives), CCS (Derivatives)' (line has no risk terms). Next: user use case B.

- User confirmed use case B (FX, CCS). Use case C (maturity per table): Depo Lent LPI a5tKE000000LBYWYA4 Max_Tenor_WC__c changed '2' -> '30' (UI shows 1M), recalculated 11:07 -> 'Maximum consumption and maturities relationship' YELLOW listing only Depo Lent. User confirmed C; restored to '2' (snapshot compare no diff), PASSPORT-6477 recalculated 11:34 back to original (maturity green, amount yellow). Next: use case D ES unchanged (PASSPORT-6566 a6UKE000000L5q62AC, line a5uKE000000Gx3uYAC, calculated after deploy, no new row). LPI snapshot scratchpad mx_lpi_snapshot.csv. Evidence 4613-mx-ui-3-depos-maturity-yellow.png.

- User confirmed use case D (ES, no new row) 2026-10-27. All 4 MX + 4 Opp use cases confirmed.
- 2026-10-27: user angry at line-number staging list (diffed vs stale personal repo; the 'not ours' Selector hunks were only personal-repo staleness, org pre-change r2 vs now = only our 2 changes). Added // CIBGLOBALD-4613 to every touched line (script scratchpad mark_lines.py, baselines r1/r2 pre-change org, Opp test = git HEAD) + <!-- CIBGLOBALD-4613 --> above the 3 labels. Redeployed 0AfgN000003OpqrSAC Succeeded 216/216; org == local (tests EOF only). User corrected marker style (new block = one comment above; changed existing line = trailing); redone with scratchpad remark.py, redeployed 0AfgN000003OlfCSAS Succeeded 216/216, org == local. Then user flagged duplicate SOQL: getRiskLineTermsByLine removed; new overload DMT_Passport_Selector.getRiskLineTerm(recordId, Set<String> riskTypes) (old 1-arg delegates with Derivatives; other callers: Calc validationRenovation, DMT_Passport_Helper L289); Treasury branch now ONE query lineRiskTerms (Derivatives, Depos, Repos) for waiver, maturity and amount. Deploy 0AfgN000003OpioSAC Succeeded 216/216; PASSPORT-6477 recalculated 13:32 same result. Rules added to global CLAUDE.md (anti-patterns confirm first, no extra SOQL, ticket marker). 2026-10-27 afternoon (user approved): ENHANCEMENTS. (a) transaction cache in DMT_Passport_Selector: riskLineTermsByLine static map, getRiskLineTermsByLines(Set<Id>, riskTypes) one query all risk types, both getRiskLineTerm overloads filter in memory (non-Id String -> empty), @TestVisible clearRiskLineTermCache; validationRenovation loads line+parent in one call. (b) bug fix DMT_Passport_Helper.parentConsumsStandard: getRiskLineTerm(DMT_Parent_Line__r.Line_Id__c external id -> always 0 rows) -> DMT_Parent_Line__c; productParent 03 endDateParent was parent Start+0, now Start + max parent Derivatives End Term (real: PASSPORT-6409 line a5uKE000000GwNKYA0, parent start 2027-06-01, max 16425 -> 2072-05-20). Measured Treasury Calculate with parent: DMT_Risk_Line_Term__c queries 4 -> 1 (validationRenovation 2->1, parentConsums 1->0, checkValidations 1->0); without parent 1 -> 1. Tests: DMT_LineFeatureGenCons_Calc_test.riskLineTermCacheTest, DMT_Passport_Helper_test.testSetPayloadPassport_treasuryParentConsumsDerivativesEndDate (+5 System.assertEquals -> Assert in Helper test). Factory generateTestTreasuryLines never links the parent (lineTest.Id null when building lineTest2) -> tests set it with update. Deploy 0AfgN000003OwAnSAK Succeeded 229/229. DMT_LinesBulkActionControllerTest.testGetModifyPayloadAndSaveModifiedLinesGuards fails in org already (NPE DMT_Line_Helper.createConsolidatedLine L366) - not ours. Browser: PASSPORT-6409, 6477, 6566 recalculated OK. Manifest + DMT_Passport_Helper, DMT_Passport_Helper_test. 2026-10-27 evening (user: fix all anti-patterns): getLine passed through (Helper.calculateFeatureGenCons(DMT_Line__c) -> Calc.checkValidations(DMT_Line__c) overload, old String one delegates; isCurrentLine uses line; validationRenovationOtherLines(DMT_Line__c) overload + private core, no getLine in loop, getLine selects DMT_Parent_Line__r.Amount__c); Selector caches productLineItemsByLine (getProductLineItemsByLines, 200 per line) + riskLineTermsWithoutRiskTypeByLine (getRiskLineTermWhithoutRiskTypeByLines); clearRiskLineTermCache renamed clearTransactionCache (clears 3). Tests: productLineItemCacheTest, validationRenovationOtherLinesWithLineTest, clearTransactionCache in 2 existing tests that change data mid-test, DMT_Parent_Line__c added to 2 isCurrentLine test queries. Deploy 0AfgN000003Oz3qSAC Succeeded 231/231, org == local. SOQL per payload (read-only build): Treasury with parent 31 -> 24 (line 3->1, LPI 3->1, risk 4->1); OtherProducts with parent and 1 risk term 24 -> 19 (line 4->1, risk without type 3->1; old loop +2 per extra term); Treasury no parent saves 2 (line 3->1). Browser: PASSPORT-6409, 6477, 6566, 5992 (Opp) recalculated, saved rows identical to before (0 differences); PASSPORT-5587 (OtherProducts with parent) same 4 rows on screen (4613-otherproducts-unchanged.png). 2026-10-29: marker audit (scratchpad audit_markers.py, baselines r1/r2/r19/git HEAD vs fresh org r23): all hunks marked except deletion-only lines (explained) and SOQL lines (comment above query); added 2 block comments in validationRenovationOtherLines private method, redeployed DMT_LineFeatureGenCons_Calc 0AfgN000003QEQbSAO Succeeded 96/96, org == local. User retrieves on the other computer: must re-retrieve DMT_LineFeatureGenCons_Calc. Labels given as exact XML. Waiting for user to confirm staging; THEN give commit message + note (drafts from earlier turn still valid; note must mention nothing about markers).

## Status
Deployed + verified in browser. Not committed. Next: user tests; then commit message + ticket note.
