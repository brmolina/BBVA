public with sharing class DMT_OpportunityRequirementsRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Opportunity data not provided</div>';
        }
        try {
             Integer CURRENT_YEAR = Date.today().year();
            String html = '<div>'
            + '<h3 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">REQUIREMENTS</h3>'
            + '<div style="font-size: 16px; color: #004481; margin-bottom: 10px;"> 1. RISKS </div>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<colgroup>'
                    + '<col style="width: 50%;">'
                    + '<col style="width: 50%;">'
                + '</colgroup>'
                + DMT_FormattingUtils.tableRow2columns_New('AA Industry:', 'TODO', 'Asset Allocation limit:', 'TODO')
                + DMT_FormattingUtils.tableRow2columns_New('Financial Program limit:', 'TODO', 'Country Risk:', DMT_FormattingUtils.checkNull(!data.oppProducts.isEmpty() ? data.oppProducts[0].country : null))
                + DMT_FormattingUtils.tableRow2columns_New('LGD:', 'TODO', 'Leveraged Lending:', 'TODO')
                + DMT_FormattingUtils.tableRow2columns_New('CRR2 / CRR3:', 'TODO', 'Credit Risk Opinion Provided by:', 'TODO')
            + '</table></br>'
            + '<div style="font-size: 16px; color: #004481; margin-bottom: 10px;"> 2. BASIC FINANCIALS </div>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; color: #444; font-size: 10px;"><i> Figures in Mn </i></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;">(-1y) <strong>'+(CURRENT_YEAR - 1)+'</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR - 0)+'</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;">(+1y) <strong>'+(CURRENT_YEAR + 1)+'</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;">(+2y) <strong>'+(CURRENT_YEAR + 2)+'</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;">(+3y) <strong>'+(CURRENT_YEAR + 3)+'</strong></td>'
                + '</tr>';
            html += '<tr>';
                    List<String> label = new List<String>{'Revenues','EBITDA','EBIT', 'Net Income','Free Cash Flow', 'Debt / EBITDA', 'Net Debt / EBITDA'};
                    List<String> values = new List<String>{'Revenues_', 'EBITDA_', 'EBIT_', 'Net_Income_', 'Free_Cash_Flow_', 'Debt_EBITDA_', 'Net_Debt_EBITDA_'};
                    for(Integer i = 0; i < label.size(); i++){
                        html += '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+label[i]+'</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Last_Year_number__c'))+'</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Current_Year_number__c'))+'</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_number__c'))+'</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_1_number__c'))+'</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_2_number__c'))+'</td>'
                        + '</tr>';
                    }
            html += '</table></br>'
                + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                    + '<colgroup>'
                        + '<col style="width: 50%;">'
                        + '<col style="width: 50%;">'
                    + '</colgroup>'
                    + DMT_FormattingUtils.tableRow1column('Other Relevant Ratios', DMT_FormattingUtils.checkNull(data.oppClient.Other_Relevant_Ratios_desc__c))
                    + DMT_FormattingUtils.tableRow1column('Basic Financials Comments', DMT_FormattingUtils.checkNull(data.oppClient.cstk_sust_indicators_comments__c))
            + '</table></br>'
            + '<div style="font-size: 16px; color: #004481; margin-bottom: 10px;"> 3. SYNDICATION OPINION </div>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                        + '<td style="width:33%; padding:8px; border-bottom:1px solid #ccc; background-color:#F3F3F3;"><strong>Syndication</strong></td>'
                        + '<td style="width:33%; padding:8px; border-bottom:1px solid #ccc; background-color:#F3F3F3;"><strong>DCM/ECM</strong></td>'
                        + '<td style="width:34%; padding:8px; border-bottom:1px solid #ccc; background-color:#F3F3F3;"><strong>Underwriting</strong></td>'
                    + '</tr>'
                    + '<tr>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">'
                            + '<div style="font-size:8px; color:#666; font-style:italic;">Required in writing for the cases stated in NBC Governance</div>'
                            + '<div>TODO</div>'
                            + '<div>TODO</div>'
                        + '</td>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">'
                            + '<div>TODO</div>'
                        + '</td>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">'
                            + '<div>TODO</div>'
                        + '</td>'
                    + '</tr>'
                + '</table><br/>'
            +'</div>';
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OpportunityRequirementsRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
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

            // initial page break threshold
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 60
            };
            contentList.add(pageBreak);

            // Main Title
            contentList.add(DMT_Create_Pdf_Controller.createTitle('REQUIREMENTS'));

            // 1. RISKS subtitle
            Map<String, Object> risksTitle = DMT_Create_Pdf_Controller.createTitle('1. RISKS');
                risksTitle.put('type', 'text');
                Map<String, Object> style = (Map<String, Object>) risksTitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(risksTitle);

            List<String> detailLabels = new List<String>();
            List<String> detailValues = new List<String>();

            detailLabels.add('AA Industry:');
            detailValues.add('TODO');
            detailLabels.add('Financial Program limit:');
            detailValues.add('TODO');
            detailLabels.add('LGD:');
            detailValues.add('TODO');
            detailLabels.add('CRR2 / CRR3:');
            detailValues.add('TODO');
            detaillabels.add('Asset Allocation limit:');
            detailValues.add('TODO');
            detailLabels.add('Country Risk:');
            detailValues.add(DMT_FormattingUtils.checkNull(!data.oppProducts.isEmpty() ? data.oppProducts[0].country : null));
            detailLabels.add('Leveraged Lending:');
            detailValues.add('TODO');
            detailLabels.add('Credit Risk Opinion Provided by:');
            detailValues.add('TODO');

            contentList.add(DMT_Create_Pdf_Controller.createListText(detailLabels, detailValues, ''));

            // 2. BASIC FINANCIALS subtitle
            Map<String, Object> basicTitle = DMT_Create_Pdf_Controller.createTitle('2. BASIC FINANCIALS');
                basicTitle.put('type', 'text');
                style = (Map<String, Object>) basicTitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(basicTitle);

            // Basic Financials Table Head
            List<List<Object>> basicHead = new List<List<Object>>{
                new List<Object>{
                    new Map<String, Object>{
                        'content' => 'Figures in Mn',
                        'styles' => new Map<String, Object>{
                            'fontSize' => 9,
                            'fontStyle' => 'italic',
                            'textColor' => new List<Integer>{68, 68, 68},
                            'fillColor' => new List<Integer>{243, 243, 243}
                        }
                    },
                    new Map<String, Object>{
                        'content' => '(-1y) ' + String.valueOf(CURRENT_YEAR - 1),
                        'styles' => new Map<String, Object>{
                            'bold' => true,
                            'fillColor' => new List<Integer>{243, 243, 243}
                        }
                    },
                    new Map<String, Object>{
                        'content' => String.valueOf(CURRENT_YEAR),
                        'styles' => new Map<String, Object>{
                            'bold' => true,
                            'fillColor' => new List<Integer>{243, 243, 243}
                        }
                    },
                    new Map<String, Object>{
                        'content' => '(+1y) ' + String.valueOf(CURRENT_YEAR + 1),
                        'styles' => new Map<String, Object>{
                            'bold' => true,
                            'fillColor' => new List<Integer>{243, 243, 243}
                        }
                    },
                    new Map<String, Object>{
                        'content' => '(+2y) ' + String.valueOf(CURRENT_YEAR + 2),
                        'styles' => new Map<String, Object>{
                            'bold' => true,
                            'fillColor' => new List<Integer>{243, 243, 243}
                        }
                    },
                    new Map<String, Object>{
                        'content' => '(+3y) ' + String.valueOf(CURRENT_YEAR + 3),
                        'styles' => new Map<String, Object>{
                            'bold' => true,
                            'fillColor' => new List<Integer>{243, 243, 243}
                        }
                    }
                }
            };

            // Basic Financials Table Body
            List<String> label = new List<String>{'Revenues','EBITDA','EBIT', 'Net Income','Free Cash Flow', 'Debt / EBITDA', 'Net Debt / EBITDA'};
            List<String> values = new List<String>{'Revenues_', 'EBITDA_', 'EBIT_', 'Net_Income_', 'Free_Cash_Flow_', 'Debt_EBITDA_', 'Net_Debt_EBITDA_'};
            List<List<Object>> basicBody = new List<List<Object>>();
            for(Integer i = 0; i < label.size(); i++){
                basicBody.add(new List<Object>{
                    label[i],
                    DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Last_Year_number__c')),
                    DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Current_Year_number__c')),
                    DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_number__c')),
                    DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_1_number__c')),
                    DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_2_number__c'))
                });
            }

            Map<String, Object> basicTable = DMT_Create_Pdf_Controller.createStyledTableObj(basicHead, basicBody, values, new List<String>(), new List<String>());
            Map<String, Object> basicStyleMap = (Map<String, Object>)basicTable.get('style');
            basicStyleMap.put('lineWidth', new Map<String, Object>{'bottom' => 0.1});
            Map<String, Object> basicMarginMap = (Map<String, Object>)basicTable.get('margin');
            basicMarginMap.put('margin', new Map<String, Object>{'top' => 0, 'bottom' => 1});
            contentList.add(basicTable);

            // Other Relevant Ratios section
            List<String> otherLabelList = new List<String>{'Other Relevant Ratios'};
            List<String> otherValueList = new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.Other_Relevant_Ratios_desc__c)};
            contentList.add(DMT_Create_Pdf_Controller.createListText(otherLabelList, otherValueList, 'ONE'));

            // Basic Financials Comments section
            List<String> basicLabelList = new List<String>{'Basic Financials Comments'};
            List<String> basicValueList = new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.cstk_sust_indicators_comments__c)};
            contentList.add(DMT_Create_Pdf_Controller.createListText(basicLabelList, basicValueList, 'ONE'));

            // 3. SYNDICATION OPINION subtitle
            Map<String, Object> syndTitle = DMT_Create_Pdf_Controller.createTitle('3. SYNDICATION OPINION');
                syndTitle.put('type', 'text');
                style = (Map<String, Object>) syndTitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(syndTitle);

            // Syndication Opinion Table Head
            List<List<Object>> syndHead = new List<List<Object>>{
                new List<Object>{'Syndication', 'DCM/ECM', 'Underwriting'}
            };
            // Syndication Opinion Table Body
            List<List<Object>> syndBody = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{'content'=>'Required in writing for the cases stated in NBC Governance','styles'=>new Map<String,Object>{'fontSize'=>8,'textColor'=>'#666666','fontStyle'=>'italic'}},
                    '',
                    ''
                },
                new List<Object>{
                    'TODO',
                    'TODO',
                    'TODO'
                },
                new List<Object>{
                    'TODO',
                    '',
                    ''
                }
            };
            Map<String, Object> syndTable = DMT_Create_Pdf_Controller.createTableObj(syndHead, syndBody);

            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 30 };
            contentList.add(pageBreak);

            contentList.add(syndTable);

            component.put('content', contentList);
            component.put('name', 'REQUIREMENTS');
            return component;
        } catch (Exception e) {
            System.debug('Error in DMT_OpportunityRequirementsRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OpportunityRequirementsRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}