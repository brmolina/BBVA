public with sharing class DMT_PermissionSelector {
    public static Boolean isCurrentUserAdmin() {
        User currentUser = [
            SELECT Profile.Name 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
        ];
        return currentUser.Profile.Name == 'System Administrator';
    }

    public static Opportunity getOpportunityById(Id oppId) {
        return [
            SELECT Id, OwnerId 
            FROM Opportunity 
            WHERE Id = :oppId
            LIMIT 1
        ];
    }

    public static List<DMT_TeamMember__c> getTeamMemberAccess(Id oppId) {
        return [
            SELECT AccessLevel__c
            FROM DMT_TeamMember__c
            WHERE Opportunity__c = :oppId 
              AND User__c = :UserInfo.getUserId()
        ];
    }
}