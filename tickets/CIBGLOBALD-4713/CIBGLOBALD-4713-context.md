# CIBGLOBALD-4713 - context (written 2026-10-20)

Requirement as written: add a Download (PDF) button to the Opportunity Passport Profitability modal, reusing NBC components. In practice it is a refactor: the modal and the NBC renderer are two separate implementations of the same screen.

## Where things are
- Entry points that open the modal in profitability mode (showProfitabilityChart: true): dmt_feature_profitability.js:70, dmt_feature_with_workflow.js:185, dmt_passport.js:930 (getter). All open `c/dmt_passport_modal` (LightningModal; header = feature name 'Profitability Engine', body = c-dmt_profitability_chart, footer = Close only).
- Modal body `dmt_profitability_chart` (LWC): own template + JS (processProfitabilityData, normalizeProfitabilityResults, buildOrderedRows), Chart.js canvas, button 'External RWA calculate' in the middle of the data (Regulatory Capital header). Apex used: DMT_Profitability_utils (getProductDetailsByIds, getNominalAmountsByOpportunityLineItemIds, convertNominalsToOppCurrency, getRwaRegLinkInfo, getUnderlyingDetailsByIds, callExternalOrchestrators). Input: feature.profitability (saved Passport JSON object) + opportunityId.
- NBC / views chain: Configuration tab > Views (screen view management, dmt_screen_view_management) > dmt_view_lwc embeds the view > DMT_ViewController.loadComponentsForView(recordOrLineId, viewType, selectedItems, productId, itemsImg) > filterActiveComponents (CMDT DMT_Configurator_View_Items__mdt) > loadRelatedData (builds LineDataWrapper; for Opportunity: featuresList = getFeatures(oppId) = Passport__c.DMT_Passport_Save__c JSON; preloads profitabilityProductDetailsList / NominalAmountsMap / NominalAmountsConvertedMap through DMT_Profitability_utils) > generateHtmlForComponent > DMT_RendererFactory.getRenderer(name).renderHtml(data). 'Profitability' => DMT_ProfitabilityRenderer (by record type) => DMT_OppProfitabilityRenderer. Also 'Profitability Summaries', 'Profitability Visual' (chart image captured client-side from a hidden c-dmt_profitability_chart via getChartImage and sent as itemsImg).
- PDF: dmt_view_lwc.handleDownloadPDF > generatePdf(htmlForPdf) > DMT_PdfService.preparePdfAssets (data: images -> temp Documents) > generateFinalPdf (Blob.toPdf via DMT_BlobBuilderForPDF; mobile stores a temp ContentVersion) > browser blob download. Generated on demand; no stored profitability PDF exists.
- Renderer HTML contract (DMT_RendererFactory header comment): the same HTML feeds (A) Blob.toPdf and (B) version snapshot diff (dmt_lineVersions_compare / htmlVersionNormalizer.js, data-dmt-* attributes). Any change to a renderer's HTML also affects version snapshots and, if the renderer is tracked, the approval restart framework (CIBGLOBALD-4117).
- Sharing: DMT_ViewController without sharing; DMT_OppProfitabilityRenderer without sharing; DMT_Profitability_utils with sharing (modal path).

## Modal vs renderer: what differs (code read + browser run, opp ESCD26OPP00004148ES, record 006KE000003Qx30YAC)
- 2026-10-20 10:37 UTC another developer (Jorge Andres Florentin Escurra) changed DMT_OppProfitabilityRenderer in DMT_TCM_DEV (Net Income -> Incomes 12 months, added NetIncome Reg and NetIncome Eco columns) and DMT_ProfitabilityChartGenerator (adaptive scaling for the server chart). Same direction as this ticket's refactor. Coordinate with him and Diego before touching these classes.
- Still different after his change (seen in the Profitability view of Configuration > Views):
  - Tenor: renderer reads row.tenor, data key is term -> Tenor cell empty in the renderer.
  - Average Life / Tenor: modal prints '2.91y', renderer '2,91'.
  - Small amounts: modal formatAmountWithCurrencyMax2 prints scientific notation (-4.47e-4 EUR), renderer formatCurrencyAmountLikeModal rounds (0,00 EUR).
  - Notional columns on product/underlying rows: modal '—', renderer '0,00 EUR'.
  - Economic table: renderer has extra 'RAROEC CDD' column.
  - External RWA 1Y column + button (modal only; enabled when Opportunity branch matches DMT_Taxonomy_Value_link__mdt with_link__c; callExternalOrchestrators on click, result kept in memory only).
  - Chart: Chart.js canvas (modal) vs image captured from the canvas / server chart (renderer).
- Row logic duplicated: JS normalizeProfitabilityResults/buildOrderedRows vs Apex orderProfitabilityResults.

## Decisions so far (user, 2026-10-20)
- The modal is the source of truth. Step 1: make the renderer output identical to the modal with the same data (data built in DMT_ViewController, then DMT_RendererFactory, then the renderer). Step 2: modal displays the renderer HTML; middle button disappears. The Download PDF button is only added once step 1 is verified in Configuration > Views.
- Download PDF: generated on demand when the user clicks (not stored).
- Button location open: footer next to Close (brand, right) is the working idea; Diego asked to confirm with Fernando (owner). Needs spinner, error message, UX care. Button must run query + callout (if any) through the ViewController and renderer.
- Live chart should be in the renderer; PDF must be creatable before migrating the modal.
- No per-user hiding found in the modal itself (RWA button depends on the Opportunity branch, not the user). Views are per approver (Configuration > Approvers: Approver View Opportunity), which is not applied in the modal.
