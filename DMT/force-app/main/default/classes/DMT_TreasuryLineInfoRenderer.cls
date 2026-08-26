// NOTE: This renderer builds HTML directly (not via DMT_FormattingUtils helpers) because
// the field layout is tailored for this view type. data-dmt-* attributes are added manually
// so htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
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
                + '<tr data-dmt-row="field">'
                + '<td data-dmt-pair="1" data-dmt-label="Line Id:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Line Id:</strong></td>'
                + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Line_Id__c) + '</td>'
                + '<td data-dmt-pair="2" data-dmt-label="Name:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Name:</strong></td>'
                + '<td data-dmt-pair="2" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Name) + '</td>'
                + '</tr>'
                + '<tr data-dmt-row="field">'
                + '<td data-dmt-pair="1" data-dmt-label="Entific:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Entific:</strong></td>'
                + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Booking_Geography__c) + '</td>'
                + '<td data-dmt-pair="2" data-dmt-label="Start Date:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Start Date:</strong></td>'
                + '<td data-dmt-pair="2" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.changeDateFormat(data.line.Start_Date__c) + '</td>'
                + '</tr>'
                + '<tr data-dmt-row="field">'
                + '<td data-dmt-pair="1" data-dmt-label="End Date:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>End Date:</strong></td>'
                + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.changeDateFormat(data.line.End_Date__c) + '</td>'
                + '<td data-dmt-pair="2" data-dmt-label="Currency:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Currency:</strong></td>'
                + '<td data-dmt-pair="2" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.CurrencyIsoCode) + '</td>'
                + '</tr>'
                + '<tr data-dmt-row="field">'
                + '<td data-dmt-pair="1" data-dmt-label="Office:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Office:</strong></td>'
                + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.DMT_Oficina__c) + '</td>'
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
}