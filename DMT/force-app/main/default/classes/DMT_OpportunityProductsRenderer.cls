public with sharing class DMT_OpportunityProductsRenderer implements DMT_ViewRenderer {

    // ==========================================
    // HELPER METHODS: Form Grids (DisplayFields)
    // ==========================================

    private List<DMT_FormattingUtils.DisplayField> buildDetailFields(DMT_ViewController.OpportunityProduct oppProduct) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Name', DMT_FormattingUtils.checkNull(oppProduct.name)),
            new DMT_FormattingUtils.DisplayField('', ''), // Empty field for spacing in 2-column layout
            new DMT_FormattingUtils.DisplayField('Product Start Date', DMT_FormattingUtils.changeDateFormat(oppProduct.initialDate)),
            new DMT_FormattingUtils.DisplayField('Product Maturity Date', DMT_FormattingUtils.changeDateFormat(oppProduct.maturityDate)),
            new DMT_FormattingUtils.DisplayField('Risk Type', DMT_FormattingUtils.checkNull(oppProduct.riskType)),
            new DMT_FormattingUtils.DisplayField('Use of Proceeds', DMT_FormattingUtils.checkNull(oppProduct.useOfProceeds)),
            new DMT_FormattingUtils.DisplayField('Comments:', DMT_FormattingUtils.checkNull(oppProduct.comments))
        };
    }

    /*private List<DMT_FormattingUtils.DisplayField> buildAmortizationFields(DMT_ViewController.OpportunityProduct oppProduct) {
        List<DMT_FormattingUtils.DisplayField> amortizationFields = new List<DMT_FormattingUtils.DisplayField>();
        amortizationFields.add(new DMT_FormattingUtils.DisplayField('Amortization Type', DMT_FormattingUtils.checkNull(oppProduct.amortizationType)));
        amortizationFields.add(new DMT_FormattingUtils.DisplayField('Interest Payment Frequency', DMT_FormattingUtils.checkNull(oppProduct.paymentFrequency)));
        amortizationFields.add(new DMT_FormattingUtils.DisplayField('Rate Type', DMT_FormattingUtils.checkNull(oppProduct.rateType)));

        if (oppProduct.amortizationType == 'User-Defined') {
            amortizationFields.add(new DMT_FormattingUtils.DisplayField('Bullet', DMT_FormattingUtils.checkNull(oppProduct.bullet)));
            amortizationFields.add(new DMT_FormattingUtils.DisplayField('Balloon', DMT_FormattingUtils.checkNull(oppProduct.balloon)));
        }

        amortizationFields.add(new DMT_FormattingUtils.DisplayField('Product Currency', DMT_FormattingUtils.checkNull(oppProduct.TenorsCurrency)));
        amortizationFields.add(new DMT_FormattingUtils.DisplayField('Tenors Amount', DMT_FormattingUtils.checkNull(oppProduct.dealAmountTenors + ' ' + oppProduct.TenorsCurrency)));
        amortizationFields.add(new DMT_FormattingUtils.DisplayField('', ''));
        amortizationFields.add(new DMT_FormattingUtils.DisplayField('Accrual Fee (BPS)', DMT_FormattingUtils.checkNull(oppProduct.gf_accrual_fees_bp)));
        amortizationFields.add(new DMT_FormattingUtils.DisplayField('Extension/Duration Fees (BPS)', DMT_FormattingUtils.checkNull(oppProduct.extensionDurationFees)));
        amortizationFields.add(new DMT_FormattingUtils.DisplayField('New Money for BBVA', DMT_FormattingUtils.checkNull(oppProduct.newMoney)));
        amortizationFields.add(new DMT_FormattingUtils.DisplayField('Old Money for BBVA', DMT_FormattingUtils.checkNull(oppProduct.oldMoney)));
        amortizationFields.add(new DMT_FormattingUtils.DisplayField('Expected Final Take', DMT_FormattingUtils.checkNull(oppProduct.expectedFinalTake)));
        amortizationFields.add(new DMT_FormattingUtils.DisplayField('Lifetime Expected Drawn (%)', DMT_FormattingUtils.checkNull(oppProduct.expectedDrawn)));
        return amortizationFields;
    }*/

    private List<DMT_FormattingUtils.DisplayField> buildDealDescriptionFields(DMT_ViewController.OpportunityProduct oppProduct) {
        List<DMT_FormattingUtils.DisplayField> dealDescriptionFields = new List<DMT_FormattingUtils.DisplayField>();
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Deal amount', DMT_FormattingUtils.checkNull(oppProduct.dealAmount)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('BBVA commitment amount', DMT_FormattingUtils.checkNull(oppProduct.bbvaPrtcpTrancheAmount)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('New Money for BBVA', DMT_FormattingUtils.checkNull(oppProduct.newMoney)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Old Money for BBVA', DMT_FormattingUtils.checkNull(oppProduct.oldMoney)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Expected BBVA Final Take', DMT_FormattingUtils.checkNull(oppProduct.expectedFinalTakeBBVA)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Expected Drawn (%)', DMT_FormattingUtils.checkNull(oppProduct.expectedDrawn)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Liquidity Fee (bps)', DMT_FormattingUtils.checkNull(oppProduct.liquidityFee)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Commitment Fees (bps)', DMT_FormattingUtils.checkNull(oppProduct.commitmentFees)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Extension/Duration Fee (bps)', DMT_FormattingUtils.checkNull(oppProduct.extensionDurationFees)));
        dealDescriptionFields.add(new DMT_FormattingUtils.DisplayField('Other Fees (bps)', DMT_FormattingUtils.checkNull(oppProduct.otherFees)));
        return dealDescriptionFields;
    }

    private List<DMT_FormattingUtils.DisplayField> buildScheduleFields(DMT_ViewController.OpportunityProduct oppProduct) {
        List<DMT_FormattingUtils.DisplayField> scheduleFields = new List<DMT_FormattingUtils.DisplayField>();
        scheduleFields.add(new DMT_FormattingUtils.DisplayField('Amortization Type', DMT_FormattingUtils.checkNull(oppProduct.amortizationType)));
        scheduleFields.add(new DMT_FormattingUtils.DisplayField('Interest Rate Period', DMT_FormattingUtils.checkNull(oppProduct.paymentFrequency)));
        scheduleFields.add(new DMT_FormattingUtils.DisplayField('Margin Rate Type', DMT_FormattingUtils.checkNull(oppProduct.rateType)));
        scheduleFields.add(new DMT_FormattingUtils.DisplayField('Currency', DMT_FormattingUtils.checkNull(oppProduct.TenorsCurrency)));
        scheduleFields.add(new DMT_FormattingUtils.DisplayField('Accrual Fees', DMT_FormattingUtils.checkNull(oppProduct.gf_accrual_fees_bp)));
        return scheduleFields;
    }

    private List<DMT_FormattingUtils.DisplayField> buildPricingGridField(DMT_ViewController.OpportunityProduct oppProduct) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Pricing Grid or Step-ups (if applicable)', DMT_FormattingUtils.checkNull(oppProduct.pricingGrid), 'FULL')
        };
    }

    private List<DMT_FormattingUtils.DisplayField> buildFundingFields(DMT_ViewController.OpportunityProduct oppProduct) {
        List<DMT_FormattingUtils.DisplayField> fundingFields = new List<DMT_FormattingUtils.DisplayField>();
        Boolean fundingManual = oppProduct.fundingCurve == 'Manual';

        fundingFields.add(new DMT_FormattingUtils.DisplayField('CoF Manual', fundingManual));
        if (fundingManual) {
            fundingFields.add(new DMT_FormattingUtils.DisplayField('CoF Drawn (BPS)', DMT_FormattingUtils.formatCurrencyAmount(oppProduct.fundingDrawnBPS, oppProduct.TenorsCurrency)));
            fundingFields.add(new DMT_FormattingUtils.DisplayField('CoF Undrawn (BPS)', DMT_FormattingUtils.formatCurrencyAmount(oppProduct.fundingUndrawnBPS, oppProduct.TenorsCurrency)));
        } else {
            fundingFields.add(new DMT_FormattingUtils.DisplayField('Time of Cost of Funding', DMT_FormattingUtils.checkNull(oppProduct.fundingTerm)));
        }
        return fundingFields;
    }

    private List<DMT_FormattingUtils.DisplayField> buildSustainabilityFields(DMT_ViewController.OpportunityProduct oppProduct) {
        // Assessment and Subtype are standard picklists
        String assessPickLabel = Util_Picklist.getLabelFromAPI('OpportunityLineItem', 'DMT_sustainable_deal_assessment__c').get(oppProduct.sustainableDealAssessment);
        String subtypePickLabel = Util_Picklist.getLabelFromAPI('OpportunityLineItem', 'DMT_Sustainable_Deal_Subtype__c').get(oppProduct.sustainableDealSubtype);
        
        // Ensure fallbacks if picklist labels return null
        assessPickLabel = assessPickLabel != null ? assessPickLabel : oppProduct.sustainableDealAssessment;
        subtypePickLabel = subtypePickLabel != null ? subtypePickLabel : oppProduct.sustainableDealSubtype;

        // Map Green Activity Filter
        String greenFilterLabel = '';
        if (oppProduct.greenActivityFilter == 'delegated') {
            greenFilterLabel = 'Delegated Label';
        } else if (oppProduct.greenActivityFilter == 'other') {
            greenFilterLabel = 'Other Green Activity';
        } else {
            greenFilterLabel = oppProduct.greenActivityFilter;
        }

        // Deal Label uses the translated value from the taxonomy query
        String dealLabel = oppProduct.sustainableDealLabel; 

        return new List<DMT_FormattingUtils.DisplayField>{
            // Row 1
            new DMT_FormattingUtils.DisplayField('Sustainable Deal Assessment', DMT_FormattingUtils.checkNull(assessPickLabel)),
            new DMT_FormattingUtils.DisplayField('Sustainable Deal Subcategory', DMT_FormattingUtils.checkNull(subtypePickLabel)),
            
            // Row 2
            new DMT_FormattingUtils.DisplayField('Green Activity Filter', DMT_FormattingUtils.checkNull(greenFilterLabel)),
            new DMT_FormattingUtils.DisplayField('Sustainable Deal Label', DMT_FormattingUtils.checkNull(dealLabel)),
            
            // Row 3
            new DMT_FormattingUtils.DisplayField('Sustainability Percentage (%)', DMT_FormattingUtils.checkNull(oppProduct.sustainablePercentage)),
            new DMT_FormattingUtils.DisplayField('Sustainability bonus-eligible', DMT_FormattingUtils.checkNull(oppProduct.sustainabilityBonusEligible))
        };
    }

    private List<DMT_FormattingUtils.DisplayField> buildCountryRiskFields(DMT_ViewController.OpportunityProduct oppProduct) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Country', DMT_FormattingUtils.checkNull(oppProduct.country))
            // new DMT_FormattingUtils.DisplayField('Country Rating', DMT_FormattingUtils.checkNull(oppProduct.countryRating))
        };
    }

    private String getSafePercentage(Decimal val) {
        return val != null ? String.valueOf(Integer.valueOf(val)) : '';
    }

    // ==========================================
    // DATA TABLE BUILDERS (For Lists of Records)
    // ==========================================

    private DMT_FormattingUtils.DataTableWrapper buildTenorsTable(DMT_ViewController.OpportunityProduct oppProduct) {
        DMT_FormattingUtils.DataTableWrapper table = new DMT_FormattingUtils.DataTableWrapper('Repayment Schedule', new List<String>{
            'Payment Date', 'Drawn Amount', 'Undrawn Amount', 'Drawn Spread (BPS)', 'Undrawn Spread (BPS)', 'Non Accrual Fees (amount)', 'Non Accrual Fees (BPS)'
        });

        if (!oppProduct.oppTenors.isEmpty()) {
            for (DMT_Opportunity_Tenor__c tenor : oppProduct.oppTenors) {
                table.rows.add(new List<String>{
                    DMT_FormattingUtils.changeDateFormat(tenor.gf_tenor_date__c),
                    DMT_FormattingUtils.formatCurrencyAmount(tenor.gj_nominal_amount_db__c, oppProduct.TenorsCurrency),
                    DMT_FormattingUtils.formatCurrencyAmount(tenor.gf_nominal_amount_fb__c, oppProduct.TenorsCurrency),
                    DMT_FormattingUtils.checkNull(tenor.gf_spread_db__c),
                    DMT_FormattingUtils.checkNull(tenor.gf_spread_fb__c),
                    DMT_FormattingUtils.checkNull(tenor.gf_accrual_fees_bp__c),
                    DMT_FormattingUtils.checkNull(tenor.gf_non_accrual_fees_bp__c)
                });
            }
        }
        return table;
    }

    private List<DMT_FormattingUtils.DataTableWrapper> buildMitigantTables(DMT_ViewController.OpportunityProduct oppProduct) {
        DMT_FormattingUtils.DataTableWrapper collateralTable = new DMT_FormattingUtils.DataTableWrapper(System.Label.dmt_cl_Collateral_Guarantees_Text, new List<String>{
            'Collateral Type', 'Commercial Risk (%)', 'Political Risk (%)', 'End Date', 'Internal Rating', 'External Rating', 'Currency', 'Country Collateral', 'Liquidation Period'
        });

        DMT_FormattingUtils.DataTableWrapper guarantorTable = new DMT_FormattingUtils.DataTableWrapper(System.Label.dmt_cl_Guarantors_Text, new List<String>{
            'Mitigant Type', 'Guarantor (IDClient - Nombre)', 'Commercial Risk (%)', 'Political Risk (%)', 'End Date', 'Internal Rating', 'Scoring', 'External Rating', 'Currency'
        });

        Set<String> validCollateralTypes = new Set<String>{
            'Real > Mortgage guarantee', 'Real > Cash', 'Real > Gold Bullion', 'Real > Debt securities', 'Real > Debt securities issued by central governments or central Banks', 'Real > Receivables', 'Real > Index equities and Index convertible bonds', 'Real > Securitisation', 'Real > Others real'
        };

        Set<String> validUnfundedTypes = new Set<String>{
            'Others > Guarantee in favour of Public Administration', 'Others > ECA Guarantor (Exporte Credit agency)', 'Others > Shared maintenance clause', 'Personal > Parent guarantee', 'Personal > Corporate', 'Personal > Bank'
        };

        if (!oppProduct.oppMitigants.isEmpty()) {
            for (DMT_Opportunity_Mitigant__c mit : oppProduct.oppMitigants) {
                String type = mit.Mitigant_Type__c;
                if (String.isBlank(type)) continue;

                if (validCollateralTypes.contains(type)) {
                    collateralTable.rows.add(new List<String>{
                        DMT_FormattingUtils.checkNull(type),
                        getSafePercentage(mit.Commercial_Percentage__c),
                        getSafePercentage(mit.Political_Percentage__c),
                        DMT_FormattingUtils.checkNull(mit.End_Date__c),
                        DMT_FormattingUtils.checkNull(mit.Internal_Rating__c),
                        DMT_FormattingUtils.checkNull(mit.External_Rating__c),
                        DMT_FormattingUtils.checkNull(mit.DMT_Currency__c),
                        DMT_FormattingUtils.checkNull(mit.DMT_Country_Guarantor__c),
                        DMT_FormattingUtils.checkNull(mit.Liquidation_Period__c)
                    });
                } else if (validUnfundedTypes.contains(type)) {
                    guarantorTable.rows.add(new List<String>{
                        DMT_FormattingUtils.checkNull(type),
                        DMT_FormattingUtils.checkNull(mit.DMT_Guarantor_Display__c),
                        getSafePercentage(mit.Commercial_Percentage__c),
                        getSafePercentage(mit.Political_Percentage__c),
                        DMT_FormattingUtils.checkNull(mit.End_Date__c),
                        DMT_FormattingUtils.checkNull(mit.Internal_Rating__c),
                        String.valueOf(mit.DMT_Scoring__c != null ? mit.DMT_Scoring__c : 0),
                        DMT_FormattingUtils.checkNull(mit.External_Rating__c),
                        DMT_FormattingUtils.checkNull(mit.DMT_Currency__c)
                    });
                }
            }
        }

        return new List<DMT_FormattingUtils.DataTableWrapper>{ collateralTable, guarantorTable };
    }

    // ==========================================
    // MAIN RENDER METHODS
    // ==========================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.oppProducts.isEmpty()) return '<div>Product data not provided</div>';

        try {
            String htmlOutput = '<div><h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Products</h2>';

            for (DMT_ViewController.OpportunityProduct oppProduct : data.oppProducts) {

                htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">General Info</h3><div class="slds-scope">'
                            + DMT_FormattingUtils.generateHtmlTable(buildDetailFields(oppProduct))
                            + '</div>&nbsp;</br>';

                /*htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Amortization</h3><div class="slds-scope">'
                            + DMT_FormattingUtils.generateHtmlTable(buildAmortizationFields(oppProduct))
                            + '</div>&nbsp;</br>';
                */
                //Deal Description
                htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Deal description</h3><div class="slds-scope">'
                            + DMT_FormattingUtils.generateHtmlTable(buildDealDescriptionFields(oppProduct))
                            + '</div>&nbsp;</br>';

                //Schedule
                htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Schedule</h3><div class="slds-scope">'
                            + DMT_FormattingUtils.generateHtmlTable(buildScheduleFields(oppProduct))
                            + '</div>&nbsp;</br>';

                // TENORS TABLE
                htmlOutput += '<div>' + DMT_FormattingUtils.renderHtmlDataTable(buildTenorsTable(oppProduct)) + '</div>';

                // PRICING GRID (Immediately following table)
                htmlOutput += '<div class="slds-scope">' + DMT_FormattingUtils.generateHtmlTable(buildPricingGridField(oppProduct)) + '</div>&nbsp;</br>';

                htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Cost of Funding</h3><div class="slds-scope">'
                            + DMT_FormattingUtils.generateHtmlTable(buildFundingFields(oppProduct))
                            + '</div>&nbsp;</br>';

                htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Sustainability</h3><div class="slds-scope">'
                            + DMT_FormattingUtils.generateHtmlTable(buildSustainabilityFields(oppProduct))
                            + '</div>&nbsp;</br>';

                htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Country Risk</h3><div class="slds-scope">'
                            + DMT_FormattingUtils.generateHtmlTable(buildCountryRiskFields(oppProduct))
                            + '</div>&nbsp;</br>';

                htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Mitigants</h3><div class="slds-scope">';

                // MITIGANTS TABLES (Collateral & Guarantors)
                List<DMT_FormattingUtils.DataTableWrapper> mitigantTables = buildMitigantTables(oppProduct);
                for (DMT_FormattingUtils.DataTableWrapper mitTable : mitigantTables) {
                    htmlOutput += '<div>' + DMT_FormattingUtils.renderHtmlDataTable(mitTable) + '</div>&nbsp;</br>';
                }
            }
            return htmlOutput + '</div>';

        } catch (Exception e){
            System.debug('Error in DMT_OpportunityProductsRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.oppProducts.isEmpty()) return new Map<String, Object>();

        try {
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();
            contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 60 });
            contentList.add(DMT_Create_Pdf_Controller.createTitle('Products'));

            for (DMT_ViewController.OpportunityProduct oppProduct : data.oppProducts) {
                contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });

                // General Info
                contentList.add(new Map<String, Object>{ 'type' => 'text', 'text' => 'General Info', 'style' => new Map<String, Object>{'fontSize'=>14, 'textColor'=>'#004481'} });
                contentList.add(DMT_Create_Pdf_Controller.generatePdfList(buildDetailFields(oppProduct)));
                contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });

                // Amortization
                /*contentList.add(new Map<String, Object>{ 'type' => 'text', 'text' => 'Amortization', 'style' => new Map<String, Object>{'fontSize'=>14, 'textColor'=>'#004481'} });
                contentList.add(DMT_Create_Pdf_Controller.generatePdfList(buildAmortizationFields(oppProduct)));*/

                // Deal description
                contentList.add(new Map<String, Object>{ 'type' => 'text', 'text' => 'Deal description', 'style' => new Map<String, Object>{'fontSize'=>14, 'textColor'=>'#004481'} });
                contentList.add(DMT_Create_Pdf_Controller.generatePdfList(buildDealDescriptionFields(oppProduct)));

                //Schedule
                contentList.add(new Map<String, Object>{ 'type' => 'text', 'text' => 'Schedule', 'style' => new Map<String, Object>{'fontSize'=>14, 'textColor'=>'#004481'} });
                contentList.add(DMT_Create_Pdf_Controller.generatePdfList(buildScheduleFields(oppProduct)));

                // Tenors Table
                DMT_FormattingUtils.DataTableWrapper tenorsData = buildTenorsTable(oppProduct);
                List<Object> tenorsTitle = DMT_Create_Pdf_Controller.createTitleSection(tenorsData.title);
                contentList.add(tenorsTitle[0]); contentList.add(tenorsTitle[1]);
                contentList.add(DMT_Create_Pdf_Controller.createTable(new List<List<String>>{tenorsData.headers}, tenorsData.rows));

                // Pricing Grid Field
                contentList.add(DMT_Create_Pdf_Controller.generatePdfList(buildPricingGridField(oppProduct)));

                contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });

                // Funding
                contentList.add(new Map<String, Object>{ 'type' => 'text', 'text' => 'Cost of Funding', 'style' => new Map<String, Object>{'fontSize'=>14, 'textColor'=>'#004481'} });
                contentList.add(DMT_Create_Pdf_Controller.generatePdfList(buildFundingFields(oppProduct)));
                contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });

                // Sustainability
                contentList.add(new Map<String, Object>{ 'type' => 'text', 'text' => 'Sustainability', 'style' => new Map<String, Object>{'fontSize'=>14, 'textColor'=>'#004481'} });
                contentList.add(DMT_Create_Pdf_Controller.generatePdfList(buildSustainabilityFields(oppProduct)));              
                contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });

                // Country Risk
                contentList.add(new Map<String, Object>{ 'type' => 'text', 'text' => 'Country Risk', 'style' => new Map<String, Object>{'fontSize'=>14, 'textColor'=>'#004481'} });
                contentList.add(DMT_Create_Pdf_Controller.generatePdfList(buildCountryRiskFields(oppProduct)));
                contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });

                // Mitigants Base
                contentList.add(new Map<String, Object>{ 'type' => 'text', 'text' => 'Mitigants', 'style' => new Map<String, Object>{'fontSize'=>14, 'textColor'=>'#004481'} });

                // Mitigants Tables (Collateral & Guarantors)
                for (DMT_FormattingUtils.DataTableWrapper mitTable : buildMitigantTables(oppProduct)) {
                    if (!mitTable.rows.isEmpty()) {
                        List<Object> mitTitle = DMT_Create_Pdf_Controller.createTitleSection(mitTable.title);
                        contentList.add(mitTitle[0]); contentList.add(mitTitle[1]);
                        contentList.add(DMT_Create_Pdf_Controller.createTable(new List<List<String>>{mitTable.headers}, mitTable.rows));
                    }
                }

                component.put('content', contentList);
                component.put('name', 'Products');
            }
            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OpportunityProductsRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            return new Map<String, Object>();
        }
    }
}