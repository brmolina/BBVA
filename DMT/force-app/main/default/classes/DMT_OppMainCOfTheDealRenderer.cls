public with sharing class DMT_OppMainCOfTheDealRenderer implements DMT_ViewRenderer {

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
                        + DMT_FormattingUtils.tableRow1columnWithHelper('3. Opportunities & Threats Related to the Deal', 'Banker\'s insight on the impact of this deal: advantages, opportunities and potential issues - external or internal - which may arise. (Max. 103 characters/line)', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Opp_Threats_Related_Deal__c))
                        + '</table>'
                        + '</div>'
                        + '<div style="margin-top: 20px;"></div>';

            return html;
            
        } catch (Exception e) {
            System.debug('Error in DMT_OppMainCOfTheDealRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    // ====================================================================================================
    // PDF RENDERING
    // ====================================================================================================

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return new Map<String, Object>();
        }
        
        try {
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();

            // Promoted Main Title
            contentList.add(DMT_Create_Pdf_Controller.createTitle('MAIN CHARACTERISTICS OF THE DEAL'));

            contentList.add(createHelperTable('1. DESCRIPTION AND ISSUES', 'Brief description of the deal presented, main transactional features and changes vs former facility if any and key issues to be discussed (Max 617 characters)', data.oppClient.DMT_Description_Issues__c));
            contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });
            
            contentList.add(createHelperTable('2. PURPOSE', 'Product/Banker\'s description of the use of funds of the facility/(ies) presented (Max 206 characters)', data.oppClient.DMT_Purpose__c));
            contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });
            
            contentList.add(createHelperTable('3. OPPORTUNITIES & THREATS RELATED TO THE DEAL', 'Banker\'s insight on the impact of this deal: advantages, opportunities and potential issues - external or internal - which may arise. (Max. 103 characters/line)', data.oppClient.DMT_Opp_Threats_Related_Deal__c));

            component.put('content', contentList);
            component.put('name', 'Main Characteristics of the Deal');

            System.debug('returning component: ' + JSON.serialize(component));
            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OppMainCOfTheDealRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OppMainCOfTheDealRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }

    // ====================================================================================================
    // HELPER METHODS
    // ====================================================================================================

    private Map<String, Object> createHelperTable(String title, String helperText, String value) {
        List<List<Object>> head = new List<List<Object>>{ new List<Object>{title} };
        List<List<Object>> body = new List<List<Object>>{
            new List<Object>{ new Map<String,Object>{'content'=> helperText, 'styles'=>new Map<String,Object>{'fontSize'=>8,'textColor'=>'#666666','fontStyle'=>'italic'}} },
            new List<Object>{ DMT_FormattingUtils.checkNull(value) }
        };
        return DMT_Create_Pdf_Controller.createTableObj(head, body);
    }
}