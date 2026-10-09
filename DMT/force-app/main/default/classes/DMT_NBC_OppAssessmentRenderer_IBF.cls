public without sharing class DMT_NBC_OppAssessmentRenderer_IBF implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_CalloutTrackableRenderer {
    // ====================================================================================================
    // DATA WRAPPER (centralizes values for HTML and PDF)
    // ====================================================================================================
    private class AssessmentData {
        public String reputationalRisk = '';
        public String eqPrinScope = '';
        public String eqPrinCat = '';
        public String infraFact = '';
        public String envSocFrame = '';
        public String expThermalCoal = '';
        public String capWeight = '';
        public String source = '';
        public String coalPhaseOut = '';
        public String kpiMarginAdj = '';
        public String sustainableDeal = '';

        public AssessmentData(DMT_ViewController.LineDataWrapper data) {

            this.reputationalRisk = DMT_FormattingUtils.checkNull(data.toolkitData.reputationalRisk);
            this.eqPrinScope = DMT_FormattingUtils.checkNull(data.oppClient.DMT_equator_Principles__c);
            this.eqPrinCat = DMT_FormattingUtils.checkNull(data.oppClient.DMT_equator_Principles_Category__c);
            this.infraFact = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Infrastructure_Supporting_Factor__c);
            this.expThermalCoal = DMT_FormattingUtils.checkNull(data.toolkitData.exposureThermalCoal);
            this.capWeight = DMT_FormattingUtils.checkNull(data.toolkitData.capacityWeight);
            this.source = DMT_FormattingUtils.checkNull(data.toolkitData.exposureIndicatorSource);
            this.coalPhaseOut = DMT_FormattingUtils.checkNull(data.toolkitData.coalPhaseOutPlan);
            this.kpiMarginAdj = DMT_FormattingUtils.checkNull(data.oppClient.DMT_KPI_Margin_Adjustment__c);
            this.sustainableDeal = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Sustainable_Deal__c);
        }
    }

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - mirrors AssessmentData's field reads. Folds getTrackedFields() in under
    // 'Opportunity' here too - DMT_ApprovalChangeStep_Handler.resolveTrackedFieldsForItems uses
    // getTrackedFieldsByObject() exclusively the instant it's non-empty, never falling back to
    // getTrackedFields() on its own, so this renderer has to self-include its own switch fields to
    // stay complete.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Client__c' => new List<String>{
                'DMT_equator_Principles__c', 'DMT_Equator_Principles_Category__c',
                'DMT_Infrastructure_Supporting_Factor__c', 'DMT_KPI_Margin_Adjustment__c',
                'DMT_Sustainable_Deal__c'
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
                'NBC Assessment', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            )
        };
    }

    public String getCalloutCacheKey(SObject record) {
        return record.Id;
    }

    // CIBGLOBALD-4117 - not a real HTTP callout: reuses this interface's generic derived-value diff
    // machinery because these 5 values are computed by the cstk managed package (ComponentNBC_Controller
    // .preloadToolkitInfo -> cstk.Toolkit_Service.getNbcInfo), not read directly off any queryable
    // field on the Opportunity/Account/DMT_Opportunity_Client__c chain.
    public Map<String, Object> fetchLiveTrackedValues(SObject record) {
        Map<String, Object> values = new Map<String, Object>();
        Opportunity opp = [
            SELECT AccountId, Account.DES_Client_Type__c, Account.DES_Main_Parent__c
            FROM Opportunity
            WHERE Id = :record.Id
        ];
        DES_Template__c toolkitTemplate = new DES_Template__c();
        ComponentNBC_Controller.preloadToolkitInfo(opp, toolkitTemplate);
        values.put('reputationalRisk', toolkitTemplate.Reputational_Risk_type__c);
        values.put('exposureThermalCoal', toolkitTemplate.cstk_g_thermal_coal_exps_ind_type__c);
        values.put('capacityWeight', toolkitTemplate.cstk_gf_thermal_coal_prod_wg_per__c);
        values.put('exposureIndicatorSource', toolkitTemplate.cstk_g_thermal_coal_exps_i_src_type__c);
        values.put('coalPhaseOutPlan', toolkitTemplate.cstk_g_coal_prgrsv_red_pl_ind_type__c);
        return values;
    }

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }

            AssessmentData vals = new AssessmentData(data);

            String html = '<div style="font-family: Arial, sans-serif; font-size: 11px; margin-bottom: 20px; page-break-inside: avoid;">'

                        + '<div style="background-color: #1a62a5; color: #ffffff; padding: 6px 10px; font-size: 12px; font-weight: bold; text-transform: uppercase; margin-bottom: 15px;">'
                        + 'SUSTAINABLE FINANCE'
                        + '</div>'

                        + '<div style="color: #004481; font-size: 11px; font-weight: bold; margin-bottom: 8px;">'
                        + 'ASSESSMENT'
                        + '</div>'

                        + '<table style="width: 100%; border-collapse: collapse; table-layout: fixed;">'
                        + '<colgroup>'
                        + '<col style="width: 35%;">'
                        + '<col style="width: 65%;">'
                        + '</colgroup>'

                        + generateHtmlRow('Reputational risk', vals.reputationalRisk)
                        + generateHtmlRow('Equator Principles Scope', vals.eqPrinScope)
                        + generateHtmlRow('Equator Principles Category', vals.eqPrinCat)
                        + generateHtmlRow('Infrastructure supporting factor', vals.infraFact)
                        + generateHtmlRow('Environmental and Social Framework', vals.envSocFrame)
                        + generateHtmlRow('Does the group have exposure to thermal coal?', vals.expThermalCoal)
                        + generateHtmlRow('Capacity weight', vals.capWeight)
                        + generateHtmlRow('Source', vals.source)
                        + generateHtmlRow('Does the company have a coal phase-out plan?', vals.coalPhaseOut)
                        + generateHtmlRow('KPI-Link Margin Adjustment', vals.kpiMarginAdj)
                        + generateHtmlRow('Sustainable Deal', vals.sustainableDeal)

                        + '</table>'
                        + '</div>';

            return html;

        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppAssessmentRenderer_IBF renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String generateHtmlRow(String label, String value) {
        String displayValue = String.isBlank(value) ? '&nbsp;' : value;
        return '<tr>'
             + '<td style="color: #004481; padding: 6px 10px 6px 20px; vertical-align: middle; border-bottom: 3px solid #ffffff;">' + label + '</td>'
             + '<td style="background-color: #f2f2f2; color: #004481; padding: 6px 10px; vertical-align: middle; border-bottom: 3px solid #ffffff;">' + displayValue + '</td>'
             + '</tr>';
    }
}