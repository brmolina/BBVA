// CIBGLOBALD-4117: tracked-field methods union this renderer's own static-layout fields
// (STATIC_* below, used when a risk line has no matching DMT_LineOtherTemplateConfig__mdt row) with
// every field currently configured in that CMDT for line type 'OP' - see
// DMT_OtherProductsRenderer's header for the shared reasoning (same
// DMT_ProductMetadataRenderService.getConfiguredFieldsByObject mechanism, same wider-net trade
// across every Entific__c/TemplateSubtype__c variant).
public without sharing class DMT_LineSanctionProductsRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {
    private static final String LINE_TYPE_CODE = 'OP';

    private static final Set<String> STATIC_LINE_FIELDS = new Set<String>{
        'CurrencyIsoCode', 'g_limit_last_level_type__c'
    };

    private static final Set<String> STATIC_RISK_LINE_TERM_FIELDS = new Set<String>{
        'DMT_Amount__c', 'CurrencyIsoCode', 'g_multioperation_ind_type__c', 'DMT_Product__r.Name',
        'g_global_product_family_Id__c', 'g_global_product_subfamily_Id__c', 'g_global_product_category_Id__c',
        'g_gbl_product_subcategory_Id__c', 'DMT_Init_Term__c', 'DMT_End_Term__c', 'g_branch_id__c',
        'DMT_Comments__c', 'g_line_commitment_level_type__c'
    };

    private static Map<String, List<String>> mergedFieldsByObject() {
        Map<String, List<String>> merged = new Map<String, List<String>>{
            'DMT_Line__c' => new List<String>(STATIC_LINE_FIELDS),
            'DMT_Risk_Line_Term__c' => new List<String>(STATIC_RISK_LINE_TERM_FIELDS),
            'DMT_Warranty__c' => new List<String>{ 'Name' },
            'DMT_Currency_Provision__c' => new List<String>{ 'g_currency_id__c' }
        };
        // getConfiguredFieldsByObject only ever resolves to these same 4 objects (see its own
        // header) - all pre-populated above, so no object-not-yet-in-merged branch is reachable.
        Map<String, List<String>> configuredFields = DMT_ProductMetadataRenderService.getConfiguredFieldsByObject(LINE_TYPE_CODE);
        for (String objectName : configuredFields.keySet()) {
            for (String fieldName : configuredFields.get(objectName)) {
                if (!merged.get(objectName).contains(fieldName)) {
                    merged.get(objectName).add(fieldName);
                }
            }
        }
        return merged;
    }

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>(STATIC_LINE_FIELDS);
    }

    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return mergedFieldsByObject();
    }

    // CIBGLOBALD-4117 - child sections for Risk/Currency Provisions/Warranties.
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
                'Products', 'riskLineList', 'DMT_Risk_Line_Term__c', 'DMT_Line__c', 'Id', 'DMT_Init_Term__c ASC'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Products', 'currencyProvisions', 'DMT_Currency_Provision__c', 'DMT_Risk_Line_Term__r.DMT_Line__c', 'Id', 'Name ASC'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Products', 'warranties', 'DMT_Warranty__c', 'DMT_Risk_Line_Term__r.DMT_Line__c', 'Id', 'Name ASC'
            )
        };
    }

    // ==========================================
    // HELPER: Build the DisplayField List
    // ==========================================
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data, DMT_Risk_Line_Term__c riskLine) {
        
        DMT_Currency_Provision__c provision = data.riskLineToCurrencyProvisionMap.get(riskLine.Id);
        String availCurrencies = (provision != null && provision.g_currency_id__c != null) ? provision.g_currency_id__c : 'All Currencies';
        String mitigants = DMT_FormattingUtils.getWarrantyNamesAsString(data.riskLineToWarrantyListMap.get(riskLine.Id));

        // Dynamically add currency Iso Code to the Amount label if available
        String amountLabel = 'Amount' + (String.isNotBlank(data.currencyIsoCode) ? ' (' + data.currencyIsoCode + ')' : '');

        return new List<DMT_FormattingUtils.DisplayField>{
            // Row 1
            new DMT_FormattingUtils.DisplayField(amountLabel, DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Amount__c, riskLine.CurrencyIsoCode)),
            new DMT_FormattingUtils.DisplayField('Currency', DMT_FormattingUtils.checkNull(riskLine.CurrencyIsoCode)),

            // Row 2
            new DMT_FormattingUtils.DisplayField('Available Currencies for disposals', availCurrencies),
            new DMT_FormattingUtils.DisplayField('Required mitigants', mitigants),

            // Row 3
            new DMT_FormattingUtils.DisplayField('Type of risk', DMT_FormattingUtils.checkNull(data.line.g_limit_last_level_type__c)),
            new DMT_FormattingUtils.DisplayField('Multioperation indicator', riskLine.g_multioperation_ind_type__c), 

            // Row 4
            new DMT_FormattingUtils.DisplayField('Global Product', DMT_FormattingUtils.checkNull(riskLine.DMT_Product__r?.Name)),
            new DMT_FormattingUtils.DisplayField('Global Product Subcategory', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id)?.get('subcategoryProduct'))),

            // Row 5
            new DMT_FormattingUtils.DisplayField('Global Product Category', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id)?.get('categoryProduct'))),
            new DMT_FormattingUtils.DisplayField('Global Product Subfamily', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id)?.get('subfamilyProduct'))),

            // Row 6 
            new DMT_FormattingUtils.DisplayField('Global Product Family', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id)?.get('familyProduct'))),
            new DMT_FormattingUtils.DisplayField('Initial Term', riskLine.DMT_Init_Term__c != null ? String.valueOf(Math.round(Decimal.valueOf(riskLine.DMT_Init_Term__c) / 31)) + ' month(s)' : '-'),

            // Row 7
            new DMT_FormattingUtils.DisplayField('Maximum Term', riskLine.DMT_End_Term__c != null ? String.valueOf(Math.round(Decimal.valueOf(riskLine.DMT_End_Term__c) / 31)) + ' month(s)' : '-'),
            new DMT_FormattingUtils.DisplayField('Booking Geography', DMT_FormattingUtils.checkNull(data.riskLineToTaxonomyH007Map.get(riskLine.Id))),

            // Row 8 (Full Width)
            new DMT_FormattingUtils.DisplayField('Comments', DMT_FormattingUtils.checkNull(riskLine.DMT_Comments__c)),
            new DMT_FormattingUtils.DisplayField('Line / Opportunity', DMT_FormattingUtils.checkNull(riskLine.g_line_commitment_level_type__c))
            
        };
    }

    // ==========================================
    // HTML RENDERING
    // ==========================================
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty() || data.riskLineList.isEmpty()) {
            return '<div>Approval Product data not provided</div>';
        }

        try {
            Map<Id, List<DMT_ProductMetadataRenderService.RenderSection>> metadataSectionsByRiskId =
                DMT_ProductMetadataRenderService.buildSectionsForRisks(data, data.riskLineList, 'OP', 'LIN');
            String htmlOutput = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">PRODUCTS</h2>';
            
            // Iterate over all products (Risk Line Terms)
            for (DMT_Risk_Line_Term__c riskLine : data.riskLineList) {
                List<DMT_ProductMetadataRenderService.RenderSection> metadataSections =
                    metadataSectionsByRiskId.containsKey(riskLine.Id)
                        ? metadataSectionsByRiskId.get(riskLine.Id)
                        : new List<DMT_ProductMetadataRenderService.RenderSection>();

                // Add Sub-Header for each product and generate table
                htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px; font-weight: bold">' + DMT_FormattingUtils.checkNull(riskLine.Name) + '</h3>'
                    + '<div class="slds-scope">';

                if (!metadataSections.isEmpty()) {
                    htmlOutput += DMT_ProductMetadataRenderService.renderSectionsHtml(metadataSections);
                } else {
                    htmlOutput += DMT_FormattingUtils.generateHtmlTable(buildRenderFields(data, riskLine));
                }

                htmlOutput += '</div><br/>';
            }
            
            htmlOutput += '</div>&nbsp;</br>';
            // Append sustainability data sourced from the associated Opportunity
            htmlOutput += new DMT_OpportunitySustainabilityRenderer().renderHtml(data);
            return htmlOutput;

        } catch (Exception e){
            System.debug('Error in DMT_LineSanctionProductsRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}