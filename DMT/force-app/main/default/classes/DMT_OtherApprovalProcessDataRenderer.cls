// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
public without sharing class DMT_OtherApprovalProcessDataRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer {

    // ADD OR REMOVE A FIELD HERE. Feeds both renderHtml() and getTrackedFields(), so pass the field
    // API name as the third DisplayField argument or the field renders without being watched.
    // See DMT_InfoRenderer for the full rules. Comments/Additional Restrictions here, Client Use on
    // DMT_TreasuryApprovalProcessDataRenderer instead - each record type tracks only what its own
    // dmt_approval_process_data.js commentsColumns actually shows it.
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Global Banker:', DMT_FormattingUtils.checkNull(data.line.DMT_GlobalBanker__c), new List<String>{'DMT_GlobalBanker__c'}),
            new DMT_FormattingUtils.DisplayField('Financial Program Risk Approver (Global):', DMT_FormattingUtils.checkNull(data.line.DMT_Approver__r?.Name), new List<String>{'DMT_Approver__r.Name'}),
            new DMT_FormattingUtils.DisplayField('Approver Global Banker:', DMT_FormattingUtils.checkNull(data.line.DMT_ApproverGlobalBanker__r?.Name), new List<String>{'DMT_ApproverGlobalBanker__r.Name'}),
            new DMT_FormattingUtils.DisplayField('Booking Unit Risk Approver (Local):', DMT_FormattingUtils.checkNull(data.line.DMT_Booking_Unit_Risk_Analyst__r?.Name), new List<String>{'DMT_Booking_Unit_Risk_Analyst__r.Name'}),
            new DMT_FormattingUtils.DisplayField('Comments:', DMT_FormattingUtils.checkNull(data.line.DMT_Comments__c), new List<String>{'DMT_Comments__c'}),
            new DMT_FormattingUtils.DisplayField('Additional Restrictions:', DMT_FormattingUtils.checkNull(data.line.DMT_Additional_Restrictions__c), new List<String>{'DMT_Additional_Restrictions__c'})
        };
    }

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        Set<String> fields = new Set<String>();
        for (DMT_FormattingUtils.DisplayField df : buildRenderFields(new DMT_ViewController.LineDataWrapper())) {
            if (df.fieldApiNames != null) {
                fields.addAll(df.fieldApiNames);
            }
        }
        return new List<String>(fields);
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Line data not provided</div>';
        }
        try {
            List<DMT_FormattingUtils.DisplayField> f = buildRenderFields(data);
            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Approval Process Data</h2>'
                + '<table class="style-table" style="width:100%; border-collapse: separate; border-spacing: 10px 0; table-layout: fixed; margin-left: -10px; margin-right: -10px;">'
                + '<colgroup>'
                + '<col style="width: 50%;">'
                + '<col style="width: 50%;">'
                + '</colgroup>'
                + '<tr data-dmt-row="field">'
                    + '<td data-dmt-pair="1" data-dmt-label="Global Banker:" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Global Banker:</strong></div>'
                    + '<div data-dmt-value="true" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + f[0].value + '</div>'
                    + '</td>'
                    + '<td data-dmt-pair="2" data-dmt-label="Financial Program Risk Approver (Global):" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Financial Program Risk Approver (Global):</strong></div>'
                    + '<div data-dmt-value="true" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + f[1].value + '</div>'
                    + '</td>'
                + '</tr>'
                + '<tr data-dmt-row="field">'
                    + '<td data-dmt-pair="1" data-dmt-label="Approver Global Banker:" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Approver Global Banker:</strong></div>'
                    + '<div data-dmt-value="true" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + f[2].value + '</div>'
                    + '</td>'
                    + '<td data-dmt-pair="2" data-dmt-label="Booking Unit Risk Approver (Local):" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Booking Unit Risk Approver (Local):</strong></div>'
                    + '<div data-dmt-value="true" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + f[3].value + '</div>'
                    + '</td>'
                + '</tr>'
                + '</table>'
                + '<div style="height: 20px;"></div>'
                + '<div data-dmt-row="field" data-dmt-pair="1" data-dmt-label="Comments:" style="padding-bottom: 8px; padding-top: 8px;">'
                + '<div><strong>Comments:</strong></div>'
                + '<div data-dmt-value="true" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + f[4].value + '</div>'
                + '</div>'
                + '<div data-dmt-row="field" data-dmt-pair="1" data-dmt-label="Additional Restrictions:" style="padding-bottom: 8px; padding-top: 8px;">'
                + '<div><strong>Additional Restrictions:</strong></div>'
                + '<div data-dmt-value="true" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + f[5].value + '</div>'
                + '</div>'
                + '</div>'
                + ' </br>';
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OtherApprovalProcessDataRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}