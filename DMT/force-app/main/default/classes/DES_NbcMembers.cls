/**
    *Autor: Alejandro del Rio
     */
public with sharing class DES_NbcMembers {
    private DES_NbcMembers() {}


    @AuraEnabled
    /**
     *Autor: Alejandro del Rio
     *Description: Met0d0 que recibe un nbc y una oportunidad y devuelve datos de NBC_Commitee_Member__c
     */
    public static List<NBC_Commitee_Member__c> gtNBCMembers(Id recordId,String oppId) {
        try {
            return [SELECT Id,gf_virtual_cmtee_supp_ind_type__c,gf_oppy_virtual_cmtee_user_id__c,gf_oppy_virtual_cmtee_user_id__r.name,opportunity_id__r.NBC_Decision_Taken_type__c,opportunity_id__r.NBC_decision_type__c FROM NBC_Commitee_Member__c WHERE opportunity_id__c = :oppId and gf_oppy_virtual_cmtee_id__c =:recordId ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage());//NOSONAR
        }
    }


    @AuraEnabled
    /**
     *Autor: Alejandro del Rio
     *Description: Met0d0 que recibe una oportunidad y devuelve datos de DES_Template__c
     */
    public static List<DES_Template__c> gtNBCTemplate(String oppId) {
        try {
            return [SELECT Id, opportunity_id__c, opportunity_id__r.Account.Name, opportunity_id__r.NBC_Decision_Taken_type__c,opportunity_id__r.NBC_decision_type__c,opportunity_id__r.Name, opportunity_nbc_comments_desc__c FROM DES_Template__c WHERE opportunity_id__c = :oppId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage());//NOSONAR
        }
    }


    @AuraEnabled
    /**
     *Autor: Alejandro del Rio
     *Description: Met0d0 que aztualiza el voto del miembro del comite del nbc virtual
     */
    public static void updateNBCvote(Id recordId, String vote,String oppId) {
        try {
            final List <NBC_Commitee_Member__c> members = new List <NBC_Commitee_Member__c>();//NOSONAR
            Final List<NBC_Commitee_Member__c>  lsNbcMembers = new List<NBC_Commitee_Member__c>([SELECT Id,gf_oppy_virtual_cmtee_user_id__c,gf_virtual_cmtee_supp_ind_type__c FROM NBC_Commitee_Member__c WHERE opportunity_id__c = :oppId and gf_oppy_virtual_cmtee_id__c =:recordId  and opportunity_id__r.NBC_decision_type__c = false ]);
            if(lsNbcMembers != null && !lsNbcMembers.isEmpty()) {
                for(NBC_Commitee_Member__c member : lsNbcMembers) {
                    if(member.gf_oppy_virtual_cmtee_user_id__c==UserInfo.getUserId()) {
                        member.gf_virtual_cmtee_supp_ind_type__c= vote;
                        members.add(member);
                    }
                }
                update members;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + ': ' + e.getMessage());//NOSONAR
        }
    }

    @AuraEnabled
    /**
     *Autor: Alejandro del Rio
     *Description: Met0d0 que cmobureba si es usuario actual puede ver la oportunidad
     */
    public static Boolean getUserRelated(Id oppId) {
        Final List<String> groupList= new List<String>();
        groupList.add(String.valueOf(Label.SP_Users_Group_DevName));
        groupList.add(String.valueOf(Label.GroupNBCVirtualDevName));
        Final List<GroupMember> members=new List<GroupMember>([SELECT id, Group.Name, UserOrGroupId  FROM GroupMember where Group.DeveloperName  =:groupList])  ;//NOSONAR
        Final List<String> usersId= new List<String>();
        Final List<OpportunityTeamMember> opp=new List<OpportunityTeamMember>([SELECT id, UserId FROM OpportunityTeamMember WHERE OpportunityId =: oppId]) ;
        for(GroupMember member : members) {
            usersId.add(member.UserOrGroupId);
        }
        for(OpportunityTeamMember member2 : opp) {
            usersId.add(member2.UserId);
        }
        Final Boolean result = usersId.contains(UserInfo.getUserId());
        return result;//NOSONAR
    }
}