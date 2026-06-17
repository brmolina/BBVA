public with sharing class DMT_OtherClientRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if(data.line.getPopulatedFieldsAsMap().isEmpty() || data.line.Client__c == null){
            return '<div>Client data not provided</div>';
        }
        try {
            String table = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">CLIENT</h2>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Client:</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Client__r.Name) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Client Type:</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Client_Type__c) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Internal Rating (Short):</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.ratingMonoHolder) + '</td>'
                + '</tr>'
                + '</table>'
                + '</div>'
                + '&nbsp;</br>';

            String table2 = '';
            if (!data.customAssociationClientList.isEmpty()) {
                table2 = '<div>'
                    + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                    + '<td colspan="6" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>SELECTED CLIENT</strong></td>'
                    + '</tr>'
                    + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>CLIENT NAME</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>MAIN HOLDER</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>STAR CODE</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>CUSTOMER ID</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>CLIENT CONTRACTS</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>INTERNAL RATING (SHORT)</strong></td>'
                    + '</tr>';
                for (Custom_Association_Client__c client : data.customAssociationClientList) {
                    String isMainHolder = (client.Alpha_Code_Client__c == data.mainHolderCustomerId) ? 'Yes' : 'No';
                    table2 += '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.Name) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + isMainHolder + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.DMT_ClientStarCode__c) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.Alpha_Code_Client__c) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.DMT_ClientContracts__c) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(client.DMT_ClientRating__c) + '</td>'
                        + '</tr>';
                }
                table2 += '</table></div>&nbsp;</br>';
            }
            return table + table2;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultClientRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {

        if(data.line.getPopulatedFieldsAsMap().isEmpty() || data.line.Client__c == null){
            return new Map<String, Object>();
        }
        try {
            List<Object> contentListTable = new List<Object>();
            Map<String, Object> componentTable = new Map<String, Object>();
                // CREATE TITLE
                contentListTable.add(DMT_Create_Pdf_Controller.createTitle('CLIENT'));
                //Text Conten Client
                Map<String, Object> textClient = new Map<String, Object>();
                List<String> name = new List<String>{'Client:','Client Type:'};
                List<String> value = new List<String>{DMT_FormattingUtils.checkNull(data.line.Client__r.Name),DMT_FormattingUtils.checkNull(data.line.Client_Type__c)};
                if(data.isSubsidiary){
                    name.add('Internal Rating (Short):');
                    value.add(DMT_FormattingUtils.checkNull(data.ratingMonoHolder));
                }
                    textClient = DMT_Create_Pdf_Controller.createListText(name, value, '');
                    contentListTable.add(textClient);
              
                    if(!data.customAssociationClientList.isEmpty()){
                List<List<String>> headers = new List<List<String>>();
                Map<String, Object> tableComponent = new Map<String, Object>();
                List<List<String>> body = new List<List<String>>();
                    // Table Content Client
                    List<String> listHeaders = new List<String>{'CLIENT NAME', 'MAIN HOLDER', 'STAR CODE', 'CUSTOMER ID', 'CLIENT CONTRACTS','INTERNAL RATING (SHORT)'};
                    headers.add(listHeaders);
                for (Custom_Association_Client__c customAssociationClient : data.customAssociationClientList) {
                    String isMainHolder = (customAssociationClient.Alpha_Code_Client__c == data.mainHolderCustomerId) ? 'Yes' : 'No';
                        List<String> row = new List<String>();
                        row.add(DMT_FormattingUtils.checkNull(customAssociationClient.Name));
                        row.add(isMainHolder);
                        row.add(DMT_FormattingUtils.checkNull(customAssociationClient.DMT_ClientStarCode__c));
                        row.add(DMT_FormattingUtils.checkNull(customAssociationClient.Alpha_Code_Client__c));
                        row.add(DMT_FormattingUtils.checkNull(customAssociationClient.DMT_ClientContracts__c));
                         row.add(DMT_FormattingUtils.checkNull(customAssociationClient.DMT_ClientRating__c));
                        body.add(row);
            }
                Map<String, Object> stylesTable = new Map<String, Object>();
                    stylesTable.put('fontSize', 8);
                Map<String, Object> lineWidthItem = new Map<String, Object>();
                    lineWidthItem.put('bottom',0.1);
                    stylesTable.put('lineWidth',lineWidthItem);
                Map<String, Object> headStyles= new Map<String, Object>();
                    headStyles.put('fontSize', 8);
                Map<String, Object> tableMargin= new Map<String, Object>();
                    tableMargin.put('bottom', 5);
                    tableMargin.put('top', 0.1);

                    tableComponent.put('margin', tableMargin);
                    tableComponent.put('headStyles', headStyles);
                    tableComponent.put('style', stylesTable);
                    tableComponent.put('body', body);
                    tableComponent.put('head', headers);
                    tableComponent.put('type', 'table');
                List<Object> titleSection = new List<Object>();
                titleSection = DMT_Create_Pdf_Controller.createTitleSection('SELECTED CLIENT');
                contentListTable.add(titleSection[0]);
                contentListTable.add(titleSection[1]);
                contentListTable.add(tableComponent);
                }
                componentTable.put('content', contentListTable);
                componentTable.put('name', 'CLIENT');

            return componentTable;
        } catch (Exception e){
            System.debug('Error in DMT_DefaultClientRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_DefaultClientRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}