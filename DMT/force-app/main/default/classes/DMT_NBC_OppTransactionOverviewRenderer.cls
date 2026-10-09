public without sharing class DMT_NBC_OppTransactionOverviewRenderer implements DMT_ViewRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_CalloutTrackableRenderer {

    // CIBGLOBALD-4117 - mirrors buildHtmlTransactionOverview/getValueForLabel's OpportunityLineItem
    // reads below. Per-product profitability (averageLife/rorc/raroec) comes from featuresList and is
    // tracked separately via DMT_CalloutTrackableRenderer (see fetchLiveTrackedValues below). Shares
    // the opportunityLineItems section key with NBC Deal, which reads mostly the same object.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'OpportunityLineItem' => new List<String>{
                'Product2.Name', 'Product2.CurrencyIsoCode', 'CurrencyIsoCode', 'DMT_Deal_Amount_Tenors__c',
                'DMT_ExpectedFinal_Take__c', 'DMT_NewMoney_BBVA__c', 'DMT_OldMoney_BBVA__c',
                'gf_group_priority_opportunity_id__c'
            }
        };
    }

    // CIBGLOBALD-4117 - ChildSection(componentName, snapshotSectionKey, childObjectApiName,
    // childLookupField, parentValueField[, orderBy]):
    //   componentName       - this component's display name, matching its DMT_Items__c row;
    //                         shows up in logs/labels, not used for lookups.
    //   snapshotSectionKey  - the key this section's rows are stored under in the frozen JSON
    //                         snapshot. Shared across every component that reads the same child
    //                         object under the same key - fields from all of them get queried and
    //                         compared together, so add/remove fields on the OBJECT's
    //                         getTrackedFieldsByObject() map, never invent a new key for one field.
    //   childObjectApiName  - the SObject to query for this section's rows. Must match a key in
    //                         this renderer's own getTrackedFieldsByObject() map, or nothing gets
    //                         queried/compared for it.
    //   childLookupField    - the field ON childObjectApiName that points back to the parent record.
    //   parentValueField    - the field ON THE PARENT (Opportunity/Line) whose value is matched
    //                         against childLookupField - almost always 'Id'; a different value here
    //                         means an extra hop (see Custom_Association_Client__c's hand-written
    //                         special case in DMT_ApprovalChangeStep_Handler for why that one isn't
    //                         generic).
    //   orderBy (optional)  - ORDER BY clause for the child query, when row order matters for the
    //                         comparison.
    public List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record) {
        return new List<DMT_ApprovalChangeStep_Helper.ChildSection>{
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'NBC Transaction Overview', 'opportunityLineItems', 'OpportunityLineItem',
                'OpportunityId', 'Id'
            )
        };
    }

    public String getCalloutCacheKey(SObject record) {
        return record.Id;
    }

    // CIBGLOBALD-4117 - not a real HTTP callout: reuses this interface's generic derived-value diff
    // machinery, same reason as DMT_NBC_DealRenderer. Per-product, keyed 'productId:metric'.
    public Map<String, Object> fetchLiveTrackedValues(SObject record) {
        Map<String, Object> values = new Map<String, Object>();
        Set<String> productIds = new Set<String>();
        for (OpportunityLineItem oli : [
            SELECT gf_group_priority_opportunity_id__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :record.Id AND gf_group_priority_opportunity_id__c != null
        ]) {
            productIds.add(oli.gf_group_priority_opportunity_id__c);
        }
        if (productIds.isEmpty()) {
            return values;
        }

        for (Map<String, Object> feature : DMT_ViewController.getFeatures(record.Id)) {
            if (feature == null || feature.get('profitability') == null) {
                continue;
            }
            Map<String, Object> profitability = (Map<String, Object>) feature.get('profitability');
            List<Object> results = (List<Object>) profitability.get('results');
            if (results == null) {
                continue;
            }
            for (Object resultObj : results) {
                Map<String, Object> row = (Map<String, Object>) resultObj;
                String productId = (String) row.get('productId');
                if (productId == null || !productIds.contains(productId)) {
                    continue;
                }
                values.put(productId + ':averageLife', row.get('averageLife'));
                values.put(productId + ':rorc', row.get('rorc'));
                values.put(productId + ':raroec', row.get('raroec'));
            }
            break;
        }
        return values;
    }

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
                System.debug('Rendering Transaction Overview for Opportunity Id featuresList: ' + JSON.serialize(data.featuresList));
                feature = getProfitabilityFeature(data.featuresList);
                if (!feature.isEmpty() && feature.containsKey('profitability')) {
                    profitability = (Map<String, Object>)feature.get('profitability');
                    if (!profitability.isEmpty() && profitability.containsKey('results')) {
                        profitabilityResults = (List<Object>)profitability.get('results');
                    }
                }
            }

            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Transaction Overview</h2>'
                        + '</br>';
            html += buildHtmlTransactionOverview(data, profitabilityResults)
                 + '</br></br>';

            return html;
        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppTransactionOverviewRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String buildHtmlTransactionOverview(DMT_ViewController.LineDataWrapper data, List<Object> profitabilityResults) {
        if (data == null || data.opportunity == null || data.opportunity.OpportunityLineItems.isEmpty()) {
            return '';
        }

        String html = '';
        List<OpportunityLineItem> allItems = data.opportunity.OpportunityLineItems;
        Integer totalItems = allItems.size();
        Integer batchSize = 4;

        List<String> orderedLabels = new List<String>{
            'Currency', 'BBVA Commitment',
            'Expected Final Take', 'New Money for BBVA', 'Old Money for BBVA',
            'Tenor', 'Average Life', 'RORC / RAROEC'
        };

        html += '<style>.dmt-transaction-overview td.dmt-value-right, .dmt-transaction-overview td.dmt-value-right * { text-align: right !important; }</style>';

        for (Integer startIndex = 0; startIndex < totalItems; startIndex += batchSize) {
            Integer endIndex = Math.min(startIndex + batchSize, totalItems);
            List<OpportunityLineItem> batchItems = new List<OpportunityLineItem>();
            for (Integer i = startIndex; i < endIndex; i++) {
                batchItems.add(allItems[i]);
            }

            html += '<table class="dmt-transaction-overview style-table" style="width:100%; border-collapse: collapse; margin-bottom: -17px; table-layout: fixed;">';

            // Header
            html += '<tr>';
            html += '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px; color: #777; width: 20%;"><i> Figures in Mn </i></td>';
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
                    html += '<td class="dmt-value-right" align="right" style="padding: 8px; border-bottom: 1px solid #ccc; text-align: right !important; width: 20%">' + value + '</td>';
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
            when 'Currency' { return (oli.Product2 != null && oli.Product2.CurrencyIsoCode != null) ? oli.Product2.CurrencyIsoCode : oli.CurrencyIsoCode; }
            when 'BBVA Commitment' { return DMT_FormattingUtils.formatWithoutDecimals(oli.DMT_Deal_Amount_Tenors__c); }
            when 'Expected Final Take' { return DMT_FormattingUtils.formatWithoutDecimals(oli.DMT_ExpectedFinal_Take__c); }
            when 'New Money for BBVA' { return DMT_FormattingUtils.formatWithoutDecimals(oli.DMT_NewMoney_BBVA__c); }
            when 'Old Money for BBVA' { return DMT_FormattingUtils.formatWithoutDecimals(oli.DMT_OldMoney_BBVA__c); }
            when 'Tenor' { return DMT_FormattingUtils.checkNull(productResult.get('averageLife')); }
            when 'Average Life' { return DMT_FormattingUtils.checkNull(productResult.get('averageLife')); }
            when 'RORC / RAROEC' {
                if(!productResult.isEmpty()){
                    return DMT_FormattingUtils.formatPercent(productResult.get('rorc')) + ' / ' + DMT_FormattingUtils.formatPercent(productResult.get('raroec'));
                } else {
                    return '';
                }
            }
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