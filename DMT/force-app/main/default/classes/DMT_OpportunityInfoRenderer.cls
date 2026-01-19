public with sharing class DMT_OpportunityInfoRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Opportunity data not provided</div>';
        }
        try {

            Boolean underXSell = !data.opportunity.X_sell__r.isEmpty();

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">OPPORTUNITY INFO</h2>'
                + '<div class="slds-scope">'
                + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
                + '<colgroup>'
                + '<col style="width: 50%;">'
                + '<col style="width: 50%;">'
                + '</colgroup>'
                + DMT_FormattingUtils.tableRow2columns_New('Opportunity Id', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Opp_Id__c), 'Name', DMT_FormattingUtils.checkNull(data.opportunity.Name))
                + DMT_FormattingUtils.tableRow2columns_New('Entific', DMT_FormattingUtils.checkNull(data.oppEntific), 'Entity', DMT_FormattingUtils.checkNull(data.oppEntity))
                + DMT_FormattingUtils.tableRow2columns_New('Opportunity Initial Date', DMT_FormattingUtils.changeDateFormat(data.opportunity.DMT_DATE_Initial_Date__c), 'Opportunity End Date', DMT_FormattingUtils.changeDateFormat(data.opportunity.DMT_DATE_Maturity_Date__c))
                + DMT_FormattingUtils.tableRow2columns_New('Tenor', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Tenor__c), 'Notional Amount', DMT_FormattingUtils.formatCurrencyAmount(data.opportunity.DMT_CUR_Notional_Amount__c, data.opportunity.CurrencyIsoCode))
                + DMT_FormattingUtils.tableRow2columns_New('Currency', DMT_FormattingUtils.checkNull(data.currencyIsoCode), 'Capital Action', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Capital_Action__c))
                + DMT_FormattingUtils.tableRow2columns_New('Under Cross-Sell', DMT_FormattingUtils.booleanToYesNo(underXSell), '', '')
                + '</table>'
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';
                    html += '<div>'
                    + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<colgroup>'
                    + '<col style="width: 50%;">'
                    + '<col style="width: 50%;">'
                    + '</colgroup>'
                        + '<tr>'
                        + '<td colspan="2" style="padding: 8px; text-align: center; border-bottom: 1px solid; #ccc; background-color: rgb(174, 174, 174); font-size: 17px;"><strong>Cross SELL</strong></td>'
                        + '</tr>'
                        + '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; border-right: 1px solid #ccc; background-color: #F3F3F3;"><strong>YEAR</strong></td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>NOTIONAL AMOUNT</strong></td>'
                        + '</tr>';
            if (!data.xSellOpp.isEmpty()) {
                    for (DMT_X_Sell__c xSellOpp : data.xSellOpp) {
                        html += '<tr>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + xSellOpp.Year__c + '</td>'
                            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(xSellOpp.g_notional_amount__c, data.currencyIsoCode) + '</td>'
                            + '</tr>';
                    }
            }
            html += '</table></div>&nbsp;</br>&nbsp;</br>';
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OpportunityInfoRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return new Map<String, Object>();
        }
        try {

            Boolean underXSell = !data.opportunity.X_sell__r.isEmpty();

            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();

            contentList.add(DMT_Create_Pdf_Controller.createTitle('OPPORTUNITY INFO'));

            // Render "Name" as full-width (one column)
            /*List<String> nameNameList = new List<String>{'Name'};
            List<String> nameValueList = new List<String>{DMT_FormattingUtils.checkNull(data.opportunity.Name)};
            contentList.add(DMT_Create_Pdf_Controller.createListText(nameNameList, nameValueList, 'ONE'));*/

            // Render remaining pairs in two columns
            List<String> pairNameList = new List<String>{'Opportunity Id','Entific', 'Opportunity Initial Date', 'Tenor', 'Currency', 'Entity', 'Name','Opportunity End Date', 'Notional Amount', 'Capital Action', 'Under Cross-Sell'};
            List<String> pairValueList = new List<String>{
                DMT_FormattingUtils.checkNull(data.opportunity.DMT_Opp_Id__c),
                DMT_FormattingUtils.checkNull(data.opportunity.Entific__c),
                DMT_FormattingUtils.changeDateFormat(data.opportunity.DMT_DATE_Initial_Date__c),
                DMT_FormattingUtils.checkNull(data.opportunity.DMT_Tenor__c),
                DMT_FormattingUtils.checkNull(data.opportunity.CurrencyIsoCode),
                DMT_FormattingUtils.checkNull(data.opportunity.DMT_Entity__c),
                DMT_FormattingUtils.checkNull(data.opportunity.Name),
                DMT_FormattingUtils.changeDateFormat(data.opportunity.DMT_DATE_Maturity_Date__c),
                DMT_FormattingUtils.formatCurrencyAmount(data.opportunity.DMT_CUR_Notional_Amount__c, data.opportunity.CurrencyIsoCode),
                DMT_FormattingUtils.checkNull(data.opportunity.DMT_Capital_Action__c),
                DMT_FormattingUtils.booleanToYesNo(underXSell)
            };
            contentList.add(DMT_Create_Pdf_Controller.createListText(pairNameList, pairValueList, ''));

            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 30
            };
            contentList.add(pageBreak);

            List<Object> titleSection = DMT_Create_Pdf_Controller.createTitleSection('Cross SELL');
            contentList.add(titleSection[0]);
            contentList.add(titleSection[1]);

            // Cross Sell Table
            List<List<String>> crossHead = new List<List<String>>{new List<String>{'YEAR', 'NOTIONAL AMOUNT'}};
            List<List<String>> crossBody = new List<List<String>>();
            if (!data.xSellOpp.isEmpty()) {
                for (DMT_X_Sell__c xSellOpp : data.xSellOpp) {
                    crossBody.add(new List<String>{
                        DMT_FormattingUtils.checkNull(xSellOpp.Year__c),
                        DMT_FormattingUtils.formatCurrencyAmount(xSellOpp.g_notional_amount__c, data.currencyIsoCode)
                    });
                }
            } else {
                crossBody.add(new List<String>{
                    '',
                    ''
                });
            }
            Map<String, Object> crossSellTable = DMT_Create_Pdf_Controller.createTable(crossHead, crossBody);
             // *** COLUMN WIDTHS UPDATE FOR 50%-50% (A4, 15mm margin each side, so 180mm usable; 90mm per column) ***
            Map<String, Object> columnStyles = new Map<String, Object>{
                '0' => new Map<String, Object>{ 'cellWidth' => 90 },
                '1' => new Map<String, Object>{ 'cellWidth' => 90 }
            };
            crossSellTable.put('columnStyles', columnStyles);
            contentList.add(crossSellTable);

            component.put('content', contentList);
            component.put('name', 'Opportunity Info');
            return component;
        } catch (Exception e) {
            System.debug('Error in DMT_OpportunityInfoRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OpportunityInfoRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }
}