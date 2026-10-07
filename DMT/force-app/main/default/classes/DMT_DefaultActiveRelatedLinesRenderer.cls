// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
public without sharing class DMT_DefaultActiveRelatedLinesRenderer implements DMT_ViewRenderer{

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
                + '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr data-dmt-table-title="true">'
                + '<td colspan="8" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Active Related Lines</strong></td>'
                + '</tr>'
                + '<tr data-dmt-table-header="true">'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Name</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Client Name</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Customer Id</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Start Date</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>End Date</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Derivatives Amount</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FD Amount</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DVP Amount</strong></td>'
                + '</tr>';

                    for (DMT_Line__c lines : data.activeRelatedLines) {
                        table += '<tr data-dmt-table-row="true">'
                            + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lines?.Name) + '</td>'
                            + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lines?.Client__r?.Name) + '</td>'
                            + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lines?.Client__r?.g_customer_id__c) + '</td>'
                            + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lines?.Start_Date__c) + '</td>'
                            + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lines?.End_Date__c) + '</td>'
                            + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + checkNullAmount(lines?.DMT_DerivativesAmount__c, DMT_FormattingUtils.checkNull(lines?.CurrencyIsoCode)) + '</td>'
                            + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + checkNullAmount(lines?.FD_Amount__c, DMT_FormattingUtils.checkNull(lines?.CurrencyIsoCode)) + '</td>'
                            + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + checkNullAmount(lines?.DvP_Amount__c, DMT_FormattingUtils.checkNull(lines?.CurrencyIsoCode)) + '</td>'
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
    
    public static String checkNullAmount(Object value, Object currencyIsoCode) {
        if (value == null || value == 'null') return ''; // If the value is null, return an empty string
        return String.valueOf(value) + ' ' +String.valueOf(currencyIsoCode);
    }
}