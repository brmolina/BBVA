/**********************************************************************************
* @author       Global Desktop
* @date         12/02/2020
* @description  Helper del trigger de altm__Commercial_Alert__c
**********************************************************************************/
public with sharing class Commercial_Alert_Helper {
  /**
  * @author Global Desktop
  * @Description PROFILENAME
  */
  final static String PROFILENAME {
    get {
      System.debug('::::::::::UserInfo.getProfileId(): ' + UserInfo.getProfileId());
      if(PROFILENAME == null || Test.isRunningTest()) {
        PROFILENAME = [SELECT Name
                      FROM Profile
                      WHERE Id = :UserInfo.getProfileId()
                      LIMIT 1].Name;
      }
      return PROFILENAME;
    } set;
  }

  /*
  * Commercial alert String
  */
  final static String COMALERTRT = 'Commercial_Alert';

  /**
  * @author Global Desktop
  * @Description USERNAME
  */
  final static String USERNAME {
    get {
      if(USERNAME == null || Test.isRunningTest()) {
        USERNAME = [SELECT Name
                    FROM User
                    WHERE Id = :UserInfo.getUserId()
                    LIMIT 1].Name;
      }
      return USERNAME;
    } set;
  }

  /**
  * @author Global Desktop
  * @Description AUTOMATED_PR
  */
  final static String AUTOMATED_PR = 'Automated Process';

  /**
  * @author Global Desktop
  * @Description mapa para guardar la matriz de grupo ppal-matriz
  */
  private static Map<Id, Id> mapGroupFilial = new Map<Id, Id>();

  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Commercial_Alert_Helper() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description Concatena el BBVASA para las contrapartidas
  */
  public static void informGroupName(List<altm__Commercial_Alert__c> triggerNew) {
      final Set<Id> clientIds = new Set<Id>();
      final Set<String> groupsCode = new Set<String>();

      for(altm__Commercial_Alert__c alert : triggerNew) {
        clientIds.add(alert.altm__participant_id__c);
        if(alert.business_group_id__c != null) {
          groupsCode.add(alert.business_group_id__c);
        }
      }

      final Map<String, Account> mapGroupGtb = completeMapGroup(groupsCode);

      final List<DES_Subsidiary_Group_Relation__c> matrix = new List<DES_Subsidiary_Group_Relation__c>([
        SELECT Id, participant_parent_id__r.Name, participant_child_id__c
        FROM DES_Subsidiary_Group_Relation__c
        WHERE participant_child_id__c IN :clientIds AND main_subsidiary_ind_type__c = true
      ]);

      final Map<Id, String> mapGroupName = new Map<Id, String>();

      for(DES_Subsidiary_Group_Relation__c mtrx : matrix) {
        mapGroupName.put(mtrx.participant_child_id__c, mtrx.participant_parent_id__r.Name);
      }

      for(altm__Commercial_Alert__c alert : triggerNew) {
        if(mapGroupGtb.get(alert.business_group_id__c) == null) {
          alert.Group_Name__c = mapGroupName.get(alert.altm__participant_id__c);
        } else {
          alert.Group_Name__c = mapGroupGtb.get(alert.business_group_id__c).Name;
        }
      }
      completeListFields(triggerNew);
  }

  /**
  * @author Global Desktop
  * @Description Complete group - fields
  */
  private static void completeListFields(List<altm__Commercial_Alert__c> triggerNew) {
    final Set<Id> idsClients = new Set<Id>();
    for(altm__Commercial_Alert__c alert : triggerNew) {
      idsClients.add(alert.altm__participant_id__c);
    }
    final Map<Id, Account> mapClients = new Map<Id, Account>([
      SELECT Id, Name
      FROM Account
      WHERE Id IN :idsClients
    ]);

    completeListFieldsAux(triggerNew, mapClients);
  }

  /**
  * @author Global Desktop
  * @Description completeListFieldsAux
  */
  private static void completeListFieldsAux(List<altm__Commercial_Alert__c> triggerNew, final Map<Id, Account> mapClients) {
    for(altm__Commercial_Alert__c alert : triggerNew) {
      if(mapClients.get(alert.altm__participant_id__c) != null) {
        alert.Group_Client__c = alert.Group_Name__c == null ? mapClients.get(alert.altm__participant_id__c).Name : alert.Group_Name__c + ' - ' + mapClients.get(alert.altm__participant_id__c).Name;
        if(alert.altm__commercial_product_type__c == null) {
          alert.Group_Product__c = alert.Group_Name__c;
        } else {
          alert.Group_Product__c = alert.Group_Name__c == null ? alert.altm__commercial_product_type__c : alert.altm__commercial_product_type__c + ' - ' + alert.Group_Name__c;
        }
        if(alert.altm__commercial_alert_task_type__c == null) {
          alert.Group_Type__c = alert.Group_Name__c;
        } else {
          alert.Group_Type__c = alert.Group_Name__c == null ? alert.altm__commercial_alert_task_type__c : alert.altm__commercial_alert_task_type__c + ' - ' + alert.Group_Name__c;
        }
      }
    }
  }

  /*
  * @author Global Desktop
  * @Description Method to generateMapGroupName
  */
  private static Map<String, Account> completeMapGroup(Set<String> groupsCode) {
    final Map<String, Account> mapGroupName = new Map<String, Account>();
    final List<Account> accs = new List<Account>([
      SELECT Id, DES_Group_Code__c, Name FROM Account WHERE DES_Group_Code__c IN :groupsCode
    ]);
    for(Account acc : accs) {
      mapGroupName.put(acc.DES_Group_Code__c, acc);
    }
    return mapGroupName;
  }

  /**
  * @author Global Desktop
  * @Description genera un mapa con la clave externa del cliente y el id de salesforce en función de la tipología de alerta
  */
  private static Map<String, String> generateMaps(List<altm__Commercial_Alert__c> triggerNew) {
    final Set<String> setParticName = new Set<String>();

    for(altm__Commercial_Alert__c iCommercialAlert : triggerNew) {
      if(iCommercialAlert.participant_name__c != null && iCommercialAlert.altm__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GTB) {
        setParticName.add(iCommercialAlert.participant_name__c);
      }
    }

    final List<Account> accountsIds = new List <Account>([SELECT Id, g_customer_id__c
                                                          FROM Account
                                                          WHERE g_customer_id__c IN :setParticName]);

    return fillmapExtId(accountsIds);
  }

  /**
  * @author Global Desktop
  * @Description Genera un mapa con el codigo del grupo y el id de salesforce
  */
  private static Map<String, String> fillmapExtId(List<Account> accountsIds) {
    final Map<String, String> mapExtId = new Map <String, String>();

    for(Account iAccount : accountsIds) {
      if(iAccount.g_customer_id__c != null && mapExtId.get(iAccount.g_customer_id__c) == null) {
        mapExtId.put(iAccount.g_customer_id__c, iAccount.Id);
      }
    }

    return mapExtId;
  }

  /**
  * @author Global Desktop
  * @Description Copia el valor de un lookup a cliente relleno en uno vacio
  */
  public static void copyClient(altm__Commercial_Alert__c iCommercialAlert, Map<String, String> mapExtId) {
    if(iCommercialAlert.participant_name__c != null && mapExtId.get(iCommercialAlert.participant_name__c) != null) {
      iCommercialAlert.altm__participant_id__c = mapExtId.get(iCommercialAlert.participant_name__c);
    }
  }

  /**
  * @author Global Desktop
  * @Description Añade un campo al id de usuarios
  */
  private static Set<String> addIdsUser(String field, Set <String> idUsers1) {
    final Set<String> idUsers = idUsers1;
    if(!idUsers.contains(field) && field != null) {
      idUsers.add(field);
    }
    return idUsers;
  }

  /**
  * @author Global Desktop
  * @Description Añade un campo al id de usuarios
  */
  private static void setUserField(Map <String,Id> mapIdUsers, String userSearch, String fieldToOwrt, altm__Commercial_Alert__c iCommercialAlert) {
    if(mapIdUsers.get(userSearch) == null) {
        iCommercialAlert.put(fieldToOwrt, null);
    } else {
        iCommercialAlert.put(fieldToOwrt, mapIdUsers.get(userSearch));
    }
  }

  /**
  * @author Global Desktop
  * @Description Comprueba si el owner existe y lo guarda en el campo estandar de owner
  */
  public static void setLookupUsers(List<altm__Commercial_Alert__c> triggerNew, Map<Id, altm__Commercial_Alert__c> triggerOldMap) {
    System.debug('entro en setLookupUsers');
    if(USERNAME != AUTOMATED_PR && (PROFILENAME == Label.DES_ADMIN_PROFILE || PROFILENAME == Label.DES_INTEGRATION_PROFILE)) {
      Set<String> idUsers = new Set <String>();

      for(altm__Commercial_Alert__c iCommercialAlert : triggerNew) {
        if(iCommercialAlert.altm__alert_stage_type__c != Label.COMMERCIAL_ALERT_STATUS_DISCARDED) {
          idUsers = addIdsUser(iCommercialAlert.altm__owner_access_alert_id__c, idUsers);
          idUsers = addIdsUser(iCommercialAlert.sf_no_db_user_id__c, idUsers);
          idUsers = addIdsUser(iCommercialAlert.sf_no_db_monitor_manager_user_id__c, idUsers);
          idUsers = addIdsUser(iCommercialAlert.sf_no_db_ori_manager_user_id__c, idUsers);
        }
      }
      system.debug('>>>>>> Users Set:   ' + idUsers);

      setLookupUsersAux(triggerNew, idUsers, triggerOldMap);
    }
  }

  /**
  * @author Global Desktop
  * @Description Comprueba si el owner existe y lo guarda en el campo estandar de owner
  */
  public static void setLookupUsersAux(List<altm__Commercial_Alert__c> triggerNew, Set<String> idUsers, Map<Id, altm__Commercial_Alert__c> triggerOldMap) {
    List<User> users = new List<User>();
    final Map<String,Id> mapIdUsers = new Map<String,Id>();
    // recojo los usuarios de Salesforce de los campos auxiliares de lookup
    if(users.isEmpty() && !idUsers.isEmpty() && Schema.sObjectType.User.fields.FederationIdentifier.isAccessible()) {
      users = [SELECT Id, FederationIdentifier from User where FederationIdentifier IN : idUsers AND IsActive = true];

      system.debug('>>>>>> Users Set2:   ' + users);

      // guardo los federation ID
      for (User us : users) {
        if(!mapIdUsers.containsKey(us.FederationIdentifier)) {
          mapIdUsers.put(us.FederationIdentifier, us.Id);
        }
      }
      system.debug('>>>>>> Users Map:   ' + mapIdUsers);
    }

    for(altm__Commercial_Alert__c iCommercialAlert : triggerNew) {
      if(iCommercialAlert.altm__alert_stage_type__c != Label.COMMERCIAL_ALERT_STATUS_DISCARDED) {
        // Banker/Product Specialist
        setUserField(mapIdUsers, iCommercialAlert.altm__owner_access_alert_id__c, 'OwnerId', iCommercialAlert);
        setUserField(mapIdUsers, iCommercialAlert.sf_no_db_user_id__c, 'altm__User_id__c', iCommercialAlert);
        setUserField(mapIdUsers, iCommercialAlert.sf_no_db_monitor_manager_user_id__c, 'altm__Monitor_manager_user_id__c', iCommercialAlert);
        setUserField(mapIdUsers, iCommercialAlert.sf_no_db_ori_manager_user_id__c, 'altm__Origination_manager_user_id__c', iCommercialAlert);
      }
    }
    setOwner(triggerNew, mapIdUsers, triggerOldMap);
  }

  /*
  * @author Global Desktop
  * @Description Comprueba si el owner existe y lo guarda en el campo estandar de owner
  */
  public static void setOwner(List<altm__Commercial_Alert__c> triggerNew, Map <String,Id> mapIdUsers, Map<Id, altm__Commercial_Alert__c> triggerOldMap) {
    System.debug('entro en setOwner');
    final Map<String, List<DES_BBVA_Management_team__c>> mapAlertMembers = getTransactionBanker(triggerNew); //NOSONAR

    for(altm__Commercial_Alert__c commAlert : triggerNew) {
      system.debug('>>>>>> Old Owner:   ' + commAlert.OwnerId);

      // si el owner es inválido
      if(mapIdUsers.get(commAlert.altm__owner_access_alert_id__c) == null && commAlert.altm__alert_stage_type__c != Label.COMMERCIAL_ALERT_STATUS_DISCARDED) {
        setOwnerAux(commAlert, mapAlertMembers, triggerOldMap);
      } else if(commAlert.altm__alert_stage_type__c != Label.COMMERCIAL_ALERT_STATUS_DISCARDED) {
        commAlert.OwnerId = mapIdUsers.get(commAlert.altm__owner_access_alert_id__c);
      }
      system.debug('>>>>>> New Owner:   ' + commAlert.OwnerId);
    }
  } // FIN setOwner

  /*
  * @author Global Desktop
  * @Description setOwnerAux
  */
  public static void setOwnerAux(altm__Commercial_Alert__c commAlert, Map<String, List<DES_BBVA_Management_team__c>> mapAlertMembers,  Map<Id, altm__Commercial_Alert__c> triggerOldMap) {
    DES_BBVA_Management_team__c transactionBanker = new DES_BBVA_Management_team__c();
    for(DES_BBVA_Management_team__c member : mapAlertMembers.get(commAlert.altm__commercial_alert_id__c)) {
      if(member.DES_Member_Role__c == Label.DES_Role_Transactional_Banker) {
        transactionBanker = member;
      }
    }
    if(triggerOldMap == null || (triggerOldMap != null && triggerOldMap.get(commAlert.Id) != null && triggerOldMap.get(commAlert.Id).altm__gf_last_upload_alerts_ind_type__c == commAlert.altm__gf_last_upload_alerts_ind_type__c)) {
      if((commAlert.altm__commercial_alert_record_type__c != Label.DES_RT_COMM_ALERT_COM_TASK_GTB || (commAlert.altm__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GTB && transactionBanker.DES_User__c == null)) && !System.isBatch()) {
        commAlert.addError(Label.DES_INVALID_OWNER);
      } else if(commAlert.altm__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GTB && transactionBanker.DES_User__c != null) {
        commAlert.OwnerId = transactionBanker.DES_User__c;
        commAlert.altm__owner_access_alert_id__c = transactionBanker.DES_User__r.ID_User__c;
      }
    }
  }

  /*
  * @author Global Desktop
  * @Description Busca el transaction banker del grupo
  */
  public static Map<String, List<DES_BBVA_Management_team__c>> getTransactionBanker(List<altm__Commercial_Alert__c> triggerNew) {
    final Set<String> groupsCodes = new Set <String>();
    final Map<String, String> mapAlertGroup = new Map<String, String>();

    final set<Id> relAccId = new set<Id>();
    for(altm__Commercial_Alert__c alert : triggerNew) {
      relAccId.add(alert.altm__participant_id__c);
      if(alert.business_group_id__c != null) {
        groupsCodes.add(alert.business_group_id__c);
      }
    }

    final Map <String, String> mapCodeAccount = fillMapCodesId(groupsCodes);

    final List<DES_Subsidiary_Group_Relation__c> relGroupList = new List<DES_Subsidiary_Group_Relation__c> ([SELECT participant_parent_id__c
                                                                                                            FROM DES_Subsidiary_Group_Relation__c
                                                                                                            WHERE participant_child_id__c IN: relAccId AND main_subsidiary_ind_type__c = true]);
    final set<Id> groupIds = new set<Id>();
    for(DES_Subsidiary_Group_Relation__c matrix : relGroupList) {
      groupIds.add(matrix.participant_parent_id__c);
    }

    final Map<Id, DES_BBVA_Management_team__c> mapMembers = new Map <Id, DES_BBVA_Management_team__c>([
                                                                                                        SELECT Id, DES_User__c, DES_Client__c, DES_Member_Role__c, DES_Local_Banker_Country__c, DES_User__r.ID_User__c, CreatedDate
                                                                                                        FROM DES_BBVA_Management_team__c
                                                                                                        WHERE (DES_Member_Role__c =: Label.DES_Role_Transactional_Banker OR DES_Member_Role__c =: Label.DES_ROLE_GLOBAL_BANKER)
                                                                                                        AND DES_User__r.IsActive = true
                                                                                                        AND (DES_Client__c IN: groupIds OR DES_Client__c IN: mapCodeAccount.values())
                                                                                                        ORDER BY CreatedDate ASC
                                                                                                      ]);

    final Map <String, String> mapAccMembers = auxFillmapAccMembers(mapMembers);
    final Set <Id> setIdCuentas = getSetIdCuentas(triggerNew);

    system.debug('**setIdCuentasGrupos -> '+ setIdCuentas);

    for(altm__Commercial_Alert__c alert : triggerNew) {
      if(mapGroupFilial.get(alert.altm__participant_id__c) != null) {
        mapAlertGroup.put(alert.altm__commercial_alert_id__c, mapGroupFilial.get(alert.altm__participant_id__c));
      }
    }

    return fillMapTB(mapAlertGroup, mapAccMembers, triggerNew, mapCodeAccount, mapMembers);
  }

  /*
  * @author Global Desktop
  * @Description Completa el mapa del Transactional Banker
  */
  private static Map<String, List<DES_BBVA_Management_team__c>> fillMapTB(Map<String, String> mapAlertGroup, Map <String, String> mapAccMembers,
                                                                    List<altm__Commercial_Alert__c> triggerNew, Map <String, String> mapCodeAccount, Map<Id, DES_BBVA_Management_team__c> mapMembers) {
    final Map<String, List<DES_BBVA_Management_team__c>> mapAlertMembers = new Map<String, List<DES_BBVA_Management_team__c>>();

    for(altm__Commercial_Alert__c alert : triggerNew) {
      List<String> members = new List<String>();
      if(alert.business_group_id__c != null && mapAccMembers.get(mapCodeAccount.get(alert.business_group_id__c)) != null) { //NOSONAR
        members = mapAccMembers.get(mapCodeAccount.get(alert.business_group_id__c)).split(';');
      } else if(mapAlertGroup.get(alert.altm__commercial_alert_id__c) != null && mapAccMembers.get(mapAlertGroup.get(alert.altm__commercial_alert_id__c)) != null) {
        members = mapAccMembers.get(mapAlertGroup.get(alert.altm__commercial_alert_id__c)).split(';');
      }

      final List<DES_BBVA_Management_team__c> alertMembers = fillMapTBAux(members, mapMembers, alert);
      mapAlertMembers.put(alert.altm__commercial_alert_id__c, alertMembers);
    }
    return mapAlertMembers;
  }

  /**
  * @author Global Desktop
  * @Description fillMapTBAux
  */
  private static List<DES_BBVA_Management_team__c> fillMapTBAux(List<String> members, Map<Id, DES_BBVA_Management_team__c> mapMembers, altm__Commercial_Alert__c alert) {
    final List<DES_BBVA_Management_team__c> alertMembers = new List<DES_BBVA_Management_team__c>();
    for(String member : members) {
      if(mapMembers.containsKey(member) && (mapMembers.get(member).DES_Member_Role__c == Label.DES_ROLE_GLOBAL_BANKER || (mapMembers.get(member).DES_Local_Banker_Country__c == alert.altm__country_id__c && mapMembers.get(member).DES_Member_Role__c == Label.DES_Role_Transactional_Banker))) {
        alertMembers.add(mapMembers.get(member)); //Aquí se pisa el TB con el último si hay varios del mismo país
      }
    }

    return alertMembers;
  }

  /*
  * @author Global Desktop
  * @Description Genera un mapa con el codigo del grupo y el id de salesforce
  */
  private static Map<String, String> fillMapCodesId(Set<String> groupsCodes) {
    final Map <String, String> mapCodeAccount = new Map <String, String>();

    final List <Account> accounts = new List <Account> ([SELECT Id, DES_Group_Code__c FROM Account WHERE DES_Group_Code__c IN: groupsCodes]);
    for (Account acc : accounts) {
      mapCodeAccount.put(acc.DES_Group_Code__c, acc.Id);
    }

    return mapCodeAccount;
  }

  /*
  * Aux Method1 to get Transactional Banker
  */
  private static Map <String, String> auxFillmapAccMembers(Map<Id, DES_BBVA_Management_team__c> mapMembers) {
    final Map <String, String> mapAccMembers = new Map<String,String>();
    for(DES_BBVA_Management_team__c member : mapMembers.values()) {
      if(mapAccMembers.get(member.DES_Client__c) == null) {
        mapAccMembers.put(member.DES_Client__c, member.Id);
      } else {
        String concat = mapAccMembers.get(member.DES_Client__c);
        if(!concat.contains(member.Id)) {
          concat += ';' + member.Id;
        }
        mapAccMembers.put(member.DES_Client__c, concat);
      }
    }
    return mapAccMembers;
  }

  /*
  * @author Global Desktop
  * @Description Funcion que devuelve un set con los ids del cliente directo de la alerta y su padre principal
  */
  public static Set<Id> getSetIdCuentas(List<altm__Commercial_Alert__c> triggerNew) {
    final Set<Id> setIdsCuentas = new Set<Id>();
    for(altm__Commercial_Alert__c cAlert : triggerNew) {
      if(!setIdsCuentas.contains(cAlert.altm__participant_id__c)) {
        setIdsCuentas.add(cAlert.altm__participant_id__c);
      }
    }
    System.debug('@@setIdsCuentas' + setIdsCuentas);
    // recojo las matrix en las que las alertas son hijos
    final List<DES_Subsidiary_Group_Relation__c> matrixAccList = new List<DES_Subsidiary_Group_Relation__c> ([
                                                                                                              SELECT Id, participant_parent_id__c, participant_child_id__c FROM DES_Subsidiary_Group_Relation__c WHERE participant_child_id__c IN: setIdsCuentas AND main_subsidiary_ind_type__c = true
                                                                                                            ]);
    // guardo los padres en el set que ya tengo
    for(DES_Subsidiary_Group_Relation__c idAux : matrixAccList) {
      setIdsCuentas.add(idAux.participant_parent_id__c);
      mapGroupFilial.put(idAux.participant_child_id__c, idAux.participant_parent_id__c);
      System.debug('mapGroupSubsidiary ' + mapGroupFilial);
    }
    system.debug('>>>>> setIdsCuentas : ' + setIdsCuentas);
    return setIdsCuentas;
  }

  /**
  * @author Global Desktop
  * @Description Establece el record type de la alerta en función de su familia de producto y si tiene o no autorizadores de ganado o descarte
  */
  public static void stRecordType(List<altm__Commercial_Alert__c> triggerNew) {
    for(altm__Commercial_Alert__c comAlert : triggerNew) {
      if(comAlert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISABLED
        || comAlert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISCARDED
        || comAlert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_MATURED) {
        stRecordTypeAuxClosed(comAlert);
      } else {
        stRecordTypeAux(comAlert);
      }
    }
  } //FIN setRecordType

  /**
  * @author Global Desktop
  * @Description setRecordTypeAux
  */
  public static void stRecordTypeAux(altm__Commercial_Alert__c comAlert) {
    if(comAlert.altm__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_IBF) {
      comAlert.recordTypeId = Schema.SObjectType.altm__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_IBF).getRecordTypeId();
    } else if(comAlert.altm__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GM) {
      comAlert.recordTypeId = Schema.SObjectType.altm__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_GM).getRecordTypeId();
    } else if(comAlert.altm__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GTB) {
      comAlert.recordTypeId = Schema.SObjectType.altm__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_GTB).getRecordTypeId();
    } else if(comAlert.altm__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GCC) {
      comAlert.recordTypeId = Schema.SObjectType.altm__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_GCC).getRecordTypeId();
    }
  }

  /**
  * @author Global Desktop
  * @Description setRecordTypeAuxClosed
  */
  public static void stRecordTypeAuxClosed(altm__Commercial_Alert__c comAlert) {
    if(comAlert.altm__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_IBF) {
      comAlert.recordTypeId = Schema.SObjectType.altm__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_IBF_CLOSED).getRecordTypeId();
    } else if(comAlert.altm__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GM) {
      comAlert.recordTypeId = Schema.SObjectType.altm__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_GM_CLOSED).getRecordTypeId();
    } else if(comAlert.altm__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GTB) {
      comAlert.recordTypeId = Schema.SObjectType.altm__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_GTB_CLOSED).getRecordTypeId();
    }
  }

  /**
  * @author Global Desktop
  * @Description Establece el record type de la alerta en función de su familia de producto y si tiene o no autorizadores de ganado o descarte
  */
  public static void setRecordTypeOnUpdate(Map<Id, altm__Commercial_Alert__c> newMap, Map<Id, altm__Commercial_Alert__c> oldMap) {
    final List<altm__Commercial_Alert__c> listCommAlert = new List<altm__Commercial_Alert__c>();
    for(altm__Commercial_Alert__c iCommercialAlert : newMap.values()) {
      if(newMap.get(iCommercialAlert.Id).altm__commercial_alert_record_type__c != oldMap.get(iCommercialAlert.Id).altm__commercial_alert_record_type__c
        || newMap.get(iCommercialAlert.Id).recordTypeId != oldMap.get(iCommercialAlert.Id).recordTypeId
        || newMap.get(iCommercialAlert.Id).altm__alert_stage_type__c != oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c) {
        listCommAlert.add(iCommercialAlert);
      }
    }

    if(!listCommAlert.isEmpty()) {
      stRecordType(listCommAlert);
    }
  }

  /*
  * Method to inform the final owner
  */
  public static void informOwner(List<altm__Commercial_Alert__c> triggerNew, Map<Id, altm__Commercial_Alert__c> mapOld) {
    final Set<Id> usersIds = new Set<Id>();
    for(altm__Commercial_Alert__c alert : triggerNew) {
      usersIds.add(alert.OwnerId);
      if(mapOld != null) {
        usersIds.add(mapOld.get(alert.Id).OwnerId);
      }
    }
    final Map <Id, User> mapUsers = new Map<Id, User>([SELECT Id, FederationIdentifier from User Where Id IN :usersIds]);
    for(altm__Commercial_Alert__c alert : triggerNew) {
      if(mapUsers.get(alert.OwnerId) != null) {
        if(mapOld == null) {
          alert.Members_code__c = '**' + mapUsers.get(alert.OwnerId).FederationIdentifier + '**';
        } else if(mapUsers.get(mapOld.get(alert.Id).OwnerId).FederationIdentifier != mapUsers.get(alert.OwnerId).FederationIdentifier) { //NOSONAR
          alert.altm__owner_access_alert_id__c = mapUsers.get(alert.OwnerId).FederationIdentifier;
          if(mapUsers.get(alert.OwnerId)!=null&&mapUsers.get(alert.OwnerId).FederationIdentifier!=null&&mapOld.get(alert.Id)!=null&&mapOld.get(alert.Id).OwnerId!=null&&mapUsers.get(mapOld.get(alert.Id).OwnerId)!=null&&alert.Members_code__c!=null)
          {
            alert.Members_code__c = alert.Members_code__c.replace('**' + mapUsers.get(mapOld.get(alert.Id).OwnerId).FederationIdentifier + '**', '**' + mapUsers.get(alert.OwnerId).FederationIdentifier + '**');
          
          }
        } else if(alert.Members_code__c != null && alert.Members_code__c.contains(mapUsers.get(mapOld.get(alert.Id).OwnerId).FederationIdentifier)) {
          alert.Members_code__c = alert.Members_code__c.replace(',' + mapUsers.get(mapOld.get(alert.Id).OwnerId).FederationIdentifier, ',' + mapUsers.get(alert.OwnerId).FederationIdentifier);
        }
      }
    }
  }

