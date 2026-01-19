public with sharing class DMT_DefaultLimitVisualRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList.isEmpty()) {
            return '<div>Limit Visual data not provided</div>';
        }
        System.debug('DMT_DefaultLimitVisualRenderer renderHtml data.featuresList, '+ JSON.serialize(data.featuresList));
        try {
            String table = '';
            for (Integer i = 0; i < data.featuresList.size(); i++) {
                Map<String, Object> feature = data.featuresList[i];
                List<Map<String, Object>> consumptionLimitsList = DMT_FormattingUtils.getListMap(feature, 'consumptionLimits');
                Boolean hasContent = !consumptionLimitsList.isEmpty();
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
                                table += '<tr>'
                                    + '<td align="left" style="padding: 8px; border-bottom: 1px solid #ccc" width="10%">' + DMT_FormattingUtils.renderTrafficLightSingle(stateNameLimit) + '</td>'
                                    + '<td colspan="2" style="padding: 8px; border-bottom: 1px solid #ccc" width="60%">' + limitDesc + '</td>'
                                    + '</tr>';
                                table += renderDetailTable(consumtionLimits, data.currencyIsoCode);
                                table += '</table><table class="style-table" style="width:100%; border-collapse: collapse;">';
                            }
                        }
                    }
                    table += '</table></br>';
                }
            }
            return table;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultLimitVisualRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
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
        String tableDetail = '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr><td style="padding: 4px; border-top: none;"><div style="width: 1rem; background-color: #053363; height: 1rem;"></div></td>'
            + '<td style="padding: 4px; border-top: none;">Drawn</td>'
            + '<td style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('cmtContDisposedAmount')) + DMT_FormattingUtils.convertValue(amount.get('uncmtContDisposedAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none;"><div style="width: 1rem; background-color: #1463a6; height: 1rem;"></div></td>'
            + '<td style="padding: 4px; border-top: none;">Undrawn committed</td>'
            + '<td style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('cmtContNonDspsAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none;"><div style="width: 1rem; background-color: #2496eb; height: 1rem;"></div></td>'
            + '<td style="padding: 4px; border-top: none;">Undrawn uncommitted</td>'
            + '<td style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('uncmtContNonDspsAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc"><div style="width: 1rem; background-color: #2dcccd; height: 1rem;"></div></td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">Pending authorized</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + DMT_FormattingUtils.formatDecimalAbbreviation(DMT_FormattingUtils.convertValue(amount.get('authorizedRiskAmount'))) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none; border-bottom: none;"><div style="width: 1rem; background-color: #ffffff; height: 1rem;"></div></td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: none;">Total Amount</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(totalAmount) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="border-top: none; border-bottom: none;">&nbsp;</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none;"><div style="width: 1rem; background-color: #bdbdbd; height: 1rem;"></div></td>'
            + '<td style="padding: 4px; border-top: none;">New Opportunity</td>'
            + '<td style="padding: 4px; border-top: none;">' + DMT_FormattingUtils.formatDecimalAbbreviation(newOpportunity) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc"><div style="width: 1rem; background-color: #d90000; height: 1rem;"></div></td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">Limit</td>'
            + '<td style="padding: 4px; border-top: none; border-bottom: 1px solid #ccc">' + DMT_FormattingUtils.formatDecimalAbbreviation(limits) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="padding: 4px; border-bottom: none; border-top: none;"><div style="width: 1rem; background-color: #fffff; height: 1rem;"></div></td>'
            + '<td style="padding: 4px; border-bottom: none; border-top: none;">Exceeded</td>'
            + '<td style="padding: 4px; border-bottom: none; border-top: none;">' + (limits - (totalAmount + newOpportunity)) + ' ' + currencyIsoCode + '</td></tr>'
            + '<tr><td style="border-top: none; border-bottom: none;">&nbsp;</td></tr>'
            + '</table>';
        return tableDetail;
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList.isEmpty()) {
            return new Map<String, Object>();
        }
        System.debug('DMT_DefaultLimitVisualRenderer renderPdfJson data.featuresList, '+ JSON.serialize(data.featuresList));
        try {
            List<Object> contentListLimitDetailVisual= new List<Object>();
            Map<String, Object> componentLimitDetailVisual = new Map<String, Object>();
            Map<String, Object> stylesTableLimit = new Map<String, Object>();
                stylesTableLimit.put('fontSize', 8);
            Map<String, Object> marginTable = new Map<String, Object>();
                marginTable.put('top', 5);
                marginTable.put('bottom',5);
            Map<String, Object> lineWidthItem = new Map<String, Object>();
                lineWidthItem.put('top',0.1);
                lineWidthItem.put('bottom',0.1);
                stylesTableLimit.put('lineWidth',lineWidthItem);
            //TITLE 
            Map<String, Object> tableLimit = new Map<String, Object>();
            List<List<String>> headers = new List<List<String>>();
            List<String> listHeaders = new List<String>{' ',' ', ' '};
            headers.add(listHeaders);
    
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
                        for(Object title : listTitle){
                            contentListLimitDetailVisual.add(title);
                        }
                    }
                
                 //    List<Map<String, Object>> consumptionLimitsList = getListMap(feature,'consumptionLimits');
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
                            if (j >= 0 && j < data.itemImgBase64.size()) {
                                tableLimitVisual.put('src', data.itemImgBase64[j]?.imgB64);
                            }
                            tableLimitVisual.put('type', 'image');
                            contentListLimitDetailVisual.add(tableLimitVisual);
                            
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
                        List<Object> bodyConsu = new List<Object>();
                        Map<String, Object> tableLimitConsu = new Map<String, Object>();
                        Map<String, Object> printDatail = new Map<String, Object>();
                        for(Map<String, Object> consumtionLimits : consumptionLimitsList) {
                            stateName = DMT_FormattingUtils.checkNull(consumtionLimits?.get('stateName'));
                            String limitDesc = DMT_FormattingUtils.checkNull(consumtionLimits?.get('limitDesc'));
                            if (String.isNotBlank(limitDesc)) {
                                tableLimitConsu = printRowDetailConsumtion(stateName, limitDesc);
                                printDatail = printTableDetail(consumtionLimits, data.currencyIsoCode);                                 
                            }
                            contentListLimitDetailVisual.add(tableLimitConsu);
                            contentListLimitDetailVisual.add(printDatail);
                        }
                        componentLimitDetailVisual.put('content', contentListLimitDetailVisual);
                        componentLimitDetailVisual.put('name', 'LIMIT DETAIL IMAGE');
                    }
                }
            }
            return componentLimitDetailVisual;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultLimitVisualRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_DefaultLimitVisualRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }

    private static Map<String, Object> printRowDetailConsumtion(String stateName, String limitDesc){
        List<Object> contentListLimitDetail= new List<Object>();
        Map<String, Object> stylesTableLimit = new Map<String, Object>();
            stylesTableLimit.put('fontSize', 8);
        Map<String, Object> marginTable = new Map<String, Object>();
            marginTable.put('top', 2);
            marginTable.put('bottom',2);
        Map<String, Object> lineWidthItem = new Map<String, Object>();
            lineWidthItem.put('bottom',0.1);
            stylesTableLimit.put('lineWidth',lineWidthItem);
        Map<String, Object> tableRowDetailConsumtion = new Map<String, Object>();
        List<Object> body = new List<Object>();
        List<Object> rows = new List<Object>();
            rows.add(DMT_FormattingUtils.createTrafficLightJson(stateName, 'ONE'));
            rows.add(limitDesc);
            body.add(rows);

            tableRowDetailConsumtion.put('margin',marginTable); 
            tableRowDetailConsumtion.put('style', stylesTableLimit);
            tableRowDetailConsumtion.put('body', body);
            tableRowDetailConsumtion.put('type', 'table');

        return tableRowDetailConsumtion;
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
              //  secondRow.add((limits - (totalAmount + newOpportunity))+' '+ currencyIsoCode);
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