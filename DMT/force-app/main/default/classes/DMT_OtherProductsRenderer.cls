// CIBGLOBALD-4117: tracked-field methods union this renderer's own static-layout fields
// (STATIC_* below, used when a risk line has no matching DMT_LineOtherTemplateConfig__mdt row) with
// every field currently configured in that CMDT for line type 'OL' - resolved generically via
// DMT_ProductMetadataRenderService.getConfiguredFieldsByObject(), which reuses the exact same
// field-resolution the renderer itself uses (resolveRelatedKey/resolveSpecialKey/
// resolveFieldApiName), so this can never silently drift from what actually renders. Unlike every
// other Products variant, the CMDT config is not scoped per record here (no Entific__c/
// TemplateSubtype__c filter) - the union across every configured variant is reported regardless of
// which one a given record currently matches, the same wider-net trade DMT_TreasuryProductsRenderer
// already makes across its CO/PE/default geography variants.
public without sharing class DMT_OtherProductsRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {
    private static final String LINE_TYPE_CODE = 'OL';

    private static final Set<String> STATIC_LINE_FIELDS = new Set<String>{
        'Line_Id__c', 'CurrencyIsoCode', 'g_limit_last_level_type__c'
    };

    private static final Set<String> STATIC_RISK_LINE_TERM_FIELDS = new Set<String>{
        'DMT_Parent_Product_Name__c', 'gf_group_priority_line_id__c', 'DMT_Amount__c', 'CurrencyIsoCode',
        'DMT_Product__r.Name', 'g_bullet_ind_type__c', 'g_smscl_internal_ratg_type__c', 'DMT_Init_Term__c',
        'DMT_End_Term__c', 'gf_inscol_months_grace_number__c', 'gf_loan_value_per__c', 'g_notary_crtfn_ind_type__c',
        'gf_payment_frequency__c', 'g_gtee_public_adm_ind_type__c', 'gf_loan_eca_cntrb_per__c',
        'gf_min_raroec_fcg_per__c', 'gf_min_raroec_wo_fcg_per__c', 'gf_min_rorc_fcg_per__c',
        'gf_min_rorc_wo_fcg_per__c', 'gf_revolvence_pd_days_number__c', 'g_multioperation_ind_type__c',
        'DMT_Comments__c', 'g_global_product_family_Id__c', 'g_global_product_subfamily_Id__c',
        'g_global_product_category_Id__c', 'g_gbl_product_subcategory_Id__c',
        'g_limit_sinds_ast_sctr_id__c', 'g_limit_sinds_ast_subsec_id__c', 'g_branch_id__c', 'g_amortization_type__c'
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

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty() || data.riskLineList.isEmpty()) {
            return '<div>Product data not provided</div>';
        }
        try {
            Map<Id, List<DMT_ProductMetadataRenderService.RenderSection>> metadataSectionsByRiskId =
                DMT_ProductMetadataRenderService.buildSectionsForRisks(data, data.riskLineList, 'OL', null);
            String htmlOutput = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">PRODUCTS</h2>';
            for (DMT_Risk_Line_Term__c riskLine : data.riskLineList) {
                List<DMT_ProductMetadataRenderService.RenderSection> metadataSections =
                    metadataSectionsByRiskId.containsKey(riskLine.Id)
                        ? metadataSectionsByRiskId.get(riskLine.Id)
                        : new List<DMT_ProductMetadataRenderService.RenderSection>();
                String tableRows = '';
                DMT_Currency_Provision__c provision = data.riskLineToCurrencyProvisionMap.get(riskLine.Id);
                if (metadataSections.isEmpty() && riskLine.DMT_Parent_Product_Name__c != null) {
                    tableRows += DMT_FormattingUtils.tableRow2columns('Parent Product Name', DMT_FormattingUtils.checkNull(riskLine.DMT_Parent_Product_Name__c), 'Parent Product Id', DMT_FormattingUtils.checkNull(data.line.Line_Id__c) + '_' + DMT_FormattingUtils.checkNull(riskLine.gf_group_priority_line_id__c));
                }
                if (metadataSections.isEmpty()) {
                    String amountFormatted = DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Amount__c, data.line.CurrencyIsoCode);
                    tableRows += DMT_FormattingUtils.tableRow2columns('Amount:', amountFormatted, 'Currency', DMT_FormattingUtils.checkNull(riskLine.CurrencyIsoCode));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Available Currencies:', (provision != null && provision.g_currency_id__c != null) ? provision.g_currency_id__c : 'All Currencies', 'Required mitigants:', DMT_FormattingUtils.getWarrantyNamesAsString(data.riskLineToWarrantyListMap.get(riskLine.Id)));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Typology of financial program risks:', DMT_FormattingUtils.checkNull(data.line.g_limit_last_level_type__c), 'Global Product:', DMT_FormattingUtils.checkNull(riskLine.DMT_Product__r?.Name));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Global Product Subcategory:', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id).get('subcategoryProduct')), 'Global Product Category:', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id).get('categoryProduct')));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Global Product Subfamily:', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id).get('subfamilyProduct')), 'Global Product Family:', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id).get('familyProduct')));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Bullet indicator Limitation:', DMT_FormattingUtils.checkNull(riskLine.g_bullet_ind_type__c), 'Minimum Internal Rating Limitation:', DMT_FormattingUtils.checkNull(riskLine.g_smscl_internal_ratg_type__c));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Initial Term:', DMT_FormattingUtils.checkNull(riskLine.DMT_Init_Term__c), 'Maximum Term', DMT_FormattingUtils.checkNull(riskLine.DMT_End_Term__c));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Asset Allocation Sector Limitation:', DMT_FormattingUtils.checkNull(data.riskLineToTaxonomyC162Map.get(riskLine.Id)), 'Asset Allocation Subsector Limitation:', DMT_FormattingUtils.checkNull(data.riskLineToTaxonomyC164Map.get(riskLine.Id)));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Booking Geography:', DMT_FormattingUtils.checkNull(data.riskLineToTaxonomyH007Map.get(riskLine.Id)), 'Number of months of grace period:', DMT_FormattingUtils.checkNull(riskLine.gf_inscol_months_grace_number__c));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Loan to value LTV (%)', DMT_FormattingUtils.checkNull(riskLine.gf_loan_value_per__c), 'Notary formalization indicator GMOD:', DMT_FormattingUtils.checkNull(riskLine.g_notary_crtfn_ind_type__c));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Amortization Type', DMT_FormattingUtils.checkNull(data.riskLineToTaxonomyALATMap.get(riskLine.Id)), 'Interest Payment Frecuency:', DMT_FormattingUtils.checkNull(riskLine.gf_payment_frequency__c));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Indicator guarantees to public administrations GMOD:', DMT_FormattingUtils.checkNull(riskLine.g_gtee_public_adm_ind_type__c), 'Percentage contribution export credit agency loan:', DMT_FormattingUtils.checkNull(riskLine.gf_loan_eca_cntrb_per__c));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Minimum percentage RAROEC with financing:', DMT_FormattingUtils.checkNull(riskLine.gf_min_raroec_fcg_per__c), 'Minimum percentage RAROEC without financing:', DMT_FormattingUtils.checkNull(riskLine.gf_min_raroec_wo_fcg_per__c));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Minimum percentage RORC with financing:', DMT_FormattingUtils.checkNull(riskLine.gf_min_rorc_fcg_per__c), 'Minimum percentage RORC without financing:', DMT_FormattingUtils.checkNull(riskLine.gf_min_rorc_wo_fcg_per__c));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Number of days revolvency period:', DMT_FormattingUtils.checkNull(riskLine.gf_revolvence_pd_days_number__c), 'Multioperation indicator:', DMT_FormattingUtils.checkNull(riskLine.g_multioperation_ind_type__c));
                    tableRows += DMT_FormattingUtils.tableRow2columns('Comments', DMT_FormattingUtils.checkNull(riskLine.DMT_Comments__c), '', '');
                }

                String tableCustomAssociationClientsProducts = '';
                if(data.mainHolderProductsWrapperMap.size()>0 && data.mainHolderProductsWrapperMap.containsKey(data.line.Line_Id__c + '_' + riskLine.gf_group_priority_line_id__c)){
                    tableCustomAssociationClientsProducts = '<div>'
                    + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                    + '<td colspan="9" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>SELECTED CLIENT</strong></td>'
                    + '</tr>'
                    + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>CLIENT NAME</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>INTERNAL RATING (SHORT)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>CURRENT RATING TOOL DATE</strong></td>'
                    + '</tr>';
                    for(DMT_ViewController.MainHolderProductsWrapper client : data.mainHolderProductsWrapperMap.get(data.line.Line_Id__c + '_' + riskLine.gf_group_priority_line_id__c)){
                        tableCustomAssociationClientsProducts += '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.clientName) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.internalRatingShort) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.currentRatingToolDate) + '</td>'
                        + '</tr>';
                    }
                    tableCustomAssociationClientsProducts += '</table></div>&nbsp;</br>';
                }
         
    
                htmlOutput += '<h3 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">' + DMT_FormattingUtils.checkNull(riskLine.Name) + '</h3>'
                    + '<div class="slds-scope">'
                    + (metadataSections.isEmpty()
                        ? '<table class="style-table" style="width:100%; border-collapse: collapse;">' + tableRows + '</table>'
                        : DMT_ProductMetadataRenderService.renderSectionsHtml(metadataSections))
                    + tableCustomAssociationClientsProducts
                    + '</div>'
                    + '</div>'
                    + '&nbsp;</br>'
                    + '&nbsp;</br>';
            }
            return htmlOutput;
        } catch (Exception e){
            System.debug('Error in DMT_OtherProductsRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}