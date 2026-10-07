// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
public without sharing class DMT_LineSanctionLimitVisualRenderer implements DMT_ViewRenderer {
    
    // ==========================================
    // HTML RENDERING
    // ==========================================
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.sanctionFeaturesList.isEmpty()) {
            return '<div>Approval Limit Visual data not provided</div>';
        }
        System.debug('DMT_LineSanctionLimitVisualRenderer renderHtml data.sanctionFeaturesList, '+ JSON.serialize(data.sanctionFeaturesList));
        try {
            String table = '';
            for (Integer i = 0; i < data.sanctionFeaturesList.size(); i++) {
                Map<String, Object> feature = data.sanctionFeaturesList[i];
                List<Map<String, Object>> consumptionLimitsList = DMT_FormattingUtils.getListMap(feature, 'consumptionLimits');
                Boolean hasContent = !consumptionLimitsList.isEmpty();
                
                if (hasContent && i > 0) {
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    
                    if (String.isNotBlank(stateName) && new List<String>{'RED','YELLOW','GREEN'}.contains(stateName)) {
                        table += '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse; margin-bottom: 10px;">'
                            + '<tr data-dmt-table-row="true"><td data-dmt-cell="true" style="font-size: 16px; color: #004481; font-weight: bold; padding: 4px; text-align: left;">' + name + '</td>'
                            + '<td data-dmt-cell="true" style="text-align: right; padding: 4px;">' + DMT_FormattingUtils.renderTrafficLight(stateName) + '</td></tr>'
                            + '</table>';
                    }
                    
                    table += '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">';
                    Map<String, Object> amount = new Map<String, Object>();
                    Boolean proceed = false;
                    for (Map<String, Object> consumtionLimits : consumptionLimitsList) {
                        amount = (Map<String, Object>) consumtionLimits.get('amount');
                        if (amount != null) {
                            proceed = true;
                            break;
                        }
                    }
                    
                    if (proceed) {
                        if (!data.itemImgBase64.isEmpty() && data.itemImgBase64.size() > 0) {
                            Integer j = data.itemImgBase64.size() <= 3 ? i - 1 : i - 2;
                            if (j >= 0 && j < data.itemImgBase64.size()) {
                                table += '<div><img src="' + DMT_FormattingUtils.checkNull(data.itemImgBase64[j]?.imgB64) + '" width="90%" height="90%"/></div>';
                            }
                        }
                        
                        for (Map<String, Object> consumtionLimits : consumptionLimitsList) {
                            String stateNameLimit = DMT_FormattingUtils.checkNull(consumtionLimits?.get('stateName'));
                            String limitDesc = DMT_FormattingUtils.checkNull(consumtionLimits?.get('limitDesc'));
                            if (String.isNotBlank(limitDesc)) {
                                table += '<tr data-dmt-table-row="true">'
                                    + '<td data-dmt-cell="true" align="left" style="padding: 8px; border-bottom: 1px solid #ccc" width="10%">' + DMT_FormattingUtils.renderTrafficLightSingle(stateNameLimit) + '</td>'
                                    + '<td data-dmt-cell="true" colspan="2" style="padding: 8px; border-bottom: 1px solid #ccc" width="60%">' + limitDesc + '</td>'
                                    + '</tr>';
                                table += renderDetailTable(consumtionLimits, data.currencyIsoCode);
                                table += '</table><table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">';
                            }
                        }
                    }
                    table += '</table></br>';
                }
            }
            return table;
        } catch (Exception e){
            System.debug('Error in DMT_LineSanctionLimitVisualRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
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
        
        String tableDetail = '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr data-dmt-table-row="true"><td data-dmt-cell="true" style="padding: 4px; border-top: none;">' + renderPdfColorSquare('#053363') + '</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none;">Drawn</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) + DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-table-row="true"><td data-dmt-cell="true" style="padding: 4px; border-top: none;">' + renderPdfColorSquare('#1463a6') + '</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none;">Undrawn committed</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-table-row="true"><td data-dmt-cell="true" style="padding: 4px; border-top: none;">' + renderPdfColorSquare('#2496eb') + '</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none;">Undrawn uncommitted</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-table-row="true"><td data-dmt-cell="true" style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + renderPdfColorSquare('#2dcccd') + '</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">Pending authorized</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-table-row="true"><td data-dmt-cell="true" style="padding: 4px; border-top: none; border-bottom: none;">' + renderPdfColorSquare('#ffffff') + '</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none; border-bottom: none;">Total Amount</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none; border-bottom: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(totalAmount) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-table-row="true"><td data-dmt-cell="true" style="border-top: none; border-bottom: none;">&nbsp;</td></tr>'
            + '<tr data-dmt-table-row="true"><td data-dmt-cell="true" style="padding: 4px; border-top: none;">' + renderPdfColorSquare('#bdbdbd') + '</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none;">New Opportunity</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(newOpportunity) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-table-row="true"><td data-dmt-cell="true" style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + renderPdfColorSquare('#d90000') + '</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">Limit</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + DMT_FormattingUtils.formatDecimalAbbreviation(limits) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-table-row="true"><td data-dmt-cell="true" style="padding: 4px; border-bottom: none; border-top: none;">' + renderPdfColorSquare('#ffffff') + '</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-bottom: none; border-top: none;">Exceeded</td>'
            + '<td data-dmt-cell="true" style="padding: 4px; border-bottom: none; border-top: none;">' + (limits - (totalAmount + newOpportunity)) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr data-dmt-table-row="true"><td data-dmt-cell="true" style="border-top: none; border-bottom: none;">&nbsp;</td></tr>'
            + '</table>';
        return tableDetail;
    }

    // ==========================================
    // PDF RENDERING
    // ==========================================

    private static String renderPdfColorSquare(String color) {
        String safeColor = String.isBlank(color) ? '#ffffff' : color;
        return '<span style="display:inline-block; width:12px; height:12px; background-color:' + safeColor + '; border:1px solid #d9d9d9; vertical-align:middle; font-size:0; line-height:0;">&#160;</span>';
    }
}