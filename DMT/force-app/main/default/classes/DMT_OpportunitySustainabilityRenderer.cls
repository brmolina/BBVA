public with sharing class DMT_OpportunitySustainabilityRenderer implements DMT_ViewRenderer {

    private List<DMT_FormattingUtils.DisplayField> buildSustainabilityFields(DMT_ViewController.OpportunityProduct oppProduct) {
        String assessPickLabel = Util_Picklist.getLabelFromAPI('OpportunityLineItem','DMT_sustainable_deal_assessment__c').get(oppProduct.sustainableDealAssessment);

        String subtypePickLabel = Util_Picklist.getLabelFromAPI('OpportunityLineItem','DMT_Sustainable_Deal_Subtype__c').get(oppProduct.sustainableDealSubtype);
        
        assessPickLabel = assessPickLabel != null ? assessPickLabel : oppProduct.sustainableDealAssessment;
        subtypePickLabel = subtypePickLabel != null ? subtypePickLabel : oppProduct.sustainableDealSubtype;

        String greenFilterLabel = '';
        if (oppProduct.greenActivityFilter == 'delegated') {
            greenFilterLabel = 'Delegated Label';
        } else if (oppProduct.greenActivityFilter == 'other') {
            greenFilterLabel = 'Other Green Activity';
        } else {
            greenFilterLabel = oppProduct.greenActivityFilter;
        }

        String dealLabel = oppProduct.sustainableDealLabel; 

        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Sustainable Deal Assessment', DMT_FormattingUtils.checkNull(assessPickLabel)),
            new DMT_FormattingUtils.DisplayField('Sustainable Deal Subcategory', DMT_FormattingUtils.checkNull(subtypePickLabel)),
            new DMT_FormattingUtils.DisplayField('Green Activity Filter', DMT_FormattingUtils.checkNull(greenFilterLabel)),
            new DMT_FormattingUtils.DisplayField('Sustainable Deal Label', DMT_FormattingUtils.checkNull(dealLabel)),
            new DMT_FormattingUtils.DisplayField('Sustainability Percentage (%)', DMT_FormattingUtils.checkNull(oppProduct.sustainablePercentage)),
            new DMT_FormattingUtils.DisplayField('Sustainability bonus-eligible', DMT_FormattingUtils.checkNull(oppProduct.sustainabilityBonusEligible))
        };
    }

    private Boolean hasSustainabilityData(DMT_ViewController.OpportunityProduct oppProduct) {
        return oppProduct != null && (
            String.isNotBlank(oppProduct.sustainableDealAssessment) ||
            String.isNotBlank(oppProduct.sustainableDealSubtype) ||
            String.isNotBlank(oppProduct.greenActivityFilter) ||
            String.isNotBlank(oppProduct.sustainableDealLabel) ||
            oppProduct.sustainablePercentage != null ||
            oppProduct.sustainabilityBonusEligible != null
        );
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.oppProducts == null || data.oppProducts.isEmpty()) {
            return '<div>Sustainability data not provided</div>';
        }

        try {
            String htmlOutput = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Sustainability</h2>';

            Boolean hasRenderedData = false;

            for (DMT_ViewController.OpportunityProduct oppProduct : data.oppProducts) {
                if (!hasSustainabilityData(oppProduct)) {
                    continue;
                }

                hasRenderedData = true;

                if (String.isNotBlank(oppProduct.name)) {
                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">'
                        + DMT_FormattingUtils.checkNull(oppProduct.name)
                        + '</h3>';
                }

                htmlOutput += '<div class="slds-scope">'
                    + DMT_FormattingUtils.generateHtmlTable(buildSustainabilityFields(oppProduct))
                    + '</div>&nbsp;</br>';
            }

            if (!hasRenderedData) {
                return '<div>Sustainability data not provided</div>';
            }

            return htmlOutput + '</div>';

        } catch (Exception e) {
            System.debug('Error in DMT_OpportunitySustainabilityRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        Map<String, Object> component = new Map<String, Object>();

        if (data == null || data.oppProducts == null || data.oppProducts.isEmpty()) {
            return component;
        }

        try {
            List<Object> contentList = new List<Object>();
            contentList.add(DMT_Create_Pdf_Controller.createTitle('Sustainability'));

            Boolean hasRenderedData = false;

            for (DMT_ViewController.OpportunityProduct oppProduct : data.oppProducts) {
                if (!hasSustainabilityData(oppProduct)) {
                    continue;
                }

                hasRenderedData = true;

                if (String.isNotBlank(oppProduct.name)) {
                    contentList.add(new Map<String, Object>{
                        'type' => 'text',
                        'text' => DMT_FormattingUtils.checkNull(oppProduct.name),
                        'style' => new Map<String, Object>{
                            'fontSize' => 14,
                            'textColor' => '#004481'
                        }
                    });
                }

                contentList.add(DMT_Create_Pdf_Controller.generatePdfList(
                    buildSustainabilityFields(oppProduct)
                ));
            }

            if (!hasRenderedData) {
                return component;
            }

            component.put('content', contentList);
            component.put('name', 'Sustainability');

            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OpportunitySustainabilityRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(
                e.getMessage(),
                e.getStackTraceString(),
                e.getLineNumber(),
                e.getTypeName(),
                'DMT_OpportunitySustainabilityRenderer',
                'renderPdfJson',
                'DMT',
                ''
            ));
            return component;
        }
    }
}