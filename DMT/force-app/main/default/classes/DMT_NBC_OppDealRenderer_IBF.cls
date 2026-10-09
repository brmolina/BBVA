/**
 * Renderer for NBC Opportunity Deal section (IB&F). Shared data-prep and Transaction Overview
 * table logic live in DMT_NBC_DealRendererHelper.
 */
public without sharing class DMT_NBC_OppDealRenderer_IBF implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_CalloutTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - mirrors DealData's field reads and buildHtmlTransactionOverview's
    // getValueForLabel columns. Account.Name/DES_ID_Fiscal__c are deliberately untracked - parent
    // Account data, same precedent as DMT_OpportunityClientRenderer (watching them would restart
    // approvals on every opportunity for that client). Per-product profitability figures come from
    // featuresList and are tracked separately via this renderer's own DMT_CalloutTrackableRenderer
    // methods below. Folds getTrackedFields() in under 'Opportunity' here too -
    // DMT_ApprovalChangeStep_Handler.resolveTrackedFieldsForItems uses getTrackedFieldsByObject()
    // exclusively the instant it's non-empty, never falling back to getTrackedFields() on its own,
    // so this renderer has to self-include its own switch fields to stay complete.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Client__c' => new List<String>{
                'DMT_History_Deal__c', 'DMT_Guarantor_Name_Fiscal_ID__c'
            },
            'OpportunityLineItem' => new List<String>{
                'Product2.Name', 'DMT_TXT_ProductNameOLI__c', 'DMT_Deal_amount__c', 'g_currency_id__c',
                'entity_role_type__c', 'underwriting_agreement_type__c', 'bbva_prtcp_tranche_amount__c',
                'syndicated_loan_drawn_amount__c', 'DMT_Sub_Limit__c', 'DMT_NewMoney_BBVA__c',
                'DMT_OldMoney_BBVA__c', 'gf_group_priority_opportunity_id__c'
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
                'NBC Deal', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'NBC Deal', 'opportunityLineItems', 'OpportunityLineItem',
                'OpportunityId', 'Id'
            )
        };
    }

    public String getCalloutCacheKey(SObject record) {
        return record.Id;
    }

    // CIBGLOBALD-4117 - not a real HTTP callout: reuses this interface's generic derived-value diff
    // machinery. Per-product: each OpportunityLineItem's profitability figures are matched by
    // gf_group_priority_opportunity_id__c, so values are keyed 'productId:metric' to avoid collisions.
    public Map<String, Object> fetchLiveTrackedValues(SObject record) {
        Map<String, Object> values = new Map<String, Object>();
        Set<String> productIds = new Set<String>();
        for (OpportunityLineItem oli : [
            SELECT gf_group_priority_opportunity_id__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :record.Id AND gf_group_priority_opportunity_id__c != null
        ]) {
            productIds.add(oli.gf_group_priority_opportunity_id__c);
        }
        if (productIds.isEmpty()) {
            return values;
        }

        for (Map<String, Object> feature : DMT_ViewController.getFeatures(record.Id)) {
            if (feature == null || feature.get('profitability') == null) {
                continue;
            }
            Map<String, Object> profitability = (Map<String, Object>) feature.get('profitability');
            List<Object> results = (List<Object>) profitability.get('results');
            if (results == null) {
                continue;
            }
            for (Object resultObj : results) {
                Map<String, Object> row = (Map<String, Object>) resultObj;
                String productId = (String) row.get('productId');
                if (productId == null || !productIds.contains(productId)) {
                    continue;
                }
                values.put(productId + ':rorc', row.get('rorc'));
                values.put(productId + ':raroec', row.get('raroec'));
                values.put(productId + ':term', row.get('term'));
                values.put(productId + ':averageLife', row.get('averageLife'));
                values.put(productId + ':regulatoryEad', row.get('regulatoryEad'));
            }
            break;
        }
        return values;
    }

    private static final List<String> TRANSACTION_LABELS_IBF = new List<String>{
        'Type', 'Deal Amount', 'Currency', 'Role of BBVA', 'Underwriting',
        'BBVA Commitment', 'Expected Final Take', 'Sub-limit (if any)', 'EAD',
        'New Money for BBVA', 'Old Money for BBVA', 'Tenor', 'Average Life',
        'Standalone RORC/RAROEC'
    };

    /**
     * Builds HTML for the Deal section.
     * @param data wrapper with opportunity and related data.
     * @return rendered HTML fragment for The Deal component.
     */
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }

            DMT_NBC_DealRendererHelper.DealData vals = new DMT_NBC_DealRendererHelper.DealData(data);
            return renderIBFHtml(vals);
        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppDealRenderer_IBF renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String renderIBFHtml(DMT_NBC_DealRendererHelper.DealData vals) {
        String colorBlue = '#004481';
        String colorBg = '#F4F6F9';
        String colorHelper = '#888888';

        String sContainer = 'font-family: Arial, sans-serif; color: ' + colorBlue + '; width: 100%; box-sizing: border-box; page-break-inside: avoid; margin-bottom: 20px;';
        String sMainHeader = 'background-color: ' + colorBlue + '; color: #ffffff; font-size: 14px; font-weight: bold; padding: 6px 10px; margin-bottom: 15px; text-transform: uppercase;';
        String sH2 = 'font-size: 13px; color: ' + colorBlue + '; font-weight: bold; margin: 0 0 2px 0; text-transform: uppercase;';
        String sH3 = 'font-size: 10px; color: ' + colorBlue + '; font-weight: bold; margin: 10px 0 2px 0; text-transform: uppercase;';
        String sHelper = 'font-size: 9px; color: ' + colorHelper + '; font-style: italic; margin-bottom: 4px; line-height: 1.1;';
        String sBox = 'background-color: ' + colorBg + '; padding: 8px 10px; margin-bottom: 10px; font-size: 10px; color: ' + colorBlue + '; min-height: 40px;';
        String sTable = 'width: 100%; border-collapse: collapse; margin-bottom: 10px; table-layout: fixed;';
        String sTdL = 'padding: 3px 6px; text-align: left; font-size: 9px; color: ' + colorBlue + '; border: none; background-color: transparent;';
        String sTdV = 'padding: 3px 6px; text-align: left; font-size: 9px; color: ' + colorBlue + '; border: 1px solid #ffffff; background-color: ' + colorBg + ';';

        return '<div style="' + sContainer + '">'
            + '<div style="' + sMainHeader + '">THE DEAL (1/2)</div>'
            + '<h2 style="' + sH2 + '">HISTORY OF THE DEAL *</h2>'
            + '<div style="' + sHelper + '">'
            + 'Product/Banker\'s insight on the origination of the deal (active pitch or client\'s/other banks<br/>'
            + 'Comment on the deadline to reply to the client'
            + '</div>'
            + '<div style="' + sBox + '">'
            + vals.historyDeal
            + '</div>'
            + '<h2 style="' + sH2 + '">DEAL STRUCTURE*</h2>'
            + '<h3 style="' + sH3 + '">CORPORATE STRUCTURE</h3>'
            + '<table style="' + sTable + '">'
            + '<tr>'
            + '<td style="' + sTdL + ' width: 20%;">Borrower(s) name &amp; Fiscal ID</td>'
            + '<td style="' + sTdV + ' width: 80%;">' + vals.borrowerNameFiscalId + '</td>'
            + '</tr>'
            + '<tr>'
            + '<td style="' + sTdL + '">Guarantor(s) name &amp; Fiscal ID</td>'
            + '<td style="' + sTdV + '">' + vals.guarantorNameFiscalId + '</td>'
            + '</tr>'
            + '</table>'
            + '<h3 style="' + sH3 + '">TRANSACTION OVERVIEW</h3>'
            + DMT_NBC_DealRendererHelper.buildHtmlTransactionOverview(vals.opportunityLineItems, vals.profitabilityResults, TRANSACTION_LABELS_IBF)
            + '</div>';
    }
}