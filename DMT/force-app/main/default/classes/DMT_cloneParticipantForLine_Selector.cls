public without sharing  class DMT_cloneParticipantForLine_Selector {
    public static List<DMT_TeamMember__c> getTeamMember(String oldLineId){
        return  [SELECT Id, User__c, Full_Name_User__c, Line__c,Line__r.Client__r.DES_Group_Code__c, Line__r.Client__r.DES_Subsidiary_Group_Code__c,
                         AccessLevel__c, DMT_ApprovalEdit__c, Team_Role__c, User__r.DMT_User_Role__c
                        FROM DMT_TeamMember__c
                        WHERE (Line__c = :oldLineId OR Opportunity__c = :oldLineId) AND DMT_ApprovalEdit__c = false  WITH SECURITY_ENFORCED];
    }
    public static Account getLocalClient(String accountId){
        List<Account> accounts = [SELECT Id, DES_Main_Parent__c
                  FROM Account
                  WHERE id = :accountId WITH SECURITY_ENFORCED LIMIT 1];
        return accounts.isEmpty() ? null : accounts[0];
    }
    public static List<DES_BBVA_Management_team__c> getManagementTeam(Set<Id> clientIds){
        return  [SELECT Id, Name, DES_First_Name__c, DES_Last_Name__c, DES_User__c, DES_User__r.IsActive, DES_User_email__c, DES_Client__c, DES_Client__r.DES_Group_Code__c
                  FROM DES_BBVA_Management_team__c
                  WHERE DES_Client__c IN :clientIds AND DES_User__r.IsActive = true WITH SECURITY_ENFORCED];

    }
}