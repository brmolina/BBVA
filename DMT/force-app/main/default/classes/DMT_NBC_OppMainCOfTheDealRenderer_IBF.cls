public without sharing class DMT_NBC_OppMainCOfTheDealRenderer_IBF implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - mirrors OppClientData's own field reads below, so the two can't drift apart.
    // Folds getTrackedFields() in under 'Opportunity' here too - DMT_ApprovalChangeStep_Handler
    // .resolveTrackedFieldsForItems uses getTrackedFieldsByObject() exclusively the instant it's
    // non-empty, never falling back to getTrackedFields() on its own, so this renderer has to
    // self-include its own switch fields to stay complete.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Client__c' => new List<String>{
                'DMT_Current__c', 'DMT_Tiering_Action__c', 'DMT_Target__c',
                'DMT_Description_Issues__c', 'DMT_Purpose__c', 'DMT_Opp_Threats_Related_Deal__c'
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
                'NBC Main Characteristics of the Deal', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            )
        };
    }

    // ====================================================================================================
    // DATA WRAPPER (centralizes values)
    // ====================================================================================================
    private class OppClientData {

        public String currentTier;
        public String tieringAction;
        public String targetTier;
        public String descriptionIssues;
        public String purpose;
        public String oppThreats;

        public OppClientData(DMT_ViewController.LineDataWrapper data) {
            this.currentTier       = data.oppClient.DMT_Current__c != null ? String.valueOf(data.oppClient.DMT_Current__c) : 'No change';
            this.tieringAction     = data.oppClient.DMT_Tiering_Action__c != null ? String.valueOf(data.oppClient.DMT_Tiering_Action__c) : 'No change';
            this.targetTier        = data.oppClient.DMT_Target__c != null ? String.valueOf(data.oppClient.DMT_Target__c) : 'No change';
            this.descriptionIssues = DMT_FormattingUtils.toSafeMultilineHtml(DMT_FormattingUtils.checkNull(data.oppClient.DMT_Description_Issues__c));
            this.purpose           = DMT_FormattingUtils.toSafeMultilineHtml(DMT_FormattingUtils.checkNull(data.oppClient.DMT_Purpose__c));
            this.oppThreats        = DMT_FormattingUtils.toSafeMultilineHtml(DMT_FormattingUtils.checkNull(data.oppClient.DMT_Opp_Threats_Related_Deal__c));
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
            System.debug('Error in DMT_NBC_OppMainCOfTheDealRenderer_IBF renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String renderIBFHtml(OppClientData vals) {
        return '<div style="font-family: Arial, sans-serif; color: #333333; font-size: 9px; width: 100%; box-sizing: border-box;">'

            + '<table style="width: 100%; border-collapse: collapse; margin-bottom: 10px; border: none; table-layout: fixed;">'
            + '  <tr>'
            + '    <td colspan="6" style="vertical-align: middle; text-align: left; border: none; padding-bottom: 8px;">'
            + '      <h2 style="font-size: 8pt; color: #004481; margin: 0; padding: 0; font-weight: bold; text-transform: uppercase;">MAIN CHARACTERISTICS OF THE DEAL*</h2>'
            + '    </td>'
            + '  </tr>'
            + '  <tr>'
            + '    <td style="width: 18%; vertical-align: middle; text-align: left; border: none; font-size: 8px; color: #004481;">'
            + '      Current Tier'
            + '    </td>'
            + '    <td style="width: 15%; vertical-align: middle; text-align: left; border: none;">'
            + '      <span style="display: block; border: 1px solid #004481; padding: 0px 8px; font-weight: normal; background-color: #ffffff; color: #004481;">' + vals.currentTier + '</span>'
            + '    </td>'
            + '    <td style="width: 18%; vertical-align: middle; text-align: right; border: none; font-size: 8px; color: #004481; padding-right: 10px;">'
            + '      Tiering Action'
            + '    </td>'
            + '    <td style="width: 15%; vertical-align: middle; text-align: left; border: none;">'
            + '      <span style="display: block; border: 1px solid #004481; padding: 0px 8px; font-weight: normal; background-color: #ffffff; color: #004481;">' + vals.tieringAction + '</span>'
            + '    </td>'
            + '    <td style="width: 18%; vertical-align: middle; text-align: right; border: none; font-size: 8px; color: #004481; padding-right: 10px;">'
            + '      Target tier'
            + '    </td>'
            + '    <td style="width: 16%; vertical-align: middle; text-align: left; border: none;">'
            + '      <span style="display: block; border: 1px solid #004481; padding: 0px 8px; font-weight: normal; background-color: #ffffff; color: #004481;">' + vals.targetTier + '</span>'
            + '    </td>'
            + '  </tr>'
            + '</table>'

            + '<div style="margin-bottom: 8px; page-break-inside: avoid;">'
            + '  <h2 style="font-size: 8pt; color: #004481; margin: 0 0 -0.5px 0; font-weight: bold; text-transform: uppercase;">DESCRIPTION OF THE DEAL*</h2>'
            + '  <div style="font-size: 7px; color: #888888; font-style: italic; margin-bottom: 1px;">Brief description of the deal presented, main transactional features and changes vs former</div>'
            + '  <div style="border: 1px solid #cccccc; padding: 3px; background-color: #ffffff; min-height: 10px; text-align: justify; line-height: 1.4; color: #004481; white-space: normal; word-wrap: break-word; overflow-wrap: anywhere; word-break: break-word;">'
            +      vals.descriptionIssues
            + '  </div>'
            + '</div>'

            + '<div style="margin-bottom: 8px; page-break-inside: avoid;">'
            + '  <h2 style="font-size: 8pt; color: #004481; margin: 0 0 -0.5px 0; font-weight: bold; text-transform: uppercase;">PURPOSE*</h2>'
            + '  <div style="font-size: 7px; color: #888888; font-style: italic; margin-bottom: 1px;">Product/Banker\'s description of the use of funds of the facility/(ies) presented</div>'
            + '  <div style="border: 1px solid #cccccc; padding: 3px; background-color: #ffffff; min-height: 10px; line-height: 1.4; color: #004481; white-space: normal; word-wrap: break-word; overflow-wrap: anywhere; word-break: break-word;">'
            +      vals.purpose
            + '  </div>'
            + '</div>'

            + '<div style="margin-bottom: 8px; page-break-inside: avoid;">'
            + '  <h2 style="font-size: 8pt; color: #004481; margin: 0 0 -0.5px 0; font-weight: bold; text-transform: uppercase;">OPPORTUNITIES & THREATS RELATED TO THE DEAL*</h2>'
            + '  <div style="font-size: 7px; color: #888888; font-style: italic; margin-bottom: 1px;">Banker\'s insight on the impact of this deal: advantages, opportunities and potential issues - external or internal - which may arise.</div>'
            + '  <div style="border: 1px solid #cccccc; padding: 3px; background-color: #ffffff; min-height: 10px; line-height: 1.4; color: #004481; white-space: normal; word-wrap: break-word; overflow-wrap: anywhere; word-break: break-word;">'
            +      vals.oppThreats
            + '  </div>'
            + '</div>'

            + '</div>';
    }
}