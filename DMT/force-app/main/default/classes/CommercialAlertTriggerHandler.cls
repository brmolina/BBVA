/**********************************************************************************
* @author       Global Desktop
* @date         24/01/2019
* @description  Handler de alertas
* @Revision
**********************************************************************************/
Global with sharing class CommercialAlertTriggerHandler {

  //mapa para guardar usuarios
  global static Map<Id, User> mapUsers = new Map<Id, User>();
  //mapa para guardar cuentas
  global static Map<Id, Account> mapAccounts = new Map<Id, Account>();
  //mapa para guardar la prioridad de notificaciones de los usuarios
  global static Map<String, Boolean> mapUserPriority = new Map<String, Boolean>();
  //mapa para guardar las notificaciones agrupadas por cliente
  global static Map<Id,Map<Id,Integer> > mapUserAgrupado = new Map<Id,Map<Id,Integer> >();
  //mapa para guardar los miembros de cuenta
  global static Map<Id, String> mapClientMembers = new Map<Id, String>();
  //Set de ID's de los usuarios que tendrán 1 ÚNICA notificacion general.
  global static Set<Id> setIdsUsersNotifGeneral = new Set<Id>();
  //mapa para guardar la matriz de grupo ppal-matriz
  private static Map<Id, Id> mapGroupSubsidiary = new Map<Id, Id>();
  //lista para guardar los __Share de alertas a borrar
  public static List<almd__Commercial_Alert__Share> listComAlertShareToDelete = new List<almd__Commercial_Alert__Share>();
  //set para guardar los __Share de alertas a borrar
  public static Set<Id> setComAlertShareToDelete = new Set<Id>();
  //string para guardar el perfil del current user
  final static String profileName = [SELECT Name FROM Profile WHERE Id = :userInfo.getProfileId() LIMIT 1].Name;
  //mapa para guardar las alertas a notificar
  public static Map<Id, almd__Commercial_Alert__c> alertsToNotifyMap = new Map<Id, almd__Commercial_Alert__c>();

  /*
   * @author Global Desktop
   * @Description Establece el record type de la alerta en función de su familia de producto y si tiene o no autorizadores de ganado o descarte
   */
  public static void setRecordType(List<almd__Commercial_Alert__c> triggerNew) {
    for(almd__Commercial_Alert__c comAlert : triggerNew) {

      if ( comAlert.almd__reject_authorizer_user_id__c == null && comAlert.almd__closed_won_authorizer_user_id__c == null
           && comAlert.almd__alert_sub_stage_type__c != 'Discarded') {

        if(comAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GCC)
          comAlert.recordTypeId = Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_GCC_NO_AUTH).getRecordTypeId();
        else if(comAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_IBF)
          comAlert.recordTypeId = Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_IBF_NO_AUTH).getRecordTypeId();
        else if(comAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GM)
          comAlert.recordTypeId = Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_GM_NO_AUTH).getRecordTypeId();
        else if(comAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GTB)
          comAlert.recordTypeId = Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_GTB_NO_AUTH).getRecordTypeId();
        else if(comAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_FX) {
          comAlert.recordTypeId = Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_FX_NO_AUTH).getRecordTypeId();
        } else if(comAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_NOTIFICATION)
          comAlert.recordTypeId = Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_NOTIFICATION).getRecordTypeId();

      } else if(comAlert.almd__alert_sub_stage_type__c != 'Discarded') {

        if(comAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GCC)
          comAlert.recordTypeId = Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_GCC).getRecordTypeId();
        else if(comAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_IBF)
          comAlert.recordTypeId = Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_IBF).getRecordTypeId();
        else if(comAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GM)
          comAlert.recordTypeId = Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_GM).getRecordTypeId();
        else if(comAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GTB)
          comAlert.recordTypeId = Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_GTB).getRecordTypeId();
        else if(comAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_FX) {
          comAlert.recordTypeId = Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_COM_TASK_FX).getRecordTypeId();
        } else if(comAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_NOTIFICATION)
          comAlert.recordTypeId = Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.DES_RT_COMM_ALERT_NOTIFICATION).getRecordTypeId();
      }
    }
  }  //FIN setRecordTypeId

  /*
   * @author Global Desktop
   * @Description Control sobre oportunidades, visitas y success metrics al ganar o descartar una alerta
   */
  public static void checkClosedAlert(final Map<Id,almd__Commercial_Alert__c> oldMap, final Map<Id,almd__Commercial_Alert__c> newMap ) {


    List <Opportunity> openOpportunities = new List <Opportunity>([Select id,almd__commercial_alert_id__c from Opportunity where StageName != : label.DES_Closed_Won AND StageName != : label.DES_Closed_Lose AND almd__commercial_alert_id__c in: newMap.keySet()] );
    List <Opportunity> closedOpportunities = new List <Opportunity>([Select id, almd__commercial_alert_id__c, StageName from Opportunity where (StageName = : label.DES_Closed_Won OR StageName = : label.DES_Closed_Lose) AND almd__commercial_alert_id__c in: newMap.keySet()] );
    List <dwp_kitv__Visit__c> openVisits = new List <dwp_kitv__Visit__c>([Select id,almd__commercial_alert_id__c from dwp_kitv__Visit__c where dwp_kitv__visit_status_type__c != '05' AND almd__commercial_alert_id__c IN: newMap.keySet()]);
    List <dwp_kitv__Visit__c> closedVisits = new List <dwp_kitv__Visit__c>([Select id,almd__commercial_alert_id__c from dwp_kitv__Visit__c where dwp_kitv__visit_status_type__c = '05' AND almd__commercial_alert_id__c IN: newMap.keySet()]);

    Map <Id,boolean> mapAlertOpenOpp = new Map<Id,boolean>();
    Map <Id,boolean> mapAlertWonOpp = new Map<Id,boolean>();
    Map <Id,boolean> mapAlertLostOpp = new Map<Id,boolean>();
    Map <Id,boolean> mapAlertOpenVisit = new Map<Id,boolean>();
    Map <Id,boolean> mapAlertClosedVisit = new Map<Id,boolean>();


    for(Opportunity opp : openOpportunities) {
      mapAlertOpenOpp.put(opp.almd__commercial_alert_id__c,true);
    }
    for(Opportunity opp : closedOpportunities) {
      if(opp.StageName == label.DES_Closed_Won) {
        mapAlertWonOpp.put(opp.almd__commercial_alert_id__c,true);
      }
      else if(opp.StageName == label.DES_Closed_Lose) {
        mapAlertLostOpp.put(opp.almd__commercial_alert_id__c,true);
      }
    }

    for(dwp_kitv__Visit__c visit : openVisits) {
      mapAlertOpenVisit.put(visit.almd__commercial_alert_id__c,true);
    }

    for(dwp_kitv__Visit__c visit : closedVisits) {
      mapAlertClosedVisit.put(visit.almd__commercial_alert_id__c,true);
    }


    for(almd__Commercial_Alert__c ca : newMap.values()) {
      if (ca.almd__alert_sub_stage_type__c != 'Discarded') {
        if(!mapAlertClosedVisit.containsKey(ca.Id) && ca.almd__mandatory_visit_type__c == label.DES_YES
           && ((ca.almd__alert_stage_type__c == label.DES_CLOSED && ca.almd__alert_sub_stage_type__c == label.DES_Won) || (ca.almd__alert_stage_type__c == label.DES_PENDING_APPROVAL && ca.almd__alert_sub_stage_type__c == label.DES_TO_BE_CLOSED))) {
          ca.addError(label.DES_ERROR_ALERT_VISIT_REQUIRE);
        } else if(mapAlertOpenVisit.containsKey(ca.Id) && ((ca.almd__alert_stage_type__c == label.DES_CLOSED && ca.almd__alert_sub_stage_type__c == label.DES_Won) || (ca.almd__alert_stage_type__c == label.DES_PENDING_APPROVAL && ca.almd__alert_sub_stage_type__c == label.DES_TO_BE_CLOSED))) {
          ca.addError(label.DES_ERROR_ALERT_VISIT_NOT_CLOSED);
        }

        if(mapAlertOpenOpp.containsKey(ca.Id) && (ca.almd__alert_sub_stage_type__c == label.DES_Won || ca.almd__alert_sub_stage_type__c == label.DES_TO_BE_CLOSED)) {
          ca.addError(label.DES_ERROR_ALERT_OPPORTUNITY_NOT_CLOSED);
        } else if(mapAlertLostOpp.containsKey(ca.Id) && !mapAlertWonOpp.containsKey(ca.Id) && (ca.almd__alert_sub_stage_type__c == label.DES_Won || ca.almd__alert_sub_stage_type__c == label.DES_TO_BE_CLOSED)) {
          ca.addError(label.DES_NOT_WON_OPPORTUNITY);
        }

        if((mapAlertOpenOpp.containsKey(ca.Id) || mapAlertWonOpp.containsKey(ca.Id)) && (ca.almd__alert_sub_stage_type__c == label.DES_DISCARDED || ca.almd__alert_sub_stage_type__c == label.DES_TO_BE_DISCARDED)) {
          ca.addError(label.DES_ALL_LOST_OPPORTUNITIES);
        }

        //Si el estado ahora es Pending Approval y SubStage Won y antes no era Pending Approval
        if(((ca.almd__alert_stage_type__c == label.DES_PENDING_APPROVAL && ca.almd__alert_sub_stage_type__c == label.DES_TO_BE_CLOSED)
            || (ca.almd__alert_stage_type__c == label.DES_CLOSED && ca.almd__alert_sub_stage_type__c == label.DES_Won))
           &&(oldMap.get(ca.Id).almd__alert_stage_type__c != label.DES_PENDING_APPROVAL) ) {
          validateSuccessMetrics(ca);
        } if(!mapAlertClosedVisit.containsKey(ca.Id) && ca.almd__mandatory_visit_type__c == label.DES_YES
             && ((ca.almd__alert_stage_type__c == label.DES_CLOSED && ca.almd__alert_sub_stage_type__c == label.DES_Won) || (ca.almd__alert_stage_type__c == label.DES_PENDING_APPROVAL && ca.almd__alert_sub_stage_type__c == label.DES_TO_BE_CLOSED))) {
          ca.addError(label.DES_ERROR_ALERT_VISIT_REQUIRE);
        } else if(mapAlertOpenVisit.containsKey(ca.Id) && ((ca.almd__alert_stage_type__c == label.DES_CLOSED && ca.almd__alert_sub_stage_type__c == label.DES_Won) || (ca.almd__alert_stage_type__c == label.DES_PENDING_APPROVAL && ca.almd__alert_sub_stage_type__c == label.DES_TO_BE_CLOSED))) {
          ca.addError(label.DES_ERROR_ALERT_VISIT_NOT_CLOSED);
        }

        if(mapAlertOpenOpp.containsKey(ca.Id) && (ca.almd__alert_sub_stage_type__c == label.DES_Won || ca.almd__alert_sub_stage_type__c == label.DES_TO_BE_CLOSED)) {
          ca.addError(label.DES_ERROR_ALERT_OPPORTUNITY_NOT_CLOSED);
        } else if(mapAlertLostOpp.containsKey(ca.Id) && !mapAlertWonOpp.containsKey(ca.Id) && (ca.almd__alert_sub_stage_type__c == label.DES_Won || ca.almd__alert_sub_stage_type__c == label.DES_TO_BE_CLOSED)) {
          ca.addError(label.DES_NOT_WON_OPPORTUNITY);
        }

        if((mapAlertOpenOpp.containsKey(ca.Id) || mapAlertWonOpp.containsKey(ca.Id)) && (ca.almd__alert_sub_stage_type__c == label.DES_DISCARDED || ca.almd__alert_sub_stage_type__c == label.DES_TO_BE_DISCARDED)) {
          ca.addError(label.DES_ALL_LOST_OPPORTUNITIES);
        }

        //Si el estado ahora es Pending Approval y SubStage Won y antes no era Pending Approval
        if(((ca.almd__alert_stage_type__c == label.DES_PENDING_APPROVAL && ca.almd__alert_sub_stage_type__c == label.DES_TO_BE_CLOSED)
            || (ca.almd__alert_stage_type__c == label.DES_CLOSED && ca.almd__alert_sub_stage_type__c == label.DES_Won))
           &&(oldMap.get(ca.Id).almd__alert_stage_type__c != label.DES_PENDING_APPROVAL) ) {
          validateSuccessMetrics(ca);
        }
      }
    }
  }  // FIN closedAlerts

  /*
   * @author Global Desktop
   * @Description Control sobre success metrics al ganar o descartar una alerta
   */
  private static void validateSuccessMetrics(almd__Commercial_Alert__c comAlert) {
    system.debug('>>>>> comAlert.execution_indicator_type__c : ' + comAlert.almd__execution_indicator_type__c);
    if(comAlert.almd__execution_indicator_type__c == null) {
      comAlert.addError(Label.DES_ERROR_SUCCESS_METRICS);
    }
  }

  public static Map<Id, almd__Commercial_Alert__c> filtrarDescartadas(List<almd__Commercial_Alert__c> triggerNew) {
    Map<Id, almd__Commercial_Alert__c> alertMap;
    alertMap = new Map<Id, almd__Commercial_Alert__c>();
    for(almd__Commercial_Alert__c commAlert : triggerNew) {
      if (commAlert.almd__alert_sub_stage_type__c != 'Discarded') {
        alertMap.put(commAlert.Id, commAlert);
      }
    }
    return alertMap;
  }

  /*
   * @author Global Desktop
   * @Description Funcion que guarda en un mapa los usuarios con sus campos necesarios
     y que devuelve un mapa el usuario con su nivel de prioridad marcada en check
   */
  global static Map<String, Boolean> userPriorityInfo(List<almd__Commercial_Alert__c> triggerNew) {
    Set<Id> setIdsUsers = new Set<Id>();
    for(almd__Commercial_Alert__c commAlert : triggerNew) {
      //SI NO VIENE EL GESTOR, QUE SE VAYA AL CLIENTE Y NOTIFIQUE A LOS MIEMBROS DE LA CUENTA DE ESE CLIENTE RELACIONADO
      if(commAlert.almd__User_id__c == null) {
        //Si no tiene product specialist, hay que notificar al equipo de cuenta
        if(mapClientMembers.get(commAlert.almd__participant_id__c) != null) {
          List<String> idsUsers = mapClientMembers.get(commAlert.almd__participant_id__c).split(';');
          setIdsUsers.add(UserInfo.getUserId());
          for(String us : idsUsers) {
            if(!setIdsUsers.contains((Id)us)) {
              setIdsUsers.add((Id)us);              //LO AGREGO PARA LAS PRIORIDADES
            }
          }
        }
        for(Id idGrupo : mapGroupSubsidiary.values()) {
          if(mapClientMembers.get(idGrupo) != null) {
            List<String> idsUsers = mapClientMembers.get(idGrupo).split(';');
            System.debug('idsUsers: ' +idsUsers);
            for(String us : idsUsers) {
              if(!setIdsUsers.contains((Id)us))
                setIdsUsers.add((Id)us);                //LO AGREGO PARA LAS PRIORIDADES
            }
          }
        }
      }

      //User_id__c
      if(!setIdsUsers.contains(commAlert.almd__User_id__c) && commAlert.almd__User_id__c!=null) {
        setIdsUsers.add(commAlert.almd__User_id__c);
      }
      System.debug('setIdsUsers: '+setIdsUsers);


      //OwnerId
      if(!setIdsUsers.contains(commAlert.OwnerId)) {
        setIdsUsers.add(commAlert.OwnerId);
      }
      System.debug('setIdsUsers: '+setIdsUsers);

    }

    //current user lo guardo siempre
    if(!setIdsUsers.contains(UserInfo.getUserId())) {
      setIdsUsers.add(UserInfo.getUserId());
    }

    System.debug('setIdsUsers: '+setIdsUsers);

    //Map<String, Boolean> mapUserPriority = new Map<String, Boolean>();
    mapUsers = new Map<Id, User>([SELECT Id, Name, DES_Disable_Chatter__c, almd__alert_notification_type__c, almd__notification_priority_high_type__c,
                                  almd__notification_priority_med_type__c, almd__notification_priority_low_type__c FROM User WHERE Id IN: setIdsUsers]);
    system.debug('>>>>> mapUsers : ' + mapUsers);
    for(User us : mapUsers.values()) {
      mapUserPriority.put(us.Id + Label.almd.Priority_High, us.almd__notification_priority_high_type__c);
      mapUserPriority.put(us.Id + Label.almd.Priority_Medium, us.almd__notification_priority_med_type__c);
      mapUserPriority.put(us.Id + Label.almd.Priority_Low, us.almd__notification_priority_low_type__c);
    }
    return mapUserPriority;
  }

  /*
   * @author Global Desktop
   * @Description Funcion que devuelve un set con los ids del cliente directo de la alerta y su padre principal
   */
  global static Set<Id> getSetIdCuentas(List<almd__Commercial_Alert__c> triggerNew) {
    Set<Id> setIdsCuentas = new Set<Id>();
    for(almd__Commercial_Alert__c cAlert : triggerNew) {
      if(!setIdsCuentas.contains(cAlert.almd__participant_id__c)) {
        setIdsCuentas.add(cAlert.almd__participant_id__c);
      }
    }
    System.debug('@@setIdsCuentas' + setIdsCuentas);
    // recojo las matrix en las que las alertas son hijos
    List<DES_Subsidiary_Group_Relation__c> matrixAccountsList = new List<DES_Subsidiary_Group_Relation__c> ([
      SELECT Id, participant_parent_id__c,participant_child_id__c FROM DES_Subsidiary_Group_Relation__c WHERE participant_child_id__c IN: setIdsCuentas AND main_subsidiary_ind_type__c = true
    ]);
    // guardo los padres en el set que ya tengo
    for (DES_Subsidiary_Group_Relation__c idAux : matrixAccountsList) {
      setIdsCuentas.add(idAux.participant_parent_id__c);
      mapGroupSubsidiary.put(idAux.participant_child_id__c, idAux.participant_parent_id__c);
      System.debug('mapGroupSubsidiary ' + mapGroupSubsidiary);
    }
    system.debug('>>>>> setIdsCuentas : ' + setIdsCuentas);
    return setIdsCuentas;
  }

  /*
   * @author Global Desktop
   * @Description Funcion que obtiene los miembros de cuenta de un set de cuentas
   */
  global static Map<Id, AccountTeamMember> getMapAccountMembers(Set<Id> setIdsCuentas) {
    return new Map<Id, AccountTeamMember>([
                                            SELECT Id,
                                            UserId,
                                            AccountId
                                            FROM AccountTeamMember
                                            WHERE AccountId IN: setIdsCuentas AND User.DES_Disable_Chatter__c = false]);
  }

  /*
   * @author Global Desktop
   * @Description Genero el mapa con los clientes y sus miembros de cuentas concatenados en el value
   */
  global static void setMapClientMembers(Map<Id, AccountTeamMember> mapEquiposCuenta) {
    for(AccountTeamMember bbvaMT : mapEquiposCuenta.values()) {
      if(mapClientMembers.get(bbvaMT.AccountId) != null) {      //Si el mapa contiene el cliente

        //Concateno en un string los id's de los usuarios que son miembros de las cuentas
        system.debug('>>>>> mapClientMembers.get(bbvaMT.AccountId): ' + mapClientMembers.get(bbvaMT.AccountId));
        String concat = mapClientMembers.get(bbvaMT.AccountId);
        if(!concat.contains(bbvaMT.UserId)) {
          concat += ';' + bbvaMT.UserId;
        }
        mapClientMembers.put(bbvaMT.AccountId, concat);
      } else {
        mapClientMembers.put(bbvaMT.AccountId, (String)bbvaMT.UserId);
      }
      system.debug('>>>>> mapClientMembers.get(bbvaMT.AccountId): ' + mapClientMembers.get(bbvaMT.AccountId));
    }
  }


  /*
   * @author Global Desktop
   * @Description Funcion que genera el mensaje de notificaciones individuales
   */
  global static String getIndividualMessage(String text, almd__Commercial_Alert__c comAlert) {
    String formMessage = text;
    if(formMessage.contains('%alertType%')) {
      formMessage = formMessage.replaceAll('%alertType%', comAlert.almd__commercial_alert_task_type__c);
    }

    if(formMessage.contains('%clientName%')) {
      formMessage = formMessage.replaceAll('%clientName%', mapAccounts.get(comAlert.almd__participant_id__c).Name);
    }

    if(formMessage.contains('%notiName%')) {
      formMessage = formMessage.replaceAll('%notiName%', comAlert.Name);
    }

    system.debug('>>>>> formMessage : ' + formMessage);
    return formMessage;
  }

  /*
   * @author Global Desktop
   * @Description Funcion que genera notificaciones individuales
   */
  global static void notificacionIndividual(almd__Commercial_Alert__c comAlert, Id userId) {
    system.debug('>>>>> comAlert.Priority_Alert_Type__c : ' + comAlert.almd__Priority_Alert_Type__c);
    system.debug('>>>>> mapUserPriority.get(userId + comAlert.Priority_Alert_Type__c) : ' + mapUserPriority.get(userId + comAlert.almd__Priority_Alert_Type__c));
    //Notifico al usuario que va por el parametro userId
    if(comAlert.almd__Priority_Alert_Type__c != null
       && mapUserPriority.get(userId + comAlert.almd__Priority_Alert_Type__c) && comAlert.RecordTypeId != Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.almd.RT_COMM_ALERT_NOTIFICATION).getRecordTypeId()) {
      generarPostChatter(comAlert, userId, getIndividualMessage(Label.DES_MESSAGE_COMM_ALERT_NOTIF, comAlert));       //DEFINIR MENSAJE
    }
    else if(comAlert.almd__Priority_Alert_Type__c != null
            && mapUserPriority.get(userId + comAlert.almd__Priority_Alert_Type__c) && comAlert.RecordTypeId == Schema.SObjectType.almd__Commercial_Alert__c.getRecordTypeInfosByName().get(Label.almd.RT_COMM_ALERT_NOTIFICATION).getRecordTypeId()) {
      generarPostChatter(comAlert, userId, getIndividualMessage(Label.almd.MESSAGE_NOTIFICATION, comAlert));       //DEFINIR MENSAJE
    }
  }  //FIN notificacionIndividual


  /*
   * @author Global Desktop
   * @Description Funcion que genera el post de chatter para las notificaciones de alertas
   */
  global static void generarPostChatter(almd__Commercial_Alert__c commAlert, Id idUser, String textNotification) {
    System.debug('commAler: ' + commAlert);
    System.debug('idUser: ' + idUser);
    System.debug('textNotification: ' + textNotification);
    ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
    messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
    ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
    mentionSegment.id = idUser;     // The ID of the user to mention.
    messageInput.messageSegments.add(mentionSegment);
    ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = ' ' + textNotification;
    messageInput.messageSegments.add(textSegment);
    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = '.';
    messageInput.messageSegments.add(textSegment);
    ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
    input.body = messageInput;
    if(commAlert != null) {
      input.subjectId = commAlert.id;
    }
    else {
      input.subjectId = idUser;
    }
    ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);
    Desktop_Utils.batchFeedItemInputs.add(batchInput);
    System.debug('Desktop_Utils.batchFeedItemInputs.size(): ' + Desktop_Utils.batchFeedItemInputs.size());
    if(Desktop_Utils.batchFeedItemInputs.size() == 500 || test.isRunningTest()) {
      ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils.batchFeedItemInputs);
      Desktop_Utils.batchFeedItemInputs = new List<ConnectApi.BatchInput>();
      system.debug('>>>>> Desktop_Utils.batchFeedItemInputs FORMATEADO : ' + Desktop_Utils.batchFeedItemInputs);
    }
  }

  /*
   * @author Global Desktop
   * @Description Obtiene las cuentas de un set de ids de cuentas
   */
  global static void getMapaAccounts(Set<Id> setIdsCuentas) {
    if(mapAccounts.isEmpty()) {
      mapAccounts = new Map<Id, Account>([
                                           SELECT Id,
                                           Name
                                           FROM Account
                                           WHERE Id IN: setIdsCuentas
                                         ]);
    }
  }

  /*
   * @author Global Desktop
   * @Description Comparticion de alertas con el banker, owner y autorizadores de la alerta
   */
  public static void createManualSharing(List<almd__Commercial_Alert__c> triggerNew, Map<Id, almd__Commercial_Alert__c> triggerOldMap) {
    final Desktop_Utils handlerDesktopUtils = Desktop_Utils.getInstance();

    //Lista de sharing objets para compartirlos manualmente
    List<almd__Commercial_Alert__Share> listComAlertShare = new List<almd__Commercial_Alert__Share>();

    //Set<Id> setComAlertShareToDelete = new Set<Id>();
    Set<Id> setAccountIds = new Set<Id>();

    //Mapa con el Id de la cuenta como key y un string que concatena los Id's de los miembros de dicha cuenta
    Map<Id, String> mapAccountIdMembersId = new Map<Id, String>();

    //Boolean thereIsUpdate = false;
    for(almd__Commercial_Alert__c comAlert : triggerNew) {
      System.debug('comAlert.OwnerId: ' + comAlert.OwnerId);

      //Guardo en un set los id's de los clientes
      if(!setAccountIds.contains(comAlert.almd__participant_id__c)) {
        setAccountIds.add(comAlert.almd__participant_id__c);
      }

      //Si es Insert
      if(triggerOldMap == null) {
        if(comAlert.OwnerId != null ) {
          listComAlertShare.add(handlerDesktopUtils.newManualSharingCommercialAlert(comAlert.Id, comAlert.OwnerId,'Edit'));
        }
        if(comAlert.almd__User_id__c != null) {
          listComAlertShare.add(handlerDesktopUtils.newManualSharingCommercialAlert(comAlert.Id, comAlert.almd__User_id__c,'Edit'));
        }
        if(comAlert.almd__closed_won_authorizer_user_id__c != null) {
          listComAlertShare.add(handlerDesktopUtils.newManualSharingCommercialAlert(comAlert.Id, comAlert.almd__closed_won_authorizer_user_id__c,'Edit'));
        }
        if(comAlert.almd__reject_authorizer_user_id__c != null) {
          listComAlertShare.add(handlerDesktopUtils.newManualSharingCommercialAlert(comAlert.Id, comAlert.almd__reject_authorizer_user_id__c,'Edit'));
        }

        //Si es Update
      } else {
        if(comAlert.OwnerId != null  && triggerOldMap.get(comAlert.Id) != null
           && comAlert.OwnerId != triggerOldMap.get(comAlert.Id).OwnerId) {
          listComAlertShare.add(handlerDesktopUtils.newManualSharingCommercialAlert(comAlert.Id, comAlert.OwnerId,'Edit'));

          system.debug('createManualSharing - comAlert.OwnerId: ' + comAlert.OwnerId);
          system.debug('createManualSharing - triggerOldMap.get(comAlert.Id): ' + triggerOldMap.get(comAlert.Id));
        }
        if(comAlert.almd__User_id__c != null  && triggerOldMap.get(comAlert.Id) != null
           && comAlert.almd__User_id__c != triggerOldMap.get(comAlert.Id).almd__User_id__c) {
          listComAlertShare.add(handlerDesktopUtils.newManualSharingCommercialAlert(comAlert.Id, comAlert.almd__User_id__c,'Edit'));

        }
      }
    }    //FIN FOR

    //BUSCO LOS GRUPOS VINCULADOS A ESTAS CUENTAS
    Map<Id, Id> mapClientGroup = handlerDesktopUtils.getMapClientGroup(setAccountIds);

    //GENERO EL MAPA QUE NECESITO CON ID DE LA CUENTA Y LOS MIEMBROS DE LA CUENTA
    for(DES_BBVA_Management_Team__c bbvaMT : [SELECT Id, DES_Client__c, DES_User__c FROM DES_BBVA_Management_Team__c WHERE DES_Client__c IN :setAccountIds OR DES_Client__c IN :mapClientGroup.values()]) {
      if(mapAccountIdMembersId.get(bbvaMT.DES_Client__c) != null) {      //Si el mapa contiene el cliente
        //Concateno en un string los id's de los usuarios que son miembros de las cuentas
        String concat = mapAccountIdMembersId.get(bbvaMT.DES_Client__c);
        if(!concat.contains(bbvaMT.DES_User__c))
          concat += ';' + bbvaMT.DES_User__c;
        mapAccountIdMembersId.put(bbvaMT.DES_Client__c, concat);
      } else {
        mapAccountIdMembersId.put(bbvaMT.DES_Client__c, (String)bbvaMT.DES_User__c);
      }
      if(setComAlertShareToDelete.contains(bbvaMT.DES_User__c)) {
        setComAlertShareToDelete.remove(bbvaMT.DES_User__c);
      }
    }

    //RECORRO EL TRIGGER NEW DE ALERTAS PARA DAR A CADA USUARIO MIEMBRO DE LA CUENTA PERMISOS DE EDICION
    for(almd__Commercial_Alert__c comAlert : triggerNew) {

      //CLIENTE DIRECTO
      if(mapAccountIdMembersId.get(comAlert.almd__participant_id__c) != null
         && mapAccountIdMembersId.get(comAlert.almd__participant_id__c).contains(';')) {
        List<String> listaUsers = mapAccountIdMembersId.get(comAlert.almd__participant_id__c).split(';');
        for(String userId : listaUsers) {
          system.debug('userId: ' + userId);
          listComAlertShare.add(handlerDesktopUtils.newManualSharingCommercialAlert(comAlert.Id, userId,'Edit'));
        }
      } else if(mapAccountIdMembersId.get(comAlert.almd__participant_id__c) != null) {
        system.debug(' mapAccountIdMembersId.get(comAlert.almd__participant_id__c): ' +  mapAccountIdMembersId.get(comAlert.almd__participant_id__c));
        listComAlertShare.add(handlerDesktopUtils.newManualSharingCommercialAlert(comAlert.Id, mapAccountIdMembersId.get(comAlert.almd__participant_id__c),'Edit'));
      }

      //GRUPO DEL CLIENTE DIRECTO
      if(mapAccountIdMembersId.get(mapClientGroup.get(comAlert.almd__participant_id__c)) != null
         && mapAccountIdMembersId.get(mapClientGroup.get(comAlert.almd__participant_id__c)).contains(';')) {
        List<String> listaUsers = mapAccountIdMembersId.get(mapClientGroup.get(comAlert.almd__participant_id__c)).split(';');
        for(String userId : listaUsers) {
          system.debug('userId: ' + userId);
          listComAlertShare.add(handlerDesktopUtils.newManualSharingCommercialAlert(comAlert.Id, userId,'Edit'));
        }
      } else if(mapAccountIdMembersId.get(mapClientGroup.get(comAlert.almd__participant_id__c)) != null) {
        system.debug('mapAccountIdMembersId.get(mapClientGroup.get(comAlert.almd__participant_id__c)): ' + mapAccountIdMembersId.get(mapClientGroup.get(comAlert.almd__participant_id__c)));
        listComAlertShare.add(handlerDesktopUtils.newManualSharingCommercialAlert(comAlert.Id, mapAccountIdMembersId.get(mapClientGroup.get(comAlert.almd__participant_id__c)),'Edit'));
      }
    }
    system.debug('>>>>> listComAlertShare : ' + listComAlertShare);
    List<almd__Commercial_Alert__Share> alertShareToInsertAux = CommercialAlertTriggerHandlerWihoutShare.insertCommAlertShare(listComAlertShare);

    // lista de almd__Commercial_Alert__Share a borrar
    if(!triggerNew.isEmpty()) {
      listComAlertShareToDelete = new List<almd__Commercial_Alert__Share>([
                                                                            SELECT Id
                                                                            FROM almd__Commercial_Alert__Share
                                                                            WHERE ParentId = : triggerNew.get(0).Id
                                                                                             AND UserOrGroupId IN: setComAlertShareToDelete
                                                                                             AND RowCause = 'Manual'
                                                                          ]);
    }
    system.debug('listComAlertShareToDelete: ' + listComAlertShareToDelete);
    //}
  }  //FIN createManualSharing

  /*
   * @author Global Desktop
   * @Description Comprueba si el owner o banker/PS ha cambiado
   */
  global static void afterUpdate(List<almd__Commercial_Alert__c> triggerNew, List<almd__Commercial_Alert__c> triggerOld, Map<Id, almd__Commercial_Alert__c> triggerNewMap, Map<Id, almd__Commercial_Alert__c> triggerOldMap) {
    system.debug('>>>>> AFTER UPDATE');

    //Busco los campos del usuario necesarios para las validaciones
    List<almd__Commercial_Alert__c> triggerAll = new List<almd__Commercial_Alert__c>();
    system.debug('>>>>> DENTRO DE  mapUserPriority.isEmpty() ');
    Map<String, Boolean> mapUserPriority = new Map<String, Boolean>();
    triggerAll.addAll(triggerNew);
    triggerAll.addAll(triggerOld);
    mapUserPriority = userPriorityInfo(triggerAll);
    system.debug('>>>>> mapUsers : ' + mapUsers);
    system.debug('>>>>> mapUserPriority : ' + mapUserPriority);

    //Set que tiene los id's de las cuentas de las alertas comerciales
    Set<Id> setIdsCuentas = new Set<Id>();
    for(almd__Commercial_Alert__c cAlert : triggerNew) {
      if(!setIdsCuentas.contains(cAlert.almd__participant_id__c)) {
        setIdsCuentas.add(cAlert.almd__participant_id__c);
      }
    }
    getMapaAccounts(setIdsCuentas);
    for(almd__Commercial_Alert__c comAlert : triggerNew) {
      notifyOwnerBankerChanged(comAlert, triggerNew, triggerOldMap);
    }
  }  //FIN AFTERUPDATE

  /*
   * @author Global Desktop
   * @Description Notifica al owner o banker/PS si ha cambiado de manera manual
   */
  public static void notifyOwnerBankerChanged(almd__Commercial_Alert__c comAlert, List<almd__Commercial_Alert__c> triggerNew, Map<Id, almd__Commercial_Alert__c> triggerOldMap) {
    system.debug('>>>>> comAlert: ' + comAlert);
    system.debug('>>>>> triggerOldMap.get(comAlert.Id): ' + triggerOldMap.get(comAlert.Id));
    system.debug('>>>>> mapUsers.get(UserInfo.getUserId()): ' + mapUsers.get(UserInfo.getUserId()));
    system.debug('>>>>> comAlert.OwnerId: ' + comAlert.OwnerId);
    system.debug('>>>>> triggerOldMap.get(comAlert.Id).OwnerId: ' + triggerOldMap.get(comAlert.Id).OwnerId);
    system.debug('>>>>> mapUsers.get(comAlert.OwnerId): ' + mapUsers.get(comAlert.OwnerId));

    // notifica al nuevo owner si ha cambiado
    if (comAlert.OwnerId != triggerOldMap.get(comAlert.Id).OwnerId
        && mapUsers.get(comAlert.OwnerId) != null && !mapUsers.get(comAlert.OwnerId).DES_Disable_Chatter__c
        && !mapUsers.get(UserInfo.getUserId()).DES_Disable_Chatter__c) {
      system.debug('>>>>> comAlert.OwnerId: ' + comAlert.OwnerId);
      if((profileName != Label.DES_ADMIN_PROFILE && profileName != Label.DES_INTEGRATION_PROFILE) || Test.isRunningTest()) {           //NOSONAR
        notificacionIndividual(comAlert, comAlert.OwnerId);
        ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils.batchFeedItemInputs);
      }
    }

    // notifica al nuevo banker si ha cambiado
    if(comAlert.almd__User_id__c != null) {
      // el anterior banker está vacío
      if(triggerOldMap.get(comAlert.Id).almd__User_id__c == null) {
        system.debug('>>>>> DISTINTO BANKER - NULL ');
        // el nuevo banker tiene chatter, el current user tiene chatter y no es admin ni desktop integrator
        if(mapUsers.get(comAlert.almd__User_id__c) != null && !mapUsers.get(comAlert.almd__User_id__c).DES_Disable_Chatter__c
           && mapUsers.get(UserInfo.getUserId()) != null && !mapUsers.get(UserInfo.getUserId()).DES_Disable_Chatter__c
           && profileName != Label.DES_ADMIN_PROFILE && profileName != Label.DES_INTEGRATION_PROFILE) {
          notificacionIndividual(comAlert, comAlert.almd__User_id__c);
          ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils.batchFeedItemInputs);
        }

        // el nuevo banker y el antiguo son distintos, el nuevo banker tiene chatter, el current user tiene chatter y no es admin ni desktop integrator
      } else if(comAlert.almd__User_id__c != triggerOldMap.get(comAlert.Id).almd__User_id__c
                && mapUsers.get(comAlert.almd__User_id__c) != null && !mapUsers.get(comAlert.almd__User_id__c).DES_Disable_Chatter__c
                && mapUsers.get(UserInfo.getUserId()) != null && !mapUsers.get(UserInfo.getUserId()).DES_Disable_Chatter__c
                && profileName != Label.DES_ADMIN_PROFILE && profileName != Label.DES_INTEGRATION_PROFILE) {
        system.debug('>>>>> DISTINTO BANKER ');
        notificacionIndividual(comAlert, comAlert.almd__User_id__c);
        ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils.batchFeedItemInputs);
      }
    }
    system.debug('alertsToNotifyMap: ' + alertsToNotifyMap);
  }

  /*
   * @author Global Desktop
   * @Description Comprueba si el owner existe y lo guarda en el campo estandar de owner
   */
  public static void setLookupUsers(List<almd__Commercial_Alert__c> triggerNew, Map<Id, almd__Commercial_Alert__c> triggerOldMap) {
    System.debug('entro en setLookupUsers');
    Set <String> idUsers = new Set <String>();
    List <User> users = new List <User>();
    Map <String,Id> mapIdUsers = new Map<String,Id>();
    if(profileName == Label.DES_ADMIN_PROFILE || profileName == Label.DES_INTEGRATION_PROFILE) {
      for(almd__Commercial_Alert__c commAlert : triggerNew) {
        if (commAlert.almd__alert_sub_stage_type__c != 'Discarded') {
          if(!idUsers.contains(commAlert.almd__owner_access_alert_id__c) && commAlert.almd__owner_access_alert_id__c != null) {
            idUsers.add(commAlert.almd__owner_access_alert_id__c);
          }
          if(!idUsers.contains(commAlert.sf_no_db_authorizer_user_id__c) && commAlert.sf_no_db_authorizer_user_id__c != null) {
            idUsers.add(commAlert.sf_no_db_authorizer_user_id__c);
          }
          if(!idUsers.contains(commAlert.sf_no_db_reject_user_id__c) && commAlert.sf_no_db_reject_user_id__c != null) {
            idUsers.add(commAlert.sf_no_db_reject_user_id__c);
          }
          if(!idUsers.contains(commAlert.sf_no_db_user_id__c) && commAlert.sf_no_db_user_id__c != null) {
            idUsers.add(commAlert.sf_no_db_user_id__c);
          }
          if(!idUsers.contains(commAlert.sf_no_db_monitor_manager_user_id__c) && commAlert.sf_no_db_monitor_manager_user_id__c != null) {
            idUsers.add(commAlert.sf_no_db_monitor_manager_user_id__c);
          }
          if(!idUsers.contains(commAlert.sf_no_db_ori_manager_user_id__c) && commAlert.sf_no_db_ori_manager_user_id__c != null) {
            idUsers.add(commAlert.sf_no_db_ori_manager_user_id__c);
          }
        }
      }
      system.debug('>>>>>> Users Set:   ' + idUsers);

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

      for(almd__Commercial_Alert__c commAlert : triggerNew) {
        if (commAlert.almd__alert_sub_stage_type__c != 'Discarded') {

          // Authorizer (Won)
          if (mapIdUsers.get(commAlert.sf_no_db_authorizer_user_id__c) == null) {
            commAlert.almd__closed_won_authorizer_user_id__c = null;
          } else {
            commAlert.almd__closed_won_authorizer_user_id__c = mapIdUsers.get(commAlert.sf_no_db_authorizer_user_id__c);
          }

          // Authorizer (Discarded)
          if (mapIdUsers.get(commAlert.sf_no_db_reject_user_id__c) == null) {
            commAlert.almd__reject_authorizer_user_id__c = null;
          } else {
            commAlert.almd__reject_authorizer_user_id__c = mapIdUsers.get(commAlert.sf_no_db_reject_user_id__c);
          }

          // Banker/Product Specialist
          if (mapIdUsers.get(commAlert.sf_no_db_user_id__c) == null) {
            commAlert.almd__User_id__c = null;
          } else {
            commAlert.almd__User_id__c = mapIdUsers.get(commAlert.sf_no_db_user_id__c);
          }

          // Monitoring manager
          if (mapIdUsers.get(commAlert.sf_no_db_monitor_manager_user_id__c) == null) {
            commAlert.almd__Monitor_manager_user_id__c = null;
          } else {
            commAlert.almd__Monitor_manager_user_id__c = mapIdUsers.get(commAlert.sf_no_db_monitor_manager_user_id__c);
          }

          // Origination manager
          if (mapIdUsers.get(commAlert.sf_no_db_ori_manager_user_id__c) == null) {
            commAlert.almd__Origination_manager_user_id__c = null;
          } else {
            commAlert.almd__Origination_manager_user_id__c = mapIdUsers.get(commAlert.sf_no_db_ori_manager_user_id__c);
          }
        }
      }
      setOwnerAndBankerPS(triggerNew, triggerOldMap, mapIdUsers);
    }
  }

  /*
	* @author Global Desktop
	* @Description Comprueba si el owner existe y lo guarda en el campo estandar de owner
	*/
	public static void setOwnerAndBankerPS(List<almd__Commercial_Alert__c> triggerNew, Map<Id, almd__Commercial_Alert__c> triggerOldMap, Map <String,Id> mapIdUsers) {
		System.debug('entro en setOwnerAndBankerPS');
    final Map<String, Regional_Product_Specialist__c> alertPSMap = getProductSpecialist(triggerNew);
    final Map<String, DES_BBVA_Management_team__c> mapAlertTB = getTransactionBanker(triggerNew);

    for(almd__Commercial_Alert__c commAlert : triggerNew) {
      system.debug('>>>>>> Old Owner:   ' + commAlert.OwnerId);

      // si el owner es inválido
      if (mapIdUsers.get(commAlert.almd__owner_access_alert_id__c) == null && commAlert.almd__alert_sub_stage_type__c != 'Discarded') {
        // si no hay PS en la matriz y RT != GTB o no hay PS ni TB y RT = GTB generamos el error
        if (alertPSMap.get(commAlert.almd__commercial_alert_id__c) == null
              && (commAlert.almd__commercial_alert_record_type__c != Label.DES_RT_COMM_ALERT_COM_TASK_GTB
              || (commAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GTB && mapAlertTB.get(commAlert.almd__commercial_alert_id__c) == null))) {
      //Desktop_Utils.invalidAlertsSet.add(commAlert.almd__commercial_alert_id__c);
          commAlert.addError(Label.DES_INVALID_OWNER);

      // si existe PS, ponemos en el owner el PS de la matriz
        } else if(alertPSMap.get(commAlert.almd__commercial_alert_id__c) != null) { //NOSONAR
            commAlert.OwnerId = alertPSMap.get(commAlert.almd__commercial_alert_id__c).DES_Product_Specialist__c;
            commAlert.almd__owner_access_alert_id__c = alertPSMap.get(commAlert.almd__commercial_alert_id__c).DES_Product_Specialist__r.ID_User__c;

            // si el banker/PS está vacío y hay matriz, pongo el de la matriz
            if (commAlert.almd__User_id__c == null && alertPSMap.get(commAlert.almd__commercial_alert_id__c) != null) {
              commAlert.almd__User_id__c = alertPSMap.get(commAlert.almd__commercial_alert_id__c).DES_Product_Specialist__c;
            }

              //Si el RT = GTB y no hay PS y hay TB en el grupo pongo el TB del grupo como owner
        } else if(commAlert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GTB
                      && alertPSMap.get(commAlert.almd__commercial_alert_id__c) == null
                      && mapAlertTB.get(commAlert.almd__commercial_alert_id__c) != null) {
          commAlert.OwnerId = mapAlertTB.get(commAlert.almd__commercial_alert_id__c).DES_User__c;
          commAlert.almd__owner_access_alert_id__c = mapAlertTB.get(commAlert.almd__commercial_alert_id__c).DES_User__r.ID_User__c;
        }

    // si el owner existe en Salesforce, lo guardamos en el lookup estandar
      } else if(commAlert.almd__alert_sub_stage_type__c != 'Discarded') {
        commAlert.OwnerId = mapIdUsers.get(commAlert.almd__owner_access_alert_id__c);
        // si el banker/PS está vacío y hay matriz, pongo el de la matriz
        if (commAlert.almd__User_id__c == null && alertPSMap.get(commAlert.almd__commercial_alert_id__c) != null) {
          commAlert.almd__User_id__c = alertPSMap.get(commAlert.almd__commercial_alert_id__c).DES_Product_Specialist__c;
        }
      }
        system.debug('>>>>>> New Owner:   ' + commAlert.OwnerId);
    }
  } // FIN setOwnerAndBankerPS

  /*
   * @author Global Desktop
   * @Description Busca en la matriz de PS
   */
  public static Map<String, Regional_Product_Specialist__c> getProductSpecialist(List<almd__Commercial_Alert__c> triggerNew) {
    System.debug('entro en getProductSpecialist');

    // buscamos los PS de la matriz
    Map<String, Regional_Product_Specialist__c> psMap = new Map<String, Regional_Product_Specialist__c>();
    List<Regional_Product_Specialist__c> psList= [SELECT Id, DES_Product__r.DES_External_ID__c, DES_Country__c, DES_Product_Specialist__c,DES_Product_Specialist__r.ID_User__c
                                                  FROM Regional_Product_Specialist__c
                                                  WHERE DES_Active_User__c = true];
    for (Regional_Product_Specialist__c productSpecialist : psList) {
      psMap.put(productSpecialist.DES_Product__r.DES_External_ID__c + '_' + productSpecialist.DES_Country__c, productSpecialist);
    }
    System.debug('psMap: ' + psMap);

    // emparejamos las alertas con su regional product specialist record
    Map<String, Regional_Product_Specialist__c> alertPSMap;
    alertPSMap = new Map<String, Regional_Product_Specialist__c>();
    for(almd__Commercial_Alert__c alert : triggerNew) {
      if(psMap.get(alert.almd__Transaction_type_desc__c + '_' + alert.almd__country_id__c) != null) {
        alertPSMap.put(alert.almd__commercial_alert_id__c, psMap.get(alert.almd__Transaction_type_desc__c + '_' + alert.almd__country_id__c));
      }
    }
    System.debug('alertPSMap: ' + alertPSMap);
    return alertPSMap;
  }

  /*
	* @author Global Desktop
	* @Description Busca el transaction banker del grupo
	*/
  public static Map<String, DES_BBVA_Management_team__c> getTransactionBanker(List<almd__Commercial_Alert__c> triggerNew) {
      final Set<String> groupsCodes = new Set <String>();
      final Map<String, String> mapAlertGroup = new Map<String, String>();

      final set<Id> relAccId = new set<Id>();
      for(almd__Commercial_Alert__c alert : triggerNew) {
          relAccId.add(alert.almd__participant_id__c);
          if(alert.business_group_id__c != null) {
              groupsCodes.add(alert.business_group_id__c);
          }
      }

      final Map <String, String> mapCodeAccount = fillMapCodesId(groupsCodes);

      final List<DES_Subsidiary_Group_Relation__c> relGroupList = new List<DES_Subsidiary_Group_Relation__c> ([SELECT participant_parent_id__c
                                                      FROM DES_Subsidiary_Group_Relation__c
                                                      WHERE participant_child_id__c  IN :relAccId AND main_subsidiary_ind_type__c = true]);
      final set<Id> groupIds = new set<Id>();
      for(DES_Subsidiary_Group_Relation__c matrix : relGroupList) {
          groupIds.add(matrix.participant_parent_id__c);
      }


      final Map<Id, DES_BBVA_Management_team__c> mapMembers = new Map <Id, DES_BBVA_Management_team__c>([
            SELECT Id, DES_User__c, DES_Client__c, DES_Member_Role__c, DES_Local_Banker_Country__c, DES_User__r.ID_User__c, CreatedDate
            FROM DES_BBVA_Management_team__c
            WHERE DES_Member_Role__c = :Label.DES_Role_Transactional_Banker AND DES_User__r.IsActive = true AND
            (DES_Client__c IN :groupIds OR DES_Client__c IN :mapCodeAccount.values())
            ORDER BY CreatedDate ASC
        ]);

      final Map <String, String> mapAccMembers = auxFillmapAccMembers(mapMembers);

      final Set <Id> setIdCuentas = getSetIdCuentas(triggerNew);

      system.debug('**setIdCuentasGrupos -> '+ setIdCuentas);

      for(almd__Commercial_Alert__c alert : triggerNew) {
          if(mapGroupSubsidiary.get(alert.almd__participant_id__c) != null) {
              mapAlertGroup.put(alert.almd__commercial_alert_id__c, mapGroupSubsidiary.get(alert.almd__participant_id__c));
          }
      }

      return fillMapTB(mapAlertGroup, mapAccMembers, triggerNew, mapCodeAccount, mapMembers);
  }


    /*
	* @author Global Desktop
	* @Description Completa el mapa del Transactional Banker
	*/
    private static Map<String, DES_BBVA_Management_team__c> fillMapTB(Map<String, String> mapAlertGroup, Map <String, String> mapAccMembers,
      List<almd__Commercial_Alert__c> triggerNew, Map <String, String> mapCodeAccount, Map<Id, DES_BBVA_Management_team__c> mapMembers) {

      final Map<String, DES_BBVA_Management_team__c> mapAlertTB = new Map<String, DES_BBVA_Management_team__c>();

      for(almd__Commercial_Alert__c alert : triggerNew) {
          List<String> members = new List<String>();
          if(alert.business_group_id__c != null && mapAccMembers.get(mapCodeAccount.get(alert.business_group_id__c)) != null) { //NOSONAR
              members = mapAccMembers.get(mapCodeAccount.get(alert.business_group_id__c)).split(';');
          } else if(mapAlertGroup.get(alert.almd__commercial_alert_id__c) != null && mapAccMembers.get(mapAlertGroup.get(alert.almd__commercial_alert_id__c)) != null) {
              members = mapAccMembers.get(mapAlertGroup.get(alert.almd__commercial_alert_id__c)).split(';');
          }
          for(String member : members) {
              if(mapMembers.containsKey(member) && mapMembers.get(member).DES_Local_Banker_Country__c == alert.almd__country_id__c) {
                  mapAlertTB.put(alert.almd__commercial_alert_id__c, mapMembers.get(member)); //Aquí se pisa el TB con el último si hay varios del mismo país
              }
          }
      }
      return mapAlertTB;
  }


    /*
	* @author Global Desktop
	* @Description Genera un mapa con el codigo del grupo y el id de salesforce
	*/
  private static Map<String, String> fillMapCodesId(Set<String> groupsCodes) {
      final Map <String, String> mapCodeAccount = new Map <String, String>();

      final List <Account> accounts = new List <Account> ([SELECT Id, DES_Group_Code__c FROM Account WHERE DES_Group_Code__c IN :groupsCodes]);
      for (Account acc : accounts) {
          mapCodeAccount.put(acc.DES_Group_Code__c, acc.Id);
      }

      return mapCodeAccount;
  }


  /*
   * @author Global Desktop
   * @Description Si el owner o banker/PS ha cambiado, se inserta un registro __Share para el antiguo
   */
  public static void checkOwnerBankerChange(List<almd__Commercial_Alert__c> triggerNew, Map<Id, almd__Commercial_Alert__c> triggerOldMap) {
    final Desktop_Utils handlerDesktopUtils = Desktop_Utils.getInstance();
    Set<Id> alertIds = new Set<Id>();
    Map<String, almd__Commercial_Alert__Share> alertShareIdMap = new Map<String, almd__Commercial_Alert__Share>();
    for(almd__Commercial_Alert__c alert : triggerNew) {
      if(alert.almd__alert_sub_stage_type__c != 'Discarded') {

        system.debug('>>>>> distinto de DISCARDED');
        // si el owner ha cambiado, inserto un registro __Share para el antiguo y preparo la lista que a futuro se borra
        if(alert.OwnerId != triggerOldMap.get(alert.Id).OwnerId) {
          Desktop_Utils.alertShareToInsert.add(handlerDesktopUtils.newManualSharingCommercialAlert(alert.Id, triggerOldMap.get(alert.Id).OwnerId,'Edit'));
          if(triggerOldMap.get(alert.Id).OwnerId != alert.almd__User_id__c && compareAuthorizersWithOwner(triggerOldMap.get(alert.Id))) {
            Desktop_Utils.alertShareToDelete.add(handlerDesktopUtils.newManualSharingCommercialAlert(alert.Id, triggerOldMap.get(alert.Id).OwnerId,'Edit'));
            alertShareIdMap.put(alert.Id + '_' + triggerOldMap.get(alert.Id).OwnerId,handlerDesktopUtils.newManualSharingCommercialAlert(alert.Id, triggerOldMap.get(alert.Id).OwnerId,'Edit'));
          }

        }

        // si el banker ha cambiado, inserto un registro __Share para el antiguo y preparo la lista que a futuro se borra
        if(alert.almd__User_id__c != triggerOldMap.get(alert.Id).almd__User_id__c
           && triggerOldMap.get(alert.Id).almd__User_id__c != alert.OwnerId && alert.almd__User_id__c != null) {
          Desktop_Utils.alertShareToInsert.add(handlerDesktopUtils.newManualSharingCommercialAlert(alert.Id, triggerOldMap.get(alert.Id).almd__User_id__c,'Edit'));
          system.debug('>>>aqui ');
          if(compareAuthorizersWithBanker(triggerOldMap.get(alert.Id))) {
            system.debug('DENTRO DE compareAuthorizersWithBanker(alert)');
            Desktop_Utils.alertShareToDelete.add(handlerDesktopUtils.newManualSharingCommercialAlert(alert.Id, triggerOldMap.get(alert.Id).almd__User_id__c,'Edit'));
            alertShareIdMap.put(alert.Id + '_' + triggerOldMap.get(alert.Id).almd__User_id__c,handlerDesktopUtils.newManualSharingCommercialAlert(alert.Id, triggerOldMap.get(alert.Id).almd__User_id__c,'Edit'));
          }
        }
        alertIds.add(alert.Id);
        system.debug('checkOwnerBankerChange - Desktop_Utils.alertShareToInsert: ' + Desktop_Utils.alertShareToInsert);
        system.debug('checkOwnerBankerChange - Desktop_Utils.alertShareToDelete: ' + Desktop_Utils.alertShareToDelete);
      }
    }
    List<almd__Commercial_Alert__Share> alertShareToInsertAux = CommercialAlertTriggerHandlerWihoutShare.insertCommAlertShare(Desktop_Utils.alertShareToInsert);
    for(almd__Commercial_Alert__Share alertShare : alertShareToInsertAux) {
      if(alertShareIdMap.get(alertShare.ParentId + '_' + alertShare.UserOrGroupId) != null) {
        almd__Commercial_Alert__Share cas = alertShareIdMap.get(alertShare.ParentId + '_' + alertShare.UserOrGroupId);
        cas.Id = alertShare.Id;
        alertShareIdMap.put(alertShare.ParentId + '_' + alertShare.UserOrGroupId, cas);
      }
    }
    Desktop_Utils.alertShareToDelete.clear();
    system.debug('>>>>> alertShareIdMap.values() : ' + alertShareIdMap.values());
    for(almd__Commercial_Alert__Share alertShare : alertShareIdMap.values()) {
      system.debug('>>>>> alertShare: ' + alertShare);
      Desktop_Utils.alertShareToDelete.add(alertShare);
    }
    system.debug('checkOwnerBankerChange - Desktop_Utils.alertShareToDelete: ' + Desktop_Utils.alertShareToDelete);
  }

  /*
	* @author Global Desktop
	* @Description Copia el valor de un lookup a cliente relleno en uno vacio
	*/
	public static void copyClient(almd__Commercial_Alert__c alert, Map<String, String> mapExtId) {
		if(alert.participant_name__c != null && mapExtId.get(alert.participant_name__c) != null) {
			alert.almd__participant_id__c = mapExtId.get(alert.participant_name__c);
    }
    if(alert.Client_STAR_ID__c != null && mapExtId.get(alert.Client_STAR_ID__c) != null) {
			alert.almd__participant_id__c = mapExtId.get(alert.Client_STAR_ID__c);
    }
	}

    /*
    * @author Global Desktop
    * @Description genera un mapa con la clave externa del cliente y el id de salesforce en función de la tipología de alerta
    */
    private static Map<String, String> generateMaps(List<almd__Commercial_Alert__c> triggerNew) {
      final Set <String> setParticName = new Set <String>();
      final Set <String> setClientStar = new Set <String>();

      for(almd__Commercial_Alert__c alert : triggerNew) {
        if(alert.participant_name__c != null && alert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GTB) {
          setParticName.add(alert.participant_name__c);
        }
        if(alert.Client_STAR_ID__c != null && alert.almd__commercial_alert_record_type__c == Label.DES_RT_COMM_ALERT_COM_TASK_GM) {
          setClientStar.add(alert.Client_STAR_ID__c);
        }
      }

      final List <Account> accountsIds = new List <Account>([
        SELECT Id, SER_CClient__c, Client_STAR_ID__c
        FROM Account
        WHERE SER_CClient__c IN :setParticName OR Client_STAR_ID__c IN :setClientStar
      ]);


      return fillmapExtId(accountsIds);

    }

    /*
	* @author Global Desktop
	* @Description Genera un mapa con el codigo del grupo y el id de salesforce
	*/
    private static Map<String, String> fillmapExtId(List <Account> accountsIds) {
      final Map<String, String> mapExtId = new Map <String, String>();

      for(Account acc : accountsIds) {
        if(acc.SER_CClient__c != null && mapExtId.get(acc.SER_CClient__c) == null) {
          mapExtId.put(acc.SER_CClient__c, acc.Id);
        }
        if(acc.Client_STAR_ID__c != null && mapExtId.get(acc.Client_STAR_ID__c) == null) {
          mapExtId.put(acc.Client_STAR_ID__c, acc.Id);
        }
      }

      return mapExtId;
    }

    /*
    * @author Global Desktop
    * @Description Concatena el BBVASA para las contrapartidas
    */
    public static void concatenateBBVASA (List<almd__Commercial_Alert__c> triggerNew) {
      for(almd__Commercial_Alert__c alert : triggerNew) {
        if(alert.Client_STAR_ID__c != null) {
          alert.Client_STAR_ID__c = alert.Client_STAR_ID__c + '-BBVASA';
        }
      }
    }

    /*
	* @author Global Desktop
	* @Description Concatena el nombre de la alerta con el del id del cliente
	*/
    public static void concatenateAlertName (List<almd__Commercial_Alert__c> triggerNew, Map<Id, almd__Commercial_Alert__c> triggerOldMap) {
        // solo en la carga
      if(profileName == Label.DES_ADMIN_PROFILE || profileName == Label.DES_INTEGRATION_PROFILE) {
        system.debug('triggerOldMap: ' + triggerOldMap);
        Set<Id> clientIdSet = new Set<Id>();
          final Map<String, String> mapExtId = generateMaps(triggerNew);
        for(almd__Commercial_Alert__c alert : triggerNew) {

          copyClient(alert, mapExtId);

          if(alert.almd__participant_id__c != null && !clientIdSet.contains(alert.almd__participant_id__c) && alert.almd__alert_sub_stage_type__c != 'Discarded') {
            clientIdSet.add(alert.almd__participant_id__c);
          }

          if(alert.almd__commercial_alert_record_type__c == LABEL.DES_RT_COMM_ALERT_COM_TASK_GM || alert.almd__commercial_alert_record_type__c == LABEL.DES_RT_COMM_ALERT_COM_TASK_GM_NO_AUTH ||
              alert.almd__commercial_alert_record_type__c == LABEL.DES_RT_COMM_ALERT_COM_TASK_GTB || alert.almd__commercial_alert_record_type__c == LABEL.DES_RT_COMM_ALERT_COM_TASK_GTB_NO_AUTH) {
            alert.almd__Transaction_type_desc__c = alert.almd__commercial_product_type__c;
          }

        }
        system.debug('clientIdSet: ' + clientIdSet);
        final Map<Id, Account> clientID = new Map<Id, Account>([SELECT Id, SER_CClient__c FROM Account WHERE Id IN :clientIdSet]);
        system.debug('clientID: ' + clientID);
        for(almd__Commercial_Alert__c alert : triggerNew) {
          if(alert.almd__participant_id__c != null && clientID.get(alert.almd__participant_id__c).SER_CClient__c != null && alert.almd__alert_sub_stage_type__c != 'Discarded') {
            alert.Name = alert.Name + '_' + clientID.get(alert.almd__participant_id__c).SER_CClient__c;
          }
        }
      }
    }

  /*
   * @author Global Desktop
   * @Description Comprueba que el owner es distinto a los autorizadores
   */
  public static Boolean compareAuthorizersWithOwner (almd__Commercial_Alert__c comAlert) {
    return (comAlert.OwnerId != comAlert.almd__closed_won_authorizer_user_id__c
            && comAlert.OwnerId != comAlert.almd__reject_authorizer_user_id__c);
  }

  /*
   * @author Global Desktop
   * @Description Comprueba que el banker es distinto a los autorizadores
   */
  public static Boolean compareAuthorizersWithBanker (almd__Commercial_Alert__c comAlert) {
    system.debug('>>>>> AA');
    return (comAlert.almd__User_id__c != comAlert.almd__closed_won_authorizer_user_id__c
            && comAlert.almd__User_id__c != comAlert.almd__reject_authorizer_user_id__c );
  }
  /***************************************
   * Aux methods to avoid sonar errors
   ****************************************/
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
  * Method to inform the final owner
  */
  public static void informOwner(List<almd__Commercial_Alert__c> triggerNew) {
    final Set<Id> usersIds = new Set<Id>();
    for(almd__Commercial_Alert__c alert : triggerNew) {
      if(!usersIds.contains(alert.OwnerId)) {
        usersIds.add(alert.OwnerId);
      }
    }
    final Map <Id, User> mapUsers = new Map<Id, User>([SELECT Id, FederationIdentifier from User Where Id IN :usersIds]);
    for(almd__Commercial_Alert__c alert : triggerNew) {
      alert.almd__owner_access_alert_id__c = mapUsers.get(alert.OwnerId).FederationIdentifier;
    }

  }

  /*
  * Method to concatenate Client code in update
  */
  public static void setNameUpdate(List<almd__Commercial_Alert__c> triggerNew, Map<Id, almd__Commercial_Alert__c> mapOld) {
    for(almd__Commercial_Alert__c alert : triggerNew) {
      if(profileName == Label.DES_ADMIN_PROFILE || profileName == Label.DES_INTEGRATION_PROFILE) {
        alert.Name = mapOld.get(alert.Id).Name;
      }
    }
  }
}