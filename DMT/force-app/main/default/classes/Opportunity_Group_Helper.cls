/**********************************************************************************
* @author       Global Desktop
* @date         14/01/2020
* @description  Helper del handler de intt__Opportunity_Group__c
**********************************************************************************/
public without sharing class Opportunity_Group_Helper {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static Opportunity_Group_Helper instance;

  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static Opportunity_Group_Helper getInstance() { //NOSONAR
    if (instance == null) {
      instance = new Opportunity_Group_Helper();
    }
    return instance;
  }

  /**
   * @author Global Desktop
   * @description Empty Constructor
   */
  private Opportunity_Group_Helper() {
    System.debug('Constructor empty');
  }

  /**
   * @author Global Desktop
   * @Description increaseNumberOfOpp
   */
  public static void increaseNumberOfOpp(final List<intt__Opportunity_Group__c> newList) {
    final List<Id> listAccCampaignId = new List<Id>();
    for(intt__Opportunity_Group__c iOppGroup : newList) {
      listAccCampaignId.add(iOppGroup.intt__participant_id__c);
    }

    final List<cond__Account_Campaign__c> listAccCampaign = new List<cond__Account_Campaign__c>();
    for(cond__Account_Campaign__c iAccountCampaign : [SELECT Id,
                                                        Number_of_opportunities__c
                                                      FROM cond__Account_Campaign__c
                                                      WHERE Id IN :listAccCampaignId]) {
      if(iAccountCampaign.Number_of_opportunities__c == null
        || iAccountCampaign.Number_of_opportunities__c == 0) {
        iAccountCampaign.Number_of_opportunities__c = 1;
      } else {
        iAccountCampaign.Number_of_opportunities__c = iAccountCampaign.Number_of_opportunities__c + 1;
      }
      listAccCampaign.add(iAccountCampaign);
    }

    if(!listAccCampaign.isEmpty()) {
      update listAccCampaign;
    }
  }

  /**
   * @author Global Desktop
   * @Description increaseCampaignNumberOfOpp
   */
  public static void increaseCampaignNumberOfOpp(final List<intt__Opportunity_Group__c> newList) {
    final List<Id> listCampaignId = new List<Id>();
    for(intt__Opportunity_Group__c iOppGroup : [SELECT Id,
                                                  intt__participant_id__r.cond__campaign_id__c
                                                FROM intt__Opportunity_Group__c
                                                WHERE Id IN :newList]) {
      listCampaignId.add(iOppGroup.intt__participant_id__r.cond__campaign_id__c);
    }

    final List<Campaign> listCampaign = new List<Campaign>();
    for(Campaign iCampaign : [SELECT Id,
                                Number_of_opportunities__c
                              FROM Campaign
                              WHERE Id IN :listCampaignId]) {
      if(iCampaign.Number_of_opportunities__c == null
        || iCampaign.Number_of_opportunities__c == 0) {
        iCampaign.Number_of_opportunities__c = 1;
      } else {
        iCampaign.Number_of_opportunities__c = iCampaign.Number_of_opportunities__c + 1;
      }
      listCampaign.add(iCampaign);
    }

    if(!listCampaign.isEmpty()) {
      update listCampaign;
    }
  }

  /**
   * @author Global Desktop
   * @Description decreaseNumberOfOpp
   */
  public static void decreaseNumberOfOpp(final List<intt__Opportunity_Group__c> oldList) {
    final List<Id> listAccCampaignId = new List<Id>();
    for(intt__Opportunity_Group__c iOppGroup : oldList) {
      listAccCampaignId.add(iOppGroup.intt__participant_id__c);
    }

    final List<cond__Account_Campaign__c> listAccCampaign = new List<cond__Account_Campaign__c>();
    for(cond__Account_Campaign__c iAccountCampaign : [SELECT Id,
                                                        Number_of_opportunities__c
                                                      FROM cond__Account_Campaign__c
                                                      WHERE Id IN :listAccCampaignId]) {
      iAccountCampaign.Number_of_opportunities__c -= 1;
      listAccCampaign.add(iAccountCampaign);
    }

    if(!listAccCampaign.isEmpty()) {
      update listAccCampaign;
    }
  }

  /**
   * @author Global Desktop
   * @Description decreaseCampaignNumberOfOpp
   */
  public static void decreaseCampaignNumberOfOpp(final List<intt__Opportunity_Group__c> oldList) {
    final List<Id> listCampaignId = new List<Id>();
    for(intt__Opportunity_Group__c iOppGroup : [SELECT Id,
                                                  intt__participant_id__r.cond__campaign_id__c
                                                FROM intt__Opportunity_Group__c
                                                WHERE Id IN :oldList]) {
      listCampaignId.add(iOppGroup.intt__participant_id__r.cond__campaign_id__c);
    }

    final List<Campaign> listCampaign = new List<Campaign>();
    for(Campaign iCampaign : [SELECT Id,
                                Number_of_opportunities__c
                              FROM Campaign
                              WHERE Id IN :listCampaignId]) {
      iCampaign.Number_of_opportunities__c -= 1;
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
  public static void checkTeamInitiative(final List<intt__Opportunity_Group__c> listOppGroup) {
    final Map<Id, intt__Opportunity_Group__c> mapAccCampOpp = new Map<Id, intt__Opportunity_Group__c>();
    for(intt__Opportunity_Group__c iOppGroup : listOppGroup) {
      mapAccCampOpp.put(iOppGroup.intt__participant_id__c, iOppGroup);
    }

    final Map<intt__Opportunity_Group__c, Boolean> mapOppTeam = new Map<intt__Opportunity_Group__c, Boolean>();
    for(intt__Team_initiative__c iTeamInitiative : [SELECT Id,
                                                      intt__manager_team_id__c,
                                                      intt__gf_group_campaign_id__c
                                                    FROM intt__Team_initiative__c
                                                    WHERE intt__gf_group_campaign_id__c IN :mapAccCampOpp.keySet()]) {
      if(iTeamInitiative.intt__manager_team_id__c == UserInfo.getUserId()) {
        mapOppTeam.put(mapAccCampOpp.get(iTeamInitiative.intt__gf_group_campaign_id__c), true);
      }
    }

    for(intt__Opportunity_Group__c iOppGroup : listOppGroup) {
      if(!mapOppTeam.containsKey(iOppGroup)) {
        iOppGroup.addError(Label.validate_discarted);
      }
    }
  }
}