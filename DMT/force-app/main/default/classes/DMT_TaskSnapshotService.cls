/**
 * CIBGLOBALD-4117 - builds the JSON snapshot string frozen onto DMT_TaskStatusWhenCompleted__c
 * (DMT_ViewFieldStatusAtClose__c) from pre-fetched data. Used by
 * DMT_ApprovalChangeStep_Handler.updateTaskWithStatus and
 * DMT_Massive_Task_Closure_Service.confirmMassiveClosure.
 */
public without sharing class DMT_TaskSnapshotService {

    /**
     * @param lineChildSectionsByKey Line-side ChildSections, keyed by snapshotSectionKey.
     * @param oppChildSectionsByKey  Opportunity-side ChildSections, keyed by snapshotSectionKey.
     * @param childListsBySectionKey Rows for every child section, keyed by snapshotSectionKey.
     * @param calloutTrackedValuesByComponent CIBGLOBALD-4117 - live values already fetched
     *        (before this call) from any DMT_CalloutTrackableRenderer components this view has,
     *        keyed by component name. Pass an empty map for a caller that doesn't capture this yet
     *        (a component's callout-tracked data is then never frozen from that path, so it will
     *        never restart a task from that path either - same "no baseline, no restart" rule
     *        DMT_ApprovalChangeStep_Helper.checkCalloutTrackableComponent already follows).
     */
    public static String buildSnapshotJson(
            Case c,
            Map<String, List<String>> fm,
            Map<Id, SObject> lineMap,
            Map<Id, SObject> oppMap,
            Map<Id, List<SObject>> customAssocMap,
            Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> lineChildSectionsByKey,
            Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> oppChildSectionsByKey,
            Map<String, Map<Id, List<SObject>>> childListsBySectionKey,
            Map<String, Object> calloutTrackedValuesByComponent) {

        Map<String, Object> snapshot = new Map<String, Object>();

        if (c.DMT_LineOpportunity__c == 'L') {
            Id lineId = c.DMT_Line__c;

            if (fm.containsKey('DMT_Line__c') && lineMap.containsKey(lineId)) {
                snapshot.put('line', lineMap.get(lineId));
            }

            Id caId = c.DMT_Line__r?.Custom_Association__c;
            if (fm.containsKey('Custom_Association_Client__c')
                    && caId != null && customAssocMap.containsKey(caId)) {
                snapshot.put('customAssociationClientList',
                    toIdKeyMap(customAssocMap.get(caId)));
            }

            putChildSections(snapshot, fm, lineChildSectionsByKey, childListsBySectionKey, lineId);

        } else if (c.DMT_LineOpportunity__c == 'O') {
            Id oppId = c.opportunity_id__c;

            if (fm.containsKey('Opportunity') && oppMap.containsKey(oppId)) {
                snapshot.put('opportunity', oppMap.get(oppId));
            }

            putChildSections(snapshot, fm, oppChildSectionsByKey, childListsBySectionKey, oppId);
        }

        if (calloutTrackedValuesByComponent != null && !calloutTrackedValuesByComponent.isEmpty()) {
            snapshot.put('calloutTrackedValues', calloutTrackedValuesByComponent);
        }

        String snapshotJson = System.JSON.serialize(snapshot, true) // CIBGLOBALD-5023
                    .replaceAll('"attributes":\\{[^\\}]*\\},?', '');
        return limitSnapshotSize(snapshotJson); // CIBGLOBALD-5023
    }

    // CIBGLOBALD-5023 - marks a value stored as a fingerprint instead of its text (see fingerprint).
    public static final String FINGERPRINT_PREFIX = '__DMT_FP__:';
    // CIBGLOBALD-5023 - snapshot key listing the sections left out because the snapshot did not fit
    // DMT_ViewFieldStatusAtClose__c. DMT_ApprovalChangeStep_Helper.isTaskStale reopens such a task.
    public static final String OVERFLOW_SECTIONS_KEY = 'overflowSections';
    // CIBGLOBALD-5023 - long text values up to this length are stored as they are.
    private static final Integer FINGERPRINT_MIN_LENGTH = 255;
    // CIBGLOBALD-5023 - room kept free for the HPG values added later by
    // DMT_ApprovalChangeStep_Helper.freezeCalloutTrackableBaseline (calloutTrackedValues).
    private static final Integer RESERVED_LENGTH = 5000;
    // CIBGLOBALD-5023 - largest snapshot stored; tests lower it to reach the overflow path.
    @TestVisible
    private static Integer maxSnapshotLength =
        DMT_TaskStatusWhenCompleted__c.DMT_ViewFieldStatusAtClose__c.getDescribe().getLength() - RESERVED_LENGTH;
    // CIBGLOBALD-5023 - long text area / rich text field names (lower case) per object, read once per transaction.
    private static Map<Schema.SObjectType, Set<String>> longTextFieldsByType = new Map<Schema.SObjectType, Set<String>>();

    /**
     * CIBGLOBALD-5023 - fixed-length stand-in for a long text value: prefix, original length and SHA-256 of the text
     * (about 80 characters whatever the length). Any edit anywhere in the text gives another fingerprint, so the
     * restart comparison (DMT_ApprovalChangeStep_Helper.valueChanged) still sees every change.
     */
    public static String fingerprint(String value) {
        return FINGERPRINT_PREFIX + value.length() + ':'
            + EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(value)));
    }

    // CIBGLOBALD-5023 - true when a frozen value was stored as a fingerprint.
    public static Boolean isFingerprint(Object value) {
        return value instanceof String && ((String) value).startsWith(FINGERPRINT_PREFIX);
    }

    /**
     * CIBGLOBALD-5023 - keeps the snapshot inside DMT_ViewFieldStatusAtClose__c (Long Text Area, 131,072 characters).
     * 1. Long text area / rich text values longer than FINGERPRINT_MIN_LENGTH become fingerprints, in every record
     *    and child row (the object of each row is read from its Id).
     * 2. If the snapshot still does not fit, the largest sections are left out and listed under OVERFLOW_SECTIONS_KEY;
     *    the task is then reopened at the next checkpoint, so no approver is skipped. Logged as DMT_LogExceptionPayload.
     */
    @TestVisible
    private static String limitSnapshotSize(String snapshotJson) {
        Map<String, Object> snapshot = (Map<String, Object>) JSON.deserializeUntyped(snapshotJson);
        Boolean fingerprinted = false;
        for (String sectionKey : snapshot.keySet()) {
            if (sectionKey == 'calloutTrackedValues') {
                continue;
            }
            Object section = snapshot.get(sectionKey);
            if (!(section instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> sectionMap = (Map<String, Object>) section;
            if (sectionMap.containsKey('Id')) {
                fingerprinted = fingerprintLongTexts(sectionMap) || fingerprinted;
                continue;
            }
            for (Object row : sectionMap.values()) {
                if (row instanceof Map<String, Object>) {
                    fingerprinted = fingerprintLongTexts((Map<String, Object>) row) || fingerprinted;
                }
            }
        }
        // Nothing to fingerprint: the snapshot is stored exactly as built.
        String result = fingerprinted ? JSON.serialize(snapshot) : snapshotJson;
        if (result.length() <= maxSnapshotLength) {
            return result;
        }

        List<String> overflowSections = new List<String>();
        while (result.length() > maxSnapshotLength) {
            String largestKey;
            Integer largestLength = -1;
            for (String sectionKey : snapshot.keySet()) {
                if (sectionKey == OVERFLOW_SECTIONS_KEY) {
                    continue;
                }
                Integer sectionLength = JSON.serialize(snapshot.get(sectionKey)).length();
                if (sectionLength > largestLength) {
                    largestKey = sectionKey;
                    largestLength = sectionLength;
                }
            }
            if (largestKey == null) {
                break;
            }
            snapshot.remove(largestKey);
            overflowSections.add(largestKey);
            snapshot.put(OVERFLOW_SECTIONS_KEY, overflowSections);
            result = JSON.serialize(snapshot);
        }
        DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
            'Approval snapshot over ' + maxSnapshotLength + ' characters; sections left out (task reopens at the next checkpoint): '
                + String.join(overflowSections, ', '),
            null, null, 'SnapshotOverflow', 'DMT_TaskSnapshotService', 'limitSnapshotSize', 'DMT', 'DMT_TaskStatusWhenCompleted__c'
        ));
        return result;
    }

    // CIBGLOBALD-5023 - replaces the long text values of one record or row (JSON map with its Id) by fingerprints;
    // true when any value was replaced.
    private static Boolean fingerprintLongTexts(Map<String, Object> record) {
        Schema.SObjectType recordType;
        try {
            recordType = Id.valueOf((String) record.get('Id')).getSObjectType();
        } catch (Exception e) {
            return false;
        }
        Map<String, Object> fingerprintsByField = new Map<String, Object>();
        Set<String> longTextFields = longTextFields(recordType);
        for (String fieldName : record.keySet()) {
            Object value = record.get(fieldName);
            if (value instanceof String && ((String) value).length() > FINGERPRINT_MIN_LENGTH
                    && !isFingerprint(value) && longTextFields.contains(fieldName.toLowerCase())) {
                fingerprintsByField.put(fieldName, fingerprint((String) value));
            }
        }
        record.putAll(fingerprintsByField);
        return !fingerprintsByField.isEmpty();
    }

    // CIBGLOBALD-5023 - long text area and rich text fields of an object (TEXTAREA longer than 255 in the describe).
    private static Set<String> longTextFields(Schema.SObjectType recordType) {
        if (!longTextFieldsByType.containsKey(recordType)) {
            Set<String> names = new Set<String>();
            for (Schema.SObjectField field : recordType.getDescribe().fields.getMap().values()) {
                Schema.DescribeFieldResult describe = field.getDescribe();
                if (describe.getType() == Schema.DisplayType.TEXTAREA && describe.getLength() > FINGERPRINT_MIN_LENGTH) {
                    names.add(describe.getName().toLowerCase());
                }
            }
            longTextFieldsByType.put(recordType, names);
        }
        return longTextFieldsByType.get(recordType);
    }

    // CIBGLOBALD-4117 - one domain's ChildSection rows into the snapshot.
    private static void putChildSections(
            Map<String, Object> snapshot,
            Map<String, List<String>> fm,
            Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> childSectionsByKey,
            Map<String, Map<Id, List<SObject>>> childListsBySectionKey,
            Id parentId) {
        for (String sectionKey : childSectionsByKey.keySet()) {
            DMT_ApprovalChangeStep_Helper.ChildSection section = childSectionsByKey.get(sectionKey);
            if (!fm.containsKey(section.childObjectApiName)) continue;

            Map<Id, List<SObject>> rowsByParent = childListsBySectionKey.get(sectionKey);
            if (rowsByParent == null || !rowsByParent.containsKey(parentId)) {
                // P27: an executed bulk query with no Sold Orders is an empty baseline.
                // Do not manufacture baselines for unqueried sections or other components.
                if (rowsByParent != null && parentId != null
                        && section.componentName == 'Underwriting'
                        && sectionKey == 'soldOrders'
                        && section.childObjectApiName == 'Sold_Order__c') {
                    snapshot.put(sectionKey, new Map<Id, SObject>());
                }
                continue;
            }

            List<SObject> rows = rowsByParent.get(parentId);
            snapshot.put(sectionKey, toIdKeyMap(rows));
        }
    }

    // CIBGLOBALD-4117 - Map<Id, SObject> shape, every child section uses this.
    private static Map<Id, SObject> toIdKeyMap(List<SObject> records) {
        Map<Id, SObject> result = new Map<Id, SObject>();
        for (SObject rec : records) result.put((Id) rec.get('Id'), rec);
        return result;
    }
}