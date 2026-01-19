public with sharing class DMT_OpportunityBusinessPlanRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Opportunity data not provided</div>';
        }
        try {
            Integer CURRENT_YEAR = Date.today().year();
            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004477; margin-bottom: 10px; font-weight: bold">BUSINESS PLAN CIB</h2>'
                        + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                        + '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #004477; color: #fff; font-size: 10px;"><i> Figures in Thousands </i></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #004477; color: #fff; font-weight: bold; font-size: 12px;"><strong> (-2Y) FY'+(CURRENT_YEAR -2)+'</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #004477; color: #fff; font-weight: bold; font-size: 12px;"><strong> (-1y) FY'+(CURRENT_YEAR -1)+'</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #004477; color: #fff; font-weight: bold; font-size: 12px;"><strong> FY'+CURRENT_YEAR+' E </strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #004477; color: #fff; font-weight: bold; font-size: 12px;"><strong> (+1y) FY'+(CURRENT_YEAR +1)+' E </strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #004477; color: #fff; font-weight: bold; font-size: 12px;"><strong> (+2y) FY'+(CURRENT_YEAR +2)+' E </strong></td>'
                        + '</tr>'
                        + '<tr>';
                        List<String> label = new List<String>{'Corp. Synd. Lending','Struct. Finance','Struct. Trade Finance', 'Rates',
                                                                'GTF', 'Working Capital', 'Total Non X-Sell', 'ECM', 'M&A',
                                                                'Credit/Equity', 'FX/CCS', 'Cash Management', 'Client Resources', 'Securities Services',
                                                                'Total X-Sell', 'Total Revenues'};
                        List<String> values = new List<String>{'Corp_Synd_Lending_amount__c', 'Structured_Finance_amount__c', 'Str_Trade_Finance_amount__c', 'Rates_amount__c',
                                                                'GTF_amount__c', 'Working_Capital_amount__c', 'Total_Non_X_Sell_amount__c', 'ECM_M_A_Amount__c', 'ECM_M_A_Amount__c',
                                                                'Credit_Equity_amount__c', 'FX_CCS_amount__c', 'Cash_Management_amount__c', 'Client_Resources_amount__c', 'Securities_Services_amount__c',
                                                                'Total_X_Sell_amount__c', 'Total_Revenues_amount__c'};
                        List<String> totals = new List<String>{'Total_Non_X_Sell_amount__c', 'Total_X_Sell_amount__c'};
                        List<String> totalsDarker = new List<String>{'Total_Revenues_amount__c'};
                        for(Integer i = 0; i < label.size(); i++){
                            Boolean isTotal = totals.contains(values[i]);
                            Boolean isTotalDarker = totalsDarker.contains(values[i]);
                            String tdStyle = isTotal
                                ? 'padding: 8px; border-bottom: 1px solid #ccc; background-color: #5BBEFF; color: #fff; font-weight: bold;' :
                                isTotalDarker
                                    ? 'padding: 8px; border-bottom: 1px solid #ccc; background-color: #1464A5; color: #fff; font-weight: bold;'
                                    : 'padding: 8px; border-bottom: 1px solid #ccc;';
                            html += '<td style="' + tdStyle + '">' + label[i] + '</td>'
                                + '<td style="' + tdStyle + '">' + DMT_FormattingUtils.checkNull(data.oppClient.get('Past2_FY_' + values[i])) + '</td>'
                                + '<td style="' + tdStyle + '">' + DMT_FormattingUtils.checkNull(data.oppClient.get('Past_FY_' + values[i])) + '</td>'
                                + '<td style="' + tdStyle + '">' + DMT_FormattingUtils.checkNull(data.oppClient.get('Current_FY_' + values[i])) + '</td>'
                                + '<td style="' + tdStyle + '">' + DMT_FormattingUtils.checkNull(data.oppClient.get('Next_FY_' + values[i])) + '</td>'
                                + '<td style="' + tdStyle + '"> create field <strong>Next2_FY_' + values[i] + '</strong></td>'
                                + '</tr>';
                        }
                html += '</table></br>'
                + DMT_FormattingUtils.tableRow1columnWithHelper(
                    'Qualitative Assessment of the estimated revenues',
                    'Explanation of the business plan figures presented by country and product.  Includes  a description of the future opportunities when relevant, the competition expected and an indication of the potential incremental revenues included (max 2.393 characters)',
                    'TODO'
                )
                + '</br>'
            + '</div></br>';
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OpportunityBusinessPlanRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            Integer CURRENT_YEAR = Date.today().year();
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();

            // Main Title
            contentList.add(DMT_Create_Pdf_Controller.createTitle('BUSINESS PLAN CIB'));

            // Table Head
            List<List<Object>> tableHead = new List<List<Object>>{
                new List<Object>{
                    // Custom cell for "Figures in Thousands"
                    new Map<String, Object>{
                        'content' => 'Figures in Thousands',
                        'styles' => new Map<String, Object>{
                            'fontSize' => 8,
                            'fontStyle' => 'italic',
                            'textColor' => new List<Integer>{255,255,255}, // #ffffffff
                            'fillColor' => new List<Integer>{0,68,119} // #004477
                        }
                    },
                    '(-2Y) FY' + String.valueOf(CURRENT_YEAR - 2),
                    '(-1Y) FY' + String.valueOf(CURRENT_YEAR - 1),
                    'FY' + String.valueOf(CURRENT_YEAR) + ' E',
                    '(+1Y) FY' + String.valueOf(CURRENT_YEAR + 1) + ' E',
                    '(+2Y) FY' + String.valueOf(CURRENT_YEAR + 2) + ' E'
                }
            };

            // Table Body
            List<String> label = new List<String>{
                'Corp. Synd. Lending','Struct. Finance','Struct. Trade Finance', 'Rates',
                'GTF', 'Working Capital', 'Total Non X-Sell', 'ECM', 'M&A',
                'Credit/Equity', 'FX/CCS', 'Cash Management', 'Client Resources', 'Securities Services',
                'Total X-Sell', 'Total Revenues'
            };
            List<String> values = new List<String>{
                'Corp_Synd_Lending_amount__c', 'Structured_Finance_amount__c', 'Str_Trade_Finance_amount__c', 'Rates_amount__c',
                'GTF_amount__c', 'Working_Capital_amount__c', 'Total_Non_X_Sell_amount__c', 'ECM_M_A_Amount__c', 'ECM_M_A_Amount__c',
                'Credit_Equity_amount__c', 'FX_CCS_amount__c', 'Cash_Management_amount__c', 'Client_Resources_amount__c', 'Securities_Services_amount__c',
                'Total_X_Sell_amount__c', 'Total_Revenues_amount__c'
            };

            // Table Body
            List<List<Object>> tableBody = new List<List<Object>>();
            for (Integer i = 0; i < label.size(); i++) {
                tableBody.add(new List<Object>{
                    label[i],
                    DMT_FormattingUtils.checkNull(data.oppClient.get('Past2_FY_' + values[i])),
                    DMT_FormattingUtils.checkNull(data.oppClient.get('Past_FY_' + values[i])),
                    DMT_FormattingUtils.checkNull(data.oppClient.get('Current_FY_' + values[i])),
                    DMT_FormattingUtils.checkNull(data.oppClient.get('Next_FY_' + values[i])),
                    'create field Next2_FY_' + values[i] // Placeholder for future field
                });
            }

            List<String> totals = new List<String>{'Total_Non_X_Sell_amount__c', 'Total_X_Sell_amount__c'};
            List<Integer> totalsColors = new List<Integer>{91,190,255}; // #5BBEFF
            List<String> totalsDarker = new List<String>{'Total_Revenues_amount__c'};
            List<Integer> totalsDarkerColors = new List<Integer>{20,100,165}; // #1464A5

            // Add table to content
            Map<String, Object> mainTable = DMT_Create_Pdf_Controller.createStyledTableObj(tableHead, tableBody, values, totals, totalsDarker, totalsColors, totalsDarkerColors);
            // Ensure lines between rows
            Map<String, Object> styleMap = (Map<String, Object>)mainTable.get('style');
            Map<String, Object> lineWidthItem = new Map<String, Object>{'bottom' => 0.1};
            styleMap.put('lineWidth', lineWidthItem);
            Map<String, Object> marginMap = (Map<String, Object>)mainTable.get('margin');
            Map<String, Object> marginTable = new Map<String, Object>{'top' => 0, 'bottom' => 1};
            marginMap.put('margin', marginTable);
            contentList.add(mainTable);

            // small page break before next section
            Map<String, Object> pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 };
            contentList.add(pageBreak);

            // Qualitative Assessment section
            List<List<Object>> qaSecHead = new List<List<Object>>{
                new List<Object>{'Qualitative Assessment of the estimated revenues'}
            };
            List<List<Object>> qaSecBody = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{'content'=>
                    'Explanation of the business plan figures presented by country and product.  Includes a description of the future opportunities when relevant, the competition expected and an indication of the potential incremental revenues included (max 2.393 characters)',
                        'styles'=>new Map<String,Object>{'fontSize'=>8,'textColor'=>'#666666','fontStyle'=>'italic'}}
                },
                new List<Object>{
                    'TODO'
                }
            };
            Map<String, Object> qaSec = DMT_Create_Pdf_Controller.createTableObj(qaSecHead, qaSecBody);
            contentList.add(qaSec);

            component.put('content', contentList);
            component.put('name', 'Business Plan CIB');
            return component;
        } catch (Exception e) {
            System.debug('Error in DMT_OpportunityBusinessPlanRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OpportunityBusinessPlanRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}