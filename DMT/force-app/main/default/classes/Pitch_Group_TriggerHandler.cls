/**********************************************************************************
* @author       Global Desktop
* @date         14/01/2020
* @description  Handler del trigger de intt__Pitch_Group__c
**********************************************************************************/
public with sharing class Pitch_Group_TriggerHandler {

  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static Pitch_Group_TriggerHandler instance;

  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static Pitch_Group_TriggerHandler getInstance() { //NOSONAR
    if (instance == null) {
      instance = new Pitch_Group_TriggerHandler();
    }
    return instance;
  }

  /*
  * Met0d0 para pasar sonar
  */
  private Pitch_Group_TriggerHandler() {}

  /**
   * @author Global Desktop
   * @Description onAfterInsert
   */
  public static void onAfterInsert(final List<intt__Pitch_Group__c> newList) {
    // Pitch_Group_Helper.checkTeamInitiative(newList);
    Pitch_Group_Helper.increaseCampaignNumberOfPitch(newList);
    Pitch_Group_Helper.increaseNumberOfPitch(newList);
  }

  /**
   * @author Global Desktop
   * @Description onBeforeDelete
   */
  public static void onBeforeDelete(final List<intt__Pitch_Group__c> oldList) {
    // Pitch_Group_Helper.checkTeamInitiative(oldList);
    Pitch_Group_Helper.decreaseCampaignNumberOfPitch(oldList);
    Pitch_Group_Helper.decreaseNumberOfPitch(oldList);
  }
}