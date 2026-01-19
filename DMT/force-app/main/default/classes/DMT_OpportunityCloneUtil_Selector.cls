public with sharing class DMT_OpportunityCloneUtil_Selector {
    public static List<DMT_TeamMember__c> getTeamMember(String oldOppId){
        return  [SELECT Id, User__c, Full_Name_User__c, Opportunity__c, AccessLevel__c, DMT_ApprovalEdit__c, User__r.DMT_User_Role__c 
                        FROM DMT_TeamMember__c
                        WHERE Opportunity__c = :oldOppId AND DMT_ApprovalEdit__c = false  WITH SECURITY_ENFORCED];
    }
    public static List<DES_BBVA_Management_team__c> getManagementTeam(Set<Id> clientIds){
        return  [SELECT Id, Name, DES_First_Name__c, DES_Last_Name__c, DES_User__c, DES_User__r.IsActive, DES_User_email__c, DES_Client__c, DES_Client__r.DES_Group_Code__c 
                  FROM DES_BBVA_Management_team__c
                  WHERE DES_Client__c IN :clientIds AND DES_User__r.IsActive = true WITH SECURITY_ENFORCED];
    }
    public static List<OpportunityTeamMember> getOpportunityTeamMember(String oppIds){
        return  [SELECT Id, OpportunityId, UserId, Name, PhotoUrl, Title, TeamMemberRole, OpportunityAccessLevel, CurrencyIsoCode, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, IsDeleted, DES_Already_Exist__c, DES_BBVA_Opportunity_Role__c, DES_Scope__c, member_employee_dept_desc__c, otm_external_id__c 
                 FROM OpportunityTeamMember
                 WHERE OpportunityId = :oppIds WITH SECURITY_ENFORCED];
    }
    public static List<DES_Opportunity_Management_member__c> getOpportunityManagementMember(String oppIds){
        return  [SELECT Id, IsDeleted, Name, CurrencyIsoCode, RecordTypeId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, LastViewedDate, LastReferencedDate, DES_Opportunity__c, DES_BBVA_Opportunity_Role__c, DES_Email__c, DES_First_Name__c, DES_Opportunity_Lead__c, DES_Opportunity_member_role__c, DES_Opportunity_member_role_del__c, DES_Phone__c, DES_Scope__c, DES_User__c, DES_Tipo_de_cobertura__c, DES_PS_Product_Family__c, DES_PS_Product__c, member_employee_dept_desc__c, DES_Owner__c, isActive__c 
                 FROM DES_Opportunity_Management_member__c
                 WHERE DES_Opportunity__c = :oppIds WITH SECURITY_ENFORCED];
    }
}