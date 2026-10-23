---
name: cibglobald-3981
description: Bugfix 2026-10-23 - Client Profitability fields with >2 decimals (inferred from Account) break step 0.01; fixed LWC-only via maxDecimals in dmt_form_renderer; deployed + browser-tested
metadata:
  node_type: memory
  type: project
  originSessionId: e2385a98-eb47-4cbf-bdff-1658ff182033
  modified: 2026-10-23T10:12:39.335Z
---

**Ticket:** CIBGLOBALD-3981 (original feature: DMT_OpportunityClientTriggerHelper.syncInferredAccountGroupFields copies Account DES_RORC_NBC__c / DES_RORC_YTD__c / DES_RWA_Last12m__c / DES_BDI_Last12m__c into DMT_Opportunity_Client__c on insert). Bugfix 2026-10-23.

**Bug:** Account values hold 4 decimals (API loads, e.g. 19.2512) although fields are scale 2; copied as is. Client Profitability tab (dmt_opp_tab > Approval Process Data > dmt_opp_approval_details > dmt_section_simple_form > dmt_form_renderer, numberWithSuffix lightning-input step 0.01) showed 'Your entry isn't a valid increment.' and blocked Save.

**Decision (user, 2026-10-23):** trigger keeps EXACT Account values (no Apex change; an Apex rounding draft was reverted to org version). Fix only in LWC: display rounded to 2 decimals, typing limited to 2 decimals, on the 4 inferred fields.

**Done, deployed to DMT_TCM_DEV 2026-10-23 10:07 UTC (Status Succeeded, org == local), branch 3981:**
- lwc/dmt_form_renderer/dmt_form_renderer.js: opt-in field prop `maxDecimals`; _enrichField uses new _roundToMaxDecimals (display only, HALF_UP); new _limitTypedDecimals called in handleFieldInput and handleFieldChange (change fires before input).
- lwc/dmt_opp_approval_details/dmt_approval_client_profitability_fields.js: `maxDecimals: 2` on DMT_Clients_Global_RORC_CIB_Past_FY__c, DMT_Client_RORC_YTD__c, DMT_Client_Net_Incomes__c, DMT_Client_RWA__c.
- Manifest DMT/tickets/CIBGLOBALD-3981/CIBGLOBALD-3981-package.xml.
- Browser test (Opp 006gN000009gndSQAQ, client YTD 19.2512): view 19,25 %; edit 19,25 valid; typed 12,3456 -> 12,34; entering edit + Cancel shows no unsaved dialog (rounding does not dirty); record still 19.2512.

**Org drift (not ours) in retrieved files:** dmt_form_renderer.js (~75 lines others), dmt_form_renderer.html (org lacks CIBGLOBALD-3779 isFractionPercent block that git has), dmt_approval_process_data.*, dmt_opp_approval_details.html/.js, dmt_approval_deal_main_fields.js.

**Status 2026-10-23:** user pushed to the work repo; commit message and ticket note (DMT/tickets/CIBGLOBALD-3981/) delivered; personal repo committed on branch 3981 and merged to main. Ticket done.
