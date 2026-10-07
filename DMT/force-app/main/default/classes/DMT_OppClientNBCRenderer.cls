public without sharing class DMT_OppClientNBCRenderer implements DMT_ViewRenderer, DMT_CalloutTrackableRenderer {


    // 2. HELPER: Calculate Client Group — reads pre-fetched value from wrapper (no SOQL here)
    private String getClientGroupString(DMT_ViewController.LineDataWrapper data) {
        if (data.opportunity.AccountId == null) return '';
        return data.clientGroupName != null ? data.clientGroupName : '';
    }

    // ==========================================
    // DMT_CalloutTrackableRenderer (CIBGLOBALD-4117)
    // ==========================================
    // 'Current Rating Tool Date' (below) comes from the HPG MonoHolder service - it is never
    // written to any Salesforce field, so the standard SOQL-based tracked-field comparison can
    // never see it change. This is the one field on this renderer that needs the callout-tracked
    // path; everything else it displays is ad-hoc/tailor-made per business request and out of
    // scope for this.

    // Test-only override: DMT_HPG_Utils.callService bypasses Test.setMock(HttpCalloutMock.class,...)
    // entirely in test context - it always returns the one fixed body configured on the matching
    // iaso__GBL_integration_service__mdt record, so a test cannot make two calls return two
    // different values through the callout itself. This lets a test simulate the external value
    // changing between a freeze and a later comparison without a live service.
    @TestVisible private static Boolean forceLiveDateForTest = false;
    @TestVisible private static Date forcedLiveDateForTest = null;

    public String getCalloutCacheKey(SObject record) {
        Opportunity opp = [SELECT Id, Account.g_customer_id__c FROM Opportunity WHERE Id = :record.Id];
        return opp.Account?.g_customer_id__c;
    }

    public Map<String, Object> fetchLiveTrackedValues(SObject record) {
        Map<String, Object> values = new Map<String, Object>();
        if (forceLiveDateForTest) {
            values.put('currentRatingToolDate', forcedLiveDateForTest);
            return values;
        }
        Opportunity opp = [SELECT Id, AccountId, Account.g_customer_id__c FROM Opportunity WHERE Id = :record.Id];
        if (opp.AccountId == null || opp.Account.g_customer_id__c == null) {
            return values;
        }
        DMT_ViewController.MonoHolderDataWrapper monoHolderData =
            DMT_ViewController.getMonoHolderDataFromService(opp.AccountId, opp.Account.g_customer_id__c);
        values.put('currentRatingToolDate', monoHolderData.currentRatingToolDate);
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

            // Resolve picklist labels
            String clientGroup   = getClientGroupString(data);
            String sectorLbl     = Util_Picklist.getLabelFromAPI('Account', 'DES_AGGR_Sector__c').get(data.oppClient.DMT_Sector__c);
            String subsectorLbl  = Util_Picklist.getLabelFromAPI('Account', 'Subsector__c').get(data.oppClient.DMT_Subsector__c);
            String activityLbl   = Util_Picklist.getLabelFromAPI('Account', 'DES_Activity__c').get(data.oppClient.DMT_Activity__c);
            String industryLbl   = Util_Picklist.getLabelFromAPI('DMT_Opportunity_Client__c', 'DMT_Industry__c').get(data.oppClient.DMT_Industry__c);
            String sectorHeadLbl = Util_Picklist.getLabelFromAPI('DMT_Opportunity_Client__c', 'DMT_Sector_Head__c').get(data.oppClient.DMT_Sector_Head__c);

            Boolean isSubsidiary = data.opportunity.Account.DES_Client_Type__c == 'Subsidiary';
            Boolean isFinInst    = new Set<String>{'Fin Inst', 'Fin Inst-I', 'Fin Inst-B'}.contains(data.oppClient.Counterpart__c);

            // Cell style constants
            String LS = 'background-color:#004481;color:#ffffff;font-weight:bold;font-size:11px;padding:4px 8px;';
            String VS = 'padding:6px 8px;border-bottom:1px solid #ccc;min-height:22px;font-size:12px;background-color:#ffffff;';
            String CS = 'padding:0 6px 6px 0;vertical-align:top;';

            String internalRatingScoring = DMT_FormattingUtils.checkNull(data.oppClient.g_upd_lmscl_internal_ratg_type__c)
                + ' | ' + DMT_FormattingUtils.checkNull(data.oppClient.DMT_Scoring__c);

            String h = '<div style="margin-bottom:16px;">'
                + '<h2 style="font-size:18px;color:#004481;margin-bottom:10px;font-weight:bold;">Client NBC</h2>'
                + '<table style="width:100%;border-collapse:separate;border-spacing:0;table-layout:fixed;">'
                + '<colgroup><col style="width:25%;"><col style="width:25%;"><col style="width:25%;"><col style="width:25%;"></colgroup>';

            // Row 1: Group / Client | Internal rating | Scoring (combined)
            h += '<tr>'
                + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">Group / Client</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(clientGroup) + '</div></td>'
                + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">Internal rating | Scoring</div><div style="' + VS + '">' + internalRatingScoring + '</div></td>'
                + '</tr>';

            // Row 2 (subsidiary only): spacer left | Current Rating Tool Date right
            if (isSubsidiary) {
                h += '<tr>'
                    + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">&nbsp;</div><div style="' + VS + '">&nbsp;</div></td>'
                    + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">Current Rating Tool Date</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(data.currentRatingToolDate) + '</div></td>'
                    + '</tr>';
            }

            // Row 3: External rating | Client Threshold Type
            h += '<tr>'
                + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">External rating (S&amp;P | Moody\'s | Fitch)</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(data.oppClient.External_Rating__c) + '</div></td>'
                + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">Client Threshold Type</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(data.opportunity.DMT_Threshold_Type__c) + '</div></td>'
                + '</tr>';

            // Row 4: Industry | Leveraged Lending
            h += '<tr>'
                + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">Industry</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(industryLbl).toLowerCase().capitalize() + '</div></td>'
                + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">Leveraged Lending</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(data.oppClient.DMT_Leveraged_Lending__c) + '</div></td>'
                + '</tr>';

            // Row 5: Client Type | (SCRA if FinInst, otherwise spacer)
            if (isFinInst) {
                h += '<tr>'
                    + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">Client Type</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(data.oppClient.Counterpart__c) + '</div></td>'
                    + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">SCRA (Simplified Credit Risk Approach)</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(data.oppClient.SCRA__c) + '</div></td>'
                    + '</tr>';
                h += '<tr>'
                    + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">&nbsp;</div><div style="' + VS + '">&nbsp;</div></td>'
                    + '<td colspan="1" style="' + CS + '"><div style="' + LS + '">Asset Value Correlation</div><div style="' + VS + '"><input type="checkbox" disabled="" ' + (data.oppClient.AVC_Check__c ? 'checked="checked"' : '') + ' /></div></td>'
                    + '<td colspan="1" style="' + CS + '"><div style="' + LS + '">European Bank</div><div style="' + VS + '"><input type="checkbox" disabled="" ' + (data.oppClient.European_Bank_Check__c ? 'checked="checked"' : '') + ' /></div></td>'
                    + '</tr>';
            } else {
                h += '<tr>'
                    + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">Client Type</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(data.oppClient.Counterpart__c) + '</div></td>'
                    + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">&nbsp;</div><div style="' + VS + '">&nbsp;</div></td>'
                    + '</tr>';
            }

            // Row 6: Sector | Subsector
            h += '<tr>'
                + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">Sector - Asset Allocation</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(sectorLbl) + '</div></td>'
                + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">Subsector - Asset Allocation</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(subsectorLbl) + '</div></td>'
                + '</tr>';

            // Row 7: Activity | Sector Head
            h += '<tr>'
                + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">Activity - Asset Allocation</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(activityLbl) + '</div></td>'
                + '<td colspan="2" style="' + CS + '"><div style="' + LS + '">Sector Head</div><div style="' + VS + '">' + DMT_FormattingUtils.checkNull(sectorHeadLbl).toLowerCase().capitalize() + '</div></td>'
                + '</tr>';

            // Row 8: Guarantor(s) name & Fiscal ID (full width)
            h += '<tr>'
                + '<td colspan="4" style="' + CS + '"><div style="' + LS + '">Guarantor(s) name &amp; Fiscal ID</div><div style="' + VS + ' word-wrap:break-word; overflow-wrap:break-word;">' + DMT_FormattingUtils.checkNull(data.oppClient.DMT_Guarantor_Name_Fiscal_ID__c) + '</div></td>'
                + '</tr>';

            h += '</table></div><br/>';

            DMT_AsyncOrchestrator.flush();
            return h;
        } catch (Exception e){
            System.debug('Error in DMT_OppClientNBCRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }
}