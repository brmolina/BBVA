public with sharing class DMT_OppProfitabilityLimitVisualRenderer implements DMT_ViewRenderer {
    /**
     * Renders HTML for the Opportunity Profitability feature.
     * @param data The LineDataWrapper containing featuresList.
     * @return HTML string for rendering in the UI.
     */
    public static String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList == null || data.featuresList.isEmpty()) {
            return '<div>Features data not provided.</div>';
        }
        if (data.opportunity.getPopulatedFieldsAsMap().isEmpty() || data.opportunity.OpportunityLineItems.isEmpty()) {
            return '<div>Opportunity or OpportunityLineItems data not provided.</div>';
        }
        Map<String, Object> feature = getProfitabilityFeature(data.featuresList);
        if (feature.isEmpty() || !feature.containsKey('profitability')) {
            return '<div>Profitability data not provided.</div>';
        }
        Map<String, Object> profitability = (Map<String, Object>)feature.get('profitability');
        List<Object> results = (List<Object>)profitability.get('results');
        if (results == null || results.isEmpty()) {
            return '<div class="error-message">no Profitability results found.</div>';
        }
        try {
            String currencyIsoCode = data.currencyIsoCode;
            // Build map from local data.opportunity.OpportunityLineItems
            Map<String, Map<String, Object>> prodDetailsMap = new Map<String, Map<String, Object>>();

            String oppInitialDate = DMT_FormattingUtils.changeDateFormat(data.opportunity.DMT_DATE_Initial_Date__c);
            String oppMaturityDate = DMT_FormattingUtils.changeDateFormat(data.opportunity.DMT_DATE_Maturity_Date__c);

            Decimal totalNominalDb = 0;
            Decimal totalNominalFb = 0;

            for (OpportunityLineItem oppItem : data.opportunity.OpportunityLineItems) {
                System.debug('oppItem, '+ JSON.serialize(oppitem));
                for(DMT_Opportunity_Tenor__c tenor : oppItem.Opportunity_Tenors__r){
                    totalNominalDb += (tenor.gj_nominal_amount_db__c != null ? tenor.gj_nominal_amount_db__c : 0);
                    totalNominalFb += (tenor.gf_nominal_amount_fb__c != null ? tenor.gf_nominal_amount_fb__c : 0);
                }

                Map<String, Object> details = new Map<String, Object>();
                details.put('Id', oppItem.Id);
                System.debug('oppItem.DES_Product_Name__c, '+ oppItem.DES_Product_Name__c);
                details.put('Name', oppItem.DES_Product_Name__c);
                details.put('InitialDate', oppItem.gf_initial_date__c);
                details.put('MaturityDate', oppItem.gf_maturity_date__c);
             //   details.put('SpreadDb', oppItem.gf_spread_db__c);
              //  details.put('SpreadFb', oppItem.gf_spread_fb__c);
              //  details.put('FundingCostDb', oppItem.gf_funding_cost_db__c);
             //   details.put('FundingCostFb', oppItem.gf_funding_cost_fb__c);
                prodDetailsMap.put(oppItem.Id, details);
            }
    
            String html = '';
            // Image rendering 
            if (data.isImg64 && !data.itemImgBase64.isEmpty() && data.itemImgBase64.size() > 0) {
                Integer j = data.itemImgBase64.size() <= 3 ? 0 : -1;
                if (j >= 0 && j < data.itemImgBase64.size()) {
                    html += '<div><img src="' + String.valueOf(data.itemImgBase64[j]?.imgB64) + '" style="width:100%;height:100%;object-fit:contain;"/></div>';
                }
            }
            Map<String, Object> summary;
            for (Object rec : results) {
                Map<String, Object> mapRec = (Map<String, Object>)rec;
                if (!mapRec.containsKey('productId') || mapRec.get('productId') == null) {
                    summary = mapRec;
                    break;
                }
            }
            
            html += '<div class="slds-m-vertical_medium">';
            html += '<div class="slds-grid slds-wrap slds-m-top_x-small">';
            html += '<div class="slds-col slds-size_1-of-2"><strong class="slds-text-heading_small">RORC:</strong> <span class="slds-text-heading_small">' + DMT_FormattingUtils.formatPercent(summary.get('rorc')) + '</span></div>';
            html += '<div class="slds-col slds-size_1-of-2"><strong class="slds-text-heading_small">RAROEC:</strong> <span class="slds-text-heading_small">' + DMT_FormattingUtils.formatPercent(summary.get('raroec')) + '</span></div>';
            html += '</div>';
            html += '<div class="slds-grid slds-wrap slds-m-top_small">';
            html += '<div class="slds-col slds-size_1-of-2"><strong>RORC no xSell:</strong> ' + DMT_FormattingUtils.formatPercent(summary.get('rorcNoxsell')) + '</div>';
            html += '<div class="slds-col slds-size_1-of-2"><strong>RAROEC no xSell:</strong> ' + DMT_FormattingUtils.formatPercent(summary.get('raroecNoxsell')) + '</div>';
            html += '<div class="slds-col slds-size_1-of-2"><strong>RORC Prospective CDD:</strong> ' + DMT_FormattingUtils.formatPercent(summary.get('rorcProspected')) + '</div>';
            html += '<div class="slds-col slds-size_1-of-2"><strong>RAROEC Prospective CDD:</strong> ' + DMT_FormattingUtils.formatPercent(summary.get('raroecProspected')) + '</div>';
            html += '</div>';
            
            html += '</div>';
            html += '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Summary</h3>'
                + '<table class="style-table" style="width:100%; max-width:100%; border-collapse: collapse; table-layout: fixed;">'
                        + '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>ID</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Initial Date</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Maturity Date</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Tax Rate</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Spread Drawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Spread Undrawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>FC Drawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>FC Undrawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Country Risk Drawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Country Risk Undrawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Expected Loss</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Fees Non Accrua</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Fees Accrual</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>PAT</strong></td>'
                        + '</tr>';
                        for(Object result : results){
                            Map<String, Object> row = (Map<String, Object>)result;
                            String prodIdStr = String.valueOf(row.get('productId'));
                            Map<String, Object> prodDetailsVals = new Map<String, Object>();
                            prodDetailsVals = prodDetailsMap.containsKey(prodIdStr) ? prodDetailsMap.get(prodIdStr) : new Map<String, Object>();
                            String oppId = String.valueOf((prodDetailsVals.containsKey('Name') ? prodDetailsVals.get('Name') : prodDetailsVals.containsKey('Id') ? prodDetailsVals.get('Id') : String.isNotBlank(prodIdStr) ? prodIdStr : 'Opp'));
                            String initialDate = String.isBlank(String.valueOf(prodDetailsVals.get('InitialDate'))) ? oppInitialDate : DMT_FormattingUtils.changeDateFormat(prodDetailsVals.get('InitialDate'));
                            String maturityDate = String.isBlank(String.valueOf(prodDetailsVals.get('MaturityDate'))) ? oppMaturityDate : DMT_FormattingUtils.changeDateFormat(prodDetailsVals.get('MaturityDate'));
                            html   += '<tr>'
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.checkNull(oppId) + '</td>'                              
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.checkNull(initialDate) + '</td>'                              
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.checkNull(maturityDate) + '</td>'                              
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">'+ DMT_FormattingUtils.formatPercent(row.get('taxRate'))+'</td>'
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">'+ DMT_FormattingUtils.formatBps(row.get('spreadDbPbs'))+'</td>'
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">'+ DMT_FormattingUtils.formatBps(row.get('spreadFbPbs'))+'</td>'
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">'+ DMT_FormattingUtils.formatBps(row.get('fundingDbPbs'))+'</td>'
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">'+ DMT_FormattingUtils.formatBps(row.get('fundingFbPbs'))+'</td>'
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">'+ DMT_FormattingUtils.formatBps(row.get('countryRiskProvisionDbPbs'))+'</td>'
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">'+ DMT_FormattingUtils.formatBps(row.get('countryRiskProvisionFbPbs'))+'</td>'
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">'+ DMT_FormattingUtils.formatBps(row.get('expectedLossPbs'))+'</td>'
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">'+ DMT_FormattingUtils.formatBps(row.get('feesUpFrontPbs'))+'</td>'
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">'+ DMT_FormattingUtils.formatBps(row.get('periodicFeesPbs'))+'</td>'
                                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">'+ DMT_FormattingUtils.formatDecimalEs(row.get('bdi'), 3)+'</td>'
                                    + '</tr>';
                        }
                html += '</table>'
                + '&nbsp;</br>'
                + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Regulatory Capital</h3>'
                + '<table class="style-table" style="width:100%; max-width:100%; border-collapse: collapse; table-layout: fixed;">'
                        + '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>ID</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Notional Drawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Notional Undrawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>CCF reg</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>EAD reg</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>LGD reg</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>RWA reg</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Regulatory Capital</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>RORC</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>NIAT CDD</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>CR CDD</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>RORC CDD</strong></td>'
                        + '</tr>';
                        for(Object result : results){
                            Map<String, Object> row = (Map<String, Object>)result;
                            String prodIdStr = String.valueOf(row.get('productId'));
                            Map<String, Object> prodDetailsVals = new Map<String, Object>(); 
                            prodDetailsVals = prodDetailsMap.containsKey(prodIdStr) ? prodDetailsMap.get(prodIdStr) : new Map<String, Object>();
                            String oppId = String.valueOf((prodDetailsVals.containsKey('Name') ? prodDetailsVals.get('Name') : prodDetailsVals.containsKey('Id') ? prodDetailsVals.get('Id') : String.isNotBlank(prodIdStr) ? prodIdStr : 'Opp'));

                            html += '<tr>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.checkNull(oppId) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatCurrencyAmount(totalNominalDb, currencyIsoCode)+'</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatCurrencyAmount(totalNominalFb, currencyIsoCode) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(row.get('regulatoryCcf'))) / 100)+ '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatDecimalEs(row.get('regulatoryEad'), 3) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(row.get('regulatoryLgd'))) / 100) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(row.get('regulatoryApr'))) / 100) + '</td>'                                    
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatDecimalEs(row.get('regulatoryCapital'), 3) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatPercent(row.get('rorc')) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatDecimalEs(row.get('prospectedBdi'), 3) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatDecimalEs(row.get('prospectedRegulatoryCapital'), 3) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatPercent(row.get('rorcProspected')) + '</td>'
                                + '</tr>';
                        }
                html += '</table>'
                + '&nbsp;</br>'
                + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Economic Capital</h3>'
                + '<table class="style-table" style="width:100%; max-width:100%; border-collapse: collapse; table-layout: fixed;">'
                        + '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>ID</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>Notional Drawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>Notional Undrawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>CCF eco</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>EAD eco</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>LGD eco</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>RWA eco</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>Economic Capital</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>RAROEC</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>NIAT CDD</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>CE CDD</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>RAROED CDD</strong></td>'
                        + '</tr>';
                        for(Object result : results){
                            System.debug('profitability resul, '+ JSON.serialize(result));
                            Map<String, Object> row = (Map<String, Object>)result;
                            String prodIdStr = String.valueOf(row.get('productId'));
                            Map<String, Object> prodDetailsVals = new Map<String, Object>(); 
                            prodDetailsVals = prodDetailsMap.containsKey(prodIdStr) ? prodDetailsMap.get(prodIdStr) : new Map<String, Object>();
                            String oppId = String.valueOf((prodDetailsVals.containsKey('Name') ? prodDetailsVals.get('Name') : prodDetailsVals.containsKey('Id') ? prodDetailsVals.get('Id') : String.isNotBlank(prodIdStr) ? prodIdStr: 'Opp'));
                            html += '<tr>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.checkNull(oppId) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatCurrencyAmount(totalNominalDb, currencyIsoCode)+'</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatCurrencyAmount(totalNominalFb, currencyIsoCode) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(row.get('economicCcf'))) / 100)+ '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatDecimalEs(row.get('economicEad'), 3)+'</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(row.get('economicLgd'))) / 100) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(row.get('economicApr'))) / 100) + '</td>'                                    
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatDecimalEs(row.get('economicCapital'), 3) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatPercent(row.get('raroec')) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatDecimalEs(row.get('prospectedBdi'), 3) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatDecimalEs(row.get('prospectedEconomicCapital'), 3) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.formatPercent(row.get('raroecProspected')) + '</td>'
                                + '</tr>';
                        }
                html += '</table>'
                + '&nbsp;</br>'
            + '</div>';
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OppProfitabilityLimitVisualRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    /**
     * Generates PDF JSON for the Opportunity Profitability feature.
     * @param data The LineDataWrapper containing featuresList.
     * @return PDF JSON string.
     */
    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        
        Map<String, Object> componentLimitDetailVisual = new Map<String, Object>();

        if (data == null || data.featuresList == null || data.featuresList.isEmpty()) {
            return componentLimitDetailVisual;
        }
        if (data.opportunity.getPopulatedFieldsAsMap().isEmpty() || data.opportunity.OpportunityLineItems.isEmpty()) {
            return componentLimitDetailVisual;
        }
        
        Map<String, Object> feature = getProfitabilityFeature(data.featuresList);
        if (feature.isEmpty() || !feature.containsKey('profitability')) {
            return componentLimitDetailVisual;
        }
        Map<String, Object> profitability = (Map<String, Object>)feature.get('profitability');
        List<Object> results = (List<Object>)profitability.get('results');
        if (results == null || results.isEmpty()) {
            return componentLimitDetailVisual;
        }
        
        try {
            String currencyIsoCode = data.currencyIsoCode;
            // Build map from local data.opportunity.OpportunityLineItems
            Map<String, Map<String, Object>> prodDetailsMap = new Map<String, Map<String, Object>>();

            String oppInitialDate = DMT_FormattingUtils.changeDateFormat(data.opportunity.DMT_DATE_Initial_Date__c);
            String oppMaturityDate = DMT_FormattingUtils.changeDateFormat(data.opportunity.DMT_DATE_Maturity_Date__c);

            Decimal totalNominalDb = 0;
            Decimal totalNominalFb = 0;

            for (OpportunityLineItem oppItem : data.opportunity.OpportunityLineItems) {
                for(DMT_Opportunity_Tenor__c tenor : oppItem.Opportunity_Tenors__r){
                    totalNominalDb += (tenor.gj_nominal_amount_db__c != null ? tenor.gj_nominal_amount_db__c : 0);
                    totalNominalFb += (tenor.gf_nominal_amount_fb__c != null ? tenor.gf_nominal_amount_fb__c : 0);
                }

                Map<String, Object> details = new Map<String, Object>();
                details.put('Id', oppItem.Id);
                details.put('Name', oppItem.DES_Product_Name__c);
                details.put('InitialDate', oppItem.gf_initial_date__c);
                details.put('MaturityDate', oppItem.gf_maturity_date__c);
             //   details.put('SpreadDb', oppItem.gf_spread_db__c);
              //  details.put('SpreadFb', oppItem.gf_spread_fb__c);
              //  details.put('FundingCostDb', oppItem.gf_funding_cost_db__c);
             //   details.put('FundingCostFb', oppItem.gf_funding_cost_fb__c);
                prodDetailsMap.put(oppItem.Id, details);
            }
            Map<String, Object> summary;
            for (Object rec : results) {
                Map<String, Object> mapRec = (Map<String, Object>)rec;
                if (!mapRec.containsKey('productId') || mapRec.get('productId') == null) {
                    summary = mapRec;
                    break;
                }
            }
            List<Object> contentListLimitDetailVisual = new List<Object>();

            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 30
            };
            contentListLimitDetailVisual.add(pageBreak);

            // --- 1. IMAGE ---
        if (data.isImg64 && !data.itemImgBase64.isEmpty()) {
            Map<String, Object> img = new Map<String, Object>{
                'type' => 'image',
                'src'  => data.itemImgBase64[0]?.imgB64,
                'width' => 170,
                'aspectRatio' => 0.40,
                'format' => 'JPEG',
                'margin' => new Map<String, Object>{
                    'top' => 5, 'bottom' => 5, 'left' => 5, 'right' => 5
                }
            };
            contentListLimitDetailVisual.add(img);
        }

        // --- 2. SUMMARIES in 2 COLUMNS ---
        Map<String, Object> textComponent = new Map<String, Object>();
                List<String> name = new List<String>();
                List<String> value = new List<String>();
                name.add('RORC:');
                value.add(DMT_FormattingUtils.formatPercent(summary.get('rorc')));
                name.add('RORC no xSell:');
                value.add(DMT_FormattingUtils.formatPercent(summary.get('rorcNoxsell')));
                name.add('RORC Prospective CDD:');
                value.add(DMT_FormattingUtils.formatPercent(summary.get('rorcProspected')));
                name.add('RAROEC:');
                value.add(DMT_FormattingUtils.formatPercent(summary.get('raroec')));
                name.add('RAROEC no xSell:');
                value.add(DMT_FormattingUtils.formatPercent(summary.get('raroecNoxsell')));
                name.add('RAROEC Prospective CDD:');
                value.add(DMT_FormattingUtils.formatPercent(summary.get('raroecProspected')));
                //Table than create the text content
                textComponent = DMT_Create_Pdf_Controller.createListText(name, value, '');
                contentListLimitDetailVisual.add(textComponent);
            
            // SUMMARY TABLE
            List<List<String>> headersSummary = new List<List<String>>();
            List<String> summaryHeader = new List<String>();
            List<List<String>> summaryBody = new List<List<String>>();
            summaryHeader.add('ID');
            summaryHeader.add('Initial Date');
            summaryHeader.add('Maturity Date');
            summaryHeader.add('Tax Rate');
            summaryHeader.add('Spread Drawn');
            summaryHeader.add('Spread Undrawn');
            summaryHeader.add('FC Drawn');
            summaryHeader.add('FC Undrawn');
            summaryHeader.add('Country Risk Drawn');
            summaryHeader.add('Country Risk Undrawn');
            summaryHeader.add('Expected Loss');
            summaryHeader.add('Fees Non Accrua');
            summaryHeader.add('Fees Accrual');
            summaryHeader.add('PAT');
            headersSummary.add(summaryHeader);
            // Add summary rows to summaryBody
            for(Object result : results){
                Map<String, Object> row = (Map<String, Object>)result;
                String prodIdStr = String.valueOf(row.get('productId'));
                Map<String, Object> prodDetailsVals = prodDetailsMap.containsKey(prodIdStr) ? prodDetailsMap.get(prodIdStr) : new Map<String, Object>();
                String oppId = String.valueOf((prodDetailsVals.containsKey('Name') ? prodDetailsVals.get('Name') : prodDetailsVals.containsKey('Id') ? prodDetailsVals.get('Id') : 'Opp'));
                String initialDate = String.isBlank(String.valueOf(prodDetailsVals.get('InitialDate'))) ? oppInitialDate : DMT_FormattingUtils.changeDateFormat(prodDetailsVals.get('InitialDate'));
                String maturityDate = String.isBlank(String.valueOf(prodDetailsVals.get('MaturityDate'))) ? oppMaturityDate : DMT_FormattingUtils.changeDateFormat(prodDetailsVals.get('MaturityDate'));
                List<String> rowSummary = new List<String>();
                rowSummary.add(DMT_FormattingUtils.checkNull(oppId));
                rowSummary.add(DMT_FormattingUtils.checkNull(initialDate));
                rowSummary.add(DMT_FormattingUtils.checkNull(maturityDate));
                rowSummary.add(DMT_FormattingUtils.formatPercent(row.get('taxRate')));
                rowSummary.add(DMT_FormattingUtils.formatBps(row.get('spreadDbPbs')));
                rowSummary.add(DMT_FormattingUtils.formatBps(row.get('spreadFbPbs')));
                rowSummary.add(DMT_FormattingUtils.formatBps(row.get('fundingDbPbs')));
                rowSummary.add(DMT_FormattingUtils.formatBps(row.get('fundingFbPbs')));
                rowSummary.add(DMT_FormattingUtils.formatBps(row.get('countryRiskProvisionDbPbs')));
                rowSummary.add(DMT_FormattingUtils.formatBps(row.get('countryRiskProvisionFbPbs')));
                rowSummary.add(DMT_FormattingUtils.formatBps(row.get('expectedLossPbs')));
                rowSummary.add(DMT_FormattingUtils.formatBps(row.get('feesUpFrontPbs')));
                rowSummary.add(DMT_FormattingUtils.formatBps(row.get('periodicFeesPbs')));
                rowSummary.add(DMT_FormattingUtils.formatDecimalEs(row.get('bdi'), 3));
                summaryBody.add(rowSummary);
            }

        Map<String, Object> summaryTitle = DMT_Create_Pdf_Controller.createTitle('Summary');
        summaryTitle.put('type', 'text');
        Map<String, Object> style = (Map<String, Object>) summaryTitle.get('style');
        style.put('fontSize', 14);
        style.put('textColor', '#004481');
        contentListLimitDetailVisual.add(summaryTitle);
        Map<String, Object> summaryTable = DMT_Create_Pdf_Controller.createTable(headersSummary, summaryBody);
        contentListLimitDetailVisual.add(summaryTable);

        // REGULATORY CAPITAL TABLE
        List<List<String>> headersReg = new List<List<String>>();
        List<String> regHeader = new List<String>{
            'ID',
            'Notional Drawn',
            'Notional Undrawn',
            'CCF reg',
            'EAD reg',
            'LGD reg',
            'RWA reg',
            'Regulatory Capital',
            'RORC',
            'NIAT CDD',
            'CR CDD',
            'RORC CDD'
        };
        headersReg.add(regHeader);

        List<List<String>> regBody = new List<List<String>>();
        for (Object resultObj : results) {
            Map<String, Object> row = (Map<String, Object>) resultObj;
            String prodIdStr = String.valueOf(row.get('productId'));
            Map<String, Object> prodDetailsVals = prodDetailsMap.containsKey(prodIdStr) ? prodDetailsMap.get(prodIdStr) : new Map<String, Object>();
            String oppId = String.valueOf((prodDetailsVals.containsKey('Name') ? prodDetailsVals.get('Name') : prodDetailsVals.containsKey('Id') ? prodDetailsVals.get('Id') : 'Opp'));

            List<String> regRow = new List<String>();
            regRow.add(DMT_FormattingUtils.checkNull(oppId));
            regRow.add(DMT_FormattingUtils.formatCurrencyAmount(totalNominalDb, currencyIsoCode));
            regRow.add(DMT_FormattingUtils.formatCurrencyAmount(totalNominalFb, currencyIsoCode));
            regRow.add(DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(row.get('regulatoryCcf'))) / 100));
            regRow.add(DMT_FormattingUtils.formatDecimalEs(row.get('regulatoryEad'), 3));
            regRow.add(DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(row.get('regulatoryLgd'))) / 100));
            regRow.add(DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(row.get('regulatoryApr'))) / 100));
            regRow.add(DMT_FormattingUtils.formatDecimalEs(row.get('regulatoryCapital'), 3));
            regRow.add(DMT_FormattingUtils.formatPercent(row.get('rorc')));
            regRow.add(DMT_FormattingUtils.formatDecimalEs(row.get('prospectedBdi'), 3));
            regRow.add(DMT_FormattingUtils.formatDecimalEs(row.get('prospectedRegulatoryCapital'), 3));
            regRow.add(DMT_FormattingUtils.formatPercent(row.get('rorcProspected')));

            regBody.add(regRow);
        }

        contentListLimitDetailVisual.add(pageBreak);

        Map<String, Object> regTitle = DMT_Create_Pdf_Controller.createTitle('Regulatory Capital');
        regTitle.put('type', 'text');
        Map<String, Object> regStyle = (Map<String, Object>) regTitle.get('style');
        regStyle.put('fontSize', 14);
        regStyle.put('textColor', '#004481');
        contentListLimitDetailVisual.add(regTitle);

        Map<String, Object> regTable = DMT_Create_Pdf_Controller.createTable(headersReg, regBody);
        contentListLimitDetailVisual.add(regTable);

        // ECONOMIC CAPITAL TABLE
        List<List<String>> headersEco = new List<List<String>>();
        List<String> ecoHeader = new List<String>{
            'ID',
            'Notional Drawn',
            'Notional Undrawn',
            'CCF eco',
            'EAD eco',
            'LGD eco',
            'RWA eco',
            'Economic Capital',
            'RAROEC',
            'NIAT CDD',
            'CE CDD',
            'RAROEC CDD'
        };
        headersEco.add(ecoHeader);

        List<List<String>> ecoBody = new List<List<String>>();
        for (Object resultObj : results) {
            Map<String, Object> row = (Map<String, Object>) resultObj;
            String prodIdStr = String.valueOf(row.get('productId'));
            Map<String, Object> prodDetailsVals = prodDetailsMap.containsKey(prodIdStr) ? prodDetailsMap.get(prodIdStr) : new Map<String, Object>();
            String oppId = String.valueOf((prodDetailsVals.containsKey('Name') ? prodDetailsVals.get('Name') : prodDetailsVals.containsKey('Id') ? prodDetailsVals.get('Id') : 'Opp'));

            List<String> ecoRow = new List<String>();
            ecoRow.add(DMT_FormattingUtils.checkNull(oppId));
            ecoRow.add(DMT_FormattingUtils.formatCurrencyAmount(totalNominalDb, currencyIsoCode));
            ecoRow.add(DMT_FormattingUtils.formatCurrencyAmount(totalNominalFb, currencyIsoCode));
            ecoRow.add(DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(row.get('economicCcf'))) / 100));
            ecoRow.add(DMT_FormattingUtils.formatDecimalEs(row.get('economicEad'), 3));
            ecoRow.add(DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(row.get('economicLgd'))) / 100));
            ecoRow.add(DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(row.get('economicApr'))) / 100));
            ecoRow.add(DMT_FormattingUtils.formatDecimalEs(row.get('economicCapital'), 3));
            ecoRow.add(DMT_FormattingUtils.formatPercent(row.get('raroec')));
            ecoRow.add(DMT_FormattingUtils.formatDecimalEs(row.get('prospectedBdi'), 3));
            ecoRow.add(DMT_FormattingUtils.formatDecimalEs(row.get('prospectedEconomicCapital'), 3));
            ecoRow.add(DMT_FormattingUtils.formatPercent(row.get('raroecProspected')));

            ecoBody.add(ecoRow);
        }

        contentListLimitDetailVisual.add(pageBreak);

        Map<String, Object> ecoTitle = DMT_Create_Pdf_Controller.createTitle('Economic Capital');
        ecoTitle.put('type', 'text');
        Map<String, Object> ecoStyle = (Map<String, Object>) ecoTitle.get('style');
        ecoStyle.put('fontSize', 14);
        ecoStyle.put('textColor', '#004481');
        contentListLimitDetailVisual.add(ecoTitle);

        Map<String, Object> ecoTable = DMT_Create_Pdf_Controller.createTable(headersEco, ecoBody);
        contentListLimitDetailVisual.add(ecoTable);
        componentLimitDetailVisual.put('content', contentListLimitDetailVisual);
            return componentLimitDetailVisual;

        } catch (Exception e) {
            System.debug('Error in DMT_OppProfitabilityLimitVisualRenderer renderPdfJson: ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OppProfitabilityLimitVisualRenderer','renderPdfJson','DMT',''));
            return componentLimitDetailVisual;
        }
    }

    // Helper to extract the profitability feature from featuresList
    private static Map<String, Object> getProfitabilityFeature(List<Object> featuresList) {
        for (Object obj : featuresList) {
            Map<String, Object> feature = (Map<String, Object>)obj;
            if (feature != null && feature.containsKey('profitability')) {
                return feature;
            }
        }
        return new Map<String, Object>();
    }
}