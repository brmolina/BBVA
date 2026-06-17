public with sharing class DMT_OppClientTierRenderer implements DMT_ViewRenderer {

    // ====================================================================================================
    // HELPER: Build the list dynamically using the data wrapper for 2-column fields ONLY
    // ====================================================================================================
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Tiering Action', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Tiering_Action__c)),
            new DMT_FormattingUtils.DisplayField('Current Tier', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Current__c)),
            new DMT_FormattingUtils.DisplayField('Target Tier', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Target__c))
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
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">CLIENT TIER</h2>'
                        + '<div class="slds-scope">'
                        + DMT_FormattingUtils.generateHtmlTable(fieldsToRender)
                        + '</div></div>&nbsp;</br>';

            return html;

        } catch (Exception e) {
            System.debug('Error in DMT_OppClientTierRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
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

            contentList.add(DMT_Create_Pdf_Controller.createTitle('CLIENT TIER'));

            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);
            contentList.add(DMT_Create_Pdf_Controller.generatePdfList(fieldsToRender));

            component.put('content', contentList);
            component.put('name', 'Client Tier');

            System.debug('returning component: ' + JSON.serialize(component));
            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OppClientTierRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OppClientTierRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}