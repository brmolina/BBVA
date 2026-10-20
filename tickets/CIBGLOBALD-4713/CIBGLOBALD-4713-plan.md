# CIBGLOBALD-4713 - Plan (draft 2026-10-20)

Goal: the Profitability modal (Passport of Opportunity) shows the HTML built by the Profitability renderer, so the screen, the NBC views and the PDF come from one implementation. A Download PDF button in the modal footer downloads exactly what is on screen.

Context and findings: `CIBGLOBALD-4713-context.md`.

## Agreed design
- Modal: keep `dmt_passport_modal` (3 callers: dmt_feature_profitability, dmt_feature_with_workflow, dmt_passport). In profitability mode its body becomes a new thin LWC; Download PDF goes in the footer.
- Data: saved Passport JSON (same as today). Opportunity from `DMT_View_Selector.getOpportunityWithRelatedData` (same query as the ViewController). No new queries.
- Apex entry: a new method in `DMT_Profitability_utils` builds only what the renderer reads and calls `DMT_RendererFactory.getRenderer('Profitability')`.
- Chart: image generated in the front end (hidden `dmt_profitability_chart.getChartImage`) and sent to Apex; the renderer appends it. Server chart stays as the fallback (ongoing migration).
- External RWA: callout and new column in the backend. The renderer only emits a silent empty marker with a unique id where the button is today, and only when the modal asks; the modal LWC inserts the button there; the marker is removed before the PDF.
- Sizes: option A. Renderer sizes unchanged; the modal applies its own sizing on screen; the modal PDF is landscape.
- PDF generated on demand on click, from the HTML on screen (with the RWA column only if the user clicked it).

## Step 1 - Renderer parity (verify in Configuration > Views before touching the modal)

