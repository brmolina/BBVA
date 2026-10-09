public without sharing class DMT_ApprovalChangeStep_Selector {

    public static Task getTaskById(Id recordId) {
        return [SELECT Id, OwnerId, WhatId, DMT_Task_Type__c, DMT_ViewStatusAtClose__c FROM Task WHERE Id =: recordId WITH SYSTEM_MODE LIMIT 1];
    }

    // CIBGLOBALD-4117 - single source of truth for Case routing info (Line/Opportunity lookup,
    // RecordType, Custom_Association__c, Booking_Geography__c), shared by the single-task freeze path
    // (getCaseById below), the bulk massive-closure freeze path, and the preview path.
    // DMT_Product_Area__c/DMT_Capital_Action__c are the two exceptions kept here rather than pushed
    // to DMT_View_Selector: every NBC IBF/GTB delegator's resolveRenderer() needs them to route, and
    // DMT_Massive_Task_Closure_Service works directly off this Case-level record for its whole batch
    // (by design, for bulk scalability - it never fetches a full Opportunity/Line per task the way
    // updateTaskWithStatus/previewCompareTasksFromCase do), so it has no other way to see them. Any
    // OTHER field a delegator needs belongs on DMT_View_Selector.getOpportunityWithRelatedData()/
    // getLineWithRelatedData() instead, picked up automatically by the single-record freeze/preview
    // paths - only add here if DMT_Massive_Task_Closure_Service's bulk routing genuinely needs it too.
    public static Map<Id, Case> getCasesByIds(Set<Id> caseIds) {
        return new Map<Id, Case>([
            SELECT Id, OwnerId, DMT_Line__c, opportunity_id__c, DMT_Related_feature_name__c,
                   DMT_Line__r.Custom_Association__c, DMT_Line__r.RecordType.DeveloperName,
                   DMT_Line__r.RecordTypeId, DMT_Line__r.Booking_Geography__c,
                   DMT_LineOpportunity__c,
                   opportunity_id__r.RecordType.DeveloperName, opportunity_id__r.RecordTypeId,
                   opportunity_id__r.DMT_Product_Area__c, opportunity_id__r.DMT_Capital_Action__c,
                   DMT_Passport_Sanction__c,opportunity_id__r.StageName
            FROM Case
            WHERE Id IN :caseIds
            WITH SYSTEM_MODE
        ]);
    }

    // CIBGLOBALD-4117 - thin single-record wrapper so every caller shares the exact same query
    // instead of maintaining its own.
    public static Case getCaseById(Id recordId) {
        Map<Id, Case> results = getCasesByIds(new Set<Id>{ recordId });
        return results.isEmpty() ? null : results.values()[0];
    }

    public static Group getGroupById(Id recordId) {
        return [SELECT Id, DeveloperName FROM Group WHERE Type =: DMT_Constants.TYPE_GROUP_QUEUE and Id =: recordId WITH SYSTEM_MODE LIMIT 1];
    }

    public static DMT_Approver__c getApproverByDmtGroup(String groupName) {
        return [SELECT Id, Approvers_View__c, Approvers_View_Treasury__c, Approvers_View_Opportunity__c FROM DMT_Approver__c WHERE DMT_Group__c =: groupName WITH SYSTEM_MODE LIMIT 1];
    }

    public static List<DMT_Items__c> getItemsByDmtView(String viewName) {
        return  [SELECT Id, DMT_Campos_componente__c, DMT_Component_Item__c FROM DMT_Items__c WHERE DMT_View__c =: viewName  WITH SYSTEM_MODE ORDER BY Name ASC];
    }
}