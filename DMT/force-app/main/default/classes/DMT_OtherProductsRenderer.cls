public with sharing class DMT_OtherProductsRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty() || data.riskLineList.isEmpty()) {
            return '<div>Product data not provided</div>';
        }
        try {
            String htmlOutput = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">PRODUCTS</h2>';
            for (DMT_Risk_Line_Term__c riskLine : data.riskLineList) {
                String tableRows = '';
                DMT_Currency_Provision__c provision = data.riskLineToCurrencyProvisionMap.get(riskLine.Id);
                if (riskLine.DMT_Parent_Product_Name__c != null) {
                    tableRows += DMT_FormattingUtils.tableRow2columns('Parent Product Name', DMT_FormattingUtils.checkNull(riskLine.DMT_Parent_Product_Name__c), 'Parent Product Id', DMT_FormattingUtils.checkNull(data.line.Line_Id__c) + '_' + DMT_FormattingUtils.checkNull(riskLine.gf_group_priority_line_id__c));
                }
                String amountFormatted = DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Amount__c, data.line.CurrencyIsoCode);
                tableRows += DMT_FormattingUtils.tableRow2columns('Amount:', amountFormatted, 'Currency', DMT_FormattingUtils.checkNull(riskLine.CurrencyIsoCode));
                tableRows += DMT_FormattingUtils.tableRow2columns('Available Currencies:', (provision != null && provision.g_currency_id__c != null) ? provision.g_currency_id__c : 'All Currencies', 'Required mitigants:', DMT_FormattingUtils.getWarrantyNamesAsString(data.riskLineToWarrantyListMap.get(riskLine.Id)));
                tableRows += DMT_FormattingUtils.tableRow2columns('Typology of financial program risks:', DMT_FormattingUtils.checkNull(data.line.g_limit_last_level_type__c), 'Global Product:', DMT_FormattingUtils.checkNull(riskLine.DMT_Product__r?.Name));
                tableRows += DMT_FormattingUtils.tableRow2columns('Global Product Subcategory:', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id).get('subcategoryProduct')), 'Global Product Category:', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id).get('categoryProduct')));
                tableRows += DMT_FormattingUtils.tableRow2columns('Global Product Subfamily:', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id).get('subfamilyProduct')), 'Global Product Family:', DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id).get('familyProduct')));
                tableRows += DMT_FormattingUtils.tableRow2columns('Bullet indicator Limitation:', DMT_FormattingUtils.checkNull(riskLine.g_bullet_ind_type__c), 'Minimum Internal Rating Limitation:', DMT_FormattingUtils.checkNull(riskLine.g_smscl_internal_ratg_type__c));
                tableRows += DMT_FormattingUtils.tableRow2columns('Initial Term:', DMT_FormattingUtils.checkNull(riskLine.DMT_Init_Term__c), 'Maximum Term', DMT_FormattingUtils.checkNull(riskLine.DMT_End_Term__c));
                tableRows += DMT_FormattingUtils.tableRow2columns('Asset Allocation Sector Limitation:', DMT_FormattingUtils.checkNull(data.riskLineToTaxonomyC162Map.get(riskLine.Id)), 'Asset Allocation Subsector Limitation:', DMT_FormattingUtils.checkNull(data.riskLineToTaxonomyC164Map.get(riskLine.Id)));
                tableRows += DMT_FormattingUtils.tableRow2columns('Booking Geography:', DMT_FormattingUtils.checkNull(data.riskLineToTaxonomyH007Map.get(riskLine.Id)), 'Number of months of grace period:', DMT_FormattingUtils.checkNull(riskLine.gf_inscol_months_grace_number__c));
                tableRows += DMT_FormattingUtils.tableRow2columns('Loan to value LTV (%)', DMT_FormattingUtils.checkNull(riskLine.gf_loan_value_per__c), 'Notary formalization indicator GMOD:', DMT_FormattingUtils.checkNull(riskLine.g_notary_crtfn_ind_type__c));
                tableRows += DMT_FormattingUtils.tableRow2columns('Indicator guarantees to public administrations GMOD:', DMT_FormattingUtils.checkNull(riskLine.g_gtee_public_adm_ind_type__c), 'Percentage contribution export credit agency loan:', DMT_FormattingUtils.checkNull(riskLine.gf_loan_eca_cntrb_per__c));
                tableRows += DMT_FormattingUtils.tableRow2columns('Minimum percentage RAROEC with financing:', DMT_FormattingUtils.checkNull(riskLine.gf_min_raroec_fcg_per__c), 'Minimum percentage RAROEC without financing:', DMT_FormattingUtils.checkNull(riskLine.gf_min_raroec_wo_fcg_per__c));
                tableRows += DMT_FormattingUtils.tableRow2columns('Minimum percentage RORC with financing:', DMT_FormattingUtils.checkNull(riskLine.gf_min_rorc_fcg_per__c), 'Minimum percentage RORC without financing:', DMT_FormattingUtils.checkNull(riskLine.gf_min_rorc_wo_fcg_per__c));
                tableRows += DMT_FormattingUtils.tableRow2columns('Number of days revolvency period:', DMT_FormattingUtils.checkNull(riskLine.gf_revolvence_pd_days_number__c), 'Multioperation indicator:', DMT_FormattingUtils.checkNull(riskLine.g_multioperation_ind_type__c));
                tableRows += DMT_FormattingUtils.tableRow2columns('Comments', DMT_FormattingUtils.checkNull(riskLine.DMT_Comments__c), '', '');

                String tableCustomAssociationClientsProducts = '';
                if(data.mainHolderProductsWrapperMap.size()>0 && data.mainHolderProductsWrapperMap.containsKey(data.line.Line_Id__c + '_' + riskLine.gf_group_priority_line_id__c)){
                    tableCustomAssociationClientsProducts = '<div>'
                    + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                    + '<td colspan="9" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>SELECTED CLIENT</strong></td>'
                    + '</tr>'
                    + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>CLIENT NAME</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>INTERNAL RATING (SHORT)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>CURRENT RATING TOOL DATE</strong></td>'
                    + '</tr>';
                    for(DMT_ViewController.MainHolderProductsWrapper client : data.mainHolderProductsWrapperMap.get(data.line.Line_Id__c + '_' + riskLine.gf_group_priority_line_id__c)){
                        tableCustomAssociationClientsProducts += '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.clientName) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.internalRatingShort) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.currentRatingToolDate) + '</td>'
                        + '</tr>';
                    }
                    tableCustomAssociationClientsProducts += '</table></div>&nbsp;</br>';
                }
         
    
                htmlOutput += '<h3 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">' + DMT_FormattingUtils.checkNull(riskLine.Name) + '</h3>'
                    + '<div class="slds-scope">'
                    + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + tableRows
                    + '</table>'
                    + tableCustomAssociationClientsProducts
                    + '</div>'
                    + '</div>'
                    + '&nbsp;</br>'
                    + '&nbsp;</br>';
            }
            return htmlOutput;
        } catch (Exception e){
            System.debug('Error in DMT_OtherProductsRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty() || data.riskLineList.isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            List<Object> contentListProduct = new List<Object>();
            Map<String, Object> componentProduct = new Map<String, Object>();
            
            // Add the main title "OtherProducts" to match the HTML "PRODUCTS" title expectation
            contentListProduct.add(DMT_Create_Pdf_Controller.createTitle('PRODUCTS'));
            
            for (DMT_Risk_Line_Term__c riskLine : data.riskLineList) {
                List<String> nameProducts = new List<String>();
                List<String> valueProducts = new List<String>();
                DMT_Currency_Provision__c provision = data.riskLineToCurrencyProvisionMap.get(riskLine.Id);
                
                // Add page break before each product for proper formatting
                Map<String, Object> pageBreak = new Map<String, Object>{
                    'type' => 'pageBreak',
                    'threshold' => 20
                };
                contentListProduct.add(pageBreak);
                
                // Add product-specific title (e.g., "Import Financing")
                contentListProduct.add(DMT_Create_Pdf_Controller.createTitle(DMT_FormattingUtils.checkNull(riskLine.Name)));
                
                if (riskLine.DMT_Parent_Product_Name__c != null) {
                    nameProducts.add('Parent Product Name');
                    valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.DMT_Parent_Product_Name__c));
                    nameProducts.add('Parent Product Id');
                    valueProducts.add(DMT_FormattingUtils.checkNull(data.line.Line_Id__c) + '_' + 
                                    DMT_FormattingUtils.checkNull(riskLine.gf_group_priority_line_id__c));
                }
                nameProducts.add('Amount:');
                valueProducts.add(DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Amount__c, riskLine.CurrencyIsoCode));
                nameProducts.add('Currency:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.CurrencyIsoCode));
                nameProducts.add('Available Currencies for disposals:');
                valueProducts.add(provision != null && provision.g_currency_id__c != null ? 
                                provision.g_currency_id__c : 'All Currencies');
                nameProducts.add('Required mitigants:');
                valueProducts.add(DMT_FormattingUtils.getWarrantyNamesAsString(data.riskLineToWarrantyListMap.get(riskLine.Id)));
                nameProducts.add('Typology of financial program risks:');
                valueProducts.add(DMT_FormattingUtils.checkNull(data.line.g_limit_last_level_type__c));
                nameProducts.add('Global Product:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.DMT_Product__r?.Name));
                nameProducts.add('Global Product Subcategory:');
                valueProducts.add(DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id).get('subcategoryProduct')));
                nameProducts.add('Global Product Category:');
                valueProducts.add(DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id).get('categoryProduct')));
                nameProducts.add('Global Product Subfamily:');
                valueProducts.add(DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id).get('subfamilyProduct')));
                nameProducts.add('Global Product Family:');
                valueProducts.add(DMT_FormattingUtils.checkNull(data.productLevelsByRiskLine.get(riskLine.Id).get('familyProduct')));
                nameProducts.add('Bullet indicator Limitation:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.g_bullet_ind_type__c));
                nameProducts.add('Minimum Internal Rating Limitation:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.g_smscl_internal_ratg_type__c));
                nameProducts.add('Initial Term:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.DMT_Init_Term__c));
                nameProducts.add('Maximum Term:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.DMT_End_Term__c));
                nameProducts.add('Asset Allocation Sector Limitation:');
                valueProducts.add(DMT_FormattingUtils.checkNull(data.riskLineToTaxonomyC162Map.get(riskLine.Id)));
                nameProducts.add('Asset Allocation Subsector Limitation:');
                valueProducts.add(DMT_FormattingUtils.checkNull(data.riskLineToTaxonomyC164Map.get(riskLine.Id)));
                nameProducts.add('Booking Geography:');
                valueProducts.add(DMT_FormattingUtils.checkNull(data.riskLineToTaxonomyH007Map.get(riskLine.Id)));
                nameProducts.add('Number of months of grace period:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.gf_inscol_months_grace_number__c));
                nameProducts.add('Loan to value LTV (%):');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.gf_loan_value_per__c));
                nameProducts.add('Notary formalization indicator GMOD:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.g_notary_crtfn_ind_type__c));
                nameProducts.add('Indicator guarantees to public administrations GMOD:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.g_gtee_public_adm_ind_type__c));
                nameProducts.add('Percentage contribution export credit agency loan:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.gf_loan_eca_cntrb_per__c));
                nameProducts.add('Minimum percentage RAROEC with financing:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.gf_min_raroec_fcg_per__c));
                nameProducts.add('Minimum percentage RAROEC without financing:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.gf_min_raroec_wo_fcg_per__c));
                nameProducts.add('Minimum percentage RORC with financing:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.gf_min_rorc_fcg_per__c));
                nameProducts.add('Minimum percentage RORC without financing:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.gf_min_rorc_wo_fcg_per__c));
                nameProducts.add('Number of days revolvency period:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.gf_revolvence_pd_days_number__c));
                nameProducts.add('Multioperation indicator:');
                valueProducts.add(DMT_FormattingUtils.checkNull(riskLine.g_multioperation_ind_type__c));
                
                // Add product details as a list
                Map<String, Object> tableComponentProducts = DMT_Create_Pdf_Controller.createListText(nameProducts, valueProducts, '');
                contentListProduct.add(tableComponentProducts);
                
                // Add long text fields (e.g., Comments) in a single-column format
                List<String> nameLong = new List<String>{'Comments'};
                List<String> valueLong = new List<String>{DMT_FormattingUtils.checkNull(riskLine.DMT_Comments__c)};
                contentListProduct.add(DMT_Create_Pdf_Controller.createListText(nameLong, valueLong, 'ONE'));

                if(data.mainHolderProductsWrapperMap.size()>0 && data.mainHolderProductsWrapperMap.containsKey(data.line.Line_Id__c + '_' + riskLine.gf_group_priority_line_id__c)){
                    List<List<String>> headers = new List<List<String>>();
                    Map<String, Object> tableComponent = new Map<String, Object>();
                    List<List<String>> body = new List<List<String>>();
                        // Table Content Client
                        List<String> listHeaders = new List<String>{'CLIENT NAME', 'INTERNAL RATING (SHORT)', 'CURRENT RATING TOOL DATE'};
                        headers.add(listHeaders);
                    for (DMT_ViewController.MainHolderProductsWrapper client : data.mainHolderProductsWrapperMap.get(data.line.Line_Id__c + '_' + riskLine.gf_group_priority_line_id__c)) {
                            List<String> row = new List<String>();
                            row.add(DMT_FormattingUtils.checkNull(client.clientName)); 
                            row.add(DMT_FormattingUtils.checkNull(client.internalRatingShort));
                            row.add(DMT_FormattingUtils.checkNull(client.currentRatingToolDate));
                           
                            body.add(row);
                }
                    Map<String, Object> stylesTable = new Map<String, Object>();
                        stylesTable.put('fontSize', 8);
                    Map<String, Object> lineWidthItem = new Map<String, Object>();
                        lineWidthItem.put('bottom',0.1);
                        stylesTable.put('lineWidth',lineWidthItem);
                    Map<String, Object> headStyles= new Map<String, Object>();
                        headStyles.put('fontSize', 8);
                    Map<String, Object> tableMargin= new Map<String, Object>();
                        tableMargin.put('bottom', 5);
                        tableMargin.put('top', 0.1);

                        tableComponent.put('margin', tableMargin);
                        tableComponent.put('headStyles', headStyles);
                        tableComponent.put('style', stylesTable);
                        tableComponent.put('body', body);
                        tableComponent.put('head', headers);
                        tableComponent.put('type', 'table');
                    List<Object> titleSection = new List<Object>();
                    titleSection = DMT_Create_Pdf_Controller.createTitleSection('SELECTED CLIENT');
                    contentListProduct.add(titleSection[0]);
                    contentListProduct.add(titleSection[1]);
                    contentListProduct.add(tableComponent);
                }
            }
            
            componentProduct.put('content', contentListProduct);
            componentProduct.put('name', 'LINE(OTHER PRODUCTS)');
            return componentProduct;
        } catch (Exception e) {
            System.debug('Error in DMT_OtherProductsRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OtherProductsRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}