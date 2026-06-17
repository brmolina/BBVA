public with sharing class DMT_OtherApprovalProcessDataRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Line data not provided</div>';
        }
        try {
            DMT_Line__c line = data.line;
            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Approval Process Data</h2>'
                + '<table class="style-table" style="width:100%; border-collapse: separate; border-spacing: 10px 0; table-layout: fixed; margin-left: -10px; margin-right: -10px;">'
                + '<colgroup>'
                + '<col style="width: 50%;">'
                + '<col style="width: 50%;">'
                + '</colgroup>'
                + '<tr>'
                    /*+ '<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Transaction:</strong></div>'
                    + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + DMT_FormattingUtils.checkNull(line.DMT_Operation__c) + '</div>'
                    + '</td>'*/
                    + '<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Global Banker:</strong></div>'
                    + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + DMT_FormattingUtils.checkNull(line.DMT_GlobalBanker__c) + '</div>'
                    + '</td>'
                //+ '</tr>'
                //+ '<tr>'
                    /*+ '<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Notional:</strong></div>'
                    + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + DMT_FormattingUtils.checkNull(line.DMT_Nominal__c) + '</div>'
                    + '</td>'*/
                    + '<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Financial Program Risk Approver (Global):</strong></div>'
                    + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + DMT_FormattingUtils.checkNull(line.DMT_Approver__r?.Name) + '</div>'
                    + '</td>'
                + '</tr>'
                + '<tr>'
                    /*+ '<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Franchise L12M:</strong></div>'
                    + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + DMT_FormattingUtils.checkNull(line.DMT_Franchise_L12M__c) + '</div>'
                    + '</td>'*/
                    + '<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Approver Global Banker:</strong></div>'
                    + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + DMT_FormattingUtils.checkNull(line.DMT_ApproverGlobalBanker__r?.Name) + '</div>'
                    + '</td>'
                /*+ '</tr>'
                + '<tr>'
                    + '<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Global Markets RORC:</strong></div>'
                    + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + DMT_FormattingUtils.checkNull(line.DMT_RAROEC_RORC_Proposal__c) + '</div>'
                    + '</td>'*/
                    + '<td style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Booking Unit Risk Approver (Local):</strong></div>'
                    + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + DMT_FormattingUtils.checkNull(line.DMT_Booking_Unit_Risk_Analyst__r?.Name) + '</div>'
                    + '</td>'
                + '</tr>'
                + '</table>'
                + '<div style="height: 20px;"></div>'
                + '<div style="padding-bottom: 8px; padding-top: 8px;">'
                + '<div><strong>Comments:</strong></div>'
                + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + DMT_FormattingUtils.checkNull(line.DMT_Comments__c) + '</div>'
                + '</div>'
                + '<div style="padding-bottom: 8px; padding-top: 8px;">'
                + '<div><strong>Additional Restrictions:</strong></div>'
                + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + DMT_FormattingUtils.checkNull(line.DMT_Additional_Restrictions__c) + '</div>'
                + '</div>'
                + '</div>'
                + ' </br>';
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OtherApprovalProcessDataRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return new Map<String, Object>();
        }
        try {
            List<Object> contentProcessData= new List<Object>();
            Map<String, Object> componentProcessData = new Map<String, Object>();
            // Add a page break before
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 20
            };
            
            contentProcessData.add(pageBreak);
    
            //TITLE PROECESS DARA
            contentProcessData.add(DMT_Create_Pdf_Controller.createTitle('Approval Process Data'));
            //TEXT APPROVAL PROCESS DATA
            Map<String, Object> textProcessData = new Map<String, Object>();
            List<String> name = new List<String>();
            List<String> value = new List<String>();   
                /*name.add('Transaction:');
                value.add(DMT_FormattingUtils.checkNull(data.line.DMT_Operation__c));
                name.add('Notional:');
                value.add(DMT_FormattingUtils.checkNull(data.line.DMT_Nominal__c));
                name.add('Franchise L12M:');
                value.add(DMT_FormattingUtils.checkNull(data.line.DMT_Franchise_L12M__c));*/
                name.add('Global Banker:');
                value.add(DMT_FormattingUtils.checkNull(data.line.DMT_GlobalBanker__c)); 
                name.add('Financial Program Risk Approver (Global):');
                value.add(DMT_FormattingUtils.checkNull(data.line.DMT_Approver__r.Name)); 
                /*name.add('Global Markets RORC:');
                value.add(DMT_FormattingUtils.checkNull(data.line.DMT_RAROEC_RORC_Proposal__c)); */
                name.add('Approver Global Banker:');
                value.add(DMT_FormattingUtils.checkNull(data.line.DMT_ApproverGlobalBanker__r.Name)); 
                name.add('Booking Unit Risk Approver (Local):');
                value.add(DMT_FormattingUtils.checkNull(data.line.DMT_Booking_Unit_Risk_Analyst__r.Name)); 
           contentProcessData.add(DMT_Create_Pdf_Controller.createListText(name, value, ''));
    
            // Long text area fields (one column, spanning both columns)
            List<String> nameLong = new List<String>();
            List<String> valueLong = new List<String>();
            nameLong.add('Comments:');
            valueLong.add(DMT_FormattingUtils.checkNull(data.line.DMT_Comments__c));
            nameLong.add('Additional Restrictions:');
            valueLong.add(DMT_FormattingUtils.checkNull(data.line.DMT_Additional_Restrictions__c));
            contentProcessData.add(DMT_Create_Pdf_Controller.createListText(nameLong, valueLong, 'ONE'));
            componentProcessData.put('content', contentProcessData);
            componentProcessData.put('name', 'APPROVAL PROCESS DATA');
    
            return componentProcessData;
        } catch (Exception e){
            System.debug('Error in DMT_OtherApprovalProcessDataRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_OtherApprovalProcessDataRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}