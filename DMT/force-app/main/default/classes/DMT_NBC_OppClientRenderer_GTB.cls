public without sharing class DMT_NBC_OppClientRenderer_GTB implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_CalloutTrackableRenderer {

    // ====================================================================================================
    // DATA WRAPPER (centralizes values)
    // ====================================================================================================
    private class OppClientData {

        public String clientGroup;
        public String sectorHeadLbl;
        public String industryLbl;
        public String externalRating;
        public String productArea;
        public String guarantorNameFiscalId;
        public Boolean isLocal;
        public String internalRatingScoringHtml;
        public String typeOfDealHtml;
        public String triHtml;
        public String bookingHtml;
        public String bookingEFANHtml;
        public String tenorHtml;
        public String currencyCodeHtml;
        public String dealAmountHtml;
        public String bbvaCommitHtml;
        public String allInDrawnHtml;
        public String capitalActionHtml;
        public String bankerNameHtml;
        public String commitDeadlineHtml;
        public String structuredGTBCheckboxHtml;

        public OppClientData(DMT_ViewController.LineDataWrapper data) {

            this.clientGroup = getClientGroupString(data);
            this.sectorHeadLbl = Util_Picklist.getLabelFromAPI('DMT_Opportunity_Client__c', 'DMT_Sector_Head__c').get(data.oppClient.DMT_Sector_Head__c);
            this.industryLbl = Util_Picklist.getLabelFromAPI('DMT_Opportunity_Client__c', 'DMT_Industry__c').get(data.oppClient.DMT_Industry__c);
            this.externalRating = DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating_SP__c)
                + ' / ' + DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating_Moodys__c)
                + ' / ' + DMT_FormattingUtils.checkNull(data.oppClient.DMT_External_Rating_Fitch__c);
            this.productArea = DMT_FormattingUtils.checkNull(data.opportunity.DMT_Product_Area__c);
            this.guarantorNameFiscalId = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Guarantor_Name_Fiscal_ID__c);
            this.isLocal = data.opportunity.DMT_Threshold_Type__c == 'Local';
            String intRating = DMT_FormattingUtils.checkNull(data.oppClient.g_upd_lmscl_internal_ratg_type__c);
            String scoring = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Scoring__c);
            this.internalRatingScoringHtml = intRating + (String.isNotBlank(intRating) && String.isNotBlank(scoring) ? '<br/>' : '') + scoring;

            this.typeOfDealHtml = DMT_FormattingUtils.checkNull(data.opportunity.Name);
            this.triHtml = DMT_FormattingUtils.checkNull(data.toolkitData.tri) + ' / ' + DMT_FormattingUtils.checkNull(data.toolkitData.positioning);
            this.bookingHtml = DMT_FormattingUtils.checkNull(data.oppBookingGeography);
            this.bookingEFANHtml = DMT_FormattingUtils.checkNull(data.oppBookingEFAN);
            this.tenorHtml = DMT_FormattingUtils.checkNull(data.opportunity.DMT_Tenor__c);
            this.currencyCodeHtml = DMT_FormattingUtils.checkNull(data.opportunity.DMT_CurrencyText__c);
            this.dealAmountHtml = DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(data.opportunity.DMT_Opportunity_amount__c));
            this.bbvaCommitHtml = DMT_FormattingUtils.checkNull(DMT_FormattingUtils.toMillions(data.opportunity.DMT_CUR_Notional_Amount__c));
            this.allInDrawnHtml = DMT_NBC_ProfitabilityHelper.getOpportunityAllInDisplay(data.featuresList, false);
            this.capitalActionHtml = DMT_FormattingUtils.checkNull(data.opportunity.DMT_Capital_Action__c);
            this.bankerNameHtml = DMT_FormattingUtils.checkNull(data.opportunity.DMT_GlobalBanker__c);
            this.commitDeadlineHtml = DMT_FormattingUtils.changeDateFormat(data.oppClient.DMT_Commitment_Deadline__c);
            this.structuredGTBCheckboxHtml = buildCheckboxDivHtml(data.opportunity.DMT_Structured_GTB__c == true);
        }
        // ====================================================================================================
        // HELPER METHODS
        // ====================================================================================================

        private String buildCheckboxDivHtml(Boolean checked) {
            String checkValue = checked ? 'X' : '&nbsp;';
            String style = 'display: inline-block; width: 12px; height: 12px; border: 1px solid #004481; text-align: center; vertical-align: middle; line-height: 12px; font-family: Arial, sans-serif; font-size: 10px; color: #004481; font-weight: bold; margin: 0 auto;';
            return '<div style="' + style + '">' + checkValue + '</div>';
        }

        public String getClientGroupString(DMT_ViewController.LineDataWrapper data) {
            if (data.opportunity.AccountId == null) return '';

            String groupName = data.clientGroupName != null ? data.clientGroupName : '';
            String accountName = data.opportunity.Account != null && data.opportunity.Account.Name != null
                ? data.opportunity.Account.Name
                : '';

            if (String.isBlank(groupName)) return accountName;
            if (String.isBlank(accountName) || groupName.contains(accountName)) return groupName;
            return groupName + ' - ' + accountName;
        }
    }

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{
            'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c', 'Name',
            'DMT_Tenor__c', 'DMT_CurrencyText__c', 'DMT_Opportunity_amount__c', 'DMT_CUR_Notional_Amount__c',
            'DMT_GlobalBanker__c', 'DMT_Structured_GTB__c',
            'DMT_branch_id_c__c', 'DMT_Entity__c', 'Entific__c', 'DMT_Booking_EFAN__c'
        };
    }

    // CIBGLOBALD-4117 - mirrors OppClientData's field reads. Same fields as the IBF sub-renderer -
    // GTB hides several rows by value but reads the same underlying set (isLocal only toggles
    // which cells render, not which fields are read). Folds getTrackedFields() in under
    // 'Opportunity' here too - DMT_ApprovalChangeStep_Handler.resolveTrackedFieldsForItems uses
    // getTrackedFieldsByObject() exclusively the instant it's non-empty, never falling back to
    // getTrackedFields() on its own, so this renderer has to self-include its own plain fields to
    // stay complete.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Client__c' => new List<String>{
                'DMT_Sector_Head__c', 'DMT_Industry__c', 'DMT_External_Rating_SP__c',
                'DMT_External_Rating_Moodys__c', 'DMT_External_Rating_Fitch__c',
                'DMT_Guarantor_Name_Fiscal_ID__c', 'g_upd_lmscl_internal_ratg_type__c',
                'DMT_Scoring__c', 'DMT_Commitment_Deadline__c'
            }
        };
    }

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
                'NBC Client', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            )
        };
    }

    public String getCalloutCacheKey(SObject record) {
        return record.Id;
    }

    // CIBGLOBALD-4117 - not a real HTTP callout: reuses this interface's generic derived-value diff
    // machinery for three values that aren't queryable off the record directly. Same source/reasoning
    // as the IB&F sub-renderer's own fetchLiveTrackedValues() - see that file.
    public Map<String, Object> fetchLiveTrackedValues(SObject record) {
        Map<String, Object> values = new Map<String, Object>();
        Opportunity opp = [
            SELECT AccountId, Account.DES_Client_Type__c, Account.DES_Main_Parent__c
            FROM Opportunity
            WHERE Id = :record.Id
        ];

        DES_Template__c toolkitTemplate = new DES_Template__c();
        ComponentNBC_Controller.preloadToolkitInfo(opp, toolkitTemplate);
        values.put('toolkitTri', toolkitTemplate.cstk_tri__c);
        values.put('toolkitPositioning', toolkitTemplate.cstk_positioning__c);

        Map<String, Object> summaryRow = DMT_NBC_ProfitabilityHelper.getOpportunitySummaryRow(DMT_ViewController.getFeatures(record.Id));
        if (summaryRow != null) {
            values.put('allInDb', summaryRow.get('allInDb'));
            values.put('allInFb', summaryRow.get('allInFb'));
        }

        if (opp.AccountId != null) {
            List<DES_Denorm_AccountVisits__c> visits = DMT_View_Selector.getAccountVisitsByAccountId(opp.AccountId);
            values.put('lastVisitClient', (visits != null && !visits.isEmpty()) ? visits[0].DES_Start_Date__c : null);
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

            OppClientData vals = new OppClientData(data);

            // ── Style constants (Ultra compact: line-height 1, minimal padding) ─────────────
            String L = 'color:#ffffff; font-size:8px; font-weight:bold; padding:2px 3px; vertical-align:middle; font-family:Arial, sans-serif; word-wrap:break-word; line-height:1.1;';
            String V = 'background-color:#ffffff; color:#004481; font-size:8px; padding:2px 3px; vertical-align:middle; border:1px solid #004481; font-family:Arial, sans-serif; word-wrap:break-word; line-height:1.1;';
            String E = 'border:none; background-color:transparent; padding:0;';

            return renderGTBHtml(vals, L, V, E);

        } catch (Exception e){
            System.debug('Error in DMT_NBC_OppClientRenderer_GTB renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    // ==========================================
    // GTB RENDER (table adapted for GTB)
    // Always hides: Last Visit to the Client, Prospect, Under X-Sell Monitoring.
    // Additionally hides (label + value) when Threshold Type = Local: Deal Amount Mn, Commitment Deadline.
    // ==========================================

    private String renderGTBHtml(OppClientData vals, String L, String V, String E) {

        String h = '<div style="background-color:#004481; padding:6px; width:100%; box-sizing:border-box; page-break-inside:avoid; margin-bottom:15px;">';

        h += '<table style="width:97%; border-collapse:collapse; table-layout:fixed;">'
           +'<colgroup>'
           +'<col style="width:15%;">'
           +'<col style="width:15%;">'
           +'<col style="width:15%;">'
           + '<col style="width:15%;">'
           +'<col style="width:2%;">'
           +'<col style="width:20%;">'
           +'<col style="width:15%;">'
           + '</colgroup>';

        h += '<tr>'
           + '<td style="' + L + '">Group / Client</td>'
           + '<td colspan="3" style="' + V + '">' + vals.clientGroup + '</td>'
           + '<td style="' + E + '"></td>'
           + '<td style="' + L + '">Internal rating / Scoring</td>'
           + '<td style="' + V + '">' + vals.internalRatingScoringHtml + '</td>'
           + '</tr>';

        h += '<tr>'
           + '<td style="' + L + '">Type of Deal:</td>'
           + '<td colspan="3" style="' + V + '">' + vals.typeOfDealHtml + '</td>'
           + '<td style="' + E + '"></td>'
           + '<td style="' + L + '">External rating(S&P/Moody\'s/Fitch)</td>'
           + '<td style="' + V + '">' + vals.externalRating + '</td>'
           + '</tr>';

        h += '<tr>'
           + '<td style="' + L + '">Booking</td>'
           + '<td colspan="3" style="' + V + '">' + vals.bookingEFANHtml + '</td>'
           + '<td style="' + E + '"></td>'
           + '<td style="' + L + '">TRI</td>'
           + '<td style="' + V + '">' + vals.triHtml + '</td>'
           + '</tr>';

        h += '<tr>'
           + '<td style="' + L + '">Product Area</td>'
           + '<td colspan="3" style="' + V + '">' + vals.productArea + '</td>'
           + '<td style="' + E + '"></td>'
           + '<td colspan="2" style="' + E + '"></td>'
           + '</tr>';

        h += '<tr><td colspan="7" style="height:6px;"></td></tr>';

        // Deal Amount Mn is omitted (label + value replaced with blank cells) for Threshold Type = Local.
        h += '<tr>'
           + '<td style="' + L + '">Tenor</td>'
           + '<td style="' + L + '">Currency</td>'
           + (vals.isLocal ? ('<td style="' + E + '"></td>') : ('<td style="' + L + '">Deal Amount Mn</td>'))
           + '<td style="' + L + '">BBVA Commit. Mn</td>'
           + '<td colspan="2" style="' + L + '">All in: Drawn | Undrawn</td>'
           + '<td style="' + L + '">Capital Action</td>'
           + '</tr>';

        h += '<tr>'
           + '<td style="' + V + '">' + vals.tenorHtml + '</td>'
           + '<td style="' + V + '">' + vals.currencyCodeHtml + '</td>'
           + (vals.isLocal ? ('<td style="' + E + '"></td>') : ('<td style="' + V + '">' + vals.dealAmountHtml + '</td>'))
           + '<td style="' + V + '">' + vals.bbvaCommitHtml + '</td>'
           + '<td colspan="2" style="' + V + '">' + vals.allInDrawnHtml + '</td>'
           + '<td style="' + V + '">' + vals.capitalActionHtml + '</td>'
           + '</tr>';

        h += '<tr><td colspan="7" style="height:6px;"></td></tr>';

        // Last Visit to the Client is always hidden in GTB.
        h += '<tr>'
           + '<td style="' + L + '">Banker</td>'
           + '<td colspan="3" style="' + V + '">' + vals.bankerNameHtml + '</td>'
           + '<td style="' + E + '"></td>'
           + '</tr>';

        // Commitment Deadline is additionally omitted for Threshold Type = Local. Prospect is always hidden in GTB.
        h += '<tr>'
           + '<td style="' + L + '">Sector Head</td>'
           + '<td style="' + V + '">' + vals.sectorHeadLbl + '</td>'
           + (vals.isLocal
                ? ('<td style="' + E + '"></td>' + '<td style="' + E + '"></td>')
                : ('<td style="' + L + ' text-align:right;">Commit. Deadline&nbsp;</td>' + '<td style="' + V + '">' + vals.commitDeadlineHtml + '</td>'))
           + '<td style="' + E + '"></td>'
           + '</tr>';

        // Under X-Sell Monitoring is always hidden in GTB.
        h += '<tr>'
           + '<td style="' + L + '">Industry</td>'
           + '<td colspan="3" style="' + V + '">' + vals.industryLbl + '</td>'
           + '<td style="' + E + '"></td>'
           + '</tr>';

        h += '</table></div>';
        return h;
    }
}