// CIBGLOBALD-4117: Factory -> Delegator -> Renderer - this delegator holds no field/section
// knowledge of its own. Tracked-field methods route through the same resolveRenderer() that
// renderHtml uses (RecordTypeId, plus Booking_Geography__c for Treasury), and ask whichever single
// renderer is active what it tracks - never a hand-maintained union across geography variants. If
// Booking_Geography__c changes (e.g. CO -> MX), that is itself caught because the frozen data was
// built by the old variant and this call now compares against the new one, same reasoning as every
// NBC IBF/GTB delegator.
// OtherProducts (DMT_OtherProductsRenderer) and Sanction (DMT_LineSanctionProductsRenderer) both
// render through DMT_ProductMetadataRenderService, a dynamic per-product-type CMDT-driven metadata
// system - both now implement the tracking interfaces too, resolving their CMDT-configured fields
// generically via DMT_ProductMetadataRenderService.getConfiguredFieldsByObject() (see either
// renderer's header for how a computed display value maps back to its real stored field). All four
// Products record types are tracked by a renderer.
public without sharing class DMT_ProductsRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_TrackedComponent {
    private static Map<String, DMT_ViewRenderer> recordTypeRenderers = new Map<String, DMT_ViewRenderer>();

    public Boolean isComponentTracked() {
        return true;
    }

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

        recordTypeRenderers.put(treasuryId, new DMT_TreasuryProductsRenderer());
        recordTypeRenderers.put(otherId, new DMT_OtherProductsRenderer());
        recordTypeRenderers.put('treasuryProductsCO', new DMT_TreasuryProductsRenderer_CO());
        recordTypeRenderers.put('treasuryProductsPE', new DMT_TreasuryProductsRenderer_PE());
        recordTypeRenderers.put('treasuryProductsMX', new DMT_TreasuryProductsRenderer_MX());
        recordTypeRenderers.put(dmtOpportunityId, new DMT_OpportunityProductsRenderer());
        recordTypeRenderers.put(sanctionId, new DMT_LineSanctionProductsRenderer());

    }

    // CIBGLOBALD-4117 - shared by renderHtml and every tracked-field method: which renderer is
    // active. recordTypeId/geography come straight off the record.
    private DMT_ViewRenderer resolveRenderer(Id recordTypeId, String bookingGeography) {
        if (recordTypeId == treasuryId && bookingGeography == 'CO') {
            return recordTypeRenderers.get('treasuryProductsCO');
        } else if (recordTypeId == treasuryId && bookingGeography == 'PE') {
            return recordTypeRenderers.get('treasuryProductsPE');
        } else if (recordTypeId == treasuryId && bookingGeography == 'MX') {
            return recordTypeRenderers.get('treasuryProductsMX');
        }
        return recordTypeRenderers.get(recordTypeId);
    }

    // CIBGLOBALD-4117 - tracked-field methods receive a generic SObject that may be an Opportunity
    // (no Booking_Geography__c field at all, not just unqueried - record.get() throws "Invalid
    // field", not the usual "not queried" SObjectException). Only read it once we already know the
    // record is a DMT_Line__c with the Treasury record type, same guard renderHtml gets for free
    // from its statically-typed data.line?.Booking_Geography__c access.
    private DMT_ViewRenderer resolveRenderer(SObject record) {
        Id recordTypeId = (Id) record.get('RecordTypeId');
        String bookingGeography = recordTypeId == treasuryId ? (String) record.get('Booking_Geography__c') : null;
        return resolveRenderer(recordTypeId, bookingGeography);
    }

    public List<String> getTrackedFields(SObject record) {
        DMT_ViewRenderer renderer = resolveRenderer(record);
        if (renderer instanceof DMT_FieldTrackableRenderer) {
            return ((DMT_FieldTrackableRenderer) renderer).getTrackedFields(record);
        }
        return new List<String>();
    }

    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        DMT_ViewRenderer renderer = resolveRenderer(record);
        if (renderer instanceof DMT_MultiObjectFieldTrackableRenderer) {
            return ((DMT_MultiObjectFieldTrackableRenderer) renderer).getTrackedFieldsByObject(record);
        }
        return new Map<String, List<String>>();
    }

    public List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record) {
        DMT_ViewRenderer renderer = resolveRenderer(record);
        if (renderer instanceof DMT_MultiObjectFieldTrackableRenderer) {
            return ((DMT_MultiObjectFieldTrackableRenderer) renderer).getChildSections(record);
        }
        return new List<DMT_ApprovalChangeStep_Helper.ChildSection>();
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Error: Data not provided</div>';
        }
        try{
            DMT_ViewRenderer renderer = resolveRenderer(data.recordTypeId, data.line?.Booking_Geography__c);

            if (renderer == null) {
                throw new IllegalArgumentException('No Products renderer for record type Id: ' + data.recordTypeId);
            }

            return renderer.renderHtml(data);
        } catch (Exception e){
            System.debug(e.getMessage());
            return '<div>Error: ' + e.getMessage() + '</div>';
        }
    }
}