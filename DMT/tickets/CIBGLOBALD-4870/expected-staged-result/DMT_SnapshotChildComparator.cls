// CIBGLOBALD-4117 - compares a snapshot's child-record sections against live data.
public without sharing class DMT_SnapshotChildComparator implements DMT_ApprovalChangeStep_Helper.SnapshotChildComparator {

    // sectionKey -> recordId -> the tracked fields / live rows for that record's section.
    private Map<String, Map<Id, List<String>>> trackedFieldsBySectionAndRecord = new Map<String, Map<Id, List<String>>>();
    private Map<String, Map<Id, Map<Id, SObject>>> liveRowsBySectionAndRecord = new Map<String, Map<Id, Map<Id, SObject>>>();
    // CIBGLOBALD-4811, CIBGLOBALD-4870 - Enhancement fix to existing process: sectionKey -> recordId -> component -> the fields
    // that component tracks in the section, so a task compares and names only its own components.
    private Map<String, Map<Id, Map<String, List<String>>>> fieldsBySectionRecordAndComponent = new Map<String, Map<Id, Map<String, List<String>>>>();
    // CIBGLOBALD-4811, CIBGLOBALD-4870 - sectionKey -> child object API name, to match the unsaved rows of a tab.
    private Map<String, String> objectApiNameBySection = new Map<String, String>();

    private DMT_SnapshotChildComparator() {}

    // CIBGLOBALD-4117 - builds a comparator for a batch of records, or null when none has a child
    // section.
    public static DMT_SnapshotChildComparator forRecords(Map<Id, SObject> recordsById) {
        return forRecords(recordsById, null); // CIBGLOBALD-4811, CIBGLOBALD-4870
    }

    // CIBGLOBALD-4811, CIBGLOBALD-4870 - Enhancement fix to existing process: only the sections of these components are
    // queried (the components frozen in the snapshots being compared); null = every tracked component.
    public static DMT_SnapshotChildComparator forRecords(Map<Id, SObject> recordsById, List<String> componentNames) {
        if (recordsById == null || recordsById.isEmpty()) {
            return null;
        }

        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> sectionsByKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
        Map<String, Map<Id, Set<String>>> fieldsBySectionAndRecordType = new Map<String, Map<Id, Set<String>>>();
        // CIBGLOBALD-4811, CIBGLOBALD-4870 - sectionKey -> recordTypeId -> component -> fields.
        Map<String, Map<Id, Map<String, List<String>>>> componentFieldsBySectionAndRecordType = new Map<String, Map<Id, Map<String, List<String>>>>();
        for (Id recordId : recordsById.keySet()) {
            SObject record = recordsById.get(recordId);
            Id recordTypeId = (Id) record.get('RecordTypeId');
            for (String componentName : componentNames == null ? DMT_RendererFactory.getTrackedComponentNames() : componentNames) { // CIBGLOBALD-4811, CIBGLOBALD-4870
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

                    // CIBGLOBALD-4811, CIBGLOBALD-4870 - the same fields kept per component.
                    if (!componentFieldsBySectionAndRecordType.containsKey(section.snapshotSectionKey)) {
                        componentFieldsBySectionAndRecordType.put(section.snapshotSectionKey, new Map<Id, Map<String, List<String>>>());
                    }
                    if (!componentFieldsBySectionAndRecordType.get(section.snapshotSectionKey).containsKey(recordTypeId)) {
                        componentFieldsBySectionAndRecordType.get(section.snapshotSectionKey).put(recordTypeId, new Map<String, List<String>>());
                    }
                    componentFieldsBySectionAndRecordType.get(section.snapshotSectionKey).get(recordTypeId).put(componentName, componentFields);
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
            Map<Id, Map<String, List<String>>> componentFieldsByRecordId = new Map<Id, Map<String, List<String>>>(); // CIBGLOBALD-4811, CIBGLOBALD-4870
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
                componentFieldsByRecordId.put(recordId, componentFieldsBySectionAndRecordType.get(section.snapshotSectionKey).get(recordTypeId)); // CIBGLOBALD-4811, CIBGLOBALD-4870
                parentValueByRecordId.put(recordId, parentValue);
                allTrackedFields.addAll(trackedFields);
            }
            if (trackedFieldsByRecordId.isEmpty()) {
                continue;
            }
            hasAnythingToTrack = true;

            comparator.trackedFieldsBySectionAndRecord.put(section.snapshotSectionKey, trackedFieldsByRecordId);
            comparator.fieldsBySectionRecordAndComponent.put(section.snapshotSectionKey, componentFieldsByRecordId); // CIBGLOBALD-4811, CIBGLOBALD-4870
            comparator.objectApiNameBySection.put(section.snapshotSectionKey, section.childObjectApiName); // CIBGLOBALD-4811, CIBGLOBALD-4870
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
    // CIBGLOBALD-4811, CIBGLOBALD-4870 - Enhancement fix to existing process: only the fields of the task's components
    // (componentNames, from DMT_TaskStatusWhenCompleted__c.DMT_TrackedComponents__c) are compared.
    public Boolean hasChanges(Id recordId, Map<String, Object> snapshotJson, List<String> componentNames) {
        for (String sectionKey : trackedFieldsBySectionAndRecord.keySet()) {
            if (sectionDiffers(sectionKey, recordId, snapshotJson, componentFields(sectionKey, recordId, componentNames))) { // CIBGLOBALD-4811, CIBGLOBALD-4870
                return true;
            }
        }
        return false;
    }

    // CIBGLOBALD-4811, CIBGLOBALD-4870 - the fields of the given components in one section; null components = all of them.
    private List<String> componentFields(String sectionKey, Id recordId, List<String> componentNames) {
        Map<String, List<String>> fieldsByComponent = fieldsBySectionRecordAndComponent.get(sectionKey).get(recordId);
        if (fieldsByComponent == null) {
            return null;
        }
        Set<String> fields = new Set<String>();
        for (String componentName : fieldsByComponent.keySet()) {
            if (componentNames == null || componentNames.contains(componentName)) {
                fields.addAll(fieldsByComponent.get(componentName));
            }
        }
        return new List<String>(fields);
    }

    // CIBGLOBALD-4811, CIBGLOBALD-4870 - one section of hasChanges(), compared on the given fields.
    private Boolean sectionDiffers(String sectionKey, Id recordId, Map<String, Object> snapshotJson, List<String> trackedFields) {
        Object frozenSection = snapshotJson.get(sectionKey);
        if (trackedFields == null || trackedFields.isEmpty() || !(frozenSection instanceof Map<String, Object>)) {
            return false;
        }

        Map<String, Object> liveRowsAsJson = (Map<String, Object>) JSON.deserializeUntyped(
            JSON.serialize(liveRowsBySectionAndRecord.get(sectionKey).get(recordId))
        );
        return DMT_ApprovalChangeStep_Helper.rowsDiffer( // CIBGLOBALD-4811, CIBGLOBALD-4870
            (Map<String, Object>) frozenSection, liveRowsAsJson, trackedFields,
            Schema.getGlobalDescribe().get(objectApiNameBySection.get(sectionKey)) // CIBGLOBALD-4811, CIBGLOBALD-4870
        );
    }
}