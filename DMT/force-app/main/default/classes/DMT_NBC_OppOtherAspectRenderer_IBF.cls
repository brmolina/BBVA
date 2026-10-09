/**
 * Renderer for NBC Opportunity Other Aspect section (IB&F). Shared data-prep and table-building
 * logic live in DMT_NBC_OtherAspectRendererHelper.
 */
public without sharing class DMT_NBC_OppOtherAspectRenderer_IBF implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - mirrors OtherAspectData's field reads and the active (non-commented-out)
    // HTML builders below. The featuresList-based profitability computation
    // (cddStandaloneRorcRaroec/cddClientGlobalRorc) is never actually rendered by any active branch
    // here - only by the commented-out buildHtmlGTBAdditionalTable - so it's not tracked, same as the
    // dead code already documented on DMT_OppApprovalProcessDataRenderer/DMT_NBC_EconomicsRendererHelper.
    // Global Structure and Banking Pool Structure fields are the same ones
    // DMT_OppApprovalProcessDataRenderer already tracks under 'Approval Process Data'. Folds
    // getTrackedFields() in under 'Opportunity' here too - DMT_ApprovalChangeStep_Handler
    // .resolveTrackedFieldsForItems uses getTrackedFieldsByObject() exclusively the instant it's
    // non-empty, never falling back to getTrackedFields() on its own, so this renderer has to
    // self-include its own switch fields to stay complete.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Client__c' => new List<String>{
                'DMT_Applicable_Jurisdiction__c', 'DMT_Security_Package__c', 'DMT_Rating_Scenarios__c',
                'DMT_Other_Relevant_Issues__c', 'DMT_Competition_Deal__c'
            },
            'DMT_Global_Structure__c' => new List<String>{'Name', 'DMT_Type__c', 'DMT_Funds__c'},
            'DMT_Banking_Pool_Structure__c' => new List<String>{
                'Name', 'DMT_Ticket__c', 'DMT_Fees__c', 'DMT_Margin__c', 'DMT_N_Banks__c'
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
                'NBC Other Aspects', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'NBC Other Aspects', 'opportunityGlobalStructure', 'DMT_Global_Structure__c',
                'DMT_Opportunity__c', 'Id'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'NBC Other Aspects', 'opportunityBankingPoolStructure', 'DMT_Banking_Pool_Structure__c',
                'DMT_Opportunity__c', 'Id'
            )
        };
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }

            DMT_NBC_OtherAspectRendererHelper.OtherAspectData vals = new DMT_NBC_OtherAspectRendererHelper.OtherAspectData(data);
            String sMainHeader = 'background-color: #004481; color: #ffffff; font-size: 14px; font-weight: bold; padding: 6px 10px; margin-bottom: 15px; text-transform: uppercase;';

            String html = '<div style="font-family: Arial, sans-serif; font-size: 11px; color: #004481; margin-bottom: 20px; page-break-before: always; break-before: page;">';
            html += '<div style="' + sMainHeader + '">THE DEAL (2/2)</div>';

            html += DMT_NBC_OtherAspectRendererHelper.buildHtmlOtherAspects(vals);
            html += DMT_NBC_OtherAspectRendererHelper.buildHtmlGlobalStructures(vals.globalStructure);
            html += DMT_NBC_OtherAspectRendererHelper.buildHtmlBankingPoolStructure(vals.bankingPoolTierMap);

            html += '<div style="margin-bottom: 10px; page-break-inside: avoid;">'
                + '<div style="margin-bottom: 2px;">'
                + '<span style="font-size: 13px; font-weight: bold; text-transform: uppercase;">COMPETITION FOR THE DEAL*</span>'
                + '</div>'
                + '<div style="color: #888888; font-style: italic; font-size: 9px; margin-bottom: 4px;">BBVA\'s list of main competitors for this deal and reasons.</div>'
                + '<div style="background-color: #F4F4F4; padding: 8px 10px; font-size: 11px; min-height: 35px;">'
                + vals.competitionDeal
                + '</div>'
                + '</div>';

            html += '</div>';

            return html;
        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppOtherAspectRenderer_IBF renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }
}