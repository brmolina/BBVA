public without sharing class DMT_NBC_OppClientTierRenderer_IBF implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - mirrors ClientBusinessPlanData's field reads below. These are the same
    // fields DMT_OppApprovalProcessDataRenderer already tracks under 'Approval Process Data' -
    // declared again here under this component's own name so it's tracked on views that don't also
    // carry Approval Process Data. DMT_Booking_Geography__c is the discriminator findGlobalBPRecord
    // uses to pick the GLOBAL row - not displayed by value, but changing it changes which row wins.
    // Folds getTrackedFields() in under 'Opportunity' here too -
    // DMT_ApprovalChangeStep_Handler.resolveTrackedFieldsForItems uses getTrackedFieldsByObject()
    // exclusively the instant it's non-empty, never falling back to getTrackedFields() on its own,
    // so this renderer has to self-include its own switch fields to stay complete.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Client__c' => new List<String>{
                'Geographical_Footprint_desc__c', 'Relationship_Status_desc__c', 'Industry_Overview_desc__c'
            },
            'DMT_Opportunity_Business_Plan__c' => new List<String>{
                'DMT_QAOTER__c', 'DMT_Booking_Geography__c'
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
                'NBC Client Information', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'NBC Client Information', 'opportunityBusinessPlan', 'DMT_Opportunity_Business_Plan__c',
                'DMT_Opportunity__c', 'Id'
            )
        };
    }

    // ====================================================================================================
    // DATA WRAPPER (centralizes values)
    // ====================================================================================================
    private class ClientBusinessPlanData {
        public String geoFootprint = '';
        public String relationshipStatus = '';
        public String industryOverview = '';
        public String businessPlan = '';

        public ClientBusinessPlanData(DMT_ViewController.LineDataWrapper data) {
            this.geoFootprint = DMT_FormattingUtils.toSafeMultilineHtml(DMT_FormattingUtils.checkNull(data.oppClient.Geographical_Footprint_desc__c));
            this.relationshipStatus = DMT_FormattingUtils.toSafeMultilineHtml(DMT_FormattingUtils.checkNull(data.oppClient.Relationship_Status_desc__c));
            this.industryOverview = DMT_FormattingUtils.toSafeMultilineHtml(DMT_FormattingUtils.checkNull(data.oppClient.Industry_Overview_desc__c));

            DMT_Opportunity_Business_Plan__c globalBpRecord = findGlobalBPRecord(data.businessPlanRecords);
            this.businessPlan = (globalBpRecord != null) ? DMT_FormattingUtils.toSafeMultilineHtml(DMT_FormattingUtils.checkNull(globalBpRecord.DMT_QAOTER__c)) : '';
        }

        private DMT_Opportunity_Business_Plan__c findGlobalBPRecord(List<DMT_Opportunity_Business_Plan__c> records) {
            if (records == null || records.isEmpty()) {
                return null;
            }
            for (DMT_Opportunity_Business_Plan__c rec : records) {
                if (rec.DMT_Booking_Geography__c == 'GLOBAL') {
                    return rec;
                }
            }
            return records[0];
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

            return renderIBFHtml(data);

        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppClientTierRenderer_IBF renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String renderIBFHtml(DMT_ViewController.LineDataWrapper data) {
        ClientBusinessPlanData vals = new ClientBusinessPlanData(data);

        String descGeo = 'Banker\'s insight on client\'s presence and our geographical matching. Description of our capabilities in the countries where we are present and weight of the countries where we lack of presence in client\'s revenues/sales/EBITDA.';
        String descRel = 'Banker\'s feedback on the status of our relationship: evolution since onboarding, strengths, weakness, opportunities in the short term';
        String descInd = 'Industry Head/Banker brief opinion on key drivers of client\'s sector. Opportunities & Threats, acquisition movements, strategic actions (sale/ buy of business division) impact of market risks and BBVA position in this sector';
        String descBus = 'Explanation of the business plan figures presented by country and product. Includes a description of the future opportunities when relevant, the competition expected and an indication of the potential incremental revenues included';

        String html = '<div style="font-family: Arial, sans-serif; font-size: 11px; margin-bottom: 20px; page-break-inside: avoid;">'

                    + '<div style="background-color: #1a62a5; color: #ffffff; padding: 6px 10px; font-size: 12px; font-weight: bold; text-transform: uppercase; margin-bottom: 15px;">'
                    + 'CLIENT & BUSINESS PLAN'
                    + '</div>'

                    + '<div style="color: #004481; font-size: 12px; font-weight: bold; margin-bottom: 20px; text-transform: uppercase;">'
                    + 'CLIENT INFORMATION'
                    + '</div>'

                    + generateBoxSection('GEOGRAPHICAL FOOTPRINT*', null, descGeo, vals.geoFootprint)

                    + generateBoxSection('RELATIONSHIP STATUS*', null, descRel, vals.relationshipStatus)

                    + generateBoxSection('INDUSTRY OVERVIEW*', null, descInd, vals.industryOverview)

                    + generateBoxSection('BUSINESS PLAN', 'Qualitative Assessment of the estimated revenues', descBus, vals.businessPlan)

                    + '</div>';

        return html;
    }

    // ====================================================================================================
    // HELPER — GRAY BOX SECTIONS
    // ====================================================================================================
    private String generateBoxSection(String title, String subtitle, String description, String value) {
        String displayValue = String.isBlank(value) ? '&nbsp;' : value;

        String html = '<div style="margin-bottom: 25px;">';

        html += '<div style="color: #004481; font-size: 11px; font-weight: bold; margin-bottom: 4px;">' + title + '</div>';

        if (String.isNotBlank(subtitle)) {
            html += '<div style="color: #004481; font-size: 11px; font-weight: bold; margin-bottom: 4px;">' + subtitle + '</div>';
        }

        if (String.isNotBlank(description)) {
            html += '<div style="color: #888888; font-size: 10px; font-style: italic; margin-bottom: 8px;">' + description + '</div>';
        }

        html += '<div style="background-color: #f2f2f2; min-height: 50px; padding: 10px; font-size: 11px; color: #004481; white-space: normal; word-wrap: break-word; overflow-wrap: anywhere; word-break: break-word;">' + displayValue + '</div>';

        html += '</div>';

        return html;
    }
}