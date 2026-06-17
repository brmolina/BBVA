public with sharing class DMT_OppProductSimpleRenderer implements DMT_ViewRenderer {

    // ==========================================
    // HELPER METHODS: Form Grids (DisplayFields)
    // ==========================================

    private List<DMT_FormattingUtils.DisplayField> buildDetailFields(DMT_ViewController.OpportunityProduct oppProduct) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Name', DMT_FormattingUtils.checkNull(oppProduct.name))
        };
    }

   

    private List<DMT_FormattingUtils.DisplayField> buildFundingFields(DMT_ViewController.OpportunityProduct oppProduct) {
        List<DMT_FormattingUtils.DisplayField> fundingFields = new List<DMT_FormattingUtils.DisplayField>();
        Boolean fundingManual = oppProduct.fundingCurve == 'Manual';

        fundingFields.add(new DMT_FormattingUtils.DisplayField('Funding Manual', fundingManual));
        if (fundingManual) {
            fundingFields.add(new DMT_FormattingUtils.DisplayField('Funding Drawn (BPS)', DMT_FormattingUtils.formatCurrencyAmount(oppProduct.fundingDrawnBPS, oppProduct.TenorsCurrency)));
            fundingFields.add(new DMT_FormattingUtils.DisplayField('Funding Undrawn (BPS)', DMT_FormattingUtils.formatCurrencyAmount(oppProduct.fundingUndrawnBPS, oppProduct.TenorsCurrency)));
        } else {
            fundingFields.add(new DMT_FormattingUtils.DisplayField('Time of Cost of Funding', DMT_FormattingUtils.checkNull(oppProduct.fundingTerm)));
        }
        return fundingFields;
    }



    private String getSafePercentage(Decimal val) {
        return val != null ? String.valueOf(Integer.valueOf(val)) : '';
    }

    // ==========================================
    // DATA TABLE BUILDERS (For Lists of Records)
    // ==========================================

  

    private List<DMT_FormattingUtils.DataTableWrapper> buildMitigantTables(DMT_ViewController.OpportunityProduct oppProduct) {
        DMT_FormattingUtils.DataTableWrapper collateralTable = new DMT_FormattingUtils.DataTableWrapper(System.Label.dmt_cl_Collateral_Guarantees_Text, new List<String>{
            'Collateral Type', 'Commercial Risk (%)', 'Political Risk (%)', 'End Date', 'Internal Rating'
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
                        DMT_FormattingUtils.checkNull(mit.Internal_Rating__c)
                        
                    });
                } 
            }
        }

        return new List<DMT_FormattingUtils.DataTableWrapper>{ collateralTable};
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
               

                htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Cost of Funding</h3><div class="slds-scope">'
                            + DMT_FormattingUtils.generateHtmlTable(buildFundingFields(oppProduct))
                            + '</div>&nbsp;</br>';

            


                htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Mitigants</h3><div class="slds-scope">';

                // MITIGANTS TABLES (Collateral)
                List<DMT_FormattingUtils.DataTableWrapper> mitigantTables = buildMitigantTables(oppProduct);
                for (DMT_FormattingUtils.DataTableWrapper mitTable : mitigantTables) {
                    htmlOutput += '<div>' + DMT_FormattingUtils.renderHtmlDataTable(mitTable) + '</div>&nbsp;</br>';
                }
            }
            return htmlOutput + '</div>';

        } catch (Exception e){
            System.debug('Error in DMT_OppProductSimleRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
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

                // Funding
                contentList.add(new Map<String, Object>{ 'type' => 'text', 'text' => 'Cost of Funding', 'style' => new Map<String, Object>{'fontSize'=>14, 'textColor'=>'#004481'} });
                contentList.add(DMT_Create_Pdf_Controller.generatePdfList(buildFundingFields(oppProduct)));
                contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });

               

              

                // Mitigants Base
                contentList.add(new Map<String, Object>{ 'type' => 'text', 'text' => 'Mitigants', 'style' => new Map<String, Object>{'fontSize'=>14, 'textColor'=>'#004481'} });

                // Mitigants Tables (Collateral)
                for (DMT_FormattingUtils.DataTableWrapper mitTable : buildMitigantTables(oppProduct)) {
                    if (!mitTable.rows.isEmpty()) {
                        List<Object> mitTitle = DMT_Create_Pdf_Controller.createTitleSection(mitTable.title);
                        contentList.add(mitTitle[0]); contentList.add(mitTitle[1]);
                        contentList.add(DMT_Create_Pdf_Controller.createTable(new List<List<String>>{mitTable.headers}, mitTable.rows));
                    }
                }
                contentList.add(new Map<String, Object>{
                    'type' => 'text',
                    'text' => ' ',
                    'style' => new Map<String, Object>{ 'fontSize' => 24 }
                });

                component.put('content', contentList);
                component.put('name', 'Products');
            }
            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OppProductSimpleRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            return new Map<String, Object>();
        }
    }
}