public with sharing class DMT_OpportunityProductsRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.oppProducts.isEmpty()) {
            return '<div>Product data not provided</div>';
        }
        try{
            String htmlOutput = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">PRODUCTS</h2>';
                for (DMT_ViewController.OpportunityProduct oppProduct : data.oppProducts) {
                    htmlOutput += '<h3 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">' + DMT_FormattingUtils.checkNull(oppProduct.name) + '</h3>'
                    //Detail
                    + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px; ">Detail</h3>'
                    + '<div class="slds-scope">'
                        + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                            + '<colgroup>'
                            + '<col style="width: 50%;">'
                            + '<col style="width: 50%;">'
                            + '</colgroup>'
                            + DMT_FormattingUtils.tableRow2columns_New('Booking Geography:', DMT_FormattingUtils.checkNull(oppProduct.bookingGeography), 'Risk Type:', DMT_FormattingUtils.checkNull(oppProduct.riskType))
                            + DMT_FormattingUtils.tableRow2columns_New('Initial Date:', DMT_FormattingUtils.changeDateFormat(oppProduct.initialDate), 'Maturity Data:', DMT_FormattingUtils.changeDateFormat(oppProduct.maturityDate))
                            + DMT_FormattingUtils.tableRow1column('Comments:', DMT_FormattingUtils.checkNull(oppProduct.comments))
    
                        + '</table>'
                    + '</div>';
                    //Amortization
                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px; ">Amortization</h3>'
                    + '<div class="slds-scope">'
                            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                                + '<colgroup>'
                                + '<col style="width: 50%;">'
                                + '<col style="width: 50%;">'
                                + '</colgroup>'
                                + DMT_FormattingUtils.tableRow2columns_New('Amortization Type:', DMT_FormattingUtils.checkNull(oppProduct.amortizationType), 'Payment Frequency:', DMT_FormattingUtils.checkNull(oppProduct.paymentFrequency))
                                + DMT_FormattingUtils.tableRow2columns_New('Amortization Schedule Currency:', DMT_FormattingUtils.checkNull(oppProduct.amortizationScheduleCurrency), ' ', ' ')
    
                            + '</table>'
                    + '</div>&nbsp;</br>';
                    htmlOutput += '<div>'
                    + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                    + '<td colspan="7" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>TENORS</strong></td>'
                    + '</tr>'
                    + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>PAYMENT DATE</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DRAWN NOTIONAL AMOUNT</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>UNDRAWN NOTIONAL AMOUNT</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DRAWN SPREAD (BPS)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>UNDRAWN SPREAD (BPS)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>ACCRUAL FEES (BPS)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>ACCRUAL FEES (BPS)</strong></td>'
                    + '</tr>';
                    if(!oppProduct.oppTenors.isEmpty()){
                        for(DMT_Opportunity_Tenor__c  tenor : oppProduct.oppTenors){
                            System.debug('tenor, '+ tenor);
                            htmlOutput += '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.changeDateFormat(tenor.gf_tenor_date__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(tenor.gj_nominal_amount_db__c, tenor.CurrencyIsoCode) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(tenor.gf_nominal_amount_fb__c, tenor.CurrencyIsoCode) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(tenor.gf_spread_db__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(tenor.gf_spread_fb__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(tenor.gf_accrual_fees_bp__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(tenor.gf_non_accrual_fees_bp__c) + '</td>'
                            + '</tr>';
                        }
                    }
                    htmlOutput += '</table></div>&nbsp;</br>';
                    //Funding
                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px; ">Funding</h3>'
                    + '<div class="slds-scope">'
                            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                                + '<colgroup>'
                                + '<col style="width: 50%;">'
                                + '<col style="width: 50%;">'
                                + '</colgroup>'
                                + DMT_FormattingUtils.tableRow2columns_New('Funding Curve:', DMT_FormattingUtils.checkNull(oppProduct.fundingCurve), 'Funding Term:', DMT_FormattingUtils.checkNull(oppProduct.fundingTerm))
                                + DMT_FormattingUtils.tableRow2columns_New('Funding Drawn (BPS):', DMT_FormattingUtils.formatCurrencyAmount(oppProduct.fundingDrawnBPS, oppProduct.CurrencyIsoCode), 'Funding Undrawn (BPS)', DMT_FormattingUtils.formatCurrencyAmount(oppProduct.fundingUndrawnBPS, oppProduct.CurrencyIsoCode))
                                + DMT_FormattingUtils.tableRow2columns_checkbox('Green Bonus:',oppProduct.greenBonus, 'Social Bonus',oppProduct.socialBonus)
                            + '</table>'
                    + '</div>&nbsp;</br>';
                    // Country Risk
                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px; ">Country Risk</h3>'
                    + '<div class="slds-scope">'
                            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                                + '<colgroup>'
                                + '<col style="width: 50%;">'
                                + '<col style="width: 50%;">'
                                + '</colgroup>'
                                + DMT_FormattingUtils.tableRow2columns_New('Country:', DMT_FormattingUtils.checkNull(oppProduct.country), 'Country Rating:', DMT_FormattingUtils.checkNull(oppProduct.countryRating))
                            + '</table>'
                    + '</div>&nbsp;</br>';
                    //Mitigants
                    htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px; ">Mitigants</h3>'
                    + '<div class="slds-scope">'
                            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                                + '<colgroup>'
                                + '<col style="width: 50%;">'
                                + '<col style="width: 50%;">'
                                + '</colgroup>'
                                + DMT_FormattingUtils.tableRow2columns_New('Currency Mitigant:', DMT_FormattingUtils.checkNull(oppProduct.currencyMitigant), ' ', ' ')
                            + '</table>'
                    + '</div>&nbsp;</br>';
                    htmlOutput += '<div>'
                    + '<table class="style-table" style="width:100%; border-collapse: separate;">'
                    + '<tr>'
                    + '<td colspan="5" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>'+ System.Label.dmt_cl_Collateral_Guarantees_Text +'</strong></td>'
                    + '</tr>'
                    + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>MITIGANT TYPE</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>COMMERCIAL RISK (%)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>POLITICAL RISK (%)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>EXTERNAL RATING</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>LIQUIDATION PERIOD</strong></td>'
                    + '</tr>';
                    if(!oppProduct.oppMitigants.isEmpty()){
                        for(DMT_Opportunity_Mitigant__c  mitigant : oppProduct.oppMitigants){
                            System.debug('mitigant, '+ mitigant);
                            htmlOutput += '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(mitigant.Mitigant_Type__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(Integer.valueOf(mitigant.Commercial_Percentage__c)) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(Integer.valueOf(mitigant.Political_Percentage__c)) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(mitigant.External_Rating__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(mitigant.Liquidation_Period__c) + '</td>'
                            + '</tr>';
                        }
                    }
                    htmlOutput += '</table></div>&nbsp;</br>';
                    htmlOutput += '<div>'
                    + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
                    + '<tr>'
                    + '<td colspan="9" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px; word-wrap: break-word;"><strong>'+ System.Label.dmt_cl_Guarantors_Text +'</strong></td>'
                    + '</tr>'
                    + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-wrap: break-word;"><strong>MITIGANT TYPE</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-wrap: break-word;"><strong>COMMERCIAL RISK (%)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-wrap: break-word;"><strong>POLITICAL RISK (%)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-wrap: break-word;"><strong>EXTERNAL RATING</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-wrap: break-word;"><strong>CLIENT TYPE</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-wrap: break-word;"><strong>SCRA</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-wrap: break-word;"><strong>ASSET VALUE CORRELATION</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-wrap: break-word;"><strong>GUARANTOR EUROPEAN ECA</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-wrap: break-word;"><strong>EUROPEAN BANK</strong></td>'
                    + '</tr>';
                    if(!oppProduct.oppMitigants.isEmpty()){
                        for(DMT_Opportunity_Mitigant__c  mitigant : oppProduct.oppMitigants){
                            System.debug('mitigant, '+ mitigant);
                            htmlOutput += '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-wrap: break-word;">' + DMT_FormattingUtils.checkNull(mitigant.Mitigant_Type__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-wrap: break-word;">' + DMT_FormattingUtils.checkNull(Integer.valueOf(mitigant.Commercial_Percentage__c)) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-wrap: break-word;">' + DMT_FormattingUtils.checkNull(Integer.valueOf(mitigant.Political_Percentage__c)) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-wrap: break-word;">' + DMT_FormattingUtils.checkNull(mitigant.External_Rating__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-wrap: break-word;">' + DMT_FormattingUtils.checkNull(mitigant.Counterpart__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-wrap: break-word;">' + DMT_FormattingUtils.checkNull(mitigant.SCRA__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-wrap: break-word;">' + '<input type="checkbox" disabled="" '+ (mitigant.AVC_Check__c ? 'checked' : '') +' />' 
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-wrap: break-word;">' + '<input type="checkbox" disabled="" '+ (mitigant.Garantor_European_ECA__c ? 'checked' : '') +' />' 
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-wrap: break-word;">' + '<input type="checkbox" disabled="" '+ (mitigant.European_Bank_Check__c ? 'checked' : '') +' />' 
                            + '</tr>';
                        }
                    }
                    htmlOutput += '</table></div>&nbsp;</br>';
                }
                htmlOutput  += '</div>&nbsp;</br>';
            return htmlOutput;
        } catch (Exception e){
            System.debug('Error in DMT_OpportunityProductsRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.oppProducts.isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();

            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 60
            };
            contentList.add(pageBreak);
            
            // Main Title: PRODUCTS
            contentList.add(DMT_Create_Pdf_Controller.createTitle('PRODUCTS'));
            
            for (DMT_ViewController.OpportunityProduct oppProduct : data.oppProducts) {

                pageBreak = new Map<String, Object>{
                    'type' => 'pageBreak',
                    'threshold' => 50
                };
                contentList.add(pageBreak);

                Map<String, Object> productTitle = DMT_Create_Pdf_Controller.createTitle(DMT_FormattingUtils.checkNull(oppProduct.name));
                contentList.add(productTitle);
                
                // Detail Section Title
                Map<String, Object> detailTitle = DMT_Create_Pdf_Controller.createTitle('Detail');
                detailTitle.put('type', 'text');
                Map<String, Object> style = (Map<String, Object>) detailTitle.get('style');
                style.put('fontSize', 14);
                style.put('textColor', '#004481');
                contentList.add(detailTitle);
                
                List<String> detailLabels = new List<String>();
                List<String> detailValues = new List<String>();

                detailLabels.add('Booking Geography');
                detailValues.add(DMT_FormattingUtils.checkNull(oppProduct.bookingGeography));
                detaillabels.add('Initial Date');
                detailValues.add(DMT_FormattingUtils.changeDateFormat(oppProduct.initialDate));
                detailLabels.add('Risk Type');
                detailValues.add(DMT_FormattingUtils.checkNull(oppProduct.riskType));
                detailLabels.add('Maturity Date');
                detailValues.add(DMT_FormattingUtils.changeDateFormat(oppProduct.maturityDate));

                contentList.add(DMT_Create_Pdf_Controller.createListText(detailLabels, detailValues, ''));
                
                // Comments (full-width)
                List<String> commentNames = new List<String>{'Comments'};
                List<String> commentValues = new List<String>{DMT_FormattingUtils.checkNull(oppProduct.comments)};
                contentList.add(DMT_Create_Pdf_Controller.createListText(commentNames, commentValues, 'ONE'));

                pageBreak = new Map<String, Object>{
                    'type' => 'pageBreak',
                    'threshold' => 50
                };
                contentList.add(pageBreak);
                
                // Amortization Section Title
                Map<String, Object> amortizationTitle = DMT_Create_Pdf_Controller.createTitle('Amortization');
                amortizationTitle.put('type', 'text');
                style = (Map<String, Object>) amortizationTitle.get('style');
                style.put('fontSize', 14);
                style.put('textColor', '#004481');
                contentList.add(amortizationTitle);
                
                // Amortization Pairs (two columns, with empty for second in last row)
                List<String> amortLabels = new List<String>{'Amortization Type', 'Payment Frequency', 'Amortization Schedule Currency'};
                List<String> amortValues = new List<String>{
                    DMT_FormattingUtils.checkNull(oppProduct.amortizationType),
                    DMT_FormattingUtils.checkNull(oppProduct.paymentFrequency),
                    DMT_FormattingUtils.checkNull(oppProduct.amortizationScheduleCurrency)
                };
                contentList.add(DMT_Create_Pdf_Controller.createListText(amortLabels, amortValues, ''));

                List<Object> titleSection = DMT_Create_Pdf_Controller.createTitleSection('TENORS');
                contentList.add(titleSection[0]);
                contentList.add(titleSection[1]);
                
                // Tenors Table
                List<List<String>> tenorsHead = new List<List<String>>{new List<String>{'PAYMENT DATE', 'DRAWN NOTIONAL AMOUNT', 'UNDRAWN NOTIONAL AMOUNT', 'DRAWN SPREAD (BPS)', 'UNDRAWN SPREAD (BPS)', 'ACCRUAL FEES (BPS)', 'ACCRUAL FEES (BPS)'}};
                List<List<String>> tenorsBody = new List<List<String>>();
                if (!oppProduct.oppTenors.isEmpty()) {
                    for (DMT_Opportunity_Tenor__c tenor : oppProduct.oppTenors) {
                        tenorsBody.add(new List<String>{
                            DMT_FormattingUtils.changeDateFormat(tenor.gf_tenor_date__c),
                            DMT_FormattingUtils.formatCurrencyAmount(tenor.gj_nominal_amount_db__c, tenor.CurrencyIsoCode),
                            DMT_FormattingUtils.formatCurrencyAmount(tenor.gf_nominal_amount_fb__c, tenor.CurrencyIsoCode),
                            DMT_FormattingUtils.checkNull(tenor.gf_spread_db__c),
                            DMT_FormattingUtils.checkNull(tenor.gf_spread_fb__c),
                            DMT_FormattingUtils.checkNull(tenor.gf_accrual_fees_bp__c),
                            DMT_FormattingUtils.checkNull(tenor.gf_non_accrual_fees_bp__c)
                        });
                    }
                } else {
                    tenorsBody.add(new List<String>{'', '', '', '', '', '', ''});
                }
                Map<String, Object> tenorsTable = DMT_Create_Pdf_Controller.createTable(tenorsHead, tenorsBody);
                contentList.add(tenorsTable);

                pageBreak = new Map<String, Object>{
                    'type' => 'pageBreak',
                    'threshold' => 50
                };
                contentList.add(pageBreak);
                
                // Funding Section Title
                Map<String, Object> fundingTitle = DMT_Create_Pdf_Controller.createTitle('Funding');
                fundingTitle.put('type', 'text');
                style = (Map<String, Object>) fundingTitle.get('style');
                style.put('fontSize', 14);
                style.put('textColor', '#004481');
                contentList.add(fundingTitle);
                
                // Funding Pairs (two columns)
                List<String> fundingLabels = new List<String>{'Funding Curve', 'Funding Term', 'Funding Drawn (BPS)', 'Funding Undrawn (BPS)', 'Green Bonus', 'Social Bonus'};
                List<String> fundingValues = new List<String>{
                    DMT_FormattingUtils.checkNull(oppProduct.fundingCurve),
                    DMT_FormattingUtils.checkNull(oppProduct.fundingTerm),
                    DMT_FormattingUtils.formatCurrencyAmount(oppProduct.fundingDrawnBPS, oppProduct.CurrencyIsoCode),
                    DMT_FormattingUtils.formatCurrencyAmount(oppProduct.fundingUndrawnBPS, oppProduct.CurrencyIsoCode),
                    oppProduct.greenBonus ? 'Yes' : 'No',
                    oppProduct.socialBonus ? 'Yes' : 'No'
                };
                contentList.add(DMT_Create_Pdf_Controller.createListText(fundingLabels, fundingValues, ''));

                pageBreak = new Map<String, Object>{
                    'type' => 'pageBreak',
                    'threshold' => 50
                };
                contentList.add(pageBreak);
                
                // Country Risk Section Title
                Map<String, Object> countryRiskTitle = DMT_Create_Pdf_Controller.createTitle('Country Risk');
                countryRiskTitle.put('type', 'text');
                style = (Map<String, Object>) countryRiskTitle.get('style');
                style.put('fontSize', 14);
                style.put('textColor', '#004481');
                contentList.add(countryRiskTitle);
                
                // Country Risk Pairs (two columns)
                List<String> countryLabels = new List<String>{'Country', 'Country Rating'};
                List<String> countryValues = new List<String>{
                    DMT_FormattingUtils.checkNull(oppProduct.country),
                    DMT_FormattingUtils.checkNull(oppProduct.countryRating)
                };
                contentList.add(DMT_Create_Pdf_Controller.createListText(countryLabels, countryValues, ''));

                pageBreak = new Map<String, Object>{
                    'type' => 'pageBreak',
                    'threshold' => 50
                };
                contentList.add(pageBreak);
                
                // Mitigants Section Title
                Map<String, Object> mitigantTitle = DMT_Create_Pdf_Controller.createTitle('Mitigants');
                mitigantTitle.put('type', 'text');
                style = (Map<String, Object>) mitigantTitle.get('style');
                style.put('fontSize', 14);
                style.put('textColor', '#004481');
                contentList.add(mitigantTitle);
                
                // Currency Mitigant (with empty second column)
                List<String> mitigantLabels = new List<String>{'Currency Mitigant', ''};
                List<String> mitigantValues = new List<String>{DMT_FormattingUtils.checkNull(oppProduct.currencyMitigant), ''};
                contentList.add(DMT_Create_Pdf_Controller.createListText(mitigantLabels, mitigantValues, ''));
                
                // Real Guarantees Table
                List<List<String>> realGuarHead = new List<List<String>>{new List<String>{'MITIGANT TYPE', 'COMMERCIAL RISK (%)', 'POLITICAL RISK (%)', 'EXTERNAL RATING', 'LIQUIDATION PERIOD'}};
                List<List<String>> realGuarBody = new List<List<String>>();
                // Guarantors Table
                List<List<String>> guarHead = new List<List<String>>{new List<String>{'MITIGANT TYPE', 'COMMERCIAL RISK (%)', 'POLITICAL RISK (%)', 'EXTERNAL RATING', 'CLIENT TYPE', 'SCRA', 'ASSET VALUE CORRELATION', 'GUARANTOR EUROPEAN ECA', 'EUROPEAN BANK'}};
                List<List<String>> guarBody = new List<List<String>>();
                if (!oppProduct.oppMitigants.isEmpty()) {
                     // Real Guarantees Table
                    for (DMT_Opportunity_Mitigant__c mitigant : oppProduct.oppMitigants) {
                        realGuarBody.add(new List<String>{
                            DMT_FormattingUtils.checkNull(mitigant.Mitigant_Type__c),
                            String.valueOf(mitigant.Commercial_Percentage__c),
                            String.valueOf(mitigant.Political_Percentage__c),
                            DMT_FormattingUtils.checkNull(mitigant.External_Rating__c),
                            DMT_FormattingUtils.checkNull(mitigant.Liquidation_Period__c)
                        });
                        
                        // Guarantors Table
                        guarBody.add(new List<String>{
                            DMT_FormattingUtils.checkNull(mitigant.Mitigant_Type__c),
                            String.valueOf(mitigant.Commercial_Percentage__c),
                            String.valueOf(mitigant.Political_Percentage__c),
                            DMT_FormattingUtils.checkNull(mitigant.External_Rating__c),
                            DMT_FormattingUtils.checkNull(mitigant.Counterpart__c),
                            DMT_FormattingUtils.checkNull(mitigant.SCRA__c),
                            mitigant.AVC_Check__c ? 'Yes' : 'No',
                            mitigant.Garantor_European_ECA__c ? 'Yes' : 'No',
                            mitigant.European_Bank_Check__c ? 'Yes' : 'No'
                        });
                    }
                } else {
                    // Real Guarantees Table
                       realGuarBody.add(new List<String>{
                           '','','','',''
                       });
                       // Guarantors Table
                       guarBody.add(new List<String>{
                           '','','','','','','','',''
                       });
                }
                titleSection = DMT_Create_Pdf_Controller.createTitleSection(System.Label.dmt_cl_Collateral_Guarantees_Text);
                contentList.add(titleSection[0]);
                contentList.add(titleSection[1]);
                contentList.add(DMT_Create_Pdf_Controller.createTable(realGuarHead, realGuarBody));

                titleSection = DMT_Create_Pdf_Controller.createTitleSection(System.Label.dmt_cl_Guarantors_Text);
                contentList.add(titleSection[0]);
                contentList.add(titleSection[1]);
                contentList.add(DMT_Create_Pdf_Controller.createTable(guarHead, guarBody));
                
                component.put('content', contentList);
                component.put('name', 'Products');
            }
            return component;
        } catch (Exception e) {
            System.debug('Error in DMT_OpportunityProductsRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OpportunityProductsRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}