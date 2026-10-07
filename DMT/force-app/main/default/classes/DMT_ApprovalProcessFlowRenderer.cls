public without sharing class DMT_ApprovalProcessFlowRenderer implements DMT_ViewRenderer {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfosOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id treasuryId = rtInfos.get('TreasurySettlement').getRecordTypeId();
        Id otherId = rtInfos.get('OtherProducts').getRecordTypeId();
        Id sanctionId = rtInfos.get('Sanction').getRecordTypeId();
        Id dmtOpportunityId = rtInfosOpportunity.get('DMT_Opportunity').getRecordTypeId();
        recordTypeRenderers.put(treasuryId, new DMT_DefaultApprovalProcessFlowRenderer());
        recordTypeRenderers.put(otherId, new DMT_DefaultApprovalProcessFlowRenderer());
        recordTypeRenderers.put(sanctionId, new DMT_SanctionOppApprovalProcessRenderer());
        recordTypeRenderers.put(dmtOpportunityId, new DMT_DefaultApprovalProcessFlowRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Approval Process Flow renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderHtml(data);
        } catch (Exception e) {
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }
}