public without sharing class DMT_LineSanctionClientRenderer implements DMT_ViewRenderer {

    // ==========================================
    // HELPER: Build the DisplayField List
    // ==========================================
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {
        // Always include the base sanction line fields
        List<DMT_FormattingUtils.DisplayField> renderFields = new List<DMT_FormattingUtils.DisplayField>{
            //new DMT_FormattingUtils.DisplayField('Client', DMT_FormattingUtils.checkNull(data.line.Client__r?.Name)),
            //new DMT_FormattingUtils.DisplayField('Client Type', DMT_FormattingUtils.checkNull(data.line.Client_Type__c))
        };
        // If oppClient is available, append the full opportunity client fields
        if (data.oppClient != null && !data.oppClient.getPopulatedFieldsAsMap().isEmpty()) {
            renderFields.addAll(buildRenderFieldsFromOppClient(data));
        }
        return renderFields;
    }

    // Full client fields sourced from the associated Opportunity's DMT_Opportunity_Client__c record
    private List<DMT_FormattingUtils.DisplayField> buildRenderFieldsFromOppClient(DMT_ViewController.LineDataWrapper data) {
        String clientGroup = data.clientGroupName != null ? data.clientGroupName : '';

        String sectorPickLabel       = Util_Picklist.getLabelFromAPI('Account', 'DES_AGGR_Sector__c').get(data.oppClient.DMT_Sector__c);
        String subsectorPickLabel    = Util_Picklist.getLabelFromAPI('Account', 'Subsector__c').get(data.oppClient.DMT_Subsector__c);
        String activityPickLabel     = Util_Picklist.getLabelFromAPI('Account', 'DES_Activity__c').get(data.oppClient.DMT_Activity__c);
        String industryPickLabel     = Util_Picklist.getLabelFromAPI('DMT_Opportunity_Client__c', 'DMT_Industry__c').get(data.oppClient.DMT_Industry__c);
        String industryHeadPickLabel = Util_Picklist.getLabelFromAPI('DMT_Opportunity_Client__c', 'DMT_Sector_Head__c').get(data.oppClient.DMT_Sector_Head__c);

        List<DMT_FormattingUtils.DisplayField> renderFields = new List<DMT_FormattingUtils.DisplayField>();

        renderFields.add(new DMT_FormattingUtils.DisplayField('Group / Client', DMT_FormattingUtils.checkNull(clientGroup)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('', ''));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Internal Rating', DMT_FormattingUtils.checkNull(data.oppClient.g_upd_lmscl_internal_ratg_type__c)));

        if (data.opportunity != null && data.opportunity.Account != null
                && data.opportunity.Account.DES_Client_Type__c == 'Subsidiary') {
            renderFields.add(new DMT_FormattingUtils.DisplayField('Current Rating Tool Date', DMT_FormattingUtils.checkNull(data.currentRatingToolDate)));
        }
        renderFields.add(new DMT_FormattingUtils.DisplayField('Scoring',                  DMT_FormattingUtils.checkNull(data.oppClient.DMT_Scoring__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Unified External Rating',  DMT_FormattingUtils.checkNull(data.oppClient.External_Rating__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('S&P External Rating',      DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating_SP__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Moody\'s External Rating', DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating_Moodys__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Fitch External Rating',    DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating_Fitch__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Client Threshold Type',    DMT_FormattingUtils.checkNull(data.opportunity?.DMT_Threshold_Type__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Industry',                 DMT_FormattingUtils.checkNull(industryPickLabel).toLowerCase().capitalize()));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Leveraged Lending',        DMT_FormattingUtils.checkNull(data.oppClient.DMT_Leveraged_Lending__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('CAMN',                     DMT_FormattingUtils.checkNull(data.oppClient.DMT_CAMN__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Client Type',              DMT_FormattingUtils.checkNull(data.oppClient.Counterpart__c)));

        Set<String> validCounterparts = new Set<String>{'Fin Inst', 'Fin Inst-I', 'Fin Inst-B'};
        if (validCounterparts.contains(data.oppClient.Counterpart__c)) {
            renderFields.add(new DMT_FormattingUtils.DisplayField('SCRA (Simplified Credit Risk Approach)', DMT_FormattingUtils.checkNull(data.oppClient.SCRA__c), 'HALF'));
            renderFields.add(new DMT_FormattingUtils.DisplayField('Asset Value Correlation', data.oppClient.AVC_Check__c, 'QUARTER'));
            renderFields.add(new DMT_FormattingUtils.DisplayField('European Bank',           data.oppClient.European_Bank_Check__c, 'QUARTER'));
        }

        renderFields.add(new DMT_FormattingUtils.DisplayField('Fiscal ID',        DMT_FormattingUtils.checkNull(data.opportunity?.Account?.DES_ID_Fiscal__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Client Group Code - Asset Allocation', DMT_FormattingUtils.checkNull(data.opportunity?.Account?.DES_Group_Code__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Sector - Asset Allocation',            DMT_FormattingUtils.checkNull(sectorPickLabel)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Subsector - Asset Allocation',         DMT_FormattingUtils.checkNull(subsectorPickLabel)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Activity - Asset Allocation',          DMT_FormattingUtils.checkNull(activityPickLabel)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Sector Head',                          DMT_FormattingUtils.checkNull(industryHeadPickLabel).toLowerCase().capitalize()));

        return renderFields;
    }

    // ==========================================
    // HTML RENDERING
    // ==========================================
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Approval Client data not provided</div>';
        }

        try {
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Approval Client</h2>'
                + '<div class="slds-scope">'
                + DMT_FormattingUtils.generateHtmlTable(fieldsToRender)
                + '</div>'
                + '</div>'
                + '&nbsp;</br>';

            return html;

        } catch (Exception e){
            System.debug('Error in DMT_LineSanctionClientRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}