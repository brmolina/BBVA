public with sharing class DMT_OtherLineInfoRenderer implements DMT_ViewRenderer {

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Line data not provided</div>';
        }
        try {
            String commitmentLabel = data.line.g_line_commitment_level_type__c == 'COM'
                ? 'COMMITTED'
                : data.line.g_line_commitment_level_type__c == 'UNC'
                    ? 'UNCOMMITTED'
                    : data.line.g_line_commitment_level_type__c == 'PNG'
                        ? 'PENDING FORMALIZATION'
                        : data.line.g_line_commitment_level_type__c;

            return '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">LINE INFO</h2>'
                + '<div class="slds-scope">'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + DMT_FormattingUtils.tableRow2columns('Line Id:', DMT_FormattingUtils.checkNull(data.line.Line_Id__c), 'Name:', DMT_FormattingUtils.checkNull(data.line.Name))
                + DMT_FormattingUtils.tableRow2columns('Entific:', DMT_FormattingUtils.checkNull(data.line.Booking_Geography__c), 'Start Date:', DMT_FormattingUtils.changeDateFormat(data.line.Start_Date__c))
                + DMT_FormattingUtils.tableRow2columns('End Date:', DMT_FormattingUtils.changeDateFormat(data.line.End_Date__c), 'Amount:', DMT_FormattingUtils.formatCurrencyAmount(data.line.Amount__c, data.currencyIsoCode))
                + DMT_FormattingUtils.tableRow2columns('Currency:', DMT_FormattingUtils.checkNull(data.line.CurrencyIsoCode), 'Type of Risk:', DMT_FormattingUtils.checkNull(data.line.g_limit_last_level_type__c))
                + DMT_FormattingUtils.tableRow2columns('Office:', DMT_FormattingUtils.checkNull(data.line.DMT_Oficina__c), 'Line Commitment Type:', DMT_FormattingUtils.checkNull(commitmentLabel))
                + DMT_FormattingUtils.tableRow1column_checkbox('Individual Disposal Approval:', data.line.DMT_Individual_Disposal_Approval__c)
                + '</table>'
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';
        } catch (Exception e){
            System.debug('Error in DMT_OtherLineInfoRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}