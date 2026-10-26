---
name: cibglobald-4726
description: "Tooltip with products[].opportunityValidation.conditionDesc on the RED traffic light of the 'Line Engine - Asset Allocation' feature (Ready to Close); investigation done, questions asked"
metadata:
  node_type: memory
  type: project
  originSessionId: 05e188e5-86f2-4aa0-8cb8-cda85d05edb0
  modified: 2026-10-23T12:53:13.071Z
---

**Ticket:** CIBGLOBALD-4726 (Jira branch feature/CIBGLOBALD-4726-dmt-mostrar-tooltip-de-validaciones-en-feature-de-asset-allocation-ready-to). Personal repo branch `4726` (from main, 2026-10-23). Ticket folder: `DMT/tickets/CIBGLOBALD-4726/`.

**Ask:** feature with `motorDesc = 'Line Engine - Asset Allocation'` (Ready to Close): when its traffic light is RED, hover shows `products[].opportunityValidation.conditionDesc` from the Passport JSON (`Passport__c.DMT_Passport_Save__c`, root `data.features[]`). Dynamic (no hardcoded text), refresh on recalculation, no empty tooltip, do not rely on products[0] only. Informative only; other features unchanged.

**Findings (2026-10-23, all retrieved fresh from DMT_TCM_DEV, no diff vs git):**
- Opportunity: `dmt_passport_opportunity.js` `setFeatureProperties(feature)` (~L617) enriches every feature from the full JSON (products available). Ready to Close features (`passportSanction = readytoclose`) render through `c-dmt_feature_with_workflow` with `isreadytoclose`; capability traffic light is `c-dmt_traffic_light status={feature.stateName}` (3 variants, html L12-41). Note filterListByField is exact match, so motorDesc 'Line Engine - Asset Allocation' never falls into lineEngineFeatures.
- Line: `dmt_passport.js` `buildWrapperList` (~L535) copies only selected fields (NO products) -> must add products (or a derived tooltip field). Rendered by `dmt_passport_child.html` L50 traffic light.
- `dmt_traffic_light` already has `@api tooltipmessage` with hover popover (`.dmt-tooltip:hover .dmt-tooltip-message` in static resource DMT_Styles.css L74-80). Only other user: cfSummaryTreasury_Flexcard_76_BBVA. Popover is single-line, absolute top:-35px; long text may need CSS.
- Test data: DMT_TCM_DEV (400 latest) has only 1 feature with that motorDesc (GREEN, approval, no conditionDesc); DMTPRE2 (1000 latest, read-only) 1 hit, GREEN passport, no products. Line Engine readytoclose 'OP14 - OPTIONAL' has opportunityValidation.conditionDesc = 'Authorized risk amount' (so the shape exists).
- Unrelated: working tree showed uncommitted edits in DES_CoreDocuments.cls / DMT_CoreDocuments_Controller.cls (likely CIBGLOBALD-4760 work from another session). Not ours, not touched.

**User decisions (2026-10-23):** both Line and Opportunity; all products (dedupe); split on ', ' one reason per line; may create/edit DEV test records. User thought 'yellow or red' but ticket says RED only -> implemented RED only (told user; yellow = one-line change).
- CoreDocuments classes matched org -> committed as org-align b846944f on branch 4726 (user OK).

**Implemented (local, dry-run Succeeded 5/5, NOT deployed yet, waiting user OK):**
- `dmt_passport_opportunity.js`: const ASSET_ALLOCATION_ENGINE_FEATURE, `feature.trafficLightTooltip = this.getAssetAllocationTooltip(feature)` in setFeatureProperties, new method getAssetAllocationTooltip.
- `dmt_feature_with_workflow.html`: tooltipmessage={feature.trafficLightTooltip} on the 3 capability lights (L12-41).
- `dmt_passport.js`: same const + method; buildWrapperList adds trafficLightTooltip.
- `dmt_passport_child.html` L50: tooltipmessage on capability light.
- `dmt_traffic_light.html`: popover body style white-space: pre-line (shared with cfSummaryTreasury_Flexcard_76_BBVA; no visual change for single-line text).
- Manifest `DMT/tickets/CIBGLOBALD-4726/CIBGLOBALD-4726-package.xml` (5 LWC bundles, order arbitrary).

