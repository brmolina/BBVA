/**********************************************************************************
* @author       Global Desktop
* @date         14/01/2020
* @description  Handler del trigger de intt__Opportunity_Group__c
**********************************************************************************/
public with sharing class Opportunity_Group_TriggerHandler {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static Opportunity_Group_TriggerHandler instance;

  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static Opportunity_Group_TriggerHandler getInstance() { //NOSONAR
    if (instance == null) {
      instance = new Opportunity_Group_TriggerHandler();
    }
    return instance;
  }

  /**
   * @author Global Desktop
   * @description Empty Constructor
   */
  private Opportunity_Group_TriggerHandler() {
    System.debug('Constructor empty');
  }

  /**
   * @author Global Desktop
   * @Description onAfterInsert
   */
  public static void onAfterInsert(final List<intt__Opportunity_Group__c> newList) {
    // Opportunity_Group_Helper.checkTeamInitiative(newList);
    Opportunity_Group_Helper.increaseCampaignNumberOfOpp(newList);
    Opportunity_Group_Helper.increaseNumberOfOpp(newList);
  }

  /**
   * @author Global Desktop
   * @Description onBeforeDelete
   */
  public static void onBeforeDelete(final List<intt__Opportunity_Group__c> oldList) {
    // Opportunity_Group_Helper.checkTeamInitiative(oldList);
    Opportunity_Group_Helper.decreaseCampaignNumberOfOpp(oldList);
    Opportunity_Group_Helper.decreaseNumberOfOpp(oldList);
  }
}