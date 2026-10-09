public without sharing class DMT_NBC_OpportunityInfoRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_TrackedComponent {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos_Line = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfos_Opportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id treasuryId = rtInfos_Line.get('TreasurySettlement').getRecordTypeId();
        Id otherId = rtInfos_Line.get('OtherProducts').getRecordTypeId();
        Id sanctionId = rtInfos_Line.get('Sanction').getRecordTypeId();
        Id dmtOpportunityId = rtInfos_Opportunity.get('DMT_Opportunity').getRecordTypeId();

        recordTypeRenderers.put(dmtOpportunityId, new DMT_NBC_OppInfoRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Opportunity Info NBC renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderHtml(data);
        } catch (Exception e){
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }

    // CIBGLOBALD-4117 - routes to the record type's own renderer; only DMT_Opportunity has one today.
    public Boolean isComponentTracked() {
        return true;
    }

    public List<String> getTrackedFields(SObject record) {
        Id recordTypeId = (Id) record.get('RecordTypeId');
        DMT_ViewRenderer renderer = recordTypeRenderers.get(recordTypeId);
        if (renderer instanceof DMT_FieldTrackableRenderer) {
            return ((DMT_FieldTrackableRenderer) renderer).getTrackedFields(record);
        }
        return new List<String>();
    }
}