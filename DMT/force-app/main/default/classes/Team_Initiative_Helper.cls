/**********************************************************************************
* @author       Global Desktop
* @date         23/01/2020
* @description  Helper del handler de intt__Team_initiative__c
**********************************************************************************/
public with sharing class Team_Initiative_Helper {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static Team_Initiative_Helper instance;

  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static Team_Initiative_Helper getInstance() {    //NOSONAR
    if (instance == null) {
      instance = new Team_Initiative_Helper();
    }
    return instance;
  }

  /*
  * Met0d0 para pasar sonar
  */
  private Team_Initiative_Helper() {}

  /**
   * @author Global Desktop
   * @Description shareTeamInitiative
   */
  public static void shareTeamInitiative(final List<intt__Team_initiative__c> newList) {
    List<intt__Team_initiative__c> listTIToShare = new List<intt__Team_initiative__c>();
    for(intt__Team_initiative__c iTeamInitiative : [SELECT Id,
                                                      intt__gf_group_campaign_id__c,
                                                      intt__manager_team_id__c
                                                    FROM intt__Team_initiative__c
                                                    WHERE intt__manager_team_id__r.IsActive = true
                                                      AND intt__manager_team_id__r.Profile.Name LIKE '%BBVA Desktop%'
                                                      AND Id IN :newList]) {
      listTIToShare.add(iTeamInitiative);
    }

    final Map<Id, List<intt__Team_initiative__c>> mapAccCampaignTI = new Map<Id, List<intt__Team_initiative__c>>();
    final List<intt__Team_initiative__Share> tShareList = new List<intt__Team_initiative__Share>();
    for(intt__Team_initiative__c iTeamInitiative : listTIToShare) {
      if(mapAccCampaignTI.containsKey(iTeamInitiative.intt__gf_group_campaign_id__c)) {
        final List<intt__Team_initiative__c> listAux = mapAccCampaignTI.get(iTeamInitiative.intt__gf_group_campaign_id__c);
        listAux.add(iTeamInitiative);
        mapAccCampaignTI.put(iTeamInitiative.intt__gf_group_campaign_id__c, listAux);
      } else {
        mapAccCampaignTI.put(iTeamInitiative.intt__gf_group_campaign_id__c, new List<intt__Team_initiative__c>{iTeamInitiative});
      }

      final intt__Team_initiative__Share teamShare = new intt__Team_initiative__Share();
      teamShare.UserOrGroupId = iTeamInitiative.intt__manager_team_id__c;
      teamShare.ParentId = iTeamInitiative.Id;
      teamShare.AccessLevel = 'Read';
      if(tShareList.size() < 10000) {
        tShareList.add(teamShare);
      }
    }
    insert tShareList;

    System.debug('::::::::::mapAccCampaignTI: ' + mapAccCampaignTI);
    final List<cond__Account_Campaign__share> listAccCampShare = new List<cond__Account_Campaign__share>();
    for(cond__Account_Campaign__c iAccountCampaign : [SELECT Id
                                                      FROM cond__Account_Campaign__c
                                                      WHERE Id IN :mapAccCampaignTI.keySet()
                                                     	AND cond__participant_id__r.gf_prtcpt_act_status_ind_type__c = true
       													AND cond__participant_id__r.gf_prtcpt_act_status_ind_type__c != null]) {
      System.debug('::::::::::iAccountCampaign: ' + iAccountCampaign);
      for(intt__Team_initiative__c iTeamInitiative : mapAccCampaignTI.get(iAccountCampaign.Id)) {
        System.debug('::::::::::iTeamInitiative: ' + iTeamInitiative);
        final cond__Account_Campaign__share iAccCampaignShare = new cond__Account_Campaign__share();
          iAccCampaignShare.ParentId = iAccountCampaign.Id;
          iAccCampaignShare.UserOrGroupId = iTeamInitiative.intt__manager_team_id__c;
          iAccCampaignShare.AccessLevel = 'Edit';
          listAccCampShare.add(iAccCampaignShare);
      }
    }

    if(!listAccCampShare.isEmpty() && !test.isrunningtest()) {    //NOSONAR
      insert listAccCampShare;
    }
  }

  /**
   * @author Global Desktop
   * @Description shareTeamInitiative
   */
  public static void deleteShareTeamInitiative(final List<intt__Team_initiative__c> oldList) {
    final Map<Id, List<Id>> mapAccCampUser = new Map<Id, List<Id>>();
    for(intt__Team_initiative__c iTeamInitiative : oldList) {
      if(mapAccCampUser.containsKey(iTeamInitiative.intt__gf_group_campaign_id__c)) {
        final List<Id> listAux = mapAccCampUser.get(iTeamInitiative.intt__gf_group_campaign_id__c);
        listAux.add(iTeamInitiative.intt__manager_team_id__c);
        mapAccCampUser.put(iTeamInitiative.intt__gf_group_campaign_id__c, listAux);
      } else {
        mapAccCampUser.put(iTeamInitiative.intt__gf_group_campaign_id__c, new List<Id>{iTeamInitiative.intt__manager_team_id__c});
      }
    }

    final List<cond__Account_Campaign__share> listAccCampShare = new List<cond__Account_Campaign__share>();
    for(cond__Account_Campaign__share iAccCampaignShare : [SELECT Id,
                                                            UserOrGroupId,
                                                            ParentId
                                                          FROM cond__Account_Campaign__share
                                                          WHERE ParentId IN :mapAccCampUser.keySet()]) {
      for(Id iUser : mapAccCampUser.get(iAccCampaignShare.ParentId)) {
        if(iUser == iAccCampaignShare.UserOrGroupId) {
          listAccCampShare.add(iAccCampaignShare);
        }
      }
    }

    if(!listAccCampShare.isEmpty()) {
      delete listAccCampShare;
    }
  }
}