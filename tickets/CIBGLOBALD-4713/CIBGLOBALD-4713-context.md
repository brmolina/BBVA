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

## Update 2026-10-20 (PDF reviewed, entry points, chart, RWA)
### PDF generated from Configuration > Views > 'Profitability view' (6 pages, opp ESCD26OPP00004148ES)
- Profitability section starts mid page 4 after the Client block (the view has Opportunity Info, Products, Client, Profitability). Tables use 6px font; ID cells of product/underlying rows are indented and overlap the Initial Date column (garbled text). Tenor column empty. Economic Capital table splits across pages 4-5 without a repeated header; page 5 is almost blank because the chart block has page-break-before: always; chart alone on page 6.
- Server chart (DMT_ProfitabilityChartGenerator, also edited by Jorge today) is NOT faithful to the modal chart: (1) modal reads only the Opportunity row totalYears, server aggregates all rows (max EAD per year, average of rorc/raroec over every row incl. products/underlyings); (2) modal EAD / 1,000,000 ('Mill EUR'), server / 10,000,000 so bars vanish; (3) modal percent = yearly*100 and shows negatives, server clamps negatives to 0 (normalizePercentForChart) so RORC disappears and RAROEC is flat at 0; (4) modal pads to 3 years with null points, server pads with 0. Needs rework before it can replace the client chart.
### Entry points of the view component
- Quick action Opportunity.NBC_VIEW ('View List', ScreenAction) -> LWC dmt_open_view_nbc (modal) -> dmt_screen_view_management (is-opp-screen-view) -> dmt_view_lwc with opp-id + selected-items. Other embedders: dmt_view_structure (record-id + selected-items), dmt_massive_task_snapshot_runner and dmt_CreateHTMLAndJSONForTask (hidden, snapshots). dmt_view_lwc @api: selectedItems, oppId, prodId, recordId, viewType, objectApiName, recordTypeApiName, currencyIsoCode. With explicit selectedItems it does not call getItemsToDisplay (the per-approver lookup), so embedding it in the modal with a fixed item list avoids per-user section hiding.
### External RWA (button in the middle of the modal) - reproducible server side
- All configuration is already server side: enablement = DMT_Taxonomy_Value_link__mdt (MasterLabel = Opportunity DMT_branch_id_c__c, with_link__c true; only ES0182-ES is true in DMT_TCM_DEV; opp 4148 is ES0182-ES), base URL = isIntegratedOrg() in DMT_Profitability_utils (Organization.IsSandbox), explanationId = Opportunity.DMT_Opp_Id__c + '_' + productId, country = Opportunity.Entific__c, callout = DMT_Profitability_utils.callExternalOrchestrators -> DMT_Utils.callService('DMTO_ExternalOrchestrators') -> DMT_HPG_Utils.callService (record exists in iaso__GBL_integration_service__mdt), response data.aprsCalculator[].aprCalculator{productId, aprCalculation}. Result is never persisted; the modal keeps it in memory.
- Design implication: the renderer must not call the service on every render (snapshots, PDFs, NBC). Add an explicit request flag (like itemsImg) that makes the ViewController call the service once and pass the map to the renderer.
- Related framework: DMT_CalloutTrackableRenderer (CIBGLOBALD-4117) is for restart tracking of callout-based values; not required for this, but note it exists.
### User decisions
- Make DMT_Profitability_utils 'without sharing' (user approved). Keep the originally generated HTML for version snapshots (user approved approach).
- Waiting on Jorge: is he only aligning the renderer or also migrating the modal.
