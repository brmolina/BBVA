/**
 * @author       Global Desktop
 * @date         10/10/2019
 * @description  Clase auxiliar de la clase NPW_Wave_Helper
 */
public with sharing class NPS_Wave_Helper_Aux {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static NPS_Wave_Helper_Aux instance;
  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static NPS_Wave_Helper_Aux getInstance() { //NOSONAR
    if (instance == null) {
      instance = new NPS_Wave_Helper_Aux();
    }
    return instance;
  }

  private NPS_Wave_Helper_Aux() {
  }

  /**
   *   @author Global Desktop
   *   @method getGroupRelation
   */
  public static Map<Id, List<Id>> getGroupRelation(Map<Id, Account> mapAccounts, Map<Id, Account> mapAccountsGroup) {
    final Map<Id, List<Id>> mapGroupSub = new Map<Id, List<Id>>();
    for(DES_Subsidiary_Group_Relation__c iRelation : [SELECT Id,
                                                        participant_child_id__c,
                                                        participant_parent_id__c
                                                      FROM DES_Subsidiary_Group_Relation__c
                                                      WHERE participant_parent_id__c IN :mapAccountsGroup.keySet()
                                                        AND participant_child_id__c IN :mapAccounts.keySet()]) {
      if(mapGroupSub.get(iRelation.participant_parent_id__c) == null) {
        mapGroupSub.put(iRelation.participant_parent_id__c, new List<Id> {iRelation.participant_child_id__c});
      } else {
        final List<Id> listIdAux = mapGroupSub.get(iRelation.participant_parent_id__c);
        listIdAux.add(iRelation.participant_child_id__c);
        mapGroupSub.put(iRelation.participant_parent_id__c, listIdAux);
      }
    }

    return mapGroupSub;
  }

  /**
   *   @author Global Desktop
   *   @method filialHasContactFunc
   */
  public static Boolean filialHasContactFunc(Map<Id, Account> mapAccounts, Map<Id, List<Id>> mapGroupSub, Id iAccountId) {
    Boolean filialHasContact = false;
    if(mapGroupSub.get(iAccountId) != null) {
      for(Id iAccountFilialId : mapGroupSub.get(iAccountId)) {
        if(!mapAccounts.get(iAccountFilialId).Contacts.isEmpty()) {
          filialHasContact = true;
        }
      }
    }

    return filialHasContact;
  }

  /**
   *   @author Global Desktop
   *   @method getUserId
   */
  public static Id getUserId(Map<Id, Account> mapAccountsGroup, Id iAccountId) {
    Id userIdAux = null;
    if(mapAccountsGroup.get(iAccountId) != null) {
      for(DES_BBVA_Management_team__c iBBVATeam : mapAccountsGroup.get(iAccountId).BBVA_Client_teams__r) {
        if(iBBVATeam.DES_Member_Role__c == Label.DES_ROLE_GLOBAL_BANKER) {
          userIdAux = iBBVATeam.DES_User__c;
        } else {
          if(userIdAux == null) {
            userIdAux = iBBVATeam.DES_User__c;
          }
        }
      }
    }

    return userIdAux;
  }

  /**
   *   @author Global Desktop
   *   @method getListContactsNPS
   */
  public static Map<NPS_Wave__c, List<Contact>> getListContactsNPS(Map<NPS_Wave__c, List<Contact>> listContactsNPS, Map<Id, Account> mapAccounts, Id iAccountId, NPS_Wave__c iNPSWave) {
    if(listContactsNPS.get(iNPSWave) == null) {
      listContactsNPS.put(iNPSWave, mapAccounts.get(iAccountId).Contacts);
    } else {
      final List<Contact> listContactAux = listContactsNPS.get(iNPSWave);
      listContactAux.addAll(mapAccounts.get(iAccountId).Contacts);
      listContactsNPS.put(iNPSWave, listContactAux);
    }

    return listContactsNPS;
  }

  /**
   *   @author Global Desktop
   *   @method getListGlobalBanker
   */
  public static Map<NPS_Wave__c, List<Id>> getListGlobalBanker(Map<NPS_Wave__c, List<Id>> listGlobalBanker, Map<Id, Account> mapAccounts, Id userIdAux, NPS_Wave__c iNPSWave) {
    if(listGlobalBanker.get(iNPSWave) == null) {
      listGlobalBanker.put(iNPSWave, new List<Id> {userIdAux});
    } else {
      final List<Id> listIdAux = listGlobalBanker.get(iNPSWave);
      listIdAux.add(userIdAux);
      listGlobalBanker.put(iNPSWave, listIdAux);
    }

    return listGlobalBanker;
  }

  /**
  * @author Global Desktop
  * @Description getMapClientGroup
  */
  public static Map<Id, Id> getMapClientGroup(Set<Id> setAccountId) { //NOSONAR
    final Map<Id, Id> mapClientGroup = new Map<Id, Id>();

    for(DES_Subsidiary_Group_Relation__c iGroupRelation : [SELECT Id,
                                                            participant_child_id__c,
                                                            participant_parent_id__c
                                                          FROM DES_Subsidiary_Group_Relation__c
                                                          WHERE participant_child_id__c IN :setAccountId
                                                            AND main_subsidiary_ind_type__c = true]) {
      if(mapClientGroup.get(iGroupRelation.participant_child_id__c) == null) {
        mapClientGroup.put(iGroupRelation.participant_child_id__c, iGroupRelation.participant_parent_id__c);
      }
    }

    return mapClientGroup;
  }
}