### 1.1 `DMT_OppProfitabilityRenderer` (we own it now)
1. Image branch: `itemImgBase64.size() > 7` back to `> 0` (Jorge's test value).
2. Parity with the modal, which is the source of truth:
   - Tenor reads `term` (today reads `tenor`, always empty).
   - Average Life and Tenor with the `y` suffix and 2 decimals.
   - Amount format of NetIncome Reg/Eco and Incomes 12 months like the modal (`formatAmountWithCurrencyMax2`, small values in scientific notation).
   - Notional Drawn/Undrawn: product and underlying rows show `—` when the modal does; underlying nominals summed into the product row like `buildOrderedRows`.
   - Remove 'RAROEC CDD' from Economic Capital (not in the modal).
   - Row order and dedupe like `normalizeProfitabilityResults` / `buildOrderedRows`, including the underlying order by `orderIndex` (added to the modal on 2026-10-19).
   - Header lines (Deal RORC / RAROEC lifetime with < / >) checked against the modal.
3. External RWA column (Regulatory Capital, after RWA reg): 'External RWA 1Y', value per product from the callout result, link built from `getRwaRegLinkInfo` (base URL, explanationId = DMT_Opp_Id__c + '_' + productId, country = Entific__c). Only rendered when the wrapper carries a callout result.
4. Silent marker for the button: `<span data-dmt-action="external-rwa" data-enabled="true|false"></span>` in the Regulatory Capital header, only when the wrapper asks for it (modal). Never present for View List, Configuration, case task modal, snapshots.
5. PDF readability (ticket: no cut tables, no lost information): fix the ID cell indent that overlaps the next column, `page-break-inside: avoid` on rows, header repeated on page break (`thead` as table-header-group), remove the forced page break before the chart.
6. Keep the existing inline sizes (option A).
7. Silent hook on each table wrapper (`data-dmt-table-block="summary|regulatory|economic"`) so the modal can make each table scroll on its own. Harmless for the PDF and the other entry points.

### 1.2 `DMT_ViewController`
- `LineDataWrapper`: new fields `profitabilityAprsByProductId` (Map<String, Object>), `profitabilityRwaLinkInfo` (Map<String, Object>), `profitabilityShowRwaAction` (Boolean).
- Move the profitability preload block (product details, nominal amounts, converted nominals; ~L1034-1053) to a shared helper in `DMT_Profitability_utils` and call it from here. Same behaviour for every existing view.

### 1.3 `DMT_Profitability_utils`
- Class becomes `without sharing` (agreed).
- New shared helper `preloadProfitabilityData(LineDataWrapper data)` (moved code).
- New `@AuraEnabled` method, e.g. `renderProfitabilityHtml(String oppId, String itemsImg, Boolean withExternalRwa)`:
  1. Opportunity via `DMT_View_Selector.getOpportunityWithRelatedData(oppId, 'DMT_Opportunity')`.
  2. Profitability feature from the saved Passport JSON (same source as `DMT_ViewController.getFeatures`).
  3. `preloadProfitabilityData`, image (`itemsImg`), RWA link info, `profitabilityShowRwaAction = true`.
  4. If `withExternalRwa`: one call to `callExternalOrchestrators`, parse `data.aprsCalculator[].aprCalculator`, put the map in the wrapper; callout failure returns a message and the HTML without the column.
  5. `DMT_RendererFactory.getRenderer('Profitability').renderHtml(data)`; returns JSON { html, hasData, message }.
  6. Errors logged with `DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(...))` + `flush()`.
- Doc comments name the callout technical info (service DMTO_ExternalOrchestrators, `iaso__GBL_integration_service__mdt` record, call path, CMDT `DMT_Taxonomy_Value_link__mdt`).

### 1.4 Gate
- Configuration > Views > 'Profitability view' with ESCD26OPP00004148ES, 006KE000003QvjeYAC, 006KE000003QuiYYAS: screen and Download PDF compared with the modal, row by row.

## Step 2 - Modal

### 2.1 New LWC `dmt_profitability_view` (name to confirm)
- Inputs: `opportunityId`, `profitability` (already passed to the modal).
- No `profitability.results` -> message 'No profitability data available', no Apex call, `hasData = false` to the parent.
- Lives inside `dmt_passport_modal` (body of the profitability branch).
- Per-table scroll: screen-only style on `[data-dmt-table-block]` (overflow-x auto, table at natural width with the original modal sizes), so each table scrolls like today. Not part of the PDF HTML.
- Load: spinner -> chart image from a hidden `c-dmt_profitability_chart` (`getChartImage`, same as dmt_view_lwc does today; the component stays the image generator) -> `renderProfitabilityHtml(oppId, image, false)` -> HTML into a `lwc:dom="manual"` container + modal sizing style -> find the marker and insert the 'External RWA calculate' button (brand, disabled when `data-enabled="false"`).
- RWA click: spinner, `renderProfitabilityHtml(oppId, sameImage, true)`, replace the HTML, re-insert the button; error message inline if the callout failed.
- `@api getPdfHtml()`: copy of the displayed HTML without the marker/button, plus a landscape `@page` style.
- Error state: inline message + toast; exceptions logged by Apex.

### 2.2 `dmt_passport_modal`
- Profitability branch renders `c-dmt_profitability_view` instead of `c-dmt_profitability_chart`.
- Footer: actions driven by a small list (label, icon, variant, handler, disabled) so later buttons are one entry. Profitability mode: Close (neutral) + Download PDF (brand, `utility:download`), disabled while loading, when there is no data, or while a PDF is running.
- Download PDF: `getPdfHtml()` -> `DMT_PdfService.preparePdfAssets` -> `generateFinalPdf(html, docIds)` on desktop (blob download, file name with the Opportunity name) / `generateFinalPdfMob(html, docIds, true)` on mobile (shepherd download) -> button label 'Downloading PDF...' + spinner; error toast on failure. No recalculation, no page reload.

### 2.3 Unchanged on purpose
- `dmt_profitability_chart` stays (image generator for dmt_view_lwc, snapshots, pdfGenerator); its visible tables are no longer used by the modal. Deprecation of that markup is a follow-up, not this ticket.
- `dmt_view_lwc`, `DMT_PdfService`, `DMT_ProfitabilityChartGenerator` not modified.

## Tests (Apex)
- `DMT_Profitability_utilsTest`: new method (with data, no data, with RWA via HttpCalloutMock, callout error), shared helper.
- `DMT_ProfitabilityRendererTest`: image branch, RWA column + marker present/absent, Tenor/term, row order with underlyings.
- `DMT_ViewController_Test`: preload still filled through the helper.
- Data only through `DMT_Test_DataFactory` (add generators if missing, retrieved fresh first). `System.assert*` -> `Assert.*` in every touched test file.

## Manifest (`manifest/CIBGLOBALD-4713-package.xml`, order)
1. ApexClass: DMT_Profitability_utils, DMT_ViewController, DMT_OppProfitabilityRenderer, DMT_Profitability_utilsTest, DMT_ProfitabilityRendererTest, DMT_ViewController_Test
2. LightningComponentBundle: dmt_profitability_view, dmt_passport_modal
No permission set change (no new Apex class). No CMDT change.

## Before any deploy
- Fresh retrieve and diff of every component (DMT_ViewController, dmt_view_lwc and DMT_PdfService were changed by other devs today).

## Rollback plan
What can go wrong is code only: no data, schema, CMDT or permission set changes, so there is nothing to restore in data.

Preparation (before each deploy, by the user):
1. Fresh retrieve of every component in the manifest into `tickets/CIBGLOBALD-4713/rollback/<date>/` (exact org versions right before our deploy; DMT_ViewController, DMT_PdfService and dmt_view_lwc change often).
2. Commit that folder in the personal repo; note the commit hash in `CIBGLOBALD-4713-deployment-notes.md`.
3. Deploy in two separate releases: Step 1 (Apex) first, Step 2 (LWC) only after the Configuration > Views gate passes.

Rollback Step 2 only (modal problem, NBC fine):
1. Redeploy the backed-up `dmt_passport_modal` (old body `c-dmt_profitability_chart`, footer with Close only).
2. `dmt_profitability_view` can stay deployed unused (nothing references it); remove later with `CIBGLOBALD-4713-destructiveChanges.xml` if wanted.
3. Check: modal opens with the old tables and the External RWA button works as before.

Rollback Step 1 (renderer / ViewController / utils problem):
1. If Step 2 is deployed, roll back Step 2 first (the new LWC calls `renderProfitabilityHtml`).
2. Redeploy the backed-up `DMT_Profitability_utils`, `DMT_ViewController`, `DMT_OppProfitabilityRenderer` and their three test classes together (RunSpecifiedTests with those test classes, explicit --target-org). This also restores 'with sharing' on the utils class.
3. Check: Configuration > Views 'Profitability view' and View List render; Download PDF there works; the modal works.

Optional, to decide: keep the old modal body behind a switch for one release, so Step 2 can be turned off without a deploy. Not planned by default (adds a flag to remove later).

## QA (from the ticket)
- Modal with data: tables, chart and RWA button in place; Download PDF in the footer with icon.
- PDF matches the modal; multi product + underlyings (ESCD26OPP00004148ES); no cut tables.
- RWA clicked -> column in screen and PDF; not clicked -> no column.
- No data -> message, button disabled, no empty PDF.
- No recalculation: only `callExternalOrchestrators` on the RWA click; Passport untouched.
- NBC views (View List, Configuration, case task modal) unchanged except the parity fixes; no marker, no button.

## Risks / open
- Modal open time: the selector query is heavier than today's 4 calls (one Opportunity only); measure in the prototype.
- Chart image timing (Chart.js load in the hidden chart) to verify.
- Wide tables in the modal (one HTML block instead of per-table scroll).
- Parity changes also change future NBC PDFs and snapshots (expected: the modal is the source of truth).
