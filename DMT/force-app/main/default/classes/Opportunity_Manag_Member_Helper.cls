/**********************************************************************************
* @author       Global Desktop
* @date         28/04/2020
* @description  Helper del handler Opportunity_Manag_Member_TriggerHandler
**********************************************************************************/
public with sharing class Opportunity_Manag_Member_Helper {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Opportunity_Manag_Member_Helper() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description newPitchParticipant
  */
  public static void newPitchParticipant(final List<DES_Opportunity_Management_member__c> newList) {
    final Map<Id, List<Id>> mapOppUser = new Map<Id, List<Id>>();
    for(DES_Opportunity_Management_member__c iOpportunityMM : newList) {
      if(mapOppUser.containsKey(iOpportunityMM.DES_Opportunity__c)) {
        final List<Id> listAux = mapOppUser.get(iOpportunityMM.DES_Opportunity__c);
        listAux.add(iOpportunityMM.DES_User__c);
        mapOppUser.put(iOpportunityMM.DES_Opportunity__c, listAux);
      } else {
        mapOppUser.put(iOpportunityMM.DES_Opportunity__c, new List<Id> {iOpportunityMM.DES_User__c});
      }
    }

    final Map<Id, List<Id>> mapPitchUser = new Map<Id, List<Id>>();
    for(pith__Related_opportunity_pitch__c iRelOppPitch : [SELECT Id, //NOSONAR
                                                            pith__opportunity_pitch_id__c,
                                                            pith__pitch_opportunity_id__c
                                                          FROM pith__Related_opportunity_pitch__c
                                                          WHERE pith__opportunity_pitch_id__c IN :mapOppUser.keySet()
                                                            AND pith__pitch_opportunity_id__c != null]) {
      if(mapPitchUser.containsKey(iRelOppPitch.pith__pitch_opportunity_id__c)) {
        final List<Id> listAux = mapPitchUser.get(iRelOppPitch.pith__pitch_opportunity_id__c);
        listAux.addAll(mapOppUser.get(iRelOppPitch.pith__opportunity_pitch_id__c));
        mapPitchUser.put(iRelOppPitch.pith__pitch_opportunity_id__c, listAux);
      } else {
        mapPitchUser.put(iRelOppPitch.pith__pitch_opportunity_id__c, mapOppUser.get(iRelOppPitch.pith__opportunity_pitch_id__c));
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

      System.debug('::::::::::mapPitchUserId: ' + mapPitchUserId);
      for(Id iUserId : mapPitchUser.get(iPitch.Id)) {
        System.debug('::::::::::iUserId: ' + iUserId);
        System.debug('::::::::::mapPitchUserId.get(iPitch.Id): ' + mapPitchUserId.get(iPitch.Id));
        if(!mapPitchUserId.get(iPitch.Id).contains(iUserId)) {
          final pith__BBVA_Pitch_Team__c iPitchTeam = new pith__BBVA_Pitch_Team__c();
          iPitchTeam.pith__external_reference_id__c = iPitch.Id;
          iPitchTeam.pith__external_user_id__c = iUserId;
          iPitchTeam.User_Origin__c = 'Opportunity';
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
  public static void deletePitchParticipant(final List<DES_Opportunity_Management_member__c> oldList) {
    final Map<Id, List<Id>> mapOppUser = new Map<Id, List<Id>>();
    for(DES_Opportunity_Management_member__c iOpportunityMM : oldList) {
      if(mapOppUser.containsKey(iOpportunityMM.DES_Opportunity__c)) {
        final List<Id> listAux = mapOppUser.get(iOpportunityMM.DES_Opportunity__c);
        listAux.add(iOpportunityMM.DES_User__c);
        mapOppUser.put(iOpportunityMM.DES_Opportunity__c, listAux);
      } else {
        mapOppUser.put(iOpportunityMM.DES_Opportunity__c, new List<Id> {iOpportunityMM.DES_User__c});
      }
    }

    final Map<Id, List<Id>> mapPitchUser = new Map<Id, List<Id>>();
    for(pith__Related_opportunity_pitch__c iRelOppPitch : [SELECT Id, //NOSONAR
                                                            pith__opportunity_pitch_id__c,
                                                            pith__pitch_opportunity_id__c
                                                          FROM pith__Related_opportunity_pitch__c
                                                          WHERE pith__opportunity_pitch_id__c IN :mapOppUser.keySet()
                                                            AND pith__pitch_opportunity_id__c != null]) {
      if(mapPitchUser.containsKey(iRelOppPitch.pith__pitch_opportunity_id__c)) {
        final List<Id> listAux = mapPitchUser.get(iRelOppPitch.pith__pitch_opportunity_id__c);
        listAux.addAll(mapOppUser.get(iRelOppPitch.pith__opportunity_pitch_id__c));
        mapPitchUser.put(iRelOppPitch.pith__pitch_opportunity_id__c, listAux);
      } else {
        mapPitchUser.put(iRelOppPitch.pith__pitch_opportunity_id__c, mapOppUser.get(iRelOppPitch.pith__opportunity_pitch_id__c));
      }
    }

    final List<pith__BBVA_Pitch_Team__c> listPitchTeam = new List<pith__BBVA_Pitch_Team__c>();
    for(pith__BBVA_Pitch_Team__c iPitchTeam : [SELECT Id,
                                                pith__external_reference_id__c,
                                                pith__external_user_id__c
                                              FROM pith__BBVA_Pitch_Team__c
                                              WHERE pith__external_reference_id__c IN :mapPitchUser.keySet()
                                                AND User_origin__c = 'Opportunity']) {
      if(mapPitchUser.get(iPitchTeam.pith__external_reference_id__c).contains(iPitchTeam.pith__external_user_id__c)) {
        listPitchTeam.add(iPitchTeam);
      }
    }

    if(!listPitchTeam.isEmpty()) {
      delete listPitchTeam;
    }
  }
}