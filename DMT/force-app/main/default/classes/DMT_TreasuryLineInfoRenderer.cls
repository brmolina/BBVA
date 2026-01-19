public with sharing class DMT_TreasuryLineInfoRenderer implements DMT_ViewRenderer {

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Line data not provided</div>';
        }
        try {
            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">LINE INFO</h2>'
                + '<div class="slds-scope style-table">'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Line Id:</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Line_Id__c) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Name:</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Name) + '</td>'
                + '</tr>'
                + '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Entific:</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Booking_Geography__c) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Start Date:</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.changeDateFormat(data.line.Start_Date__c) + '</td>'
                + '</tr>'
                + '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>End Date:</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.changeDateFormat(data.line.End_Date__c) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Line Term:</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Line_Term__c) + '</td>'
                + '</tr>'
                + '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Currency:</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.CurrencyIsoCode) + '</td>'
                 + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Office:</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.DMT_Oficina__c) + '</td>'
                + '</tr>'
                + '<tr>'
               + '</tr>'
                + '</table>'
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_TreasuryLineInfoRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            List<Object> contentList = new List<Object>();
                Map<String, Object> component = new Map<String, Object>(); 
                //CREATE TITLE
                    contentList.add(DMT_Create_Pdf_Controller.createTitle('LINE INFO'));
                // Crea componente de Line Info
                Map<String, Object> textComponent = new Map<String, Object>();
                List<String> name = new List<String>();
                List<String> value = new List<String>();
                name.add('Line Id:');
                value.add(DMT_FormattingUtils.checkNull(data.line.Line_Id__c));
                name.add('Entific:');
                value.add(DMT_FormattingUtils.checkNull(data.line.Booking_Geography__c));
                name.add('Start Date:');
                value.add(DMT_FormattingUtils.changeDateFormat(data.line.Start_Date__c));
                name.add('Line Term:');
                value.add(DMT_FormattingUtils.checkNull(data.line.Line_Term__c));
                name.add('Name:');
                value.add(data.line.Name);
                name.add('Currency:');
                value.add(data.currencyIsoCode);
                name.add('End Date:');
                value.add(DMT_FormattingUtils.changeDateFormat(data.line?.End_Date__c));
                name.add('Office:');
                value.add(DMT_FormattingUtils.checkNull(data.line.DMT_Oficina__c));
                
                
                //Table than create the text content
                textComponent = DMT_Create_Pdf_Controller.createListText(name, value, '');
                contentList.add(textComponent);
                component.put('content', contentList);
                component.put('name', 'Line Info');
                
                return component;
        } catch (Exception e){
            System.debug('Error in DMT_TreasuryLineInfoRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_TreasuryLineInfoRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}