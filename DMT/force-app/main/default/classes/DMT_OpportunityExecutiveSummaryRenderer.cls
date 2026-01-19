public with sharing class DMT_OpportunityExecutiveSummaryRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Opportunity data not provided</div>';
        }
        try {

            String accRecordCode = DMT_Client_Selector.getAccountRecordCode(data.opportunity.AccountId);
            Map<String, Object> mapGroupCode = DMT_HPG_Utils.getGroupFromClientAccount(accRecordCode);
            String groupName = mapGroupCode.get('groupName') != null ? (String)mapGroupCode.get('groupName') : '';
            String accountName = data.opportunity.AccountId != null ? data.opportunity.Account.Name : '';
            String clientGroup = groupName + ' - ' + accountName;

            Boolean underXSell = !data.opportunity.X_sell__r.isEmpty();

            String html = '<div>'
            + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">EXECUTIVE SUMMARY</h2>'
            + '<table class="style-table style-border" style="width:100%; border-collapse: separate; border-spacing: 10px 0; table-layout: fixed; margin-left: -10px; margin-right: -10px;">'
                + '<colgroup>'
                    + '<col style="width: 50%;">'
                    + '<col style="width: 50%;">'
                + '</colgroup>'
                + DMT_FormattingUtils.tableRow2columns_New('Group / Client:', DMT_FormattingUtils.checkNull(clientGroup), 'Int. Rating:', DMT_FormattingUtils.checkNull(data.oppClient.g_upd_smscl_internal_ratg_type__c))
                + DMT_FormattingUtils.tableRow2columns_New('Booking:', 'TODO', 'Ext. Rating:', DMT_FormattingUtils.checkNull(data.oppClient.External_Rating__c))
                + DMT_FormattingUtils.tableRow2columns_New('Product Area:', 'TODO', 'TRI:', 'TODO')
                + '</table></br>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Type of Deal</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Capital Action</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>BBVA Commitment (Mn)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>BBVA Commitment (Mn)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Tenor</strong></td>'
                + '</tr>'
                + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; ">TODO</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; ">'+DMT_FormattingUtils.checkNull(data.opportunity.DMT_Capital_Action__c)+'</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; ">'+DMT_FormattingUtils.checkNull(data.opportunity.DMT_CUR_Notional_Amount__c)+'</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; ">TODO</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; ">'+DMT_FormattingUtils.checkNull(data.opportunity.DMT_Tenor__c)+'</td>'
                + '</tr>'
                + '</table></br>'
                + '<table class="style-table style-border" style="width:100%; border-collapse: separate; border-spacing: 10px 0; table-layout: fixed; margin-left: -10px; margin-right: -10px;">'
                + '<colgroup>'
                    + '<col style="width: 50%;">'
                    + '<col style="width: 50%;">'
                + '</colgroup>'
                + DMT_FormattingUtils.tableRow2columns_New('Banker:', DMT_FormattingUtils.checkNull(data.opportunity.Owner.Name), 'Under Cross-Sell:', DMT_FormattingUtils.booleanToYesNo(underXSell))
                + DMT_FormattingUtils.tableRow2columns_New('Sector Head I:', 'TODO', 'Commitment Deadline:', DMT_FormattingUtils.changeDateFormat(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Commitment_Deadline__c))
                + DMT_FormattingUtils.tableRow2columns_New('Sector Head II:', 'TODO', 'Exception Pool:', DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Exception_Pool__c))
                + DMT_FormattingUtils.tableRow2columns_New('Subsector:', 'TODO', 'Activity:', 'TODO')
                + DMT_FormattingUtils.tableRow2columns_New('Prospect:', 'TODO', '', '')
                + '</table></br>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr>'
                    + '<td style="width: 60%; padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Tiering Action</strong></td>'
                    + '<td style="width: 20%; padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;">Current</td>'
                    + '<td style="width: 20%; padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;">Target</td>'
                + '</tr>'
                + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; ">'+DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Tiering_Action__c)+'</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: smaller;">'+DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Current__c)+'</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: smaller;">'+DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Target__c)+'</td>'
                + '</tr>'
            + '</table></br>'
                + '<h3 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">MAIN CHARACTERISTICS OF THE DEAL</h3>'
                + DMT_FormattingUtils.tableRow1columnWithHelper(
                    '1. DESCRIPTION AND ISSUES',
                    'Brief description of the deal presented, main transactional features and changes vs former facility if any and key issues to be discussed (Max 617 characters)',
                    DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Description_Issues__c)
                )
                + '</br>'
                + DMT_FormattingUtils.tableRow1columnWithHelper(
                    '2. PURPOSE',
                    'Product/Banker\'s description of the use of funds of the facility/(ies) presented (Max 206 characters)',
                    DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Purpose__c)
                )
                + '</br>'
                + DMT_FormattingUtils.tableRow1columnWithHelper(
                    '3. OPPORTUNITIES & THREATS RELATED TO THE DEAL',
                    'Banker\'s insight on the impact of this deal: advantages, opportunities and potential issues - external or internal - which may arise. (Max. 103 characters/line)',
                    DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Opp_Threats_Related_Deal__c)
                )
                + '</br>'
                + '<h3 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">PROFITABILITY METRICS</h3>'
                + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px; ">1. THRESHOLDS</h3>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    // header row
                    + '<tr>'
                        + '<td style="width: 33%; padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>RoRC NBC</strong></td>'
                        + '<td style="width: 33%; padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>RaROEC NBC Floor</strong></td>'
                        + '<td style="width: 34%; padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Exception Pool</strong></td>'
                    + '</tr>'
                    // value row
                    + '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Client Level:</strong> TODO%</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Deal:</strong> TODO%</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'
                            + '<div><strong>Deal Threshold:</strong> TODO</div>'
                            + '<div><strong>Client Threshold:</strong> TODO</div>'
                        + '</td>'
                    + '</tr>'
                + '</table></br>'

                + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">2. PROFITABILITY</h3>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                        + '<td style="width:33%; padding:8px; border-bottom:1px solid #ccc; background-color:#F3F3F3;"><strong>Standalone</strong></td>'
                        + '<td style="width:33%; padding:8px; border-bottom:1px solid #ccc; background-color:#F3F3F3;"><strong>Client\'s RORC CIB</strong></td>'
                        + '<td style="width:34%; padding:8px; border-bottom:1px solid #ccc; background-color:#F3F3F3;"><strong>Expected Global RORC CIB</strong></td>'
                    + '</tr>'
                    + '<tr>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">'
                            + '<div><strong>RORC:</strong> TODO%</div>'
                            + '<div><strong>RAROEC:</strong> TODO%</div>'
                        + '</td>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">'
                            + '<div><strong>FY24:</strong> TODO%</div>'
                            + '<div><strong>YTD25:</strong> TODO%</div>'
                        + '</td>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">'
                            + '<div><strong>Without X-sell:</strong> TODO%</div>'
                            + '<div><strong>With X-sell:</strong> TODO%</div>'
                        + '</td>'
                    + '</tr>'
                + '</table><br/>'

                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                        + '<td style="width:50%; padding:8px; border-bottom:1px solid #ccc; background-color:#F3F3F3;"><strong>Blended RORC / RAROEC</strong></td>'
                        + '<td style="width:50%; padding:8px; border-bottom:1px solid #ccc; background-color:#F3F3F3;"><strong>Deal Franchise</strong></td>'
                    + '</tr>'
                    + '<tr>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">'
                            + '<div style="font-size:8px; color:#666; font-style:italic;">(Loan & Derivative)</div>'
                            + '<div><strong>RORC:</strong> TODO%</div>'
                            + '<div><strong>RAROEC:</strong> TODO%</div>'
                        + '</td>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">TODO</td>'
                    + '</tr>'
                + '</table><br/>'

                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                        + '<td style="width:33%; padding:8px; border-bottom:1px solid #ccc; background-color:#F3F3F3;"><strong>Standalone CDD RORC</strong></td>'
                        + '<td style="width:33%; padding:8px; border-bottom:1px solid #ccc; background-color:#F3F3F3;"><strong>Standalone CDD RAROEC</strong></td>'
                        + '<td style="width:34%; padding:8px; border-bottom:1px solid #ccc; background-color:#F3F3F3;"><strong>Client\'s CDD RORC CIB</strong></td>'
                    + '</tr>'
                    + '<tr>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">TODO</td>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">TODO</td>'
                        + '<td style="padding:8px; border-bottom:1px solid #ccc;">'
                            + '<div><strong>FY24:</strong> TODO%</div>'
                            + '<div><strong>YTD25:</strong> TODO%</div>'
                        + '</td>'
                    + '</tr>'
                + '</table><br/>'

            + '</div>&nbsp;</br>';
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OpportunityExecutiveSummaryRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            String accRecordCode = DMT_Client_Selector.getAccountRecordCode(data.opportunity.AccountId);
            Map<String, Object> mapGroupCode = DMT_HPG_Utils.getGroupFromClientAccount(accRecordCode);
            String groupName = mapGroupCode.get('groupName') != null ? (String)mapGroupCode.get('groupName') : '';
            String accountName = data.opportunity.AccountId != null ? data.opportunity.Account.Name : '';
            String clientGroup = groupName + ' - ' + accountName;

            Boolean underXSell = !data.opportunity.X_sell__r.isEmpty();

            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();

            // initial page break threshold
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 60
            };
            contentList.add(pageBreak);

            // Main Title
            contentList.add(DMT_Create_Pdf_Controller.createTitle('EXECUTIVE SUMMARY'));

            // Group / Client, Int Rating, Booking, Ext Rating, Product Area, TRI (two-column pairs)
            contentList.add(DMT_Create_Pdf_Controller.createListText(
                new List<String>{'Group / Client', 'Int. Rating', 'Booking', 'Ext. Rating', 'Product Area', 'TRI'},
                new List<String>{clientGroup, 'TODO', 'TODO', DMT_FormattingUtils.checkNull(data.oppClient.External_Rating__c), 'TODO', 'TODO'},
                ''
            ));

            // Type of Deal table (header + single row)
            List<List<String>> dealHead = new List<List<String>>{
                new List<String>{'Type of Deal', 'Capital Action', 'BBVA Commitment (Mn)', 'BBVA Commitment (Mn)', 'Tenor'}
            };
            List<List<String>> dealBody = new List<List<String>>{
                new List<String>{'TODO', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Capital_Action__c), 'TODO', 'TODO', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Tenor__c)}
            };
            contentList.add(DMT_Create_Pdf_Controller.createTable(dealHead, dealBody));

            // small page break before next section
            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 };
            contentList.add(pageBreak);

            // Banker / Sector Head / Exception Pool etc (render as pairs)
            contentList.add(DMT_Create_Pdf_Controller.createListText(
                new List<String>{
                    'Banker', 'Sector Head I', 'Sector Head II', 'Subsector', 'Prospect',
                    'Under Cross-Sell', 'Commitment Deadline', 'Exception Pool', 'Activity', ''
                },
                new List<String>{
                    'TODO', 'TODO', 'TODO', 'TODO', 'TODO',
                    DMT_FormattingUtils.booleanToYesNo(underXSell), DMT_FormattingUtils.changeDateFormat(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Commitment_Deadline__c), DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Exception_Pool__c), 'TODO', ''
                },
                ''
            ));

            // Tiering Action: table with three columns: Tiering Action | Current | Target
            List<List<String>> tierHead = new List<List<String>>{
                new List<String>{'Tiering Action', 'Current', 'Target'}
            };
            List<List<String>> tierBody = new List<List<String>>{
                new List<String>{
                    DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Tiering_Action__c),
                    DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Current__c),
                    DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Target__c)}
            };
            contentList.add(DMT_Create_Pdf_Controller.createTable(tierHead, tierBody));

            // small page break before next section
            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 };
            contentList.add(pageBreak);

            // Main characteristics - title
            contentList.add(DMT_Create_Pdf_Controller.createTitle('MAIN CHARACTERISTICS OF THE DEAL'));
            List<List<Object>> mainCHeadA = new List<List<Object>>{
                new List<Object>{'1. DESCRIPTION AND ISSUES'}
            };
            List<List<Object>> mainCBodyA = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{'content'=>
                    'Brief description of the deal presented, main transactional features and changes vs former facility if any and key issues to be discussed (Max 617 characters)',
                        'styles'=>new Map<String,Object>{'fontSize'=>8,'textColor'=>'#666666','fontStyle'=>'italic'}}
                },
                new List<Object>{
                    DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Description_Issues__c)
                }
            };
            Map<String, Object> mainCA = DMT_Create_Pdf_Controller.createTableObj(mainCHeadA, mainCBodyA);
            contentList.add(mainCA);

            // small page break before next section
            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 };
            contentList.add(pageBreak);

            List<List<Object>> mainCHeadB = new List<List<Object>>{
                new List<Object>{'2. PURPOSE'}
            };
            List<List<Object>> mainCBodyB = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{'content'=>
                    'Product/Banker\'s description of the use of funds of the facility/(ies) presented (Max 206 characters)',
                        'styles'=>new Map<String,Object>{'fontSize'=>8,'textColor'=>'#666666','fontStyle'=>'italic'}}
                },
                new List<Object>{
                    DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Purpose__c)
                }
            };
            Map<String, Object> mainCB = DMT_Create_Pdf_Controller.createTableObj(mainCHeadB, mainCBodyB);
            contentList.add(mainCB);

            // small page break before next section
            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 };
            contentList.add(pageBreak);

            List<List<Object>> mainCHeadC = new List<List<Object>>{
                new List<Object>{'3. OPPORTUNITIES & THREATS RELATED TO THE DEAL'}
            };
            List<List<Object>> mainCBodyC = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{'content'=>
                    'Banker\'s insight on the impact of this deal: advantages, opportunities and potential issues - external or internal - which may arise. (Max. 103 characters/line)',
                        'styles'=>new Map<String,Object>{'fontSize'=>8,'textColor'=>'#666666','fontStyle'=>'italic'}}
                },
                new List<Object>{
                    DMT_FormattingUtils.checkNull(data.opportunity.DMT_MDE_Opportunities_Clients__r[0].DMT_Opp_Threats_Related_Deal__c)
                }
            };
            Map<String, Object> mainCC = DMT_Create_Pdf_Controller.createTableObj(mainCHeadC, mainCBodyC);
            contentList.add(mainCC);

            // small page break before next section
            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 };
            contentList.add(pageBreak);

            // Profitability Metrics section
            contentList.add(DMT_Create_Pdf_Controller.createTitle('PROFITABILITY METRICS'));

            // 1. THRESHOLDS (we use label/value pairs split into two columns per logical column)
            Map<String, Object> thresholdTitle = DMT_Create_Pdf_Controller.createTitle('1. THRESHOLDS');
                thresholdTitle.put('type', 'text');
                Map<String, Object> style = (Map<String, Object>) thresholdTitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(thresholdTitle);
            // Build a 6-column table: (Label,value) x 3
            List<List<Object>> thrHeadObj = new List<List<Object>>{
                new List<Object>{'RoRC NBC', '', 'RaROEC NBC Floor', '', 'Exception Pool', ''}
            };
            // Build styled body using boldLabelCell
            List<List<Object>> thrBody = new List<List<Object>>{
            new List<Object>{
                new Map<String,Object>{ 'content'=>'Client Level:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                'TODO%',
                new Map<String,Object>{ 'content'=>'Deal:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                'TODO%',
                new Map<String,Object>{ 'content'=>'Deal Threshold:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                'TODO',
                new Map<String,Object>{ 'content'=>'Client Threshold:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                'TODO'
            }
        };
            // Use createTableObj since we are mixing bold labels
            Map<String, Object> thresholdTable = DMT_Create_Pdf_Controller.createTableObj(thrHeadObj, thrBody);
            // add to content list
            contentList.add(thresholdTable);

            // 2. PROFITABILITY
            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 30 };
            contentList.add(pageBreak);
            Map<String, Object> profitabilityTitle = DMT_Create_Pdf_Controller.createTitle('2. PROFITABILITY');
                profitabilityTitle.put('type', 'text');
                style = (Map<String, Object>) profitabilityTitle.get('style');
                style.put('fontSize', 12);
                style.put('textColor', '#004481');
            contentList.add(profitabilityTitle);


            // Block A - Standalone | Client's RORC CIB | Expected Global RORC CIB
            List<List<Object>> profHeadA = new List<List<Object>>{
                new List<Object>{'Standalone', '', 'Client\'s RORC CIB', '', 'Expected Global RORC CIB', ''}
            };
            List<List<Object>> profBodyA = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{ 'content'=>'RORC:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                    'TODO%',
                    new Map<String,Object>{ 'content'=>'RORCFY24:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                    'TODO%',
                    new Map<String,Object>{ 'content'=>'Without X-sell:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                    'TODO%'
                },
                new List<Object>{
                    new Map<String,Object>{ 'content'=>'RAROEC:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                    'TODO%',
                    new Map<String,Object>{ 'content'=>'YTD25:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                    'TODO%',
                    new Map<String,Object>{ 'content'=>'With X-sell:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                    'TODO%'
                }
            };
            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 30 };
            contentList.add(pageBreak);
            contentList.add(DMT_Create_Pdf_Controller.createTableObj(profHeadA, profBodyA));

            // Block B - Blended RORC / RAROEC vs Deal Franchise (4 cols: (label,val),(label,val))
            List<List<Object>> profHeadB = new List<List<Object>>{
                new List<Object>{'Blended RORC / RAROEC', '', 'Deal Franchise', ''}
            };
            List<List<Object>> profBodyB = new List<List<Object>>{
                new List<Object>{
                    new Map<String,Object>{'content'=>'(Loan & Derivative)','styles'=>new Map<String,Object>{'fontSize'=>8,'textColor'=>'#666666','fontStyle'=>'italic', 'halign' => 'center'}, 'colSpan' => 2},
                    '',
                    ''
                },
                new List<Object>{
                    new Map<String,Object>{ 'content'=>'RORC:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                    'TODO',
                    'TODO',
                    ''
                },
                new List<Object>{
                    new Map<String,Object>{ 'content'=>'RAROEC:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                    'TODO',
                    '',
                    ''
                }
            };
            Map<String, Object> profTableB = DMT_Create_Pdf_Controller.createTableObj(profHeadB, profBodyB);

            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 30 };
            contentList.add(pageBreak);

            contentList.add(profTableB);


            // Block C - Standalone CDD RORC | Standalone CDD RAROEC | Client's CDD RORC CIB
            List<List<Object>> profHeadC = new List<List<Object>>{
                new List<Object>{'Standalone CDD RORC', '', 'Standalone CDD RAROEC', '', 'Client\'s CDD RORC CIB', ''}
            };
            List<List<Object>> profBodyC = new List<List<Object>>{
                new List<Object>{
                    'TODO',
                    '',
                    'TODO',
                    '',
                    new Map<String,Object>{ 'content'=>'FY24:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                    'TODO'
                },
                new List<Object>{
                    '',
                    '',
                    '',
                    '',
                    new Map<String,Object>{ 'content'=>'YTD25:','styles'=>new Map<String,Object>{'fontStyle'=>'bold'} },
                    'TODO' }
            };

            pageBreak = new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 30 };
            contentList.add(pageBreak);

            contentList.add(DMT_Create_Pdf_Controller.createTableObj(profHeadC, profBodyC));

            // finalise component
            component.put('content', contentList);
            component.put('name', 'Executive Summary');

            return component;
        } catch (Exception e) {
            System.debug('Error in DMT_OpportunityExecutiveSummaryRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OpportunityExecutiveSummaryRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}