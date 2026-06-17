public with sharing class DMT_OppRisksRenderer implements DMT_ViewRenderer {

    // ====================================================================================================
    // HELPER: Build the list dynamically using the data wrapper for 2-column fields ONLY
    // ====================================================================================================
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Asset Allocation Limit', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Asset_Allocation_limit__c)),
            new DMT_FormattingUtils.DisplayField('Financial Program Limit', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Financial_Program_limit__c))
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
            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Risks Info</h2>'
                        + '<div class="slds-scope">'
                        
                        // --- 2-COLUMN BLOCK ---
                        + DMT_FormattingUtils.generateHtmlTable(buildRenderFields(data))
                        
                    
                        
                        + '</div></div>'
                        + '<div style="margin-top: 20px;"></div>';

            return html;
            
        } catch (Exception e) {
            System.debug('Error in DMT_OppRisksRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
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
            contentList.add(DMT_Create_Pdf_Controller.createTitle('Risks Info'));

            // --- 2-COLUMN BLOCK ---
            contentList.add(DMT_Create_Pdf_Controller.generatePdfList(buildRenderFields(data)));
            
            
            component.put('content', contentList);
            
            // Map strictly to the custom metadata / component name
            component.put('name', 'Risks');

            System.debug('returning component: ' + JSON.serialize(component));
            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OppRisksRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_OppRisksRenderer', 'renderPdfJson', 'DMT', ''));
            return new Map<String, Object>();
        }
    }
}