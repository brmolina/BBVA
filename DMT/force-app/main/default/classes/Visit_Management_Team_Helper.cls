/**********************************************************************************
* @author       Global Desktop
* @date         23/04/2020
* @description  Helper del handler Visit_Management_Team_TriggerHandler
**********************************************************************************/
public with sharing class Visit_Management_Team_Helper {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Visit_Management_Team_Helper() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description newPitchParticipant
  */
  public static void newPitchParticipant(final List<dwp_kitv__Visit_Management_Team__c> newList) {
    final Map<Id, List<Id>> mapVisitUser = new Map<Id, List<Id>>();
    for(dwp_kitv__Visit_Management_Team__c iVisitMT : newList) {
      if(mapVisitUser.containsKey(iVisitMT.dwp_kitv__visit_id__c)) {
        final List<Id> listAux = mapVisitUser.get(iVisitMT.dwp_kitv__visit_id__c);
        listAux.add(iVisitMT.dwp_kitv__user_id__c);
        mapVisitUser.put(iVisitMT.dwp_kitv__visit_id__c, listAux);
      } else {
        mapVisitUser.put(iVisitMT.dwp_kitv__visit_id__c, new List<Id> {iVisitMT.dwp_kitv__user_id__c});
      }
    }

    final Map<Id, List<Id>> mapPitchUser = new Map<Id, List<Id>>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : [SELECT Id, //NOSONAR
                                                  dwp_kitv__visit_id__c,
                                                  pith__pitch_visit_topic_id__c
                                                FROM dwp_kitv__Visit_Topic__c
                                                WHERE dwp_kitv__visit_id__c IN :mapVisitUser.keySet()
                                                  AND pith__pitch_visit_topic_id__c != null]) {
      if(mapPitchUser.containsKey(iVisitTopic.pith__pitch_visit_topic_id__c)) {
        final List<Id> listAux = mapPitchUser.get(iVisitTopic.pith__pitch_visit_topic_id__c);
        listAux.addAll(mapVisitUser.get(iVisitTopic.dwp_kitv__visit_id__c));
        mapPitchUser.put(iVisitTopic.pith__pitch_visit_topic_id__c, listAux);
      } else {
        mapPitchUser.put(iVisitTopic.pith__pitch_visit_topic_id__c, mapVisitUser.get(iVisitTopic.dwp_kitv__visit_id__c));
      }
    }

    newPitchParticipantAux(mapPitchUser);
  }

  /**
  * @author Global Desktop
  * @Description newPitchParticipantAux
  */
  public static void newPitchParticipantAux(final Map<Id, List<Id>> mapPitchUser) {
    final List<pith__BBVA_Pitch_Team__c> listPitchTeam = new List<pith__BBVA_Pitch_Team__c>();
    for(pith__Pitch__c iPitch : [SELECT Id,
                                  (SELECT Id,
                                    pith__external_reference_id__c,
                                    pith__external_user_id__c
                                  FROM pith__BBVA_Pitch_Team__r)
                                FROM pith__Pitch__c
                                WHERE Id IN :mapPitchUser.keySet()]) {
      final Map<Id, List<Id>> mapPitchUserId = new Map<Id, List<Id>>();
      for(pith__BBVA_Pitch_Team__c iPitchTeam : iPitch.pith__BBVA_Pitch_Team__r) {
        if(mapPitchUserId.containsKey(iPitchTeam.pith__external_reference_id__c)) {
          final List<Id> listAux = mapPitchUserId.get(iPitchTeam.pith__external_reference_id__c);
          listAux.add(iPitchTeam.pith__external_user_id__c);
          mapPitchUserId.put(iPitchTeam.pith__external_reference_id__c, listAux);
        } else {
          mapPitchUserId.put(iPitchTeam.pith__external_reference_id__c, new List<Id> {iPitchTeam.pith__external_user_id__c});
        }
      }

      for(Id iUserId : mapPitchUser.get(iPitch.Id)) {
        if(!mapPitchUserId.get(iPitch.Id).contains(iUserId)) {
          final pith__BBVA_Pitch_Team__c iPitchTeam = new pith__BBVA_Pitch_Team__c();
          iPitchTeam.pith__external_reference_id__c = iPitch.Id;
          iPitchTeam.pith__external_user_id__c = iUserId;
          iPitchTeam.User_Origin__c = 'Visit';
          listPitchTeam.add(iPitchTeam);
        }
      }
    }

    if(!listPitchTeam.isEmpty()) {
      insert listPitchTeam;
    }
  }

  /**
  * @author Global Desktop
  * @Description deletePitchParticipant
  */
  public static void deletePitchParticipant(final List<dwp_kitv__Visit_Management_Team__c> oldList) {
    final Map<Id, List<Id>> mapVisitUser = new Map<Id, List<Id>>();
    for(dwp_kitv__Visit_Management_Team__c iVisitMT : oldList) {
      if(mapVisitUser.containsKey(iVisitMT.dwp_kitv__visit_id__c)) {
        final List<Id> listAux = mapVisitUser.get(iVisitMT.dwp_kitv__visit_id__c);
        listAux.add(iVisitMT.dwp_kitv__user_id__c);
        mapVisitUser.put(iVisitMT.dwp_kitv__visit_id__c, listAux);
      } else {
        mapVisitUser.put(iVisitMT.dwp_kitv__visit_id__c, new List<Id> {iVisitMT.dwp_kitv__user_id__c});
      }
    }

    final Map<Id, List<Id>> mapPitchUser = new Map<Id, List<Id>>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : [SELECT Id, //NOSONAR
                                                  dwp_kitv__visit_id__c,
                                                  pith__pitch_visit_topic_id__c
                                                FROM dwp_kitv__Visit_Topic__c
                                                WHERE dwp_kitv__visit_id__c IN :mapVisitUser.keySet()
                                                  AND pith__pitch_visit_topic_id__c != null]) {
      if(mapPitchUser.containsKey(iVisitTopic.pith__pitch_visit_topic_id__c)) {
        final List<Id> listAux = mapPitchUser.get(iVisitTopic.pith__pitch_visit_topic_id__c);
        listAux.addAll(mapVisitUser.get(iVisitTopic.dwp_kitv__visit_id__c));
        mapPitchUser.put(iVisitTopic.pith__pitch_visit_topic_id__c, listAux);
      } else {
        mapPitchUser.put(iVisitTopic.pith__pitch_visit_topic_id__c, mapVisitUser.get(iVisitTopic.dwp_kitv__visit_id__c));
      }
    }

    final List<pith__BBVA_Pitch_Team__c> listPitchTeam = new List<pith__BBVA_Pitch_Team__c>();
    for(pith__BBVA_Pitch_Team__c iPitchTeam : [SELECT Id,
                                                pith__external_reference_id__c,
                                                pith__external_user_id__c
                                              FROM pith__BBVA_Pitch_Team__c
                                              WHERE pith__external_reference_id__c IN :mapPitchUser.keySet()
                                                AND User_origin__c = 'Visit']) {
      if(mapPitchUser.get(iPitchTeam.pith__external_reference_id__c).contains(iPitchTeam.pith__external_user_id__c)) {
        listPitchTeam.add(iPitchTeam);
      }
    }

    if(!listPitchTeam.isEmpty()) {
      delete listPitchTeam;
    }
  }
}