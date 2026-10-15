/**
 * @description Selector layer for DMT ApprovalTemplate workflow.
 * Centralizes all SOQL queries for Case, Task, Task Types, Relationships, Approvers, and Groups.
 * @author DMT Team | CIBGLOBALD-REFACTOR | Phase 1: Clean Orchestration
 */
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class DMT_ApprovalTemplate_Selector {

    /**
     * @description Retrieves Case with related Line and basic information
     * @param recordId Case ID to retrieve
     * @return Case record with Line__r and related fields, null if not found
     */
    public static Case getCaseWithLineAndBasics(Id recordId) {
        List<Case> cases = [
            SELECT Id, OwnerId, Description, DMT_Line__c, DMT_Line__r.Status__c, DMT_LineOpportunity__c,
                   DMT_Closing_Tasks__c, DMT_Passport_Sanction__c, opportunity_id__c
            FROM Case
            WHERE Id = :recordId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return cases.isEmpty() ? null : cases[0];
    }

    /**
     * @description Retrieves a Case together with its current open approval Task.
     * @param caseId Case identifier used as the entry point for the flow.
     * @return The Case record with its current Task pre-loaded in the Tasks child relationship.
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
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }

    /**
     * @description Gets the RecordType ID for DMT_Step_Approval on Task object
     * @return RecordType ID for DMT_Step_Approval, null if not found
     */
    public static Id getDmtStepApprovalRecordTypeId() {
        List<RecordType> rts = [ // NOPMD
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Task' AND DeveloperName = 'DMT_Step_Approval'
            LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    /**
     * @description Retrieves current pending Task for a Case with DMT_Step_Approval RecordType
     * @param recordId Case ID
     * @param rtId RecordType ID for DMT_Step_Approval
     * @return Pending Task record, null if not found
     */
    public static Task getCurrentPendingTask(Id recordId, Id rtId) {
        List<Task> tasks = [
            SELECT Id, Status, Description, DMT_Step_Result__c, DMT_Step_Type__c, DMT_Not_Restart__c,
                   DMT_Committee_Label__c, DMT_Task_Type__c, WhatId
            FROM Task
            WHERE WhatId = :recordId
            AND RecordTypeId = :rtId
            AND Status NOT IN ('Finished', 'Completed')
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return tasks.isEmpty() ? null : tasks[0];
    }

    /**
     * @description Retrieves a specific DMT_Task_Type__c record by ID
     * @param taskTypeId DMT_Task_Type__c ID
     * @return DMT_Task_Type__c record with validation fields, null if not found
     */
    public static DMT_Task_Type__c getTaskType(Id taskTypeId) {
        List<DMT_Task_Type__c> taskTypes = [
            SELECT Id, Name, CreatedDate, LastModifiedDate, DMT_External_Id__c, DMT_ApprovalEdit__c, DMT_Finish_Case__c,
                   DMT_Send_To_Approver__c, DMT_Review_Operation__c, DMT_No_Flag__c, DMT_Yes_Flag__c, DMT_NA_Flag__c, gf_task_ind_type__c
            FROM DMT_Task_Type__c
            WHERE Id = :taskTypeId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return taskTypes.isEmpty() ? null : taskTypes[0];
    }

    /**
     * @description Retrieves a Task Type by external identifier.
     * @param externalId External task type identifier.
     * @return Matching task type record or null.
     */
    public static DMT_Task_Type__c getTaskTypeByExternalId(String externalId) {
        if (String.isBlank(externalId)) {
            return null;
        }

        List<DMT_Task_Type__c> records = [
            SELECT Id, Name, DMT_External_Id__c, DMT_ApprovalEdit__c, DMT_Approver_Field__c,
                   DMT_No_Flag__c, DMT_Yes_Flag__c, DMT_NA_Flag__c, DMT_Finish_Case__c,
                   DMT_Send_To_Approver__c, DMT_Review_Operation__c, gf_task_ind_type__c
            FROM DMT_Task_Type__c
            WHERE DMT_External_Id__c = :externalId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    /**
     * @description Retrieves Task Relationships for a given Task Type (relationships originating from this task)
     * @param fromTaskTypeId DMT_Task_Type__c ID to retrieve relationships from
     * @return List of DMT_Task_Relationship__c records
     */
    public static List<DMT_Task_Relationship__c> getTaskRelationships(Id fromTaskTypeId) {
        if (fromTaskTypeId == null) {
            return new List<DMT_Task_Relationship__c>();
        }

        return [
            SELECT Id, Name, CreatedDate, DMT_From_Task_Type__c, DMT_To_Task_Type__c,
                   DMT_Order_Number__c
            FROM DMT_Task_Relationship__c
            WHERE DMT_From_Task_Type__c = :fromTaskTypeId AND DMT_Order_Number__c != null
            WITH SECURITY_ENFORCED
            ORDER BY DMT_Order_Number__c ASC, CreatedDate DESC
        ];
    }

    /**
     * @description Retrieves Task Type records by a set of IDs
     * @param taskTypeIds Set of DMT_Task_Type__c IDs
     * @return List of DMT_Task_Type__c records
     */
    public static List<DMT_Task_Type__c> getTaskTypesByIds(Set<Id> taskTypeIds) {
        if (taskTypeIds == null || taskTypeIds.isEmpty()) {
            return new List<DMT_Task_Type__c>();
        }

        return [
            SELECT Id, Name, CreatedDate, LastModifiedDate, DMT_External_Id__c, DMT_ApprovalEdit__c, DMT_Finish_Case__c,
                   DMT_Send_To_Approver__c, DMT_Review_Operation__c, DMT_Approver_Field__c,
                   DMT_No_Flag__c, DMT_Yes_Flag__c, DMT_NA_Flag__c, gf_task_ind_type__c
            FROM DMT_Task_Type__c
            WHERE Id IN :taskTypeIds
            WITH SECURITY_ENFORCED
            ORDER BY Name ASC
        ];
    }

    /**
     * @description Retrieves approvers associated with a task type in a single query.
     * @param taskTypeId Task type identifier.
     * @return Matching approver records.
     */
    public static List<DMT_Approver__c> getApproversForTaskType(Id taskTypeId) {
        if (taskTypeId == null) {
            return new List<DMT_Approver__c>();
        }

        return [
            SELECT Id, Name, DMT_External_Id__c, DMT_Approver_Type__c, DMT_Approver_Code__c, DMT_Group__c
            FROM DMT_Approver__c
            WHERE Id IN (
                SELECT DMT_Approver__c
                FROM DMT_Task_Approver_Relationship__c
                WHERE DMT_Task_Type__c = :taskTypeId
            )
            WITH SECURITY_ENFORCED
            ORDER BY Name
        ];
    }

    /**
     * @description Retrieves related Tasks for a Case (DMT_Step_Approval tasks excluding current task)
     * @param recordId Case ID
     * @param rtId RecordType ID for DMT_Step_Approval
     * @param currentTaskId Current Task ID to exclude
     * @return List of related Task records
     */
    public static List<Task> getRelatedTasksForCase(Id recordId, Id rtId, Id currentTaskId) {
        return [
            SELECT Id, Status, DMT_Step_Type__c, WhatId
            FROM Task
            WHERE WhatId = :recordId
            AND RecordTypeId = :rtId
            AND Id != :currentTaskId
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
        ];
    }

    /**
     * @description Retrieves related Tasks for validation purposes (excluding current task)
     * @param caseId Case ID
     * @param rtId RecordType ID for DMT_Step_Approval
     * @param currentTaskId Current Task ID to exclude
     * @return List of Task records with DMT_Task_Type__c
     */
    public static List<Task> getRelatedTasksForValidation(Id caseId, Id rtId, Id currentTaskId) {
        return [
            SELECT Id, DMT_Task_Type__c
            FROM Task
            WHERE WhatId = :caseId
            AND RecordTypeId = :rtId
            AND Id != :currentTaskId
            AND Status != 'Finished'
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
        ];
    }

    /**
     * @description Retrieves a Group record by owner ID
     * @param ownerId User/Group ID that owns a Case
     * @return Group record if owner is a Group, null otherwise
     */
    public static Group getGroupByOwnerId(Id ownerId) {
        List<Group> groups = [
            SELECT Id, DeveloperName, Name
            FROM Group
            WHERE Id = :ownerId
            WITH USER_MODE
            LIMIT 1
        ];
        return groups.isEmpty() ? null : groups[0];
    }

    /**
     * @description Retrieves a Group by developer name.
     * @param developerName Group developer name.
     * @return Matching group record or null.
     */
    public static Group getGroupByDeveloperName(String developerName) {
        if (String.isBlank(developerName)) {
            return null;
        }

        List<Group> groups = [
            SELECT Id, Name, DeveloperName
            FROM Group
            WHERE DeveloperName = :developerName
            WITH USER_MODE
            LIMIT 1
        ];

        return groups.isEmpty() ? null : groups[0];
    }

    /**
     * @description Retrieves an Approver by external identifier.
     * @param externalId External approver identifier.
     * @return Matching approver record or null.
     */
    public static DMT_Approver__c getApproverByExternalId(String externalId) {
        if (String.isBlank(externalId)) {
            return null;
        }

        List<DMT_Approver__c> records = [
            SELECT Id, Name, DMT_External_Id__c, DMT_Group__c
            FROM DMT_Approver__c
            WHERE DMT_External_Id__c = :externalId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    /**
     * @description Retrieves approvers associated with a group developer name.
     * @param developerName Group developer name.
     * @return Matching approvers.
     */
    public static List<DMT_Approver__c> getApproversByGroup(String developerName) {
        if (String.isBlank(developerName)) {
            return new List<DMT_Approver__c>();
        }

        return [
            SELECT Id, Name, DMT_Group__c, DMT_Approver_Type__c, DMT_Approver_Code__c
            FROM DMT_Approver__c
            WHERE DMT_Group__c = :developerName
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description Retrieves approver member records for a set of approvers and a user.
     * @param approverIds Approver identifiers to inspect.
     * @param userId User identifier.
     * @return Matching approver member records.
     */
    public static List<DMT_Approver_Member__c> getApproverMembers(Set<Id> approverIds, Id userId) {
        if (approverIds == null || approverIds.isEmpty() || userId == null) {
            return new List<DMT_Approver_Member__c>();
        }

        return [
            SELECT Id, DMT_Approver__c, DMT_User__c, DMT_Access_Level__c
            FROM DMT_Approver_Member__c
            WHERE DMT_Approver__c IN :approverIds AND DMT_User__c = :userId
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description Retrieves approver members for the current user and owner group in a single query.
     * @param developerName Group developer name.
     * @param userId User identifier.
     * @return Matching approver member records.
     */
    public static List<DMT_Approver_Member__c> getApproverMembersByGroupAndUser(String developerName, Id userId) {
        if (String.isBlank(developerName) || userId == null) {
            return new List<DMT_Approver_Member__c>();
        }

        return [
            SELECT Id, DMT_Approver__c, DMT_User__c, DMT_Access_Level__c
            FROM DMT_Approver_Member__c
            WHERE DMT_User__c = :userId
              AND DMT_Approver__r.DMT_Group__c = :developerName
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description Retrieves the open Cases associated with a line.
     * @param lineId Line identifier.
     * @return Open Cases linked to the line.
     */
    public static List<Case> getOpenCasesByLine(Id lineId) {
        if (lineId == null) {
            return new List<Case>();
        }

        return [
            SELECT Id, DMT_Line__c, DMT_Related_feature_name__c, IsClosed
            FROM Case
            WHERE DMT_Line__c = :lineId AND IsClosed = false
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description Retrieves approval-enabled tasks for related Cases on the same line.
     * @param caseIds Related Case identifiers.
     * @param currentTaskId Current Task identifier to exclude from results.
     * @return Matching Task records.
     */
    public static List<Task> getRelatedLineTasks(Set<Id> caseIds, Id currentTaskId) {
        if (caseIds == null || caseIds.isEmpty()) {
            return new List<Task>();
        }

        return [
            SELECT Id, WhatId, OwnerId, Owner.Name, Status, DMT_Task_Type__c,
                   DMT_Task_Type__r.Name, DMT_Task_Type__r.DMT_ApprovalEdit__c
            FROM Task
            WHERE WhatId IN :caseIds
              AND Id != :currentTaskId
              AND Status NOT IN ('Cancelled', 'Completed', 'Finished')
              AND DMT_Task_Type__r.DMT_ApprovalEdit__c = true
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description Retrieves the Opportunity context required by the close-task flow.
     * @param opportunityId Opportunity identifier.
     * @return Matching Opportunity record or null.
     */
    public static Opportunity getOpportunity(Id opportunityId) {
        if (opportunityId == null) {
            return null;
        }

        List<Opportunity> records = [
            SELECT Id, DMT_Approver__c, DMT_Approver__r.DMT_Approver_Code__c,
                   DMT_ApproverGlobalBanker__c, DMT_ApproverGlobalBanker__r.DMT_Approver_Code__c,
                   DMT_Booking_Unit_Risk_Analyst__c, DMT_Booking_Unit_Risk_Analyst__r.DMT_Approver_Code__c
            FROM Opportunity
            WHERE Id = :opportunityId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    /**
     * @description Retrieves the line context required by the close-task flow.
     * @param lineId Line identifier.
     * @return Matching line record or null.
     */
    public static DMT_Line__c getLine(Id lineId) {
        if (lineId == null) {
            return null;
        }

        List<DMT_Line__c> records = [
            SELECT Id, DMT_Approver__c, DMT_Approver__r.DMT_Approver_Code__c,
                   DMT_ApproverGlobalBanker__c, DMT_ApproverGlobalBanker__r.DMT_Approver_Code__c,
                   DMT_Booking_Unit_Risk_Analyst__c, DMT_Booking_Unit_Risk_Analyst__r.DMT_Approver_Code__c
            FROM DMT_Line__c
            WHERE Id = :lineId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }
}