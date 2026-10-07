/**
 * @description Renderer for the IB&F Requirements and Risks section.
 */
public without sharing class DMT_NBC_OppRequirementsRenderer_IBF implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - mirrors RequirementsData's field reads below. Folds getTrackedFields() in
    // under 'Opportunity' here too - DMT_ApprovalChangeStep_Handler.resolveTrackedFieldsForItems
    // uses getTrackedFieldsByObject() exclusively the instant it's non-empty, never falling back to
    // getTrackedFields() on its own, so this renderer has to self-include its own switch fields to
    // stay complete.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Client__c' => new List<String>{
                'DMT_Rating_Scenarios__c', 'DMT_Financial_Program_limit__c', 'DMT_Asset_Allocation_limit__c',
                'DMT_AA_Industry__c', 'DMT_Top_3_Active_Facilities__c'
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
                'NBC Requirements', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            )
        };
    }

    // ====================================================================================================
    // DATA WRAPPER (centralizes values for HTML and PDF)
    // ====================================================================================================
    /**
     * @description Centralized data used by HTML and PDF rendering.
     */
    private class RequirementsData {
        /** @description Scenario text value. */
        public String scenariosText = ' ';

        /** @description Financial program limit value. */
        public String financialLimit = ' ';

        /** @description Asset allocation limit value. */
        public String assetLimit = ' ';

        /** @description AA industry value. */
        public String aaIndustry = ' ';

        /** @description Top 3 Active Facilities value. */
        public String top3ActiveFacilities = ' ';

        /**
         * @description Builds the centralized values for the renderer.
         * @param data Line data wrapper used by the renderer.
         */
        public RequirementsData(DMT_ViewController.LineDataWrapper data) {
            if (data == null) {
                return;
            }

            this.scenariosText = '';
            if (data.oppClient != null) {
                this.scenariosText = DMT_FormattingUtils.toSafeMultilineHtml(DMT_FormattingUtils.checkNull(data.oppClient.DMT_Rating_Scenarios__c));
            }

            this.financialLimit = ' ';
            if (data.oppClient != null) {
                this.financialLimit = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Financial_Program_limit__c);
            }
            if (String.isBlank(this.financialLimit)) {
                this.financialLimit = ' ';
            }

            this.assetLimit = ' ';
            if (data.oppClient != null) {
                this.assetLimit = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Asset_Allocation_limit__c);
            }
            if (String.isBlank(this.assetLimit)) {
                this.assetLimit = ' ';
            }
            this.aaIndustry = '';
            if (String.isBlank(this.aaIndustry)) {
                this.aaIndustry = DMT_FormattingUtils.checkNull(data.oppClient.DMT_AA_Industry__c);
            }

            this.top3ActiveFacilities = ' ';
            if (data.oppClient != null) {
                this.top3ActiveFacilities = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Top_3_Active_Facilities__c);
            }
            if (String.isBlank(this.top3ActiveFacilities)) {
                this.top3ActiveFacilities = ' ';
            }
        }
    }

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    /**
     * @description Builds the HTML for the IB&F Requirements and Risks section.
     * @param data Line data wrapper used by the renderer.
     * @return HTML string.
     */
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity == null || data.oppClient == null) {
            return '<div>Opportunity data not provided</div>';
        }

        if (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }

            RequirementsData vals = new RequirementsData(data);

            String html = '<div style="font-family: Arial, sans-serif; font-size: 11px; margin-bottom: 20px; page-break-inside: avoid;">'

                        // BLUE BAR: REQUIREMENTS
                        + '<div style="background-color: #1a62a5; color: #ffffff; padding: 6px 10px; font-size: 12px; font-weight: bold; text-transform: uppercase; margin-bottom: 15px;">'
                        + 'REQUIREMENTS'
                        + '</div>'

                        // SECTION: SCENARIOS
                        + '<div style="color: #004481; font-size: 11px; font-weight: bold; margin-bottom: 5px;">'
                        + 'Profitability Scenario'
                        + '</div>'
                        + '<div style="background-color: #f2f2f2; min-height: 60px; padding: 10px; font-size: 11px; color: #004481; margin-bottom: 15px; white-space: normal; word-wrap: break-word; overflow-wrap: anywhere; word-break: break-word;">'
                        +  vals.scenariosText
                        + '</div>'

                        // SECTION: 10. RISKS
                        + '<div style="color: #004481; font-size: 11px; font-weight: bold; margin-bottom: 8px;">'
                        + 'RISKS*'
                        + '</div>'

                        // Spaced table
                        + '<table style="width: 100%; border-collapse: separate; border-spacing: 0 3px; table-layout: fixed;">'
                        + '<colgroup>'
                        + '<col style="width: 35%;">'
                        + '<col style="width: 65%;">'
                        + '</colgroup>'
                        + '<tr>'
                        + '<td style="color: #004481; padding: 6px 10px 6px 20px; vertical-align: middle;">AA Industry</td>'
                        + '<td style="background-color: #f2f2f2; color: #004481; padding: 6px 10px; vertical-align: middle; white-space: normal; word-wrap: break-word; overflow-wrap: anywhere; word-break: break-word;">' + vals.aaIndustry + '</td>'
                        + '</tr>'
                        + '<tr>'
                        + '<td style="color: #004481; padding: 6px 10px 6px 20px; vertical-align: middle;">Asset Allocation limit</td>'
                        + '<td style="background-color: #f2f2f2; color: #004481; padding: 6px 10px; vertical-align: middle; white-space: normal; word-wrap: break-word; overflow-wrap: anywhere; word-break: break-word;">' + vals.assetLimit + '</td>'
                        + '</tr>'
                        + '<tr>'
                        + '<td style="color: #004481; padding: 6px 10px 6px 20px; vertical-align: middle;">Financial Program limit</td>'
                        + '<td style="background-color: #f2f2f2; color: #004481; padding: 6px 10px; vertical-align: middle; white-space: normal; word-wrap: break-word; overflow-wrap: anywhere; word-break: break-word;">' + vals.financialLimit + '</td>'
                        + '</tr>'
                        + '<tr>'
                        + '<td style="color: #004481; padding: 6px 10px 6px 20px; vertical-align: middle;">Top 3 Active Facilities</td>'
                        + '<td style="background-color: #f2f2f2; color: #004481; padding: 6px 10px; vertical-align: middle; white-space: normal; word-wrap: break-word; overflow-wrap: anywhere; word-break: break-word;">' + vals.top3ActiveFacilities + '</td>'
                        + '</tr>'
                        + '</table>'
                        + '</div>';

            return html;
        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppRequirementsRenderer_IBF renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }
}