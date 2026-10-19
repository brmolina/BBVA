---
name: cibglobald-4630
description: "Preload Guarantor data (scoring, ratings, political/commercial risk) from HPG service when a Guarantor is selected in the Opportunity product modal (One-Off Deal and Line); research stage"
metadata:
  node_type: memory
  type: project
  originSessionId: eb35ce4e-2d3b-473c-9de7-c6c1d36b558e
  modified: 2026-10-15T16:31:44.947Z
---

# CIBGLOBALD-4630 - Guarantor data preload from HPG

Started 2026-10-15. Branch name in team repo: feature/CIBGLOBALD-4630-dmt-precarga-de-datos-de-guarantor-desde-servicio-hpg. Local personal branch convention: `4630` (session started while checked out on `4374` with uncommitted 4374 work).

## Requirement (pasted by user)
- In the Guarantor modal of Opportunity products (both One-Off Deal and Line), when the user SELECTS a Guarantor (not on modal open), call the HPG service with the Guarantor identifier and preload all fields available in the modal.
- Minimum mapping to review: Scoring, Internal Rating, External Rating, Political Risk, Commercial Risk. Political/Commercial Risk: first verify whether HPG actually returns them.
- Other HPG fields that already exist in the modal: review mapping too.
- Never invent/default values when HPG returns nothing.
- Changing Guarantor: re-query HPG, update fields, do not keep previous Guarantor values; handle empty response and call failure gracefully.
- Common logic for One-Off Deal and Line.
- QA: select guarantor in One-Off and Line, ratings/scoring preload; change guarantor clears old data; guarantor without HPG data does not break modal; save persists preloaded data.

## Starting hints from user
Start from dmt_opp_tab LWC -> child product LWC -> find which table is the Guarantor one. User does not know the ticket background; ask/relay questions.

## Research findings (2026-10-15, org DMT_TCM_DEV retrieved dmt_opp* LWCs, no local changes)
- Modal: lwc/dmt_opp_product_modal_guarantor (js/html/_fields.js), a LightningModal built on c-dmt_form_renderer; handleFieldChange(event.detail {fieldId,value}) is the hook. Saves to DMT_Opportunity_Mitigant__c via createRecord/updateRecord (no Apex).
- Opened from lwc/dmt_opp_product_table_unfunded_mitigants (_openGuarantorModal, 'Guarantors' table). That table is embedded by BOTH dmt_opp_product_details (One-Off) and dmt_opp_product_details_line (Line) -> single modal serves both, so logic is already common.
- Modal fields -> mitigant fields: DMT_Guarantor_Account__c (customLookup Account, filter g_customer_id__c LIKE entity), Counterpart__c, Commercial_Percentage__c (number, required, default 0), Political_Percentage__c (number, required, default 0), Internal_Rating__c (picklist, catalog C204), DMT_Scoring__c (number), External_Rating__c (picklist, catalog C009), DMT_Currency__c, End_Date__c, DMT_Country_Guarantor__c, SCRA__c, European_Bank_Check__c, AVC_Check__c.
- Existing HPG pattern: DMT_HPG_Utils.getCustomerHPGS(inputMap{clientId,customerId,lastDate}) -> DMT_HPG_GlobalPosition.Data (used by DMT_CreateOpportunityService and DMT_OpportunityClientController). Mapping precedent: totalRatingScoreNumber -> DMT_Scoring__c (scale 2), updLmsclInternalRatgType -> internal rating (validated against DMT_Taxonomy_Values__c catalog C204 via resolveRatingValueIfExists), unifiedExtRatgLtFcType -> External_Rating__c.
- DMT_HPG_GlobalPosition.Data has NO political/commercial risk field (grep) -> likely not returned by this service; to confirm.
- getCustomerHPGS requires clientId (opportunity client account Id) + customerId (g_customer_id__c of the guarantor) and fetches whole client position table (heavy, 4000 rows) then filters by customerId.

