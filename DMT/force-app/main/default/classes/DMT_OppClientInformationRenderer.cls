public with sharing class DMT_OppClientInformationRenderer implements DMT_ViewRenderer {

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

    // ====================================================================================================
    // PDF RENDERING
    // ====================================================================================================

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (
            data == null ||
            data.opportunity == null ||
            data.oppClient == null ||
            (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())
        ) {
            return new Map<String, Object>();
        }
        
        try {
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();
            String comparisonAccountName = data.oppAccountParentName;

            contentList.add(DMT_Create_Pdf_Controller.createTitle(
                'CLIENT INFORMATION' + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '')
            ));

            contentList.add(DMT_Create_Pdf_Controller.createListText(
                new List<String>{
                    'Geographical Footprint',
                    'Relationship Status',
                    'Industry Overview'
                },
                new List<String>{
                    DMT_FormattingUtils.checkNull(data.oppClient.Geographical_Footprint_desc__c),
                    DMT_FormattingUtils.checkNull(data.oppClient.Relationship_Status_desc__c),
                    DMT_FormattingUtils.checkNull(data.oppClient.Industry_Overview_desc__c)
                },
                'ONE'
            ));

            component.put('content', contentList);
            component.put('name', 'Client Information');

            System.debug('returning component: ' + JSON.serialize(component));
            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OppClientInformationRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(
                e.getMessage(),
                e.getStackTraceString(),
                e.getLineNumber(),
                e.getTypeName(),
                'DMT_OppClientInformationRenderer',
                'renderPdfJson',
                'DMT',
                ''
            ));
            return new Map<String, Object>();
        }
    }
}