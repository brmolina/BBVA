public with sharing class DMT_PassportProcessFlowRenderer implements DMT_ViewRenderer {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfosOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id treasuryId = rtInfos.get('TreasurySettlement').getRecordTypeId();
        Id otherId = rtInfos.get('OtherProducts').getRecordTypeId();
        Id dmtOpportunityId = rtInfosOpportunity.get('DMT_Opportunity').getRecordTypeId();
        Id sanctionId = rtInfos.get('Sanction').getRecordTypeId();

        recordTypeRenderers.put(treasuryId, new DMT_DefaultPassportProcessFlowRenderer());
        recordTypeRenderers.put(otherId, new DMT_DefaultPassportProcessFlowRenderer());
        recordTypeRenderers.put(dmtOpportunityId, new DMT_DefaultPassportProcessFlowRenderer());
        recordTypeRenderers.put(sanctionId, new DMT_OtherLineInfoRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Passport Process renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderHtml(data);
        } catch (Exception e) {
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return new Map<String, Object>();
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Passport Process renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderPdfJson(data);
        } catch (Exception e){
            System.debug(e.getMessage());
            return new Map<String, Object>();
        }
    }
}