// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
public without sharing class DMT_DefaultLimitVisualRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList.isEmpty()) {
            return '<div>Limit Visual data not provided</div>';
        }
        System.debug('DMT_DefaultLimitVisualRenderer renderHtml data.featuresList, '+ JSON.serialize(data.featuresList));
        try {
            String table = '';
            Integer imageIndex = 0;
            Integer chartIndex = 0;
            List<DMT_ChartHtmlGenerator.ChartRequest> chartRequests = DMT_ChartHtmlGenerator.buildChartRequests(data);
            // Patch: if Opportunity, build productId-to-real-name mapping
            Boolean isOpportunity = data.opportunity != null && data.opportunity.Id != null;
            Map<String, String> productIdToName = isOpportunity ? buildProductIdToName(data) : new Map<String, String>();

            for (Integer i = 0; i < data.featuresList.size(); i++) {
                Map<String, Object> feature = data.featuresList[i];
                // Handle limits from nested products (Opportunity) vs direct consumptionLimits (Line)
                List<Map<String, Object>> allLimits = new List<Map<String, Object>>();
                Boolean foundLimits = false;
                if (feature.containsKey('products')) {
                    List<Object> products = (List<Object>)feature.get('products');
                    if (products != null && !products.isEmpty()) {
                        for (Object prodObj : products) {
                            Map<String, Object> product = (Map<String, Object>)prodObj;
                            if (product != null && product.containsKey('consumptionLimits')) {
                                Object cl = product.get('consumptionLimits');
                                if (cl instanceof List<Object>) {
                                    for (Object item : (List<Object>)cl) {
                                        if (item instanceof Map<String, Object>) {
                                            allLimits.add((Map<String, Object>)item);
                                        }
                                    }
                                } else if (cl instanceof List<Map<String, Object>>) {
                                    allLimits.addAll((List<Map<String, Object>>)cl);
                                }
                                foundLimits = true;
                            }
                        }
                    }
                }
                if (!foundLimits) {
                    if (feature.containsKey('consumptionLimits')) {
                        Object cl = feature.get('consumptionLimits');
                        if (cl instanceof List<Object>) {
                            for (Object item : (List<Object>)cl) {
                                if (item instanceof Map<String, Object>) {
                                    allLimits.add((Map<String, Object>)item);
                                }
                            }
                        } else if (cl instanceof List<Map<String, Object>>) {
                            allLimits = (List<Map<String, Object>>)cl;
                        }
                    } else {
                        allLimits = DMT_FormattingUtils.getListMap(feature, 'consumptionLimits');
                    }
                }
                Boolean hasContent = !allLimits.isEmpty();
                if (hasContent && i > 0) {
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    if (String.isNotBlank(stateName) && new List<String>{'RED','YELLOW','GREEN'}.contains(stateName)) {
                        table += '<table class="style-table" style="width:100%; border-collapse: collapse; margin-bottom: 10px;">'
                            + '<tr data-dmt-table-title="true"><td style="font-size: 16px; color: #004481; font-weight: bold; padding: 4px; text-align: left;">' + name + '</td>'
                            + '<td style="text-align: right; padding: 4px;">' + DMT_FormattingUtils.renderTrafficLight(stateName) + '</td></tr>'
                            + '</table>';
                    }
                    table += '<table class="style-table" style="width:100%; border-collapse: collapse;">';
                    Map<String, Object> amount = new Map<String, Object>();
                    Boolean proceed = false;
                    for (Map<String, Object> consumtionLimits : allLimits) {
                        amount = (Map<String, Object>) consumtionLimits.get('amount');
                        if (amount != null) {
                            proceed = true;
                            break;
                        }
                    }
                    if (proceed) {
                        if (!data.itemImgBase64.isEmpty() && data.itemImgBase64.size() > 7) {
                            Integer j = imageIndex;
                            System.debug('DMT_DefaultLimitVisualRenderer renderHtml image size, ' + data.itemImgBase64.size());
                            if (j >= 0 && j < data.itemImgBase64.size()) {
                                System.debug('DMT_DefaultLimitVisualRenderer renderHtml image index, ' + j);
                                String raw = normalizeImageBase64(data.itemImgBase64[j].imgB64);
                                String dataUri = toImageDataUri(raw);
                                System.debug('DMT_DefaultLimitVisualRenderer renderHtml normalized dataUri, ' + dataUri);
                                if (String.isNotBlank(dataUri)) {
                                    table += '<tr style="page-break-inside: avoid;">' +
                                            '  <td colspan="3" style="padding:10px 0; border-bottom:1px solid #ccc; text-align:center;">' +
                                            '    <img alt="item" src="' + DMT_FormattingUtils.checkNull(dataUri) + '" ' +
                                            '    style="display:block; width:100%; max-width:100%; height:auto; margin:0 auto;" />' +
                                            '  </td>' +
                                            '</tr>';
                                }
                            }
                        } else {
                            // No image available: generate chart HTML for this feature
                            if (chartIndex < chartRequests.size()) {
                                table += '</table>';
                                table += DMT_ChartHtmlGenerator.getHorizontalBarChartHtml(chartRequests[chartIndex]);
                                table += '<table class="style-table" style="width:100%; border-collapse: collapse;">';
                            }
                            chartIndex++;
                        }
                        imageIndex++;
                        for (Map<String, Object> consumtionLimits : allLimits) {
                            String stateNameLimit = DMT_FormattingUtils.checkNull(consumtionLimits?.get('stateName'));
                            String limitDesc = DMT_FormattingUtils.checkNull(consumtionLimits?.get('limitDesc'));
                            String productId = null;
                            String labelToShow = limitDesc;
                            if (isOpportunity && consumtionLimits.containsKey('productId') && consumtionLimits.get('productId') != null) {
                                productId = String.valueOf(consumtionLimits.get('productId'));
                                // Try all possible ID forms in the map (18-char and 15-char)
                                String[] possibleIds = new String[] { productId };
                                if (productId.length() == 18) {
                                    possibleIds.add(productId.substring(0, 15));
                                }
                                // Try each candidate ID
                                for (String pid : possibleIds) {
                                    if (productIdToName.containsKey(pid)) {
                                        labelToShow = productIdToName.get(pid);
                                        break;
                                    }
                                }
                            }
                            // If the label still looks like an ID (UUID or SFID), fall back to limitDesc
                            if (labelToShow == null || labelToShow == '' || labelToShow == productId) {
                                labelToShow = limitDesc;
                            }
                            if (String.isNotBlank(labelToShow)) {
                                table += '<tr data-dmt-row="field">'
                                    + '<td data-dmt-pair="1" data-dmt-value="true" align="left" style="padding: 8px; border-bottom: 1px solid #ccc" width="10%">' + DMT_FormattingUtils.renderTrafficLightSingle(stateNameLimit) + '</td>'
                                    + '<td data-dmt-pair="1" colspan="2" style="padding: 8px; border-bottom: 1px solid #ccc" width="60%">' + labelToShow + '</td>'
                                    + '</tr>';
                                table += renderDetailTable(consumtionLimits, data.currencyIsoCode);
                                table += '</table><table class="style-table" style="width:100%; border-collapse: collapse;">';
                            }
                        }
                    }
                    table += '</table></br>';
                }
            }
            // --- Append Profitability tables for Opportunity ---
            if (isOpportunity) {
                try {
                    table += DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
                } catch (Exception e) {
                    System.debug('Error appending Profitability tables: ' + e.getMessage() + ' ' + e.getLineNumber());
                    table += '<div>Error appending Profitability tables: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
                }
            }
            // --- End append ---
            return table;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultLimitVisualRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    /**
     * Builds the productId/sfId -> real name map by consuming preloaded data
     * from the wrapper (data.profitabilityProductDetailsList). Only executes
     * an additional SOQL query as a fallback when the wrapper is empty.
     */
    private static Map<String, String> buildProductIdToName(DMT_ViewController.LineDataWrapper data) {
        Map<String, String> result = new Map<String, String>();
        List<Map<String, Object>> preloaded = data.profitabilityProductDetailsList;
        if (preloaded == null || preloaded.isEmpty()) {
            // Fallback: query only if loadRelatedData could not preload the data
            Set<String> productIds = new Set<String>();
            for (Map<String, Object> feature : data.featuresList) {
                if (feature.containsKey('products')) {
                    List<Object> products = (List<Object>) feature.get('products');
                    if (products != null) {
                        for (Object prodObj : products) {
                            Map<String, Object> product = (Map<String, Object>) prodObj;
                            if (product != null && product.containsKey('productId') && product.get('productId') != null) {
                                productIds.add(String.valueOf(product.get('productId')));
                            }
                        }
                    }
                }
            }
            if (productIds.isEmpty()) { return result; }
            preloaded = DMT_Profitability_utils.getProductDetailsByIds(new List<String>(productIds), data.opportunity.Id);
        }
        for (Map<String, Object> prod : preloaded) {
            String id   = prod.containsKey('gf_group_priority_opportunity_id__c') && prod.get('gf_group_priority_opportunity_id__c') != null
                          ? String.valueOf(prod.get('gf_group_priority_opportunity_id__c')) : null;
            String name = prod.containsKey('Name') && prod.get('Name') != null
                          ? String.valueOf(prod.get('Name')) : null;
            if (id != null && name != null)   { result.put(id, name); }
            if (prod.containsKey('Id') && prod.get('Id') != null && name != null) {
                result.put(String.valueOf(prod.get('Id')), name);
            }
        }
        return result;
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
        // If already a data URI, return as-is
        if (cleaned.toLowerCase().startsWith('data:')) {
            return cleaned;
        }
        // Try to infer MIME type from Base64 header to avoid forcing JPEG always
        // Common signatures (base64-encoded):
        // JPEG starts with /9j/
        // PNG starts with iVBORw0KGgo
        // GIF starts with R0lGOD
        String lower = cleaned.toLowerCase();
        String mime = 'image/jpeg';
        if (lower.startsWith('ivborw0kggo')) {
            mime = 'image/png';
        } else if (lower.startsWith('r0lgod')) {
            mime = 'image/gif';
        }
        return 'data:' + mime + ';base64,' + cleaned;
    }

    private static String renderDetailTable(Map<String, Object> consumptionLimits, String currencyIsoCode) {
        Map<String, Object> amount = (Map<String, Object>) consumptionLimits.get('amount');
        if (amount == null) return '';
        Decimal sumAmount = (DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('notSignedTrConsumptionAmount')));
        Decimal newOpportunity = (DMT_FormattingUtils.convertValue(amount.get('unavailableRiskAmount')) - sumAmount);
        Decimal totalAmount = (DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount')) +
            DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount')));
        Decimal limits = amount.get('currentApprovedAmount') != null ? DMT_FormattingUtils.convertValue(amount.get('currentApprovedAmount')) : 0;
        String tableDetail = '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr data-dmt-row="field"><td style="padding: 4px; border-top: none;">' + renderPdfColorSquare('#053363') + '</td>'
            + '<td data-dmt-pair="1" data-dmt-label="Drawn:" style="padding: 4px; border-top: none;">Drawn</td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) + DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-row="field"><td style="padding: 4px; border-top: none;">' + renderPdfColorSquare('#1463a6') + '</td>'
            + '<td data-dmt-pair="1" data-dmt-label="Undrawn committed:" style="padding: 4px; border-top: none;">Undrawn committed</td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-row="field"><td style="padding: 4px; border-top: none;">' + renderPdfColorSquare('#2496eb') + '</td>'
            + '<td data-dmt-pair="1" data-dmt-label="Undrawn uncommitted:" style="padding: 4px; border-top: none;">Undrawn uncommitted</td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-row="field"><td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + renderPdfColorSquare('#2dcccd') + '</td>'
            + '<td data-dmt-pair="1" data-dmt-label="Pending authorized:" style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">Pending authorized</td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-row="field"><td style="padding: 4px; border-top: none; border-bottom: none;">' + renderPdfColorSquare('#ffffff') + '</td>'
            + '<td data-dmt-pair="1" data-dmt-label="Total Amount:" style="padding: 4px; border-top: none; border-bottom: none;">Total Amount</td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 4px; border-top: none; border-bottom: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(totalAmount) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="border-top: none; border-bottom: none;">&nbsp;</td></tr>'
            + '<tr data-dmt-row="field"><td style="padding: 4px; border-top: none;">' + renderPdfColorSquare('#bdbdbd') + '</td>'
            + '<td data-dmt-pair="1" data-dmt-label="New Opportunity:" style="padding: 4px; border-top: none;">New Opportunity</td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(newOpportunity) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-row="field"><td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + renderPdfColorSquare('#d90000') + '</td>'
            + '<td data-dmt-pair="1" data-dmt-label="Limit:" style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">Limit</td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + DMT_FormattingUtils.formatDecimalAbbreviation(limits) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-row="field"><td style="padding: 4px; border-bottom: none; border-top: none;">' + renderPdfColorSquare('#ffffff') + '</td>'
            + '<td data-dmt-pair="1" data-dmt-label="Exceeded:" style="padding: 4px; border-bottom: none; border-top: none;">Exceeded</td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 4px; border-bottom: none; border-top: none;">' + (limits - (totalAmount + newOpportunity)) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="border-top: none; border-bottom: none;">&nbsp;</td></tr>'
            + '</table>';
        return tableDetail;
    }

    private static String renderPdfColorSquare(String color) {
        String safeColor = String.isBlank(color) ? '#ffffff' : color;
        return '<span style="display:inline-block; width:12px; height:12px; background-color:' + safeColor + '; border:1px solid #d9d9d9; vertical-align:middle; font-size:0; line-height:0;">&#160;</span>';
    }
}