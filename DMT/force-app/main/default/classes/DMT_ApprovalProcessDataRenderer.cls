/**
 * Routes the "Approval Process Data" component to the renderer for the record type being viewed.
 *
 *   TreasurySettlement -> DMT_TreasuryApprovalProcessDataRenderer (DisplayField-based)
 *   OtherProducts      -> DMT_OtherApprovalProcessDataRenderer    (DisplayField-based)
 *   DMT_Opportunity    -> DMT_OppApprovalProcessDataRenderer      (multi-object - see its header)
 *   Sanction           -> DMT_LineSancAppProcessDataRenderer      (not watched)
 *
 * See DMT_InfoRenderer for the field-tracking maintenance rules; the Line record types here follow
 * the same DisplayField convention.
 */
public without sharing class DMT_ApprovalProcessDataRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_TrackedComponent {
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
        Id sanctionId = rtInfos.get('Sanction').getRecordTypeId();

        recordTypeRenderers.put(treasuryId, new DMT_TreasuryApprovalProcessDataRenderer());
        recordTypeRenderers.put(otherId, new DMT_OtherApprovalProcessDataRenderer());
        recordTypeRenderers.put(dmtOpportunityId, new DMT_OppApprovalProcessDataRenderer());
        recordTypeRenderers.put(sanctionId, new DMT_LineSancAppProcessDataRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try{
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Approval Process renderer for record type Id: ' + data.recordTypeId);
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