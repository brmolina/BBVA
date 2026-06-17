public with sharing class DMT_OpportunityInfoRenderer implements DMT_ViewRenderer {

    // 1. HELPER: Build the list dynamically using the 'data' wrapper
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            // Row 1
            new DMT_FormattingUtils.DisplayField('Name', DMT_FormattingUtils.checkNull(data.opportunity.Name)),
            new DMT_FormattingUtils.DisplayField('Opportunity Id', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Opp_Id__c)),

            // Row 2 (Standardized to use the wrapper properties from your HTML method)
            new DMT_FormattingUtils.DisplayField('Entific', DMT_FormattingUtils.checkNull(data.opportunity.Entific__c + '-' + data.oppEntific)),
            new DMT_FormattingUtils.DisplayField('Entity', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Entity__c + '-' + data.oppEntity)),

            // Row 3
            new DMT_FormattingUtils.DisplayField('Booking Geography', DMT_FormattingUtils.checkNull(data.oppBookingGeography)),// TODO JAFE ADD VALUE TO THIS FIELD
            new DMT_FormattingUtils.DisplayField('Opportunity Tenor', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Tenor__c)),

            // Row 4 (Standardized currency reference)
            new DMT_FormattingUtils.DisplayField('Opportunity BBVA commitment amount', DMT_FormattingUtils.formatCurrencyAmount(data.opportunity.DMT_CUR_Notional_Amount__c == null ? 0.00 : data.opportunity.DMT_CUR_Notional_Amount__c, data.opportunity.DMT_CurrencyText__c)),
            new DMT_FormattingUtils.DisplayField('Currency', DMT_FormattingUtils.checkNull(data.opportunity.DMT_CurrencyText__c)),

            // Row 5
            new DMT_FormattingUtils.DisplayField('Capital Action', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Capital_Action__c)),
            new DMT_FormattingUtils.DisplayField('Product Area',  DMT_FormattingUtils.checkNull(data.opportunity.DMT_Product_Area__c)), // TODO KV ADD VALUE TO THIS FIELD

            // Row 6
            new DMT_FormattingUtils.DisplayField('Opportunity Deal Amount',  DMT_FormattingUtils.formatCurrencyAmount(data.opportunity.DMT_Opportunity_amount__c == null ? 0.00 : data.opportunity.DMT_Opportunity_amount__c, data.opportunity.DMT_CurrencyText__c)),
            data.opportunity.DMT_Product_Area__c == 'IB&F' ?
                new DMT_FormattingUtils.DisplayField('Contingent Commitments',  DMT_FormattingUtils.checkNull(data.opportunity.DMT_ContingentCommitments__c)) 
                : new DMT_FormattingUtils.DisplayField('', '') // Dynamic empty space to balance the 2-column grid // TODO KV ADD VALUE TO THIS FIELD
        };
    }

    // ==========================================
    // RENDER METHODS
    // ==========================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            Boolean underXSell = !data.opportunity.X_sell__r.isEmpty();

            // 1. Build the Top Section (Opportunity Info) using the shared helper
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Opportunity Info</h2>'
                + '<div class="slds-scope">'
                + DMT_FormattingUtils.generateHtmlTable(fieldsToRender) // Replaces hardcoded tableRow2columns_New
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';

            // 2. Build the Bottom Section (Cross Sell Table)
            /*html += '<div>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<colgroup>'
                + '<col style="width: 50%;">'
                + '<col style="width: 50%;">'
                + '</colgroup>'
                + '<tr>'
                + '<td colspan="2" style="padding: 8px; text-align: center; border-bottom: 1px solid; #ccc; background-color: rgb(174, 174, 174); font-size: 17px;"><strong>Cross SELL</strong></td>'
                + '</tr>'
                + '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; border-right: 1px solid #ccc; background-color: #F3F3F3;"><strong>Year</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Deal Amount</strong></td>'
                + '</tr>';

            if (!data.xSellOpp.isEmpty()) {// TODO KV this is rendering even when empty xsell?
                for (DMT_X_Sell__c xSellOpp : data.xSellOpp) {
                    html += '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(xSellOpp.Year__c) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(xSellOpp.g_notional_amount__c, data.currencyIsoCode) + '</td>'
                        + '</tr>';
                }
            }
            html += '</table></div>&nbsp;</br>&nbsp;</br>';*/

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

            // 1. Build the Top Section (Opportunity Info)
            contentList.add(DMT_Create_Pdf_Controller.createTitle('Opportunity Info'));

            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);
            contentList.add(DMT_Create_Pdf_Controller.generatePdfList(fieldsToRender)); // Shared utility replaces createListText

            // Page Break
            Map<String, Object> pageBreak = new Map<String, Object>{
                'type' => 'pageBreak',
                'threshold' => 30
            };
            contentList.add(pageBreak);

            // 2. Build the Bottom Section (Cross Sell)
/*            List<Object> titleSection = DMT_Create_Pdf_Controller.createTitleSection('Cross SELL');
            contentList.add(titleSection[0]);
            contentList.add(titleSection[1]);

            List<List<String>> crossHead = new List<List<String>>{new List<String>{'Year', 'Deal Amount'}};
            List<List<String>> crossBody = new List<List<String>>();

            if (!data.xSellOpp.isEmpty()) {
                for (DMT_X_Sell__c xSellOpp : data.xSellOpp) {
                    crossBody.add(new List<String>{
                        DMT_FormattingUtils.checkNull(xSellOpp.Year__c),
                        DMT_FormattingUtils.formatCurrencyAmount(xSellOpp.g_notional_amount__c, data.currencyIsoCode)
                    });
                }
            } else {
                // Add an empty row if no records exist
                crossBody.add(new List<String>{'', ''});
            }

             Map<String, Object> crossSellTable = DMT_Create_Pdf_Controller.createTable(crossHead, crossBody);

            Map<String, Object> columnStyles = new Map<String, Object>{
                '0' => new Map<String, Object>{ 'cellWidth' => 90 },
                '1' => new Map<String, Object>{ 'cellWidth' => 90 }
            };
            crossSellTable.put('columnStyles', columnStyles);
            contentList.add(crossSellTable); */

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