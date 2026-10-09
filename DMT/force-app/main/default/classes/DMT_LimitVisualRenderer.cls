public without sharing class DMT_LimitVisualRenderer implements DMT_ViewRenderer {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfos_Opportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id treasuryId = rtInfos.get('TreasurySettlement').getRecordTypeId();
        Id otherId = rtInfos.get('OtherProducts').getRecordTypeId();
        Id dmtOpportunityId = rtInfos_Opportunity.get('DMT_Opportunity').getRecordTypeId();
        Id sanctionId = rtInfos.get('Sanction').getRecordTypeId();

        recordTypeRenderers.put(treasuryId, new DMT_DefaultLimitVisualRenderer());
        recordTypeRenderers.put(otherId, new DMT_DefaultLimitVisualRenderer());
        // DMT_Opportunity intentionally routes to DMT_DefaultLimitVisualRenderer (not DMT_OppProfitabilityLimitVisualRenderer):
        // DMT_DefaultLimitVisualRenderer handles consumption limits for all record types and, for Opportunity,
        // additionally appends the Profitability Visual by calling DMT_OppProfitabilityLimitVisualRenderer.renderHtml()
        // statically at the end of its render pass. Routing Opportunity directly to DMT_OppProfitabilityLimitVisualRenderer
        // would lose the consumption limits section entirely.
        recordTypeRenderers.put(dmtOpportunityId, new DMT_DefaultLimitVisualRenderer());
        recordTypeRenderers.put(sanctionId, new DMT_DefaultLimitVisualRenderer());

    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Limit Visual renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderHtml(data);
        } catch (Exception e){
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }
}