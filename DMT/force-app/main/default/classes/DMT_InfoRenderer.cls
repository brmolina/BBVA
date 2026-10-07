/**
 * Routes the "Line Info" / "Opportunity Info" / "Approval Info" components to the renderer for the
 * record type being viewed.
 *
 *   TreasurySettlement -> DMT_TreasuryLineInfoRenderer
 *   OtherProducts      -> DMT_OtherLineInfoRenderer
 *   DMT_Opportunity    -> DMT_OpportunityInfoRenderer
 *   Sanction           -> DMT_LineSanctionApprovalInfoRenderer
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * ADDING OR REMOVING A FIELD IN ANY INFO RENDERER - READ THIS FIRST
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * The fields these renderers DISPLAY are the fields the approval-restart mechanism WATCHES. When
 * a watched field changes while a Line/Opportunity is resubmitted, its open approval tasks are
 * cancelled and recreated so the approver reviews the new value.
 *
 * So the watched list must move with the displayed field. Every Info renderer is DisplayField-based,
 * so pass the field API name as the THIRD argument when building it:
 *     new DMT_FormattingUtils.DisplayField('Name:', value, new List<String>{'Name'})
 * Omit it and the field renders but is never watched.
 *
 * A field watched but NOT displayed is added explicitly in getTrackedFields() with a comment
 * saying why - see DMT_TreasuryLineInfoRenderer.
 *
 * A renderer implementing neither tracking interface is simply not watched. That is intentional;
 * there is no list anywhere of which record types are tracked.
 *
 * (The Client renderers do the same job a second way, via a column constant - see
 * DMT_ClientRenderer.)
 */
public without sharing class DMT_InfoRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_TrackedComponent {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    public Boolean isComponentTracked() {
        return true;
    }

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos_Line = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfos_Opportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id treasuryId = rtInfos_Line.get('TreasurySettlement').getRecordTypeId();
        Id otherId = rtInfos_Line.get('OtherProducts').getRecordTypeId();
        Id sanctionId = rtInfos_Line.get('Sanction').getRecordTypeId();
        Id dmtOpportunityId = rtInfos_Opportunity.get('DMT_Opportunity').getRecordTypeId();
        recordTypeRenderers.put(treasuryId, new DMT_TreasuryLineInfoRenderer());
        recordTypeRenderers.put(otherId, new DMT_OtherLineInfoRenderer());
        recordTypeRenderers.put(dmtOpportunityId, new DMT_OpportunityInfoRenderer());
        recordTypeRenderers.put(sanctionId, new DMT_LineSanctionApprovalInfoRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Info renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderHtml(data);
        } catch (Exception e){
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }

    public List<String> getTrackedFields(SObject record) {
        Id recordTypeId = (Id) record.get('RecordTypeId');
        DMT_ViewRenderer renderer = recordTypeRenderers.get(recordTypeId);
        if (renderer == null) {
            System.debug(LoggingLevel.WARN, '[DMT_InfoRenderer.getTrackedFields] No Info renderer registered for record type Id: ' + recordTypeId);
            return new List<String>();
        }
        if (renderer instanceof DMT_FieldTrackableRenderer) {
            return ((DMT_FieldTrackableRenderer) renderer).getTrackedFields(record);
        }
        return new List<String>();
    }
}