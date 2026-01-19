public with sharing class DMT_DefaultLimitRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList.isEmpty()) {
            return '<div>Features data not provided</div>';
        }
        try {
            String table = '';
            for (Integer i = 0; i < data.featuresList.size(); i++) {
                Map<String, Object> feature = data.featuresList[i];
                if (i == 0) {
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    if (String.isNotBlank(stateName) && new List<String>{'RED', 'YELLOW', 'GREEN'}.contains(stateName)) {
                        table += '<table class="style-table" style="width: 100%; border-collapse: collapse; margin-bottom: 10px;">'
                            + '<tr><td style="font-size: 16px; color: #004481; font-weight: bold; padding: 4px; text-align: left;">' + name + '</td>'
                            + '<td style="text-align: right; padding: 4px;">' + DMT_FormattingUtils.renderTrafficLight(stateName) + '</td></tr>'
                            + '</table>';
                    }
                    table += '<table class="style-table" style="width:100%; border-collapse: collapse;">';
                    List<Map<String, Object>> validationLimitList = DMT_FormattingUtils.getListMap(feature, 'validations');
                    for (Map<String, Object> validationLimit : validationLimitList) {
                        table += '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; white-space: normal;"><strong>' + DMT_FormattingUtils.checkNull(validationLimit?.get('name')) + '</strong></td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; white-space: normal;">' + DMT_FormattingUtils.renderTrafficLightSingle(DMT_FormattingUtils.checkNull(validationLimit?.get('state'))) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; white-space: normal;">' + DMT_FormattingUtils.checkNull(validationLimit?.get('message')) + '</td>'
                            + '</tr>';
                    }
                    table += '</table></br></br>';
                }
            }
            return table;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultLimitRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList.isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            List<Object> contentListLimit= new List<Object>();
            // Add a page break before
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 30
            };
    
            Map<String, Object> componentLimit= new Map<String, Object>();
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
            //   List<List<String>> headers = new List<List<String>>();
            List<String> listHeaders = new List<String>{' ',' ', ' '};
            //   headers.add(listHeaders);
            for(Integer i = 0; i < data.featuresList.size(); i++) {
                Map<String, Object> feature = data.featuresList[i];
                List<Map<String, Object>> consumtionLimitsList = DMT_FormattingUtils.getListMap(feature,'consumptionLimits');
                if(i== 0){
                    // CREATE TITLE
                    String name = DMT_FormattingUtils.checkNull(feature?.get('name'));
                    String stateName = DMT_FormattingUtils.checkNull(feature?.get('stateName'));
                    if(String.isNotBlank(stateName) && new List<String>{'RED', 'YELLOW', 'GREEN'}.contains(stateName)) {
                        //add page break
                         contentListLimit.add(pageBreak);
                        // Create title with circle
                        List<Object> listTitle = DMT_FormattingUtils.createTitleWithCircles(name, stateName);
                        System.debug('listTitle: ' + listTitle);
                        for(Object title : listTitle){
                            System.debug('title: ' + title);
                            contentListLimit.add(title);
                        }                
                    }                
                    List<Object> bodyVali = new List<Object>();
                    Map<String, Object> column= new Map<String, Object>();
                    List<Map<String, Object>> validationLimitList = DMT_FormattingUtils.getListMap(feature,'validations');
                    for(Map<String, Object> validationLimit : validationLimitList) {
                        List<Object> row = new List<Object>();
                        row.add(DMT_FormattingUtils.checkNull(validationLimit != null ? validationLimit.get('name') : null));
                        row.add(DMT_FormattingUtils.createTrafficLightJson(DMT_FormattingUtils.checkNull(validationLimit != null ? validationLimit.get('state') : null),'ONE'));
                        row.add(DMT_FormattingUtils.checkNull(validationLimit != null ? validationLimit.get('message') : null));
                        bodyVali.add(row); 
                    } 
                    i++;
                    tableLimit.put('margin',marginTable); 
                    tableLimit.put('style', stylesTableLimit);
                    tableLimit.put('body', bodyVali);
                    //tableLimit.put('head', headers);
                    tableLimit.put('type', 'table');
                    contentListLimit.add(tableLimit);
                    componentLimit.put('content', contentListLimit);
                    componentLimit.put('name', 'LIMIT VALIDATION');  
                }
            }
            return componentLimit;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultLimitRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_DefaultLimitRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}