public without sharing class DMT_OpportunityClientRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_CalloutTrackableRenderer {

    /**
     * CIBGLOBALD-4117: ADD OR REMOVE A FIELD HERE. Pass the field API name as the third DisplayField argument or the
     * field will render without being watched by the approval-restart mechanism - see
     * DMT_ClientRenderer.
     *
     * This component spans two objects, so those names are OBJECT-QUALIFIED ('Object.Field').
     * getTrackedFieldsByObject() groups on the qualifier; getTrackedFields() returns only the
     * Opportunity-native ones. Single-object renderers use bare field names instead.
     *
     * Intentionally untagged, so they display but are never watched via this DisplayField mechanism:
     *   Fiscal ID / Client Group Code    - live on the parent Account. Client master data edited
     *                                      outside this flow; watching them would restart
     *                                      approvals on every opportunity for that client.
     *
     * CIBGLOBALD-4117 - Group / Client (clientGroupName) and Current Rating Tool Date
     * (currentRatingToolDate) are derived from HPG callouts, not queryable fields, so the
     * DisplayField tagging mechanism above can't watch them - see getCalloutCacheKey()/
     * fetchLiveTrackedValues() below instead.
     */
    private List<DMT_FormattingUtils.DisplayField> buildRenderFields(DMT_ViewController.LineDataWrapper data) {

        // The tracking methods call this with an empty wrapper, needing only field names. Skip the
        // picklist label lookups then - they run Schema.getGlobalDescribe() inside the trigger and
        // the result would be discarded.
        Boolean hasData = !data.oppClient.getPopulatedFieldsAsMap().isEmpty();

        String clientGroup = getClientGroupString(data);
        String sectorPickLabel = hasData ? Util_Picklist.getLabelFromAPI('Account', 'DES_AGGR_Sector__c').get(data.oppClient.DMT_Sector__c) : null;
        String subsectorPickLabel = hasData ? Util_Picklist.getLabelFromAPI('Account', 'Subsector__c').get(data.oppClient.DMT_Subsector__c) : null;
        String activityPickLabel = hasData ? Util_Picklist.getLabelFromAPI('Account', 'DES_Activity__c').get(data.oppClient.DMT_Activity__c) : null;
        String industryPickLabel = hasData ? Util_Picklist.getLabelFromAPI('DMT_Opportunity_Client__c', 'DMT_Industry__c').get(data.oppClient.DMT_Industry__c) : null;
        String industryHeadPickLabel = hasData ? Util_Picklist.getLabelFromAPI('DMT_Opportunity_Client__c', 'DMT_Sector_Head__c').get(data.oppClient.DMT_Sector_Head__c) : null;
        String sectorV2 = '';

        List<SObject> opportunityClients = data.opportunity.getSObjects('DMT_MDE_Opportunities_Clients__r');
        if (opportunityClients != null && !opportunityClients.isEmpty()) {
            sectorV2 = (String) opportunityClients[0].get('DMT_Sector__c');
        }

        // 1. Initialize the empty list first
        List<DMT_FormattingUtils.DisplayField> renderFields = new List<DMT_FormattingUtils.DisplayField>();

        // 2. Add base fields ('HALF' = 1 standard column in a 2-column layout)
        renderFields.add(new DMT_FormattingUtils.DisplayField('Group / Client', DMT_FormattingUtils.checkNull(clientGroup)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('', '')); // Our dynamic empty space flag!
        renderFields.add(new DMT_FormattingUtils.DisplayField('Internal Rating', DMT_FormattingUtils.checkNull(data.oppClient.g_upd_lmscl_internal_ratg_type__c), new List<String>{'DMT_Opportunity_Client__c.g_upd_lmscl_internal_ratg_type__c'}));

        if (data.opportunity.Account?.DES_Client_Type__c == 'Subsidiary') {
            renderFields.add(new DMT_FormattingUtils.DisplayField('Current Rating Tool Date', DMT_FormattingUtils.checkNull(data.currentRatingToolDate)));
        }
        renderFields.add(new DMT_FormattingUtils.DisplayField('Scoring', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Scoring__c), new List<String>{'DMT_Opportunity_Client__c.DMT_Scoring__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Unified External Rating', DMT_FormattingUtils.checkNull(data.oppClient.External_Rating__c), new List<String>{'DMT_Opportunity_Client__c.External_Rating__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('S&P External Rating', DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating_SP__c), new List<String>{'DMT_Opportunity_Client__c.DMT_External_Rating_SP__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Moody\'s External Rating', DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating_Moodys__c), new List<String>{'DMT_Opportunity_Client__c.DMT_External_Rating_Moodys__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Fitch External Rating', DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating_Fitch__c), new List<String>{'DMT_Opportunity_Client__c.DMT_External_Rating_Fitch__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Client Threshold Type', DMT_FormattingUtils.checkNull(data.opportunity.DMT_Threshold_Type__c), new List<String>{'Opportunity.DMT_Threshold_Type__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Industry', DMT_FormattingUtils.checkNull(industryPickLabel).toLowerCase().capitalize(), new List<String>{'DMT_Opportunity_Client__c.DMT_Industry__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Leveraged Lending', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Leveraged_Lending__c), new List<String>{'DMT_Opportunity_Client__c.DMT_Leveraged_Lending__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('CAMN', DMT_FormattingUtils.checkNull(data.oppClient.DMT_CAMN__c), new List<String>{'DMT_Opportunity_Client__c.DMT_CAMN__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Client Type', DMT_FormattingUtils.checkNull(data.oppClient.Counterpart__c), new List<String>{'DMT_Opportunity_Client__c.Counterpart__c'}));

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
        renderFields.add(new DMT_FormattingUtils.DisplayField('Fiscal ID', DMT_FormattingUtils.checkNull(data.opportunity.Account?.DES_ID_Fiscal__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Client Group Code - Asset Allocation', DMT_FormattingUtils.checkNull(data.opportunity.Account?.DES_Group_Code__c)));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Sector - Asset Allocation', DMT_FormattingUtils.checkNull(sectorPickLabel), new List<String>{'DMT_Opportunity_Client__c.DMT_Sector__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Subsector - Asset Allocation', DMT_FormattingUtils.checkNull(subsectorPickLabel), new List<String>{'DMT_Opportunity_Client__c.DMT_Subsector__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Activity - Asset Allocation', DMT_FormattingUtils.checkNull(activityPickLabel), new List<String>{'DMT_Opportunity_Client__c.DMT_Activity__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Sector Head', DMT_FormattingUtils.checkNull(industryHeadPickLabel).toLowerCase().capitalize(), new List<String>{'DMT_Opportunity_Client__c.DMT_Sector_Head__c'}));
        renderFields.add(new DMT_FormattingUtils.DisplayField('Guarantor(s) name & Fiscal ID', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Guarantor_Name_Fiscal_ID__c), 'FULL'));

        return renderFields;
    }

    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        Map<String, List<String>> byObject = new Map<String, List<String>>();
        for (DMT_FormattingUtils.DisplayField df : buildRenderFields(new DMT_ViewController.LineDataWrapper())) {
            if (df.fieldApiNames == null) {
                continue;
            }
            for (String qualified : df.fieldApiNames) {
                addField(byObject, qualified.substringBefore('.'), qualified.substringAfter('.'));
            }
        }
        // These four never surface from the loop above: the first three are only built inside the
        // Fin Inst Counterpart branch, which an empty wrapper never enters, and the fourth uses the
        // (label, value, size) DisplayField constructor, which carries no field names. They are
        // watched regardless of branch, since Counterpart__c itself can change.
        addField(byObject, 'DMT_Opportunity_Client__c', 'SCRA__c');
        addField(byObject, 'DMT_Opportunity_Client__c', 'AVC_Check__c');
        addField(byObject, 'DMT_Opportunity_Client__c', 'European_Bank_Check__c');
        addField(byObject, 'DMT_Opportunity_Client__c', 'DMT_Guarantor_Name_Fiscal_ID__c');
        return byObject;
    }

    // DMT_Opportunity_Client__c rows are direct children of the Opportunity, so parentValueField is
    // simply 'Id' - unlike a Line's Client rows, which hang off DMT_Line__c.Custom_Association__c.
    // CIBGLOBALD-4117 - ChildSection(componentName, snapshotSectionKey, childObjectApiName,
    // childLookupField, parentValueField[, orderBy]):
    //   componentName       - this component's display name, matching its DMT_Items__c row;
    //                         shows up in logs/labels, not used for lookups.
    //   snapshotSectionKey  - the key this section's rows are stored under in the frozen JSON
    //                         snapshot. Shared across every component that reads the same child
    //                         object under the same key - fields from all of them get queried and
    //                         compared together, so add/remove fields on the OBJECT's
    //                         getTrackedFieldsByObject() map, never invent a new key for one field.
    //   childObjectApiName  - the SObject to query for this section's rows. Must match a key in
    //                         this renderer's own getTrackedFieldsByObject() map, or nothing gets
    //                         queried/compared for it.
    //   childLookupField    - the field ON childObjectApiName that points back to the parent record.
    //   parentValueField    - the field ON THE PARENT (Opportunity/Line) whose value is matched
    //                         against childLookupField - almost always 'Id'; a different value here
    //                         means an extra hop (see Custom_Association_Client__c's hand-written
    //                         special case in DMT_ApprovalChangeStep_Handler for why that one isn't
    //                         generic).
    //   orderBy (optional)  - ORDER BY clause for the child query, when row order matters for the
    //                         comparison.
    public List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record) {
        return new List<DMT_ApprovalChangeStep_Helper.ChildSection>{
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Client', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            )
        };
    }

    private static void addField(Map<String, List<String>> byObject, String objectApiName, String fieldApiName) {
        if (!byObject.containsKey(objectApiName)) {
            byObject.put(objectApiName, new List<String>());
        }
        if (!byObject.get(objectApiName).contains(fieldApiName)) {
            byObject.get(objectApiName).add(fieldApiName);
        }
    }

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    // This renderer instead delegates to its own getTrackedFieldsByObject()'s 'Opportunity' key -
    // only the fields on the Opportunity itself. The DMT_Opportunity_Client__c fields are child
    // rows, compared separately by DMT_SnapshotChildComparator.
    public List<String> getTrackedFields(SObject record) {
        List<String> opportunityFields = getTrackedFieldsByObject(record).get('Opportunity');
        return opportunityFields == null ? new List<String>() : opportunityFields;
    }

    // 2. HELPER: Calculate Client Group — reads pre-fetched value from wrapper (no SOQL here)
    private String getClientGroupString(DMT_ViewController.LineDataWrapper data) {
        if (data.opportunity.AccountId == null) return '';
        return data.clientGroupName != null ? data.clientGroupName : '';
    }

    // CIBGLOBALD-4117 - record is only guaranteed to carry its Id here (async context) - re-query
    // everything needed.
    public String getCalloutCacheKey(SObject record) {
        Opportunity opp = [SELECT Id, Account.g_customer_id__c FROM Opportunity WHERE Id = :record.Id];
        return opp.Account?.g_customer_id__c;
    }

    public Map<String, Object> fetchLiveTrackedValues(SObject record) {
        Map<String, Object> values = new Map<String, Object>();
        Opportunity opp = [SELECT Id, AccountId, Account.Name, Account.g_customer_id__c FROM Opportunity WHERE Id = :record.Id];
        if (opp.AccountId == null) {
            return values;
        }

        if (opp.Account.g_customer_id__c != null) {
            DMT_ViewController.MonoHolderDataWrapper monoHolderData =
                DMT_ViewController.getMonoHolderDataFromService(opp.AccountId, opp.Account.g_customer_id__c);
            values.put('currentRatingToolDate', monoHolderData.currentRatingToolDate);
        }

        // Mirrors DMT_ViewController's own composition and try/catch - getGroupFromClientAccount
        // isn't trusted to always succeed there either.
        try {
            Map<String, Object> groupData = DMT_HPG_Utils.getGroupFromClientAccount(opp.AccountId);
            String groupName = groupData.get('groupName') != null ? (String) groupData.get('groupName') : '';
            String accountName = opp.Account.Name != null ? opp.Account.Name : '';
            values.put('clientGroupName', groupName + ' - ' + accountName);
        } catch (Exception e) {
            values.put('clientGroupName', '');
        }

        return values;
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
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Client</h2>'
                + '<div class="slds-scope">'
                + DMT_FormattingUtils.generateHtmlTable(fieldsToRender) // Call the utility
                + '</div>'
                + '</div></br></br>';

            DMT_AsyncOrchestrator.flush();
            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OpportunityClientRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                e.getMessage(),
                e.getStackTraceString(),
                e.getLineNumber(),
                e.getTypeName(),
                'DMT_OpportunityClientRenderer',
                'renderHtml',
                'DMT',
                ''
            ));
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}