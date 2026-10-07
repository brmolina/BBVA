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

        return System.JSON.serialize(snapshot, true)
                    .replaceAll('"attributes":\\{[^\\}]*\\},?', '');
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
            if (rowsByParent == null || !rowsByParent.containsKey(parentId)) continue;

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