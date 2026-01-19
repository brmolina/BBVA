public with sharing class DMT_OtherLineInfoRenderer implements DMT_ViewRenderer {

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Line data not provided</div>';
        }
        try {
            String commitmentLabel = data.line.g_line_commitment_level_type__c == 'COM' ? 'COMMITTED' : data.line.g_line_commitment_level_type__c == 'UNC' ? 'UNCOMMITTED' : data.line.g_line_commitment_level_type__c == 'PNG' ? 'PENDING FORMALIZATION' : data.line.g_line_commitment_level_type__c;
            return '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">LINE INFO</h2>'
                + '<div class="slds-scope">'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + DMT_FormattingUtils.tableRow2columns('Line Id:', DMT_FormattingUtils.checkNull(data.line.Line_Id__c),'Name:', DMT_FormattingUtils.checkNull(data.line.Name))
                + DMT_FormattingUtils.tableRow2columns('Entific', DMT_FormattingUtils.checkNull(data.line.Booking_Geography__c), 'Start Date:', DMT_FormattingUtils.changeDateFormat(data.line.Start_Date__c))
                + DMT_FormattingUtils.tableRow2columns('End Date:',  DMT_FormattingUtils.changeDateFormat(data.line.End_Date__c), 'Line Term:',  DMT_FormattingUtils.checkNull(data.line.Line_Term__c))
                + DMT_FormattingUtils.tableRow2columns('Amount:', DMT_FormattingUtils.formatCurrencyAmount(data.line.Amount__c, data.currencyIsoCode), 'Type of Risk:', DMT_FormattingUtils.checkNull(data.line.g_limit_last_level_type__c))
                + DMT_FormattingUtils.tableRow2columns('Currency:', DMT_FormattingUtils.checkNull(data.line.CurrencyIsoCode),'Office: ',DMT_FormattingUtils.checkNull(data.line.DMT_Oficina__c))
                /* + DMT_FormattingUtils.tableRow2columns('Line Commitment Type:', DMT_FormattingUtils.checkNull(commitmentLabel)) */
                + '</table>'
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';
        } catch (Exception e){
            System.debug('Error in DMT_OtherLineInfoRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            String commitmentLabel = data.line.g_line_commitment_level_type__c == 'COM' ? 'COMMITTED' : data.line.g_line_commitment_level_type__c == 'UNC' ? 'UNCOMMITTED' : data.line.g_line_commitment_level_type__c == 'PNG' ? 'PENDING FORMALIZATION' : data.line.g_line_commitment_level_type__c;
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>(); 
            //CREATE TITLE
                contentList.add(DMT_Create_Pdf_Controller.createTitle('LINE INFO'));
            // Crea componente de Line Info
            Map<String, Object> textComponent = new Map<String, Object>();
            List<String> name = new List<String>();
            List<String> value = new List<String>();
            name.add('Line Id:');
            value.add(data.line.Line_Id__c);
            name.add('Entific:');
            value.add(DMT_FormattingUtils.checkNull(data.line.Booking_Geography__c));
            name.add('Start Date:');
            value.add(DMT_FormattingUtils.changeDateFormat(data.line.Start_Date__c));
            name.add('Line Term:');
            value.add(DMT_FormattingUtils.checkNull(data.line.Line_Term__c));
            name.add('Type of Risk:'); // Last Level Id
            value.add(DMT_FormattingUtils.checkNull(data.line.g_limit_last_level_type__c));
            name.add('Name:');
            value.add(data.line.Name);
            name.add('Amount:');
            value.add(DMT_FormattingUtils.formatCurrencyAmount(data.line.Amount__c, data.currencyIsoCode));
            name.add('End Date:');
            value.add(DMT_FormattingUtils.changeDateFormat(data.line?.End_Date__c));
            name.add('Currency:');
            value.add(data.currencyIsoCode);
            name.add('Office:');
            value.add(data.line.DMT_Oficina__c);
            /*name.add('Line Commitment Type:');
            value.add(DMT_FormattingUtils.checkNull(commitmentLabel)); */

            //Table than create the text content
            textComponent = DMT_Create_Pdf_Controller.createListText(name, value, '');
            contentList.add(textComponent);
            component.put('content', contentList);
            component.put('name', 'Line Info');
            
            return component;
        } catch (Exception e){
            System.debug('Error in DMT_OtherLineInfoRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_OtherLineInfoRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}