/**
  * @author Global Desktop
  * @Description setStatusOnInsert
  */
  public static void setStatusOnInsert(List<altm__Commercial_Alert__c> newList) { //NOSONAR
    for(altm__Commercial_Alert__c iCommercialAlert : newList) {
      if(iCommercialAlert.altm__alert_stage_type__c == null
        || iCommercialAlert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_PENDING) {
        if(iCommercialAlert.altm__commercial_alert_end_date__c < Date.today()) {
          iCommercialAlert.altm__alert_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_MATURED;
        } else {
          iCommercialAlert.altm__alert_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_PENDING;
        }
      } else if(iCommercialAlert.altm__alert_stage_type__c != null
        && iCommercialAlert.altm__alert_stage_type__c != Label.COMMERCIAL_ALERT_STATUS_DISABLED
        && iCommercialAlert.altm__alert_stage_type__c != Label.COMMERCIAL_ALERT_STATUS_UNREAD
        && iCommercialAlert.altm__alert_stage_type__c != Label.COMMERCIAL_ALERT_STATUS_PENDING) {
        iCommercialAlert.addError(Label.COMMERCIAL_ALERT_STATUS_NOT_ALLOWED + ': ' + iCommercialAlert.altm__alert_stage_type__c);
      }
    }
  }

  /**
  * @author Global Desktop
  * @Description setStatusOnUpdate
  */
  public static void setStatusOnUpdate(Map<Id, altm__Commercial_Alert__c> newMap, Map<Id, altm__Commercial_Alert__c> oldMap) { //NOSONAR
    for(altm__Commercial_Alert__c iCommercialAlert : newMap.values()) {
      if(iCommercialAlert.altm__alert_stage_type__c == null
        || iCommercialAlert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_PENDING) {
          System.debug('Entra Empty');
        setStatusOnUpdateEmpty(newMap, oldMap, iCommercialAlert);
      } else if(iCommercialAlert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISABLED) {
        System.debug('Entra Disabled');
        setStatusOnUpdateDisabled(newMap, oldMap, iCommercialAlert);
      } else if(iCommercialAlert.altm__alert_stage_type__c != null
        && iCommercialAlert.altm__alert_stage_type__c != Label.COMMERCIAL_ALERT_STATUS_DISABLED
        && iCommercialAlert.altm__alert_stage_type__c != Label.COMMERCIAL_ALERT_STATUS_PENDING
        && USERNAME != AUTOMATED_PR
        && (PROFILENAME == Label.DES_ADMIN_PROFILE
          || PROFILENAME == Label.DES_INTEGRATION_PROFILE)
        && (oldMap.get(iCommercialAlert.Id).altm__gf_last_upload_alerts_ind_type__c == false
          || iCommercialAlert.altm__gf_last_upload_alerts_ind_type__c == true)
        && !System.isBatch()) {
            System.debug('Entra error');
        iCommercialAlert.addError(Label.COMMERCIAL_ALERT_STATUS_NOT_ALLOWED + ': ' + iCommercialAlert.altm__alert_stage_type__c);
      }
    }
  }

  /**
  * @author Global Desktop
  * @Description setStatusOnUpdateEmpty
  */
  public static void setStatusOnUpdateEmpty(Map<Id, altm__Commercial_Alert__c> newMap, Map<Id, altm__Commercial_Alert__c> oldMap, altm__Commercial_Alert__c iCommercialAlert) { //NOSONAR
    if((oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_MATURED
        || oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_UNREAD
        || oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISABLED)
      && iCommercialAlert.altm__commercial_alert_end_date__c >= Date.today()) {
      iCommercialAlert.altm__alert_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_PENDING;
    } else if((oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_MATURED
        || oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_UNREAD
        || oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISABLED)
        && iCommercialAlert.altm__commercial_alert_end_date__c < Date.today()) {
      iCommercialAlert.altm__alert_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_MATURED;
    } else if((oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_MANAGED
        || oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISCARDED)
      && USERNAME != AUTOMATED_PR
      && (PROFILENAME == Label.DES_ADMIN_PROFILE
        || PROFILENAME == Label.DES_INTEGRATION_PROFILE)) {
      iCommercialAlert.addError('The alert ' + iCommercialAlert.Name + ' ' + Label.COMMERCIAL_ALERT_CANNOT_BE_UPDATED + ': ' + iCommercialAlert.altm__alert_stage_type__c);
    } else {
      iCommercialAlert.altm__alert_stage_type__c = oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c;
    }
  }

  /**
  * @author Global Desktop
  * @Description setStatusOnUpdateDisabled
  */
  public static void setStatusOnUpdateDisabled(Map<Id, altm__Commercial_Alert__c> newMap, Map<Id, altm__Commercial_Alert__c> oldMap, altm__Commercial_Alert__c iCommercialAlert) {
    if(oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_PENDING
      || oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_MATURED) {
      iCommercialAlert.altm__alert_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_DISABLED;
    } else if((oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_MANAGED
        || oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISCARDED)
      && USERNAME != AUTOMATED_PR && (PROFILENAME == Label.DES_ADMIN_PROFILE || PROFILENAME == Label.DES_INTEGRATION_PROFILE)) {
      iCommercialAlert.addError('The alert ' + iCommercialAlert.Name + ' ' + Label.COMMERCIAL_ALERT_CANNOT_BE_UPDATED + ': ' + iCommercialAlert.altm__alert_stage_type__c);
    } else {
      iCommercialAlert.altm__alert_stage_type__c = oldMap.get(iCommercialAlert.Id).altm__alert_stage_type__c;
    }
  }

  /**
  * @author Global Desktop
  * @Description createManualSharingInsert
  */
  public static void createManualSharingInsert(List<altm__Commercial_Alert__c> newList) {
    final List<altm__Commercial_Alert__Share> commAlertShare = new List<altm__Commercial_Alert__Share>();
    final Set<Id> setAccountId = new Set<Id>();
    final Set<String> groupsIds = new Set<String>();

    for(altm__Commercial_Alert__c iCommercialAlert : newList) {
      System.debug('iCommercialAlert.OwnerId: ' + iCommercialAlert.OwnerId);

      if(!setAccountId.contains(iCommercialAlert.altm__participant_id__c)) {
        setAccountId.add(iCommercialAlert.altm__participant_id__c);
      }

      if(iCommercialAlert.altm__User_id__c != null) {
        commAlertShare.add(newBankerManualSharingCommAlert(iCommercialAlert.Id, iCommercialAlert.altm__User_id__c));
      }

      if(iCommercialAlert.business_group_id__c != null) {
        groupsIds.add(iCommercialAlert.business_group_id__c);
      }
    }

    final Map<String, Account> mapGroup = completeMapGroup(groupsIds);

    //BUSCO LOS GRUPOS VINCULADOS A ESTAS CUENTAS
    createManualSharingInsertAux(newList, setAccountId, mapGroup, commAlertShare);
  }

  /**
  * @author Global Desktop
  * @Description createManualSharingInsertAux
  */
  public static void createManualSharingInsertAux(List<altm__Commercial_Alert__c> newList, final Set<Id> setAccountId, final Map<String, Account> mapGroup, List<altm__Commercial_Alert__Share> commAlertShare) {
    //BUSCO LOS GRUPOS VINCULADOS A ESTAS CUENTAS
    final Map<Id, Id> mapClientGroup = getMapClientGroup(setAccountId);
    final Map<Id, List<DES_BBVA_Management_Team__c>> mapClientTeam = new Map<Id, List<DES_BBVA_Management_Team__c>>();
    for(DES_BBVA_Management_Team__c iBBVAManagTeam : [SELECT Id,
                                                        DES_Client__c,
                                                        DES_User__c
                                                      FROM DES_BBVA_Management_Team__c
                                                      WHERE (DES_Client__c IN :setAccountId
                                                          OR DES_Client__c IN :mapClientGroup.values()
                                                          OR DES_Client__c IN :mapGroup.values())
                                                        AND copy_record_approval_type__c = false
                                                        AND DES_User__r.isActive = true]) {
      if(mapClientTeam.containsKey(iBBVAManagTeam.DES_Client__c)) {
        final List<DES_BBVA_Management_Team__c> listAux = mapClientTeam.get(iBBVAManagTeam.DES_Client__c);
        listAux.add(iBBVAManagTeam);
        mapClientTeam.put(iBBVAManagTeam.DES_Client__c, listAux);
      } else {
        mapClientTeam.put(iBBVAManagTeam.DES_Client__c, new List<DES_BBVA_Management_Team__c> {iBBVAManagTeam});
      }
    }

    List<altm__Commercial_Alert__Share> newCommAlertShare = new List<altm__Commercial_Alert__Share>();
    newCommAlertShare = createManualSharingInsertGetShare(newList, mapGroup, commAlertShare, mapClientGroup, mapClientTeam);

    Commercial_Alert_Share_Helper.insertCommAlertShare(newCommAlertShare);
  }

  /**
  * @author Global Desktop
  * @Description createManualSharingInsertGetShare
  */
  public static List<altm__Commercial_Alert__Share> createManualSharingInsertGetShare(List<altm__Commercial_Alert__c> newList, final Map<String, Account> mapGroup, final List<altm__Commercial_Alert__Share> commAlertShare, final Map<Id, Id> mapClientGroup, Map<Id, List<DES_BBVA_Management_Team__c>> mapClientTeam) {
    for(altm__Commercial_Alert__c iCommercialAlert : newList) {
      System.debug('::::::::::mapClientTeam.get(mapClientGroup.get(iCommercialAlert.altm__participant_id__c)): ' + mapClientTeam.get(mapClientGroup.get(iCommercialAlert.altm__participant_id__c)));
      if(mapClientTeam.get(iCommercialAlert.altm__participant_id__c) != null) {
        for(DES_BBVA_Management_Team__c iBBVAManagTeam : mapClientTeam.get(iCommercialAlert.altm__participant_id__c)) {
          commAlertShare.add(newBBVAManualSharingCommAlert(iCommercialAlert.Id, iBBVAManagTeam.DES_User__c));
        }
      }
      if(mapGroup.get(iCommercialAlert.business_group_id__c) != null //NOSONAR
        && mapClientTeam.get(mapGroup.get(iCommercialAlert.business_group_id__c).Id) != null) {
        for(DES_BBVA_Management_Team__c iBBVAManagTeam : mapClientTeam.get(mapGroup.get(iCommercialAlert.business_group_id__c).Id)) {
          commAlertShare.add(newBBVAGroupManualSharingCommAlert(iCommercialAlert.Id, iBBVAManagTeam.DES_User__c));
        }
      } else if(mapClientTeam.get(mapClientGroup.get(iCommercialAlert.altm__participant_id__c)) != null) {
        for(DES_BBVA_Management_Team__c iBBVAManagTeam : mapClientTeam.get(mapClientGroup.get(iCommercialAlert.altm__participant_id__c))) {
          commAlertShare.add(newBBVAGroupManualSharingCommAlert(iCommercialAlert.Id, iBBVAManagTeam.DES_User__c));
        }
      }
    }

    return commAlertShare;
  }

  /**
  * @author Global Desktop
  * @Description createManualSharingUpdate
  */
  public static void createManualSharingUpdate(Map<Id, altm__Commercial_Alert__c> newMap, Map<Id, altm__Commercial_Alert__c> oldMap) {
    final List<altm__Commercial_Alert__Share> commAlertShare = new List<altm__Commercial_Alert__Share>();
    final Set<Id> setAccountId = new Set<Id>(); //NOSONAR
    final Set<String> groupsIds = new Set<String>(); //NOSONAR

    final Set<altm__Commercial_Alert__c> bankerCommAlert = new Set<altm__Commercial_Alert__c>(); //NOSONAR
    final Set<altm__Commercial_Alert__c> bbvaTeamCommAlert = new Set<altm__Commercial_Alert__c>();
    final Set<altm__Commercial_Alert__c> groupTeamComAlert = new Set<altm__Commercial_Alert__c>();
    for(altm__Commercial_Alert__c iCommercialAlert : newMap.values()) {
      if(oldMap.get(iCommercialAlert.Id) != null
        && iCommercialAlert.altm__User_id__c != oldMap.get(iCommercialAlert.Id).altm__User_id__c) {
        bankerCommAlert.add(iCommercialAlert);
      }

      if(iCommercialAlert.altm__participant_id__c != oldMap.get(iCommercialAlert.Id).altm__participant_id__c) {
        setAccountId.add(iCommercialAlert.altm__participant_id__c);
        bbvaTeamCommAlert.add(iCommercialAlert);
      }

      if(iCommercialAlert.business_group_id__c != oldMap.get(iCommercialAlert.Id).business_group_id__c) {
        if(iCommercialAlert.business_group_id__c != null) {
          groupsIds.add(iCommercialAlert.business_group_id__c);
        }
        groupTeamComAlert.add(iCommercialAlert);
      }
    }

    createManualSharingUpdateAux(bankerCommAlert, bbvaTeamCommAlert, setAccountId, commAlertShare, groupTeamComAlert, groupsIds);
  }

  /**
  * @author Global Desktop
  * @Description createManualSharingUpdateAux
  */
  public static void createManualSharingUpdateAux(final Set<altm__Commercial_Alert__c> bankerCommAlert, final Set<altm__Commercial_Alert__c> bbvaTeamCommAlert, final Set<Id> setAccountId, final List<altm__Commercial_Alert__Share> commAlertShare, final Set<altm__Commercial_Alert__c> groupTeamComAlert, final Set<String> groupsIds) {
    //BUSCO LOS GRUPOS VINCULADOS A ESTAS CUENTAS
    if(!bankerCommAlert.isEmpty()) {
      commAlertShare.addAll(changeBankerShareCommercialAlert(bankerCommAlert));
    }

    if(!bbvaTeamCommAlert.isEmpty()) {
      final Map<Id, Id> mapClientGroup = getMapClientGroup(setAccountId);
      commAlertShare.addAll(changeBBVATeamShareCommercialAlert(bbvaTeamCommAlert, setAccountId, mapClientGroup));
    }

    if(!groupTeamComAlert.isEmpty()) {
      final Map<String, Account> mapGroup = completeMapGroup(groupsIds);
      commAlertShare.addAll(changeGroupShareCommAlert(groupTeamComAlert, mapGroup));
    }

    Commercial_Alert_Share_Helper.insertCommAlertShare(commAlertShare);
  }

  /**
  * @author Global Desktop
  * @Description changeBankerShareCommercialAlert
  */
  public static List<altm__Commercial_Alert__Share> changeBankerShareCommercialAlert(Set<altm__Commercial_Alert__c> bankerCommAlert) { //NOSONAR
    final List<altm__Commercial_Alert__Share> commAlertShare = new List<altm__Commercial_Alert__Share>([
      SELECT Id
      FROM altm__Commercial_Alert__Share
      WHERE ParentId IN :bankerCommAlert
      AND RowCause = :Schema.altm__Commercial_Alert__Share.RowCause.Banker_member__c
    ]);

    if(!commAlertShare.isEmpty()) {
      delete commAlertShare;
    }

    final List<altm__Commercial_Alert__Share> newCommAlertShare = new List<altm__Commercial_Alert__Share>();
    for(altm__Commercial_Alert__c iCommercialAlert : bankerCommAlert) {
      if(iCommercialAlert.altm__User_id__c != null) {
        newCommAlertShare.add(newBankerManualSharingCommAlert(iCommercialAlert.Id, iCommercialAlert.altm__User_id__c));
      }
    }

    return newCommAlertShare;
  }

  /**
  * @author Global Desktop
  * @Description changeBBVATeamShareCommercialAlert
  */
  public static List<altm__Commercial_Alert__Share> changeBBVATeamShareCommercialAlert(Set<altm__Commercial_Alert__c> bbvaTeamCommAlert, Set<Id> setAccountId, Map<Id, Id> mapClientGroup) { //NOSONAR
    final List<altm__Commercial_Alert__Share> commAlertShare = new List<altm__Commercial_Alert__Share>([
      SELECT Id
      FROM altm__Commercial_Alert__Share
      WHERE ParentId IN :bbvaTeamCommAlert
      AND (RowCause = :Schema.altm__Commercial_Alert__Share.RowCause.Participant_member__c
      OR RowCause = :Schema.altm__Commercial_Alert__Share.RowCause.Group_member__c)
    ]);

    if(!commAlertShare.isEmpty()) {
      delete commAlertShare;
    }

    final List<altm__Commercial_Alert__Share> newCommAlertShare = new List<altm__Commercial_Alert__Share>();
    final Map<Id, List<DES_BBVA_Management_Team__c>> mapClientTeam = new Map<Id, List<DES_BBVA_Management_Team__c>>();
    for(DES_BBVA_Management_Team__c iBBVAManagTeam : [SELECT Id,
                                                        DES_Client__c,
                                                        DES_User__c
                                                      FROM DES_BBVA_Management_Team__c
                                                      WHERE (DES_Client__c IN :setAccountId
                                                          OR DES_Client__c IN :mapClientGroup.values())
                                                        AND copy_record_approval_type__c = false
                                                        AND DES_User__r.IsActive = true]) {
      if(mapClientTeam.containsKey(iBBVAManagTeam.DES_Client__c)) {
        final List<DES_BBVA_Management_Team__c> listAux = mapClientTeam.get(iBBVAManagTeam.DES_Client__c);
        listAux.add(iBBVAManagTeam);
        mapClientTeam.put(iBBVAManagTeam.DES_Client__c, listAux);
      } else {
        mapClientTeam.put(iBBVAManagTeam.DES_Client__c, new List<DES_BBVA_Management_Team__c> {iBBVAManagTeam});
      }
    }

    for(altm__Commercial_Alert__c iCommercialAlert : bbvaTeamCommAlert) {
      if(mapClientTeam.get(iCommercialAlert.altm__participant_id__c) != null) {
        for(DES_BBVA_Management_Team__c iBBVAManagTeam : mapClientTeam.get(iCommercialAlert.altm__participant_id__c)) {
          newCommAlertShare.add(newBBVAManualSharingCommAlert(iCommercialAlert.Id, iBBVAManagTeam.DES_User__c));
        }
      }
      if(mapClientTeam.get(mapClientGroup.get(iCommercialAlert.altm__participant_id__c)) != null) {
        for(DES_BBVA_Management_Team__c iBBVAManagTeam : mapClientTeam.get(mapClientGroup.get(iCommercialAlert.altm__participant_id__c))) {
          newCommAlertShare.add(newBBVAGroupManualSharingCommAlert(iCommercialAlert.Id, iBBVAManagTeam.DES_User__c));
        }
      }
    }

    return newCommAlertShare;
  }

  /**
  * @author Global Desktop
  * @Description changeGroupShareCommAlert
  */
  public static List<altm__Commercial_Alert__Share> changeGroupShareCommAlert(Set<altm__Commercial_Alert__c> groupTeamCommAlert, Map<String, Account> mapGroup) { //NOSONAR
    final List<altm__Commercial_Alert__Share> commAlertShare = new List<altm__Commercial_Alert__Share>([
      SELECT Id
      FROM altm__Commercial_Alert__Share
      WHERE ParentId IN :groupTeamCommAlert
      AND RowCause = :Schema.altm__Commercial_Alert__Share.RowCause.Group_member__c
    ]);

    if(!commAlertShare.isEmpty()) {
      delete commAlertShare;
    }

    final List<altm__Commercial_Alert__Share> newCommAlertShare = new List<altm__Commercial_Alert__Share>();
    final Map<Id, List<DES_BBVA_Management_Team__c>> mapClientTeam = new Map<Id, List<DES_BBVA_Management_Team__c>>();
    if(!mapGroup.values().isEmpty()) {
      for(DES_BBVA_Management_Team__c iBBVAManagTeam : [SELECT Id, DES_Client__c, DES_User__c
        FROM DES_BBVA_Management_Team__c
        WHERE DES_Client__c IN :mapGroup.values() AND copy_record_approval_type__c = false AND DES_User__r.IsActive = true]) {
          if(mapClientTeam.containsKey(iBBVAManagTeam.DES_Client__c)) {
            final List<DES_BBVA_Management_Team__c> listAux = mapClientTeam.get(iBBVAManagTeam.DES_Client__c);
            listAux.add(iBBVAManagTeam);
            mapClientTeam.put(iBBVAManagTeam.DES_Client__c, listAux);
          } else {
            mapClientTeam.put(iBBVAManagTeam.DES_Client__c, new List<DES_BBVA_Management_Team__c> {iBBVAManagTeam});
          }
      }
    }

    for(altm__Commercial_Alert__c iCommercialAlert : groupTeamCommAlert) {
      if(mapGroup.get(iCommercialAlert.business_group_id__c) != null
        && mapClientTeam.get(mapGroup.get(iCommercialAlert.business_group_id__c).Id) != null) {
        for(DES_BBVA_Management_Team__c iBBVAManagTeam : mapClientTeam.get(mapGroup.get(iCommercialAlert.business_group_id__c).Id)) {
          newCommAlertShare.add(newBBVAGroupManualSharingCommAlert(iCommercialAlert.Id, iBBVAManagTeam.DES_User__c));
        }
      }
    }

    return newCommAlertShare;
  }

  /**
  * @author Global Desktop
  * @Description newBankerManualSharingCommAlert
  */
  public static altm__Commercial_Alert__Share newBankerManualSharingCommAlert(Id recordId, Id userOrGroupId) { //NOSONAR
    final altm__Commercial_Alert__Share comAlertShare  = new altm__Commercial_Alert__Share();
    comAlertShare.ParentId = recordId;
    comAlertShare.UserOrGroupId = userOrGroupId;
    comAlertShare.AccessLevel = 'Edit';
    comAlertShare.RowCause = Schema.altm__Commercial_Alert__Share.RowCause.Banker_member__c;

    System.debug('::::::::::comAlertShare: ' + comAlertShare);
    return comAlertShare;
  }

  /**
  * @author Global Desktop
  * @Description newBBVAManualSharingCommAlert
  */
  public static altm__Commercial_Alert__Share newBBVAManualSharingCommAlert(Id recordId, Id userOrGroupId) { //NOSONAR
    final altm__Commercial_Alert__Share comAlertShare  = new altm__Commercial_Alert__Share();
    comAlertShare.ParentId = recordId;
    comAlertShare.UserOrGroupId = userOrGroupId;
    comAlertShare.AccessLevel = 'Edit';
    comAlertShare.RowCause = Schema.altm__Commercial_Alert__Share.RowCause.Participant_member__c;

    System.debug('::::::::::comAlertShare: ' + comAlertShare);
    return comAlertShare;
  }

  /**
  * @author Global Desktop
  * @Description newBBVAManualSharingCommAlert
  */
  public static altm__Commercial_Alert__Share newBBVAGroupManualSharingCommAlert(Id recordId, Id userOrGroupId) { //NOSONAR
    final altm__Commercial_Alert__Share comAlertShare  = new altm__Commercial_Alert__Share();
    comAlertShare.ParentId = recordId;
    comAlertShare.UserOrGroupId = userOrGroupId;
    comAlertShare.AccessLevel = 'Edit';
    comAlertShare.RowCause = Schema.altm__Commercial_Alert__Share.RowCause.Group_member__c;

    System.debug('::::::::::comAlertShare: ' + comAlertShare);
    return comAlertShare;
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

  /**
  * @author Global Desktop
  * @Description getClientCounterpartyUpdate
  */
  public static void getClientCounterpartyUpdate(Map<Id, altm__Commercial_Alert__c> newMap, Map<Id, altm__Commercial_Alert__c> oldMap) { //NOSONAR
    final List<altm__Commercial_Alert__c> listCommAlertGM = new List<altm__Commercial_Alert__c>();
    for(altm__Commercial_Alert__c iCommercialAlert : newMap.values()) {
      if(iCommercialAlert.altm__commercial_alert_record_type__c == LABEL.DES_RT_COMM_ALERT_COM_TASK_GM) {
        iCommercialAlert.altm__participant_id__c = oldMap.get(iCommercialAlert.Id).altm__participant_id__c;
        if(iCommercialAlert.Client_STAR_ID__c != null && iCommercialAlert.Client_STAR_ID__c != oldMap.get(iCommercialAlert.Id).Client_STAR_ID__c) {
          listCommAlertGM.add(iCommercialAlert);
        }
      }
    }

    if(!listCommAlertGM.isEmpty()) {
      getClientCounterparty(listCommAlertGM);
    }
  }

  /**
  * @author Global Desktop
  * @Description getClientCounterparty
  */
  public static void getClientCounterparty(List<altm__Commercial_Alert__c> newList) { //NOSONAR
    final List<altm__Commercial_Alert__c> listCommAlertGM = new List<altm__Commercial_Alert__c>();
    for(altm__Commercial_Alert__c iCommercialAlert : newList) {
      if(iCommercialAlert.altm__commercial_alert_record_type__c == LABEL.DES_RT_COMM_ALERT_COM_TASK_GM) {
        listCommAlertGM.add(iCommercialAlert);
      }
    }

    final List<String> listStarID = new List<String>();
    for(altm__Commercial_Alert__c iCommercialAlert : listCommAlertGM) {
      final String starID = '%' + iCommercialAlert.Client_STAR_ID__c + '%';
      listStarID.add(starID);
    }

    System.debug('::::::::::');
    final Map<String, Id> mapStarIDClient = new Map<String, Id>();
    for(Counterparty__c iCounterparty : [SELECT Id,
                                          star_counterparty_oper_desc__c,
                                          participant_id__c
                                        FROM Counterparty__c
                                        WHERE star_counterparty_oper_desc__c LIKE :listStarID]) {
      for(String starID : iCounterparty.star_counterparty_oper_desc__c.split(',')) {
        mapStarIdClient.put(starID.replaceAll(' ', ''), iCounterparty.participant_id__c);
      }
    }

    for(altm__Commercial_Alert__c iCommercialAlert : listCommAlertGM) {
      if(mapStarIdClient.containsKey(iCommercialAlert.Client_STAR_ID__c)) {
        iCommercialAlert.altm__participant_id__c = mapStarIdClient.get(iCommercialAlert.Client_STAR_ID__c);
      }
    }
  }

  /**
  * @author Global Desktop
  * @description resetLastLoadFut
  */
  @future
  public static void resetLastLoadFut(String newListJSON) { //NOSONAR
    final List<altm__Commercial_Alert__c> newList = (List<altm__Commercial_Alert__c>) JSON.deserialize(newListJSON, List<altm__Commercial_Alert__c>.class);
    final List<altm__Commercial_Alert__c> listCommAlert = new List<altm__Commercial_Alert__c>();
    final Set<String> recordTypesSt = new Set<String>();
    for(altm__Commercial_Alert__c iCommercialAlert : newList) {
      recordTypesSt.add(iCommercialAlert.altm__commercial_alert_record_type__c);
    }
    for(altm__Commercial_Alert__c iCommercialAlert : [SELECT Id, altm__gf_last_upload_alerts_ind_type__c,ownerId FROM altm__Commercial_Alert__c WHERE altm__gf_last_upload_alerts_ind_type__c = true AND Id NOT IN :newList AND altm__commercial_alert_record_type__c IN :recordTypesSt AND CreatedDate != TODAY AND Owner.IsActive = true and ownerId!=null for update]) { //NOSONAR
      iCommercialAlert.altm__gf_last_upload_alerts_ind_type__c = false;
      listCommAlert.add(iCommercialAlert);
    }

    if(!listCommAlert.isEmpty()) {
      update listCommAlert;
    }
  }

  /**
  * @author Global Desktop
  * @Description getParticipantClient
  */
  public static void getParticipantClient(List<altm__Commercial_Alert__c> newList, Map<Id, altm__Commercial_Alert__c> oldMap) {
    final List<altm__Commercial_Alert__c> listParticipant = new List<altm__Commercial_Alert__c>();
    if(oldMap == null) {
      listParticipant.addAll(newList);
    } else {
      for(altm__Commercial_Alert__c alert : newList) {
        if(alert.altm__commercial_alert_record_type__c == LABEL.DES_RT_COMM_ALERT_COM_TASK_GTB) {
          alert.altm__participant_id__c = oldMap.get(alert.Id).altm__participant_id__c;
          if(alert.participant_name__c != null && alert.participant_name__c != oldMap.get(alert.Id).participant_name__c) {
            listParticipant.add(alert);
          }
        }
      }
    }
    if(!listParticipant.isEmpty()) {
      final Map<String, String> mapExtId = generateMaps(listParticipant);
      for(altm__Commercial_Alert__c alert : listParticipant) {
        copyClient(alert, mapExtId);
      }
    }
  }

  /*
  * @author Global Desktop
  * @Description Insert owner in alert team
  */
  public static List<ctcp__Custom_Team__c> addMembers(List<altm__Commercial_Alert__c> triggerNew, Map<String, Id> alertOwnerId, List<ctcp__Custom_Team__c> customTeam) {
    final Map<String, List<DES_BBVA_Management_team__c>> mapAlertMembers = getTransactionBanker(triggerNew); //NOSONAR
    final List<ctcp__Custom_Team__c> customTeamAux = customTeam;
    system.debug('**customTeamAux -> ' + JSON.serialize(customTeamAux));
    for(altm__Commercial_Alert__c commAlert : triggerNew) {
      for(DES_BBVA_Management_team__c memb : mapAlertMembers.get(commAlert.altm__commercial_alert_id__c)) {
        if(alertOwnerId.get(commAlert.altm__commercial_alert_id__c) != null && alertOwnerId.get(commAlert.altm__commercial_alert_id__c) != memb.DES_User__c) {
          final ctcp__Custom_Team__c member = createMember(commAlert.Id, memb.DES_User__c, true);
          customTeamAux.add(member);
        }
      }
    }
    return customTeamAux;
  }

  /*
  * @author Global Desktop
  * @Description Insert owner in alert team
  */
  public static void addOwner(List<altm__Commercial_Alert__c> triggerNew) {
    List<ctcp__Custom_Team__c> customTeam = new List<ctcp__Custom_Team__c>();
    //final Map<String, List<DES_BBVA_Management_team__c>> mapAlertMembers = getTransactionBanker(triggerNew); //NOSONAR
    final Map<String, Id> alertOwnerId = new Map<String, Id>();
    for(altm__Commercial_Alert__c alert : triggerNew) {
      final ctcp__Custom_Team__c member = createMember(alert.Id, alert.OwnerId, false);
      alertOwnerId.put(alert.altm__commercial_alert_id__c, alert.OwnerId);
      customTeam.add(member);
    }
    system.debug('**customTeamOwner -> ' + JSON.serialize(customTeam));
    customTeam = addMembers(triggerNew, alertOwnerId, customTeam);
    checkListMember(customTeam, true);
  }

  /*
  * @author Global Desktop
  * @Description Add the new owner to alert team
  */
  public static void changeOwner(List<altm__Commercial_Alert__c> triggerNew, Map<Id, altm__Commercial_Alert__c> mapOld) {
    final Map<Id, Id> alertOwnyOld = new Map<Id, Id>();
    final Map<Id, Id> alertOwnyNew = new Map<Id, Id>(); //NOSONAR
    for(altm__Commercial_Alert__c alert : triggerNew) {
      if(alert.OwnerId != mapOld.get(alert.Id).OwnerId) {
        alertOwnyOld.put(alert.Id, mapOld.get(alert.Id).OwnerId);
        alertOwnyNew.put(alert.Id, alert.OwnerId);
      }
    }
    final List<ctcp__Custom_Team__c> members = new List<ctcp__Custom_Team__c>([
      SELECT Id, commercial_alert_id__c, ctcp__gf_team_users_desc__c
      FROM ctcp__Custom_Team__c
      WHERE commercial_alert_id__c IN :alertOwnyOld.keySet() AND ctcp__gf_team_users_desc__c IN :alertOwnyOld.values()
    ]);

    final List<ctcp__Custom_Team__c> toDelete = new List<ctcp__Custom_Team__c>();
    final List<ctcp__Custom_Team__c> toCreate = new List<ctcp__Custom_Team__c>();
    for(ctcp__Custom_Team__c memb : members) {
      for(Id alertId : alertOwnyOld.keySet()) {
        if(memb.commercial_alert_id__c == alertId && memb.ctcp__gf_team_users_desc__c == alertOwnyOld.get(alertId)) {
          toDelete.add(memb);
          final ctcp__Custom_Team__c member = createMember(alertId, alertOwnyNew.get(alertId), false);
          toCreate.add(member);
        }
      }
    }
    checkListMember(toCreate, true);
    checkListMember(toDelete, false);
  }

  /*
  * @author Global Desktop
  * @Description Delete Members when alert is deleted
  */
  public static void deleteMembers(List<altm__Commercial_Alert__c> triggerOld) {
    final Set<Id> alertsId = new Set<Id>();
    for(altm__Commercial_Alert__c alert : triggerOld) {
      alertsId.add(alert.Id);
    }
    final List<ctcp__Custom_Team__c> toDelete = new List<ctcp__Custom_Team__c>([
      SELECT Id
      FROM ctcp__Custom_Team__c
      WHERE commercial_alert_id__c IN :alertsId
    ]);

    checkListMember(toDelete, false);
  }

  /*
  * @author Global Desktop
  * @Description Method to register the first owner of the alert
  */
  public static void setOriginalOwner(List<altm__Commercial_Alert__c> newList) { //NOSONAR
    final Map<Id, List<altm__Commercial_Alert__c>> mapOwnerAlerts = new Map<Id, List<altm__Commercial_Alert__c>>();
    for(altm__Commercial_Alert__c iCommercialAlert : newList) {
      if(mapOwnerAlerts.containsKey(iCommercialAlert.OwnerId)) {
        final List<altm__Commercial_Alert__c> listAux = mapOwnerAlerts.get(iCommercialAlert.OwnerId);
        listAux.add(iCommercialAlert);
        mapOwnerAlerts.put(iCommercialAlert.OwnerId, listAux);
      } else {
        mapOwnerAlerts.put(iCommercialAlert.OwnerId, new List<altm__Commercial_Alert__c> {iCommercialAlert});
      }
    }

    for(User iUser : [SELECT Id,
                        FederationIdentifier
                      FROM User
                      WHERE Id IN :mapOwnerAlerts.keySet()]) {
      for(altm__Commercial_Alert__c iCommercialAlert : mapOwnerAlerts.get(iUser.Id)) {
        iCommercialAlert.gf_alert_owner_user_origl_id__c = iUser.FederationIdentifier;
          if(iCommercialAlert.altm__owner_access_alert_id__c == null){
          iCommercialAlert.altm__owner_access_alert_id__c = iUser.FederationIdentifier;
        }
        if(iCommercialAlert.altm__commercial_alert_id__c == null){
          iCommercialAlert.altm__commercial_alert_id__c = 'CES-'+iUser.FederationIdentifier+'-'+String.valueOf(Datetime.now());
        }
      }
    }
  }

  /**
  * @author Global Desktop
  * @Description stCampaignIdOnInsert
  */
  public static void stCampaignIdOnInsert(List<altm__Commercial_Alert__c> newList) {
    final Map<String, Id> mapTypeCampaignId = new Map<String, Id>();
    for(Campaign iCampaign : [SELECT Id,
                                Type
                              FROM Campaign
                              WHERE RecordTypeId = :Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get(COMALERTRT).getRecordTypeId()]) {
      mapTypeCampaignId.put(iCampaign.Type, iCampaign.Id);
    }

    for(altm__Commercial_Alert__c iCommercialAlert : newList) {
      iCommercialAlert.altm__campaign_id__c = mapTypeCampaignId.get(iCommercialAlert.altm__commercial_alert_task_type__c);
    }
  }

  /**
  * @author Global Desktop
  * @Description increaseNumberOfAlerts
  */
  public static void increaseNumberOfAlerts(List<altm__Commercial_Alert__c> newList) {
    final Map<Id, List<altm__Commercial_Alert__c>> mapCampaignAlert = new Map<Id, List<altm__Commercial_Alert__c>>();
    for(altm__Commercial_Alert__c iCommercialAlert : newList) {
      if(iCommercialAlert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_PENDING
        || iCommercialAlert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_MANAGED) {
        if(mapCampaignAlert.containsKey(iCommercialAlert.altm__campaign_id__c)) {
          final List<altm__Commercial_Alert__c> listAux = mapCampaignAlert.get(iCommercialAlert.altm__campaign_id__c);
          listAux.add(iCommercialAlert);
          mapCampaignAlert.put(iCommercialAlert.altm__campaign_id__c, listAux);
        } else {
          mapCampaignAlert.put(iCommercialAlert.altm__campaign_id__c, new List<altm__Commercial_Alert__c> {iCommercialAlert});
        }
      }
    }

    final List<Campaign> listCampaign = new List<Campaign>();
    for(Campaign iCampaign : [SELECT Id,
                                Type,
                                Number_of_alerts__c
                              FROM Campaign
                              WHERE RecordTypeId = :Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get(COMALERTRT).getRecordTypeId()
                                AND Id IN :mapCampaignAlert.keySet()]) {
      if(iCampaign.Number_of_alerts__c == null) {
        iCampaign.Number_of_alerts__c = mapCampaignAlert.get(iCampaign.Id).size();
      } else {
        iCampaign.Number_of_alerts__c += mapCampaignAlert.get(iCampaign.Id).size();
      }

      listCampaign.add(iCampaign);
    }

    if(!listCampaign.isEmpty()) {
      update listCampaign;
    }
  }

  /**
  * @author Global Desktop
  * @Description decreaseNumberOfAlerts
  */
  public static void decreaseNumberOfAlerts(List<altm__Commercial_Alert__c> oldList) {
    final Map<Id, List<altm__Commercial_Alert__c>> mapCampaignAlert = new Map<Id, List<altm__Commercial_Alert__c>>();
    for(altm__Commercial_Alert__c iCommercialAlert : oldList) {
      if(iCommercialAlert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_PENDING
        || iCommercialAlert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_MANAGED) {
        if(mapCampaignAlert.containsKey(iCommercialAlert.altm__campaign_id__c)) {
          final List<altm__Commercial_Alert__c> listAux = mapCampaignAlert.get(iCommercialAlert.altm__campaign_id__c);
          listAux.add(iCommercialAlert);
          mapCampaignAlert.put(iCommercialAlert.altm__campaign_id__c, listAux);
        } else {
          mapCampaignAlert.put(iCommercialAlert.altm__campaign_id__c, new List<altm__Commercial_Alert__c> {iCommercialAlert});
        }
      }
    }

    final List<Campaign> listCampaign = new List<Campaign>();
    for(Campaign iCampaign : [SELECT Id,
                                Type,
                                Number_of_alerts__c
                              FROM Campaign
                              WHERE RecordTypeId = :Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get(COMALERTRT).getRecordTypeId()
                                AND Id IN :mapCampaignAlert.keySet()]) {
      if(iCampaign.Number_of_alerts__c != null
        && iCampaign.Number_of_alerts__c >= mapCampaignAlert.get(iCampaign.Id).size()) {
        iCampaign.Number_of_alerts__c -= mapCampaignAlert.get(iCampaign.Id).size();
        listCampaign.add(iCampaign);
      }
    }

    if(!listCampaign.isEmpty()) {
      update listCampaign;
    }
  }

  /**
  * @author Global Desktop
  * @Description increaseAndDecreaseNumberOfAlerts
  */
  public static void increaseAndDecreaseNumberOfAlerts(Map<Id, altm__Commercial_Alert__c> newMap, Map<Id, altm__Commercial_Alert__c> oldMap) {
    final List<altm__Commercial_Alert__c> listNewCommAlerts = new List<altm__Commercial_Alert__c>();
    final List<altm__Commercial_Alert__c> listOldCommAlerts = new List<altm__Commercial_Alert__c>();
    for(altm__Commercial_Alert__c iCommercialAlert : newMap.values()) {
      if(newMap.get(iCommercialAlert.Id).altm__campaign_id__c != null
          && newMap.get(iCommercialAlert.Id).altm__campaign_id__c != oldMap.get(iCommercialAlert.Id).altm__campaign_id__c) {
        listNewCommAlerts.add(iCommercialAlert);
        listOldCommAlerts.add(oldMap.get(iCommercialAlert.Id));
      }
    }

    if(!listNewCommAlerts.isEmpty()) {
      increaseNumberOfAlerts(listNewCommAlerts);
    }

    if(!listOldCommAlerts.isEmpty()) {
      decreaseNumberOfAlerts(listOldCommAlerts);
    }
  }

  /**
  * @author Global Desktop
  * @Description setCampaignIdOnUpdate
  */
  public static void setCampaignIdOnUpdate(Map<Id, altm__Commercial_Alert__c> newMap, Map<Id, altm__Commercial_Alert__c> oldMap) {
    final Map<String, Id> mapTypeCampaignId = new Map<String, Id>();
    for(Campaign iCampaign : [SELECT Id,
                                Type
                              FROM Campaign
                              WHERE RecordTypeId = :Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get(COMALERTRT).getRecordTypeId()]) {
      mapTypeCampaignId.put(iCampaign.Type, iCampaign.Id);
    }

    for(altm__Commercial_Alert__c iCommercialAlert : newMap.values()) {
      if(newMap.get(iCommercialAlert.Id).altm__commercial_alert_task_type__c != oldMap.get(iCommercialAlert.Id).altm__commercial_alert_task_type__c) {
        iCommercialAlert.altm__campaign_id__c = mapTypeCampaignId.get(iCommercialAlert.altm__commercial_alert_task_type__c);
      }
    }
  }

  /*
  * @author Global Desktop
  * @Description Method to add or delete members
  */
  public static void checkParticipantNotNull(List<altm__Commercial_Alert__c> newList) {
    final List<altm__Commercial_Alert__c> listCommAlertFail = new List<altm__Commercial_Alert__c>();
    for(altm__Commercial_Alert__c iCommercialAlert : newList) {
      if(iCommercialAlert.altm__participant_id__c == null) {
        listCommAlertFail.add(iCommercialAlert);
      }
    }

    for(altm__Commercial_Alert__c iCommercialAlert : listCommAlertFail) {
      if(iCommercialAlert.altm__participant_id__c == null) {
        iCommercialAlert.addError(Label.COMMERCIAL_ALERT_EMPTY_PARTICIPANT);
      }
    }
  }

  /**
  * @author Global Desktop
  * @Description Concatena el nombre de la alerta con el del id del cliente
  */
  public static void stNameOnInsert(List<altm__Commercial_Alert__c> newList) {
    if(profileName == Label.DES_ADMIN_PROFILE || profileName == Label.DES_INTEGRATION_PROFILE) {
      final Set<Id> setAccountId = new Set<Id>();
      for(altm__Commercial_Alert__c iCommercialAlert : newList) {
        if(iCommercialAlert.altm__participant_id__c != null) {
          setAccountId.add(iCommercialAlert.altm__participant_id__c);
        }
      }

      final Map<Id, Account> mapAccountId = new Map<Id, Account>([SELECT Id,
                                                                    g_customer_id__c
                                                                  FROM Account
                                                                  WHERE Id IN :setAccountId]);

      for(altm__Commercial_Alert__c iCommercialAlert : newList) {
        if(iCommercialAlert.altm__participant_id__c != null
          && mapAccountId.get(iCommercialAlert.altm__participant_id__c).g_customer_id__c != null) {
          iCommercialAlert.Name = iCommercialAlert.Name + '_' + mapAccountId.get(iCommercialAlert.altm__participant_id__c).g_customer_id__c;
        }
      }
    }
  }

  /**
  * Method to concatenate Client code in update
  */
  public static void setNameOnUpdate(Map<Id, altm__Commercial_Alert__c> newMap, Map<Id, altm__Commercial_Alert__c> oldMap) {
    final Map <Id, altm__Commercial_Alert__c> mapAlerts = new Map <Id, altm__Commercial_Alert__c>([SELECT Id, //NOSONAR
                                                                                                    altm__participant_id__c,
                                                                                                    altm__participant_id__r.g_customer_id__c
                                                                                                  FROM altm__Commercial_Alert__c
                                                                                                  WHERE Id IN :newMap.values()]);

    for(altm__Commercial_Alert__c iCommercialAlert : newMap.values()) {
      if(USERNAME != AUTOMATED_PR && (PROFILENAME == Label.DES_ADMIN_PROFILE || PROFILENAME == Label.DES_INTEGRATION_PROFILE)
        && (oldMap.get(iCommercialAlert.Id).altm__participant_id__c != iCommercialAlert.altm__participant_id__c
          || oldMap.get(iCommercialAlert.Id).altm__participant_id__r.g_customer_id__c != iCommercialAlert.altm__participant_id__r.g_customer_id__c
          || oldMap.get(iCommercialAlert.Id).Name != iCommercialAlert.Name)) {
        iCommercialAlert.Name = iCommercialAlert.Name + '_' + mapAlerts.get(iCommercialAlert.Id).altm__participant_id__r.g_customer_id__c;
      }
    }
  }

  /*
  * @author Global Desktop
  * @Description Method to create Member for alert
  */
  private static ctcp__Custom_Team__c createMember(Id alertId, Id ownerId, boolean fromGroup) {
    final ctcp__Custom_Team__c member = new ctcp__Custom_Team__c();
    member.ctcp__gf_team_users_desc__c = ownerId;
    member.ctcp__Object_Name__c = 'altm__Commercial_Alert__c';
    member.commercial_alert_id__c = alertId;
    member.OwnerId = ownerId;
    member.DES_From_Group__c = fromGroup;
    member.RecordTypeId = Schema.SObjectType.ctcp__Custom_Team__c.getRecordTypeInfosByDeveloperName().get(COMALERTRT).getRecordTypeId();
    return member;
  }

  /*
  * @author Global Desktop
  * @Description Method to add or delete members
  */
  private static void checkListMember(List<ctcp__Custom_Team__c> members, Boolean isInsert) {
    if(!members.isEmpty() && isInsert == true) {
      insert members;
    } else if(!members.isEmpty() && isInsert == false) {
      delete members;
    }
  }

  /**
  Comparte las alertas que lleguen a un miembro de un Public Group del proyecto con todos los miembros del grupo
  */
  public static void shareEsgKpiLinkedAlerts(List<altm__Commercial_Alert__c> kpiAlerts) {
    final Map<Id, List<Id>> userToGroups = new Map<Id, List<Id>>();

    for (GroupMember m : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE Group.DeveloperName IN ('ESG_KPI_Alerts_Originacion', 'ESG_KPI_Alerts_Monitoring') WITH USER_MODE]) {
      if (!userToGroups.containsKey(m.UserOrGroupId)) {
        userToGroups.put(m.UserOrGroupId, new List<Id>{m.GroupId});
      } else {
        userToGroups.get(m.UserOrGroupId).add(m.GroupId);
      }
    }

    final List<altm__Commercial_Alert__Share> toInsert = new List<altm__Commercial_Alert__Share>();

    for (altm__Commercial_Alert__c alert : kpiAlerts) {
      if (userToGroups.containsKey(alert.OwnerId)) {
        for (Id groupId : userToGroups.get(alert.OwnerId)) {
          toInsert.add(new altm__Commercial_Alert__Share(
            ParentId = alert.Id,
            UserOrGroupId = groupId,
            AccessLevel = 'Edit'
          ));
        }
      }
    }

    Database.insert(toInsert, false, AccessLevel.USER_MODE);
  }
  /**
  * @author Manuel Canellas
  * @Description updateReviewedToolkitAlert
  */
  public static void updateReviewedToolkitAlert(Map<Id, altm__Commercial_Alert__c> newMap, Map<Id, altm__Commercial_Alert__c> oldMap) {
    final String rtIdToolkitAlert = [SELECT Id FROM RecordType WHERE DeveloperName =: Label.COMMERCIAL_ALERT_TOOLKIT_RT_NAME AND SobjectType = 'altm__Commercial_Alert__c'][0]?.Id;
    for(altm__Commercial_Alert__c iCommercialAlert : newMap.values()) {
      if(iCommercialAlert.RecordTypeId == rtIdToolkitAlert
        && oldMap.get(iCommercialAlert.Id)?.altm__alert_stage_type__c != Label.COMMERCIAL_ALERT_STATUS_REVIEWED
        && newMap.get(iCommercialAlert.Id)?.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_REVIEWED) {
          newMap.get(iCommercialAlert.Id).cstk__ReviewedBy__c = UserInfo.getUserId();
          newMap.get(iCommercialAlert.Id).cstk__Reviewed_date__c = Date.today();
      }
    }
  }
}