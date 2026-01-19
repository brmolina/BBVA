/***********************************************************************************************
Name:            OpportinityMember_cls
Description:     logic opportinity member

***********************************************************************************************/

public without sharing class OpportinityMember_cls {


    /*
    *  este mét0d0 añade al usuario creador de la oportunidad como miembro del equipo de esta, con el check de owner marcado
    */
    public static void addOwnerOppMember(Map<Id,Opportunity> triggerNewMap) {
      List<DES_Opportunity_Management_member__c> lstOppMemb;
      lstOppMemb = new List<DES_Opportunity_Management_member__c>();

      for(Opportunity opp : triggerNewMap.values()) {
        final DES_Opportunity_Management_member__c member = new DES_Opportunity_Management_member__c(
        DES_Opportunity__c = opp.Id,
        DES_User__c = opp.OwnerId,
        DES_Owner__c = true,
        Name = opp.Owner.Name
        );
        lstOppMemb.add(member);
      }

      if(!lstOppMemb.isEmpty()) {
        try {
          insert lstOppMemb;
        } catch(Exception e) {
          for(DES_Opportunity_Management_member__c member : lstOppMemb) {
            triggerNewMap.get(member.DES_Opportunity__c).addError(Label.Error_Change_Owner_Opp);
          }
        }
      }
    }

    /*
    *  este mét0d0 añade al usuario creador de la oportunidad como miembro del equipo de esta, con el check de owner marcado
    */
    public static void checkOwnerOppMember(Map<Id,Opportunity> triggerNewMap, Map<Id,Opportunity> triggerOldMap) {
      Map<Id,Opportunity> oppsNewOwner;
      oppsNewOwner = new Map<Id,Opportunity>();

      for(Opportunity oppNew : triggerNewMap.values()) {
        final Opportunity oppOld = triggerOldMap.get(oppNew.Id);
        if(oppNew.Recordtype.DeveloperName != 'Privileged_Opportunity' && oppNew.Recordtype.DeveloperName != 'Privileged_Sales_GM_Opportunity'
        && oppNew.operation_privileged_user_name__c == null && oppNew.OwnerId != oppOld.OwnerId) {
          oppsNewOwner.put(oppNew.Id,oppNew);
        }
      }
      final Map<Id,DES_Opportunity_Management_member__c> mapTM = new Map<Id, DES_Opportunity_Management_member__c>(
        [SELECT Id,DES_Opportunity__c,DES_User__c,DES_Owner__c FROM DES_Opportunity_Management_member__c WHERE DES_Opportunity__c IN :triggerNewMap.keySet()]);

      Map<Id,List<DES_Opportunity_Management_member__c>> mapOppTM;
      mapOppTM = new Map<Id,List<DES_Opportunity_Management_member__c>>();

      for(DES_Opportunity_Management_member__c member : mapTM.values()) {
        List<DES_Opportunity_Management_member__c> listOppTM = mapOppTM.get(member.DES_Opportunity__c);
        if(listOppTM == null) {
          listOppTM = new List<DES_Opportunity_Management_member__c>();
        }
        listOppTM.add(member);
        mapOppTM.put(member.DES_Opportunity__c,listOppTM);
      }

      Map<Id,Opportunity> oppsWithoutMember;
      oppsWithoutMember = new Map<Id,Opportunity>();

      for(Opportunity oppNew : oppsNewOwner.values()) {
        List<DES_Opportunity_Management_member__c> listOppTM = mapOppTM.get(oppNew.Id);
        if(listOppTM == null) {
          listOppTM = new List<DES_Opportunity_Management_member__c>();
        }
        final Opportunity oppOld = triggerOldMap.get(oppNew.Id);
        Boolean ownerChecked = false;
        for(DES_Opportunity_Management_member__c member : listOppTM) {
          if(member.DES_User__c == oppNew.OwnerId) {
            member.DES_Owner__c = true;
            ownerChecked = true;
          } else if(member.DES_User__c == oppOld.OwnerId) {
            member.DES_Owner__c = false;
          }
        }
        if(!ownerChecked) {
          oppsWithoutMember.put(oppNew.Id,oppNew);
        }
      }

      if(oppsNewOwner!=null && !oppsNewOwner.isEmpty()) {
        try {
          update mapTM.values();
        } catch(Exception e) {
          for(DES_Opportunity_Management_member__c member : mapTM.values()) {
            triggerNewMap.get(member.DES_Opportunity__c).addError(Label.Error_Change_Owner_Opp);
          }
        }
      }
      if(oppsWithoutMember!=null && !oppsWithoutMember.isEmpty()) {
        addOwnerOppMember(oppsWithoutMember);
      }
    }


}