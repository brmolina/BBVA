public without sharing class DMT_NBC_OppRisksRenderer_IBF implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - mirrors OppClientData's field reads below. Same two fields
    // DMT_OppApprovalProcessDataRenderer already tracks under 'Approval Process Data'. Folds
    // getTrackedFields() in under 'Opportunity' here too - DMT_ApprovalChangeStep_Handler
    // .resolveTrackedFieldsForItems uses getTrackedFieldsByObject() exclusively the instant it's
    // non-empty, never falling back to getTrackedFields() on its own, so this renderer has to
    // self-include its own switch fields to stay complete.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Client__c' => new List<String>{
                'DMT_Financial_Program_limit__c', 'DMT_Asset_Allocation_limit__c'
            }
        };
    }

    public List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record) {
        return new List<DMT_ApprovalChangeStep_Helper.ChildSection>{
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'NBC Risk', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            )
        };
    }

    // ====================================================================================================
    // DATA WRAPPER (centralizes values)
    // ====================================================================================================
    private class OppClientData {

        public String financialLimit;
        public String assetLimit;

        public OppClientData(DMT_ViewController.LineDataWrapper data) {
            this.financialLimit = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Financial_Program_limit__c);
            this.assetLimit     = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Asset_Allocation_limit__c);
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

            OppClientData vals = new OppClientData(data);
            return renderIBFHtml(vals);

        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppRisksRenderer_IBF renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String renderIBFHtml(OppClientData vals) {
        return '<div style="font-family: Arial, sans-serif; font-size: 9px; color: #004481; margin-bottom: 0px; page-break-inside: avoid;">'
             + '<h3 style="font-size: 12px; color: #004481; margin-bottom: -2px; font-weight: bold;">Risk</h3>'

             + '<table style="width: 100%; border-collapse: collapse; table-layout: fixed; text-align: left;">'
             + '<colgroup>'
             + '<col style="width: 50%;">'
             + '<col style="width: 50%;">'
             + '</colgroup>'

             + '<tr>'
             + '<td style="padding: 1px 1px; border-bottom: 1px solid #004481; font-weight: normal; color: #004481; vertical-align: bottom;">Financial Program</td>'
             + '<td style="padding: 1px 1px; border-bottom: 1px solid #004481; font-weight: normal; color: #004481; vertical-align: bottom;">Asset Allocation</td>'
             + '</tr>'

             + '<tr>'
             + '<td style="padding: 0.2px; vertical-align: top;">' + vals.financialLimit + '</td>'
             + '<td style="padding: 0.2px; vertical-align: top;">' + vals.assetLimit + '</td>'
             + '</tr>'

             + '</table>'
             + '</div>';
    }
}