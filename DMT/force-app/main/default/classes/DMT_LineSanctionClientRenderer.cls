public with sharing class DMT_LineSanctionClientRenderer implements DMT_ViewRenderer {

    // ==========================================
    // HELPER: Build the DisplayField List
    // ==========================================
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            // Row 1
            new DMT_FormattingUtils.DisplayField('Client', DMT_FormattingUtils.checkNull(data.line.Client__r?.Name)),
            new DMT_FormattingUtils.DisplayField('Client Type', DMT_FormattingUtils.checkNull(data.line.Client_Type__c)),

            // Row 2
            new DMT_FormattingUtils.DisplayField('Local Client', DMT_FormattingUtils.checkNull(data.line.DMT_LocalClient__r?.Name)),
            new DMT_FormattingUtils.DisplayField('', '') // Empty space to balance the 2-column grid
        };
    }

    // ==========================================
    // HTML RENDERING
    // ==========================================
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Sanction Client data not provided</div>';
        }

        try {
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Client</h2>'
                + '<div class="slds-scope">'
                + DMT_FormattingUtils.generateHtmlTable(fieldsToRender)
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';

            return html;

        } catch (Exception e){
            System.debug('Error in DMT_LineSanctionClientRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    // ==========================================
    // PDF RENDERING
    // ==========================================
    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return new Map<String, Object>();
        }

        try {
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>(); 
            
            // 1. Create Title
            contentList.add(DMT_Create_Pdf_Controller.createTitle('Client'));
            
            // 2. Generate the Dynamic List
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);
            contentList.add(DMT_Create_Pdf_Controller.generatePdfList(fieldsToRender));

            component.put('content', contentList);
            component.put('name', 'Sanction Client');
            
            return component;

        } catch (Exception e){
            System.debug('Error in DMT_LineSanctionClientRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_LineSanctionClientRenderer', 'renderPdfJson', 'DMT', ''));
            return new Map<String, Object>();
        }
    }
}