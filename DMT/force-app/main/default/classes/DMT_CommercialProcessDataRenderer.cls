public without sharing class DMT_CommercialProcessDataRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_TrackedComponent {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    public Boolean isComponentTracked() {
        return true;
    }

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfosOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id treasuryId = rtInfos.get('TreasurySettlement').getRecordTypeId();
        Id otherId = rtInfos.get('OtherProducts').getRecordTypeId();
        Id dmtOpportunityId = rtInfosOpportunity.get('DMT_Opportunity').getRecordTypeId();
        recordTypeRenderers.put(dmtOpportunityId, new DMT_OppCommercialProcessDataRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try{
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Commercial Process renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderHtml(data);
        } catch (Exception e) {
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }

    public List<String> getTrackedFields(SObject record) {
        DMT_ViewRenderer renderer = recordTypeRenderers.get((Id) record.get('RecordTypeId'));
        if (renderer instanceof DMT_FieldTrackableRenderer) {
            return ((DMT_FieldTrackableRenderer) renderer).getTrackedFields(record);
        }
        return new List<String>();
    }
}