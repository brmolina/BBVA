public with sharing class DMT_OpportunityInfoRenderer implements DMT_ViewRenderer {

    // 1. HELPER: Build the list dynamically using the 'data' wrapper
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            // Row 1
            new DMT_FormattingUtils.DisplayField('Name', DMT_FormattingUtils.checkNull(data.opportunity.Name)),
            new DMT_FormattingUtils.DisplayField('Opportunity Id', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Opp_Id__c)),

            // Row 2 (Standardized to use the wrapper properties from your HTML method)
            new DMT_FormattingUtils.DisplayField('Entific', DMT_FormattingUtils.checkNull(data.opportunity.Entific__c + '-' + data.oppEntific)),
            new DMT_FormattingUtils.DisplayField('Entity', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Entity__c + '-' + data.oppEntity)),

            // Row 3
            new DMT_FormattingUtils.DisplayField('Booking Geography', DMT_FormattingUtils.checkNull(data.oppBookingGeography)),// TODO JAFE ADD VALUE TO THIS FIELD
            new DMT_FormattingUtils.DisplayField('Booking EFAN', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Booking_EFAN__c)),

            // Row 4
            new DMT_FormattingUtils.DisplayField('Opportunity Tenor', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Tenor__c)),

            // Row 4 (Standardized currency reference)
            new DMT_FormattingUtils.DisplayField('Opportunity BBVA commitment amount', DMT_FormattingUtils.formatCurrencyAmount(data.opportunity.DMT_CUR_Notional_Amount__c == null ? 0.00 : data.opportunity.DMT_CUR_Notional_Amount__c, data.opportunity.DMT_CurrencyText__c)),
            new DMT_FormattingUtils.DisplayField('Currency', DMT_FormattingUtils.checkNull(data.opportunity.DMT_CurrencyText__c)),

            // Row 5
            new DMT_FormattingUtils.DisplayField('Capital Action', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Capital_Action__c)),
            new DMT_FormattingUtils.DisplayField('Product Area',  DMT_FormattingUtils.checkNull(data.opportunity.DMT_Product_Area__c)), // TODO KV ADD VALUE TO THIS FIELD

            // Row 6
            new DMT_FormattingUtils.DisplayField('Opportunity Deal Amount',  DMT_FormattingUtils.formatCurrencyAmount(data.opportunity.DMT_Opportunity_amount__c == null ? 0.00 : data.opportunity.DMT_Opportunity_amount__c, data.opportunity.DMT_CurrencyText__c)),
            data.opportunity.DMT_Product_Area__c == 'IB&F' ?
                new DMT_FormattingUtils.DisplayField('Contingent Commitments',  DMT_FormattingUtils.checkNull(data.opportunity.DMT_ContingentCommitments__c))
                : (data.opportunity.DMT_Product_Area__c == 'GTB' ?
                    new DMT_FormattingUtils.DisplayField('Structured GTB', data.opportunity.DMT_Structured_GTB__c)
                    : new DMT_FormattingUtils.DisplayField('', ''))
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

            // 1. Build the Top Section (Opportunity Info) using the shared helper
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Opportunity Info</h2>'
                + '<div class="slds-scope">'
                + DMT_FormattingUtils.generateHtmlTable(fieldsToRender) // Replaces hardcoded tableRow2columns_New
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';

            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OpportunityInfoRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}