public without sharing class DMT_OppClientInformationRenderer implements DMT_ViewRenderer {

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (
            data == null ||
            data.opportunity == null ||
            data.oppClient == null ||
            (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())
        ) {
            return '<div>Opportunity data not provided</div>';
        }
        
        try {
            String comparisonAccountName = data.oppAccountParentName;

            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">CLIENT INFORMATION' 
                        + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '') 
                        + '</h2>'
                        + '<div class="slds-scope">'
                        
                        + '<table class="style-table" style="width:100%; border-collapse: collapse;">'

                        + DMT_FormattingUtils.tableRow1column(
                            'Geographical Footprint',
                            DMT_FormattingUtils.checkNull(data.oppClient.Geographical_Footprint_desc__c)
                        )

                        + DMT_FormattingUtils.tableRow1column(
                            'Relationship Status',
                            DMT_FormattingUtils.checkNull(data.oppClient.Relationship_Status_desc__c)
                        )

                        + DMT_FormattingUtils.tableRow1column(
                            'Industry Overview',
                            DMT_FormattingUtils.checkNull(data.oppClient.Industry_Overview_desc__c)
                        )

                        + '</table>'
                        
                        + '</div></div>'
                        + '<div style="margin-top: 20px;"></div>';

            return html;
            
        } catch (Exception e) {
            System.debug('Error in DMT_OppClientInformationRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }
}