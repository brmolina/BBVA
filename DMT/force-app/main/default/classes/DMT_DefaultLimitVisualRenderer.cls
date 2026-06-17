public with sharing class DMT_DefaultLimitVisualRenderer implements DMT_ViewRenderer {
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
            // --- Patch: Si es Opportunity, obtener mapping productId->nombre real ---
            Boolean isOpportunity = data.opportunity != null && data.opportunity.Id != null;
            Map<String, String> productIdToName = isOpportunity ? buildProductIdToName(data) : new Map<String, String>();

            for (Integer i = 0; i < data.featuresList.size(); i++) {
                Map<String, Object> feature = data.featuresList[i];
                // --- Nuevo: manejar limits en products (Opportunity) y directo (Line) ---
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
                            + '<tr><td style="font-size: 16px; color: #004481; font-weight: bold; padding: 4px; text-align: left;">' + name + '</td>'
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
                            // Sin imagen: generar chart HTML por feature
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
                                // Buscar por todos los posibles IDs en el mapa
                                String[] possibleIds = new String[] { productId };
                                if (productId.length() == 18) {
                                    possibleIds.add(productId.substring(0, 15));
                                }
                                // Buscar por cada posible id
                                for (String pid : possibleIds) {
                                    if (productIdToName.containsKey(pid)) {
                                        labelToShow = productIdToName.get(pid);
                                        break;
                                    }
                                }
                            }
                            // Si sigue siendo un id (parece un UUID o SFID), y hay limitDesc, mostrar limitDesc
                            if (labelToShow == null || labelToShow == '' || labelToShow == productId) {
                                labelToShow = limitDesc;
                            }
                            if (String.isNotBlank(labelToShow)) {
                                table += '<tr>'
                                    + '<td align="left" style="padding: 8px; border-bottom: 1px solid #ccc" width="10%">' + DMT_FormattingUtils.renderTrafficLightSingle(stateNameLimit) + '</td>'
                                    + '<td colspan="2" style="padding: 8px; border-bottom: 1px solid #ccc" width="60%">' + labelToShow + '</td>'
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
     * Construye el mapa productId/sfId -> nombre real consumiendo primero los datos
     * precargados en el wrapper (data.profitabilityProductDetailsList). Solo ejecuta
     * una SOQL adicional como fallback si el wrapper viene vacío.
     */
    private static Map<String, String> buildProductIdToName(DMT_ViewController.LineDataWrapper data) {
        Map<String, String> result = new Map<String, String>();
        List<Map<String, Object>> preloaded = data.profitabilityProductDetailsList;
        if (preloaded == null || preloaded.isEmpty()) {
            // Fallback: consultar solo si loadRelatedData no pudo precargar
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
            + '<tr><td style="padding: 4px; border-top: none;">' + renderPdfColorSquare('#053363') + '</td>'
            + '<td style="padding: 4px; border-top: none;">Drawn</td>'
            + '<td style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) + DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none;">' + renderPdfColorSquare('#1463a6') + '</td>'
            + '<td style="padding: 4px; border-top: none;">Undrawn committed</td>'
            + '<td style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none;">' + renderPdfColorSquare('#2496eb') + '</td>'
            + '<td style="padding: 4px; border-top: none;">Undrawn uncommitted</td>'
            + '<td style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + renderPdfColorSquare('#2dcccd') + '</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">Pending authorized</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none; border-bottom: none;">' + renderPdfColorSquare('#ffffff') + '</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: none;">Total Amount</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(totalAmount) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="border-top: none; border-bottom: none;">&nbsp;</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none;">' + renderPdfColorSquare('#bdbdbd') + '</td>'
            + '<td style="padding: 4px; border-top: none;">New Opportunity</td>'
            + '<td style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(newOpportunity) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + renderPdfColorSquare('#d90000') + '</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">Limit</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + DMT_FormattingUtils.formatDecimalAbbreviation(limits) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-bottom: none; border-top: none;">' + renderPdfColorSquare('#ffffff') + '</td>'
            + '<td style="padding: 4px; border-bottom: none; border-top: none;">Exceeded</td>'
            + '<td style="padding: 4px; border-bottom: none; border-top: none;">' + (limits - (totalAmount + newOpportunity)) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="border-top: none; border-bottom: none;">&nbsp;</td></tr>'
            + '</table>';
        return tableDetail;
    }

    private static String renderPdfColorSquare(String color) {
        String safeColor = String.isBlank(color) ? '#ffffff' : color;
        return '<span style="display:inline-block; width:12px; height:12px; background-color:' + safeColor + '; border:1px solid #d9d9d9; vertical-align:middle; font-size:0; line-height:0;">&#160;</span>';
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList.isEmpty()) {
            return new Map<String, Object>();
        }
        System.debug('DMT_DefaultLimitVisualRenderer renderPdfJson data.featuresList, '+ JSON.serialize(data.featuresList));
        try {
            List<Object> contentListLimitDetailVisual= new List<Object>();
            Map<String, Object> pdfComponentLimitDetailVisual = new Map<String, Object>();
            // Mapping de productos: reutilizar datos precargados en el wrapper (cero SOQL adicionales)
            Boolean pdfIsOpportunity = data.opportunity != null && data.opportunity.Id != null;
            Map<String, String> pdfProductIdToName = pdfIsOpportunity ? buildProductIdToName(data) : new Map<String, String>();
            //add page break
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 80
            };
            for (Integer i = 0; i < data.featuresList.size(); i++) {
                Map<String, Object> feature = data.featuresList[i];
                List<Map<String, Object>> consumptionLimitsList = DMT_FormattingUtils.getListMap(feature, 'consumptionLimits');
                Boolean hasContent = !consumptionLimitsList.isEmpty();
                if(hasContent && i > 0){
                    contentListLimitDetailVisual.add(pageBreak);
                    // CREATE TITLE
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    if (String.isNotBlank(stateName) && new List<String>{'RED','YELLOW','GREEN'}.contains(stateName)) {
                        List<Object> listTitle = DMT_FormattingUtils.createTitleWithCircles(name, stateName);
                        contentListLimitDetailVisual.add(listTitle);
                    }
                }
                
                Map<String, Object> amount = new Map<String, Object>();
                Map<String, Object> chartData = new Map<String, Object>(); 
                String targetColor = 'red';
                List<Object> targets = new List<Object>();
                List<Object> labels = new List<Object>();
                List<Object> datasets = new List<Object>();
                List<Object> limitLights = new List<Object>();
                List<Object> currencies = new List<Object>();
                List<Object> conditions = new List<Object>();
                List<Object> sections = new List<Object>{'Drawn', 'Undrawn committed', 'Undrawn uncommitted', 'Pending authorized','New Opportunity'};
                List<Object> dataDraw = new List<Object>();
                List<Object> dataUndrawnCommitted = new List<Object>();
                List<Object> dataUndrawnUncommitted = new List<Object>();
                List<Object> dataPendingAuthorized = new List<Object>();
                List<Object> dataNewOpportunity = new List<Object>();

                Boolean proceed = false;
                for(Map<String, Object> consumtionLimits : consumptionLimitsList) {
                    amount = (Map<String, Object>) consumtionLimits.get('amount');
                    if(amount != null && !amount.isEmpty()){
                        proceed = true;
                        conditions.add(consumtionLimits.get('conditionDesc'));
                        currencies.add(consumtionLimits.get('currencyId'));
                        labels.add(consumtionLimits.get('limitDesc'));
                        limitLights.add(consumtionLimits.get('stateName'));
                        targets.add(DMT_FormattingUtils.convertValue(amount.get('currentApprovedAmount')));
                        dataDraw.add(DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) + DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount')));
                        dataUndrawnCommitted.add(DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount')));
                        dataUndrawnUncommitted.add(DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount')));
                        dataPendingAuthorized.add(DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount')));
                        dataNewOpportunity.add(DMT_FormattingUtils.convertValue(amount.get('notSignedTrConsumptionAmount')));     
                    }
                }
                if(proceed){
                    if(data.isImg64 && i > 0 && !data.itemImgBase64.isEmpty() && data.itemImgBase64.size() > 0){
                        Integer j = data.itemImgBase64.size() <= 3 ? i - 1 : i - 2;
                        Map<String, Object>  marginVisualImage = new Map<String, Object>();
                        marginVisualImage.put('left', 1);
                        marginVisualImage.put('bottom', 5);
                        marginVisualImage.put('right', 1);
                        marginVisualImage.put('top', 5);
                        Map<String, Object> tableLimitVisual = new Map<String, Object>();
                        tableLimitVisual.put('margin', marginVisualImage);
                        tableLimitVisual.put('aspectRatio', 0.46);
                        tableLimitVisual.put('width', 150);
                        tableLimitVisual.put('format','JPEG');
                        Boolean hasSrc = false;
                        if (j >= 0 && j < data.itemImgBase64.size()) {
                            String imgB64 = data.itemImgBase64[j]?.imgB64;
                            if (String.isNotBlank(imgB64)) {
                                tableLimitVisual.put('src', imgB64);
                                hasSrc = true;
                            }
                        }
                        tableLimitVisual.put('type', 'image');
                        if (hasSrc) {
                            contentListLimitDetailVisual.add(tableLimitVisual);
                        }
                    }else{
                        Map<String, Object> mapDataDraw = new Map<String, Object>();
                        mapDataDraw.put('backgroundColor','rgba(4, 50, 99, 1)');
                        mapDataDraw.put('data',dataDraw);
                        mapDataDraw.put('hoverBackgroundColor','rgba(4, 50, 99, 1)');
                        mapDataDraw.put('label','Drawn');
                        datasets.add(mapDataDraw);
                        Map<String, Object> mapDataUndrawnCommitted = new Map<String, Object>();
                        mapDataUndrawnCommitted.put('backgroundColor','rgba(20, 100, 165, 1)');
                        mapDataUndrawnCommitted.put('data',dataUndrawnCommitted);
                        mapDataUndrawnCommitted.put('hoverBackgroundColor','rgba(20, 100, 165, 1)');
                        mapDataUndrawnCommitted.put('label','Undrawn committed');
                        datasets.add(mapDataUndrawnCommitted);
                        Map<String, Object> mapDataUndrawnUncommitted = new Map<String, Object>();
                        mapDataUndrawnUncommitted.put('backgroundColor','rgba(36, 150, 234, 1)');
                        mapDataUndrawnUncommitted.put('data',dataUndrawnUncommitted);
                        mapDataUndrawnUncommitted.put('hoverBackgroundColor','rgba(36, 150, 234, 1)');
                        mapDataUndrawnUncommitted.put('label','Undrawn uncommitted');
                        datasets.add(mapDataUndrawnUncommitted);
                        Map<String, Object> mapDataPendingAuthorized = new Map<String, Object>();
                        mapDataPendingAuthorized.put('backgroundColor','rgba(45, 204, 205, 1)');
                        mapDataPendingAuthorized.put('data',dataPendingAuthorized);
                        mapDataPendingAuthorized.put('hoverBackgroundColor','rgba(45, 204, 205, 1)');
                        mapDataPendingAuthorized.put('label','Pending authorized');
                        datasets.add(mapDataPendingAuthorized);
                        Map<String, Object> mapDataNewOpportunity = new Map<String, Object>();
                        mapDataNewOpportunity.put('backgroundColor','rgba(189, 189, 189, 1)');
                        mapDataNewOpportunity.put('data', dataNewOpportunity);
                        mapDataNewOpportunity.put('hoverBackgroundColor','rgba(189, 189, 189, 1)');
                        mapDataNewOpportunity.put('label','New Opportunity');
                        datasets.add(mapDataNewOpportunity);

                        chartData.put('targets', targets);
                        chartData.put('targetColor', targetColor);
                        chartData.put('sections', sections);
                        chartData.put('originCurrency', 'EUR');
                        chartData.put('limitLights', limitLights);
                        chartData.put('labels', labels);
                        chartData.put('datasets', datasets);
                        chartData.put('currencies', currencies);
                        chartData.put('conditions', conditions);   

                        Map<String, Object> wrapperChartData = new Map<String, Object>();
                        wrapperChartData.put('wrapperData',chartData);
                        wrapperChartData.put('format','JPEG');
                        wrapperChartData.put('quality', 0.1);
                        Map<String, Object>  marginVisualImage = new Map<String, Object>();
                        marginVisualImage.put('left', 15);
                        marginVisualImage.put('bottom', 7);
                        marginVisualImage.put('right', 15);
                        marginVisualImage.put('top', 7);
                        Map<String, Object> tableLimitVisual = new Map<String, Object>();
                        tableLimitVisual.put('margin', marginVisualImage);
                        tableLimitVisual.put('aspectRatio', 0.46);
                        tableLimitVisual.put('width', 150);
                        tableLimitVisual.put('chartType', 'dmt_subfeature_chart');
                        tableLimitVisual.put('params', wrapperChartData);
                        tableLimitVisual.put('type', 'chart');
                        contentListLimitDetailVisual.add(tableLimitVisual);
                    }    
                    for(Map<String, Object> consumtionLimits : consumptionLimitsList) {
                        String pdfStateName = DMT_FormattingUtils.checkNull(consumtionLimits?.get('stateName'));
                        String pdfLimitDesc = DMT_FormattingUtils.checkNull(consumtionLimits?.get('limitDesc'));
                        String pdfProductId = null;
                        if (pdfIsOpportunity && consumtionLimits.containsKey('productId') && consumtionLimits.get('productId') != null) {
                            pdfProductId = String.valueOf(consumtionLimits.get('productId'));
                        }
                        String pdfLabelToShow = pdfLimitDesc;
                        if (pdfIsOpportunity && pdfProductId != null && pdfProductIdToName.containsKey(pdfProductId)) {
                            pdfLabelToShow = pdfProductIdToName.get(pdfProductId);
                        }
                        if (String.isNotBlank(pdfLabelToShow)) {
                            Map<String, Object> tableLimitConsu = DMT_DefaultLimitVisualRenderer.printRowDetailConsumption(pdfStateName, pdfLabelToShow);
                            Map<String, Object> printDetail = DMT_DefaultLimitVisualRenderer.printTableDetail(consumtionLimits, data.currencyIsoCode);
                            contentListLimitDetailVisual.add(tableLimitConsu);
                            contentListLimitDetailVisual.add(printDetail);
                        }
                    }
                }
            }
            pdfComponentLimitDetailVisual.put('content', contentListLimitDetailVisual);
            pdfComponentLimitDetailVisual.put('name', 'LIMIT DETAIL IMAGE');
            return pdfComponentLimitDetailVisual;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultLimitVisualRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_DefaultLimitVisualRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }

    private static Map<String, Object> printRowDetailConsumption(String stateName, String limitDesc){
        Map<String, Object> stylesTableLimit = new Map<String, Object>();
        stylesTableLimit.put('fontSize', 8);
        Map<String, Object> marginTable = new Map<String, Object>();
        marginTable.put('top', 2);
        marginTable.put('bottom',2);
        Map<String, Object> lineWidthItem = new Map<String, Object>();
        lineWidthItem.put('bottom',0.1);
        stylesTableLimit.put('lineWidth',lineWidthItem);
        Map<String, Object> tableRowDetailConsumption = new Map<String, Object>();
        List<Object> body = new List<Object>();
        List<Object> rows = new List<Object>();
        rows.add(DMT_FormattingUtils.createTrafficLightJson(stateName, 'ONE'));
        rows.add(limitDesc);
        body.add(rows);
        tableRowDetailConsumption.put('margin',marginTable); 
        tableRowDetailConsumption.put('style', stylesTableLimit);
        tableRowDetailConsumption.put('type', 'table');
        tableRowDetailConsumption.put('body', body);
        return tableRowDetailConsumption;
    }

    private static Map<String, Object> printTableDetail(Map<String, Object> consumtionLimits, String currencyIsoCode){
        List<Object> contentListLimitDetail= new List<Object>();
        Map<String, Object> stylesTableLimit = new Map<String, Object>();
        stylesTableLimit.put('fontSize', 8);
        Map<String, Object> marginTable = new Map<String, Object>();
        marginTable.put('top', 0);
        marginTable.put('bottom',2);
        Map<String, Object> lineWidthItem = new Map<String, Object>();
        lineWidthItem.put('bottom',0);
        stylesTableLimit.put('lineWidth',lineWidthItem);
        Map<String, Object> tableLimitPrint = new Map<String, Object>();

        Map<String, Object> amount = (Map<String, Object>) consumtionLimits.get('amount');
        if(amount !=null){
            Decimal sumAmount = (DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount')) +
                DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) +
                DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount')) +
                DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount')) +
                DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount')) +
                DMT_FormattingUtils.convertValue(amount.get('notSignedTrConsumptionAmount')));

            Decimal newOpportunity =  (DMT_FormattingUtils.convertValue(amount.get('unavailableRiskAmount')) - sumAmount);

            Decimal totalAmount = (DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) +
                DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount')) +
                DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount')) +
                DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount')) +
                DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount')));

            Decimal limits = amount.get('currentApprovedAmount') != null ? DMT_FormattingUtils.convertValue(amount.get('currentApprovedAmount')) : 0;
            List<Object> body = new List<Object>();
            List<Object> firtRow = new List<Object>{'Drawn','Undrawn committed','Undrawn uncommitted','Pending authorized', 'Total Amount',' ', 'New Opportunity','Limit','Exceeded'};
            List<Object> secondRow = new List<Object>();
            secondRow.add(DMT_FormattingUtils.formatObjectAbbreviation((DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) + DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount'))))+' '+ currencyIsoCode);
            secondRow.add(DMT_FormattingUtils.formatObjectAbbreviation(DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount'))) +' '+ currencyIsoCode);
            secondRow.add(DMT_FormattingUtils.formatObjectAbbreviation(DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount'))) +' '+ currencyIsoCode);
            secondRow.add(DMT_FormattingUtils.formatObjectAbbreviation(DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount'))) +' '+ currencyIsoCode);
            secondRow.add(DMT_FormattingUtils.formatObjectAbbreviation(totalAmount) +' '+ currencyIsoCode);
            secondRow.add('');
            secondRow.add(DMT_FormattingUtils.formatObjectAbbreviation(newOpportunity) +' '+ currencyIsoCode);
            secondRow.add(DMT_FormattingUtils.formatObjectAbbreviation(limits) +' '+ currencyIsoCode);
            String formattedFullValue = DMT_FormattingUtils.formatCurrencyAmount((limits - (totalAmount + newOpportunity)), '');
            if (formattedFullValue != null) {
                if (formattedFullValue.startsWith('-.')) {
                    formattedFullValue = '-' + formattedFullValue.substring(2);
                } else if (formattedFullValue.startsWith('.')) {
                    formattedFullValue = formattedFullValue.substring(1);
                }
            }
            secondRow.add(formattedFullValue +' '+ currencyIsoCode);
            List<Object> rectRow = new List<Object>();
            rectRow.add(DMT_FormattingUtils.printRectTableDetail('#053363'));
            rectRow.add(DMT_FormattingUtils.printRectTableDetail('#1463a6'));
            rectRow.add(DMT_FormattingUtils.printRectTableDetail('#2496eb'));
            rectRow.add(DMT_FormattingUtils.printRectTableDetail('#2dcccd'));
            rectRow.add('');
            rectRow.add('');
            rectRow.add(DMT_FormattingUtils.printRectTableDetail('#bdbdbd'));
            rectRow.add(DMT_FormattingUtils.printRectTableDetail('#d90000'));
            rectRow.add(DMT_FormattingUtils.printRectTableDetail('#ffffff'));
            for(Integer i = 0; i < firtRow.size(); i++) {
                List<Object> rows = new List<Object>();
                rows.add(rectRow[i]);               
                rows.add(firtRow[i]);
                rows.add(secondRow[i]); 
                body.add(rows);
            }        
            tableLimitPrint.put('margin',marginTable); 
            tableLimitPrint.put('style', stylesTableLimit);
            tableLimitPrint.put('body', body);
            tableLimitPrint.put('type', 'table');
        }
        return tableLimitPrint;
    }
}