public without sharing class DMT_OppProfitabilityRenderer implements DMT_ViewRenderer {

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
        Map<String, Object> audit = profitability.containsKey('audit') && profitability.get('audit') != null ? (Map<String, Object>) profitability.get('audit') : new Map<String, Object>();

        Object rorcThreshold = audit.get('rorcThreshold');
        Object raroecThreshold = audit.get('raroecThreshold');
        if (results == null || results.isEmpty()) {
            return '<div class="error-message">no Profitability results found.</div>';
        }
        try {
            String currencyIsoCode = !String.isBlank(data.opportunity.DMT_CurrencyText__c) ? data.opportunity.DMT_CurrencyText__c : data.currencyIsoCode;

            List<Map<String, Object>> productDetailsList = data.profitabilityProductDetailsList;
            Map<String, Map<String, Object>> nominalAmountsMap = data.profitabilityNominalAmountsMap;
            Map<String, Map<String, Object>> nominalAmountsConvertedMap = data.profitabilityNominalAmountsConvertedMap;

            Map<String, Map<String, Object>> prodDetailsMap = new Map<String, Map<String, Object>>();

            String oppInitialDate = formatDateIso(data.opportunity.DMT_DATE_Initial_Date__c);
            String oppMaturityDate = formatDateIso(data.opportunity.DMT_DATE_Maturity_Date__c);

            String opportunityCurrency = currencyIsoCode;
            Decimal opportunityNominalDb = 0;
            Decimal opportunityNominalFb = 0;

            for (Map<String, Object> productDetail : productDetailsList) {
                String productKey = String.valueOf(productDetail.get('gf_group_priority_opportunity_id__c'));

                if (String.isBlank(productKey)) {
                    continue;
                }

                Map<String, Object> rawNominals = nominalAmountsMap.get(productKey);
                Map<String, Object> convertedNominals = nominalAmountsConvertedMap.get(productKey);

                Decimal rawNominalDb = 0;
                Decimal rawNominalFb = 0;

                if (rawNominals != null) {
                    Decimal rawDbValue = toDecimal(rawNominals.get('nominalDb'));
                    Decimal rawFbValue = toDecimal(rawNominals.get('nominalFb'));

                    rawNominalDb = rawDbValue != null ? rawDbValue : 0;
                    rawNominalFb = rawFbValue != null ? rawFbValue : 0;
                }

                if (convertedNominals != null) {
                    Decimal convertedDbValue = toDecimal(convertedNominals.get('nominalDb'));
                    Decimal convertedFbValue = toDecimal(convertedNominals.get('nominalFb'));

                    Decimal rawDbValue = toDecimal(rawNominals != null ? rawNominals.get('nominalDb') : null);
                    Decimal rawFbValue = toDecimal(rawNominals != null ? rawNominals.get('nominalFb') : null);

                    if (rawFbValue != null && rawFbValue > 0) {
                        opportunityNominalFb += convertedFbValue != null ? convertedFbValue : 0;
                    } else {
                        opportunityNominalDb += convertedDbValue != null ? convertedDbValue : 0;
                    }
                }

                Map<String, Object> details = new Map<String, Object>();
                details.put('Id', productKey);
                details.put('Name', productDetail.get('Name'));
                details.put('InitialDate', productDetail.get('InitialDate'));
                details.put('MaturityDate', productDetail.get('MaturityDate'));
                details.put('Currency', productDetail.get('Currency'));
                details.put('NominalDb', rawNominalDb);
                details.put('NominalFb', rawNominalFb);

                prodDetailsMap.put(productKey, details);

                if (productDetail.containsKey('Id') && productDetail.get('Id') != null) {
                    prodDetailsMap.put(String.valueOf(productDetail.get('Id')), details);
                }

                if (productDetail.containsKey('OppCurrency') && productDetail.get('OppCurrency') != null) {
                    opportunityCurrency = String.valueOf(productDetail.get('OppCurrency'));
                }
            }

            String html = '';
            html += '<div>' + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Profitability Engine</h2>' + '<div class="slds-scope">';
            Map<String, Object> summary;
            for (Object rec : results) {
                Map<String, Object> mapRec = (Map<String, Object>)rec;
                if (!mapRec.containsKey('productId') || mapRec.get('productId') == null) {
                    summary = mapRec;
                    break;
                }
            }
            if (summary == null) {
                summary = new Map<String, Object>();
            }

            List<Object> orderedResults = orderProfitabilityResults(results);

            String rorcDisplay = formatProfitabilityMetric(summary.get('rorc'), rorcThreshold);
            String raroecDisplay = formatProfitabilityMetric(summary.get('raroec'), raroecThreshold);

            html += '<div class="slds-m-vertical_medium">'
                + '<div class="slds-grid slds-wrap slds-m-top_small" style="font-size: 14px;">'

                + '<div class="slds-col slds-size_1-of-2 slds-p-bottom_small">'
                + '<strong>Deal RORC lifetime:</strong> ' + rorcDisplay
                + '</div>'

                + '<div class="slds-col slds-size_1-of-2 slds-p-bottom_small">'
                + '<strong>Deal RAROEC lifetime:</strong> ' + raroecDisplay
                + '</div>'

                + '<div class="slds-col slds-size_1-of-2 slds-p-bottom_small">'
                + '<strong>RORC Prospective CDD:</strong> '
                + DMT_FormattingUtils.formatPercent(summary.get('rorcProspected'))
                + '</div>'

                + '<div class="slds-col slds-size_1-of-2 slds-p-bottom_small">'
                + '<strong>Global Expected RORC:</strong> '
                + DMT_FormattingUtils.formatPercent(summary.get('clientRorc'))
                + '</div>'

                + '</div>'
    + '</div>';

            html += '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Summary</h3>'
            + '<div style="width:100%;">'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout:fixed; word-break:break-word;">'
                        + '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>ID</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Initial Date</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Maturity Date</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Average Life</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Tenor</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Allin Drawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Allin Undrawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Spread Drawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Spread Undrawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Fees Drawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Fees Undrawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>FC Drawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>FC Undrawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Country Risk Drawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Country Risk Undrawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Expected Loss</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Tax Rate</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>FD</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Net Income</strong></td>'
                        + '</tr>';
                        for(Object result : orderedResults){
                            Map<String, Object> row = (Map<String, Object>) result;
                            Boolean isSummary = isSummaryRow(row);
                            String rowStyle = getRowClassStyle(isSummary);

                            String oppId = getRowName(row, prodDetailsMap, data.opportunity);
                            String initialDate = getRowInitialDate(row, prodDetailsMap, oppInitialDate);
                            String maturityDate = getRowMaturityDate(row, prodDetailsMap, oppMaturityDate);
                            String rowCurrency = getRowCurrency(row, prodDetailsMap, currencyIsoCode);

                            html += '<tr style="' + rowStyle + '">'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.checkNull(oppId) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + DMT_FormattingUtils.checkNull(initialDate) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + DMT_FormattingUtils.checkNull(maturityDate) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatDecimalLikeModal(row.get('averageLife')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatDecimalLikeModal(row.get('tenor')) + '</td>'                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatBpsLikeModal(row.get('allInDb')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatBpsLikeModal(row.get('allInFb')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatBpsLikeModal(row.get('spreadDbPbs')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatBpsLikeModal(row.get('spreadFbPbs')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatBpsLikeModal(row.get('feesDbPbs')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatBpsLikeModal(row.get('feesFbPbs')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatBpsLikeModal(row.get('fundingDbPbs')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatBpsLikeModal(row.get('fundingFbPbs')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatBpsLikeModal(row.get('countryRiskProvisionDbPbs')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatBpsLikeModal(row.get('countryRiskProvisionFbPbs')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatBpsLikeModal(row.get('expectedLossPbs')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatPercentFromWhole(row.get('taxRate')) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatCurrencyAmountLikeModal(row.containsKey('franchiseDeal') ? row.get('franchiseDeal') : 0, rowCurrency) + '</td>'
                                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: 10px">' + formatCurrencyAmountLikeModal(row.get('bdi'), rowCurrency) + '</td>'
                            + '</tr>';
                        }
                html += '</table></div>'
                + '&nbsp;</br>'
                + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Regulatory Capital</h3>'
                + '<div style="width:100%;">'
                + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout:fixed; word-break:break-word;">'
                        + '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>ID</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Notional Drawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Notional Undrawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>EAD reg</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>CCF reg</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>LGD reg</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>RWA reg</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>Regulatory Capital</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>RORC CDD</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 10px"><strong>RORC</strong></td>'
                        + '</tr>';
                        for(Object result : orderedResults){
                            Map<String, Object> row = (Map<String, Object>) result;
                            Boolean isSummary = isSummaryRow(row);
                            String rowStyle = getRowClassStyle(isSummary);      

                            String oppId = getRowName(row, prodDetailsMap, data.opportunity);
                            String rowCurrency = isSummaryRow(row) ? opportunityCurrency : getRowCurrency(row, prodDetailsMap, currencyIsoCode);

                            Decimal rowNominalDb = getRowNominalDb(row, prodDetailsMap, opportunityNominalDb);
                            Decimal rowNominalFb = getRowNominalFb(row, prodDetailsMap, opportunityNominalFb);

                            html += '<tr style="' + rowStyle + '">'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.checkNull(oppId) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + formatCurrencyAmountLikeModal(rowNominalDb, rowCurrency) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + formatCurrencyAmountLikeModal(rowNominalFb, rowCurrency) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + formatCurrencyAmountLikeModal(row.get('regulatoryEad'), rowCurrency) 
                                    + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + formatPercentFromWhole(row.get('regulatoryCcf')) 
                                    + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + formatPercentFromWhole(row.get('regulatoryLgd')) 
                                    + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + formatPercentFromWhole(row.get('regulatoryApr')) 
                                    + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + formatDecimalLikeModal(row.get('regulatoryCapital')) 
                                    + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + DMT_FormattingUtils.formatPercent(row.get('rorcProspected')) 
                                    + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + DMT_FormattingUtils.formatPercent(row.get('rorc')) 
                                    + '</td>'
                                + '</tr>';
                        }
                html += '</table></div>'
                + '&nbsp;</br>'
                + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Economic Capital</h3>'
                + '<div style="width:100%;">'
                + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout:fixed; word-break:break-word;">'
                        + '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>ID</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>Notional Drawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>Notional Undrawn</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>EAD eco</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>CCF eco</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>LGD eco</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>RWA eco</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>Economic Capital</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>RAROEC CDD</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break: normal; font-size: 10px"><strong>RAROEC</strong></td>'
                        + '</tr>';
                        for(Object result : orderedResults){

                            Map<String, Object> row = (Map<String, Object>) result;
                            Boolean isSummary = isSummaryRow(row);
                            String rowStyle = getRowClassStyle(isSummary);

                            String oppId = getRowName(row, prodDetailsMap, data.opportunity);
                            String rowCurrency = isSummaryRow(row) ? opportunityCurrency : getRowCurrency(row, prodDetailsMap, currencyIsoCode);

                            Decimal rowNominalDb = getRowNominalDb(row, prodDetailsMap, opportunityNominalDb);
                            Decimal rowNominalFb = getRowNominalFb(row, prodDetailsMap, opportunityNominalFb);

                            html += '<tr style="' + rowStyle + '">'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + DMT_FormattingUtils.checkNull(oppId) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + formatCurrencyAmountLikeModal(rowNominalDb, rowCurrency) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' + formatCurrencyAmountLikeModal(rowNominalFb, rowCurrency) + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + formatCurrencyAmountLikeModal(row.get('economicEad'), rowCurrency)
                                    + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + formatPercentFromWhole(row.get('economicCcf')) 
                                    + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + formatPercentFromWhole(row.get('economicLgd')) 
                                    + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + formatPercentFromWhole(row.get('economicApr')) 
                                    + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + formatDecimalLikeModal(row.get('economicCapital')) 
                                    + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + DMT_FormattingUtils.formatPercent(row.get('raroecProspected')) 
                                    + '</td>'
                                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 10px">' 
                                    + DMT_FormattingUtils.formatPercent(row.get('raroec')) 
                                    + '</td>'
                                + '</tr>';
                        }
               html += '</table></div>'
                    + '&nbsp;</br>'
                    + '</div>'
                    + '</div>';

            Boolean hasProfitabilityVisual = false;
            if (data.isImg64 && !data.itemImgBase64.isEmpty() && data.itemImgBase64.size() > 7) {
                Integer j = data.itemImgBase64.size() <= 3 ? 0 : -1;
                if (j >= 0 && j < data.itemImgBase64.size()) {
                    String raw = normalizeImageBase64(data.itemImgBase64[j]?.imgB64);
                    String dataUri = toImageDataUri(raw);
                    if (String.isNotBlank(dataUri)) {
                        html += '<div style="margin-top: 24px;">'
                            + '<img alt="profitability" src="' + DMT_FormattingUtils.checkNull(dataUri) + '" style="width:100%;height:100%;object-fit:contain;"/>'
                            + '</div>';
                        hasProfitabilityVisual = true;
                    }
                }
            }

            if (!hasProfitabilityVisual) {
                DMT_ProfitabilityChartGenerator.ChartRequest profitabilityChartRequest =
                    DMT_ProfitabilityChartGenerator.buildChartRequest(profitability);
                String profitabilityChartHtml = DMT_ProfitabilityChartGenerator.getMixedChartHtml(profitabilityChartRequest);
                if (String.isNotBlank(profitabilityChartHtml)) {
                    html += '<div style="margin-top:24px; page-break-before:always; break-before:page; page-break-inside:avoid; break-inside:avoid;">' + profitabilityChartHtml + '</div>';
                }
            }
            
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OppProfitabilityLimitVisualRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    private static Decimal toDecimal(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return null;
        }
    }

    private static String normalizeImageBase64(String raw) {
        if (raw == null) {
            return null;
        }
        return raw.replaceAll('\\s+', '');
    }

    private static String toImageDataUri(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String cleaned = raw.trim();
        if (cleaned.toLowerCase().startsWith('data:')) {
            return cleaned;
        }
        String lower = cleaned.toLowerCase();
        String mime = 'image/jpeg';
        if (lower.startsWith('ivborw0kggo')) {
            mime = 'image/png';
        } else if (lower.startsWith('r0lgod')) {
            mime = 'image/gif';
        }
        return 'data:' + mime + ';base64,' + cleaned;
    }

    private static String formatPercentFromWhole(Object value) {
        Decimal decValue = toDecimal(value);
        if (decValue == null) {
            return '';
        }
        return DMT_FormattingUtils.formatPercent(decValue / 100);
    }

    private static String formatBpsLikeModal(Object value) {
        Decimal decValue = toDecimal(value);
        if (decValue == null) {
            return '';
        }
        return String.valueOf(decValue.setScale(0, RoundingMode.HALF_UP)) + ' bps';
    }

    private static String formatDecimalLikeModal(Object value) {
        return formatDecimalLikeModal(value, 2);
    }

    private static String formatDecimalLikeModal(Object value, Integer scale) {
        Decimal decValue = toDecimal(value);
        if (decValue == null) {
            return '';
        }

        String formattedValue = DMT_FormattingUtils.formatDecimalEs(decValue, scale);
        return removeGroupingSeparatorForSmallAmount(formattedValue, decValue);
    }

    private static String removeGroupingSeparatorForSmallAmount(String formattedValue, Decimal decValue) {
        if (String.isBlank(formattedValue) || decValue == null) {
            return formattedValue;
        }

        Decimal absValue = decValue < 0 ? decValue * -1 : decValue;

        if (absValue >= 1000 && absValue < 10000) {
            return formattedValue.replace('.', '');
        }

        return formattedValue;
    }

    private static String formatDateIso(Object value) {
        if (value == null) {
            return '';
        }

        if (value instanceof Date) {
            return String.valueOf((Date)value);
        }

        return String.valueOf(value);
    }

    private static List<Object> orderProfitabilityResults(List<Object> results) {
        List<Object> orderedResults = new List<Object>();
        Object summaryResult;

        for (Object rec : results) {
            Map<String, Object> mapRec = (Map<String, Object>) rec;
            if (!mapRec.containsKey('productId') || mapRec.get('productId') == null) {
                summaryResult = rec;
                break;
            }
        }

        if (summaryResult != null) {
            orderedResults.add(summaryResult);
        }

        for (Object rec : results) {
            Map<String, Object> mapRec = (Map<String, Object>) rec;
            if (mapRec.containsKey('productId') && mapRec.get('productId') != null) {
                orderedResults.add(rec);
            }
        }

        return orderedResults;
    }

    private static Boolean isSummaryRow(Map<String, Object> row) {
        return !row.containsKey('productId') || row.get('productId') == null;
    }

    private static String getRowName(
        Map<String, Object> row,
        Map<String, Map<String, Object>> prodDetailsMap,
        Opportunity opp
    ) {
        if (isSummaryRow(row)) {
            return DMT_FormattingUtils.checkNull(opp.Name);
        }

        String prodIdStr = String.valueOf(row.get('productId'));

        if (prodDetailsMap.containsKey(prodIdStr)) {
            Map<String, Object> details = prodDetailsMap.get(prodIdStr);
            if (details.containsKey('Name') && details.get('Name') != null) {
                return DMT_FormattingUtils.checkNull(details.get('Name'));
            }
        }

        return DMT_FormattingUtils.checkNull(prodIdStr);
    }

    private static String getRowCurrency(
        Map<String, Object> row,
        Map<String, Map<String, Object>> prodDetailsMap,
        String defaultCurrency
    ) {
        if (isSummaryRow(row)) {
            return defaultCurrency;
        }

        String prodIdStr = String.valueOf(row.get('productId'));

        if (prodDetailsMap.containsKey(prodIdStr)) {
            Map<String, Object> details = prodDetailsMap.get(prodIdStr);
            if (details.containsKey('Currency') && details.get('Currency') != null) {
                return String.valueOf(details.get('Currency'));
            }
        }

        return defaultCurrency;
    }

    private static String getRowInitialDate(
        Map<String, Object> row,
        Map<String, Map<String, Object>> prodDetailsMap,
        String oppInitialDate
    ) {
        if (isSummaryRow(row)) {
            return oppInitialDate;
        }

        String prodIdStr = String.valueOf(row.get('productId'));

        if (prodDetailsMap.containsKey(prodIdStr)) {
            return formatDateIso(prodDetailsMap.get(prodIdStr).get('InitialDate'));
        }

        return oppInitialDate;
    }

    private static String getRowMaturityDate(
        Map<String, Object> row,
        Map<String, Map<String, Object>> prodDetailsMap,
        String oppMaturityDate
    ) {
        if (isSummaryRow(row)) {
            return oppMaturityDate;
        }

        String prodIdStr = String.valueOf(row.get('productId'));

        if (prodDetailsMap.containsKey(prodIdStr)) {
            return formatDateIso(prodDetailsMap.get(prodIdStr).get('MaturityDate'));
        }

        return oppMaturityDate;
    }

   private static Decimal getRowNominalDb(
        Map<String, Object> row,
        Map<String, Map<String, Object>> prodDetailsMap,
        Decimal totalNominalDb
    ) {
        if (isSummaryRow(row)) {
            return totalNominalDb;
        }

        String prodIdStr = String.valueOf(row.get('productId'));

        if (prodDetailsMap.containsKey(prodIdStr)) {
            return toDecimal(prodDetailsMap.get(prodIdStr).get('NominalDb')) != null
                ? toDecimal(prodDetailsMap.get(prodIdStr).get('NominalDb'))
                : 0;
        }

        return 0;
    }

    private static Decimal getRowNominalFb(
        Map<String, Object> row,
        Map<String, Map<String, Object>> prodDetailsMap,
        Decimal totalNominalFb
    ) {
        if (isSummaryRow(row)) {
            return totalNominalFb;
        }

        String prodIdStr = String.valueOf(row.get('productId'));

        if (prodDetailsMap.containsKey(prodIdStr)) {
            return toDecimal(prodDetailsMap.get(prodIdStr).get('NominalFb')) != null
                ? toDecimal(prodDetailsMap.get(prodIdStr).get('NominalFb'))
                : 0;
        }

        return 0;
    }

    private static String getRowClassStyle(Boolean isSummary) {
        return isSummary ? 'background-color:#e6f0fa;' : '';
    }

    private static Object getFirstExistingValue(Map<String, Object> row, List<String> keys) {
        for (String key : keys) {
            if (row.containsKey(key) && row.get(key) != null) {
                return row.get(key);
            }
        }
        return null;
    }

    private static String formatCurrencyAmountLikeModal(Object value, String currencyIsoCode) {
        Decimal decValue = toDecimal(value);

        if (decValue == null) {
            return '';
        }

        Decimal roundedValue = decValue.setScale(2, RoundingMode.HALF_UP);

        String formattedValue = DMT_FormattingUtils.formatCurrencyAmount(
            roundedValue,
            currencyIsoCode
        );

        return removeGroupingSeparatorForSmallAmount(formattedValue, roundedValue);
    }

    private static String formatProfitabilityMetric(Object value, Object thresholdValue) {
        Decimal thresholdDecimal = toDecimal(thresholdValue);
        String formattedValue = DMT_FormattingUtils.formatPercent(value);
        if (thresholdDecimal == null) {
            return formattedValue;
        }

        Decimal valueDecimal = toDecimal(value);
        String comparisonSign = valueDecimal == null ? '&lt;'
            : valueDecimal > thresholdDecimal ? '&gt;'
            : valueDecimal < thresholdDecimal ? '&lt;'
            : '=';
        return formattedValue + ' ' + comparisonSign + ' ' + DMT_FormattingUtils.formatPercent(thresholdDecimal);
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