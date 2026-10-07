// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
public without sharing class DMT_TreasuryApprovalProcessDataRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer {

    // ADD OR REMOVE A FIELD HERE. Feeds both renderHtml() and getTrackedFields(), so pass the field
    // API name as the third DisplayField argument or the field renders without being watched.
    // See DMT_InfoRenderer for the full rules. The three approver/analyst fields are relationship
    // traversals ('X__r.Name') rather than the lookup Id itself, matching what is actually
    // displayed - see DMT_MultiObjectFieldTrackableRenderer's header comment on why a dot here is
    // unambiguous. Comments/Additional Restrictions are deliberately absent: this record type
    // (unlike OtherProducts) never displays them - see DMT_OtherApprovalProcessDataRenderer.
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Transaction:', DMT_FormattingUtils.checkNull(data.line.DMT_Booking_Unit_Risk_Analyst__r?.Name), new List<String>{'DMT_Booking_Unit_Risk_Analyst__r.Name'}),
            new DMT_FormattingUtils.DisplayField('Global Banker:', DMT_FormattingUtils.checkNull(data.line.DMT_GlobalBanker__c), new List<String>{'DMT_GlobalBanker__c'}),
            new DMT_FormattingUtils.DisplayField('Notional:', DMT_FormattingUtils.checkNull(data.line.DMT_Approver__r?.Name), new List<String>{'DMT_Approver__r.Name'}),
            new DMT_FormattingUtils.DisplayField('Financial Program Risk Approver (Global):', DMT_FormattingUtils.checkNull(data.line.DMT_ApproverGlobalBanker__r?.Name), new List<String>{'DMT_ApproverGlobalBanker__r.Name'}),
            new DMT_FormattingUtils.DisplayField('Client Use:', DMT_FormattingUtils.checkNull(data.line.DMT_Client_Use__c), new List<String>{'DMT_Client_Use__c'})
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
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">APPROVAL PROCESS DATA</h2>'
                + '<table class="style-table" style="width:100%; border-collapse: separate; border-spacing: 10px 0; table-layout: fixed; margin-left: -10px; margin-right: -10px;">'
                + '<colgroup>'
                    + '<col style="width: 50%;">'
                    + '<col style="width: 50%;">'
                + '</colgroup>'
                + '<tr data-dmt-row="field">'
                    + '<td data-dmt-pair="1" data-dmt-label="Transaction:" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Transaction:</strong></div>'
                    + '<div style="min-height: 25px;width:100%; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + f[0].value + '</div>'
                    + '</td>'
                    + '<td data-dmt-pair="2" data-dmt-label="Global Banker:" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Global Banker:</strong></div>'
                    + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + f[1].value + '</div>'
                    + '</td>'
                + '</tr>'
                + '<tr data-dmt-row="field">'
                    + '<td data-dmt-pair="1" data-dmt-label="Notional:" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Notional:</strong></div>'
                    + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + f[2].value + '</div>'
                    + '</td>'
                    + '<td data-dmt-pair="2" data-dmt-label="Financial Program Risk Approver (Global):" style="padding-bottom: 8px; padding-top: 8px; vertical-align: top;">'
                    + '<div><strong>Financial Program Risk Approver (Global):</strong></div>'
                    + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + f[3].value + '</div>'
                    + '</td>'
                 + '</tr>'
                + '</table>'
                + '<div style="height: 20px;"></div>'
                + '<div data-dmt-row="field" style="padding-bottom: 8px; padding-top: 8px;">'
                + '<div data-dmt-pair="1" data-dmt-label="Client Use:"><strong>Client Use:</strong></div>'
                + '<div data-dmt-pair="1" data-dmt-value="true" style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + f[4].value + '</div>'
                + '</div>'
                + '</div>'
                + ' </br>';
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_TreasuryApprovalProcessDataRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}