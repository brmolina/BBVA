/**
 * Shared data-prep and table-building logic for DMT_NBC_OppEconomicsRenderer_IBF and
 * DMT_NBC_OppEconomicsRenderer_GTB — the two renderers differ only in which row definitions
 * (getTableRowsDefinitionIBF/GTB, kept on each renderer) are passed into buildHtmlEconomics.
 */
public with sharing class DMT_NBC_EconomicsRendererHelper {

    public class RowDef {
        public String dataLabel;
        public String mainLabelHtml;
        public String mainLabelPdf;
        public String subLabel;

        public RowDef(String d, String mh, String mp, String s) {
            this.dataLabel = d;
            this.mainLabelHtml = mh;
            this.mainLabelPdf = mp;
            this.subLabel = s;
        }
    }

    /**
     * Centralized rendering context for Economics section.
     */
    public class EconomicsData {
        public List<Object> profitabilityResults = new List<Object>();
        public List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
        public List<DMT_ViewController.OpportunityProduct> oppProducts = new List<DMT_ViewController.OpportunityProduct>();

        public EconomicsData(DMT_ViewController.LineDataWrapper data) {
            try {
                this.profitabilityResults = DMT_NBC_EconomicsRendererHelper.extractProfitabilityResults(data != null ? data.featuresList : null);
                this.opportunityLineItems = data != null && data.opportunity != null && data.opportunity.OpportunityLineItems != null
                    ? data.opportunity.OpportunityLineItems
                    : new List<OpportunityLineItem>();
                this.oppProducts = data != null && data.oppProducts != null
                    ? data.oppProducts
                    : new List<DMT_ViewController.OpportunityProduct>();
            } catch (Exception e) {
                System.debug('Error in DMT_NBC_EconomicsRendererHelper EconomicsData, ' + e.getMessage() + ' ' + e.getLineNumber());
                this.profitabilityResults = new List<Object>();
                this.opportunityLineItems = new List<OpportunityLineItem>();
                this.oppProducts = new List<DMT_ViewController.OpportunityProduct>();
            }
        }
    }

    public static String buildHtmlEconomics(EconomicsData vals, List<RowDef> rows) {
        if (vals == null || vals.opportunityLineItems == null || vals.opportunityLineItems.isEmpty()) {
            return '';
        }

        String html = '';
        List<OpportunityLineItem> allItems = vals.opportunityLineItems;
        Integer totalItems = allItems.size();
        Integer batchSize = 4;

        for (Integer startIndex = 0; startIndex < totalItems; startIndex += batchSize) {
            Integer endIndex = Math.min(startIndex + batchSize, totalItems);
            List<OpportunityLineItem> batchItems = new List<OpportunityLineItem>();
            for (Integer i = startIndex; i < endIndex; i++) {
                batchItems.add(allItems[i]);
            }

            html += '<table style="width:100%; border-collapse: collapse; margin-bottom: 15px; table-layout: fixed;">';

            html += '<tr style="height: 0px; line-height: 0px; font-size: 0px;">';
            html += '<td style="width: 13%; padding: 0; margin: 0; border: none; height: 0px;"></td>';
            html += '<td style="width: 7%; padding: 0; margin: 0; border: none; height: 0px;"></td>';
            for(Integer i = 0; i < 8; i++) {
                html += '<td style="width: 10%; padding: 0; margin: 0; border: none; height: 0px;"></td>';
            }
            html += '</tr>';

            html += '<tr>';
            html += '<td colspan="2" style="padding: 4px 2px; color: #888888; font-style: italic; font-size: 10px; vertical-align: bottom; border: none;">Figures in bps</td>';

            for (OpportunityLineItem oli : batchItems) {
                String prodName = (oli.Product2 != null && oli.Product2.Name != null) ? oli.Product2.Name : 'Unknown Product';
                html += '<td colspan="2" style="padding: 4px 2px; color: #004481; font-weight: bold; font-size: 11px; text-align: center; border-top: 2px solid #004481; border-bottom: 1px solid #004481;">' + prodName + '</td>';
            }
            Integer remainingSlots = batchSize - batchItems.size();
            for(Integer i = 0; i < remainingSlots; i++) {
                html += '<td colspan="2" style="padding: 4px 2px; border-top: 2px solid #004481; border-bottom: 1px solid #004481;"></td>';
            }
            html += '</tr>';

            html += '<tr>';
            html += '<td colspan="2" style="border: none;"></td>';

            for (Integer i = 0; i < 4; i++) {
                html += '<td style="padding: 2px; color: #004481; font-size: 9px; text-align: center; font-weight: bold; border: none;">Old <span style="font-weight: normal;">condit.</span></td>';
                html += '<td style="padding: 2px; color: #004481; font-size: 9px; text-align: center; font-weight: bold; border: none;">New <span style="font-weight: normal;">condit.</span></td>';
            }
            html += '</tr>';

            String sMainLabel = 'padding: 2px 4px; color: #004481; font-size: 10px; vertical-align: middle; border: none; background-color: transparent; word-wrap: break-word; word-break: break-word; white-space: normal;';
            String sSubLabel  = 'padding: 2px 4px; color: #004481; font-size: 10px; vertical-align: middle; border: none; background-color: transparent; text-align: right; padding-right: 6px;';
            String cellData   = 'padding: 2px 4px; color: #004481; font-size: 10px; text-align: center; vertical-align: middle; background-color: #F4F6F9; border: 1px solid #ffffff;';

            for (RowDef r : rows) {
                html += '<tr>';
                html += '<td style="' + sMainLabel + ' text-align: left;">' + r.mainLabelHtml + '</td>';
                html += '<td style="' + sSubLabel + '">' + r.subLabel + '</td>';

                for (OpportunityLineItem oli : batchItems) {
                    String valOld = getOldValueForLabel(r.dataLabel, vals.oppProducts, oli);
                    String valNew = getValueForLabel(r.dataLabel, vals.oppProducts, oli, vals.profitabilityResults);
                    if (valOld != null) {
                        valOld = valOld.replace('\n', '<br/>');
                    }
                    if (valNew != null) {
                        valNew = valNew.replace('\n', '<br/>');
                    }

                    html += '<td style="' + cellData + '">' + valOld + '</td>';
                    html += '<td style="' + cellData + '">' + valNew + '</td>';
                }

                for(Integer i = 0; i < remainingSlots; i++) {
                    html += '<td style="' + cellData + '"></td><td style="' + cellData + '"></td>';
                }
                html += '</tr>';
            }
            html += '</table>';
        }
        return html;
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

    private static String getValueForLabel(String label, List<DMT_ViewController.OpportunityProduct> oppProducts, OpportunityLineItem oli, List<Object> profitabilityResults) {
        // A saved new-money record (DMT_Is_Old_Money__c = false, entered via the "Economics Old Money"
        // modal's New Money column) overrides the profitability-engine computation field by field, so
        // whatever the user enters in that modal is what appears in New condit. Fields left blank on
        // the record fall through to the computed value below.
        String newMoneyOverride = getNewMoneyOverrideValue(label, oppProducts, oli);
        if (newMoneyOverride == null) {
            return '';
        }
        return newMoneyOverride;

         /*Map<String, Object> productResult = new Map<String, Object>();
        if (profitabilityResults != null && !profitabilityResults.isEmpty()) {
            for (Object rec : profitabilityResults) {
                Map<String, Object> mapRec = (Map<String, Object>)rec;
                String jsonProductId = (String)mapRec.get('productId');
                if (jsonProductId == oli.gf_group_priority_opportunity_id__c) {
                    productResult = mapRec;
                    break;
                }
            }
        }

        switch on label {
            when 'Up-Front Fee Accrual' { return DMT_FormattingUtils.formatToTwoDecimals(productResult.get('periodicFeesPbs')); }
            when 'Up-Front Fee Non Accrual' { return DMT_FormattingUtils.formatToTwoDecimals(productResult.get('feesUpFrontPbs')); }
            when 'Funding Cost' { return DMT_FormattingUtils.formatToTwoDecimals(productResult.get('fundingDbPbs')); }
            when 'Liquidity Fee' { return DMT_FormattingUtils.formatToTwoDecimals(productResult.get('fundingFbPbs')); }
            when 'Interest Rate Period' { return DMT_FormattingUtils.checkNull(oli.gf_payment_frequency__c); }
            when 'Applicable Margin' {
                Decimal spreadDb = (Decimal)productResult.get('spreadDbPbs');
                Decimal spreadFb = (Decimal)productResult.get('spreadFbPbs');
                if(spreadDb != null && spreadFb != null) {
                    return DMT_FormattingUtils.formatToTwoDecimals(spreadDb + spreadFb);
                } else if (spreadDb != null) {
                    return DMT_FormattingUtils.formatToTwoDecimals(spreadDb);
                } else if (spreadFb != null) {
                    return DMT_FormattingUtils.formatToTwoDecimals(spreadFb);
                }
                return '';
            }
            when 'Pricing Grid or Step-ups (if applicable)' { return DMT_FormattingUtils.checkNull(oli.DMT_PricingGrid_OR_StepUps__c); }
            when 'Commitment Fee' { return DMT_FormattingUtils.formatToTwoDecimals(oli.DMT_TXT_Commitment_Fees__c); }
            when 'Utilisation Fee' { return DMT_FormattingUtils.formatToTwoDecimals(oli.DMT_Utilisation_Fee__c);}
            when 'Extension/Duration Fee' { return DMT_FormattingUtils.checkNull(oli.DMT_TXT_Extension_Duration_Fees__c); }
            when 'Other fees Accrual' { return DMT_FormattingUtils.formatToTwoDecimals(oli.DMT_TXT_Other_Fees_Accrual__c); }
            when 'Other fees Non Accrual' { return DMT_FormattingUtils.formatToTwoDecimals(oli.DMT_TXT_Other_Fees_NonAccrual__c); }
            when 'Expected Drawn' { return DMT_FormattingUtils.formatToTwoDecimals(oli.DMT_Expected_Drawn__c); }
            when 'All-in: Drawn' { return DMT_FormattingUtils.formatToTwoDecimals(productResult.get('allInDb')); }
            when 'All-in: Undrawn' { return DMT_FormattingUtils.formatToTwoDecimals(productResult.get('allInFb')); }
            when else { return ''; }
        } */
    } 

    private static String getOldValueForLabel(String label, List<DMT_ViewController.OpportunityProduct> oppProducts, OpportunityLineItem oli) {
        DMT_ViewController.OpportunityProduct oppProduct = getOpportunityProductForOli(oppProducts, oli);
        DMT_Opportunity_Money__c oppMoney = getPrimaryOppMoney(oppProduct, true);

        if (oppMoney == null) {
            return '';
        }

        switch on label {
            when 'Up-Front Fee Accrual' { return DMT_FormattingUtils.formatToTwoDecimals(getOppMoneyField(oppMoney, 'DMT_Up_Front_Fee_Accrual__c')); }
            when 'Up-Front Fee Non Accrual' { return DMT_FormattingUtils.formatToTwoDecimals(getOppMoneyField(oppMoney, 'DMT_Up_Front_Fee_Non_Accrual__c')); }
            when 'Funding Cost' { return DMT_FormattingUtils.formatToTwoDecimals(getOppMoneyField(oppMoney, 'DMT_Funding_Cost__c')); }
            when 'Liquidity Fee' { return DMT_FormattingUtils.formatToTwoDecimals(getOppMoneyField(oppMoney, 'DMT_Liquidity_Fee__c')); }
            when 'Interest Rate Period' { return DMT_FormattingUtils.checkNull(getOppMoneyField(oppMoney, 'DMT_Interest_Rate_Period__c')); }
            when 'Applicable Margin' { return DMT_FormattingUtils.formatToTwoDecimals(getOppMoneyField(oppMoney, 'DMT_Applicable_Margin__c')); }
            when 'Pricing Grid or Step-ups (if applicable)' { return DMT_FormattingUtils.checkNull(getOppMoneyField(oppMoney, 'DMT_Pricing_Grid_or_Step_ups__c')); }
            when 'Commitment Fee' { return DMT_FormattingUtils.formatToTwoDecimals(getOppMoneyField(oppMoney, 'DMT_Commitment_Fee__c')); }
            when 'Utilisation Fee' { return DMT_FormattingUtils.formatToTwoDecimals(getOppMoneyField(oppMoney, 'DMT_Utilisation_Fee__c')); }
            when 'Extension/Duration Fee' { return DMT_FormattingUtils.checkNull(getOppMoneyField(oppMoney, 'DMT_Extension_Duration_Fee__c')); }
            when 'Other fees Accrual' { return DMT_FormattingUtils.formatToTwoDecimals(getOppMoneyField(oppMoney, 'DMT_Other_Fees_Accrual__c')); }
            when 'Other fees Non Accrual' { return DMT_FormattingUtils.formatToTwoDecimals(getOppMoneyField(oppMoney, 'DMT_Other_Fees_Non_Accrual__c')); }
            when 'Expected Drawn' { return DMT_FormattingUtils.formatToTwoDecimals(getOppMoneyField(oppMoney, 'DMT_Expected_Drawn__c')); }
            when 'All-in: Drawn' { return DMT_FormattingUtils.formatToTwoDecimals(getOppMoneyField(oppMoney, 'DMT_All_in_Drawn__c')); }
            when 'All-in: Undrawn' { return DMT_FormattingUtils.formatToTwoDecimals(getOppMoneyField(oppMoney, 'DMT_All_in_Undrawn__c')); }
            when else { return ''; }
        }
    }

    private static DMT_ViewController.OpportunityProduct getOpportunityProductForOli(List<DMT_ViewController.OpportunityProduct> oppProducts, OpportunityLineItem oli) {
        if (oppProducts == null || oli == null) {
            return null;
        }

        for (DMT_ViewController.OpportunityProduct oppProduct : oppProducts) {
            if (oppProduct != null && oppProduct.productId != null && String.valueOf(oppProduct.productId) == String.valueOf(oli.Id)) {
                return oppProduct;
            }
        }
        return null;
    }

    private static DMT_Opportunity_Money__c getPrimaryOppMoney(DMT_ViewController.OpportunityProduct oppProduct, Boolean isOldMoney) {
        if (oppProduct == null || oppProduct.oppMoneys == null) {
            return null;
        }

        for (DMT_Opportunity_Money__c oppMoney : oppProduct.oppMoneys) {
            if (oppMoney != null && oppMoney.DMT_Is_Old_Money__c == isOldMoney) {
                return oppMoney;
            }
        }

        return null;
    }

    private static Object getOppMoneyField(DMT_Opportunity_Money__c oppMoney, String fieldApiName) {
        if (oppMoney == null || String.isBlank(fieldApiName)) {
            return null;
        }
        Map<String, Object> moneyMap = oppMoney.getPopulatedFieldsAsMap();
        return (moneyMap != null && moneyMap.containsKey(fieldApiName)) ? moneyMap.get(fieldApiName) : null;
    }

    /**
     * Returns the New condit. override sourced from the saved new-money record (DMT_Is_Old_Money__c
     * = false), field by field. Returns null (not a blank string) when there is no new-money record,
     * or the specific field on it is blank, so the caller falls back to the profitability computation.
     */
    private static String getNewMoneyOverrideValue(String label, List<DMT_ViewController.OpportunityProduct> oppProducts, OpportunityLineItem oli) {
        DMT_ViewController.OpportunityProduct oppProduct = getOpportunityProductForOli(oppProducts, oli);
        DMT_Opportunity_Money__c newMoney = getPrimaryOppMoney(oppProduct, false);
        if (newMoney == null) {
            return null;
        }

        switch on label {
            when 'Up-Front Fee Accrual' { return formatIfPresent(getOppMoneyField(newMoney, 'DMT_Up_Front_Fee_Accrual__c')); }
            when 'Up-Front Fee Non Accrual' { return formatIfPresent(getOppMoneyField(newMoney, 'DMT_Up_Front_Fee_Non_Accrual__c')); }
            when 'Funding Cost' { return formatIfPresent(getOppMoneyField(newMoney, 'DMT_Funding_Cost__c')); }
            when 'Liquidity Fee' { return formatIfPresent(getOppMoneyField(newMoney, 'DMT_Liquidity_Fee__c')); }
            when 'Interest Rate Period' { return checkNullIfPresent(getOppMoneyField(newMoney, 'DMT_Interest_Rate_Period__c')); }
            when 'Applicable Margin' { return formatIfPresent(getOppMoneyField(newMoney, 'DMT_Applicable_Margin__c')); }
            when 'Pricing Grid or Step-ups (if applicable)' { return checkNullIfPresent(getOppMoneyField(newMoney, 'DMT_Pricing_Grid_or_Step_ups__c')); }
            when 'Commitment Fee' { return formatIfPresent(getOppMoneyField(newMoney, 'DMT_Commitment_Fee__c')); }
            when 'Utilisation Fee' { return formatIfPresent(getOppMoneyField(newMoney, 'DMT_Utilisation_Fee__c')); }
            when 'Extension/Duration Fee' { return checkNullIfPresent(getOppMoneyField(newMoney, 'DMT_Extension_Duration_Fee__c')); }
            when 'Other fees Accrual' { return formatIfPresent(getOppMoneyField(newMoney, 'DMT_Other_Fees_Accrual__c')); }
            when 'Other fees Non Accrual' { return formatIfPresent(getOppMoneyField(newMoney, 'DMT_Other_Fees_Non_Accrual__c')); }
            when 'Expected Drawn' { return formatIfPresent(getOppMoneyField(newMoney, 'DMT_Expected_Drawn__c')); }
            when 'All-in: Drawn' { return formatIfPresent(getOppMoneyField(newMoney, 'DMT_All_in_Drawn__c')); }
            when 'All-in: Undrawn' { return formatIfPresent(getOppMoneyField(newMoney, 'DMT_All_in_Undrawn__c')); }
            when else { return null; }
        }
    }

    private static String formatIfPresent(Object rawValue) {
        return rawValue == null ? null : DMT_FormattingUtils.formatToTwoDecimals(rawValue);
    }

    private static String checkNullIfPresent(Object rawValue) {
        return rawValue == null ? null : DMT_FormattingUtils.checkNull(rawValue);
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