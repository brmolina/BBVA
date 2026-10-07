/**
 * @description       : Class called via the integration procedure ApprovalChangeStep
 * @author            : Aníbal Cortés
 * @group             :
 * @last modified on  : 10-31-2024
 * @last modified by  : Aníbal Cortés
 **/
global without sharing class DMT_ApprovalChangeStep_Handler implements Callable{

    // CIBGLOBALD-4117 - section-to-object cache for getComparableFieldKeys, used by
    // previewCompareTasksFromCase.
    private static Map<String, String> compareTasksFromCaseSectionToObjectCache;

    // CIBGLOBALD-4117 - section-to-object mapping for getComparableFieldKeys, derived from
    // DMT_RendererFactory.getChildSections() against one representative record per record type.
    private static Map<String, String> compareTasksFromCaseSectionToObject() {
        if (compareTasksFromCaseSectionToObjectCache == null) {
            Map<String, String> sectionToObject = new Map<String, String>{
                'line' => 'DMT_Line__c',
                'opportunity' => 'Opportunity'
            };
            Map<String, Schema.RecordTypeInfo> lineRtInfos = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
            Map<String, Schema.RecordTypeInfo> oppRtInfos = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
            List<SObject> representativeRecords = new List<SObject>{
                new DMT_Line__c(RecordTypeId = lineRtInfos.get('TreasurySettlement')?.getRecordTypeId()),
                new DMT_Line__c(RecordTypeId = lineRtInfos.get('OtherProducts')?.getRecordTypeId()),
                new DMT_Line__c(RecordTypeId = lineRtInfos.get('Sanction')?.getRecordTypeId()),
                new Opportunity(RecordTypeId = oppRtInfos.get('DMT_Opportunity')?.getRecordTypeId())
            };
            for (String componentName : DMT_RendererFactory.getTrackedComponentNames()) {
                for (SObject representative : representativeRecords) {
                    for (DMT_ApprovalChangeStep_Helper.ChildSection section : DMT_RendererFactory.getChildSections(componentName, representative)) {
                        sectionToObject.put(section.snapshotSectionKey, section.childObjectApiName);
                    }
                }
            }
            compareTasksFromCaseSectionToObjectCache = sectionToObject;
        }
        return compareTasksFromCaseSectionToObjectCache;
    }

    /**
     * The field keys to compare for a snapshot section, taken from the tracked-field config rather
     * than from the stored snapshot's own keys.
     *
     * That matters because a field that was null when the snapshot was taken has no key in the
     * JSON at all - iterating the snapshot's keySet() would skip it forever, even once populated
     * (CIBGLOBALD-4098).
     *
     * Relationship fields ("Client__r.Name") reduce to their top-level key ("Client__r") to match
     * how the JSON nests them. Falls back to the snapshot's own keys for an unrecognised section.
     */
    private static Set<String> getComparableFieldKeys(String sectionName, Map<String, List<String>> fieldMapFromObject, Set<String> fallbackKeys) {
        String objectName = compareTasksFromCaseSectionToObject().get(sectionName);
        if (objectName == null || !fieldMapFromObject.containsKey(objectName)) {
            return fallbackKeys;
        }
        Set<String> keys = new Set<String>();
        for (String trackedField : fieldMapFromObject.get(objectName)) {
            keys.add(trackedField.contains('.') ? trackedField.substringBefore('.') : trackedField);
        }
        return keys;
    }

    /**
     * @description First method that calls the Integration Procedure
     * @author Aníbal Cortés | 10-31-2024
     * @param action
     * @param args
     * @return Object
     **/
    public Object call(String action, Map<String, Object> args){

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }

    /**
     * @description Checks which method was invoked in the Integration Procedure
     * @author Aníbal Cortés | 10-31-2024
     * @param methodName
     * @param inputMap
     * @param outMap
     * @param options
     * @return Object
     **/
    private static Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options){
        try{
            if (methodName == 'saveValuesUpdate'){
                updateTaskWithStatus((String) inputMap.get('recordId'), true);
            } else if (methodName == 'saveValuesInsert'){
                updateTaskWithStatus((String) inputMap.get('recordId'), false);
            }
        } catch (exception e){
            system.debug('Exception --> ' + e.getMessage());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_ApprovalChangeStep_Handler', 'invokeMethod', 'DMT', ''));
            //DES_Exception_Utils.logException(e,'DMT_ApprovalChangeStep_Handler', 'invokeMethod', 'DMT', '');
        }
        return outMap;
    }

    // CIBGLOBALD-4117 - resolution of one approver view's DMT_Items__c rows into tracked fields and
    // components for one record type.
    public class ItemFieldResolution {
        public Map<String, List<String>> fieldMapFromObject = new Map<String, List<String>>();
        public String allFields = '';
        // CIBGLOBALD-4117 - components from DMT_RendererFactory.getTrackedComponentNames() this view
        // has a DMT_Items__c row for. Stored on the snapshot (DMT_TrackedComponents__c).
        public Set<String> trackedComponentNames = new Set<String>();
    }

    // CIBGLOBALD-4117 - watched Object.Field list for one approver view's DMT_Items__c rows.
    public static ItemFieldResolution resolveTrackedFieldsForItems(List<DMT_Items__c> itemsList, SObject record, String sObjectApiName) {
        ItemFieldResolution resolution = new ItemFieldResolution();
        for (DMT_Items__c item : itemsList){
            List<String> fields = new List<String>();
            if (item != null) {
                if (DMT_RendererFactory.getTrackedComponentNames().contains(item.DMT_Component_Item__c)) {
                    resolution.trackedComponentNames.add(item.DMT_Component_Item__c);
                }
                Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject(item.DMT_Component_Item__c, record);
                if (!fieldsByObject.isEmpty()) {
                    // Multi-object renderer already says which object each field belongs to, so
                    // don't prefix with sObjectApiName like the single-object branch below.
                    for (String objectName : fieldsByObject.keySet()) {
                        for (String fieldName : fieldsByObject.get(objectName)) {
                            fields.add(objectName + '.' + fieldName);
                        }
                    }
                } else {
                    List<String> trackedFields = DMT_RendererFactory.getTrackedFields(item.DMT_Component_Item__c, record);
                    if (!trackedFields.isEmpty()) {
                        for (String fieldName : trackedFields) {
                            fields.add(sObjectApiName + '.' + fieldName);
                        }
                    }
                }
            }
            //We obtain the Object Name and Field Name for each and store it in the Map
            for (String field : fields){
                List<String> cadenaPartida = field.split('\\.', 2);
                String objectName = cadenaPartida.get(0);
                String fieldName = cadenaPartida.get(1);
                List<String> fieldsFromMap = new List<String>();
                if (resolution.fieldMapFromObject.containsKey(objectName)){
                    fieldsFromMap = resolution.fieldMapFromObject.get(objectName);
                }
                // If the field is already on the list, we don't store it again to prevent duplicate fields on query
                if (!fieldsFromMap.contains(fieldName)){
                    fieldsFromMap.add(fieldName);
                    resolution.fieldMapFromObject.put(objectName, fieldsFromMap);
                    resolution.allFields += objectName + '.' + fieldName + ';';
                }
            }
        }
        resolution.allFields = resolution.allFields.removeEnd(';');
        return resolution;
    }

    // CIBGLOBALD-4117 - every ChildSection this view's components declare for this record type,
    // deduplicated by snapshotSectionKey.
    public static Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> resolveChildSectionsForItems(List<DMT_Items__c> itemsList, SObject record) {
        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> sectionsByKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
        for (DMT_Items__c item : itemsList) {
            if (item == null) continue;
            for (DMT_ApprovalChangeStep_Helper.ChildSection section : DMT_RendererFactory.getChildSections(item.DMT_Component_Item__c, record)) {
                if (!sectionsByKey.containsKey(section.snapshotSectionKey)) {
                    sectionsByKey.put(section.snapshotSectionKey, section);
                }
            }
        }
        return sectionsByKey;
    }

    // CIBGLOBALD-4117 - queries every ChildSection whose rows hang directly off the parent's own Id
    // (ChildSection.parentValueField == 'Id').
    public static Map<String, List<SObject>> queryDirectChildSections(
            Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> childSectionsByKey,
            Map<String, List<String>> fieldMapFromObject,
            Id parentId) {
        Map<String, List<SObject>> sections = new Map<String, List<SObject>>();
        if (parentId == null) {
            return sections;
        }
        for (DMT_ApprovalChangeStep_Helper.ChildSection section : childSectionsByKey.values()) {
            if (section.parentValueField != 'Id') continue;
            if (!fieldMapFromObject.containsKey(section.childObjectApiName)) continue;

            String query = 'SELECT Id, ' + String.join(fieldMapFromObject.get(section.childObjectApiName), ', ')
                + ' FROM ' + section.childObjectApiName
                + ' WHERE ' + section.childLookupField + ' = :parentId'
                + (String.isBlank(section.orderBy) ? '' : ' ORDER BY ' + section.orderBy);
            sections.put(section.snapshotSectionKey, Database.query(String.escapeSingleQuotes(query)));
        }
        return sections;
    }

    /**
     * @description Method that updates the task with the current status of the records from the view
     * @author Aníbal Cortés | 10-31-2024
     * @param recordId
     **/
    public static void updateTaskWithStatus(String recordId, Boolean createPdf){

        Task task = DMT_ApprovalChangeStep_Selector.getTaskById(recordId);
        Case relatedCase = DMT_ApprovalChangeStep_Selector.getCaseById(task.WhatId);
        Boolean isLineCase = relatedCase.DMT_LineOpportunity__c == 'L';

        // CIBGLOBALD-4117 - the Case's own Line or Opportunity record, via the same comprehensive
        // query DMT_ViewController uses to build the rendering wrapper (same reasoning as
        // previewCompareTasksFromCase) - every field any renderer's resolveRenderer()/
        // getTrackedFields() could ever need is already there, so this can never again drift out of
        // sync with a hand-maintained narrow SELECT.
        SObject lineOrOpportunityRecord = isLineCase
            ? (SObject) DMT_View_Selector.getLineWithRelatedData(relatedCase.DMT_Line__c, relatedCase.DMT_Line__r.RecordType.DeveloperName)
            : (SObject) DMT_View_Selector.getOpportunityWithRelatedData(relatedCase.opportunity_id__c, relatedCase.opportunity_id__r.RecordType.DeveloperName);
        String sObjectApiName = isLineCase ? 'DMT_Line__c' : 'Opportunity';

        Id approverViewId = getApproverViewId(task.OwnerId, relatedCase);
        List<DMT_Items__c> itemsList = DMT_ApprovalChangeStep_Selector.getItemsByDmtView(approverViewId);

        ItemFieldResolution resolution = resolveTrackedFieldsForItems(itemsList, lineOrOpportunityRecord, sObjectApiName);
        Map<String, List<String>> fieldMapFromObject = resolution.fieldMapFromObject;
        String allFields = resolution.allFields;

        // CIBGLOBALD-4117 - pre-fetched data for DMT_TaskSnapshotService.buildSnapshotJson.
        Map<Id, SObject> lineMap = new Map<Id, SObject>();
        Map<Id, SObject> oppMap = new Map<Id, SObject>();
        Map<Id, List<SObject>> customAssocMap = new Map<Id, List<SObject>>();
        Map<String, Map<Id, List<SObject>>> childListsBySectionKey = new Map<String, Map<Id, List<SObject>>>();

        if (relatedCase.DMT_LineOpportunity__c == 'L'){
            Id lineId = relatedCase.DMT_Line__c;

            // Makes the query for the DMT_Line__c object and stores it for the snapshot builder
            if (fieldMapFromObject.containsKey('DMT_Line__c')){
                String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('DMT_Line__c'), ',') + ' FROM DMT_Line__c WHERE ID = :lineId';
                List<DMT_Line__c> linesRetrieved = Database.query(String.escapeSingleQuotes(query));
                if (!linesRetrieved.isEmpty()) {
                    lineMap.put(lineId, linesRetrieved.get(0));
                }
            }

            // Makes the query for the Custom_Association__c object and stores it for the snapshot builder
            if (fieldMapFromObject.containsKey('Custom_Association_Client__c')){
                Id customAssociationLine = relatedCase.DMT_Line__r.Custom_Association__c;
                String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('Custom_Association_Client__c'), ',') + ' FROM Custom_Association_Client__c WHERE Custom_Association__c = :customAssociationLine ORDER BY Name ASC';
                customAssocMap.put(customAssociationLine, Database.query(String.escapeSingleQuotes(query)));
            }
        }else if (relatedCase.DMT_LineOpportunity__c == 'O'){
                Id oppId = relatedCase.opportunity_id__c;

                // Makes the query for the Opportunity object and stores it for the snapshot builder
                if (fieldMapFromObject.containsKey('Opportunity')){// Añadido opportunity_id__r.StageName como test
                    String query = 'SELECT Id,' + String.join(fieldMapFromObject.get('Opportunity'), ',') + ' FROM Opportunity WHERE ID = :oppId';
                    List<Opportunity> oppRetrieved = Database.query(String.escapeSingleQuotes(query));
                    if (!oppRetrieved.isEmpty()) {
                        oppMap.put(oppId, oppRetrieved.get(0));
                    }
                }
        }

            // CIBGLOBALD-4117 - child sections declared by this view's components' renderers.
            Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> childSectionsByKey = resolveChildSectionsForItems(itemsList, lineOrOpportunityRecord);
            Id directParentId = relatedCase.DMT_LineOpportunity__c == 'L' ? relatedCase.DMT_Line__c : relatedCase.opportunity_id__c;
            Map<String, List<SObject>> genericChildSections = queryDirectChildSections(childSectionsByKey, fieldMapFromObject, directParentId);

            for (String sectionKey : genericChildSections.keySet()) {
                childListsBySectionKey.put(sectionKey, new Map<Id, List<SObject>>{ directParentId => genericChildSections.get(sectionKey) });
            }
            Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> lineChildSectionsByKey = relatedCase.DMT_LineOpportunity__c == 'L' ? childSectionsByKey : new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
            Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> oppChildSectionsByKey = relatedCase.DMT_LineOpportunity__c == 'O' ? childSectionsByKey : new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();

            // CIBGLOBALD-4117 - callout-tracked values are never fetched synchronously here.
            // updateTaskWithStatus is called from several places beyond the ApprovalChangeStep
            // integration procedure (DMT_ApprovalTemplate_Controller, DMT_Passport_Helper.createTask),
            // and the IP itself is confirmed (production exception, 2026-09-23) to already have done
            // DML before invoking this action in at least one real flow - a callout right here throws
            // "uncommitted work pending" regardless of what this method's own DML looks like. The
            // baseline is captured after the fact, in a fresh async transaction - see the enqueue
            // below and freezeCalloutTrackableBaseline().
            String snapshotJson = DMT_TaskSnapshotService.buildSnapshotJson(
                relatedCase, fieldMapFromObject, lineMap, oppMap, customAssocMap,
                lineChildSectionsByKey, oppChildSectionsByKey, childListsBySectionKey,
                new Map<String, Object>()
            );

            // We create the DMT_TaskStatusWhenCompleted__c record which will store the data and we relate it to the task
            DMT_TaskStatusWhenCompleted__c taskStatus = new DMT_TaskStatusWhenCompleted__c();
            taskStatus.DMT_ViewFieldStatusAtClose__c = snapshotJson;
            taskStatus.Case__c = task.WhatId;
            taskStatus.DMT_AllFieldsInStatus__c = allFields;
            taskStatus.DMT_TrackedComponents__c = String.join(new List<String>(resolution.trackedComponentNames), ';');

            if (createPdf){
                //content version and core documents are generated elsewhere. if deprecated.
            }

            if (task.DMT_ViewStatusAtClose__c != null){
                taskStatus.Id = task.DMT_ViewStatusAtClose__c;
                update taskStatus;
            } else{
                insert taskStatus;
                task.DMT_ViewStatusAtClose__c = taskStatus.Id;
                update task;
            }

            // CIBGLOBALD-4117 - enqueue after the DML above (taskStatus.Id only exists once
            // inserted/confirmed) and flushed immediately, since nothing here guarantees a caller
            // downstream ever calls DMT_AsyncOrchestrator.flush() for this call path.
            for (String componentName : resolution.trackedComponentNames) {
                if (DMT_RendererFactory.isCalloutTrackable(componentName)) {
                    DMT_AsyncOrchestrator.enqueue(new DMT_CalloutTrackableFreezePayload(taskStatus.Id, lineOrOpportunityRecord.Id, componentName));
                }
            }
            if(relatedCase.opportunity_id__c != null && relatedCase.DMT_Related_feature_name__c.contains('Business') && relatedCase.DMT_Passport_Sanction__c == 'approval'){
                DMT_AsyncOrchestrator.enqueue(
                    new DMT_DynamicMapperPayload(relatedCase.opportunity_id__c, 'DMT_Finish_PAWIF', relatedCase.opportunity_id__r.StageName)
            );
            }
            
            DMT_AsyncOrchestrator.flush();
    }
    public static Id getApproverViewId(String ownerId, Case relatedCase) {
        // We make all these queries to obtain the items which contains the fields we want to store within the task
        Group queue = DMT_ApprovalChangeStep_Selector.getGroupById(ownerId);
        DMT_Approver__c approver = DMT_ApprovalChangeStep_Selector.getApproverByDmtGroup(queue.DeveloperName);
        Id approverViewId = resolveApproverViewId(approver, relatedCase);
        if(approverViewId == null){
            System.debug(LoggingLevel.ERROR, 'The approverViewId is null in DMT_ApprovalChangeStep_Handler in the getApproverViewId method.');
        }
        return approverViewId;
    }

    // CIBGLOBALD-4117 - approver view for an approver/case pair, by record type.
    public static Id resolveApproverViewId(DMT_Approver__c approver, Case relatedCase) {
        if (approver == null || relatedCase == null) {
            return null;
        }
        if (relatedCase.DMT_LineOpportunity__c == 'L') {
            String lineRecordType = relatedCase.DMT_Line__r?.RecordType?.DeveloperName;
            if (lineRecordType == 'OtherProducts') {
                return approver.Approvers_View__c;
            } else if (lineRecordType == 'TreasurySettlement') {
                return approver.Approvers_View_Treasury__c;
            }
        } else if (relatedCase.DMT_LineOpportunity__c == 'O') {
            if (relatedCase.opportunity_id__r?.RecordType?.DeveloperName == 'DMT_Opportunity') {
                return approver.Approvers_View_Opportunity__c;
            }
        }
        return null;
    }


    /**
     * @description Previews the task(s) that will be re-opened for every case on a Line or
     * Opportunity - CIBGLOBALD-4117: works off whichever parent is populated on the Case.
     * @author Aníbal Cortés | 10-02-2025
     **/
    @AuraEnabled
    public static List<FeatureChangeWrapper> previewCompareTasksFromCase(String recordId){
        // CIBGLOBALD-4117 - the two RecordType.DeveloperName relationship fields ride along on this
        // same query (no extra SOQL) so the DMT_View_Selector calls below can pass the real record
        // type instead of guessing/hardcoding it.
        List<Case> records = [SELECT Id, DMT_Related_feature_name__c, DMT_LineOpportunity__c, DMT_Line__c,
                              DMT_Line__r.Custom_Association__c, DMT_Line__r.RecordType.DeveloperName,
                              opportunity_id__c, opportunity_id__r.RecordType.DeveloperName
                              FROM Case
                              WHERE DMT_Line__c = :recordId OR opportunity_id__c = :recordId];
        if (records.isEmpty()) {
            return new List<FeatureChangeWrapper>();
        }
        Boolean isLine = records[0].DMT_LineOpportunity__c == 'L';
        String parentSectionKey = isLine ? 'line' : 'opportunity';
        String parentRecordTypeDeveloperName = isLine
            ? records[0].DMT_Line__r.RecordType.DeveloperName
            : records[0].opportunity_id__r.RecordType.DeveloperName;

        // Map that contains each Object and a list of its field Names
        Map<String, List<String>> fieldMapFromObject = new Map<String, List<String>>();
        // CIBGLOBALD-4117 - reuses the same comprehensive query DMT_ViewController uses to build the
        // rendering wrapper, instead of a hand-maintained narrow SELECT. Every field any renderer's
        // resolveRenderer()/getTrackedFields() could ever need (DMT_Product_Area__c,
        // DMT_Capital_Action__c, Custom_Association__c, etc.) is already there, so this can never again
        // drift out of sync the way DMT_ApprovalChangeStep_Selector.getCaseById did. Both selector
        // classes are now without sharing, so this carries no record-visibility regression.
        SObject parentRecord = isLine
            ? (SObject) DMT_View_Selector.getLineWithRelatedData(recordId, parentRecordTypeDeveloperName)
            : (SObject) DMT_View_Selector.getOpportunityWithRelatedData(recordId, parentRecordTypeDeveloperName);
        Id parentId = (Id) parentRecord.get('Id');
        Map<Id, String> mapCasesFeatureName = new Map<Id, String>();
        for (Case c : records){
            mapCasesFeatureName.put(c.Id, c.DMT_Related_feature_name__c);
        }

        Map<Id, Task> tasksMap = new Map<Id, Task>([SELECT Id, OwnerId, Owner.Name, DMT_Task_Type__c, WhatId, Subject, DMT_ViewStatusAtClose__c, RecordTypeId, DMT_Not_Restart__c, Status
                                                    FROM Task
                                                    WHERE WhatId IN:mapCasesFeatureName.keySet() AND Status != :DMT_Constants.CANCELLED AND DMT_Not_Restart__c = false]);

        Map<Id, Task> tasksStatusWithTaskMap = new Map<Id, Task>();
        Map<Id, List<Task>> casesWithTasksToCancel = new Map<Id, List<Task>>();

        for (Task task : tasksMap.values()){
            tasksStatusWithTaskMap.put(task.DMT_ViewStatusAtClose__c, task);
            List<Task> tasksList = new List<Task>();
            if (casesWithTasksToCancel.containsKey(task.WhatId)){
                tasksList = casesWithTasksToCancel.get(task.WhatId);
            }
            tasksList.add(task);
            casesWithTasksToCancel.put(task.WhatId, tasksList);
        }

        Map<Id, DMT_TaskStatusWhenCompleted__c> mapTaskStatus = new Map<Id, DMT_TaskStatusWhenCompleted__c>([SELECT Id, DMT_ViewFieldStatusAtClose__c, DMT_AllFieldsInStatus__c, Case__c, Case__r.Status
                                                                                                             FROM DMT_TaskStatusWhenCompleted__c
                                                                                                             WHERE Id IN:tasksStatusWithTaskMap.keySet()
                                                                                                             ORDER BY CreatedDate ASC]);
        Map<Id, List<DMT_TaskStatusWhenCompleted__c>> mapCasesTaskStatus = new Map<Id, List<DMT_TaskStatusWhenCompleted__c>>();

        for (DMT_TaskStatusWhenCompleted__c taskStatus : mapTaskStatus.values()){
            if (taskStatus.DMT_AllFieldsInStatus__c != null){
                List<DMT_TaskStatusWhenCompleted__c> taskStatusList = new List<DMT_TaskStatusWhenCompleted__c>();
                if (mapCasesTaskStatus.containsKey(taskStatus.Case__c)){
                    taskStatusList = mapCasesTaskStatus.get(taskStatus.Case__c);
                }
                taskStatusList.add(taskStatus);
                mapCasesTaskStatus.put(taskStatus.Case__c, taskStatusList);
            }
        }

        for (DMT_TaskStatusWhenCompleted__c taskStatus : mapTaskStatus.values()){
            // We get a list of each Object.Field
            if (taskStatus.DMT_AllFieldsInStatus__c != null){
                List<String> fields = taskStatus.DMT_AllFieldsInStatus__c.split(';', 0);
                //We obtain the Object Name and Field Name for each and store it in the Map
                for (String field : fields){
                    List<String> cadenaPartida = field.split('\\.', 2);
                    String objectName = cadenaPartida.get(0);
                    String fieldName = cadenaPartida.get(1);
                    List<String> fieldsFromMap = new List<String>();
                    if (fieldMapFromObject.containsKey(objectName)){
                        fieldsFromMap = fieldMapFromObject.get(objectName);
                    }
                    // If the field is already on the list, we don't store it again to prevent duplicate fields on query
                    if (!fieldsFromMap.contains(fieldName)){
                        fieldsFromMap.add(fieldName);
                        fieldMapFromObject.put(objectName, fieldsFromMap);
                    }
                }
            }
        }

        // CIBGLOBALD-4117 - live snapshot, built the same way updateTaskWithStatus/DMT_Massive_Task_Closure_Service do.
        Map<Id, SObject> lineMap = new Map<Id, SObject>();
        Map<Id, SObject> oppMap = new Map<Id, SObject>();
        String parentObjectApiName = isLine ? 'DMT_Line__c' : 'Opportunity';
        if (fieldMapFromObject.containsKey(parentObjectApiName)) {
            String query = 'SELECT Id, ' + String.join(fieldMapFromObject.get(parentObjectApiName), ',') + ' FROM ' + parentObjectApiName + ' WHERE ID = :recordId';
            List<SObject> parentsRetrieved = Database.query(String.escapeSingleQuotes(query));
            if (!parentsRetrieved.isEmpty()) {
                if (isLine) {
                    lineMap.put(parentId, parentsRetrieved.get(0));
                } else {
                    oppMap.put(parentId, parentsRetrieved.get(0));
                }
            }
        }

        Map<Id, List<SObject>> customAssocMap = new Map<Id, List<SObject>>();
        if (isLine && fieldMapFromObject.containsKey('Custom_Association_Client__c')) {
            Id customAssociationLine = (Id) parentRecord.get('Custom_Association__c');
            String query = 'SELECT Id, ' + String.join(fieldMapFromObject.get('Custom_Association_Client__c'), ',') + ' FROM Custom_Association_Client__c WHERE Custom_Association__c = :customAssociationLine ORDER BY Name ASC';
            customAssocMap.put(customAssociationLine, Database.query(String.escapeSingleQuotes(query)));
        }

        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> childSectionsByKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
        for (String componentName : DMT_RendererFactory.getTrackedComponentNames()) {
            for (DMT_ApprovalChangeStep_Helper.ChildSection section : DMT_RendererFactory.getChildSections(componentName, parentRecord)) {
                if (!childSectionsByKey.containsKey(section.snapshotSectionKey)) {
                    childSectionsByKey.put(section.snapshotSectionKey, section);
                }
            }
        }
        Map<String, List<SObject>> genericChildSections = queryDirectChildSections(childSectionsByKey, fieldMapFromObject, parentId);
        Map<String, Map<Id, List<SObject>>> childListsBySectionKey = new Map<String, Map<Id, List<SObject>>>();
        for (String sectionKey : genericChildSections.keySet()) {
            childListsBySectionKey.put(sectionKey, new Map<Id, List<SObject>>{ parentId => genericChildSections.get(sectionKey) });
        }
        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> lineChildSectionsByKey = isLine ? childSectionsByKey : new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> oppChildSectionsByKey = isLine ? new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>() : childSectionsByKey;

        // CIBGLOBALD-4117 - live callout-tracked values for this preview. This method itself
        // does no DML, but a defensive try/catch is kept anyway (matching updateTaskWithStatus) so
        // an external-service failure can never break the preview, just omit the callout-tracked
        // part of the comparison.
        Map<String, Object> calloutTrackedValuesByComponent = new Map<String, Object>();
        try {
            for (String componentName : DMT_RendererFactory.getTrackedComponentNames()) {
                DMT_CalloutTrackableRenderer calloutRenderer = DMT_RendererFactory.getCalloutTrackableRenderer(componentName);
                if (calloutRenderer != null) {
                    calloutTrackedValuesByComponent.put(componentName, calloutRenderer.fetchLiveTrackedValues(parentRecord));
                }
            }
        } catch (Exception e) {
            // Flushed immediately - this is an @AuraEnabled preview action, not a trigger, so
            // nothing downstream is guaranteed to call DMT_AsyncOrchestrator.flush() for us.
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
                'DMT_ApprovalChangeStep_Handler', 'previewCompareTasksFromCase', 'DMT', 'DMT_CalloutTrackableRenderer'
            ));
            DMT_AsyncOrchestrator.flush();
            calloutTrackedValuesByComponent.clear();
        }

        String jsonFinalSerialized = DMT_TaskSnapshotService.buildSnapshotJson(
            records[0], fieldMapFromObject, lineMap, oppMap, customAssocMap,
            lineChildSectionsByKey, oppChildSectionsByKey, childListsBySectionKey,
            calloutTrackedValuesByComponent
        );
        Map<String, Object> mapJsonFinal = (Map<String, Object>)JSON.deserializeUntyped(jsonFinalSerialized);

        List<FeatureChangeWrapper> listFeaturesToReturn = new List<FeatureChangeWrapper>();

        Map<String, Map<String, WRAPPER_Response_NewField>> mapFeaturesWithDifferentField = new Map<String, Map<String, WRAPPER_Response_NewField>>();
        Map<String, Task> mapFeatureWithTaskToCreate = new Map<String, Task>();

        for (Id caseId : mapCasesTaskStatus.keySet()){
            Boolean isDifferent = false;

            for (Integer i = 0; i < mapCasesTaskStatus.get(caseId).size(); i++){
                Map<String, Object> mapTaskStatusJson = (Map<String, Object>)JSON.deserializeUntyped(mapCasesTaskStatus.get(caseId)[i].DMT_ViewFieldStatusAtClose__c);
                for (String fieldName : mapTaskStatusJson.keySet()){
                    if (!fieldName.equalsIgnoreCase(parentSectionKey)){
                        Map<String, Object> listFromTask = (Map<String, Object>)mapTaskStatusJson.get(fieldName);
                        Map<String, Object> listFromJson = (Map<String, Object>)mapJsonFinal.get(fieldName);
                        System.debug('listFromTask: ' + listFromTask);
                        System.debug('listFromJson: ' + listFromJson);
                        if (listFromTask != null && listFromJson != null && listFromTask.size() == listFromJson.size() && listFromTask.keySet().equals(listFromJson.keySet())){
                            for (String item : listFromTask.keySet()){
                                Map<String, Object> itemFromTask = (Map<String, Object>)listFromTask.get(item);
                                Map<String, Object> itemFull = (Map<String, Object>)listFromJson.get(item);
                                for (String fieldFromItem : getComparableFieldKeys(fieldName, fieldMapFromObject, itemFromTask.keySet())){
                                    if (itemFull.get(fieldFromItem) != itemFromTask.get(fieldFromItem)){
                                        if (!isDifferent){
                                            String featureName = mapCasesFeatureName.get(caseId);
                                            Map<String, WRAPPER_Response_NewField> fieldWithValues = new Map<String, WRAPPER_Response_NewField>();
                                            WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                            valuesFromField.oldValue = (String)itemFull.get(fieldFromItem);
                                            valuesFromField.newValue = (String)itemFromTask.get(fieldFromItem);
                                            fieldWithValues.put(fieldFromItem, valuesFromField);
                                            mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                            mapFeatureWithTaskToCreate.put(featureName, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id));
                                        } else{
                                            String featureName = mapCasesFeatureName.get(caseId);
                                            Map<String, WRAPPER_Response_NewField> fieldWithValues = mapFeaturesWithDifferentField.get(featureName);
                                            WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                            valuesFromField.oldValue = (String)itemFull.get(fieldFromItem);
                                            valuesFromField.newValue = (String)itemFromTask.get(fieldFromItem);
                                            fieldWithValues.put(fieldFromItem, valuesFromField);
                                            mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                        }
                                        isDifferent = true;
                                    }
                                }
                            }
                        } else{

                            tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).Status = DMT_Constants.CANCELLED;
                            if (!isDifferent){
                                String featureName = mapCasesFeatureName.get(caseId);
                                Map<String, WRAPPER_Response_NewField> fieldWithValues = new Map<String, WRAPPER_Response_NewField>();
                                WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                valuesFromField.message = 'The list of ' + fieldName + 'is different than before';
                                fieldWithValues.put(fieldName, valuesFromField);
                                mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                mapFeatureWithTaskToCreate.put(featureName, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id));
                            } else{
                                String featureName = mapCasesFeatureName.get(caseId);
                                Map<String, WRAPPER_Response_NewField> fieldWithValues = mapFeaturesWithDifferentField.get(featureName);
                                WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                 valuesFromField.message = 'The list of ' + fieldName + 'is different than before';
                                fieldWithValues.put(fieldName, valuesFromField);
                                mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                            }
                            isDifferent = true;
                        }
                    } else{
                        Map<String, Object> itemFromTask = (Map<String, Object>)mapTaskStatusJson.get(fieldName);
                        Map<String, Object> itemFull = (Map<String, Object>)mapJsonFinal.get(fieldName);
                        if (itemFromTask != null && !itemFromTask.isEmpty()){
                            for (String fieldFromItem : getComparableFieldKeys(fieldName, fieldMapFromObject, itemFromTask.keySet())){
                                if (itemFromTask.get(fieldFromItem) instanceof Map<String, Object>){
                                    Map<String, Object> nestedFromTask = (Map<String, Object>)itemFromTask.get(fieldFromItem);
                                    Map<String, Object> nestedFromJsonFull = (Map<String, Object>)itemFull.get(fieldFromItem);
                                    for (String fieldFromNested : nestedFromTask.keySet()){
                                        if (nestedFromJsonFull.get(fieldFromNested) != nestedFromTask.get(fieldFromNested)){
                                            tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).Status = DMT_Constants.CANCELLED;
                                            if (!isDifferent){
                                                String featureName = mapCasesFeatureName.get(caseId);
                                                Map<String, WRAPPER_Response_NewField> fieldWithValues = new Map<String, WRAPPER_Response_NewField>();
                                                WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                                valuesFromField.oldValue = (String) itemFull.get(fieldFromItem);
                                                valuesFromField.newValue = (String)itemFromTask.get(fieldFromItem);
                                                fieldWithValues.put(fieldFromItem, valuesFromField);
                                                mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                                mapFeatureWithTaskToCreate.put(featureName, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id));
                                            } else{
                                                String featureName = mapCasesFeatureName.get(caseId);
                                                Map<String, WRAPPER_Response_NewField> fieldWithValues = mapFeaturesWithDifferentField.get(featureName);
                                                WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                                valuesFromField.oldValue = (String) itemFull.get(fieldFromItem);
                                                valuesFromField.newValue = (String) itemFromTask.get(fieldFromItem);
                                                fieldWithValues.put(fieldFromItem, valuesFromField);
                                                mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                            }
                                            isDifferent = true;
                                        }
                                    }
                                } else if (itemFull.get(fieldFromItem) != itemFromTask.get(fieldFromItem)){

                                    tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id).Status = DMT_Constants.CANCELLED;
                                    if (!isDifferent){
                                        String featureName = mapCasesFeatureName.get(caseId);
                                        Map<String, WRAPPER_Response_NewField> fieldWithValues = new Map<String, WRAPPER_Response_NewField>();
                                        WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                        valuesFromField.oldValue = (String) itemFull.get(fieldFromItem);
                                        valuesFromField.newValue = (String) itemFromTask.get(fieldFromItem);
                                        fieldWithValues.put(fieldFromItem, valuesFromField);
                                        mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                        mapFeatureWithTaskToCreate.put(featureName, tasksStatusWithTaskMap.get(mapCasesTaskStatus.get(caseId)[i].Id));
                                    } else{
                                        String featureName = mapCasesFeatureName.get(caseId);
                                        Map<String, WRAPPER_Response_NewField> fieldWithValues = mapFeaturesWithDifferentField.get(featureName);
                                        WRAPPER_Response_NewField valuesFromField = new WRAPPER_Response_NewField();
                                        valuesFromField.oldValue = (String) itemFull.get(fieldFromItem);
                                        valuesFromField.newValue = (String) itemFromTask.get(fieldFromItem);
                                        fieldWithValues.put(fieldFromItem, valuesFromField);
                                        mapFeaturesWithDifferentField.put(featureName, fieldWithValues);
                                    }
                                    isDifferent = true;
                                }
                            }
                        }
                    }
                }
            }

            if (!isDifferent){
                String featureName = mapCasesFeatureName.get(caseId);
                mapFeaturesWithDifferentField.put(featureName, null);
            }
        }

        for (String featureName : mapFeaturesWithDifferentField.keySet()){
            FeatureChangeWrapper feature = new FeatureChangeWrapper();
            feature.featureName = featureName;
            feature.changedFields = mapFeaturesWithDifferentField.get(featureName);
            feature.taskToRecreate = mapFeatureWithTaskToCreate.get(featureName);

            listFeaturesToReturn.add(feature);
        }

        return listFeaturesToReturn;
    }

    public class WRAPPER_Response_NewField{
        @AuraEnabled
        public String oldValue;
        @AuraEnabled
        public String newValue;
        @AuraEnabled
        public String message;
    }

    public class WRAPPER_Response_TaskFields{
        @AuraEnabled
        public String taskTypeName;
        @AuraEnabled
        public String taskOwner;
    }

    public class FeatureChangeWrapper{
        @AuraEnabled
        public String featureName;
        @AuraEnabled
        public Map<String, WRAPPER_Response_NewField> changedFields;
        @AuraEnabled
        public Task taskToRecreate;

    }

}