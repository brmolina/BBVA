public with sharing class DMT_OppClientNBCRenderer implements DMT_ViewRenderer {

    // 1. HELPER: Build the list dynamically using the 'data' passed from the render methods
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {

        // Fetch the Client Group string before building the list
        String clientGroup = getClientGroupString(data);

        String sectorPickLabel = Util_Picklist.getLabelFromAPI('Account', 'DES_AGGR_Sector__c').get(data.oppClient.DMT_Sector__c);
        String subsectorPickLabel = Util_Picklist.getLabelFromAPI('Account', 'Subsector__c').get(data.oppClient.DMT_Subsector__c);
        String activityPickLabel = Util_Picklist.getLabelFromAPI('Account', 'DES_Activity__c').get(data.oppClient.DMT_Activity__c);
        String industryPickLabel = Util_Picklist.getLabelFromAPI('DMT_Opportunity_Client__c', 'DMT_Industry__c').get(data.oppClient.DMT_Industry__c);
        String industryHeadPickLabel = Util_Picklist.getLabelFromAPI('DMT_Opportunity_Client__c', 'DMT_Sector_Head__c').get(data.oppClient.DMT_Sector_Head__c);

        // 1. Initialize the empty list first
        List<DMT_FormattingUtils.DisplayField> renderFields = new List<DMT_FormattingUtils.DisplayField>();

        // 2. Add base fields ('HALF' = 1 standard column in a 2-column layout)
        renderFields.add(new DMT_FormattingUtils.DisplayField('Group / Client', DMT_FormattingUtils.checkNull(clientGroup)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('', '')); // Our dynamic empty space flag!
        renderFields.add(new DMT_FormattingUtils.DisplayField('Internal Rating', DMT_FormattingUtils.checkNull(data.oppClient.g_upd_lmscl_internal_ratg_type__c)));

        if (data.opportunity.Account.DES_Client_Type__c == 'Subsidiary') {
            renderFields.add(new DMT_FormattingUtils.DisplayField('Current Rating Tool Date', DMT_FormattingUtils.checkNull(data.currentRatingToolDate)));
        }
        renderFields.add(new DMT_FormattingUtils.DisplayField('Scoring', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Scoring__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Unified External Rating', DMT_FormattingUtils.checkNull(data.oppClient.External_Rating__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Client Threshold Type', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Threshold_Type__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Industry', DMT_FormattingUtils.checkNull(industryPickLabel).toLowerCase().capitalize()));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Leveraged Lending', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Leveraged_Lending__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Client Type', DMT_FormattingUtils.checkNull(data.oppClient.Counterpart__c)));

        // 3. Conditional logic (Corrected the "in" syntax using an Apex Set)
        Set<String> validCounterparts = new Set<String>{'Fin Inst', 'Fin Inst-I', 'Fin Inst-B'};

        if (validCounterparts.contains(data.oppClient.Counterpart__c)) {
            // This field occupies its normal column ('HALF')
            renderFields.add(new DMT_FormattingUtils.DisplayField('SCRA (Simplified Credit Risk Approach)', DMT_FormattingUtils.checkNull(data.oppClient.SCRA__c), 'HALF'));

            // These two checkboxes share a single column ('QUARTER' each, adding up to 'HALF')
            renderFields.add(new DMT_FormattingUtils.DisplayField('Asset Value Correlation', data.oppClient.AVC_Check__c, 'QUARTER'));
            renderFields.add(new DMT_FormattingUtils.DisplayField('European Bank', data.oppClient.European_Bank_Check__c, 'QUARTER'));
        }

        // 4. Add the rest of the standard fields
        renderFields.add(new DMT_FormattingUtils.DisplayField('Sector - Asset Allocation', DMT_FormattingUtils.checkNull(sectorPickLabel)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Subsector - Asset Allocation', DMT_FormattingUtils.checkNull(subsectorPickLabel)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Activity - Asset Allocation', DMT_FormattingUtils.checkNull(activityPickLabel)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Sector Head', DMT_FormattingUtils.checkNull(industryHeadPickLabel).toLowerCase().capitalize()));

        return renderFields;
    }

    // 2. HELPER: Calculate Client Group — reads pre-fetched value from wrapper (no SOQL here)
    private String getClientGroupString(DMT_ViewController.LineDataWrapper data) {
        if (data.opportunity.AccountId == null) return '';
        return data.clientGroupName != null ? data.clientGroupName : '';
    }

    // ==========================================
    // RENDER METHODS
    // ==========================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.oppClient.getPopulatedFieldsAsMap().isEmpty()) {
            return '<div>Client data not provided</div>';
        }

        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            // Build the fields for HTML
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Client NBC</h2>'
                + '<div class="slds-scope">'
                + DMT_FormattingUtils.generateHtmlTable(fieldsToRender) // Call the utility
                + '</div>'
                + '</div></br></br>';

            DMT_AsyncOrchestrator.flush();
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OppClientNBCRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.oppClient.getPopulatedFieldsAsMap().isEmpty()) {
            return new Map<String, Object>();
        }

        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }
            // Initialize the component map
            Map<String, Object> component = new Map<String, Object>();
            List<Object> contentList = new List<Object>();

            contentList.add(DMT_Create_Pdf_Controller.createTitle('Client NBC'));

            // Build the fields for PDF
            List<DMT_FormattingUtils.DisplayField> fieldsToRender = buildRenderFields(data);

            // Call the utility
            contentList.add(DMT_Create_Pdf_Controller.generatePdfList(fieldsToRender));

            component.put('content', contentList);
            component.put('name', 'Client NBC');

            DMT_AsyncOrchestrator.flush();
            return component;
        } catch (Exception e){
            System.debug('Error in DMT_OppClientNBCRenderer renderPdfJson, '+ e.getMessage() + ' ' + e.getLineNumber());
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_OppClientNBCRenderer', 'renderPdfJson', 'DMT', ''));
            return new Map<String, Object>();
        }
    }
}