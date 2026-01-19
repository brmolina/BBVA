/**********************************************************************************
* @author       Global Desktop
* @date         14/01/2020
* @description  Helper del handler de dwp_kitv__Visit_Topic__c
**********************************************************************************/
public without sharing class Visit_Topic_Helper {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static Visit_Topic_Helper instance;

  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static Visit_Topic_Helper getInstance() { //NOSONAR
    if (instance == null) {
      instance = new Visit_Topic_Helper();
    }
    return instance;
  }

  /*
  * Met0d0 para pasar sonar
  */
  private Visit_Topic_Helper() {}

  /**
   * @author Global Desktop
   * @Description checkVisitWithInitiative
   */
  public static void checkVisitWithInitiative(final List<dwp_kitv__Visit_Topic__c> newList) {
    for(dwp_kitv__Visit_Topic__c iVisitTopic : newList) {
      if(iVisitTopic.intt__participant_id__c != null) {
        iVisitTopic.Visit_with_initiative__c = true;
      }
    }
  }

  /**
   * @author Global Desktop
   * @Description increaseNumberOfVisit
   */
  public static void increaseNumberOfVisit(final List<dwp_kitv__Visit_Topic__c> newList) {
    final List<Id> listAccCampaignId = new List<Id>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : newList) {
      listAccCampaignId.add(iVisitTopic.intt__participant_id__c);
    }

    final List<cond__Account_Campaign__c> listAccCampaign = new List<cond__Account_Campaign__c>();
    for(cond__Account_Campaign__c iAccountCampaign : [SELECT Id,
                                                        Number_of_visits__c
                                                      FROM cond__Account_Campaign__c
                                                      WHERE Id IN :listAccCampaignId]) {
      if(iAccountCampaign.Number_of_visits__c == null
        || iAccountCampaign.Number_of_visits__c == 0) {
        iAccountCampaign.Number_of_visits__c = 1;
      } else {
        iAccountCampaign.Number_of_visits__c = iAccountCampaign.Number_of_visits__c + 1;
      }
      listAccCampaign.add(iAccountCampaign);
    }

    System.debug('::::::::::listAccCampaign: ' + listAccCampaign);
    if(!listAccCampaign.isEmpty()) {
      update listAccCampaign;
    }
  }

  /**
   * @author Global Desktop
   * @Description increaseCampaignNumberOfVisit
   */
  public static void increaseCampaignNumberOfVisit(final List<dwp_kitv__Visit_Topic__c> newList) {
    final List<Id> listCampaignId = new List<Id>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : [SELECT Id,
                                                  intt__participant_id__r.cond__campaign_id__c
                                                FROM dwp_kitv__Visit_Topic__c
                                                WHERE Id IN :newList]) {
      listCampaignId.add(iVisitTopic.intt__participant_id__r.cond__campaign_id__c);
    }

    final List<Campaign> listCampaign = new List<Campaign>();
    for(Campaign iCampaign : [SELECT Id,
                                      Number_of_visits__c
                                    FROM Campaign
                                    WHERE Id IN :listCampaignId]) {
      if(iCampaign.Number_of_visits__c == null
        || iCampaign.Number_of_visits__c == 0) {
        iCampaign.Number_of_visits__c = 1;
      } else {
        iCampaign.Number_of_visits__c = iCampaign.Number_of_visits__c + 1;
      }
      listCampaign.add(iCampaign);
    }

    System.debug('::::::::::listAccCampaign: ' + listCampaign);
    if(!listCampaign.isEmpty()) {
      update listCampaign;
    }
  }

  /**
   * @author Global Desktop
   * @Description decreaseNumberOfVisit
   */
  public static void decreaseNumberOfVisit(final List<dwp_kitv__Visit_Topic__c> oldList) {
    final List<Id> listAccCampaignId = new List<Id>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : oldList) {
      listAccCampaignId.add(iVisitTopic.intt__participant_id__c);
    }

    final List<cond__Account_Campaign__c> listAccCampaign = new List<cond__Account_Campaign__c>();
    for(cond__Account_Campaign__c iAccountCampaign : [SELECT Id,
                                                        Number_of_visits__c
                                                      FROM cond__Account_Campaign__c
                                                      WHERE Id IN :listAccCampaignId]) {
      iAccountCampaign.Number_of_visits__c -= 1;
      listAccCampaign.add(iAccountCampaign);
    }

    if(!listAccCampaign.isEmpty()) {
      update listAccCampaign;
    }
  }

  /**
   * @author Global Desktop
   * @Description decreaseCampaignNumberOfVisit
   */
  public static void decreaseCampaignNumberOfVisit(final List<dwp_kitv__Visit_Topic__c> oldList) {
    final List<Id> listCampaignId = new List<Id>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : [SELECT Id,
                                                  intt__participant_id__r.cond__campaign_id__c
                                                FROM dwp_kitv__Visit_Topic__c
                                                WHERE Id IN :oldList]) {
      listCampaignId.add(iVisitTopic.intt__participant_id__r.cond__campaign_id__c);
    }

    final List<Campaign> listCampaign = new List<Campaign>();
    for(Campaign iCampaign : [SELECT Id,
                                Number_of_visits__c
                              FROM Campaign
                              WHERE Id IN :listCampaignId]) {
      iCampaign.Number_of_visits__c -= 1;
      listCampaign.add(iCampaign);
    }

    if(!listCampaign.isEmpty()) {
      update listCampaign;
    }
  }

  /**
   * @author Global Desktop
   * @Description checkTeamInitiative
   */
  public static void checkTeamInitiative(final List<dwp_kitv__Visit_Topic__c> listVisitGroup) {
    final Map<Id, dwp_kitv__Visit_Topic__c> mapAccCampVisit = new Map<Id, dwp_kitv__Visit_Topic__c>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : listVisitGroup) {
      mapAccCampVisit.put(iVisitTopic.intt__participant_id__c, iVisitTopic);
    }

    final Map<dwp_kitv__Visit_Topic__c, Boolean> mapVisitTeam = new Map<dwp_kitv__Visit_Topic__c, Boolean>();
    for(intt__Team_initiative__c iTeamInitiative : [SELECT Id,
                                                      intt__manager_team_id__c,
                                                      intt__gf_group_campaign_id__c
                                                    FROM intt__Team_initiative__c
                                                    WHERE intt__gf_group_campaign_id__c IN :mapAccCampVisit.keySet()]) {
      if(iTeamInitiative.intt__manager_team_id__c == UserInfo.getUserId()) {
        mapVisitTeam.put(mapAccCampVisit.get(iTeamInitiative.intt__gf_group_campaign_id__c), true);
      }
    }

    for(dwp_kitv__Visit_Topic__c iVisitTopic : listVisitGroup) {
      if(!mapVisitTeam.containsKey(iVisitTopic)) {
        iVisitTopic.addError(Label.validate_discarted);
      }
    }
  }

  /**
  * @author Global Desktop
  * @Description checkAlertTraceability
  */
  public static void checkAlertTraceability(final List<dwp_kitv__Visit_Topic__c> newList) {
    final List<dwp_kitv__Visit_Topic__c> listVisitOpp = new List<dwp_kitv__Visit_Topic__c>();
    final List<dwp_kitv__Visit_Topic__c> listVisitPitch = new List<dwp_kitv__Visit_Topic__c>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : newList) {
      if(iVisitTopic.dwp_kitv__opportunity_id__c != null) { //NOSONAR
        listVisitOpp.add(iVisitTopic);
      } else if(iVisitTopic.pith__pitch_visit_topic_id__c != null) {
        listVisitPitch.add(iVisitTopic);
      }
    }

    if(!listVisitOpp.isEmpty()) {
      checkAlertTraceabilityVisitOpp(listVisitOpp);
    }

    if(!listVisitPitch.isEmpty()) {
      checkAlertTraceabilityVisitPitch(listVisitPitch);
    }
  }

  /**
  * @author Global Desktop
  * @Description checkAlertTraceabilityVisitOpp
  */
  public static void checkAlertTraceabilityVisitOpp(final List<dwp_kitv__Visit_Topic__c> listVisitOpp) {
    final Set<Id> setVisit = new Set<Id>();
    final Set<Id> setOpp = new Set<Id>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : listVisitOpp) {
      setVisit.add(iVisitTopic.dwp_kitv__visit_id__c);
      setOpp.add(iVisitTopic.dwp_kitv__opportunity_id__c);
    }

    final Map<Id, dwp_kitv__Visit__c> mapIdVisit = new Map<Id, dwp_kitv__Visit__c>([SELECT Id, commercial_alert_id__c FROM dwp_kitv__Visit__c WHERE Id IN :setVisit]);
    final Map<Id, Opportunity> mapIdOpp = new Map<Id, Opportunity>([SELECT Id, commercial_alert_id__c FROM Opportunity WHERE Id IN :setOpp]);

    final List<dwp_kitv__Visit__c> listVisit = new List<dwp_kitv__Visit__c>();
    final List<Opportunity> listOpp = new List<Opportunity>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : listVisitOpp) {
      if(mapIdOpp.get(iVisitTopic.dwp_kitv__opportunity_id__c).commercial_alert_id__c != null
        && mapIdVisit.get(iVisitTopic.dwp_kitv__visit_id__c).commercial_alert_id__c == null) {
        mapIdVisit.get(iVisitTopic.dwp_kitv__visit_id__c).commercial_alert_id__c = mapIdOpp.get(iVisitTopic.dwp_kitv__opportunity_id__c).commercial_alert_id__c;
        listVisit.add(mapIdVisit.get(iVisitTopic.dwp_kitv__visit_id__c));
      } else if(mapIdOpp.get(iVisitTopic.dwp_kitv__opportunity_id__c).commercial_alert_id__c == null
        && mapIdVisit.get(iVisitTopic.dwp_kitv__visit_id__c).commercial_alert_id__c != null) {
        mapIdOpp.get(iVisitTopic.dwp_kitv__opportunity_id__c).commercial_alert_id__c = mapIdVisit.get(iVisitTopic.dwp_kitv__visit_id__c).commercial_alert_id__c;
        listOpp.add(mapIdOpp.get(iVisitTopic.dwp_kitv__opportunity_id__c));
      }
    }

    if(!listVisit.isEmpty()) {
      update listVisit;
    }
    if(!listOpp.isEmpty()) {
      update listOpp;
    }
  }

  /**
  * @author Global Desktop
  * @Description checkAlertTraceabilityVisitPitch
  */
  public static void checkAlertTraceabilityVisitPitch(final List<dwp_kitv__Visit_Topic__c> listVisitPitch) {
    final Set<Id> setVisit = new Set<Id>();
    final Set<Id> setPitch = new Set<Id>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : listVisitPitch) {
      setVisit.add(iVisitTopic.dwp_kitv__visit_id__c);
      setPitch.add(iVisitTopic.pith__pitch_visit_topic_id__c);
    }

    final Map<Id, dwp_kitv__Visit__c> mapIdVisit = new Map<Id, dwp_kitv__Visit__c>([SELECT Id, commercial_alert_id__c FROM dwp_kitv__Visit__c WHERE Id IN :setVisit]);
    final Map<Id, pith__Pitch__c> mapIdPitch = new Map<Id, pith__Pitch__c>([SELECT Id, commercial_alert_id__c FROM pith__Pitch__c WHERE Id IN :setPitch]);

    final List<dwp_kitv__Visit__c> listVisit = new List<dwp_kitv__Visit__c>();
    final List<pith__Pitch__c> listPitch = new List<pith__Pitch__c>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : listVisitPitch) {
      if(mapIdPitch.get(iVisitTopic.pith__pitch_visit_topic_id__c).commercial_alert_id__c != null
        && mapIdVisit.get(iVisitTopic.dwp_kitv__visit_id__c).commercial_alert_id__c == null) {
        mapIdVisit.get(iVisitTopic.dwp_kitv__visit_id__c).commercial_alert_id__c = mapIdPitch.get(iVisitTopic.pith__pitch_visit_topic_id__c).commercial_alert_id__c;
        listVisit.add(mapIdVisit.get(iVisitTopic.dwp_kitv__visit_id__c));
      } else if(mapIdPitch.get(iVisitTopic.pith__pitch_visit_topic_id__c).commercial_alert_id__c == null
        && mapIdVisit.get(iVisitTopic.dwp_kitv__visit_id__c).commercial_alert_id__c != null) {
        mapIdPitch.get(iVisitTopic.pith__pitch_visit_topic_id__c).commercial_alert_id__c = mapIdVisit.get(iVisitTopic.dwp_kitv__visit_id__c).commercial_alert_id__c;
        listPitch.add(mapIdPitch.get(iVisitTopic.pith__pitch_visit_topic_id__c));
      }
    }

    if(!listVisit.isEmpty()) {
      update listVisit;
    }
    if(!listPitch.isEmpty()) {
      update listPitch;
    }
  }
}