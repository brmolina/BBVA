public with sharing class DMT_OppTransactionOverviewRenderer implements DMT_ViewRenderer {

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
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">TRANSACTION OVERVIEW</h2>'
                        + '</br>';
            html += buildHtmlTransactionOverview(data, profitabilityResults)
                 + '</br></br>';

            return html;
        } catch (Exception e) {
            System.debug('Error in DMT_OppTransactionOverviewRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
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
            'Exected Final Take', 'New Money for BBVA', 'Old Money for BBVA',
            'Tenor', 'Average Life', 'RORC / RAROEC'
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
                if (jsonProductId == oli.Id) {
                    productResult = mapRec;
                    break;
                }
            }
        }
        switch on label {
            when 'Currency' { return (oli.Product2 != null && oli.Product2.CurrencyIsoCode != null) ? oli.Product2.CurrencyIsoCode : oli.CurrencyIsoCode; }
            when 'BBVA Commitment' { return DMT_FormattingUtils.checkNull(oli.DMT_Deal_Amount_Tenors__c); }
            when 'Exected Final Take' { return DMT_FormattingUtils.checkNull(oli.DMT_ExpectedFinal_Take__c); }
            when 'New Money for BBVA' { return DMT_FormattingUtils.checkNull(oli.DMT_NewMoney_BBVA__c); }
            when 'Old Money for BBVA' { return DMT_FormattingUtils.checkNull(oli.DMT_OldMoney_BBVA__c); }
            when 'Tenor' { return DMT_FormattingUtils.checkNull(oli.DES_Tenor_years__c); }
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

    // ====================================================================================================
    // PDF RENDERING
    // ====================================================================================================

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return new Map<String, Object>();
        }
        try {
            Map<String, Object> feature = new Map<String, Object>();
            Map<String, Object> profitability = new Map<String, Object>();
            List<Object> profitabilityResults = new List<Object>();

            if (data.featuresList != null && !data.featuresList.isEmpty()) {
                feature = getProfitabilityFeature(data.featuresList);
                if (!feature.isEmpty() && feature.containsKey('profitability')) {
                    profitability = (Map<String, Object>)feature.get('profitability');
                    if (!profitability.isEmpty() && profitability.containsKey('results')) {
                        profitabilityResults = (List<Object>)profitability.get('results');
                    }
                }
            }

            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();

            contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 60 });
            contentList.add(DMT_Create_Pdf_Controller.createTitle('TRANSACTION OVERVIEW'));

            contentList.addAll(buildPdfTransactionOverview(data, profitabilityResults));

            component.put('content', contentList);
            component.put('name', 'Transaction Overview');

            System.debug('returning component: ' + JSON.serialize(component));
            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OppTransactionOverviewRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OppTransactionOverviewRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }

    private List<Object> buildPdfTransactionOverview(DMT_ViewController.LineDataWrapper data, List<Object> profitabilityResults) {
        List<Object> result = new List<Object>();

        if (data == null || data.opportunity == null || data.opportunity.OpportunityLineItems.isEmpty()) {
            return result;
        }

        List<OpportunityLineItem> allItems = data.opportunity.OpportunityLineItems;
        Integer totalItems = allItems.size();
        Integer batchSize = 4;

        List<String> orderedLabels = new List<String>{
            'Currency', 'BBVA Commitment',
            'Exected Final Take', 'New Money for BBVA', 'Old Money for BBVA',
            'Tenor', 'Average Life', 'RORC / RAROEC'
        };

        // Reuse the border style object
        Map<String, Object> borderStyle = new Map<String, Object>{
            'bottom' => 0.1
        };

        for (Integer startIndex = 0; startIndex < totalItems; startIndex += batchSize) {
             Integer endIndex = Math.min(startIndex + batchSize, totalItems);

             List<OpportunityLineItem> batchItems = new List<OpportunityLineItem>();
             for (Integer i = startIndex; i < endIndex; i++) {
                batchItems.add(allItems[i]);
             }

             // -----------------------------------------------------------
             // BUILD CUSTOM STYLED HEADER
             // -----------------------------------------------------------
             List<Object> headerRow = new List<Object>();

             // 1. Figures in Mn
             headerRow.add(new Map<String, Object>{
                 'content' => 'Figures in Mn',
                 'styles' => new Map<String, Object>{
                     'fillColor' => new List<Integer>{255, 255, 255},
                     'textColor' => new List<Integer>{119, 119, 119},
                     'fontStyle' => 'italic',
                     'fontSize' => 7,
                     'halign' => 'left',
                     'lineWidth' => borderStyle
                 }
             });

             // 2. Products
             for (OpportunityLineItem oli : batchItems) {
                 String prodName = (oli.Product2 != null && oli.Product2.Name != null) ? oli.Product2.Name : 'Unknown Product';
                 headerRow.add(new Map<String, Object>{
                     'content' => prodName,
                     'styles' => new Map<String, Object>{
                         'fillColor' => new List<Integer>{255, 255, 255},
                         'textColor' => new List<Integer>{0, 0, 0},
                         'fontStyle' => 'bold',
                         'fontSize' => 8,
                         'halign' => 'center',
                         'lineWidth' => borderStyle
                     }
                 });
             }

             // 3. Filler slots
             Integer remainingSlots = batchSize - batchItems.size();
             for(Integer i = 0; i < remainingSlots; i++) {
                 headerRow.add(new Map<String, Object>{
                     'content' => '',
                     'styles' => new Map<String, Object>{
                         'fillColor' => new List<Integer>{255, 255, 255},
                         'lineWidth' => borderStyle
                     }
                 });
             }

             List<List<Object>> pdfHead = new List<List<Object>>{headerRow};

             // -----------------------------------------------------------
             // BUILD ROWS
             // -----------------------------------------------------------
             List<List<Object>> pdfRows = new List<List<Object>>();

             for(String label : orderedLabels) {
                 List<Object> row = new List<Object>();

                 // Label
                 row.add(new Map<String, Object>{
                     'content' => label,
                     'styles' => new Map<String, Object>{
                         'lineWidth' => borderStyle,
                         'fontSize' => 8
                     }
                 });

                 // Values
                 for (OpportunityLineItem oli : batchItems) {
                     String val = getValueForLabel(label, oli, profitabilityResults);
                     // Center align values with border
                     row.add(new Map<String, Object>{
                         'content' => val,
                         'styles' => new Map<String, Object>{
                             'halign' => 'center',
                             'lineWidth' => borderStyle
                         }
                     });
                 }

                 // Fillers
                 for(Integer i = 0; i < remainingSlots; i++) {
                     row.add(new Map<String, Object>{
                         'content' => '',
                         'styles' => new Map<String, Object>{
                             'lineWidth' => borderStyle
                         }
                     });
                 }
                 pdfRows.add(row);
             }

             result.add(DMT_Create_Pdf_Controller.createTableObj(pdfHead, pdfRows));

             if (endIndex < totalItems) {
                 result.add(new Map<String, Object>{ 'type' => 'text', 'text' => ' ' });
             }
        }
        return result;
    }
}