---
name: cibglobald-4713
description: "Add Download (PDF) button to the Passport Profitability modal of Opportunity, reusing NBC view rendering + DMT_PdfService; investigation stage, questions pending for user"
metadata:
  node_type: memory
  type: project
  originSessionId: 94e1ab34-09b1-40f0-92cb-05829be712d4
  modified: 2026-10-20T09:11:37.892Z
---

**Ticket (2026-10-20):** feature/CIBGLOBALD-4713-dmt-anadir-boton-para-descargar-el-modal-de-profitability-en-pdf. New `Download` button (download icon) in the header of the Opportunity Passport Profitability modal; downloads a PDF of what the modal shows, reusing the NBC view components/PDF mechanism. No recalculation, no empty PDF when there is no profitability data, tables must not break across pages (multi product / underlying).

**Git state:** branch `4713` (pushed). Before it: committed leftover CIBGLOBALD-4117 work on main (dd1edae8) and an 'Org align' commit with fresh retrieves of the components below.

## Findings (org DMT_TCM_DEV retrieved 2026-10-20)
- Passport row `dmt_feature_profitability` (openModal) opens `dmt_passport_modal` (LightningModal, footer has only Close; header is lightning-modal-header label=featureName) with `showProfitabilityChart=true`, `profitability=feature.profitability`, `opportunityId`. Modal body = `c-dmt_profitability_chart` (804-line JS, 239-line HTML; has @api `getChartImage(width,height)`, @api `profitability`, `opportunityId`, `hidden`). Chart calls Apex `DMT_Profitability_utils` (getProductDetailsByIds, getNominalAmounts..., convertNominalsToOppCurrency, getRwaRegLinkInfo, getUnderlyingDetailsByIds) and `callExternalOrchestrators(oppId)` (service DMTO_ExternalOrchestrators) - need to check when/why that callout fires (no-recalc requirement).
- NBC view: `dmt_open_view_nbc` -> `dmt_screen_view_management`; `dmt_view_lwc` renders items via `DMT_ViewController.loadComponentsForView`, and has the PDF flow: `handleDownloadPDF` -> `generatePdf(htmlForPdf)` -> `DMT_PdfService.preparePdfAssets` (persist inline base64 images) -> `DMT_PdfService.generateFinalPdf(finalHtml, docIds, isMobile)` -> blob download (desktop) or shepherd servlet (mobile). VF page `DMT_ViewPDF` (renderAs PDF, controller DMT_ViewController). Another unrelated PDF stack: LWC `pdfGenerator` (jsPDF).
- NBC profitability items (DMT_RendererFactory): 'Profitability' (DMT_ProfitabilityRenderer -> DMT_OppProfitabilityRenderer, server HTML: sections Profitability Engine, Summary, Regulatory Capital, Economic Capital, formatters 'like modal'), 'Profitability Summaries' (DMT_ProfitabilitySummariesRenderer), 'Profitability Visual' (DMT_ProfitabilityVisualRenderer; chart image is generated client-side by dmt_view_lwc.getImageB64 using hidden `c-dmt_profitability_chart`, passed to the renderer as imageData). `DMT_NBC_ProfitabilityHelper` reads featuresList.
- NBC data source = `DMT_ViewController.getFeatures(id)` = saved JSON `Passport__c.DMT_Passport_Save__c` (featuresList, key `profitability.results`). Modal data = in-memory `feature.profitability` from Passport. Whether these are identical = open question.

## KEY FINDING 2026-10-20 (user alarmed, rightly)
Modal (LWC template dmt_profitability_chart.html + JS processProfitabilityData) and NBC renderer (Apex DMT_OppProfitabilityRenderer) are TWO SEPARATE implementations and ALREADY DIFFER (code comparison, not yet browser-tested): Summary last col 'Incomes 12 months' (modal) vs 'Net Income' (renderer); modal Regulatory has NetIncome Reg + optional External RWA 1Y column, renderer has neither; modal Economic has NetIncome Eco, renderer has none + extra 'RAROEC CDD'; modal header uses > / < comparison, renderer formatProfitabilityMetric; chart = Chart.js canvas vs image/server chart. User wants ONE source of truth: modal must display the renderer HTML, PDF = same HTML. Browser test idea from user: Configuration > Views (screen view management) > new view > select renderer > external id ESCD26OPP00004148ES; dmt_view_lwc embeds it; Download PDF there.
Modal entry points with showProfitabilityChart=true: dmt_feature_profitability:70, dmt_feature_with_workflow:185, dmt_passport:930. Button goes in dmt_passport_modal footer (brand, right of Close), future-proof via actions array. Ticket said header; deviation to mention in note.

## Open questions asked to user (pending)
see chat 2026-10-20 (which version is correct where they differ; ok to change NBC output; browser test).

## Pending
Plan not drafted yet. Nothing edited yet beyond org-align retrieve.

## Update 2026-10-20 (later)
Full context doc: tickets/CIBGLOBALD-4713/CIBGLOBALD-4713-context.md (committed, branch 4713). Browser test done on Configuration > Views > 'Profitability view' with opp ESCD26OPP00004148ES (Download PDF works, opens blob tab; PDF pages not inspected, extension cannot read blob tabs). KEY: Jorge Andres Florentin Escurra edited DMT_OppProfitabilityRenderer + DMT_ProfitabilityChartGenerator in DMT_TCM_DEV today 10:37 UTC (same direction): coordinate with him/Diego. Remaining diffs: Tenor empty (renderer reads 'tenor', data has 'term'), 'y' suffix, sci-notation small amounts, notional '—' vs '0,00', extra RAROEC CDD, External RWA column/button, chart. Plan not drafted; user decisions recorded in context doc.