## User decisions (2026-10-15)
- If HPG returns nothing/fails/property missing: required fields stay required and empty for user to fill; optional fields stay blank. No defaults (so Political/Commercial must not default to 0 after a guarantor pick).
- Keep using the existing HPG service (DMT_HPG_GlobalPosition); no skinny alternative exists in custom metadata.
- Scope limited to the ticket's five fields. No test guarantors known. External rating mapping question sent to tech lead (Spanish snippet).

## Skinny call found
- Passport LWC (dmt_passport_opportunity.js ~L972) calls DMT_HPG_MainTableCustomController.fetchClientInitialData with clientId=null, customerId=<Account Id>, 'N', page 1, size 100 -> fetchClientDataFromServiceLine -> getAlphaCode(Account.g_customer_id__c) -> payload customerId (no pagination) -> one customer only. This is the single-customer call to reuse for guarantors (guarantor Account Id as customerId).
- getCustomerHPGS (clientId + customerId) instead resolves the whole group and filters; heavier.
- Only HPG integration services in metadata: DMT_HPG_GlobalPosition, ConnectedCustomers, GroupPositions, HierarchyPositions, UsedTables, Consumption, CapitalProvision; none lighter for ratings.

## Live probe (2026-10-15, anonymous Apex read-only in DMT_TCM_DEV, user-authorized)
- fetchClientInitialData(clientId=null, customerId=<Account Id>, 'N', 1, 100) works: success=true, exactly 1 row. Raw request payload: {clientPositionsType:'', searchDate, clientDataOption:'D', customerId:<g_customer_id__c>}.
- Tested Accounts 001KE000008FSe6YAG (GRIFOLS VIAJES, ES0182011178580) and 001KE000008FSe4YAG (FUNDACIO PRIVADA VICTOR GRIFOLS, ES0182030065512). Both returned totalRatingScoreNumber (8.66 / 7.16) and updLmsclInternalRatgType (B-2 / BB1), also updSmsclInternalRatgType.
- Neither returned any external rating (unifiedExtRatgLtFcType, S&P, Moody's, Fitch all absent) -> External Rating must stay blank for them.
- Raw JSON has NO political/commercial risk property at all (checked the raw response, not just the wrapper). Raw also has participationPercentage (100.0), sovereignCustomerType, padminMarkIndType (not in the modal).
- Existing mitigants in DMT_TCM_DEV for these accounts have manually typed values (Internal AA+, Scoring 4/12, External AAA) that do NOT match HPG (B-2/8.66), so preload would change what users see. Internal rating value from HPG (e.g. B-2, BB1) must exist in catalog C204 to be set.

## Live probe 2 - group call getCustomerHPGS (2026-10-15)
- Pairs: opp client accounts 001KE000008FVCcYAO (group G20100127223919) and 001KE000008FSdRYAW (group G00000000000200) with the two Grifols guarantors (group G00000000000171). Result: 'Customer not found in HPG Service' for all 3 pairs; the call sent groupId of the client, pageSize 4000.
- Conclusion: getCustomerHPGS only finds customers inside the opportunity client's group, so it cannot be used for Guarantors (typically outside the group). Use the single-customer call (customerId only).

## Catalog check (2026-10-15)
- C204 (internal rating) has 38 active values, long-scale ones included (B-2, BB1, AA+...). HPG updLmsclInternalRatgType values seen (B-2, BB1) exist in C204 -> mapping valid; still validate against catalog and leave blank if absent. C009 (external) has 26 active values.
- Client tab already maps unifiedExtRatgLtFcType -> External_Rating__c (precedent for guarantor).
- Remaining for tech lead: (1) confirm External Rating = unifiedExtRatgLtFcType like client tab; (2) confirm Political/Commercial are not returned and stay manual.

## Implemented + deployed (2026-10-15, branch 4630, DMT_TCM_DEV, RunSpecifiedTests DMT_OpportunityProductsControllerTest 64/64)
- DMT_OpportunityProductsController: new @AuraEnabled getGuarantorHpgData(Id guarantorAccountId) + private resolveActiveCatalogValue (C204/C009 validation). Returns {success, found, scoring, internalRating, externalRating, message}; never throws. PENDING comment marks External Rating property (unifiedExtRatgLtFcType, awaiting tech lead).
- dmt_opp_product_modal_guarantor (js/html): on guarantor change clears Scoring/Internal/External, calls Apex, fills what HPG returns; stale-response guard; warning toast when not found/failed. Political/Commercial untouched (HPG does not return them).
- DMT_Test_DataFactory: added generateTaxonomyValue(catalog, value). DMT_OpportunityProductsControllerTest: 5 new tests + System.assert* -> Assert.* rename (135, verified).
- manifest/package.xml: the 3 classes + the LWC bundle. The deployed LWC bundle also carries other devs' org changes (Mitigant_Type E895 catalog, dmt_mitigant_utils) because retrieve was fresh.
- Test gotcha: Account.DES_Group_Code__c and g_customer_id__c are unique; factory default group code collides with @TestSetup account.
- Not yet done: user QA in UI; commit (needs user go-ahead); ticket folder tickets/CIBGLOBALD-4630.

## Browser test (2026-10-15, Chrome, DMT_TCM_DEV, Opp 006KE000003QulXYAS 'Opportunity clone from Iber Inmo...' Products tab -> Guarantors +)
- Modal opens empty, lookup lists GRIFOLS VIAJES S.A.; on select the warning toast 'HPG data not available' appeared, fields stayed blank (failure path works).
- Cause is environmental: HPG service DMT_HPG_GetUsedTables answered 'Not found' (checked 3 times over minutes) -> DMT_HPG_Utils.lastDate() NPE (line 543, no data[0]). Same root cause as the 'Error processing passport: null object' toast on the page. Success path NOT yet seen in browser; Apex-level proof exists from the earlier probes (service worked ~10:05).
- Nothing was saved; modal cancelled.

## Wrap-up state (2026-10-15 ~12:00 local)
- User confirmed in browser: Scoring 8,66 + Internal Rating B-2 preload for GRIFOLS VIAJES, clear on guarantor clear, other value on another guarantor (One-off).
- Political/Commercial now default blank (fields.js value ''), deployed. Exceptions via DMT_LogExceptionPayload + flush. Comments: External Rating = same property as client (DMT_CreateOpportunityService, DMT_OpportunityClientController, LWC dmt_opp_client); Political/Commercial unknown/not returned; callout technical info in the method doc.
- Deployed final version to DMT_TCM_DEV (64/64, RunSpecifiedTests). Org == local for the 4 components (checked 3x).
- Line product browser test (Opp 006KE000003Que3YAC VOLKSWAGEN businessplan, Line): modal opens with blank risk fields, but guarantor lookup returned no results twice -> stopped, not a verdict on the feature. Save/reopen and no-HPG-data guarantor NOT tested in browser.
- Global CLAUDE.md updated with reusable rules (standing deploy OK, compare org before deploy, exception payload, callout comments, ticket technical note in Spanish with SF terms in English, no pleasantries).
- Pending: commit message (needs user go-ahead), ticket technical note (Spanish), QA by user, tech lead reply optional now.

## HANDOVER (2026-10-15 evening) - ticket considered finished
- Full handover, commit message and Spanish ticket note live in `D:\AI\brmolina-BBVA\tickets\CIBGLOBALD-4630\` (CIBGLOBALD-4630-HANDOVER.md, -commit-message.txt, -nota-tecnica-ticket.txt). Read HANDOVER first.
- Added after the earlier notes: DMT_Passport_Selector overload getTaxonomyValuesByValueAndCatalog(value, catalog, System.AccessLevel) (lines 325-335); Account read and taxonomy validation in SYSTEM_MODE; manifest has 5 components.
- Org check: all components identical to local; factory in org is Jimmy's 15:06 UTC version and contains generateTaxonomyValue. User deployed controller + selector by hand (my deploy ended Status: Failed on the 75% coverage gate of DMT_Passport_Selector with RunSpecifiedTests).
- Still not committed (needs user go-ahead). User will do wrap-up (review staged, commit) in another session.

## Status
- Research done; waiting on tech lead answer about External Rating field.

## Components touched
(none yet)
