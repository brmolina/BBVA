// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
public without sharing class DMT_DefaultStatusOnlyRenderer implements DMT_ViewRenderer {

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            return '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">STATUS</h2>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr data-dmt-row="field">'
                + '<td data-dmt-pair="1" data-dmt-label="Status:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Status:</strong></td>'
                + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.statusLineOrOpp) + '</td>'
                + '</tr>'
                + '</table>'
                + '</div>'
                + '&nbsp;</br>';
        } catch (Exception e) {
            System.debug('Error in DMT_DefaultStatusOnlyRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }
}