public without sharing class DMT_NBC_OppRisksRenderer_GTB implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - mirrors OppClientData's field reads below. Same two fields
    // DMT_OppApprovalProcessDataRenderer already tracks under 'Approval Process Data'. Folds
    // getTrackedFields() in under 'Opportunity' here too - see the identical note on the IB&F sibling.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Client__c' => new List<String>{
                'DMT_Financial_Program_limit__c', 'DMT_Asset_Allocation_limit__c'
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

            if (data.opportunity.DMT_Threshold_Type__c == 'Local') {
                return '';
            }

            OppClientData vals = new OppClientData(data);
            return renderGTBHtml(vals);

        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppRisksRenderer_GTB renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String renderGTBHtml(OppClientData vals) {
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