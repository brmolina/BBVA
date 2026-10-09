public without sharing class DMT_BasicRequirementRenderer implements DMT_ViewRenderer {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    static {
        Map<String, Schema.RecordTypeInfo> rtInfosOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id dmtOpportunityId = rtInfosOpportunity.get('DMT_Opportunity').getRecordTypeId();

        recordTypeRenderers.put(dmtOpportunityId, new DMT_OppBasicRequirementRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Basic Requirement renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderHtml(data);
        } catch (Exception e) {
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }
}