public with sharing class DMT_LineSanctionProductsRenderer implements DMT_ViewRenderer {

    // ==========================================
    // HELPER: Build the DisplayField List
    // ==========================================
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data, DMT_Risk_Line_Term__c riskLine) {
        
        DMT_Currency_Provision__c provision = data.riskLineToCurrencyProvisionMap.get(riskLine.Id);
        String availCurrencies = (provision != null && provision.g_currency_id__c != null) ? provision.g_currency_id__c : 'All Currencies';
        String mitigants = DMT_FormattingUtils.getWarrantyNamesAsString(data.riskLineToWarrantyListMap.get(riskLine.Id));

        // Dynamically add currency Iso Code to the Amount label if available
        String amountLabel = 'Amount' + (String.isNotBlank(data.currencyIsoCode) ? ' (' + data.currencyIsoCode + ')' : '');

        return new List<DMT_FormattingUtils.DisplayField>{
            // Row 1
            new DMT_FormattingUtils.DisplayField(amountLabel, DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Amount__c, riskLine.CurrencyIsoCode)),
            new DMT_FormattingUtils.DisplayField('Currency', DMT_FormattingUtils.checkNull(riskLine.CurrencyIsoCode)),

            // Row 2
            new DMT_FormattingUtils.DisplayField('Available Currencies for disposals', availCurrencies),
            new DMT_FormattingUtils.DisplayField('Required mitigants', mitigants),

            // Row 3
            new DMT_FormattingUtils.DisplayField('Typology of financial program risks', DMT_FormattingUtils.checkNull(data.line.g_limit_last_level_type__c)),
            new DMT_FormattingUtils.DisplayField('Multioperation indicator', riskLine.g_multioperation_ind_type__c), 

            // Row 4
            new DMT_FormattingUtils.DisplayField('Global Product', DMT_FormattingUtils.checkNull(riskLine.DMT_Product__r?.Name)),
            new DMT_FormattingUtils.DisplayField('Global Product Subcategory', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id)?.get('subcategoryProduct'))),

            // Row 5
            new DMT_FormattingUtils.DisplayField('Global Product Category', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id)?.get('categoryProduct'))),
            new DMT_FormattingUtils.DisplayField('Global Product Subfamily', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id)?.get('subfamilyProduct'))),

            // Row 6
            new DMT_FormattingUtils.DisplayField('Global Product Family', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id)?.get('familyProduct'))),
            new DMT_FormattingUtils.DisplayField('Initial Term', DMT_FormattingUtils.checkNull(riskLine.DMT_Init_Term__c)),

            // Row 7
            new DMT_FormattingUtils.DisplayField('Maximum Term', DMT_FormattingUtils.checkNull(riskLine.DMT_End_Term__c)),
            new DMT_FormattingUtils.DisplayField('Booking Geography', DMT_FormattingUtils.checkNull(data.riskLineToTaxonomyH007Map.get(riskLine.Id))),

            // Row 8 (Full Width)
            new DMT_FormattingUtils.DisplayField('Comments', DMT_FormattingUtils.checkNull(riskLine.DMT_Comments__c)),
            new DMT_FormattingUtils.DisplayField('Line / Opportunity', DMT_FormattingUtils.checkNull(riskLine.g_line_commitment_level_type__c))
            
        };
    }

    // ==========================================
    // HTML RENDERING
    // ==========================================
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty() || data.riskLineList.isEmpty()) {
            return '<div>Sanction Product data not provided</div>';
        }

        try {
            String htmlOutput = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Products</h2>';
            
            // Iterate over all products (Risk Line Terms)
            for (DMT_Risk_Line_Term__c riskLine : data.riskLineList) {
                
                List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data, riskLine);

                // Add Sub-Header for each product and generate table
                htmlOutput += '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px; font-weight: bold">' + DMT_FormattingUtils.checkNull(riskLine.Name) + '</h3>'
                    + '<div class="slds-scope">'
                    + DMT_FormattingUtils.generateHtmlTable(fieldsToRender)
                    + '</div><br/>';
            }
            
            htmlOutput += '</div>&nbsp;</br>';
            return htmlOutput;

        } catch (Exception e){
            System.debug('Error in DMT_LineSanctionProductsRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    // ==========================================
    // PDF RENDERING
    // ==========================================
    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty() || data.riskLineList.isEmpty()) {
            return new Map<String, Object>();
        }

        try {
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>(); 
            
            // 1. Create Main Title
            contentList.add(DMT_Create_Pdf_Controller.createTitle('Products'));

            // 2. Iterate over all products
            for (DMT_Risk_Line_Term__c riskLine : data.riskLineList) {
                
                // Add page break before each product (matching old renderer logic)
                contentList.add(new Map<String, Object>{
                    'type' => 'pageBreak',
                    'threshold' => 20
                });

                // Add Sub-Title for the Product
                contentList.add(DMT_Create_Pdf_Controller.createTitle(DMT_FormattingUtils.checkNull(riskLine.Name)));
                
                // Generate the Dynamic List
                List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data, riskLine);
                contentList.add(DMT_Create_Pdf_Controller.generatePdfList(fieldsToRender));
            }

            component.put('content', contentList);
            component.put('name', 'Sanction Products');
            
            return component;

        } catch (Exception e){
            System.debug('Error in DMT_LineSanctionProductsRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_LineSanctionProductsRenderer', 'renderPdfJson', 'DMT', ''));
            return new Map<String, Object>();
        }
    }
}