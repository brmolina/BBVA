/**
 * Service class to obtain recipient emails for notification flows.
 */
public with sharing class DMT_SendEmailSelectTeamMember {
    private static final String GROUP_KEYWORD_NBC = 'NBC';
    private static final String GROUP_KEYWORD_RISK = 'RISK';

    private class TeamMemberPolicy {
        public Boolean applyBusinessGroupFilter;
        public String groupKeyword;
    }

    /**
     * Returns recipient emails for team members and record owner.
     *
     * @param recordId Id of Opportunity or DMT_Line__c.
     * @param recordType SObject type for the provided record.
     * @return Map where key is User Id and value is Email.
     */
    public static Map<Id, String> getRecipientEmails(Id recordId, Schema.SObjectType recordType) {
        List<DMT_TeamMember__c> teamMembers = getTeamMembers(recordId, recordType);
        return buildRecipientEmails(teamMembers, recordId, recordType);
    }

    private static List<DMT_TeamMember__c> getTeamMembers(Id recordId, Schema.SObjectType recordType) {
        TeamMemberPolicy policy = resolveTeamMemberPolicy(recordId, recordType);
        List<DMT_TeamMember__c> teamMembers = queryTeamMembers(recordId, recordType);
        if (teamMembers.isEmpty() || !policy.applyBusinessGroupFilter) {
            return teamMembers;
        }

        Set<Id> usersInBusinessQueue = getUsersInBusinessQueue(teamMembers, policy.groupKeyword);
        return filterTeamMembersByUsers(teamMembers, usersInBusinessQueue);
    }

    private static TeamMemberPolicy resolveTeamMemberPolicy(Id recordId, Schema.SObjectType recordType) {
        TeamMemberPolicy policy = new TeamMemberPolicy();
        policy.applyBusinessGroupFilter = false;

        if (recordType == Opportunity.SObjectType) {
            policy.applyBusinessGroupFilter = true;
            policy.groupKeyword = GROUP_KEYWORD_NBC;
            return policy;
        }

        if (recordType != DMT_Line__c.SObjectType) {
            return policy;
        }

        List<DMT_Line__c> lineTypeList = DMT_SendEmailService_Selector.getLineRecordTypeById(recordId);
        if (!lineTypeList.isEmpty() && lineTypeList[0].RecordType.DeveloperName == 'Sanction') {
            policy.applyBusinessGroupFilter = true;
            policy.groupKeyword = GROUP_KEYWORD_RISK;
        }
        return policy;
    }

    private static List<DMT_TeamMember__c> queryTeamMembers(Id recordId, Schema.SObjectType recordType) {
        if (recordType == Opportunity.SObjectType) {
            return DMT_SendEmailService_Selector.getTeamMembersByOpportunityId(recordId);
        }
        if (recordType == DMT_Line__c.SObjectType) {
            return DMT_SendEmailService_Selector.getTeamMembersByLineId(recordId);
        }
        return new List<DMT_TeamMember__c>();
    }

    private static Set<Id> getUsersInBusinessQueue(List<DMT_TeamMember__c> teamMembers, String groupKeyword) {
        Set<Id> teamUserIds = extractTeamUserIds(teamMembers);
        if (teamUserIds.isEmpty() || String.isBlank(groupKeyword)) {
            return new Set<Id>();
        }

        Set<Id> usersInBusinessQueue = new Set<Id>();
        for (GroupMember groupMember : DMT_SendEmailService_Selector.getQueueGroupMembersByUserIds(teamUserIds)) {
            if (matchesGroupKeyword(groupMember.Group.Name, groupMember.Group.DeveloperName, groupKeyword)) {
                usersInBusinessQueue.add(groupMember.UserOrGroupId);
            }
        }
        return usersInBusinessQueue;
    }

    private static Set<Id> extractTeamUserIds(List<DMT_TeamMember__c> teamMembers) {
        Set<Id> teamUserIds = new Set<Id>();
        for (DMT_TeamMember__c member : teamMembers) {
            if (member.User__c != null) {
                teamUserIds.add(member.User__c);
            }
        }
        return teamUserIds;
    }

    private static Boolean matchesGroupKeyword(String groupName, String developerName, String groupKeyword) {
        String normalizedKeyword = String.isBlank(groupKeyword) ? '' : groupKeyword.toUpperCase();
        String normalizedGroupName = groupName != null ? groupName.toUpperCase() : '';
        String normalizedDeveloperName = developerName != null ? developerName.toUpperCase() : '';
        return normalizedGroupName.contains(normalizedKeyword) || normalizedDeveloperName.contains(normalizedKeyword);
    }

    @TestVisible
    private static Boolean matchesGroupKeywordForTest(String groupName, String developerName, String groupKeyword) {
        return matchesGroupKeyword(groupName, developerName, groupKeyword);
    }

    private static List<DMT_TeamMember__c> filterTeamMembersByUsers(List<DMT_TeamMember__c> teamMembers, Set<Id> allowedUserIds) {
        if (allowedUserIds.isEmpty()) {
            return new List<DMT_TeamMember__c>();
        }

        List<DMT_TeamMember__c> filteredTeamMembers = new List<DMT_TeamMember__c>();
        for (DMT_TeamMember__c member : teamMembers) {
            if (allowedUserIds.contains(member.User__c)) {
                filteredTeamMembers.add(member);
            }
        }
        return filteredTeamMembers;
    }

    private static Map<Id, String> buildRecipientEmails(List<DMT_TeamMember__c> teamMembers, Id recordId, Schema.SObjectType recordType) {
        Map<Id, String> recipientEmails = new Map<Id, String>();

        for (DMT_TeamMember__c member : teamMembers) {
            if (member.User__c != null && member.User__r != null && String.isNotBlank(member.User__r.Email)) {
                recipientEmails.put(member.User__c, member.User__r.Email);
            }
        }

        User recordOwner = getRecordOwner(recordId, recordType);
        if (recordOwner != null && recordOwner.Id != null && String.isNotBlank(recordOwner.Email)) {
            recipientEmails.put(recordOwner.Id, recordOwner.Email);
        }

        return recipientEmails;
    }

    private static User getRecordOwner(Id recordId, Schema.SObjectType recordType) {
        Id ownerId;

        if (recordType == Opportunity.SObjectType) {
            List<Opportunity> opportunities = DMT_SendEmailService_Selector.getOpportunityOwnerById(recordId);
            ownerId = opportunities.isEmpty() ? null : opportunities[0].OwnerId;
        } else if (recordType == DMT_Line__c.SObjectType) {
            List<DMT_Line__c> lines = DMT_SendEmailService_Selector.getLineOwnerById(recordId);
            ownerId = lines.isEmpty() ? null : lines[0].OwnerId;
        }

        if (ownerId == null) {
            return null;
        }

        List<User> owners = DMT_SendEmailService_Selector.getActiveUserById(ownerId);
        return owners.isEmpty() ? null : owners[0];
    }
}