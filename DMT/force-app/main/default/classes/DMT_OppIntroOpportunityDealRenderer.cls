public with sharing class DMT_OppIntroOpportunityDealRenderer implements DMT_ViewRenderer {

    // ====================================================================================================
    // HELPER: Build the list dynamically using the data wrapper
    // ====================================================================================================
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            // Row 1
            new DMT_FormattingUtils.DisplayField('Commitment Deadline', DMT_FormattingUtils.changeDateFormat(data.oppClient.DMT_Commitment_Deadline__c)),
            new DMT_FormattingUtils.DisplayField('Exception Pool', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Exception_Pool__c))
        };
    }

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }
        
        try {
            // 1. Build the Top Section (Standard Fields) using the shared helper
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Intro Opportunity Deal</h2>'
                        
                        // Commitment Deadline & Exception Pool
                        + '<div class="slds-scope">'
                        + DMT_FormattingUtils.generateHtmlTable(fieldsToRender)
                        + '</div></br>'
                        
                        // Tiering Action Table
                        + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                        + '<tr>'
                        + '<td style="width: 60%; padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Tiering Action</strong></td>'
                        + '<td style="width: 20%; padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;">Current</td>'
                        + '<td style="width: 20%; padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;">Target</td>'
                        + '</tr>'
                        + '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; ">'+DMT_FormattingUtils.checkNull(data.oppClient.DMT_Tiering_Action__c)+'</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: smaller;">'+DMT_FormattingUtils.checkNull(data.oppClient.DMT_Current__c)+'</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: smaller;">'+DMT_FormattingUtils.checkNull(data.oppClient.DMT_Target__c)+'</td>'
                        + '</tr>'
                        + '</table></div>&nbsp;</br>';

            return html;
            
        } catch (Exception e) {
            System.debug('Error in DMT_OppIntroOpportunityDealRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
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
            contentList.add(DMT_Create_Pdf_Controller.createTitle('Intro Opportunity Deal'));

            // Commitment Deadline & Exception Pool
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);
            contentList.add(DMT_Create_Pdf_Controller.generatePdfList(fieldsToRender));
            
            // Tiering Action Table
            List<List<String>> tierHead = new List<List<String>>{ new List<String>{'Tiering Action', 'Current', 'Target'} };
            List<List<String>> tierBody = new List<List<String>>{
                new List<String>{
                    DMT_FormattingUtils.checkNull(data.oppClient.DMT_Tiering_Action__c),
                    DMT_FormattingUtils.checkNull(data.oppClient.DMT_Current__c),
                    DMT_FormattingUtils.checkNull(data.oppClient.DMT_Target__c)}
            };
            contentList.add(DMT_Create_Pdf_Controller.createTable(tierHead, tierBody));

            component.put('content', contentList);
            component.put('name', 'Intro Opportunity Deal');

            System.debug('returning component: ' + JSON.serialize(component));
            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OppIntroOpportunityDealRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_OppIntroOpportunityDealRenderer', 'renderPdfJson', 'DMT', ''));
            return new Map<String, Object>();
        }
    }
}