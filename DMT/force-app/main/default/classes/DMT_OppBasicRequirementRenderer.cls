public with sharing class DMT_OppBasicRequirementRenderer implements DMT_ViewRenderer {

    private class ProfitabilityContext {
        Map<String, Object> summary = new Map<String, Object>();
        String rorcThresholdText = '';
        String raroecThresholdText = '';
    }

    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        ProfitabilityContext profitabilityContext = getProfitabilityContext(data);
        List<DMT_FormattingUtils.DisplayField> fields = new List<DMT_FormattingUtils.DisplayField>();

        if (!profitabilityContext.summary.isEmpty()) {
            fields.add(new DMT_FormattingUtils.DisplayField('Deal RORC', formatProfitabilityMetric(profitabilityContext.summary.get('rorc'), profitabilityContext.rorcThresholdText)));
            fields.add(new DMT_FormattingUtils.DisplayField('Deal RAROEC', formatProfitabilityMetric(profitabilityContext.summary.get('raroec'), profitabilityContext.raroecThresholdText)));
            fields.add(new DMT_FormattingUtils.DisplayField('RORC Prospective CDD', DMT_FormattingUtils.formatPercent(profitabilityContext.summary.get('rorcProspected'))));
        }
        fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_ClientsGlobalRorcLastFY_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_CDD_Clients_Global_Rorc_Last_FY__c))); // Client CDD Avge 6m
        fields.add(new DMT_FormattingUtils.DisplayField('Client RORC YTD', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_RORC_YTD__c))); // Client RORC YTD
        fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_ClientsGlobalRORCCIBPastFY_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Clients_Global_RORC_CIB_Past_FY__c))); //Client Rorc Last FY
        if (!profitabilityContext.summary.isEmpty()) {
            fields.add(new DMT_FormattingUtils.DisplayField('Global Expected RORC', DMT_FormattingUtils.formatPercent(profitabilityContext.summary.get('clientRorc'))));
            fields.add(new DMT_FormattingUtils.DisplayField('Deal Revenues Next 12m', DMT_FormattingUtils.formatProfitabilityDecimal(profitabilityContext.summary.get('incomes12months'), 2)));
        }

        fields.add(new DMT_FormattingUtils.DisplayField('Exception Pool', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Exception_Pool__c)));
        fields.add(new DMT_FormattingUtils.DisplayField('Other Relevant Deals', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Other_Relevant_Issues__c), 'FULL'));

        return fields;
    }

    private ProfitabilityContext getProfitabilityContext(DMT_ViewController.LineDataWrapper data) {
        ProfitabilityContext context = new ProfitabilityContext();
        if (data == null || data.featuresList == null || data.featuresList.isEmpty()) {
            return context;
        }

        Map<String, Object> feature;
        for (Map<String, Object> item : data.featuresList) {
            if (item != null && item.containsKey('profitability') && item.get('profitability') != null) {
                feature = item;
                break;
            }
        }

        if (feature == null) {
            return context;
        }

        Map<String, Object> profitability = (Map<String, Object>) feature.get('profitability');
        Map<String, Object> audit = profitability.containsKey('audit') && profitability.get('audit') != null ? (Map<String, Object>) profitability.get('audit') : new Map<String, Object>();
        context.rorcThresholdText = formatThresholdPercent(audit.get('rorcThreshold'));
        context.raroecThresholdText = formatThresholdPercent(audit.get('raroecThreshold'));

        List<Object> results = profitability.containsKey('results') ? (List<Object>) profitability.get('results') : null;
        if (results == null || results.isEmpty()) {
            return context;
        }

        for (Object rec : results) {
            Map<String, Object> summary = (Map<String, Object>) rec;
            if (!summary.containsKey('productId') || summary.get('productId') == null) {
                context.summary = summary;
                break;
            }
        }

        return context;
    }

    private String formatProfitabilityMetric(Object value, String thresholdText) {
        String formattedValue = DMT_FormattingUtils.formatPercent(value);
        return String.isBlank(thresholdText) ? formattedValue : formattedValue + ' < ' + thresholdText;
    }

    private String formatThresholdPercent(Object value) {
        if (value == null) {
            return '';
        }

        try {
            return DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(value)));
        } catch (Exception e) {
            return '';
        }
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity == null || data.oppClient == null ||
            (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Basic Profitability Metrics</h2>'
                        + '<div class="slds-scope">'
                        + DMT_FormattingUtils.generateHtmlTable(fieldsToRender)
                        + '</div></div>&nbsp;</br>';

            return html;

        } catch (Exception e) {
            System.debug('Error in DMT_OppBasicRequirementRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity == null || data.oppClient == null ||
            (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return new Map<String, Object>();
        }

        try {
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();

            contentList.add(DMT_Create_Pdf_Controller.createTitle('Basic Profitability Metrics'));

            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);
            contentList.add(DMT_Create_Pdf_Controller.generatePdfList(fieldsToRender));

            component.put('content', contentList);
            component.put('name', 'Basic Profitability Metrics');

            System.debug('returning component: ' + JSON.serialize(component));
            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OppBasicRequirementRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_OppBasicRequirementRenderer', 'renderPdfJson', 'DMT', ''));
            return new Map<String, Object>();
        }
    }
}