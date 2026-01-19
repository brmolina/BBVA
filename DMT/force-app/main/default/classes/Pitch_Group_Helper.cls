/**********************************************************************************
* @author       Global Desktop
* @date         14/01/2020
* @description  Helper del handler de intt__Pitch_Group__c
**********************************************************************************/
public without sharing class Pitch_Group_Helper {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static Pitch_Group_Helper instance;

  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static Pitch_Group_Helper getInstance() { //NOSONAR
    if (instance == null) {
      instance = new Pitch_Group_Helper();
    }
    return instance;
  }

  /*
  * Met0d0 para pasar sonar
  */
  private Pitch_Group_Helper() {}

  /**
   * @author Global Desktop
   * @Description increaseNumberOfPitch
   */
  public static void increaseNumberOfPitch(final List<intt__Pitch_Group__c> newList) {
    final List<Id> listAccCampaignId = new List<Id>();
    for(intt__Pitch_Group__c iPitchGroup : newList) {
      listAccCampaignId.add(iPitchGroup.intt__participant_id__c);
    }

    final List<cond__Account_Campaign__c> listAccCampaign = new List<cond__Account_Campaign__c>();
    for(cond__Account_Campaign__c iAccountCampaign : [SELECT Id,
                                                        Number_of_pitches__c
                                                      FROM cond__Account_Campaign__c
                                                      WHERE Id IN :listAccCampaignId]) {
      if(iAccountCampaign.Number_of_pitches__c == null
        || iAccountCampaign.Number_of_pitches__c == 0) {
        iAccountCampaign.Number_of_pitches__c = 1;
      } else {
        iAccountCampaign.Number_of_pitches__c = iAccountCampaign.Number_of_pitches__c + 1;
      }
      listAccCampaign.add(iAccountCampaign);
    }

    if(!listAccCampaign.isEmpty()) {
      update listAccCampaign;
    }
  }

  /**
   * @author Global Desktop
   * @Description increaseCampaignNumberOfPitch
   */
  public static void increaseCampaignNumberOfPitch(final List<intt__Pitch_Group__c> newList) {
    final List<Id> listCampaignId = new List<Id>();
    for(intt__Pitch_Group__c iPitchGroup : [SELECT Id,
                                              intt__participant_id__r.cond__campaign_id__c
                                            FROM intt__Pitch_Group__c
                                            WHERE Id IN :newList]) {
      listCampaignId.add(iPitchGroup.intt__participant_id__r.cond__campaign_id__c);
    }

    final List<Campaign> listCampaign = new List<Campaign>();
    for(Campaign iCampaign : [SELECT Id,
                                Number_of_pitches__c
                              FROM Campaign
                              WHERE Id IN :listCampaignId]) {
      if(iCampaign.Number_of_pitches__c == null
        || iCampaign.Number_of_pitches__c == 0) {
        iCampaign.Number_of_pitches__c = 1;
      } else {
        iCampaign.Number_of_pitches__c = iCampaign.Number_of_pitches__c + 1;
      }
      listCampaign.add(iCampaign);
    }

    if(!listCampaign.isEmpty()) {
      update listCampaign;
    }
  }

  /**
   * @author Global Desktop
   * @Description decreaseNumberOfPitch
   */
  public static void decreaseNumberOfPitch(final List<intt__Pitch_Group__c> oldList) {
    final List<Id> listAccCampaignId = new List<Id>();
    for(intt__Pitch_Group__c iPitchGroup : oldList) {
      listAccCampaignId.add(iPitchGroup.intt__participant_id__c);
    }

    final List<cond__Account_Campaign__c> listAccCampaign = new List<cond__Account_Campaign__c>();
    for(cond__Account_Campaign__c iAccountCampaign : [SELECT Id,
                                                        Number_of_pitches__c
                                                      FROM cond__Account_Campaign__c
                                                      WHERE Id IN :listAccCampaignId]) {
      iAccountCampaign.Number_of_pitches__c -= 1;
      listAccCampaign.add(iAccountCampaign);
    }

    if(!listAccCampaign.isEmpty()) {
      update listAccCampaign;
    }
  }

  /**
   * @author Global Desktop
   * @Description decreaseCampaignNumberOfPitch
   */
  public static void decreaseCampaignNumberOfPitch(final List<intt__Pitch_Group__c> oldList) {
    final List<Id> listCampaignId = new List<Id>();
    for(intt__Pitch_Group__c iPitchGroup : [SELECT Id,
                                              intt__participant_id__r.cond__campaign_id__c
                                            FROM intt__Pitch_Group__c
                                            WHERE Id IN :oldList]) {
      listCampaignId.add(iPitchGroup.intt__participant_id__r.cond__campaign_id__c);
    }

    final List<Campaign> listCampaign = new List<Campaign>();
    for(Campaign iCampaign : [SELECT Id,
                                Number_of_pitches__c
                              FROM Campaign
                              WHERE Id IN :listCampaignId]) {
      iCampaign.Number_of_pitches__c -= 1;
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
  public static void checkTeamInitiative(final List<intt__Pitch_Group__c> listPitchGroup) {
    final Map<Id, intt__Pitch_Group__c> mapAccCampPitch = new Map<Id, intt__Pitch_Group__c>();
    for(intt__Pitch_Group__c iPitchGroup : listPitchGroup) {
      mapAccCampPitch.put(iPitchGroup.intt__participant_id__c, iPitchGroup);
    }

    final Map<intt__Pitch_Group__c, Boolean> mapPitchTeam = new Map<intt__Pitch_Group__c, Boolean>();
    for(intt__Team_initiative__c iTeamInitiative : [SELECT Id,
                                                      intt__manager_team_id__c,
                                                      intt__gf_group_campaign_id__c
                                                    FROM intt__Team_initiative__c
                                                    WHERE intt__gf_group_campaign_id__c IN :mapAccCampPitch.keySet()]) {
      if(iTeamInitiative.intt__manager_team_id__c == UserInfo.getUserId()) {
        mapPitchTeam.put(mapAccCampPitch.get(iTeamInitiative.intt__gf_group_campaign_id__c), true);
      }
    }

    for(intt__Pitch_Group__c iPitchGroup : listPitchGroup) {
      if(!mapPitchTeam.containsKey(iPitchGroup)) {
        iPitchGroup.addError(Label.validate_discarted);
      }
    }
  }
}