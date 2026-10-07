public without sharing class DMT_NBC_OppBasicFinancialsRenderer_IBF implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - mirrors buildBasicFinancialsHtml's field reads below. oppAccountParentName
    // (the H2 title suffix) is derived from the parent Account, not tracked - same precedent as
    // DMT_OpportunityClientRenderer's Fiscal ID/Client Group Code (watching parent Account data would
    // restart approvals on every opportunity for that client). DMT_Opportunity_Business_Plan__c and
    // its BASIC_FINANCIALS_FIELDS/opportunityClient's two fields are the exact same ones
    // DMT_OppApprovalProcessDataRenderer already tracks under 'Approval Process Data' - declared
    // again here under this component's own name so NBC Basic Financials is tracked on views that
    // don't also carry Approval Process Data. Folds getTrackedFields() in under 'Opportunity' here
    // too - DMT_ApprovalChangeStep_Handler.resolveTrackedFieldsForItems uses getTrackedFieldsByObject()
    // exclusively the instant it's non-empty, never falling back to getTrackedFields() on its own, so
    // this renderer has to self-include its own switch fields to stay complete.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Client__c' => new List<String>{
                'Other_Relevant_Ratios_desc__c', 'cstk_sust_indicators_comments__c'
            },
            'DMT_Opportunity_Business_Plan__c' => new List<String>{
                'DMT_Revenues_number__c', 'DMT_EBITDA_number__c', 'DMT_EBIT_number__c', 'DMT_Net_Income_number__c',
                'DMT_Free_Cash_Flow_number__c', 'DMT_Debt_EBITDA_number__c', 'DMT_Net_Debt_EBITDA_number__c',
                // Discriminators - mapGlobalBusinessPlanByYear buckets rows by these, so a row moving
                // year/geography changes which column shows its values even if the values don't change.
                'DMT_Year__c', 'DMT_Booking_Geography__c'
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
                'NBC Basic Financials', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'NBC Basic Financials', 'opportunityBusinessPlan', 'DMT_Opportunity_Business_Plan__c',
                'DMT_Opportunity__c', 'Id'
            )
        };
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

            return buildBasicFinancialsHtml(data);

        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppBasicFinancialsRenderer_IBF renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String buildBasicFinancialsHtml(DMT_ViewController.LineDataWrapper data) {
        DMT_Opportunity_Client__c oppClient = data.oppClient == null
            ? new DMT_Opportunity_Client__c()
            : data.oppClient;
        Date referenceDate = (data.opportunity != null && data.opportunity.CloseDate != null)
            ? data.opportunity.CloseDate
            : Date.today();
        Integer month = referenceDate.month();
        Integer year = referenceDate.year();
        Integer baseYear = month >= 10 ? year - 1 : year - 2;
        String comparisonAccountName = data.oppAccountParentName;
        String currencyCode = (String) oppClient.getPopulatedFieldsAsMap().get('DMT_Currency__c');
        String unitLabel = String.isNotBlank(currencyCode)
            ? '(Figures in Mn ' + currencyCode + ')'
            : '(Figures in Mn)';
        Map<Integer, DMT_Opportunity_Business_Plan__c> globalBpByYear = mapGlobalBusinessPlanByYear(data.businessPlanRecords);

        String html = '<div style="font-family: Arial, sans-serif; font-size: 9px;">'
                    + '<div style="page-break-inside: avoid; break-inside: avoid-page;">'
                    + '<h2 style="font-size: 10pt; color: #004481; margin-bottom: 15px; font-weight: bold; text-transform: uppercase;"> BASIC FINANCIALS' + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '') + '</h2>';

        html += '<table style="width:100%; border-collapse: collapse; table-layout: fixed;">'
              + '<colgroup><col style="width: 25%;"><col style="width: 15%;"><col style="width: 15%;"><col style="width: 15%;"><col style="width: 15%;"><col style="width: 15%;"></colgroup>'
              + '<tr>'
              + '<td style="padding: 6px; color: #004481; font-style: italic;">' + unitLabel + '</td>'
              + '<td style="padding: 6px; color: #004481; text-align: center;">' + baseYear + '</td>'
              + '<td style="padding: 6px; color: #004481; text-align: center;">' + (baseYear + 1) + '</td>'
              + '<td style="padding: 6px; color: #004481; text-align: center;">' + (baseYear + 2) + '</td>'
              + '<td style="padding: 6px; color: #004481; text-align: center;">' + (baseYear + 3) + '</td>'
              + '<td style="padding: 6px; color: #004481; text-align: center;">' + (baseYear + 4) + '</td>'
              + '</tr>';

        List<String> label = new List<String>{'Revenues','EBITDA','EBIT', 'Net Income','Free Cash Flow', 'Debt / EBITDA', 'Net Debt / EBITDA'};
        List<String> apiFields = new List<String>{'DMT_Revenues_number__c', 'DMT_EBITDA_number__c', 'DMT_EBIT_number__c', 'DMT_Net_Income_number__c', 'DMT_Free_Cash_Flow_number__c', 'DMT_Debt_EBITDA_number__c', 'DMT_Net_Debt_EBITDA_number__c'};

        String sTdLabel = 'padding: 8px 6px; color: #004481; border: none; vertical-align: middle;';
        String sTdValue = 'padding: 8px 6px; color: #004481; background-color: #F4F4F4; border: 2px solid #ffffff; vertical-align: middle; text-align: right;';

            for(Integer i = 0; i < label.size(); i++){
                html += '<tr>'
                      + '<td style="' + sTdLabel + '">' + label[i] + '</td>'
                      + '<td style="' + sTdValue + '">' + DMT_FormattingUtils.formatDecimalEs(DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(getBusinessPlanValue(globalBpByYear, baseYear, apiFields[i]))), 2) + '</td>'
                      + '<td style="' + sTdValue + '">' + DMT_FormattingUtils.formatDecimalEs(DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(getBusinessPlanValue(globalBpByYear, baseYear + 1, apiFields[i]))), 2) + '</td>'
                      + '<td style="' + sTdValue + '">' + DMT_FormattingUtils.formatDecimalEs(DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(getBusinessPlanValue(globalBpByYear, baseYear + 2, apiFields[i]))), 2) + '</td>'
                      + '<td style="' + sTdValue + '">' + DMT_FormattingUtils.formatDecimalEs(DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(getBusinessPlanValue(globalBpByYear, baseYear + 3, apiFields[i]))), 2) + '</td>'
                      + '<td style="' + sTdValue + '">' + DMT_FormattingUtils.formatDecimalEs(DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(getBusinessPlanValue(globalBpByYear, baseYear + 4, apiFields[i]))), 2) + '</td>'
                      + '</tr>';
            }

        html += '</table>'
              + '</div>';

        html += '<div style="margin-top: 25px;">'
              + '<div style="color: #004481; font-style: italic; font-size: 11px; margin-bottom: 4px;">Other relevant Ratios.</div>'
          + '<div style="background-color: #F4F4F4; padding: 12px; min-height: 40px; margin-bottom: 20px; color: #004481;">' + DMT_FormattingUtils.checkNull(oppClient.Other_Relevant_Ratios_desc__c) + '</div>'
              + '<div style="color: #004481; font-style: italic; font-size: 11px; margin-bottom: 4px;">Comments</div>'
          + '<div style="background-color: #F4F4F4; padding: 12px; min-height: 40px; margin-bottom: 20px; color: #004481;">' + DMT_FormattingUtils.checkNull(oppClient.cstk_sust_indicators_comments__c) + '</div>'
              + '</div></div><br/>';

        return html;
    }

    private Map<Integer, DMT_Opportunity_Business_Plan__c> mapGlobalBusinessPlanByYear(List<DMT_Opportunity_Business_Plan__c> businessPlanRecords) {
        Map<Integer, DMT_Opportunity_Business_Plan__c> result = new Map<Integer, DMT_Opportunity_Business_Plan__c>();
        if (businessPlanRecords == null) {
            return result;
        }
        for (DMT_Opportunity_Business_Plan__c bp : businessPlanRecords) {
            String geo = bp.DMT_Booking_Geography__c;
            if ((String.isBlank(geo) || geo == 'GLOBAL') && bp.DMT_Year__c != null) {
                result.put(Integer.valueOf(bp.DMT_Year__c), bp);
            }
        }
        return result;
    }

    private Object getBusinessPlanValue(Map<Integer, DMT_Opportunity_Business_Plan__c> bpByYear, Integer year, String apiField) {
        DMT_Opportunity_Business_Plan__c bp = bpByYear.get(year);
        return bp != null ? bp.get(apiField) : null;
    }
}