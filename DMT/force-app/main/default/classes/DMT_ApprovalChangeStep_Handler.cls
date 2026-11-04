/**
 * @description       : Class called via the integration procedure ApprovalChangeStep
 * @author            : Aníbal Cortés
 * @group             :
 * @last modified on  : 10-31-2024
 * @last modified by  : Aníbal Cortés
 **/
global without sharing class DMT_ApprovalChangeStep_Handler implements Callable{

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
                // Multi-object renderer already says which object each field belongs to, so
                // don't prefix with sObjectApiName like the single-object fields below.
                for (String objectName : fieldsByObject.keySet()) {
                    for (String fieldName : fieldsByObject.get(objectName)) {
                        fields.add(objectName + '.' + fieldName);
                    }
                }
                // CIBGLOBALD-4117 - always added as well, never as an else of the block above: the
                // restart gate (DMT_ApprovalChangeStep_Helper.isTaskStale) compares getTrackedFields()
                // for every component, so a component that returns BOTH (Opportunity 'Approval
                // Process Data': SPPI fields + Financial Sponsors on the Opportunity, rest on child
                // objects) must also freeze them, or they read as changed on every resubmission.
                // Duplicates with the map above are removed by the contains() check further down.
                for (String fieldName : DMT_RendererFactory.getTrackedFields(item.DMT_Component_Item__c, record)) {
                    fields.add(sObjectApiName + '.' + fieldName);
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
        // query DMT_ViewController uses to build the rendering wrapper - every field any renderer's resolveRenderer()/ // CIBGLOBALD-4811
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
                if (fieldMapFromObject.containsKey('Opportunity')){
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
     * @description CIBGLOBALD-4811 - The features that would reopen, for the 'Features to Be Reopened'
     * warning (dmt_custom_path_line, dmt_custom_path_opp, dmt_custom_path_refactor). The LWC decides when to check; this
     * reads the Cases of that checkpoint and asks DMT_ApprovalChangeStep_Helper.findTasksToRestart,
     * the same comparison as the triggers. Restarts nothing. Empty when nothing reopens or the check
     * fails: a failure is logged and never stops the user.
     * Callout: only when the Salesforce data shows no change, the snapshot's callout-tracked
     * components are fetched (DMT_CalloutTrackableRenderer.fetchLiveTrackedValues).
     * @param recordId the DMT_Line__c or Opportunity
     * @param caseTypeToCheck Case.DMT_Passport_Sanction__c value: passport, approval or readytoclose
     **/
    @AuraEnabled
    public static List<FeatureChangeWrapper> previewCompareTasksFromCase(String recordId, String caseTypeToCheck){
        return previewUnsavedChanges(recordId, caseTypeToCheck, null, null); // CIBGLOBALD-4811
    }

    /**
     * @description CIBGLOBALD-4811 - The same check as previewCompareTasksFromCase for a tab save: the values
     * the user changed and has not saved yet are put on the stored record before the comparison, so the
     * answer is what the trigger would do on that save (dmt_opp_info, dmt_lineInfo, dmt_opp_client: Ready to close). Restarts nothing,
     * saves nothing. Empty when nothing reopens or the check fails (logged).
     * @param recordId the DMT_Line__c or Opportunity
     * @param caseTypeToCheck Case.DMT_Passport_Sanction__c value: passport, approval or readytoclose
     * @param unsavedValues field API name -> value, only the fields changed in the tab
     * @param unsavedRows child rows the tab saves, each {objectApiName, rowId, values}; null when the tab
     * saves no child rows (dmt_opp_client sends the main borrower DMT_Opportunity_Client__c row)
     **/
    @AuraEnabled
    public static List<FeatureChangeWrapper> previewCompareUnsavedChanges(String recordId, String caseTypeToCheck, Map<String, Object> unsavedValues, List<Map<String, Object>> unsavedRows){
        return previewUnsavedChanges(recordId, caseTypeToCheck, unsavedValues, unsavedRows);
    }

    // CIBGLOBALD-4811 - shared body of previewCompareTasksFromCase and previewCompareUnsavedChanges, also called
    // from Apex (DMT_OpportunityProductsController.previewOpportunityProductSave).
    public static List<FeatureChangeWrapper> previewUnsavedChanges(String recordId, String caseTypeToCheck, Map<String, Object> unsavedValues, List<Map<String, Object>> unsavedRows){
        List<FeatureChangeWrapper> features = new List<FeatureChangeWrapper>();
        try {
            Id parentId = recordId;
            Map<Id, Case> casesById = new Map<Id, Case>([
                SELECT Id, DMT_Related_feature_name__c
                FROM Case
                WHERE (DMT_Line__c = :parentId OR opportunity_id__c = :parentId)
                AND DMT_Passport_Sanction__c = :caseTypeToCheck
            ]);
            if (casesById.isEmpty()) {
                return features;
            }
            Map<Id, Id> caseIdToRecordId = new Map<Id, Id>();
            for (Id caseId : casesById.keySet()) {
                caseIdToRecordId.put(caseId, parentId);
            }

            String snapshotSectionKey = parentId.getSObjectType() == DMT_Line__c.SObjectType ? 'line' : 'opportunity';
            Map<Id, List<String>> changesByTaskId = DMT_ApprovalChangeStep_Helper.findTasksToRestart(parentId, caseIdToRecordId, snapshotSectionKey, unsavedValues, unsavedRows);
            features = buildFeatures(changesByTaskId, casesById, parentId.getSObjectType());
        } catch (Exception e) {
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
                'DMT_ApprovalChangeStep_Handler', 'previewUnsavedChanges', 'DMT', 'Task'
            ));
        }
        DMT_AsyncOrchestrator.flush();
        return features;
    }

    // CIBGLOBALD-4811 - one wrapper per Case, with its oldest task: the one
    // DMT_ApprovalChangeStep_Helper.restartTasksForRecord clones, and the changes of all its stale tasks.
    private static List<FeatureChangeWrapper> buildFeatures(Map<Id, List<String>> changesByTaskId, Map<Id, Case> casesById, Schema.SObjectType parentType) {
        Map<Id, FeatureChangeWrapper> featuresByCaseId = new Map<Id, FeatureChangeWrapper>();
        Set<Id> taskIds = changesByTaskId.keySet();
        for (Task task : [SELECT Id, WhatId, OwnerId, Owner.Name FROM Task WHERE Id IN :taskIds ORDER BY CreatedDate ASC]) {
            if (!featuresByCaseId.containsKey(task.WhatId)) {
                FeatureChangeWrapper feature = new FeatureChangeWrapper();
                feature.featureName = casesById.get(task.WhatId).DMT_Related_feature_name__c;
                feature.taskToRecreate = task;
                feature.changedFields = new Map<String, WRAPPER_Response_NewField>();
                featuresByCaseId.put(task.WhatId, feature);
            }
            for (String change : changesByTaskId.get(task.Id)) {
                featuresByCaseId.get(task.WhatId).changedFields.put(displayLabel(change, parentType), new WRAPPER_Response_NewField());
            }
        }
        return featuresByCaseId.values();
    }

    // CIBGLOBALD-4811 - the label the approver sees: renderer DisplayField, then describe label.
    // A component name (child rows, callout values) has neither and is shown as it is.
    private static String displayLabel(String change, Schema.SObjectType parentType) {
        String rendererLabel = DMT_FormattingUtils.labelByFieldApiName.get(change);
        if (rendererLabel != null) {
            return rendererLabel.removeEnd(':');
        }
        Schema.SObjectField field = parentType.getDescribe().fields.getMap().get(change);
        return field != null ? field.getDescribe().getLabel() : change;
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