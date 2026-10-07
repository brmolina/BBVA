/**
 * Routes the "Client" component to the renderer for the record type being viewed.
 *
 *   TreasurySettlement -> DMT_DefaultClientRenderer      (CLIENT_TABLE_COLUMN_FIELDS)
 *   OtherProducts      -> DMT_OtherClientRenderer        (CLIENT_TABLE_COLUMN_FIELDS)
 *   DMT_Opportunity    -> DMT_OpportunityClientRenderer  (DisplayField-based)
 *   Sanction           -> DMT_LineSanctionClientRenderer (not watched)
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * ADDING OR REMOVING A FIELD IN ANY CLIENT RENDERER - READ THIS FIRST
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * The fields these renderers DISPLAY are the fields the approval-restart mechanism WATCHES. When
 * a watched field changes while a Line/Opportunity is resubmitted, its open approval tasks are
 * cancelled and recreated so the approver reviews the new value.
 *
 * So the watched list must move with the displayed field. Follow whichever way the renderer you
 * are editing already does it:
 *
 *   1. DisplayField-based (DMT_OpportunityClientRenderer)
 *      Pass the field API name, qualified with its object (getTrackedFieldsByObject() splits on the
 *      first '.'), as the THIRD argument when building the DisplayField:
 *          new DMT_FormattingUtils.DisplayField('Scoring', value, new List<String>{'DMT_Opportunity_Client__c.DMT_Scoring__c'})
 *      Omit it and the field renders but is never watched. Omit the object prefix and it is watched
 *      under the wrong key instead - just as silent, so check the object name matches a real one.
 *
 *   2. Column-constant based (DMT_DefaultClientRenderer, DMT_OtherClientRenderer)
 *      Add the field to that renderer's CLIENT_TABLE_COLUMN_FIELDS. That one list drives both the
 *      rendered table columns and the watched list.
 *
 * Reading a CHILD object too? Declare it in getChildSections() - see
 * DMT_MultiObjectFieldTrackableRenderer.
 *
 * A field displayed but deliberately NOT watched (a derived value, or a parent-object field)
 * should say so where it is built - see DMT_OpportunityClientRenderer.
 *
 * A renderer implementing neither tracking interface is simply not watched, as Sanction is today.
 * That is intentional; there is no list anywhere of which record types are tracked.
 *
 * CIBGLOBALD-4117 - DMT_DefaultClientRenderer/DMT_OtherClientRenderer/DMT_OpportunityClientRenderer
 * also implement DMT_CalloutTrackableRenderer, for HPG-sourced values never written to any
 * Salesforce field, so the DisplayField/column-constant tagging above can't watch them.
 */
public without sharing class DMT_ClientRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_TrackedComponent, DMT_CalloutTrackableRenderer {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    public Boolean isComponentTracked() {
        return true;
    }

    static {
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

    // CIBGLOBALD-4117: The three methods below only route. Every declaration lives on the record type's own
    // renderer - see the class header.
    public List<String> getTrackedFields(SObject record) {
        Id recordTypeId = (Id) record.get('RecordTypeId');
        DMT_ViewRenderer renderer = recordTypeRenderers.get(recordTypeId);
        if (renderer == null) {
            System.debug(LoggingLevel.WARN, '[DMT_ClientRenderer.getTrackedFields] No Client renderer registered for record type Id: ' + recordTypeId);
            return new List<String>();
        }
        if (renderer instanceof DMT_FieldTrackableRenderer) {
            return ((DMT_FieldTrackableRenderer) renderer).getTrackedFields(record);
        }
        return new List<String>();
    }

    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        Id recordTypeId = (Id) record.get('RecordTypeId');
        DMT_ViewRenderer renderer = recordTypeRenderers.get(recordTypeId);
        if (renderer == null) {
            System.debug(LoggingLevel.WARN, '[DMT_ClientRenderer.getTrackedFieldsByObject] No Client renderer registered for record type Id: ' + recordTypeId);
            return new Map<String, List<String>>();
        }
        if (renderer instanceof DMT_MultiObjectFieldTrackableRenderer) {
            return ((DMT_MultiObjectFieldTrackableRenderer) renderer).getTrackedFieldsByObject(record);
        }
        return new Map<String, List<String>>();
    }

    public List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record) {
        Id recordTypeId = (Id) record.get('RecordTypeId');
        DMT_ViewRenderer renderer = recordTypeRenderers.get(recordTypeId);
        if (renderer == null) {
            System.debug(LoggingLevel.WARN, '[DMT_ClientRenderer.getChildSections] No Client renderer registered for record type Id: ' + recordTypeId);
            return new List<DMT_ApprovalChangeStep_Helper.ChildSection>();
        }
        if (renderer instanceof DMT_MultiObjectFieldTrackableRenderer) {
            return ((DMT_MultiObjectFieldTrackableRenderer) renderer).getChildSections(record);
        }
        return new List<DMT_ApprovalChangeStep_Helper.ChildSection>();
    }

    // CIBGLOBALD-4117 - mirrors DMT_ClientNBCRenderer's calloutRendererFor() pattern. Sanction has no
    // DMT_CalloutTrackableRenderer implementation to route to, same as its field-tracking above.
    public String getCalloutCacheKey(SObject record) {
        DMT_CalloutTrackableRenderer renderer = calloutRendererFor(record);
        return renderer == null ? null : renderer.getCalloutCacheKey(record);
    }

    public Map<String, Object> fetchLiveTrackedValues(SObject record) {
        DMT_CalloutTrackableRenderer renderer = calloutRendererFor(record);
        return renderer == null ? new Map<String, Object>() : renderer.fetchLiveTrackedValues(record);
    }

    // record is only guaranteed to carry its Id (see DMT_CalloutTrackableRenderer) - a record queried
    // without RecordTypeId throws SObjectException on a bare .get(), not null, so isSet() guards the
    // read; an async job's bare shell (Id only, never queried) is safe either way.
    private DMT_CalloutTrackableRenderer calloutRendererFor(SObject record) {
        Id recordTypeId = record.isSet('RecordTypeId') ? (Id) record.get('RecordTypeId') : null;
        if (recordTypeId == null && record.Id != null) {
            // Dynamic SOQL only binds a simple variable name, not a dotted expression like
            // :record.Id (that syntax only works in static/bracket SOQL) - assign it to its own
            // variable first.
            Id recordId = record.Id;
            String objectApiName = recordId.getSObjectType().getDescribe().getName();
            SObject queried = Database.query('SELECT RecordTypeId FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1');
            recordTypeId = (Id) queried.get('RecordTypeId');
        }
        DMT_ViewRenderer renderer = recordTypeRenderers.get(recordTypeId);
        return (renderer instanceof DMT_CalloutTrackableRenderer) ? (DMT_CalloutTrackableRenderer) renderer : null;
    }
}