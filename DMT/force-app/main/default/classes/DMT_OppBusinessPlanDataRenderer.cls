public with sharing class DMT_OppBusinessPlanDataRenderer implements DMT_ViewRenderer {

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

            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Business Plan Data' + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '') + '</h2>'
                        + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                        + '<tr>'
                        + '<td colspan="5" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Business Plan</strong></td>'
                        + '</tr>'
                        + '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+''+ '</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR - 1)+'</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+CURRENT_YEAR+'</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 1)+'</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 2)+'</strong></td>'
                        + '</tr>';

            List<String> labelBPD = new List<String>{'Corp. Synd. Lending','Structured Finance','Structured Trade Finance', 'Rates','GTF', 'Working Capital', 'Total Non X-Sell',
                                                    'ECM/M&A', 'DCM', 'Credit/Equity', 'FX/CCS','Cash Management','Client Resources','Securities Services', 'Total X-Sell',
                                                    'Total Revenues','% Cross Border Revenues', 'Transactional KPI'};
            List<String> valueBPD = new List<String>{'FY_Corp_Synd_Lending_amount__c', 'FY_Structured_Finance_amount__c', 'FY_Str_Trade_Finance_amount__c', 'FY_Rates_amount__c', 'FY_GTF_amount__c',
                                                    'FY_Working_Capital_amount__c', 'FY_Total_Non_X_Sell_amount__c', 'FY_ECM_M_A_Amount__c', 'FY_DCM_amount__c', 'FY_Credit_Equity_amount__c',
                                                    'FY_FX_CCS_amount__c', 'FY_Cash_Management_amount__c', 'FY_Client_Resources_amount__c', 'FY_Securities_Services_amount__c',
                                                    'FY_Child_X_Sell_amount__c', 'FY_Total_Revenues_amount__c','gf_xb_cust_ope_revenue_', 'gf_kpi_trans_fees_'};
            
            for(Integer i = 0; i < labelBPD.size(); i++){
                String apiName1, apiName2, apiName3, apiName4;
                if(valueBPD[i] == 'gf_xb_cust_ope_revenue_'){
                    apiName1 = valueBPD[i]+'2ya_per__c'; apiName2 = valueBPD[i]+'ly_per__c'; apiName3 = valueBPD[i]+'cyr_per__c'; apiName4 = valueBPD[i]+'nxy_per__c';
                }else if(valueBPD[i] == 'gf_kpi_trans_fees_'){
                    apiName1 = valueBPD[i]+'2ya_amount__c'; apiName2 = valueBPD[i]+'ly_amount__c'; apiName3 = valueBPD[i]+'cyr_amount__c'; apiName4 = valueBPD[i]+'nxy_amount__c';
                }else{
                    apiName1 = 'Past2_'+valueBPD[i]; apiName2 = 'Past_'+valueBPD[i]; apiName3 = 'Current_'+valueBPD[i]; apiName4 = 'Next_'+valueBPD[i];
                }

                String labelStyle = (labelBPD[i] == 'Total Non X-Sell' || labelBPD[i] == 'Total X-Sell' || labelBPD[i] == 'Total Revenues') ? 'background-color: #F3F3F3; font-weight:bold;' : '';
                String cellStart = '<td style="padding: 8px; border-bottom: 1px solid #ccc; ' + labelStyle + '">';
                String cellEnd = '</td>';

                html += '<tr>'
                      + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + labelBPD[i] + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                      + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + DMT_FormattingUtils.checkNull(data.oppClient.get(apiName1)) + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                      + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + DMT_FormattingUtils.checkNull(data.oppClient.get(apiName2))+ (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                      + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + DMT_FormattingUtils.checkNull(data.oppClient.get(apiName3)) + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                      + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + DMT_FormattingUtils.checkNull(data.oppClient.get(apiName4)) + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                      + '</tr>';
            }
            
            html += '</table></div>'
                + '<div style="margin-top: 20px;"></div>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + DMT_FormattingUtils.tableRow1column('Qualitative Assessment of the estimated Revenues', DMT_FormattingUtils.checkNull(data.oppClient.Qualitative_Assesment_of_X_Sell_Rev_desc__c))
                + DMT_FormattingUtils.tableRow1column('History of the deal', DMT_FormattingUtils.checkNull(data.oppClient.DMT_History_Deal__c))
                + '</table>'
                + '<div style="margin-top: 20px;"></div>'
                + '<table class="style-table style-border" style="width:100%; border-collapse: separate; border-spacing: 10px 0; table-layout: fixed; margin-left: -10px; margin-right: -10px;">'
                + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
                + DMT_FormattingUtils.tableRow2columns_New('Commitment Deadline', DMT_FormattingUtils.changeDateFormat(data.oppClient.DMT_Commitment_Deadline__c), 'Exception Pool', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Exception_Pool__c))
                + DMT_FormattingUtils.tableRow2columns_New(
                    'Currency',
                    DMT_FormattingUtils.checkNull(data.oppClient.DMT_Currency__c),
                    'Xsell Cost to Income (%)',
                    DMT_FormattingUtils.checkNull(data.oppClient.DMT_Xsell_Cost_to_Income__c)
                )
                + DMT_FormattingUtils.tableRow2columns_New(
                    'RWA Total RORC NBC Last12m*CET1',
                    DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_RWA__c),
                    'Economic Profit RORC NBC Last 12m',
                    DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_Net_Incomes__c)
                )
                + '</table>'
                + '<div style="margin-top: 20px;"></div>';

            html += buildHtmlXSell(data, CURRENT_YEAR);

            return html;
            
        } catch (Exception e) {
            System.debug('Error in DMT_OppBusinessPlanDataRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
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
            contentList.add(DMT_Create_Pdf_Controller.createTitle('BUSINESS PLAN DATA' + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '')));

            List<Object> titleSectionBPD = DMT_Create_Pdf_Controller.createTitleSection('BUSINESS PLAN');
            contentList.add(titleSectionBPD[0]);
            contentList.add(titleSectionBPD[1]);

            List<List<Object>> bpdHead = new List<List<Object>>{
                new List<Object>{
                    '', 
                    String.valueOf(CURRENT_YEAR - 1), 
                    String.valueOf(CURRENT_YEAR), 
                    String.valueOf(CURRENT_YEAR + 1), 
                    String.valueOf(CURRENT_YEAR + 2)
                }
            };
            
            List<List<Object>> bpdRows = new List<List<Object>>();
    
            List<String> labelBPD = new List<String>{'Corp. Synd. Lending','Structured Finance','Structured Trade Finance', 'Rates','GTF', 'Working Capital', 'Total Non X-Sell',
                                                    'ECM/M&A', 'DCM', 'Credit/Equity', 'FX/CCS','Cash Management','Client Resources','Securities Services', 'Total X-Sell',
                                                    'Total Revenues','% Cross Border Revenues', 'Transactional KPI'};
            List<String> valueBPD = new List<String>{'FY_Corp_Synd_Lending_amount__c', 'FY_Structured_Finance_amount__c', 'FY_Str_Trade_Finance_amount__c', 'FY_Rates_amount__c', 'FY_GTF_amount__c',
                                                    'FY_Working_Capital_amount__c', 'FY_Total_Non_X_Sell_amount__c', 'FY_ECM_M_A_Amount__c', 'FY_DCM_amount__c', 'FY_Credit_Equity_amount__c',
                                                    'FY_FX_CCS_amount__c', 'FY_Cash_Management_amount__c', 'FY_Client_Resources_amount__c', 'FY_Securities_Services_amount__c',
                                                    'FY_Child_X_Sell_amount__c', 'FY_Total_Revenues_amount__c','gf_xb_cust_ope_revenue_', 'gf_kpi_trans_fees_'};

            for (Integer i = 0; i < labelBPD.size(); i++) {
                String apiName1, apiName2, apiName3, apiName4;
                if (valueBPD[i] == 'gf_xb_cust_ope_revenue_') {
                    apiName1 = valueBPD[i]+'2ya_per__c'; apiName2 = valueBPD[i]+'ly_per__c'; apiName3 = valueBPD[i]+'cyr_per__c'; apiName4 = valueBPD[i]+'nxy_per__c';
                } else if(valueBPD[i] == 'gf_kpi_trans_fees_') {
                    apiName1 = valueBPD[i]+'2ya_amount__c'; apiName2 = valueBPD[i]+'ly_amount__c'; apiName3 = valueBPD[i]+'cyr_amount__c'; apiName4 = valueBPD[i]+'nxy_amount__c';
                } else {
                    apiName1 = 'Past2_'+valueBPD[i]; apiName2 = 'Past_'+valueBPD[i]; apiName3 = 'Current_'+valueBPD[i]; apiName4 = 'Next_'+valueBPD[i];
                }
                
                Boolean isHighlightedRow = (labelBPD[i] == 'Total Non X-Sell' || labelBPD[i] == 'Total X-Sell' || labelBPD[i] == 'Total Revenues');
                
                List<Object> row = new List<Object>();
                List<String> rawValues = new List<String>{
                    labelBPD[i],
                    DMT_FormattingUtils.checkNull(data.oppClient.get(apiName1)),
                    DMT_FormattingUtils.checkNull(data.oppClient.get(apiName2)),
                    DMT_FormattingUtils.checkNull(data.oppClient.get(apiName3)),
                    DMT_FormattingUtils.checkNull(data.oppClient.get(apiName4))
                };
                
                for (String val : rawValues) {
                    if (isHighlightedRow) {
                        row.add(new Map<String, Object>{
                            'content' => val,
                            'styles' => new Map<String, Object>{
                                'fillColor' => new List<Integer>{243, 243, 243}, // #F3F3F3
                                'fontStyle' => 'bold'
                            }
                        });
                    } else {
                        row.add(val);
                    }
                }
                bpdRows.add(row);
            }
            
            contentList.add(DMT_Create_Pdf_Controller.createTable(bpdHead, bpdRows));

            contentList.add(DMT_Create_Pdf_Controller.createListText(
                new List<String>{'Qualitative Assessment of the estimated Revenues'},
                new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.Qualitative_Assesment_of_X_Sell_Rev_desc__c)},
                'ONE'
            ));

            contentList.add(DMT_Create_Pdf_Controller.createListText(
                new List<String>{'History of the deal'},
                new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.DMT_History_Deal__c)},
                'ONE'
            ));

            contentList.add(DMT_Create_Pdf_Controller.createListText(
                new List<String>{'Commitment Deadline', 'Exception Pool'},
                new List<String>{DMT_FormattingUtils.changeDateFormat(data.oppClient.DMT_Commitment_Deadline__c), DMT_FormattingUtils.checkNull(data.oppClient.DMT_Exception_Pool__c)},
                ''
            ));

            contentList.add(DMT_Create_Pdf_Controller.createListText(
                new List<String>{'Currency', 'Xsell Cost to Income (%)'},
                new List<String>{
                    DMT_FormattingUtils.checkNull(data.oppClient.DMT_Currency__c),
                    DMT_FormattingUtils.checkNull(data.oppClient.DMT_Xsell_Cost_to_Income__c)
                },
                ''
            ));

            contentList.add(DMT_Create_Pdf_Controller.createListText(
                new List<String>{'RWA Total RORC NBC Last12m*CET1', 'Economic Profit RORC NBC Last 12m'},
                new List<String>{
                    DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_RWA__c),
                    DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_Net_Incomes__c)
                },
                ''
            ));

            contentList.addAll(buildPdfXSell(data, CURRENT_YEAR));

            component.put('content', contentList);
            component.put('name', 'Business Plan Data');

            System.debug('returning component: ' + JSON.serialize(component));
            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OppBusinessPlanDataRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OppBusinessPlanDataRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }

    private String buildHtmlXSell(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        if (data.xSellOpp.isEmpty()) return '';

        String html = '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Cross SELL</h3>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr style="page-break-inside: avoid;">'
            + '<td colspan="5" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Cross SELL</strong></td>'
            + '</tr>'
            + '<tr style="page-break-inside: avoid;">'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Geography</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FY'+(CURRENT_YEAR - 1)+'</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FY'+CURRENT_YEAR+'</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FY'+(CURRENT_YEAR + 1)+'</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FY'+(CURRENT_YEAR + 2)+'</strong></td>'
            + '</tr>';

        for(DMT_X_Sell__c xs : data.xSellOpp){
            String geoLabel = data.taxonomyH007Map.containsKey(xs.Booking_Geography__c) ? data.taxonomyH007Map.get(xs.Booking_Geography__c) : DMT_FormattingUtils.checkNull(xs.Booking_Geography__c);
            
            html += '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + geoLabel + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(xs.XSELL_Value_PY__c) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(xs.XSELL_Value_CY__c) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(xs.XSELL_Value_NY__c) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(xs.XSELL_Value_NY1__c) + '</td>'
                + '</tr>';
        }
        
        html += '</table></div>';
        return html;
    }

    private List<Object> buildPdfXSell(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        List<Object> result = new List<Object>();
        if (data.xSellOpp.isEmpty()) return result;

        result.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 70 });
        Map<String, Object> xsTitle = DMT_Create_Pdf_Controller.createTitle('Cross SELL');
        xsTitle.put('type', 'text');
        ((Map<String, Object>) xsTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) xsTitle.get('style')).put('textColor', '#004481');
        result.add(xsTitle);

        List<Object> titleSectionXS = DMT_Create_Pdf_Controller.createTitleSection('Cross SELL');
        result.add(titleSectionXS[0]);
        result.add(titleSectionXS[1]);

        List<List<String>> xsHead = new List<List<String>>{new List<String>{'Geography', 'FY'+(CURRENT_YEAR - 1), 'FY'+CURRENT_YEAR, 'FY'+(CURRENT_YEAR + 1), 'FY'+(CURRENT_YEAR + 2)}};
        List<List<String>> xsRows = new List<List<String>>();
        
        for(DMT_X_Sell__c xs : data.xSellOpp){
            String geoLabel = data.taxonomyH007Map.containsKey(xs.Booking_Geography__c) ? data.taxonomyH007Map.get(xs.Booking_Geography__c) : DMT_FormattingUtils.checkNull(xs.Booking_Geography__c);
            xsRows.add(new List<String>{
                geoLabel,
                DMT_FormattingUtils.checkNull(xs.XSELL_Value_PY__c),
                DMT_FormattingUtils.checkNull(xs.XSELL_Value_CY__c),
                DMT_FormattingUtils.checkNull(xs.XSELL_Value_NY__c),
                DMT_FormattingUtils.checkNull(xs.XSELL_Value_NY1__c)
            });
        }
        
        result.add(DMT_Create_Pdf_Controller.createTable(xsHead, xsRows));
        return result;
    }
}