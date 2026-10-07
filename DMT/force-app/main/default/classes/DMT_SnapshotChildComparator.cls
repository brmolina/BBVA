// CIBGLOBALD-4117 - compares a snapshot's child-record sections against live data.
public without sharing class DMT_SnapshotChildComparator implements DMT_ApprovalChangeStep_Helper.SnapshotChildComparator {

    // sectionKey -> recordId -> the tracked fields / live rows for that record's section.
    private Map<String, Map<Id, List<String>>> trackedFieldsBySectionAndRecord = new Map<String, Map<Id, List<String>>>();
    private Map<String, Map<Id, Map<Id, SObject>>> liveRowsBySectionAndRecord = new Map<String, Map<Id, Map<Id, SObject>>>();

    private DMT_SnapshotChildComparator() {}

    // CIBGLOBALD-4117 - builds a comparator for a batch of records, or null when none has a child
    // section.
    public static DMT_SnapshotChildComparator forRecords(Map<Id, SObject> recordsById) {
        if (recordsById == null || recordsById.isEmpty()) {
            return null;
        }

        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> sectionsByKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
        Map<String, Map<Id, Set<String>>> fieldsBySectionAndRecordType = new Map<String, Map<Id, Set<String>>>();
        for (Id recordId : recordsById.keySet()) {
            SObject record = recordsById.get(recordId);
            Id recordTypeId = (Id) record.get('RecordTypeId');
            for (String componentName : DMT_RendererFactory.getTrackedComponentNames()) {
                for (DMT_ApprovalChangeStep_Helper.ChildSection section : DMT_RendererFactory.getChildSections(componentName, record)) {
                    sectionsByKey.put(section.snapshotSectionKey, section);

                    List<String> componentFields = DMT_RendererFactory.getTrackedFieldsByObject(componentName, record).get(section.childObjectApiName);
                    if (componentFields == null || componentFields.isEmpty()) {
                        continue;
                    }
                    if (!fieldsBySectionAndRecordType.containsKey(section.snapshotSectionKey)) {
                        fieldsBySectionAndRecordType.put(section.snapshotSectionKey, new Map<Id, Set<String>>());
                    }
                    Map<Id, Set<String>> fieldsByRecordType = fieldsBySectionAndRecordType.get(section.snapshotSectionKey);
                    if (!fieldsByRecordType.containsKey(recordTypeId)) {
                        fieldsByRecordType.put(recordTypeId, new Set<String>());
                    }
                    fieldsByRecordType.get(recordTypeId).addAll(componentFields);
                }
            }
        }
        if (sectionsByKey.isEmpty()) {
            return null;
        }

        DMT_SnapshotChildComparator comparator = new DMT_SnapshotChildComparator();
        Boolean hasAnythingToTrack = false;

        for (DMT_ApprovalChangeStep_Helper.ChildSection section : sectionsByKey.values()) {
            Map<Id, List<String>> trackedFieldsByRecordId = new Map<Id, List<String>>();
            Map<Id, Id> parentValueByRecordId = new Map<Id, Id>();
            Set<String> allTrackedFields = new Set<String>();
            Map<Id, Set<String>> fieldsByRecordType = fieldsBySectionAndRecordType.get(section.snapshotSectionKey);

            for (Id recordId : recordsById.keySet()) {
                SObject record = recordsById.get(recordId);
                Id recordTypeId = (Id) record.get('RecordTypeId');
                Set<String> trackedFieldsSet = fieldsByRecordType == null ? null : fieldsByRecordType.get(recordTypeId);
                if (trackedFieldsSet == null || trackedFieldsSet.isEmpty()) {
                    continue;
                }
                Id parentValue = (Id) record.get(section.parentValueField);
                if (parentValue == null) {
                    continue;
                }
                List<String> trackedFields = new List<String>(trackedFieldsSet);
                trackedFieldsByRecordId.put(recordId, trackedFields);
                parentValueByRecordId.put(recordId, parentValue);
                allTrackedFields.addAll(trackedFields);
            }
            if (trackedFieldsByRecordId.isEmpty()) {
                continue;
            }
            hasAnythingToTrack = true;

            comparator.trackedFieldsBySectionAndRecord.put(section.snapshotSectionKey, trackedFieldsByRecordId);
            comparator.liveRowsBySectionAndRecord.put(
                section.snapshotSectionKey,
                queryLiveRows(section, parentValueByRecordId, allTrackedFields)
            );
        }

        return hasAnythingToTrack ? comparator : null;
    }

    private static Map<Id, Map<Id, SObject>> queryLiveRows(DMT_ApprovalChangeStep_Helper.ChildSection section, Map<Id, Id> parentValueByRecordId, Set<String> trackedFields) {
        Set<Id> parentValues = new Set<Id>(parentValueByRecordId.values());
        Boolean isCrossObject = section.childLookupField.contains('.');
        String relName = isCrossObject ? section.childLookupField.substringBefore('.') : null;
        String relField = isCrossObject ? section.childLookupField.substringAfter('.') : null;

        String query = 'SELECT Id, ' + String.escapeSingleQuotes(section.childLookupField) + ', ' +
            String.escapeSingleQuotes(String.join(new List<String>(trackedFields), ',')) +
            ' FROM ' + String.escapeSingleQuotes(section.childObjectApiName) +
            ' WHERE ' + String.escapeSingleQuotes(section.childLookupField) + ' IN :parentValues';

        Map<Id, List<SObject>> rowsByParentValue = new Map<Id, List<SObject>>();
        for (SObject row : Database.query(query)) {
            Id parentValue = isCrossObject ? (Id) row.getSObject(relName)?.get(relField) : (Id) row.get(section.childLookupField);
            if (parentValue == null) {
                continue;
            }
            if (!rowsByParentValue.containsKey(parentValue)) {
                rowsByParentValue.put(parentValue, new List<SObject>());
            }
            rowsByParentValue.get(parentValue).add(row);
        }

        Map<Id, Map<Id, SObject>> liveRowsByRecordId = new Map<Id, Map<Id, SObject>>();
        for (Id recordId : parentValueByRecordId.keySet()) {
            Map<Id, SObject> rowsById = new Map<Id, SObject>();
            List<SObject> rows = rowsByParentValue.get(parentValueByRecordId.get(recordId));
            if (rows != null) {
                for (SObject row : rows) {
                    rowsById.put((Id) row.get('Id'), row);
                }
            }
            liveRowsByRecordId.put(recordId, rowsById);
        }
        return liveRowsByRecordId;
    }

    // CIBGLOBALD-4117 - true as soon as any child section for this record no longer matches the
    // frozen snapshot.
    public Boolean hasChanges(Id recordId, Map<String, Object> snapshotJson) {
        for (String sectionKey : trackedFieldsBySectionAndRecord.keySet()) {
            List<String> trackedFields = trackedFieldsBySectionAndRecord.get(sectionKey).get(recordId);
            Object frozenSection = snapshotJson.get(sectionKey);
            if (trackedFields == null || !(frozenSection instanceof Map<String, Object>)) {
                continue;
            }

            Map<String, Object> liveRowsAsJson = (Map<String, Object>) JSON.deserializeUntyped(
                JSON.serialize(liveRowsBySectionAndRecord.get(sectionKey).get(recordId))
            );
            if (DMT_ApprovalChangeStep_Helper.rowsDiffer((Map<String, Object>) frozenSection, liveRowsAsJson, trackedFields)) {
                return true;
            }
        }
        return false;
    }
}