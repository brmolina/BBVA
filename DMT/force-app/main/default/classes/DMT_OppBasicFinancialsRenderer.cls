public with sharing class DMT_OppBasicFinancialsRenderer implements DMT_ViewRenderer {

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }
        
        try {
            Integer CURRENT_YEAR = Date.today().year();
            String comparisonAccountName = data.oppAccountParentName;

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
            List<String> values = new List<String>{'Revenues_', 'EBITDA_', 'EBIT_', 'Net_Income_', 'Free_Cash_Flow_', 'Debt_EBITDA_', 'Net_Debt_EBITDA_'};
            
            for(Integer i = 0; i < label.size(); i++){
                html += '<tr>'
                      + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+label[i]+'</td>'
                      + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Last_Year_number__c'))+'</td>'
                      + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Current_Year_number__c'))+'</td>'
                      + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_number__c'))+'</td>'
                      + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_1_number__c'))+'</td>'
                      + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_2_number__c'))+'</td>'
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

    // ====================================================================================================
    // PDF RENDERING
    // ====================================================================================================

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return new Map<String, Object>();
        }
        
        try {
            Integer CURRENT_YEAR = Date.today().year();
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();
            String comparisonAccountName = data.oppAccountParentName;
            
            // Promoted Main Title
            contentList.add(DMT_Create_Pdf_Controller.createTitle('BASIC FINANCIALS' + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '')));

            // Table Header Title Section
            List<Object> titleSectionBF = DMT_Create_Pdf_Controller.createTitleSection('BASIC FINANCIALS');
            contentList.add(titleSectionBF[0]);
            contentList.add(titleSectionBF[1]);

            List<List<String>> basicHead = new List<List<String>>{new List<String>{'', String.valueOf(CURRENT_YEAR - 1), String.valueOf(CURRENT_YEAR - 0), String.valueOf(CURRENT_YEAR + 1), String.valueOf(CURRENT_YEAR + 2), String.valueOf(CURRENT_YEAR + 3)}};
            List<List<String>> basicRows = new List<List<String>>();
            List<String> labels = new List<String>{'Revenues','EBITDA','EBIT', 'Net Income','Free Cash Flow', 'Debt / EBITDA', 'Net Debt / EBITDA'};
            List<String> values = new List<String>{'Revenues_', 'EBITDA_', 'EBIT_', 'Net_Income_', 'Free_Cash_Flow_', 'Debt_EBITDA_', 'Net_Debt_EBITDA_'};

            for (Integer i = 0; i < labels.size(); i++) {
                basicRows.add(new List<String>{
                    labels[i],
                    DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Last_Year_number__c')),
                    DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Current_Year_number__c')),
                    DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_number__c')),
                    DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_1_number__c')),
                    DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_2_number__c'))
                });
            }
            
            contentList.add(DMT_Create_Pdf_Controller.createTable(basicHead, basicRows));
            contentList.add(DMT_Create_Pdf_Controller.createListText(
                new List<String>{'Other Relevant Ratios','Basic Financials Comments'},
                new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.Other_Relevant_Ratios_desc__c), DMT_FormattingUtils.checkNull(data.oppClient.cstk_sust_indicators_comments__c)},
                'ONE'));

            component.put('content', contentList);
            component.put('name', 'Basic Financials');

            System.debug('returning component: ' + JSON.serialize(component));
            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OppBasicFinancialsRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OppBasicFinancialsRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}