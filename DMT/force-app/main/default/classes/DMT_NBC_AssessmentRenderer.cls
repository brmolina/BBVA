public without sharing class DMT_NBC_AssessmentRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_CalloutTrackableRenderer, DMT_TrackedComponent {
     private static final String GTB_PRODUCT_AREA = 'GTB';
     private static final String IBF_PRODUCT_AREA = 'IB&F';
     private static final String EXTENSION_RCF_TL_CAPITAL_ACTION = 'Extension RCF & TL';
     private static Id dmtOpportunityId;
     private static Map<String, DMT_ViewRenderer> renderersByKey = new Map<String, DMT_ViewRenderer>();

        static {
            Map<String, Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
            Map<String, Schema.RecordTypeInfo> rtInfosOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
            Id treasuryId = rtInfos.get('TreasurySettlement').getRecordTypeId();
            Id otherId = rtInfos.get('OtherProducts').getRecordTypeId();
            dmtOpportunityId = rtInfosOpportunity.get('DMT_Opportunity').getRecordTypeId();

            renderersByKey.put(IBF_PRODUCT_AREA, new DMT_NBC_OppAssessmentRenderer_IBF());
            renderersByKey.put(GTB_PRODUCT_AREA, new DMT_NBC_OppAssessmentRenderer_GTB());
        }

        public String renderHtml(DMT_ViewController.LineDataWrapper data) {
            if (data == null) {
                return '<div>Error: Data not provided</div>';
            }
            try {
                DMT_ViewRenderer renderer = resolveRenderer(data.recordTypeId, data.opportunity);
                if (renderer == null) {
                    throw new IllegalArgumentException('No Assessment renderer for record type Id: ' + data.recordTypeId);
                }
                return renderer.renderHtml(data);
            } catch (Exception e) {
                System.debug(e.getMessage());
                return '<div>Error: ' + e.getMessage() + '</div>';
            }
        }

        public Boolean isComponentTracked() {
            return true;
        }

        // CIBGLOBALD-4117 - Factory -> Delegator -> Renderer: the delegator only routes to whichever
        // single renderer is currently active (same key as renderHtml) and asks it what to track -
        // it never hardcodes or unions field/section/callout knowledge itself. If Product Area (or
        // any switch field) changes and the active renderer flips from IB&F to GTB, that switch is
        // caught because the frozen data was built by the old renderer and this call now compares
        // against the new one - not because both are pre-unioned ahead of time.
        private DMT_ViewRenderer resolveRenderer(String recordTypeId, SObject record) {
            String key;
            if (recordTypeId == String.valueOf(dmtOpportunityId)) {
                String productArea = record != null ? (String) record.get('DMT_Product_Area__c') : null;
                String capitalAction = record != null ? (String) record.get('DMT_Capital_Action__c') : null;
                Boolean isGTB = productArea == GTB_PRODUCT_AREA
                    || (productArea == IBF_PRODUCT_AREA && capitalAction == EXTENSION_RCF_TL_CAPITAL_ACTION);
                key = isGTB ? GTB_PRODUCT_AREA : IBF_PRODUCT_AREA;
            } else {
                key = recordTypeId;
            }
            return renderersByKey.get(key);
        }

        public List<String> getTrackedFields(SObject record) {
            DMT_ViewRenderer renderer = resolveRenderer(String.valueOf(record.get('RecordTypeId')), record);
            return renderer instanceof DMT_FieldTrackableRenderer
                ? ((DMT_FieldTrackableRenderer) renderer).getTrackedFields(record)
                : new List<String>();
        }

        public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
            DMT_ViewRenderer renderer = resolveRenderer(String.valueOf(record.get('RecordTypeId')), record);
            return renderer instanceof DMT_MultiObjectFieldTrackableRenderer
                ? ((DMT_MultiObjectFieldTrackableRenderer) renderer).getTrackedFieldsByObject(record)
                : new Map<String, List<String>>();
        }

        public List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record) {
            DMT_ViewRenderer renderer = resolveRenderer(String.valueOf(record.get('RecordTypeId')), record);
            return renderer instanceof DMT_MultiObjectFieldTrackableRenderer
                ? ((DMT_MultiObjectFieldTrackableRenderer) renderer).getChildSections(record)
                : new List<DMT_ApprovalChangeStep_Helper.ChildSection>();
        }

        public String getCalloutCacheKey(SObject record) {
            DMT_ViewRenderer renderer = resolveRenderer(String.valueOf(record.get('RecordTypeId')), record);
            return renderer instanceof DMT_CalloutTrackableRenderer
                ? ((DMT_CalloutTrackableRenderer) renderer).getCalloutCacheKey(record)
                : record.Id;
        }

        public Map<String, Object> fetchLiveTrackedValues(SObject record) {
            DMT_ViewRenderer renderer = resolveRenderer(String.valueOf(record.get('RecordTypeId')), record);
            return renderer instanceof DMT_CalloutTrackableRenderer
                ? ((DMT_CalloutTrackableRenderer) renderer).fetchLiveTrackedValues(record)
                : new Map<String, Object>();
        }
}