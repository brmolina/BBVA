/**********************************************************************************
* @author       Global Desktop
* @date         28/04/2020
* @description  Handler del trigger del objeto DES_Opportunity_Management_member__c
**********************************************************************************/
public with sharing class Opportunity_Manag_Member_TriggerHandler {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Opportunity_Manag_Member_TriggerHandler() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description onAfterInsert
  */
  public static void onAfterInsert(final List<DES_Opportunity_Management_member__c> newList) {
    Opportunity_Manag_Member_Helper.newPitchParticipant(newList);
  }

  /**
  * @author Global Desktop
  * @Description onAfterDelete
  */
  public static void onAfterDelete(final List<DES_Opportunity_Management_member__c> oldList) {
    Opportunity_Manag_Member_Helper.deletePitchParticipant(oldList);
  }
}