public with sharing class DMT_ClientRenderer implements DMT_ViewRenderer {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    static {
        // Initialize with default renderer for all record types
        Map<String, Schema.RecordTypeInfo> rtInfos_Line = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfos_Opportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id treasuryId = rtInfos_Line.get('TreasurySettlement').getRecordTypeId();
        Id otherId = rtInfos_Line.get('OtherProducts').getRecordTypeId();
        Id dmtOpportunityId = rtInfos_Opportunity.get('DMT_Opportunity').getRecordTypeId();
        Id sanctionId = rtInfos_Line.get('Sanction').getRecordTypeId();

        recordTypeRenderers.put(treasuryId, new DMT_DefaultClientRenderer());
        recordTypeRenderers.put(otherId, new DMT_OtherClientRenderer());
        recordTypeRenderers.put(dmtOpportunityId, new DMT_OpportunityClientRenderer());
        recordTypeRenderers.put(sanctionId, new DMT_LineSanctionClientRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.RecordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Client renderer for record type Id: ' + data.RecordTypeId);
            }
            return renderer.renderHtml(data);
        } catch (Exception e) {
            System.debug('No Client renderer for record type: ' + data.recordTypeId);
            return '<div>Error: No Client renderer for record type: ' + data.recordTypeId + '</div>';
        }
    }

     public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return new Map<String,Object>();
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.RecordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Client renderer for record type Id: ' + data.RecordTypeId);
            }
            return renderer.renderPdfJson(data);
        } catch (Exception e){
            System.debug(e.getMessage());
            return new Map<String, Object>();
        }
    }
}