**DEV test data (DMT_Passport_Save__c patched via REST, backups in session scratchpad j8f_backup.json / jAH_backup.json):**
- Opp 'Opportunity TEST 22102026 v3' 006gN000009egxpQAA (Ready to close), Passport a6UgN0000003j8fUAA, feature[2] 'OP14 - OPTIONAL' -> motorDesc AA, RED, 2 products with conditionDesc (one repeated reason).
- Line 'Approval EUROVIA MANAGEMENT ESPAÑA S.L. 2026' a5uKE000000GtNvYAK (Ready to close), Passport a6UKE000000KzZq2AK, feature[0] 'OL03 - Limit Test (Group Level)' -> motorDesc AA, RED, 2 products added.
- Line passports in DEV never have readytoclose features nor products (opportunityValidation seems Opportunity-only).
- Open visual risk: popover position absolute top:-35px is tuned for one line; check multi-line in browser after deploy.

**2026-10-23 deploy 1:** 5 bundles deployed to DMT_TCM_DEV (0AfgN000003N5N3SAK, Succeeded 5/5, org retrieve == local). Browser: content correct on Opp and Line (dedupe OK), but popover narrow (~87px: containing block is the positioned TD, left:25px), grows downwards and is clipped by the passport scroll area; faded row (isFaded, opacity 0.4) fades it too (pre-existing).
- Fix (local, NOT deployed, waiting user OK): dmt_traffic_light new @api tooltipposition; 'above' -> popover bottom:calc(50% + 1.25rem), left:1.5rem, width:max-content, max-width:20rem; default keeps top:-35px;left:25px (Treasury flexcard). Parents pass tooltipposition="above" (3x feature_with_workflow, 1x passport_child). Anchor must stay the TD (slds-truncate overflow hidden would clip an inner anchor).
- Line test moved: Passport a6UKE000000KzZq2AK feature[0] restored from backup; feature[1] 'Document Loads' now AA + RED + 2 products (OL03 shows pre-existing capability warning icon, capabilityIsValid false from DMT_Rules_Feature.getAllsValidate).

**2026-10-23 later:** user wanted the tooltip NOT faded on faded rows -> dmt_feature_with_workflow.css `.faded-row > td:not(.dmt-capability-cell) {opacity:0.4}` + capability cell border rgba(201,201,201,0.4); capability td class dmt-capability-cell; lights get faded={feature.isFaded}; dmt_traffic_light @api faded (opacity on lights container only); tooltip 'above' style now left:0, max-width:13rem. All deployed to DMT_TCM_DEV (Succeeded), org == local (CSS differs only by EOF newline). User said: just deploy to DEV, don't stop to ask on each redeploy in this ticket.
- Browser verified: Opp tooltip (4 reasons, dedupe), Line tooltip, other features no tooltip, live update after JSON change (no reload), no conditionDesc -> no popover in DOM. Opp test data restored to full 2-product state (j8f_patch.json).
- Evidence (DEV, provisional, replace with DMTPRE2 set): DMT/tickets/CIBGLOBALD-4726/4726-opp-tooltip.png, 4726-opp-tooltip-updated.png, 4726-opp-no-reasons-no-tooltip.png, 4726-other-features-no-tooltip.png, 4726-line-tooltip.png.
- Pending: commit (needs user OK), commit message + ticket note, DMTPRE2 evidence after release.
- 2026-10-26: org still == local, test Passports intact. Ticket note written: DMT/tickets/CIBGLOBALD-4726/CIBGLOBALD-4726-ticket-note.txt. Commit message in CIBGLOBALD-4726-commit-message.txt. Not committed yet.
- 2026-10-26: ticket note finalized (no cache tip, no evidence list). Committed on branch 4726, pushed, merged to main (user OK). Remaining: DMTPRE2 evidence after release (replace DEV PNGs, give user the paths as links).
