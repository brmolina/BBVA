// CIBGLOBALD-4117: tracked-field methods route by record type only, same as renderHtml. Treasury and
// OtherProducts are not wired to a Participants renderer at all (commented out below, matching
// renderHtml) - instanceof against a null map lookup returns false, so they correctly contribute
// nothing rather than throwing.
public without sharing class DMT_ParticipantRenderer implements DMT_ViewRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_TrackedComponent {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    public Boolean isComponentTracked() {
        return true;
    }

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfosOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id treasuryId = rtInfos.get('TreasurySettlement').getRecordTypeId();
        Id otherId = rtInfos.get('OtherProducts').getRecordTypeId();
        Id sanctionId = rtInfos.get('Sanction').getRecordTypeId();
        Id dmtOpportunityId = rtInfosOpportunity.get('DMT_Opportunity').getRecordTypeId();
        
       // recordTypeRenderers.put(treasuryId, new DMT_DefaultParticipantRenderer());
       // recordTypeRenderers.put(otherId, new DMT_DefaultParticipantRenderer());
        recordTypeRenderers.put(sanctionId, new DMT_DefaultParticipantRenderer());
        recordTypeRenderers.put(dmtOpportunityId, new DMT_DefaultParticipantRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Participant renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderHtml(data);
        } catch (Exception e) {
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }

    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        DMT_ViewRenderer renderer = recordTypeRenderers.get((Id) record.get('RecordTypeId'));
        if (renderer instanceof DMT_MultiObjectFieldTrackableRenderer) {
            return ((DMT_MultiObjectFieldTrackableRenderer) renderer).getTrackedFieldsByObject(record);
        }
        return new Map<String, List<String>>();
    }

    public List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record) {
        DMT_ViewRenderer renderer = recordTypeRenderers.get((Id) record.get('RecordTypeId'));
        if (renderer instanceof DMT_MultiObjectFieldTrackableRenderer) {
            return ((DMT_MultiObjectFieldTrackableRenderer) renderer).getChildSections(record);
        }
        return new List<DMT_ApprovalChangeStep_Helper.ChildSection>();
    }
}