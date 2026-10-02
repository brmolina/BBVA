// This renderer builds HTML via DMT_FormattingUtils.DisplayField/tableRow2columns, matching
// DMT_OtherLineInfoRenderer's pattern - data-dmt-* attributes are added by those shared helpers
// so htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
public with sharing class DMT_TreasuryLineInfoRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer {

    // ADD OR REMOVE A FIELD HERE. Feeds both renderHtml() and getTrackedFields(), so pass the field
    // API name as the third DisplayField argument or the field renders without being watched.
    // See DMT_InfoRenderer for the full rules.
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Line Id:', DMT_FormattingUtils.checkNull(data.line.Line_Id__c), new List<String>{'Line_Id__c'}),
            new DMT_FormattingUtils.DisplayField('Name:', DMT_FormattingUtils.checkNull(data.line.Name), new List<String>{'Name'}),
            new DMT_FormattingUtils.DisplayField('Entific:', DMT_FormattingUtils.checkNull(data.line.Booking_Geography__c), new List<String>{'Booking_Geography__c'}),
            new DMT_FormattingUtils.DisplayField('Start Date:', DMT_FormattingUtils.changeDateFormat(data.line.Start_Date__c), new List<String>{'Start_Date__c'}),
            new DMT_FormattingUtils.DisplayField('End Date:', DMT_FormattingUtils.changeDateFormat(data.line.End_Date__c), new List<String>{'End_Date__c'}),
            new DMT_FormattingUtils.DisplayField('Currency:', DMT_FormattingUtils.checkNull(data.line.CurrencyIsoCode), new List<String>{'CurrencyIsoCode'}),
            new DMT_FormattingUtils.DisplayField('Office:', DMT_FormattingUtils.checkNull(data.line.DMT_Oficina__c), new List<String>{'DMT_Oficina__c'})
        };
    }

    public List<String> getTrackedFields(Id recordTypeId) {
        Set<String> fields = new Set<String>();
        for (DMT_FormattingUtils.DisplayField df : buildRenderFields(new DMT_ViewController.LineDataWrapper())) {
            if (df.fieldApiNames != null) {
                fields.addAll(df.fieldApiNames);
            }
        }
        // Watched but not displayed, carried over from the old flow constant.
        fields.add('DMT_LastLevelId__c');
        fields.add('Line_Term__c');
        return new List<String>(fields);
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Line data not provided</div>';
        }
        try {
            List<DMT_FormattingUtils.DisplayField> renderFields = buildRenderFields(data);
            String rows = '';
            Integer i = 0;
            while (i < renderFields.size()) {
                DMT_FormattingUtils.DisplayField current = renderFields[i];
                if (i + 1 < renderFields.size()) {
                    DMT_FormattingUtils.DisplayField next = renderFields[i + 1];
                    rows += DMT_FormattingUtils.tableRow2columns(current.label, current.value, next.label, next.value);
                    i += 2;
                } else {
                    rows += DMT_FormattingUtils.tableRow1columnPairStyle(current.label, current.value);
                    i += 1;
                }
            }
            return '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">LINE INFO</h2>'
                + '<div class="slds-scope style-table">'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + rows
                + '</table>'
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';
        } catch (Exception e){
            System.debug('Error in DMT_TreasuryLineInfoRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}