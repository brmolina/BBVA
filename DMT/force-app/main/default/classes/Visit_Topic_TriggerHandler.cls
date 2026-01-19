/**********************************************************************************
* @author       Global Desktop
* @date         14/01/2020
* @description  Handler del trigger de dwp_kitv__Visit_Topic__c
**********************************************************************************/
public with sharing class Visit_Topic_TriggerHandler {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static Visit_Topic_TriggerHandler instance;

  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static Visit_Topic_TriggerHandler getInstance() { //NOSONAR
    if (instance == null) {
      instance = new Visit_Topic_TriggerHandler();
    }
    return instance;
  }

  /*
    * Met0d0 para pasar sonar
    */
    private Visit_Topic_TriggerHandler() {}

  /**
   * @author Global Desktop
   * @Description onAfterInsert
   */
  public static void onBeforeInsert(final List<dwp_kitv__Visit_Topic__c> newList) {
    Visit_Topic_Helper.checkVisitWithInitiative(newList);
  }

  /**
   * @author Global Desktop
   * @Description onAfterInsert
   */
  public static void onAfterInsert(final List<dwp_kitv__Visit_Topic__c> newList) {
    final List<dwp_kitv__Visit_Topic__c> listVisitAccCamp = new List<dwp_kitv__Visit_Topic__c>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : newList) {
      if(iVisitTopic.intt__participant_id__c != null) {
        listVisitAccCamp.add(iVisitTopic);
      }
    }
    if(!listVisitAccCamp.isEmpty()) {
      // Visit_Topic_Helper.checkTeamInitiative(newList);
      Visit_Topic_Helper.increaseCampaignNumberOfVisit(newList);
      Visit_Topic_Helper.increaseNumberOfVisit(newList);
    }
    Visit_Topic_Helper.checkAlertTraceability(newList);
  }

  /**
   * @author Global Desktop
   * @Description onBeforeDelete
   */
  public static void onBeforeDelete(final List<dwp_kitv__Visit_Topic__c> oldList) {
    final List<dwp_kitv__Visit_Topic__c> listVisitAccCamp = new List<dwp_kitv__Visit_Topic__c>();
    for(dwp_kitv__Visit_Topic__c iVisitTopic : oldList) {
      if(iVisitTopic.intt__participant_id__c != null) {
        listVisitAccCamp.add(iVisitTopic);
      }
    }
    if(!listVisitAccCamp.isEmpty()) {
      // Visit_Topic_Helper.checkTeamInitiative(oldList);
      Visit_Topic_Helper.decreaseCampaignNumberOfVisit(oldList);
      Visit_Topic_Helper.decreaseNumberOfVisit(oldList);
    }
  }
}