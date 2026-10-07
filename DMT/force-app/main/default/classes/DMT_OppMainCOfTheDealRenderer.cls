public without sharing class DMT_OppMainCOfTheDealRenderer implements DMT_ViewRenderer {

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }
        
        try {
            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Main Characteristics of the Deal</h2>'
                        + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                        + DMT_FormattingUtils.tableRow1columnWithHelper('1. Description and Issues', 'Brief description of the deal presented, main transactional features and changes vs former facility if any and key issues to be discussed (Max 617 characters)', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Description_Issues__c))
                        + DMT_FormattingUtils.tableRow1columnWithHelper('2. Purpose', 'Product/Banker\'s description of the use of funds of the facility/(ies) presented (Max 206 characters)', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Purpose__c))
                        + DMT_FormattingUtils.tableRow1columnWithHelper('3. Opportunities & Threats Related to the Deal', 'Banker\'s insight on the impact of this deal: advantages, opportunities and potential issues - external or internal - which may arise. (Max. 812 characters)', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Opp_Threats_Related_Deal__c))
                        + '</table>'
                        + '</div>'
                        + '<div style="margin-top: 20px;"></div>';

            return html;
            
        } catch (Exception e) {
            System.debug('Error in DMT_OppMainCOfTheDealRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }
}