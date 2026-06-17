public with sharing class DMT_ProductSimpleRenderer implements DMT_ViewRenderer {
    private static Map<String, DMT_ViewRenderer> recordTypeRenderers = new Map<String, DMT_ViewRenderer>();
    private static Id treasuryId;
    private static Id otherId;
    private static Id dmtOpportunityId;
    private static Id sanctionId;

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfosOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        treasuryId = rtInfos.get('TreasurySettlement').getRecordTypeId();
        otherId = rtInfos.get('OtherProducts').getRecordTypeId();
        dmtOpportunityId = rtInfosOpportunity.get('DMT_Opportunity').getRecordTypeId();
        sanctionId = rtInfos.get('Sanction').getRecordTypeId();

       
        recordTypeRenderers.put(dmtOpportunityId, new DMT_OppProductSimpleRenderer()); 
        
  
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try{
            DMT_ViewRenderer renderer;
          renderer = recordTypeRenderers.get(data.recordTypeId);
            

            if (renderer == null) {
                throw new IllegalArgumentException('No ProductSimple renderer for record type Id: ' + data.recordTypeId);
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
           
                renderer = recordTypeRenderers.get(data.recordTypeId);
            

            if (renderer == null) {
                throw new IllegalArgumentException('No ProductSimple renderer for record type Id: ' + data.recordTypeId);
            }

            return renderer.renderPdfJson(data);
        } catch (Exception e){
            System.debug(e.getMessage());
            return new Map<String, Object>();
        }
    }
}