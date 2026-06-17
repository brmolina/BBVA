public without sharing class DMT_CaseOwnerType_Selector {

    public static Group getGroupById(Id groupId) {
        return [
            SELECT Id, Name, DeveloperName, Type
            FROM Group
            WHERE Id = :groupId
            LIMIT 1
        ];
    }

    public static DMT_Approver__c getApproverWithTypeByGroupDeveloperName(String groupDeveloperName) {
        if (String.isBlank(groupDeveloperName)) {
            return null;
        }

        List<DMT_Approver__c> approvers = [
            SELECT Id, Name, DMT_ApproverType__r.Name
            FROM DMT_Approver__c
            WHERE DMT_Group__c = :groupDeveloperName
            LIMIT 1
        ];

        return approvers.isEmpty() ? null : approvers[0];
    }
}