public without sharing class DMT_OppSustainableFinanceRenderer implements DMT_ViewRenderer {

    // ====================================================================================================
    // HELPERS: Build the lists dynamically for the specific 2-column fields
    // ====================================================================================================
    
    private List<DMT_FormattingUtils.DisplayField> buildRenderFieldsGroup1(DMT_ViewController.LineDataWrapper data) {
        String productArea = data.opportunity.DMT_Product_Area__c;

        if (productArea == 'IB&F') {
            return new List<DMT_FormattingUtils.DisplayField>{
                new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_ReputationalRisk_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_reputational_risk__c)),
                new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_EquatorPrinciples_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_equator_Principles__c)),

                new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_EnviromentalSocialFramework_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Enviromental_Social_Framework__c)),
                new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_GroupHaveExposureToThermalCoal_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Group_Have_Exposure_To_Thermal_Coal__c)),

                new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_CapacityWeight_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Capacity_Weight__c)),
                new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_CompanyHaveACoalPhaseOutPlan_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Company_Have_A_Coal_Phase_Out_Plan__c)),

                new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_KPIMarginAdjustment_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_KPI_Margin_Adjustment__c)),
                new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_TRI_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_tri__c)),

                new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_GroupEngagementPlan_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Group_Engagement_Plan__c))
            };
        }

        if (productArea == 'GTB') {
            return new List<DMT_FormattingUtils.DisplayField>{
                new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_TRI_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_tri__c))
            };
        }

        // Si viene vacío o con otro valor de productArea, no mostrar nada
        return new List<DMT_FormattingUtils.DisplayField>();
    }

    private List<DMT_FormattingUtils.DisplayField> buildRenderFieldsGroup2(DMT_ViewController.LineDataWrapper data) {
        return new List<DMT_FormattingUtils.DisplayField>();
    }

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }
        
        try {
            List<DMT_FormattingUtils.DisplayField> fields = buildRenderFieldsGroup1(data);

            if (fields.isEmpty()) {
                return '';
            }

            String comparisonAccountName = data.oppAccountParentName;

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">' + 'SUSTAINABLE FINANCE' + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '') + '</h2>'
                + '<div class="slds-scope">'
                + DMT_FormattingUtils.generateHtmlTable(fields)
                + '</div></div>&nbsp;</br>';

            return html;
            
        } catch (Exception e) {
            System.debug('Error in DMT_OppSustainableFinanceRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }
}