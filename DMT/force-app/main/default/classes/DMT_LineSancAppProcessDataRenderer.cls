public with sharing class DMT_LineSancAppProcessDataRenderer implements DMT_ViewRenderer {

    // ==========================================
    // HELPER: Build the DisplayField List
    // ==========================================
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            // Row 1 (Full Width text area)
            new DMT_FormattingUtils.DisplayField('Comments', DMT_FormattingUtils.checkNull(data.line.DMT_Comments__c), 'FULL')
        };
    }

    // ==========================================
    // HTML RENDERING
    // ==========================================
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Sanction Approval Process Data not provided</div>';
        }

        try {
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">APPROVAL PROCESS DATA</h2>'
                + '<div class="slds-scope">'
                + DMT_FormattingUtils.generateHtmlTable(fieldsToRender)
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';

            return html;

        } catch (Exception e){
            System.debug('Error in DMT_LineSancAppProcessDataRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
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
            contentList.add(DMT_Create_Pdf_Controller.createTitle('APPROVAL PROCESS DATA'));
            
            // 2. Generate the Dynamic List using the shared helper
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);
            contentList.add(DMT_Create_Pdf_Controller.generatePdfList(fieldsToRender));

            component.put('content', contentList);
            component.put('name', 'Sanction Approval Process Data');
            
            return component;

        } catch (Exception e){
            System.debug('Error in DMT_LineSancAppProcessDataRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_LineSancAppProcessDataRenderer', 'renderPdfJson', 'DMT', ''));
            return new Map<String, Object>();
        }
    }
}