public without sharing class DMT_OppCommercialProcessDataRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer {
    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    // At the moment this only renders CloseDate. The other Commercial Process Data fields (DES_*,
    // gf_*, OpportunityLineItem margin/fee fields) are edited through the separate
    // DMT_CommercialProcessDataController form, which signals
    // Passport__c.DMT_Is_Obsoleted_Passport_Save__c directly on save - not part of this
    // approval-task watch list.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{ 'CloseDate' };
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Error: Opportunity data not provided</div>';
        }
        if (data.opportunity.CloseDate == null) {
            // at the moment this renderer displays only Estimated Closing Date, so if it's not provided, we don't render anything
            return '<div>Error: Opportunity Close Date not provided</div>'; 
        }
         try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            String html = '<div>'
            + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Commercial Process Data</h2>'
            + '</div>';

            List<DMT_FormattingUtils.DisplayField> fieldsToRender = new List<DMT_FormattingUtils.DisplayField>{
                new DMT_FormattingUtils.DisplayField('Estimated Closing Date', DMT_FormattingUtils.checkNull(data.opportunity.CloseDate))
            };

            html += '<div class="slds-scope">'
                + DMT_FormattingUtils.generateHtmlTable(fieldsToRender)
                + '</div>'
                + '</br></br>';

            return html;
        } catch (Exception e){
            //System.debug('Error in DMT_OppCommercialProcessDataRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}