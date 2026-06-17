/**
 * @description Selector class for email service related SOQL queries.
 */
public with sharing class DMT_SendEmailService_Selector {
    /**
     * @description Retrieves approved team members linked to an Opportunity.
     * @param opportunityId Opportunity Id.
     * @return List of matching team members.
     */
    public static List<DMT_TeamMember__c> getTeamMembersByOpportunityId(Id opportunityId) {
        return [SELECT Id, Opportunity__c, User__c, User__r.Email, DMT_ApprovalEdit__c 
                FROM DMT_TeamMember__c 
                WHERE Opportunity__c = :opportunityId
                AND DMT_ApprovalEdit__c = true AND User__c != null
                WITH USER_MODE ];
    }

    /**
        * @description Retrieves approved team members linked to a Line.
     * @param lineId DMT_Line__c Id.
     * @return List of matching team members.
     */
    public static List<DMT_TeamMember__c> getTeamMembersByLineId(Id lineId) {
        return [SELECT Id, Line__c, User__c, User__r.Email, DMT_ApprovalEdit__c
                FROM DMT_TeamMember__c
                WHERE Line__c = :lineId AND DMT_ApprovalEdit__c = true AND User__c != null
                WITH USER_MODE  ];
    }

    /**
        * @description Retrieves record type information for a line.
     * @param lineId DMT_Line__c Id.
     * @return List with the line record (max 1).
     */
    public static List<DMT_Line__c> getLineRecordTypeById(Id lineId) {
        return [SELECT RecordType.DeveloperName FROM DMT_Line__c WHERE Id = :lineId WITH USER_MODE LIMIT 1];
    }

    /**
        * @description Retrieves queue group memberships for the provided users.
     * @param userIds Set of user Ids.
     * @return List of queue group members.
     */
    public static List<GroupMember> getQueueGroupMembersByUserIds(Set<Id> userIds) {
        return [SELECT UserOrGroupId, Group.Name, Group.DeveloperName
                FROM GroupMember
                WHERE UserOrGroupId IN :userIds AND Group.Type = 'Queue'
                WITH USER_MODE ];
    }

    /**
        * @description Retrieves Opportunity owner by record Id.
     * @param opportunityId Opportunity Id.
     * @return List with the opportunity record (max 1).
     */
    public static List<Opportunity> getOpportunityOwnerById(Id opportunityId) {
        return [SELECT OwnerId FROM Opportunity WHERE Id = :opportunityId WITH USER_MODE LIMIT 1];
    }

    /**
        * @description Retrieves Line owner by record Id.
     * @param lineId DMT_Line__c Id.
     * @return List with the line record (max 1).
     */
    public static List<DMT_Line__c> getLineOwnerById(Id lineId) {
        return [SELECT OwnerId FROM DMT_Line__c WHERE Id = :lineId WITH USER_MODE LIMIT 1];

    }

    /**
        * @description Retrieves an active user by Id.
     * @param userId User Id.
     * @return List with the active user record (max 1).
     */
    public static List<User> getActiveUserById(Id userId) {
        return [SELECT Id, Email FROM User WHERE Id = :userId AND IsActive = true WITH USER_MODE LIMIT 1];
    }

    /**
     * @description Retrieves email templates by developer names.
     * @param developerNames List of template developer names.
     * @return List of email templates.
     */
    public static List<EmailTemplate> getEmailTemplatesByDeveloperNames(List<String> developerNames) {
        if (!EmailTemplate.SObjectType.getDescribe().isAccessible()) {
            return new List<EmailTemplate>();
        }

        return [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :developerNames WITH USER_MODE ];
    }

    /**
     * @description Retrieves site by name.
     * @param siteName Site name.
     * @return List with the site record (max 1).
     */
    public static List<Site> getSiteByName(String siteName) {
        if (!Site.SObjectType.getDescribe().isAccessible()) {
            return new List<Site>();
        }

        return [ SELECT Id FROM Site WHERE Name = :siteName WITH USER_MODE LIMIT 1];
    }

    /**
     * @description Retrieves site detail by durable id.
     * @param durableId Durable identifier.
     * @return List with the site detail record (max 1).
     */
    public static List<SiteDetail> getSiteDetailByDurableId(Id durableId) {
        if (!SiteDetail.SObjectType.getDescribe().isAccessible()) {
            return new List<SiteDetail>();
        }

        return [ SELECT SecureUrl FROM SiteDetail WHERE DurableId = :durableId WITH USER_MODE LIMIT 1];
          
    }

    /**
     * @description Retrieves sanction line reference for an opportunity.
     * @param opportunityId Opportunity id.
     * @return List with the opportunity record (max 1).
     */
    public static List<Opportunity> getOpportunitySanctionById(Id opportunityId) {
        if (!Opportunity.SObjectType.getDescribe().isAccessible()) {
            return new List<Opportunity>();
        }

        return [ SELECT DMT_Sanction__c FROM Opportunity WHERE Id = :opportunityId WITH USER_MODE LIMIT 1];
    }
}