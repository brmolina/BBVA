public with sharing class DMT_OppInfoNBCRenderer implements DMT_ViewRenderer {

    // 1. HELPER: Build the list dynamically using the 'data' wrapper
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            // Row 1
            new DMT_FormattingUtils.DisplayField('Name', DMT_FormattingUtils.checkNull(data.opportunity.Name)),
            new DMT_FormattingUtils.DisplayField('Entific', DMT_FormattingUtils.checkNull(data.opportunity.Entific__c + '-' + data.oppEntific)),

            // Row 2
            new DMT_FormattingUtils.DisplayField('Booking Geography', DMT_FormattingUtils.checkNull(data.oppBookingGeography)),// TODO JAFE ADD VALUE TO THIS FIELD
            new DMT_FormattingUtils.DisplayField('Opportunity Tenor', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Tenor__c)),

            // Row 3
            new DMT_FormattingUtils.DisplayField('Deal Amount', DMT_FormattingUtils.formatCurrencyAmount(data.opportunity.DMT_CUR_Notional_Amount__c == null ? 0.00 : data.opportunity.DMT_CUR_Notional_Amount__c, data.opportunity.DMT_CurrencyText__c)),
            new DMT_FormattingUtils.DisplayField('Currency', DMT_FormattingUtils.checkNull(data.opportunity.DMT_CurrencyText__c)),

            // Row 4
            new DMT_FormattingUtils.DisplayField('Capital Action', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Capital_Action__c)),
            new DMT_FormattingUtils.DisplayField('Product Area',  DMT_FormattingUtils.checkNull(data.opportunity.DMT_Product_Area__c)), // TODO KV ADD VALUE TO THIS FIELD

            // Row 5
            data.opportunity.DMT_Product_Area__c == 'IB&F' ?
                new DMT_FormattingUtils.DisplayField('Contingent Commitments',  DMT_FormattingUtils.checkNull(data.opportunity.DMT_ContingentCommitments__c)) 
                : new DMT_FormattingUtils.DisplayField('', '') // Dynamic empty space to balance the 2-column grid // TODO KV ADD VALUE TO THIS FIELD
        };
    }

    // ==========================================
    // RENDER METHODS
    // ==========================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            Boolean underXSell = !data.opportunity.X_sell__r.isEmpty();

            // 1. Build the Top Section (Opportunity Info NBC) using the shared helper
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Opportunity Info NBC</h2>'
                + '<div class="slds-scope">'
                + DMT_FormattingUtils.generateHtmlTable(fieldsToRender) // Replaces hardcoded tableRow2columns_New
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';

            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OppInfoNBCRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return new Map<String, Object>();
        }

        try {
            Boolean underXSell = !data.opportunity.X_sell__r.isEmpty();

            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();

            // 1. Build the Top Section (Opportunity Info NBC)
            contentList.add(DMT_Create_Pdf_Controller.createTitle('Opportunity Info NBC'));

            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);
            contentList.add(DMT_Create_Pdf_Controller.generatePdfList(fieldsToRender)); // Shared utility replaces createListText

            // Page Break
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 30
            };
            contentList.add(pageBreak);

            component.put('content', contentList);
            component.put('name', 'Opportunity Info NBC');

            return component;
        } catch (Exception e) {
            System.debug('Error in DMT_OppInfoNBCRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_OppInfoNBCRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}