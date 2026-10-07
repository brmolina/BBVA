public without sharing class DMT_OppEconomicsRenderer implements DMT_ViewRenderer {

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }
        try {
            Map<String, Object> feature = new Map<String, Object>();
            Map<String, Object> profitability = new Map<String, Object>();
            List<Object> profitabilityResults = new List<Object>();

            if (data.featuresList != null && !data.featuresList.isEmpty()) {
                System.debug('Rendering Economics for Opportunity Id featuresList: ' + JSON.serialize(data.featuresList));
                feature = getProfitabilityFeature(data.featuresList);
                if (!feature.isEmpty() && feature.containsKey('profitability')) {
                    profitability = (Map<String, Object>)feature.get('profitability');
                    if (!profitability.isEmpty() && profitability.containsKey('results')) {
                        profitabilityResults = (List<Object>)profitability.get('results');
                    }
                }
            }

            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Economics</h2>'
                        + '</br>';
            html += buildHtmlEconomics(data, profitabilityResults)
                 + '</br></br>';

            return html;
        } catch (Exception e) {
            System.debug('Error in DMT_OppEconomicsRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String buildHtmlEconomics(DMT_ViewController.LineDataWrapper data, List<Object> profitabilityResults) {
        if (data == null || data.opportunity == null || data.opportunity.OpportunityLineItems.isEmpty()) {
            return '';
        }

        String html = '';
        List<OpportunityLineItem> allItems = data.opportunity.OpportunityLineItems;
        Integer totalItems = allItems.size();
        Integer batchSize = 4;

        List<String> orderedLabels = new List<String>{
            'Up-Front Fee Accrual', 'Up-Front Fee Non Accrual', 'Funding Cost', 'Liquidity Fee',
            'Applicable Margin', 'Pricing Grid or Step-ups (if applicable)', 'Commitment Fee',
            'Utilisation Fee', 'Extension/Duration Fee', 'Expected Drawn',
            'All-in: Drawn', 'All-in: Undrawn'
        };

        for (Integer startIndex = 0; startIndex < totalItems; startIndex += batchSize) {
            Integer endIndex = Math.min(startIndex + batchSize, totalItems);
            List<OpportunityLineItem> batchItems = new List<OpportunityLineItem>();
            for (Integer i = startIndex; i < endIndex; i++) {
                batchItems.add(allItems[i]);
            }

            html += '<table class="style-table" style="width:100%; border-collapse: collapse; margin-bottom: 20px; table-layout: fixed;">';

            // Header
            html += '<tr>';
            html += '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px; color: #777; width: 20%;"><i> Figures in bps </i></td>';
            for (OpportunityLineItem oli : batchItems) {
                String prodName = (oli.Product2 != null && oli.Product2.Name != null) ? oli.Product2.Name : 'Unknown Product';
                html += '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-weight: bold; font-size: 12px; text-align: center; width: 20%;"><strong>' + prodName + '</strong></td>';
            }
            Integer remainingSlots = batchSize - batchItems.size();
            for(Integer i = 0; i < remainingSlots; i++) {
                 html += '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #fff; width: 20%;">&nbsp;</td>';
            }
            html += '</tr>';

            // Data
            for (String label : orderedLabels) {
                html += '<tr>';
                html += '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-weight: bold;">' + label + '</td>';
                for (OpportunityLineItem oli : batchItems) {
                    String value = getValueForLabel(label, oli, profitabilityResults);
                    html += '<td style="padding: 8px; border-bottom: 1px solid #ccc; text-align: center; width: 20%">' + value + '</td>';
                }
                for(Integer i = 0; i < remainingSlots; i++) {
                     html += '<td style="padding: 8px; border-bottom: 1px solid #ccc;">&nbsp;</td>';
                }
                html += '</tr>';
            }
            html += '</table>';
        }
        return html + '&nbsp;</br>';
    }

    private String getValueForLabel(String label, OpportunityLineItem oli, List<Object> profitabilityResults) {
        Map<String, Object> productResult = new Map<String, Object>();
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
            when 'Pricing Grid or Step-ups (if applicable)' { return DMT_FormattingUtils.formatToTwoDecimals(oli.DMT_PricingGrid_OR_StepUps__c); }
            when 'Commitment Fee' { return DMT_FormattingUtils.formatToTwoDecimals(productResult.get('feesFbPbs')); }
            when 'Utilisation Fee' { return DMT_FormattingUtils.formatToTwoDecimals(productResult.get('feesDbPbs')); }
            when 'Extension/Duration Fee' { return DMT_FormattingUtils.formatToTwoDecimals(oli.DMT_Extension_Duration_Fees__c); }
            when 'Expected Drawn' { return DMT_FormattingUtils.formatToTwoDecimals(oli.DMT_Expected_Drawn__c); }
            when 'All-in: Drawn' { return DMT_FormattingUtils.formatToTwoDecimals(productResult.get('allInDb')); }
            when 'All-in: Undrawn' { return DMT_FormattingUtils.formatToTwoDecimals(productResult.get('allInFb')); }

            when else { return ''; }
        }
    }

    private static Map<String, Object> getProfitabilityFeature(List<Object> featuresList) {
        for (Object obj : featuresList) {
            Map<String, Object> feature = (Map<String, Object>)obj;
            if (feature != null && feature.containsKey('profitability')) {
                return feature;
            }
        }
        return new Map<String, Object>();
    }
}