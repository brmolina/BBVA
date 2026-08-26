/**
 * @class   DMT_RendererFactory
 * @description Central registry mapping DMT component names (as stored in DMT_Items__c)
 *              to their concrete DMT_ViewRenderer implementation classes.
 *
 * To add a new renderer:
 * 1. Create a class that implements DMT_ViewRenderer and overrides renderHtml().
 * 2. Add an entry to rendererMap below: 'Component Name' => MyRenderer.class
 * 3. Grant classAccesses to the new class in all relevant DMT permission sets
 *    (ConsultationIT, DMT_Access, DMT_Approver_Configuration, DMT_Approver_Task,
 *    DMT_CommercialActivity, DMT_Integration_Analytics, DMT_Limit_Test, DMT_ReadOnly).
 */
public with sharing class DMT_RendererFactory {
    /*
     * ─────────────────────────────────────────────────────────────────────────
     * HTML DESIGN CONTRACT — read this before implementing a new renderer
     * ─────────────────────────────────────────────────────────────────────────
     * Every renderer's output is used for two purposes:
     *   A) PDF generation via Blob.toPdf() (DMT_BlobBuilderForPDF)
     *   B) Version snapshot diff in dmt_lineVersions_compare (htmlVersionNormalizer.js)
     *
     * Both require specific HTML conventions described below.
     * Reference implementation: DMT_TreasuryLineInfoRenderer.cls (fully compliant).
     *
     * ── A. PDF RENDERING (Blob.toPdf) ────────────────────────────────────────
     *
     * Blob.toPdf() uses a Paged Media CSS renderer. Apply these inline styles
     * on block elements (<div>, <table>, <tr>, <p>, etc.) to control pagination:
     *
     *   page-break-inside: avoid   — keeps the block on one page; if it does not
     *                                 fit, the whole block moves to the next page.
     *                                 Use on every field block and table row group.
     *   page-break-before: always  — forces a new page before the element.
     *                                 Use for major section headings.
     *   page-break-before: avoid   — keeps the element attached to the preceding block.
     *   page-break-after:  always  — forces a new page after the element.
     *   page-break-after:  avoid   — prevents a break immediately after the element.
     *   widows:  2                 — min lines that must appear at the TOP of the
     *                                 new page when a paragraph is split.
     *   orphans: 2                 — min lines that must remain at the BOTTOM of the
     *                                 first page when a paragraph is split.
     *   (Modern aliases break-inside / break-before / break-after are also accepted.)
     *
     * Global page layout — place inside a <style> tag in the rendered HTML:
     *
     *   @page { size: A4 portrait; margin: 2cm; }
     *   @page :first { ... }   — first page only
     *   @page :left  { ... }   — even (left-hand) pages
     *   @page :right { ... }   — odd (right-hand) pages
     *
     * Margin boxes (repeating headers / footers) — nested inside @page:
     *
     *   @top-left / @top-center / @top-right
     *   @bottom-left / @bottom-center / @bottom-right
     *   @left-top / @left-middle / @left-bottom
     *   @right-top / @right-middle / @right-bottom
     *
     *   Example: @page { @bottom-right { content: counter(page) " / " counter(pages); } }
     *
     * Generated content keywords (use inside margin boxes or ::before / ::after):
     *
     *   content: "Static text"
     *   content: counter(page)                              — current page number
     *   content: counter(pages)                             — total pages
     *   content: "Page " counter(page) " of " counter(pages)
     *   content: string(varName)  — repeats text set on an element via
     *                               string-set: varName content(text)
     *
     * ── B. VERSION DIFF TAGGING (htmlVersionNormalizer.js) ───────────────────
     *
     * Add data-dmt-* attributes so htmlVersionNormalizer.js uses the accurate
     * tagged path for field-level diff instead of the heuristic fallback.
     *
     * Add this comment before the class declaration in every renderer that builds
     * HTML directly (signals compliance to both humans and tooling):
     *
     *   // This renderer builds HTML directly. data-dmt-* attributes are added so
     *   // htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
     *
     * FIELD ROWS — label + value pairs:
     *
     *   <tr data-dmt-row="field">
     *     <td data-dmt-pair="1" data-dmt-label="Label Text:"> ... </td>
     *     <td data-dmt-pair="1" data-dmt-value="true"> value </td>
     *     <!-- second pair in the same row (optional): -->
     *     <td data-dmt-pair="2" data-dmt-label="Second Label:"> ... </td>
     *     <td data-dmt-pair="2" data-dmt-value="true"> value2 </td>
     *   </tr>
     *   Rules: data-dmt-label value must match visible label text including any
     *   trailing colon. data-dmt-pair groups label+value cells; use N=1 and N=2
     *   when two fields share one row.
     *
     * TITLE ROWS — section headings with no label+value pair:
     *
     *   <tr data-dmt-row="title"><td colspan="N"> Section Heading </td></tr>
     *
     * CHECKBOX ROWS — boolean fields rendered as a visual indicator:
     *
     *   <tr data-dmt-row="checkbox">
     *     <td data-dmt-pair="1" data-dmt-label="Label:"> ... </td>
     *     <td data-dmt-pair="1" data-dmt-value="true"> ✓ or ✗ or equivalent </td>
     *   </tr>
     *   The diff engine compares the text content of the value cell as a string,
     *   so any stable representation (✓/✗, Yes/No, true/false) works.
     *
     * DATA TABLES — column-header tables with data rows:
     *
     *   <table data-dmt-table="true">
     *     <tr data-dmt-table-title="true"><td colspan="N">Title</td></tr>  <!-- optional -->
     *     <tr data-dmt-table-header="true">
     *       <th data-dmt-header-cell="true">Col A</th>
     *       <th data-dmt-header-cell="true">Col B</th>
     *     </tr>
     *     <tr data-dmt-table-row="true">
     *       <td data-dmt-cell="true">value</td>
     *       <td data-dmt-cell="true">value</td>
     *     </tr>
     *   </table>
     *
     * TRAFFIC LIGHTS:
     *
     *   Via DMT_FormattingUtils.renderTrafficLight() / renderTrafficLightSingle():
     *     Already tagged — do NOT add manual attributes.
     *
     *   Built inline (without FormattingUtils), add on the outermost container:
     *     data-dmt-traffic="RED|YELLOW|GREEN|GREY|WHITE"
     *     data-dmt-traffic-mode="single"   — one circle, one active color
     *     data-dmt-traffic-mode="triple"   — three circles, active one highlighted
     *
     * SECTION WRAPPER:
     *   DMT_ViewController.loadComponentsForView wraps each renderer's output in:
     *     <section data-dmt-component="true" data-dmt-component-name="Component Name">
     *   Renderers do not add this wrapper themselves.
     */
    private static Map<String, Type> rendererMap = new Map<String, Type>{
        'Line Info' => DMT_InfoRenderer.class,
        'Opportunity Info' => DMT_InfoRenderer.class,
        'Client' => DMT_ClientRenderer.class,
        'Approval Modifications' => DMT_ApprovalModificationsRenderer.class,
        'Approval Process Data' => DMT_ApprovalProcessDataRenderer.class,
        'Commercial Process Data' => DMT_CommercialProcessDataRenderer.class,
        'Participants' => DMT_ParticipantRenderer.class,
        'Products' => DMT_ProductsRenderer.class,
        'Sustainability' => DMT_SustainabilityRenderer.class,
        'Passport' => DMT_PassportRenderer.class,
        'Limit' => DMT_LimitRenderer.class,
        'Limit Visual' => DMT_LimitVisualRenderer.class,
        'Profitability' => DMT_ProfitabilityRenderer.class,
        'Transaction Overview' => DMT_TransactionOverviewRenderer.class,
        'Economics' => DMT_EconomicsRenderer.class,
        'Approval Process' => DMT_ApprovalProcessFlowRenderer.class,
        'Validation Process' => DMT_PassportProcessFlowRenderer.class,
        'Basic Financials' => DMT_BasicFinancialsRenderer.class,
        'Client Information' => DMT_ClientInformationRenderer.class,
        'Business Plan Data' => DMT_BusinessPlanDataRenderer.class,
        'Client Tier' => DMT_ClientTierRenderer.class,
        'Sustainable Finance' => DMT_SustainableFinanceRenderer.class,
        'Main Characteristics of the Deal' => DMT_MainCharacteristicsOfTheDealRenderer.class,
        'Other Aspect' => DMT_OtherAspectRenderer.class,
        'Risks' => DMT_RisksRenderer.class,
        'Basic Requirement' => DMT_BasicRequirementRenderer.class,
        'Intro Opportunity Deal' => DMT_IntroOpportunityDealRenderer.class,
        'Active Related Lines'=>DMT_ActiveRelatedLinesRenderer.class,
        'Sanction Approval Info' => DMT_SanctionApprovalInfoRenderer.class,
        'Approval Info' => DMT_InfoRenderer.class,
        'Sanction Client' => DMT_SanctionClientRenderer.class,
        'Sanction Products' => DMT_SanctionProductsRenderer.class,
        'Sanction Participants' => DMT_SanctionParticipantsRenderer.class,
        'Sanction Approval Process Data' => DMT_SanctionApprovalProcessDataRenderer.class,
        'Sanction Passport' => DMT_SanctionPassportRenderer.class,
        'Sanction Limit' => DMT_SanctionLimitRenderer.class,
        'Sanction Limit Visual' => DMT_SanctionLimitVisualRenderer.class,
        'Product Simple' => DMT_ProductSimpleRenderer.class,
        'Opportunity Info NBC' => DMT_InfoNBCRenderer.class,
        'Client NBC' => DMT_ClientNBCRenderer.class,
        'Profitability Summaries' => DMT_ProfitabilitySummariesRenderer.class,
        'Profitability Visual' => DMT_ProfitabilityVisualRenderer.class,
        'Status' => DMT_StatusOnlyRenderer.class,
        // New Components NBC
        'NBC Opportunity Info' => DMT_NBC_OpportunityInfoRenderer.class,
        'NBC Client' => DMT_NBC_ClientRenderer.class,
        'GTB Local NBC Client' => DMT_NBC_ClientRenderer.class,
        'NBC Main Characteristics of the Deal' => DMT_NBC_MainChOfTheDealRenderer.class,
        'GTB Local NBC Main Characteristics of the Deal' => DMT_NBC_MainChOfTheDealRenderer.class,
        'NBC Basic Requeriment' => DMT_NBC_BasicRequirementRenderer.class,
        'GTB Local NBC Basic Requeriment' => DMT_NBC_BasicRequirementRenderer.class,
        'NBC Deal' => DMT_NBC_DealRenderer.class,
        'GTB Local NBC Deal' => DMT_NBC_DealRenderer.class,
        'NBC Transaction Overview' => DMT_NBC_TransactionOverviewRenderer.class,
        'NBC Economics' => DMT_NBC_EconomicsRenderer.class,
        'NBC Basic Financials' => DMT_NBC_BasicFinancialsRenderer.class,
        'NBC Business Plan Data' => DMT_NBC_BusinessPlanDataRenderer.class,
        'NBC Client Information' => DMT_NBC_ClientTierRenderer.class,
        'NBC Risk' => DMT_NBC_RiskRenderer.class,
        'NBC Other Aspects' => DMT_NBC_OtherAspectsRenderer.class,
        'GTB Local NBC Other Aspects' => DMT_NBC_OtherAspectsRenderer.class,
        'NBC Requirements' => DMT_NBC_RequirementsRenderer.class,
        'NBC Assessment' => DMT_NBC_AssessmentRenderer.class,
        'NBC Sustainability Indicators' => DMT_NBC_SustainabilityIndicatorsRenderer.class,
        'NBC Sustainability Labels' => DMT_NBC_SustainabilityLabelsRenderer.class,
        'GTB Local NBC Sustainability Labels' => DMT_NBC_SustainabilityLabelsRenderer.class,
        'NBC Sppi Test' => DMT_NBC_SppiTestRenderer.class,
        'NBC Approval Process' => DMT_NBC_ApprovalProcessRenderer.class,
        'NBC Validation Process' => DMT_NBC_ValidationProcessRenderer.class,
        'NBC XSell Geographies' => DMT_NBC_XSellGeographiesRenderer.class,
        'Has Prospect' => DMT_HasProspectRenderer.class
        // Add other components here
    };

    public static DMT_ViewRenderer getRenderer(String componentType) {
        Type rendererType = rendererMap.get(componentType);
        if (rendererType == null) throw new IllegalArgumentException('No renderer found for component: ' + componentType);
        return (DMT_ViewRenderer) rendererType.newInstance();
    }

    public static Boolean hasRenderer(String componentType) {
        return rendererMap.containsKey(componentType);
    }
}