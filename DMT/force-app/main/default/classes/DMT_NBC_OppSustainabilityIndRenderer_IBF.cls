public without sharing class DMT_NBC_OppSustainabilityIndRenderer_IBF implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_CalloutTrackableRenderer {

    // ====================================================================================================
    // DATA WRAPPER (centralizes values for HTML and PDF)
    // ====================================================================================================
    private class SustainabilityData {
        public String tri = '5';
        public String positioning = ' ';
        public String emissionsIntensity = ' ';
        public String groupEngagementPlan = ' ';
        public String engagementPlanLink = ' ';
        public String comments = ' ';

        public SustainabilityData(DMT_ViewController.LineDataWrapper data) {
            String productArea = data.opportunity.DMT_Product_Area__c;

            if (productArea == 'IB&F') {
                this.tri = DMT_FormattingUtils.checkNull(data.toolkitData.tri);
                this.positioning = DMT_FormattingUtils.checkNull(data.toolkitData.positioning);
                this.emissionsIntensity = DMT_FormattingUtils.checkNull(data.toolkitData.emissionIntensityMetric);
                this.groupEngagementPlan = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Group_Engagement_Plan__c);
                this.engagementPlanLink= DMT_FormattingUtils.checkNull(data.toolkitData.planLink );
                this.comments = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Comments__c);
            }
        }

    }

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - mirrors SustainabilityData's field reads (IB&F-only - see class comment).
    // Folds getTrackedFields() in under 'Opportunity' here too - DMT_ApprovalChangeStep_Handler
    // .resolveTrackedFieldsForItems uses getTrackedFieldsByObject() exclusively the instant it's
    // non-empty, never falling back to getTrackedFields() on its own, so this renderer has to
    // self-include its own switch fields to stay complete.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Client__c' => new List<String>{
                'DMT_Group_Engagement_Plan__c', 'DMT_comments__c'
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
                'NBC Sustainability Indicators', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            )
        };
    }

    public String getCalloutCacheKey(SObject record) {
        return record.Id;
    }

    // CIBGLOBALD-4117 - not a real HTTP callout: reuses this interface's generic derived-value diff
    // machinery because these 4 values are computed by the cstk managed package
    // (ComponentNBC_Controller.preloadToolkitInfo -> cstk.Toolkit_Service.getNbcInfo), confirmed
    // internal SOQL, not a live callout - see DMT_NBC_AssessmentRenderer.
    public Map<String, Object> fetchLiveTrackedValues(SObject record) {
        Map<String, Object> values = new Map<String, Object>();
        Opportunity opp = [
            SELECT AccountId, Account.DES_Client_Type__c, Account.DES_Main_Parent__c
            FROM Opportunity
            WHERE Id = :record.Id
        ];
        DES_Template__c toolkitTemplate = new DES_Template__c();
        ComponentNBC_Controller.preloadToolkitInfo(opp, toolkitTemplate);
        values.put('tri', toolkitTemplate.cstk_tri__c);
        values.put('positioning', toolkitTemplate.cstk_positioning__c);
        values.put('emissionIntensityMetric', toolkitTemplate.cstk_emissions_intensity_units__c);
        values.put('planLink', toolkitTemplate.cstk_portfolio_alignment_engagement_link__c);
        return values;
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

            SustainabilityData vals = new SustainabilityData(data);

            String html = '<div style="font-family: Arial, sans-serif; font-size: 11px; margin-bottom: 20px; page-break-inside: avoid;">'

                        + '<div style="color: #004481; font-size: 11px; font-weight: bold; margin-bottom: 15px;">'
                        + 'SUSTAINABILITY INDICATORS'
                        + '</div>'

                        + '<table style="width: 100%; border-collapse: collapse; table-layout: fixed; text-align: left; margin-bottom: 20px;">'
                        + '<colgroup>'
                        + '<col style="width: 25%;">'
                        + '<col style="width: 75%;">'
                        + '</colgroup>'
                        + '<tr>'
                        + '<td style="padding: 4px 6px 4px 0; border-bottom: 1px solid #004481; color: #004481; vertical-align: bottom;">TRI</td>'
                        + '<td style="padding: 4px 6px 4px 0; border-bottom: 1px solid #004481; color: #004481; vertical-align: bottom;">Positioning</td>'
                        + '</tr>'
                        + '<tr>'
                        + '<td style="padding: 6px 6px 6px 0; color: #004481; vertical-align: top;">' + vals.tri + '</td>'
                        + '<td style="padding: 6px 6px 6px 0; color: #004481; vertical-align: top;">' + vals.positioning + '</td>'
                        + '</tr>'
                        + '</table>'

                        + '<table style="width: 100%; border-collapse: collapse; table-layout: fixed; text-align: left; margin-bottom: 15px;">'
                        + '<colgroup>'
                        + '<col style="width: 33%;">'
                        + '<col style="width: 33%;">'
                        + '<col style="width: 34%;">'
                        + '</colgroup>'
                        + '<tr>'
                        + '<td style="padding: 4px 6px 4px 0; border-bottom: 1px solid #004481; color: #004481; vertical-align: bottom;">Emissions intensity</td>'
                        + '<td style="padding: 4px 6px 4px 0; border-bottom: 1px solid #004481; color: #004481; vertical-align: bottom;">Group Engagement Plan</td>'
                        + '<td style="padding: 4px 6px 4px 0; border-bottom: 1px solid #004481; color: #004481; vertical-align: bottom;">Engagement Plan Link</td>'
                        + '</tr>'
                        + '<tr>'
                        + '<td style="padding: 6px 6px 6px 0; color: #004481; vertical-align: top;">' + vals.emissionsIntensity + '</td>'
                        + '<td style="padding: 6px 6px 6px 0; color: #004481; vertical-align: top;">' + vals.groupEngagementPlan + '</td>'
                        + '<td style="padding: 6px 6px 6px 0; color: #004481; vertical-align: top;">' + vals.engagementPlanLink + '</td>'
                        + '</tr>'
                        + '</table>'

                        + '<div style="color: #004481; font-style: italic; margin-bottom: 5px;">'
                        + 'Comments'
                        + '</div>'
                        + '<div style="background-color: #f2f2f2; min-height: 60px; padding: 10px; font-size: 11px; color: #004481;">'
                        + vals.comments
                        + '</div>'

                        + '</div>';

            return html;

        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppSustainabilityIndRenderer_IBF renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }
}