## 2026-10-20 evening: IMPLEMENTATION AUTHORIZED (retrieve, update, deploy to DMT_TCM_DEV, no switch)
Plan: tickets/CIBGLOBALD-4713/CIBGLOBALD-4713-plan.md (approved). Baseline modal screenshots from user: scratchpad images/3.png and 4.png.
Scope now = architecture (light method in DMT_Profitability_utils, shared preload helper, renderer image fix + RWA column + silent marker + table-block hooks, thin LWC dmt_profitability_view in dmt_passport_modal, footer Download PDF). Formatting parity is a LATER pass.
NOT YET MIGRATED to the renderer/PDF (formatting follow-up list, vs modal):
- Tenor empty (renderer reads 'tenor', data key 'term').
- Average Life / Tenor 'y' suffix (modal 2.91y, renderer 2,91).
- Small amounts: modal sci notation (-4.47e-4 EUR, formatAmountWithCurrencyMax2), renderer 0,00 EUR (NetIncome Reg/Eco, Incomes 12 months, FD).
- Notional Drawn/Undrawn product/underlying rows: modal '—', renderer '0,00 EUR'.
- Economic table: renderer extra 'RAROEC CDD' column.
- Underlying order by orderIndex (modal since 2026-10-19), renderer not.
- ID column: modal truncates opp name ('Opportunity IBERDROLA I...'), renderer wraps.
- PDF: ID cell indent overlaps next column; tables split without repeated header; forced page break before chart; 6px fonts.

## 2026-10-20 ~19:00: DEPLOYED to DMT_TCM_DEV (deploy 0AfgN000003KsnKSAS Succeeded, 128/128; LWC redeploy 0AfgN000003KwxNSAS)
Commits on main: 1482abb6 (implementation), next (portrait PDF). Rollback copy: tickets/CIBGLOBALD-4713/rollback/2026-10-20 (baseline dacc17cf).
Components: DMT_ViewController (wrapper fields + preload via helper), DMT_Profitability_utils (without sharing, renderProfitabilityHtml, preloadProfitabilityData, parseAprsCalculation), DMT_OppProfitabilityRenderer (image size()>0, table-block hooks, RWA marker, External RWA 1Y column), DMT_Test_DataFactory (generatePassport; Jimmy's Past2_FY_Corp_Synd_Lending_amount__c line commented again, user OK), tests (DMT_Profitability_utilsTest, DMT_ProfitabilityRendererTest, DMT_ViewController_Test: testOppProductsRenderer_renderHtml_oneOff_oldMoneyUsesCalculatedValue commented out, unrelated renderer, user OK), LWC dmt_profitability_view (new), dmt_passport_modal. Manifest manifest/CIBGLOBALD-4713-package.xml.
Browser verified (opp 006KE000003Qx30YAC): modal shows renderer HTML, per-table scroll, RWA button in place, footer Close + Download PDF; PDF generated (no button, browser chart image, 2 pages portrait). RWA click: service 400 'APRS SIN TITULAR GUARANTE' for this opp -> red alert, no column (column path only unit-tested).
Follow-ups: formatting list above; landscape PDF needs DMT_BlobBuilderForPDF option (body <style> printed as text); chart labels small in modal; modal narrower than original; RWA error could show the service functional message; tell Jimmy about factory line and renderer owner about the commented VC test.

## 2026-10-21/22: parity pass + wrap-up
User committed the first work-repo commit (message in tickets/CIBGLOBALD-4713/CIBGLOBALD-4713-commit-message.txt). Second commit = parity pass: DMT_OppProfitabilityRenderer (rows/order/nominals/formats identical to the former modal, no RAROEC CDD, ID break in PDF, data-dmt-row), DMT_ProfitabilityRendererTest (new formats test), dmt_profitability_view (modal screen styles, chart at modal width). Message: CIBGLOBALD-4713-commit-message-2.txt; manifest/CIBGLOBALD-4713-package.xml now lists only these 3. Ticket note rewritten complete, no pending section.
Deploys: renderer+LWC 0AfgN000003LhJZSA0 (NoTestRun, factory was invalid from Jimmy's refactor), then factory (generatePassport re-added on Jimmy's 16:22 version, Past2 line commented again in org only) + renderer test 0AfgN000003LheXSAS Succeeded 28/28; test run 30/30, coverage renderer 91%, utils 90%.
Data parity verified via anonymous Apex render of 006KE000003Qx30YAC vs user's original screenshots (all values match). Visual check of the new styles NOT done (browser session expired, needs user login). Modal width never changed (earlier claim was a DPI comparison mistake).
External RWA service failing 2026-10-22: no code of ours touched the callout after the first commit (DMT_Profitability_utils unchanged since 1482abb6).

## 2026-10-22: chart cleanup + final checks
dmt_profitability_chart: tables/data/formats/RWA commented out (not deleted) with pointer to DMT_OppProfitabilityRenderer; only image generator now (users: dmt_profitability_view, dmt_view_lwc, dmt_CreateHTMLAndJSONForTask, dmt_massive_snapshot_worker, pdfGenerator; all only call getChartImage). getChartImage(width, height, unusedParams, fixedSize): fixedSize -> responsive false (devicePixelRatio option did not scale fonts, removed). Luis Miguel's 10-19 change (underlying orderIndex) lives in the renderer now. dmt_profitability_modal: no references (dependency API + 161 FlexiPages scanned) -> USER deletes it in the work repo; mentioned in commit message 2 + note.
Lightning persistent cache: after LWC deploys, ctrl+shift+r needed to see the new version.
Visual check done with user logged in: modal matches original (tables, formats, chart label size); final PDF checked (all values match, no ID overlap, chart page 2). Package (second commit): DMT_OppProfitabilityRenderer, DMT_ProfitabilityRendererTest, dmt_profitability_chart, dmt_profitability_view.
