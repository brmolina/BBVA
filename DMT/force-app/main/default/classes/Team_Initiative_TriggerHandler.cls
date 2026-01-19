/**********************************************************************************
* @author       Global Desktop
* @date         23/01/2020
* @description  Handler del trigger de intt__Team_initiative__c
**********************************************************************************/
public with sharing class Team_Initiative_TriggerHandler {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static Team_Initiative_TriggerHandler instance;

  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static Team_Initiative_TriggerHandler getInstance() { //NOSONAR
    if (instance == null) {
      instance = new Team_Initiative_TriggerHandler();
    }
    return instance;
  }

  /*
  * Met0d0 para pasar sonar
  */
  private Team_Initiative_TriggerHandler() {}

  /**
   * @author Global Desktop
   * @Description onAfterInsert
   */
  public static void onAfterInsert(final List<intt__Team_initiative__c> newList) {
    Team_Initiative_Helper.shareTeamInitiative(newList);
  }

  /**
   * @author Global Desktop
   * @Description onAfterDelete
   */
  public static void onAfterDelete(final List<intt__Team_initiative__c> oldList) {
    Team_Initiative_Helper.deleteShareTeamInitiative(oldList);
  }
}