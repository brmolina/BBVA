/**********************************************************************************
* @author       Global Desktop
* @date         23/04/2020
* @description  Handler del trigger del objeto dwp_kitv__Visit_Management_Team__c
**********************************************************************************/
public with sharing class Visit_Management_Team_TriggerHandler {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Visit_Management_Team_TriggerHandler() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description onAfterInsert
  */
  public static void onAfterInsert(final List<dwp_kitv__Visit_Management_Team__c> newList) {
    Visit_Management_Team_Helper.newPitchParticipant(newList);
  }

  /**
  * @author Global Desktop
  * @Description onAfterDelete
  */
  public static void onAfterDelete(final List<dwp_kitv__Visit_Management_Team__c> oldList) {
    Visit_Management_Team_Helper.deletePitchParticipant(oldList);
  }
}