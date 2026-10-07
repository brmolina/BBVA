/**
 * @description Selector layer for the close-task flow.
 * Replaces the data access that was previously handled by OmniStudio extracts.
 * @author DMT Team 
 */
public with sharing class DMT_CloserTask_Selector {

    /**
     * @description Retrieves a Case together with its current open approval Task in a single query.
     * @param caseId Case identifier used as the entry point for the flow.
     * @return The Case record with its current Task pre-loaded in the Tasks child relationship, or null when no match is found.
     */
    public static Case getCaseWithCurrentTask(Id caseId) {

        List<Case> records = [
            SELECT Id, OwnerId, Description, DMT_Line__c, DMT_Line__r.Status__c, DMT_LineOpportunity__c, opportunity_id__c,
                (SELECT Id, WhatId, OwnerId, Status, Description, DMT_Task_Type__c, DMT_Step_Result__c
                 FROM Tasks
                 WHERE RecordType.DeveloperName = 'DMT_Step_Approval' AND Status NOT IN ('Finished', 'Completed')
                 ORDER BY CreatedDate DESC
                 LIMIT 1)
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    /**
     * @description Retrieves a Task Type by Id.
     * @param taskTypeId Task Type identifier.
     * @return The task type record, or null when taskTypeId is null or no row exists.
     */
    public static DMT_Task_Type__c getTaskTypeById(Id taskTypeId) {

        if (taskTypeId == null) {
            return null;
        }

        List<DMT_Task_Type__c> records = [SELECT Id, Name, CreatedDate, LastModifiedDate, DMT_External_Id__c, DMT_No_Flag__c, DMT_Yes_Flag__c, DMT_NA_Flag__c, DMT_Finish_Case__c, DMT_Send_To_Approver__c, DMT_Review_Operation__c, DMT_ApprovalEdit__c, DMT_Approver_Field__c, gf_task_ind_type__c
                                          FROM DMT_Task_Type__c
                                          WHERE Id = :taskTypeId LIMIT 1];

        return records.isEmpty() ? null : records[0];
    }

    /**
     * @description Retrieves a Task Type by external identifier.
     * @param externalId External task type identifier.
     * @return The task type record, or null when the external id is blank or not found.
     */
    public static DMT_Task_Type__c getTaskTypeByExternalId(String externalId) {

        if (String.isBlank(externalId)) {
            return null;
        }

        List<DMT_Task_Type__c> records = [SELECT Id, Name, DMT_External_Id__c, DMT_ApprovalEdit__c, DMT_Approver_Field__c, DMT_No_Flag__c, DMT_Yes_Flag__c, DMT_NA_Flag__c, DMT_Finish_Case__c, DMT_Send_To_Approver__c, DMT_Review_Operation__c, gf_task_ind_type__c
                                          FROM DMT_Task_Type__c
                                          WHERE DMT_External_Id__c = :externalId LIMIT 1];

        return records.isEmpty() ? null : records[0];
    }

    /**
     * @description Retrieves the ordered task-type relationships for a source task type.
     * The result is sorted by the lowest DMT_Order_Number__c first and, for ties,
     * by the most recently created relationship.
     * @param fromTaskTypeId Source task type identifier.
     * @return Ordered relationship records, or an empty list when the source id is null.
     */
    public static List<DMT_Task_Relationship__c> getTaskRelationships(Id fromTaskTypeId) {

        if (fromTaskTypeId == null) {
            return new List<DMT_Task_Relationship__c>();
        }

        return [SELECT Id, Name, CreatedDate, DMT_From_Task_Type__c, DMT_To_Task_Type__c, DMT_Order_Number__c
            FROM DMT_Task_Relationship__c
            WHERE DMT_From_Task_Type__c = :fromTaskTypeId AND DMT_Order_Number__c != null
            ORDER BY DMT_Order_Number__c ASC, CreatedDate DESC];
    }

    /**
     * @description Retrieves multiple Task Type records by their Ids.
     * @param taskTypeIds Set of task type identifiers to retrieve.
     * @return Matching task type records, or an empty list when the input set is blank.
     */
    public static List<DMT_Task_Type__c> getTaskTypesByIds(Set<Id> taskTypeIds) {

        if (taskTypeIds == null || taskTypeIds.isEmpty()) {
            return new List<DMT_Task_Type__c>();
        }

        return [SELECT Id, Name, CreatedDate, LastModifiedDate, DMT_External_Id__c, DMT_ApprovalEdit__c, DMT_Approver_Field__c, DMT_No_Flag__c, DMT_Yes_Flag__c, DMT_NA_Flag__c, DMT_Finish_Case__c, DMT_Send_To_Approver__c, DMT_Review_Operation__c, gf_task_ind_type__c
            FROM DMT_Task_Type__c
            WHERE Id IN :taskTypeIds];
    }

    /**
     * @description Retrieves the approver relationships associated with a task type.
     * @param taskTypeId Task type identifier.
     * @return Relationship records linking the task type to its approvers, or an empty list.
     */
    public static List<DMT_Task_Approver_Relationship__c> getTaskApproverRelationships(Id taskTypeId) {

        if (taskTypeId == null) {
            return new List<DMT_Task_Approver_Relationship__c>();
        }

        return [ SELECT Id, DMT_Task_Type__c, DMT_Approver__c FROM DMT_Task_Approver_Relationship__c WHERE DMT_Task_Type__c = :taskTypeId];
    }

    /**
     * @description Retrieves approver records by Id.
     * @param approverIds Approver identifiers.
     * @return Matching approver records, or an empty list when the input set is blank.
     */
    public static List<DMT_Approver__c> getApproversByIds(Set<Id> approverIds) {

        if (approverIds == null || approverIds.isEmpty()) {
            return new List<DMT_Approver__c>();
        }

        return [ SELECT Id, Name, DMT_External_Id__c, DMT_Approver_Type__c, DMT_Approver_Code__c, DMT_Group__c FROM DMT_Approver__c WHERE Id IN :approverIds ORDER BY Name];
    }


    /**
     * @description Retrieves a Group record by Id.
     * @param groupId Group identifier.
     * @return The Group record, or null when no match is found.
     */
    public static Group getGroupById(Id groupId) {

        if (groupId == null) {
            return null;
        }

        List<Group> groups = [ SELECT Id, Name, DeveloperName FROM Group WHERE Id = :groupId LIMIT 1];

        return groups.isEmpty() ? null : groups[0];
    }


    /**
     * @description Retrieves an Approver by external identifier.
     * Supports the close-step flow (CIBGLOBALD-4025).
     * @param externalId External approver identifier.
     * @return The approver record, or null when the external id is blank or no match is found.
     */
    public static DMT_Approver__c getApproverByExternalId(String externalId) {

        if (String.isBlank(externalId)) {
            return null;
        }

        List<DMT_Approver__c> records = [SELECT Id, Name, DMT_External_Id__c, DMT_Group__c
                                          FROM DMT_Approver__c
                                          WHERE DMT_External_Id__c = :externalId LIMIT 1];

        return records.isEmpty() ? null : records[0];
    }


    /**
     * @description Retrieves a Group by developer name.
     * Supports the close-step flow (CIBGLOBALD-4025).
     * @param developerName Group developer name.
     * @return The Group record, or null when the developer name is blank or no match is found.
     */
    public static Group getGroupByDeveloperName(String developerName) {

        if (String.isBlank(developerName)) {
            return null;
        }

        List<Group> groups = [SELECT Id, Name, DeveloperName
                               FROM Group
                               WHERE DeveloperName = :developerName LIMIT 1];

        return groups.isEmpty() ? null : groups[0];
    }


    /**
     * @description Retrieves approvers associated with a group developer name.
     * @param developerName Group developer name.
     * @return Approvers linked to the group, or an empty list when the name is blank.
     */
    public static List<DMT_Approver__c> getApproversByGroup(
        String developerName
    ) {

        if (String.isBlank(developerName)) {
            return new List<DMT_Approver__c>();
        }

        return [SELECT Id, Name, DMT_Group__c, DMT_Approver_Type__c, DMT_Approver_Code__c FROM DMT_Approver__c WHERE DMT_Group__c = :developerName];
    }


    /**
     * @description Retrieves approver member records for a set of approvers and a user.
     * @param approverIds Approver identifiers to inspect.
     * @param userId User identifier.
     * @return Matching approver member records, or an empty list when inputs are invalid.
     */
    public static List<DMT_Approver_Member__c> getApproverMembers(Set<Id> approverIds, Id userId) {

        if ( approverIds == null ||approverIds.isEmpty() ||userId == null) {
            return new List<DMT_Approver_Member__c>();
        }

        return [SELECT Id, DMT_Approver__c, DMT_User__c, DMT_Access_Level__c
                FROM DMT_Approver_Member__c
                WHERE DMT_Approver__c IN :approverIds AND DMT_User__c = :userId];
    }

    /**
     * @description Retrieves the open Cases associated with a line.
     * @param lineId Line identifier.
     * @return Open Cases linked to the line, or an empty list when the line id is null.
     */
    public static List<Case> getOpenCasesByLine(Id lineId) {

        if (lineId == null) {
            return new List<Case>();
        }

        return [SELECT Id, DMT_Line__c, DMT_Related_feature_name__c, IsClosed
                FROM Case
                WHERE DMT_Line__c = :lineId  AND IsClosed = false];
    }

    /**
     * @description Retrieves approval-enabled tasks for related Cases on the same line.
     * @param caseIds Related Case identifiers.
     * @param currentTaskId Current Task identifier to exclude from results.
     * @return Matching Task records, or an empty list when the Case set is blank.
     */
    public static List<Task> getRelatedLineTasks(Set<Id> caseIds, Id currentTaskId) {

        if (caseIds == null || caseIds.isEmpty()) {
            return new List<Task>();
        }

        return [
            SELECT Id, WhatId, OwnerId, Owner.Name, Status, DMT_Task_Type__c, DMT_Task_Type__r.Name, DMT_Task_Type__r.DMT_ApprovalEdit__c
            FROM Task
            WHERE WhatId IN :caseIds AND Id != :currentTaskId AND Status NOT IN ( 'Cancelled', 'Completed', 'Finished')
            AND DMT_Task_Type__r.DMT_ApprovalEdit__c = true];
    }


    /**
     * @description Retrieves the Opportunity context required by the close-task flow.
     * @param opportunityId Opportunity identifier.
     * @return The Opportunity record, or null when no match is found.
     */
    public static Opportunity getOpportunity(Id opportunityId) {

        if (opportunityId == null) {
            return null;
        }

        List<Opportunity> records = [SELECT Id, DMT_Approver__c, DMT_Approver__r.DMT_Approver_Code__c, DMT_ApproverGlobalBanker__c, DMT_ApproverGlobalBanker__r.DMT_Approver_Code__c, DMT_Booking_Unit_Risk_Analyst__c, DMT_Booking_Unit_Risk_Analyst__r.DMT_Approver_Code__c
                                     FROM Opportunity
                                     WHERE Id = :opportunityId
                                     LIMIT 1];

        return records.isEmpty() ? null : records[0];
    }


    /**
     * @description Retrieves the line context required by the close-task flow.
     * @param lineId Line identifier.
     * @return The line record, or null when no match is found.
     */
    public static DMT_Line__c getLine(Id lineId) {

        if (lineId == null) {
            return null;
        }
        List<DMT_Line__c> records = [SELECT Id, DMT_Approver__c, DMT_Approver__r.DMT_Approver_Code__c, DMT_ApproverGlobalBanker__c, DMT_ApproverGlobalBanker__r.DMT_Approver_Code__c, DMT_Booking_Unit_Risk_Analyst__c, DMT_Booking_Unit_Risk_Analyst__r.DMT_Approver_Code__c
                                     FROM DMT_Line__c
                                     WHERE Id = :lineId
                                     LIMIT 1];

        return records.isEmpty() ? null : records[0];
    }
}