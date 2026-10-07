public without sharing class DMT_NBC_ApprovalProcessRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_TrackedComponent {
   private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfosOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id treasuryId = rtInfos.get('TreasurySettlement').getRecordTypeId();
        Id otherId = rtInfos.get('OtherProducts').getRecordTypeId();
        Id dmtOpportunityId = rtInfosOpportunity.get('DMT_Opportunity').getRecordTypeId();
        Id sanctionId = rtInfos.get('Sanction').getRecordTypeId();

  
        recordTypeRenderers.put(dmtOpportunityId, new DMT_NBC_OppApprovalProcessRenderer());

    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Approval Process  renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderHtml(data);
        } catch (Exception e) {
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