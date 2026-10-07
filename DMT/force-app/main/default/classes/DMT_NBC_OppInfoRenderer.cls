public without sharing class DMT_NBC_OppInfoRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        Set<String> fields = new Set<String>();
        for (DMT_FormattingUtils.DisplayField df : buildRenderFields(new DMT_ViewController.LineDataWrapper())) {
            if (df.fieldApiNames != null) {
                fields.addAll(df.fieldApiNames);
            }
        }
        // These two might not render depending on Product Area, so both are tracked.
        fields.add('DMT_ContingentCommitments__c');
        fields.add('DMT_Structured_GTB__c');
        return new List<String>(fields);
    }

    // 1. HELPER: Build the list dynamically using the 'data' wrapper
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            // Row 1
            new DMT_FormattingUtils.DisplayField('Name', DMT_FormattingUtils.checkNull(data.opportunity.Name), new List<String>{'Name'}),
            new DMT_FormattingUtils.DisplayField('Entific', DMT_FormattingUtils.checkNull(data.opportunity.Entific__c + '-' + data.oppEntific), new List<String>{'Entific__c'}),

            // Booking Geography is a derived label - underlying source is DMT_branch_id_c__c.
            new DMT_FormattingUtils.DisplayField('Booking Geography', DMT_FormattingUtils.checkNull(data.oppBookingGeography), new List<String>{'DMT_branch_id_c__c'}),
            new DMT_FormattingUtils.DisplayField('Booking EFAN', DMT_FormattingUtils.checkNull(data.oppBookingEFAN), new List<String>{'DMT_Booking_EFAN__c'}),

            // Row 3
            new DMT_FormattingUtils.DisplayField('Opportunity Tenor', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Tenor__c), new List<String>{'DMT_Tenor__c'}),
            new DMT_FormattingUtils.DisplayField('Deal Amount', DMT_FormattingUtils.formatCurrencyAmount(data.opportunity.DMT_CUR_Notional_Amount__c == null ? 0.00 : data.opportunity.DMT_CUR_Notional_Amount__c, data.opportunity.DMT_CurrencyText__c), new List<String>{'DMT_CUR_Notional_Amount__c', 'DMT_CurrencyText__c'}),

            // Row 4
            new DMT_FormattingUtils.DisplayField('Currency', DMT_FormattingUtils.checkNull(data.opportunity.DMT_CurrencyText__c), new List<String>{'DMT_CurrencyText__c'}),
            new DMT_FormattingUtils.DisplayField('Capital Action', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Capital_Action__c), new List<String>{'DMT_Capital_Action__c'}),

            // Row 5
            new DMT_FormattingUtils.DisplayField('Product Area',  DMT_FormattingUtils.checkNull(data.opportunity.DMT_Product_Area__c), new List<String>{'DMT_Product_Area__c'}),
            data.opportunity.DMT_Product_Area__c == 'IB&F' ?
                new DMT_FormattingUtils.DisplayField('Contingent Commitments',  DMT_FormattingUtils.checkNull(data.opportunity.DMT_ContingentCommitments__c), new List<String>{'DMT_ContingentCommitments__c'})
                : (data.opportunity.DMT_Product_Area__c == 'GTB' ?
                    new DMT_FormattingUtils.DisplayField('Structured GTB', data.opportunity.DMT_Structured_GTB__c, new List<String>{'DMT_Structured_GTB__c'})
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

            // 1. Build the Top Section (Opportunity Info NBC) using the shared helper
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Opportunity Info NBC</h2>'
                + '<div class="slds-scope">'
                + DMT_FormattingUtils.generateHtmlTable(fieldsToRender)
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';

            return html;
        } catch (Exception e){
            System.debug('Error in DMT_NBC_OppInfoRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}