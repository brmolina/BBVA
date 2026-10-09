public without sharing class DMT_OtherLineInfoRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer {

    // CIBGLOBALD-4117: ADD OR REMOVE A FIELD HERE. Feeds both renderHtml() and getTrackedFields(), so pass the field
    // API name as the third DisplayField argument or the field renders without being watched.
    // See DMT_InfoRenderer for the full rules.
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        String commitmentLabel = data.line.g_line_commitment_level_type__c == 'COM'
            ? 'COMMITTED'
            : data.line.g_line_commitment_level_type__c == 'UNC'
                ? 'UNCOMMITTED'
                : data.line.g_line_commitment_level_type__c == 'PNG'
                    ? 'PENDING FORMALIZATION'
                    : data.line.g_line_commitment_level_type__c;

        // CIBGLOBALD-3779: order/labels now match the dmt_lineInfo LWC's OtherProducts field set
        // exactly (dmt_lineInfo_otherProducts_fields.js) — Line Id alone, then Name/Entific,
        // Risk Approval Start/End Date, Risk Approval Term/Currency, Amount/Type of risk,
        // Office/Individual Disposal Approval, Committed-Uncommitted/RAROEC%, RORC% alone.
        return new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Line Id:', DMT_FormattingUtils.checkNull(data.line.Line_Id__c), new List<String>{'Line_Id__c'}),
            new DMT_FormattingUtils.DisplayField('', ''),
            new DMT_FormattingUtils.DisplayField('Name:', DMT_FormattingUtils.checkNull(data.line.Name), new List<String>{'Name'}),
            new DMT_FormattingUtils.DisplayField('Entific:', DMT_FormattingUtils.checkNull(data.line.Booking_Geography__c), new List<String>{'Booking_Geography__c'}),
            new DMT_FormattingUtils.DisplayField('Risk Approval Start Date:', DMT_FormattingUtils.changeDateFormat(data.line.Start_Date__c), new List<String>{'Start_Date__c'}),
            new DMT_FormattingUtils.DisplayField('Risk Approval End Date:', DMT_FormattingUtils.changeDateFormat(data.line.End_Date__c), new List<String>{'End_Date__c'}),
            new DMT_FormattingUtils.DisplayField('Risk Approval Term:', DMT_FormattingUtils.checkNull(data.line.DMT_Risk_Approval_Term__c), new List<String>{'DMT_Risk_Approval_Term__c'}),
            new DMT_FormattingUtils.DisplayField('Currency:', DMT_FormattingUtils.checkNull(data.line.CurrencyIsoCode), new List<String>{'CurrencyIsoCode'}),
            new DMT_FormattingUtils.DisplayField('Amount:', DMT_FormattingUtils.formatCurrencyAmount(data.line.Amount__c, data.currencyIsoCode), new List<String>{'Amount__c'}),
            new DMT_FormattingUtils.DisplayField('Type of Risk:', DMT_FormattingUtils.checkNull(data.line.g_limit_last_level_type__c), new List<String>{'g_limit_last_level_type__c'}),
            new DMT_FormattingUtils.DisplayField('Office:', DMT_FormattingUtils.checkNull(data.line.DMT_Oficina__c), new List<String>{'DMT_Oficina__c'}),
            // String (not Boolean) constructor so this pairs on one row with Office — the Boolean
            // constructor always forces a field onto its own row in renderHtml()'s pairing logic.
            new DMT_FormattingUtils.DisplayField('Individual Disposal Approval:', data.line.DMT_Individual_Disposal_Approval__c == true ? 'Yes' : 'No', new List<String>{'DMT_Individual_Disposal_Approval__c'}),
            new DMT_FormattingUtils.DisplayField('Committed / Uncommitted:', DMT_FormattingUtils.checkNull(commitmentLabel), new List<String>{'g_line_commitment_level_type__c'}),
            new DMT_FormattingUtils.DisplayField('Minimum percentage RAROEC without financing:', DMT_FormattingUtils.checkNull(data.line.gf_min_raroec_wo_fcg_per__c), new List<String>{'gf_min_raroec_wo_fcg_per__c'}),
            new DMT_FormattingUtils.DisplayField('Minimum percentage RORC without financing:', DMT_FormattingUtils.checkNull(data.line.gf_min_rorc_wo_fcg_per__c), new List<String>{'gf_min_rorc_wo_fcg_per__c'})
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
                if (current.boolValue != null) {
                    rows += DMT_FormattingUtils.tableRow1column_checkbox(current.label, current.boolValue);
                    i += 1;
                } else if (i + 1 < renderFields.size() && renderFields[i + 1].boolValue == null) {
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
                + '<div class="slds-scope">'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + rows
                + '</table>'
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';
        } catch (Exception e){
            System.debug('Error in DMT_OtherLineInfoRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}