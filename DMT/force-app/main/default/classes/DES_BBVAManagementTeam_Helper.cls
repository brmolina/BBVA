/**********************************************************************************
* @author       Global Desktop
* @date         11/03/2020
* @description  Contiene los mét0dos para la gestión del team de la alerta
**********************************************************************************/
public without sharing class DES_BBVAManagementTeam_Helper {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private DES_BBVAManagementTeam_Helper() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description Future method to insert team members of alerts
  */
  @future
  public static void insAlertMemberFut(String newListJSON, String oldMapJSON) {
    final List<DES_BBVA_Management_Team__c> newList = (List<DES_BBVA_Management_Team__c>) JSON.deserialize(newListJSON, List<DES_BBVA_Management_Team__c>.class);
    final List<DES_BBVA_Management_Team__c> newListFinal = new List<DES_BBVA_Management_Team__c>();
    if(oldMapJSON == '') {
      newListFinal.addAll(newList);
    } else {
      final Map<Id, DES_BBVA_Management_Team__c> oldMap = (Map<Id, DES_BBVA_Management_Team__c>) JSON.deserialize(oldMapJSON, Map<Id, DES_BBVA_Management_Team__c>.class);
      for(DES_BBVA_Management_Team__c member : newList) {
        if(!member.copy_record_approval_type__c  && oldMap.get(member.Id).copy_record_approval_type__c) {
          newListFinal.add(member);
        }
      }
    }
    system.debug('**newListFinal -> ' + newListFinal);
    insAlertMember(newListFinal);
  }

  /**
  * @author Global Desktop
  * @Description Method to insert team members of alerts
  */
  public static void insAlertMember(List<DES_BBVA_Management_Team__c> newList) {
    final List<DES_BBVA_Management_Team__c> listBBVAMT = [
      SELECT Id, DES_Client__c, DES_Client__r.DES_Group_Code__c, DES_User__c, DES_User__r.Name, DES_Member_Role__c, DES_Local_Banker_Country__c
      FROM DES_BBVA_Management_Team__c
      WHERE Id IN :newList
      AND copy_record_approval_type__c = false
    ];
    final Set<Id> accountIds = new Set<Id>();
    final Set<String> groupCodes = new Set<String>();
    for(DES_BBVA_Management_Team__c member : listBBVAMT) {
      accountIds.add(member.DES_Client__c);
      if(member.DES_Client__r.DES_Group_Code__c != null) {
				groupCodes.add(member.DES_Client__r.DES_Group_Code__c);
			}
    }
    system.debug('**groupCodes -> '+ groupCodes);

    /* Se guarda un mapa con el Id y sus filiales a través de la matriz de Subsidiary relation */
    final Map<Id, List<Id>> mapGroupClients = gtMapGroup(accountIds);
    /* Se guarda un mapa con el Id de la alerta y los global banker o transactional banker del grupo (priorizando el campo business_group__c) */
    final Map<Id, Set<Id>> mapAlertMembers = gtMapAlertsMembers(groupCodes, mapGroupClients, listBBVAMT);
    system.debug('**mapAlertMembers -> ' + mapAlertMembers);

    /* Se obtienen los miembros de las alertas asociadas a los grupos donde se borra algun miembro*/
    final List<ctcp__Custom_Team__c> listTeam = new List<ctcp__Custom_Team__c>([
      SELECT Id, ctcp__gf_team_users_desc__c, commercial_alert_id__c
      FROM ctcp__Custom_Team__c
      WHERE commercial_alert_id__c IN :mapAlertMembers.keySet()
    ]);

    /* Se guarda un mapa con el Id de la alerta y los ids de los usuarios miembros de estas */
    final Map<Id, Set<Id>> mapAlertTeam = gtAlertMembers(listTeam);

    final List<ctcp__Custom_Team__c> toCreate = gtToCreate(mapAlertMembers, mapAlertTeam);
    system.debug('**toCreate -> ' + toCreate);
    checkListMember(toCreate, true);
  }

  /*
  * @author Global Desktop
  * @Description Method to build a List with members a create
  */
  private static List<ctcp__Custom_Team__c> gtToCreate(Map<Id, Set<Id>> mapAlertMembers, Map<Id, Set<Id>> mapAlertTeam) {
    final List<ctcp__Custom_Team__c> toCreate = new List<ctcp__Custom_Team__c>();
    for(Id alertId : mapAlertMembers.keySet()) {
      for(Id member : mapAlertMembers.get(alertId)) {
        if(mapAlertTeam.get(alertId) == null || (mapAlertTeam.get(alertId) != null && !mapAlertTeam.get(alertId).contains(member))) {
          final ctcp__Custom_Team__c alertMember = createMember(alertId, member);
          toCreate.add(alertMember);
        }
      }
    }
    return toCreate;
  }

  /**
  * @author Global Desktop
  * @Description Devuelve un mapa con los ids cliente - grupo principal
  */
  private static Map<Id, List<Id>> gtMapGroup(Set<Id> accountIds) {
    final Map<Id, List<Id>> mapGroupClients = new Map<Id, List<Id>>();

    for(DES_Subsidiary_Group_Relation__c iGroupRelation : [
      SELECT Id, participant_child_id__c, participant_parent_id__c
      FROM DES_Subsidiary_Group_Relation__c
      WHERE participant_parent_id__c IN :accountIds
      AND main_subsidiary_ind_type__c = true
    ]) {
      if(mapGroupClients.containsKey(iGroupRelation.participant_parent_id__c)) {
        final List<Id> listClients = mapGroupClients.get(iGroupRelation.participant_parent_id__c);
        listClients.add(iGroupRelation.participant_child_id__c);
        mapGroupClients.put(iGroupRelation.participant_parent_id__c, listClients);
      } else {
        mapGroupClients.put(iGroupRelation.participant_parent_id__c, new List<Id> {iGroupRelation.participant_child_id__c});
      }
    }
    system.debug('**mapGroupClients -> ' + mapGroupClients);
    return mapGroupClients;
  }

  /**
  * @author Global Desktop
  * @Description Devuelve un mapa con el id de la alerta una lista de los TB y global banker del grupo relacionado
  */
  private static Map<Id, Set<Id>> gtMapAlertsMembers(Set<String> groupCodes, Map<Id, List<Id>> mapGroupClients, List<DES_BBVA_Management_Team__c> listBBVAMT) {
    final Set<Id> clientsIds = new Set<Id>();
    for(Id auxId : mapGroupClients.keySet()) {
      for(Id clientId : mapGroupClients.get(auxId)) {
        clientsIds.add(clientId);
      }
    }
    final Map<Id, Set<Id>> mapAlertMembers = new Map<Id, Set<Id>>();
    for(altm__Commercial_Alert__c alert : [
      SELECT Id, altm__participant_id__c, business_group_id__c, altm__country_id__c
      FROM altm__Commercial_Alert__c
      WHERE altm__participant_id__c IN :clientsIds OR business_group_id__c IN :groupCodes
    ]) {
      final Set<Id> setMembers = new Set<Id>();
      for(DES_BBVA_Management_Team__c member : listBBVAMT) {
        if(gtMapAlertsMembersBusiness(alert, member)) {
          setMembers.add(member.DES_User__c);
        } else if(gtMapAlertsMembersMatrix(alert, member, mapGroupClients)) {
          setMembers.add(member.DES_User__c);
        }
      }
      if(!setMembers.isEmpty()) {
        mapAlertMembers.put(alert.Id, setMembers);
      }
    }
    return mapAlertMembers;
  }

  /**
  * @author Global Desktop
  * @Description gtMapAlertsMembersBusiness
  */
  private static Boolean gtMapAlertsMembersBusiness(altm__Commercial_Alert__c alert, DES_BBVA_Management_Team__c member) {
    return alert.business_group_id__c == member.DES_Client__r.DES_Group_Code__c
      && (member.DES_Member_Role__c == Label.DES_ROLE_GLOBAL_BANKER
        || (member.DES_Local_Banker_Country__c == alert.altm__country_id__c
          && member.DES_Member_Role__c == Label.DES_Role_Transactional_Banker));
  }

  /**
  * @author Global Desktop
  * @Description gtMapAlertsMembersMatrix
  */
  private static Boolean gtMapAlertsMembersMatrix(altm__Commercial_Alert__c alert, DES_BBVA_Management_Team__c member, Map<Id, List<Id>> mapGroupClients) {
    return alert.business_group_id__c == null
      && mapGroupClients.get(member.DES_Client__c) != null
      && mapGroupClients.get(member.DES_Client__c).contains(alert.altm__participant_id__c)
      && (member.DES_Member_Role__c == Label.DES_ROLE_GLOBAL_BANKER
        || (member.DES_Local_Banker_Country__c == alert.altm__country_id__c
          && member.DES_Member_Role__c == Label.DES_Role_Transactional_Banker));
  }

  /**
  * @author Global Desktop
  * @Description Future method to delete team members of alerts
  */
  @future
  public static void delAlertMemberFut(String oldListJSON) {
    final List<DES_BBVA_Management_Team__c> oldList = (List<DES_BBVA_Management_Team__c>) JSON.deserialize(oldListJSON, List<DES_BBVA_Management_Team__c>.class);
    delAlertMember(oldList);
  }

  /**
  * @author Global Desktop
  * @Description Method to delete team members of alerts
  */
  public static void delAlertMember(List<DES_BBVA_Management_Team__c> oldList) {
    final Set<Id> clientsIds = new Set<Id>();
    for(DES_BBVA_Management_Team__c member : oldList) {
      clientsIds.add(member.DES_Client__c);
    }

    /* Lista con los miembros de los grupos que permanecen después del borrado */
    final List<DES_BBVA_Management_Team__c> listBBVAMT = [
      SELECT Id, DES_Client__c, DES_Client__r.DES_Group_Code__c, DES_User__c, DES_User__r.Name, DES_Member_Role__c, DES_Local_Banker_Country__c
      FROM DES_BBVA_Management_Team__c
      WHERE DES_Client__c IN :clientsIds
      AND copy_record_approval_type__c = false
    ];

    final Set<Id> accountIds = new Set<Id>();
    final Set<String> groupCodes = new Set<String>();
    for(Account acc : [SELECT Id, DES_Group_Code__c
      FROM Account
      WHERE Id IN :clientsIds
    ]) {
      accountIds.add(acc.Id);
      if(acc.DES_Group_Code__c != null){
        groupCodes.add(acc.DES_Group_Code__c);
      }
    }

    System.debug('**accountIds -> ' + JSON.serialize(accountIds));

    /* Se guarda un mapa con el Id y sus filiales a través de la matriz de Subsidiary relation */
    final Map<Id, List<Id>> mapGroupClients = gtMapGroup(accountIds);
    /* Se guarda un mapa con el Id de la alerta y los global banker o transactional banker del grupo (priorizando el campo business_group__c) */
    final Map<Id, Set<Id>> mapAlertMembers = gtMapAlertsMembers(groupCodes, mapGroupClients, listBBVAMT);
    system.debug('**mapAlertMembers -> ' + mapAlertMembers);

    /* Se obtienen los miembros de las alertas asociadas a los grupos donde se borra algun miembro*/
    final List<ctcp__Custom_Team__c> listTeam = new List<ctcp__Custom_Team__c>([
      SELECT Id, ctcp__gf_team_users_desc__c, commercial_alert_id__c
      FROM ctcp__Custom_Team__c
      WHERE DES_From_Group__c = true AND commercial_alert_id__c IN :mapAlertMembers.keySet()
    ]);

    system.debug('**listTeam -> ' + listTeam);

    /* Se guarda un mapa con el Id de la alerta y los ids de los usuarios miembros de estas */
    final Map<Id, Set<Id>> mapAlertTeam = gtAlertMembers(listTeam);
    final List<ctcp__Custom_Team__c> toDelete = gtToDelete(mapAlertTeam,  oldList, mapAlertMembers, listTeam);
    System.debug('**toDelete -> ' + JSON.serialize(toDelete));
    checkListMember(toDelete, false);

  }

  /**
  * @author Global Desktop
  * @Description Method to build a map with alert and its members
  */
  private static List<ctcp__Custom_Team__c> gtToDelete(Map<Id, Set<Id>> mapAlertTeam, List<DES_BBVA_Management_Team__c> oldList, Map<Id, Set<Id>> alertGroupMember, List<ctcp__Custom_Team__c> listTeam) {
    final List<ctcp__Custom_Team__c> toDelete = new List<ctcp__Custom_Team__c>();

    /* Para una alerta, si el grupo no contiene el usuario que se borra, y este esta como miembro de la alerta, se añade para borrarlo */
    for(Id alertId : mapAlertTeam.keySet()) {
      for(DES_BBVA_Management_Team__c memberToDelete : oldList) {
        if(!alertGroupMember.get(alertId).contains(memberToDelete.DES_User__c) && mapAlertTeam.get(alertId).contains(memberToDelete.DES_User__c)) {
          for(ctcp__Custom_Team__c memberTeam : listTeam) {
            if(memberTeam.commercial_alert_id__c == alertId && memberTeam.ctcp__gf_team_users_desc__c == memberToDelete.DES_User__c && !toDelete.contains(memberTeam)) {
              toDelete.add(memberTeam);
            }
          }
        }
      }
    }
    return toDelete;
  }

  /**
  * @author Global Desktop
  * @Description Method to build a map with alert and its members
  */
  private static Map<Id, Set<Id>> gtAlertMembers(List<ctcp__Custom_Team__c> listTeam) {
    final Map<Id, Set<Id>> mapAlertTeam = new Map<Id, Set<Id>>();

    for(ctcp__Custom_Team__c member : listTeam) {
      if(mapAlertTeam.containsKey(member.commercial_alert_id__c)) {
        final Set<Id> setTeam = mapAlertTeam.get(member.commercial_alert_id__c);
        setTeam.add(member.ctcp__gf_team_users_desc__c);
        mapAlertTeam.put(member.commercial_alert_id__c, setTeam);
      } else {
        mapAlertTeam.put(member.commercial_alert_id__c, new Set<Id> {member.ctcp__gf_team_users_desc__c});
      }
    }
    return mapAlertTeam;
  }

  /**
  * @author Global Desktop
  * @Description Method to create Member for alert
  */
  private static ctcp__Custom_Team__c createMember(Id alertId, Id ownerId) {
    final ctcp__Custom_Team__c member = new ctcp__Custom_Team__c();
    member.ctcp__gf_team_users_desc__c = ownerId;
    member.ctcp__Object_Name__c = 'altm__Commercial_Alert__c';
    member.commercial_alert_id__c = alertId;
    member.OwnerId = ownerId;
    member.DES_From_Group__c = true;
    member.RecordTypeId = Schema.SObjectType.ctcp__Custom_Team__c.getRecordTypeInfosByDeveloperName().get('Commercial_Alert').getRecordTypeId();
    return member;
  }

  /**
  * @author Global Desktop
  * @Description Method to add or delete members
  */
  private static void checkListMember(List<ctcp__Custom_Team__c> members, Boolean isInsert) {
    if (members != null && !members.isEmpty()) {
        // Extract user IDs from members
        Set<Id> userIds = new Set<Id>();
        for (ctcp__Custom_Team__c member : members) {
            userIds.add(member.ctcp__gf_team_users_desc__c);
        }

        // Query active users
        Set<Id> activeUserIds = new Set<Id>();
        for (User user : [SELECT Id FROM User WHERE Id IN :userIds AND IsActive = true]) {
            activeUserIds.add(user.Id);
        }

        // Filter members to include only those with active users
        List<ctcp__Custom_Team__c> filteredMembers = new List<ctcp__Custom_Team__c>();
        for (ctcp__Custom_Team__c member : members) {
            if (activeUserIds.contains(member.ctcp__gf_team_users_desc__c)) {
                filteredMembers.add(member);
            }
        }

        system.debug('**filteredMembers -> ' + filteredMembers);

        // Perform insert or delete on the filtered list
        if (!filteredMembers.isEmpty()) {
            if (isInsert) {
                insert filteredMembers;
            } else {
                delete filteredMembers;
            }
        }
    }
}

  /**
  * @author Global Desktop
  * @Description Method to replace Transaction Banker by Transactional
 
  public static void replaceTransaction(List<DES_BBVA_Management_Team__c> newList) {
    for(DES_BBVA_Management_Team__c oBBVATm : newList) {
      if(oBBVATm.DES_Member_Role__c == 'Transaction Banker') {
        oBBVATm.DES_Member_Role__c = Label.DES_TransactionalBanker;
      }
    }
  }
  */
}