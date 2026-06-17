public with sharing class DMT_DefaultActiveRelatedLinesRenderer implements DMT_ViewRenderer{

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data.line.Client__c == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Line data not provided</div>';
        }

        try {
            String table = '';
            System.debug('data.activeRelatedLines: '+data.activeRelatedLines);
           if((data.activeRelatedLines != null && !data.activeRelatedLines.isEmpty())){
                table = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Active Related Lines</h2>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr>'
                + '<td colspan="8" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Active Related Lines</strong></td>'
                + '</tr>'
                + '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Name</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Client Name</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Customer Id</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Start Date</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>End Date</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Derivatives Amount</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FD Amount</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DVP Amount</strong></td>'
                + '</tr>';
               
                    for (DMT_Line__c lines : data.activeRelatedLines) {
                        table += '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lines?.Name) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lines?.Client__r?.Name) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lines?.Client__r?.g_customer_id__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lines?.Start_Date__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lines?.End_Date__c) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + checkNullAmount(lines?.DMT_DerivativesAmount__c, DMT_FormattingUtils.checkNull(lines?.CurrencyIsoCode)) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + checkNullAmount(lines?.FD_Amount__c, DMT_FormattingUtils.checkNull(lines?.CurrencyIsoCode)) + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + checkNullAmount(lines?.DvP_Amount__c, DMT_FormattingUtils.checkNull(lines?.CurrencyIsoCode)) + '</td>'
                            + '</tr>';
                    }
                    table += '</table></div></br></br>';
            }
            
            return table;
        }catch (Exception e){
            System.debug('Error in DMT_DefaultActiveRelatedLinesRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {

        if (data == null || data.line.Client__c == null) {
            return new Map<String, Object>();
        }
        try {
            List<Object> contentListRelatedLines= new List<Object>();
            Map<String, Object> componentListRelatedLines = new Map<String, Object>();
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 35
            };
            contentListRelatedLines.add(pageBreak);
            contentListRelatedLines.add(DMT_Create_Pdf_Controller.createTitle('Active Related Lines'));

            List<List<String>> headers = new List<List<String>>();
            List<String> listHeaders = new List<String>{'Name', 'Client Name', 'Customer Id','Start Date','End Date','Derivatives Amount','FD Amount','DVP Amount'};
            headers.add(listHeaders);

            Map<String, Object> tableActiveRelatedLinesComponent = new Map<String, Object>();
            List<List<String>> body = new List<List<String>>();

            if((data.activeRelatedLines != null && !data.activeRelatedLines.isEmpty())){
            for (DMT_Line__c lines : data.activeRelatedLines) {
                List<String> row = new List<String>();
                row.add(DMT_FormattingUtils.checkNull(lines?.Name));
                row.add(DMT_FormattingUtils.checkNull(lines?.Client__r?.Name));
                row.add(DMT_FormattingUtils.checkNull(lines?.Client__r?.g_customer_id__c));
                row.add(DMT_FormattingUtils.checkNull(lines?.Start_Date__c));
                row.add(DMT_FormattingUtils.checkNull(lines?.End_Date__c));
                row.add(checkNullAmount(lines?.DMT_DerivativesAmount__c, DMT_FormattingUtils.checkNull(lines?.CurrencyIsoCode)));
                row.add(checkNullAmount(lines?.FD_Amount__c, DMT_FormattingUtils.checkNull(lines?.CurrencyIsoCode)));
                row.add(checkNullAmount(lines?.DvP_Amount__c, DMT_FormattingUtils.checkNull(lines?.CurrencyIsoCode)));
                body.add(row);
            }
            }

            Map<String, Object> stylesTable = new Map<String, Object>();
                stylesTable.put('fontSize', 8);
            Map<String, Object> lineWidthItem = new Map<String, Object>();
                lineWidthItem.put('bottom',0.1);
                stylesTable.put('lineWidth',lineWidthItem);
            Map<String, Object> headStyles= new Map<String, Object>();
                headStyles.put('fontSize', 8);
                tableActiveRelatedLinesComponent.put('headStyles', headStyles);
                tableActiveRelatedLinesComponent.put('style', stylesTable);
                tableActiveRelatedLinesComponent.put('body', body);
                tableActiveRelatedLinesComponent.put('head', headers);
                tableActiveRelatedLinesComponent.put('type', 'table');


            //CREATE TITLE SECTION
            List<Object> titleSection = new List<Object>();
            titleSection = DMT_Create_Pdf_Controller.createTitleSection('Active Related Lines');
            contentListRelatedLines.add(titleSection[0]);
            contentListRelatedLines.add(titleSection[1]);
            contentListRelatedLines.add(tableActiveRelatedLinesComponent);
            componentListRelatedLines.put('content', contentListRelatedLines);
            componentListRelatedLines.put('name', 'Participants');
    
            return componentListRelatedLines;

        } catch (Exception e){
            System.debug('Error in DMT_DefaultActiveRelatedLinesRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_DefaultActiveRelatedLinesRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }

    public static String checkNullAmount(Object value, Object currencyIsoCode) {
        if (value == null || value == 'null') return ''; // If its null return empty string
        return String.valueOf(value) + ' ' +String.valueOf(currencyIsoCode);
    }
}