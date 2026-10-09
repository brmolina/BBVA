public without sharing class DMT_SustainabilityRenderer implements DMT_ViewRenderer {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos_Opportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id dmtOpportunityId = rtInfos_Opportunity.get('DMT_Opportunity').getRecordTypeId();
        recordTypeRenderers.put(dmtOpportunityId, new DMT_OpportunitySustainabilityRenderer());

        Map<String, Schema.RecordTypeInfo> rtInfos_Line = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Id sanctionId = rtInfos_Line.get('Sanction').getRecordTypeId();
        recordTypeRenderers.put(sanctionId, new DMT_OpportunitySustainabilityRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Sustainability renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderHtml(data);
        } catch (Exception e){
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }
}