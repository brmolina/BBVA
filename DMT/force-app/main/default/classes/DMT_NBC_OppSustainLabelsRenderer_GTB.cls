public without sharing class DMT_NBC_OppSustainLabelsRenderer_GTB implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - same field set as the IB&F variant (see its own comment) - GTB reads the
    // identical OpportunityLineItem fields, just under a different section title. Folds
    // getTrackedFields() in under 'Opportunity' here too - see the identical note on the IB&F sibling.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'OpportunityLineItem' => new List<String>{
                'DMT_sustainable_deal_assessment__c', 'DMT_Sustainable_Deal_Subtype__c',
                'DMT_sustainable_deal_value__c', 'DMT_Sustainability_deal_value_criteria__c',
                'DMT_PER_Sustainability_Percentage__c', 'DMT_Sustainability_bonus_eligible__c'
            }
        };
    }

    // CIBGLOBALD-4117 - ChildSection(componentName, snapshotSectionKey, childObjectApiName,
    // childLookupField, parentValueField[, orderBy]):
    //   componentName       - this component's display name, matching its DMT_Items__c row;
    //                         shows up in logs/labels, not used for lookups.
    //   snapshotSectionKey  - the key this section's rows are stored under in the frozen JSON
    //                         snapshot. Shared across every component that reads the same child
    //                         object under the same key - fields from all of them get queried and
    //                         compared together, so add/remove fields on the OBJECT's
    //                         getTrackedFieldsByObject() map, never invent a new key for one field.
    //   childObjectApiName  - the SObject to query for this section's rows. Must match a key in
    //                         this renderer's own getTrackedFieldsByObject() map, or nothing gets
    //                         queried/compared for it.
    //   childLookupField    - the field ON childObjectApiName that points back to the parent record.
    //   parentValueField    - the field ON THE PARENT (Opportunity/Line) whose value is matched
    //                         against childLookupField - almost always 'Id'; a different value here
    //                         means an extra hop (see Custom_Association_Client__c's hand-written
    //                         special case in DMT_ApprovalChangeStep_Handler for why that one isn't
    //                         generic).
    //   orderBy (optional)  - ORDER BY clause for the child query, when row order matters for the
    //                         comparison.
    public List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record) {
        return new List<DMT_ApprovalChangeStep_Helper.ChildSection>{
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'NBC Sustainability Labels', 'opportunityLineItems', 'OpportunityLineItem',
                'OpportunityId', 'Id'
            )
        };
    }

    // ====================================================================================================
    // DATA WRAPPER (centralizes values for HTML and PDF)
    // ====================================================================================================
    private class LabelsData {
        public String assessment = '';
        public String subcategory = '';
        public String greenFilter = '';
        public String dealLabel = '';
        public String percentage = '';
        public String bonusEligible = '';

        public LabelsData(DMT_ViewController.LineDataWrapper data) {
            DMT_ViewController.OpportunityProduct selectedProduct = null;
            if (data != null && data.oppProducts != null) {
                for (DMT_ViewController.OpportunityProduct candidate : data.oppProducts) {
                    if (candidate != null && (
                        String.isNotBlank(candidate.sustainableDealAssessment) ||
                        String.isNotBlank(candidate.sustainableDealSubtype) ||
                        String.isNotBlank(candidate.greenActivityFilter) ||
                        String.isNotBlank(candidate.sustainableDealLabel) ||
                        candidate.sustainablePercentage != null ||
                        candidate.sustainabilityBonusEligible != null
                    )) {
                        selectedProduct = candidate;
                        break;
                    }
                }
            }

            if (selectedProduct == null) {
                return;
            }

            String assessPickLabel = Util_Picklist.getLabelFromAPI('OpportunityLineItem', 'DMT_sustainable_deal_assessment__c').get(selectedProduct.sustainableDealAssessment);
            String subtypePickLabel = Util_Picklist.getLabelFromAPI('OpportunityLineItem', 'DMT_Sustainable_Deal_Subtype__c').get(selectedProduct.sustainableDealSubtype);

            assessPickLabel = assessPickLabel != null ? assessPickLabel : selectedProduct.sustainableDealAssessment;
            subtypePickLabel = subtypePickLabel != null ? subtypePickLabel : selectedProduct.sustainableDealSubtype;

            String greenFilterLabel = '';
            if (selectedProduct.greenActivityFilter == 'delegated') {
                greenFilterLabel = 'Delegated Label';
            } else if (selectedProduct.greenActivityFilter == 'other') {
                greenFilterLabel = 'Other Green Activity';
            } else {
                greenFilterLabel = selectedProduct.greenActivityFilter;
            }

            String productDealLabel = selectedProduct.sustainableDealLabel;

            this.assessment = DMT_FormattingUtils.checkNull(assessPickLabel);
            this.subcategory = DMT_FormattingUtils.checkNull(subtypePickLabel);
            this.greenFilter = DMT_FormattingUtils.checkNull(greenFilterLabel);
            this.dealLabel = DMT_FormattingUtils.checkNull(productDealLabel);
            this.percentage = DMT_FormattingUtils.checkNull(selectedProduct.sustainablePercentage);
            this.bonusEligible = DMT_FormattingUtils.checkNull(selectedProduct.sustainabilityBonusEligible);
        }
    }

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }

            return buildLabelsHtml(data, 'TRANSACTION');

        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppSustainLabelsRenderer_GTB renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String buildLabelsHtml(DMT_ViewController.LineDataWrapper data, String title) {
        LabelsData vals = new LabelsData(data);

        String html = '<div style="font-family: Arial, sans-serif; font-size: 11px; margin-bottom: 20px; page-break-inside: avoid;">'

                    + '<div style="color: #004481; font-size: 11px; font-weight: bold; margin-bottom: 20px;">'
                    + title
                    + '</div>'

                    + generateTableHtml('Sustainable Deal Assessment', vals.assessment, 'Sustainable Deal Subcategory', vals.subcategory)

                    + '</div>';

        return html;
    }

    private String generateTableHtml(String header1, String val1, String header2, String val2) {
        String displayVal1 = String.isBlank(val1) ? '&nbsp;' : val1;
        String displayVal2 = String.isBlank(val2) ? '&nbsp;' : val2;

        return '<table style="width: 100%; border-collapse: collapse; table-layout: fixed; text-align: left; margin-bottom: 20px;">'
             + '<colgroup>'
             + '<col style="width: 50%;">'
             + '<col style="width: 50%;">'
             + '</colgroup>'
             + '<tr>'
             + '<td style="padding: 4px 6px 4px 0; border-bottom: 1px solid #004481; color: #004481; vertical-align: bottom;">' + header1 + '</td>'
             + '<td style="padding: 4px 6px 4px 0; border-bottom: 1px solid #004481; color: #004481; vertical-align: bottom;">' + header2 + '</td>'
             + '</tr>'
             + '<tr>'
             + '<td style="padding: 6px 6px 6px 0; vertical-align: top; color: #004481;">' + displayVal1 + '</td>'
             + '<td style="padding: 6px 6px 6px 0; vertical-align: top; color: #004481;">' + displayVal2 + '</td>'
             + '</tr>'
             + '</table>';
    }
}