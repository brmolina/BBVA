/**
 * Renderer for NBC Opportunity Economics section (GTB). Shared data-prep and table-building
 * logic live in DMT_NBC_EconomicsRendererHelper. Omits the Utilisation Fee and
 * Extension/Duration Fee rows compared to the IB&F variant.
 */
public without sharing class DMT_NBC_OppEconomicsRenderer_GTB implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - mirrors getOldValueForLabel/getNewMoneyOverrideValue's field reads below.
    // Omits Utilisation Fee/Extension Duration Fee - this variant's own row list never renders them.
    // The featuresList-based profitability computation in getValueForLabel is commented-out dead
    // code (see DMT_NBC_EconomicsRendererHelper) - not tracked, since nothing reads it today. Folds
    // getTrackedFields() in under 'Opportunity' here too - see the identical note on the IB&F sibling.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Money__c' => new List<String>{
                'DMT_Is_Old_Money__c', 'DMT_Up_Front_Fee_Accrual__c', 'DMT_Up_Front_Fee_Non_Accrual__c',
                'DMT_Funding_Cost__c', 'DMT_Liquidity_Fee__c', 'DMT_Interest_Rate_Period__c',
                'DMT_Applicable_Margin__c', 'DMT_Pricing_Grid_or_Step_ups__c', 'DMT_Commitment_Fee__c',
                'DMT_Other_Fees_Accrual__c', 'DMT_Other_Fees_Non_Accrual__c', 'DMT_Expected_Drawn__c',
                'DMT_All_in_Drawn__c', 'DMT_All_in_Undrawn__c'
            },
            'OpportunityLineItem' => new List<String>{'Product2.Name'}
        };
    }

    // DMT_Opportunity_Money__c has no direct lookup to Opportunity - it hangs off
    // OpportunityLineItem via DMT_Opportunity_Product__c, so the lookup path traverses that
    // relationship (both the freeze query and DMT_SnapshotChildComparator support this).
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
                'NBC Economics', 'opportunityMoney', 'DMT_Opportunity_Money__c',
                'DMT_Opportunity_Product__r.OpportunityId', 'Id'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'NBC Economics', 'opportunityLineItems', 'OpportunityLineItem',
                'OpportunityId', 'Id'
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

            if (data.opportunity.DMT_Threshold_Type__c == 'Local') {
                return '';
            }

            DMT_NBC_EconomicsRendererHelper.EconomicsData vals = new DMT_NBC_EconomicsRendererHelper.EconomicsData(data);
            List<DMT_NBC_EconomicsRendererHelper.RowDef> rows = getTableRowsDefinitionGTB();

            String html = '<div style="font-family: Arial, sans-serif;">'
                        + '<h2 style="font-size: 10px; color: #004481; margin-bottom: 0px; font-weight: bold; text-transform: uppercase;">ECONOMICS</h2>';
            html += DMT_NBC_EconomicsRendererHelper.buildHtmlEconomics(vals, rows)
                 + '</div>';

            return html;
        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppEconomicsRenderer_GTB renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private List<DMT_NBC_EconomicsRendererHelper.RowDef> getTableRowsDefinitionGTB() {
        return new List<DMT_NBC_EconomicsRendererHelper.RowDef>{
            new DMT_NBC_EconomicsRendererHelper.RowDef('Up-Front Fee Accrual', 'Up-Front Fee', 'Up-Front Fee', 'Accrual'),
            new DMT_NBC_EconomicsRendererHelper.RowDef('Up-Front Fee Non Accrual', '', '', 'Non Accrual'),
            new DMT_NBC_EconomicsRendererHelper.RowDef('Funding Cost', 'Funding Cost', 'Funding Cost', ''),
            new DMT_NBC_EconomicsRendererHelper.RowDef('Liquidity Fee', 'Liquidity Fee', 'Liquidity Fee', ''),
            new DMT_NBC_EconomicsRendererHelper.RowDef('Interest Rate Period', 'Interest Rate Period', 'Interest Rate Period', ''),
            new DMT_NBC_EconomicsRendererHelper.RowDef('Applicable Margin', 'Applicable Margin', 'Applicable Margin', ''),
            new DMT_NBC_EconomicsRendererHelper.RowDef('Pricing Grid or Step-ups (if applicable)', 'Pricing Grid or Step-ups<br/><span style="font-size:9px">(if applicable)</span>', 'Pricing Grid or Step-ups\n(if applicable)', ''),
            new DMT_NBC_EconomicsRendererHelper.RowDef('Commitment Fee', 'Commitment Fee', 'Commitment Fee', ''),
            new DMT_NBC_EconomicsRendererHelper.RowDef('Other fees Accrual', 'Other fees:', 'Other fees:', 'Accrual'),
            new DMT_NBC_EconomicsRendererHelper.RowDef('Other fees Non Accrual', '', '', 'Non Accrual'),
            new DMT_NBC_EconomicsRendererHelper.RowDef('Expected Drawn', 'Expected Drawn', 'Expected Drawn', ''),
            new DMT_NBC_EconomicsRendererHelper.RowDef('All-in: Drawn', 'All-in: Drawn', 'All-in: Drawn', ''),
            new DMT_NBC_EconomicsRendererHelper.RowDef('All-in: Undrawn', 'All-in: Undrawn', 'All-in: Undrawn', '')
        };
    }
}