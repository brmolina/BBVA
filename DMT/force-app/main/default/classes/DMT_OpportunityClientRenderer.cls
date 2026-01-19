public with sharing class DMT_OpportunityClientRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {

        if (data == null || data.oppClient.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Client data not provided</div>';
        }

        try{

            String accRecordCode = DMT_Client_Selector.getAccountRecordCode(data.opportunity.AccountId);
            Map<String, Object> mapGroupCode = DMT_HPG_Utils.getGroupFromClientAccount(accRecordCode);
            String groupName = mapGroupCode.get('groupName') != null ? (String)mapGroupCode.get('groupName') : '';
            String accountName = data.opportunity.AccountId != null ? data.opportunity.Account.Name : '';
            String clientGroup = groupName + ' - ' + accountName;

            String html = '<div>'
                    + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">CLIENT</h2>'
                    + '<div class="slds-scope">'
                    + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                    + '<colgroup>'
                    + '<col style="width: 50%;">'
                    + '<col style="width: 50%;">'
                    + '</colgroup>'
                    + DMT_FormattingUtils.tableRow2columns_New('Internal Rating', DMT_FormattingUtils.checkNull(data.oppClient.g_upd_lmscl_internal_ratg_type__c), 'Unified External Rating', DMT_FormattingUtils.checkNull(data.oppClient.External_Rating__c));
                    if(data.oppClient.Counterpart__c == 'Corporates'){
                        html += DMT_FormattingUtils.tableRow2columns_New('Client Type', DMT_FormattingUtils.checkNull(data.oppClient.Counterpart__c), 'Client Sales', '')
                            + DMT_FormattingUtils.tableRow1column_checkbox('Client Sales > 500 Millions (EUR)', data.oppClient.Group_Sales_Check__c);
                    }else{
                        html +=  DMT_FormattingUtils.tableRow2columns_New('Client Type', DMT_FormattingUtils.checkNull(data.oppClient.Counterpart__c), 'SCRA (Simplified Credit Risk Approach)', DMT_FormattingUtils.checkNull(data.oppClient.SCRA__c))
                            + DMT_FormattingUtils.tableRow2columns_checkbox('Asset Value Correlation', data.oppClient.AVC_Check__c, 'European Bank', data.oppClient.European_Bank_Check__c );
                    }
                    html += DMT_FormattingUtils.tableRow2columns_New('Group / Client', DMT_FormattingUtils.checkNull(clientGroup), 'Group Type', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Threshold_Type__c));
                    html += DMT_FormattingUtils.tableRow2columns_New('External Rating', DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating__c), 'Sector', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Sector__c));
                    html += DMT_FormattingUtils.tableRow2columns_New('Subsector', DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating__c), 'Activity', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Sector__c));
                    html += '</table>'
                    + '</div>'
                    + '</div>'
                    + '</br></br>';

            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OpportunityClientRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.oppClient.getPopulatedFieldsAsMap().isEmpty()) {
            return new Map<String, Object>();
        }
        try {

            String accRecordCode = DMT_Client_Selector.getAccountRecordCode(data.opportunity.AccountId);
            Map<String, Object> mapGroupCode = DMT_HPG_Utils.getGroupFromClientAccount(accRecordCode);
            String groupName = mapGroupCode.get('groupName') != null ? (String)mapGroupCode.get('groupName') : '';
            String accountName = data.opportunity.AccountId != null ? data.opportunity.Account.Name : '';
            String clientGroup = groupName + ' - ' + accountName;

            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();
            contentList.add(DMT_Create_Pdf_Controller.createTitle('CLIENT'));
            // Render remaining pairs in two columns
            List<String> pairNameList = new List<String>();
            List<String> pairValueList = new List<String>();
            pairNameList.add('Internal Rating');
            pairValueList.add(DMT_FormattingUtils.checkNull(data.oppClient.g_upd_lmscl_internal_ratg_type__c));
            pairNameList.add('Client Type');
            pairValueList.add(DMT_FormattingUtils.checkNull(data.oppClient.Counterpart__c));
            if(data.oppClient.Counterpart__c == 'Corporates'){
                pairNameList.add('Client Sales > 500 Millions (EUR)');
                pairValueList.add(data.oppClient.Group_Sales_Check__c == true ? 'Yes': 'No');
                pairNameList.add('Unified External Rating');
                pairValueList.add(DMT_FormattingUtils.checkNull(data.oppClient.External_Rating__c));
                pairNameList.add('Client Sales');
                pairValueList.add('');

            }else{
                pairNameList.add('Asset Value Correlation');
                pairValueList.add(data.oppClient.AVC_Check__c == true ? 'Yes': 'No');
                pairNameList.add('Unified External Rating');
                pairValueList.add(DMT_FormattingUtils.checkNull(data.oppClient.External_Rating__c));
                pairNameList.add('SCRA (Simplified Credit Risk Approach)');
                pairValueList.add(DMT_FormattingUtils.checkNull(data.oppClient.SCRA__c));
                pairNameList.add('European Bank');
                pairValueList.add(data.oppClient.European_Bank_Check__c == true ? 'Yes': 'No');
            }
            pairNameList.add('Client / Group');
            pairValueList.add(DMT_FormattingUtils.checkNull(clientGroup));
            pairNameList.add('Group Type');
            pairValueList.add(DMT_FormattingUtils.checkNull(data.opportunity.DMT_Threshold_Type__c));
            pairNameList.add('External Rating');
            pairValueList.add(DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating__c));
            pairNameList.add('Sector');
            pairValueList.add(DMT_FormattingUtils.checkNull(data.oppClient.DMT_Sector__c));
            pairNameList.add('Subsector');
            pairValueList.add(DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating__c));
            pairNameList.add('Activity');
            pairValueList.add(DMT_FormattingUtils.checkNull(data.oppClient.DMT_Sector__c));
            contentList.add(DMT_Create_Pdf_Controller.createListText(pairNameList, pairValueList, ''));

            component.put('content', contentList);
            component.put('name', 'CLIENT');

            return component;
        } catch (Exception e){
            System.debug('Error in DMT_OpportunityClientRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_OpportunityClientRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}