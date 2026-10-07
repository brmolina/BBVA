public without sharing class DMT_ClientNBCRenderer implements DMT_ViewRenderer, DMT_TrackedComponent, DMT_CalloutTrackableRenderer {
    private static Map<Id, DMT_ViewRenderer> recordTypeRenderers = new Map<Id, DMT_ViewRenderer>();

    static {
        Map<String, Schema.RecordTypeInfo> rtInfos_Line = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtInfos_Opportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        Id treasuryId = rtInfos_Line.get('TreasurySettlement').getRecordTypeId();
        Id otherId = rtInfos_Line.get('OtherProducts').getRecordTypeId();
        Id sanctionId = rtInfos_Line.get('Sanction').getRecordTypeId();
        Id dmtOpportunityId = rtInfos_Opportunity.get('DMT_Opportunity').getRecordTypeId();

        recordTypeRenderers.put(dmtOpportunityId, new DMT_OppClientNBCRenderer());
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try {
            DMT_ViewRenderer renderer = recordTypeRenderers.get(data.recordTypeId);
            if (renderer == null) {
                throw new IllegalArgumentException('No Opportunity Client NBC renderer for record type Id: ' + data.recordTypeId);
            }
            return renderer.renderHtml(data);
        } catch (Exception e){
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }

    // CIBGLOBALD-4117 - opts this delegator into the approval-restart watch gate. Only
    // DMT_OppClientNBCRenderer currently backs a DMT_CalloutTrackableRenderer implementation; the
    // other record types simply have nothing to check yet.
    public Boolean isComponentTracked() {
        return true;
    }

    public String getCalloutCacheKey(SObject record) {
        DMT_CalloutTrackableRenderer renderer = calloutRendererFor(record);
        return renderer == null ? null : renderer.getCalloutCacheKey(record);
    }

    public Map<String, Object> fetchLiveTrackedValues(SObject record) {
        DMT_CalloutTrackableRenderer renderer = calloutRendererFor(record);
        return renderer == null ? new Map<String, Object>() : renderer.fetchLiveTrackedValues(record);
    }

    // record is only guaranteed to carry its Id (see DMT_CalloutTrackableRenderer) - a record
    // queried without RecordTypeId throws SObjectException on a bare .get(), not null, so isSet()
    // guards the read; an async job's bare shell (Id only, never queried) is safe either way.
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