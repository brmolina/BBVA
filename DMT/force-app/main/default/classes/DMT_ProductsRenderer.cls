public with sharing class DMT_ProductsRenderer implements DMT_ViewRenderer {
    private static Map<String, DMT_ViewRenderer> recordTypeRenderers = new Map<String, DMT_ViewRenderer>();
    private static Id treasuryId;
    private static Id otherId;
    private static Id dmtOpportunityId;

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfosOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        treasuryId = rtInfos.get('TreasurySettlement').getRecordTypeId();
        otherId = rtInfos.get('OtherProducts').getRecordTypeId();
        dmtOpportunityId = rtInfosOpportunity.get('DMT_Opportunity').getRecordTypeId();
        recordTypeRenderers.put(treasuryId, new DMT_TreasuryProductsRenderer());
        recordTypeRenderers.put(otherId, new DMT_OtherProductsRenderer());
        recordTypeRenderers.put('treasuryProductsCO', new DMT_TreasuryProductsRenderer_CO());
        recordTypeRenderers.put('treasuryProductsPE', new DMT_TreasuryProductsRenderer_PE());
        recordTypeRenderers.put(dmtOpportunityId, new DMT_OpportunityProductsRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try{
            DMT_ViewRenderer renderer;
            if (data.recordTypeId == treasuryId && data.line.Booking_Geography__c == 'CO') {
                renderer = recordTypeRenderers.get('treasuryProductsCO');
            } else if (data.recordTypeId == treasuryId && data.line.Booking_Geography__c == 'PE') {
                renderer = recordTypeRenderers.get('treasuryProductsPE');
            } else {
                renderer = recordTypeRenderers.get(data.recordTypeId);
            }

            if (renderer == null) {
                throw new IllegalArgumentException('No Products renderer for record type Id: ' + data.recordTypeId);
            }

            return renderer.renderHtml(data);
        } catch (Exception e){
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return new Map<String, Object>();
        }
        try{
            DMT_ViewRenderer renderer;
            if (data.recordTypeId == treasuryId && data.line.Booking_Geography__c == 'CO') {
                renderer = recordTypeRenderers.get('treasuryProductsCO');
            } else if (data.recordTypeId == treasuryId && data.line.Booking_Geography__c == 'PE') {
                renderer = recordTypeRenderers.get('treasuryProductsPE');
            } else {
                renderer = recordTypeRenderers.get(data.recordTypeId);
            }

            if (renderer == null) {
                throw new IllegalArgumentException('No Products renderer for record type Id: ' + data.recordTypeId);
            }

            return renderer.renderPdfJson(data);
        } catch (Exception e){
            System.debug(e.getMessage());
            return new Map<String, Object>();
        }
    }
}