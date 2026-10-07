public without sharing class DMT_OppBasicFinancialsRenderer implements DMT_ViewRenderer {

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }
        
        try {
            Integer quarter = (Date.today().month() - 1) / 3 + 1;
            Integer yearOffset = (quarter == 4) ? 1 : 0;
            Integer CURRENT_YEAR = Date.today().year() + yearOffset;
            String comparisonAccountName = data.oppAccountParentName;
            Map<Integer, DMT_Opportunity_Business_Plan__c> globalBpByYear = mapGlobalBusinessPlanByYear(data.businessPlanRecords);

            // Main wrapper and promoted Title style (matching original Approval Process Data header)
            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Basic Financials' + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '') + '</h2>';

            html += '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                  + '<tr>'
                  + '<td colspan="6" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Basic Financials</strong></td>'
                  + '</tr>'
                  + '<tr>'
                  + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+' '+ '</strong></td>'
                  + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR - 1)+'</strong></td>'
                  + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR - 0)+' (optional)</strong></td>'
                  + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 1)+' (optional)</strong></td>'
                  + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 2)+' (optional)</strong></td>'
                  + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 3)+' (optional)</strong></td>'
                  + '</tr>';

            List<String> label = new List<String>{'Revenues','EBITDA','EBIT', 'Net Income','Free Cash Flow', 'Debt / EBITDA', 'Net Debt / EBITDA'};
            List<String> apiFields = new List<String>{'DMT_Revenues_number__c', 'DMT_EBITDA_number__c', 'DMT_EBIT_number__c', 'DMT_Net_Income_number__c', 'DMT_Free_Cash_Flow_number__c', 'DMT_Debt_EBITDA_number__c', 'DMT_Net_Debt_EBITDA_number__c'};

            for(Integer i = 0; i < label.size(); i++){
                html += '<tr>'
                      + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+label[i]+'</td>'
                      + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(getBusinessPlanValue(globalBpByYear, CURRENT_YEAR - 1, apiFields[i]))+'</td>'
                      + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(getBusinessPlanValue(globalBpByYear, CURRENT_YEAR, apiFields[i]))+'</td>'
                      + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(getBusinessPlanValue(globalBpByYear, CURRENT_YEAR + 1, apiFields[i]))+'</td>'
                      + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(getBusinessPlanValue(globalBpByYear, CURRENT_YEAR + 2, apiFields[i]))+'</td>'
                      + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(getBusinessPlanValue(globalBpByYear, CURRENT_YEAR + 3, apiFields[i]))+'</td>'
                      + '</tr>';
            }

            html += '</table>'
                  + '<div>'
                  + '<div class="slds-scope">'
                  + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                  + DMT_FormattingUtils.tableRow1column('Other Relevant Ratios', DMT_FormattingUtils.checkNull(data.oppClient.Other_Relevant_Ratios_desc__c))
                  + DMT_FormattingUtils.tableRow1column('Basic Financials Comments', DMT_FormattingUtils.checkNull(data.oppClient.cstk_sust_indicators_comments__c))
                  + '</table></div></div></div>'
                  + '<div style="margin-top: 20px;"></div>';

            return html;
            
        } catch (Exception e) {
            System.debug('Error in DMT_OppBasicFinancialsRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
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