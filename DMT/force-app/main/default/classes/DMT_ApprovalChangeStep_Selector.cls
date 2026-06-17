public without sharing class DMT_ApprovalChangeStep_Selector {

    public static Task getTaskById(Id recordId) {
        return [SELECT Id, OwnerId, WhatId, DMT_Task_Type__c, DMT_ViewStatusAtClose__c FROM Task WHERE Id =: recordId WITH USER_MODE LIMIT 1];
    }

    public static Case getCaseById(Id recordId) {
        return [SELECT DMT_Line__c, opportunity_id__c, DMT_Line__r.Custom_Association__c, DMT_LineOpportunity__c,opportunity_id__r.RecordType.DeveloperName, DMT_Line__r.RecordType.DeveloperName FROM Case WHERE Id = : recordId WITH USER_MODE LIMIT 1];
    }

    public static Group getGroupById(Id recordId) {
        return [SELECT Id, DeveloperName FROM Group WHERE Type =: DMT_Constants.TYPE_GROUP_QUEUE and Id =: recordId WITH USER_MODE LIMIT 1];
    }

    public static DMT_Approver__c getApproverByDmtGroup(String groupName) {
        return [SELECT Id, Approvers_View__c, Approvers_View_Treasury__c, Approvers_View_Opportunity__c FROM DMT_Approver__c WHERE DMT_Group__c =: groupName WITH USER_MODE LIMIT 1];
    }

    public static List<DMT_Items__c> getItemsByDmtView(String viewName) {
        return  [SELECT Id, DMT_Campos_componente__c, DMT_Campos_componente_Refact__c FROM DMT_Items__c WHERE DMT_View__c =: viewName  WITH USER_MODE ORDER BY Name ASC];
    }
}