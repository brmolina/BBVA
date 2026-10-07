/**
 * Shared data-prep and Transaction Overview table builder for DMT_NBC_OppDealRenderer_IBF and
 * DMT_NBC_OppDealRenderer_GTB — the two renderers differ only in header text and which label set
 * (TRANSACTION_LABELS_IBF/_GTB) is passed into buildHtmlTransactionOverview.
 */
public with sharing class DMT_NBC_DealRendererHelper {

    public static final Integer OVERVIEW_BATCH_SIZE = 4;
    public static final String HTML_OVERVIEW_TABLE_STYLE = 'width: 100%; border-collapse: collapse; margin-bottom: 10px; table-layout: fixed;';
    public static final String HTML_OVERVIEW_TD_HEAD_L = 'padding: 4px 6px; color: #888888; font-style: italic; font-size: 9px; border: none; vertical-align: bottom;';
    public static final String HTML_OVERVIEW_TD_HEAD_C = 'padding: 4px 6px; color: #004481; font-weight: bold; font-size: 10px; text-align: center; border-top: 2px solid #004481; border-bottom: 1px solid #004481; vertical-align: bottom;';
    public static final String HTML_OVERVIEW_TD_L = 'padding: 3px 6px; text-align: left; font-size: 9px; color: #004481; border: none; background-color: transparent;';
    public static final String HTML_OVERVIEW_TD_V = 'padding: 3px 6px; text-align: center; font-size: 9px; color: #004481; border: 1px solid #ffffff; background-color: #F4F6F9;';

    /**
     * Centralizes all values used to render the Deal section.
     */
    public class DealData {
        public String historyDeal = '';
        public String borrowerNameFiscalId = '';
        public String guarantorNameFiscalId = '';
        public List<Object> profitabilityResults = new List<Object>();
        public List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();

        /**
         * Builds the rendering context from the raw wrapper.
         * @param data LineDataWrapper with opportunity, client and related data.
         */
        public DealData(DMT_ViewController.LineDataWrapper data) {
            try {
                this.historyDeal = data != null && data.oppClient != null ? DMT_FormattingUtils.toSafeMultilineHtml(DMT_FormattingUtils.checkNull(data.oppClient.DMT_History_Deal__c)) : '';
                this.borrowerNameFiscalId = DMT_NBC_DealRendererHelper.buildBorrowerNameFiscalId(data);
                this.guarantorNameFiscalId = data != null && data.oppClient != null ? DMT_FormattingUtils.checkNull(data.oppClient.DMT_Guarantor_Name_Fiscal_ID__c) : '';
                this.profitabilityResults = DMT_NBC_DealRendererHelper.extractProfitabilityResults(data != null ? data.featuresList : null);
                this.opportunityLineItems = data != null && data.opportunity != null && data.opportunity.OpportunityLineItems != null
                    ? data.opportunity.OpportunityLineItems
                    : new List<OpportunityLineItem>();
            } catch (Exception e) {
                System.debug('Error in DMT_NBC_DealRendererHelper DealData, ' + e.getMessage() + ' ' + e.getLineNumber());
                this.historyDeal = '';
                this.borrowerNameFiscalId = '';
                this.guarantorNameFiscalId = '';
                this.profitabilityResults = new List<Object>();
                this.opportunityLineItems = new List<OpportunityLineItem>();
            }
        }
    }

    public static String buildBorrowerNameFiscalId(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity == null || data.opportunity.Account == null) {
            return '';
        }

        String accountName = DMT_FormattingUtils.checkNull(data.opportunity.Account.Name);
        String accountFiscalId = DMT_FormattingUtils.checkNull(data.opportunity.Account.DES_ID_Fiscal__c);
        return accountName + ' - ' + accountFiscalId;
    }

    public static List<Object> extractProfitabilityResults(List<Object> featuresList) {
        Map<String, Object> feature = getProfitabilityFeature(featuresList);
        if (feature.isEmpty() || !feature.containsKey('profitability')) {
            return new List<Object>();
        }

        Map<String, Object> profitability = (Map<String, Object>)feature.get('profitability');
        if (profitability.isEmpty() || !profitability.containsKey('results')) {
            return new List<Object>();
        }

        return (List<Object>)profitability.get('results');
    }

    public static String buildHtmlTransactionOverview(
        List<OpportunityLineItem> opportunityLineItems,
        List<Object> profitabilityResults,
        List<String> labels
    ) {
        if (opportunityLineItems == null || opportunityLineItems.isEmpty()) {
            return '<div style="font-size: 9px; color: #888888; margin-bottom: 10px;">No transaction data available</div>';
        }

        String html = '';
        List<OpportunityLineItem> allItems = opportunityLineItems;
        for (Integer startIndex = 0; startIndex < allItems.size(); startIndex += OVERVIEW_BATCH_SIZE) {
            Integer endIndex = Math.min(startIndex + OVERVIEW_BATCH_SIZE, allItems.size());
            List<OpportunityLineItem> batchItems = new List<OpportunityLineItem>();
            for (Integer i = startIndex; i < endIndex; i++) {
                batchItems.add(allItems[i]);
            }
            html += buildHtmlBatchOverviewTable(batchItems, profitabilityResults, labels);
        }

        return html;
    }

    private static String buildHtmlBatchOverviewTable(
        List<OpportunityLineItem> batchItems,
        List<Object> profitabilityResults,
        List<String> labels
    ) {
        String html = '<table style="' + HTML_OVERVIEW_TABLE_STYLE + '">';
        html += '<colgroup><col style="width: 20%;"><col style="width: 20%;"><col style="width: 20%;"><col style="width: 20%;"><col style="width: 20%;"></colgroup>';
        html += '<tr><td style="' + HTML_OVERVIEW_TD_HEAD_L + '">Figures in Mn</td>';

        for (OpportunityLineItem oli : batchItems) {
            String productName = (oli.Product2 != null && oli.Product2.Name != null) ? oli.Product2.Name : 'Unknown Product';
            html += '<td style="' + HTML_OVERVIEW_TD_HEAD_C + '">' + productName + '</td>';
        }

        Integer remainingSlots = OVERVIEW_BATCH_SIZE - batchItems.size();
        for (Integer i = 0; i < remainingSlots; i++) {
            html += '<td style="' + HTML_OVERVIEW_TD_HEAD_C + '"></td>';
        }
        html += '</tr>';

        for (String label : labels) {
            html += '<tr><td style="' + HTML_OVERVIEW_TD_L + '">' + label + '</td>';
            for (OpportunityLineItem oli : batchItems) {
                html += '<td style="' + HTML_OVERVIEW_TD_V + '">' + getValueForLabel(label, oli, profitabilityResults) + '</td>';
            }
            for (Integer i = 0; i < remainingSlots; i++) {
                html += '<td style="' + HTML_OVERVIEW_TD_V + '"></td>';
            }
            html += '</tr>';
        }

        return html + '</table>';
    }

    private static String getValueForLabel(String label, OpportunityLineItem oli, List<Object> profitabilityResults) {
        Map<String, Object> productResult = getProductResult(oli, profitabilityResults);
        switch on label {
            when 'Type' { String productName = (oli.Product2 != null && oli.DMT_TXT_ProductNameOLI__c != null) ? oli.DMT_TXT_ProductNameOLI__c : (oli.Product2 != null ? oli.Product2.Name : 'Unknown Product'); return productName; }
            when 'Deal Amount' { return DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(oli.DMT_Deal_amount__c)); }
            when 'Currency' { return (oli.g_currency_id__c != null) ? oli.g_currency_id__c : ''; }
            when 'Role of BBVA' { return (oli.entity_role_type__c != null) ? oli.entity_role_type__c : 'na'; }
            when 'Underwriting' { return (oli.underwriting_agreement_type__c != null) ? oli.underwriting_agreement_type__c : ''; }
            when 'BBVA Commitment' { return DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(oli.bbva_prtcp_tranche_amount__c)); }
            when 'Expected Final Take' { return DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(oli.syndicated_loan_drawn_amount__c)); }
            when 'Sub-limit (if any)' { return (oli.DMT_Sub_Limit__c != null) ? oli.DMT_Sub_Limit__c : ''; }
            when 'EAD' { return DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(productResult.get('regulatoryEad'))); }
            when 'New Money for BBVA' { return DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(oli.DMT_NewMoney_BBVA__c)); }
            when 'Old Money for BBVA' { return DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(oli.DMT_OldMoney_BBVA__c)); }
            when 'Tenor' { return DMT_FormattingUtils.formatDecimalEs(DMT_FormattingUtils.checkNull(productResult.get('term')), 2); }
            when 'Average Life' { return DMT_FormattingUtils.formatDecimalEs(DMT_FormattingUtils.checkNull(productResult.get('averageLife')), 2); }
            when 'Standalone RORC/RAROEC' { return formatRorcRaroec(productResult); }
            when else { return ''; }
        }
    }

    private static String formatRorcRaroec(Map<String, Object> productResult) {
        if (productResult.isEmpty()) {
            return '';
        }
        return DMT_FormattingUtils.formatPercent(productResult.get('rorc')) + ' / '
            + DMT_FormattingUtils.formatPercent(productResult.get('raroec'));
    }

    private static Map<String, Object> getProductResult(OpportunityLineItem oli, List<Object> profitabilityResults) {
        if (profitabilityResults == null || profitabilityResults.isEmpty()) {
            return new Map<String, Object>();
        }

        for (Object rec : profitabilityResults) {
            Map<String, Object> mapRec = (Map<String, Object>)rec;
            String jsonProductId = (String)mapRec.get('productId');
            if (jsonProductId == oli.gf_group_priority_opportunity_id__c) {
                return mapRec;
            }
        }
        return new Map<String, Object>();
    }

    private static Map<String, Object> getProfitabilityFeature(List<Object> featuresList) {
        if (featuresList == null || featuresList.isEmpty()) {
            return new Map<String, Object>();
        }

        for (Object obj : featuresList) {
            Map<String, Object> feature = (Map<String, Object>)obj;
            if (feature != null && feature.containsKey('profitability')) {
                return feature;
            }
        }
        return new Map<String, Object>();
    }
}