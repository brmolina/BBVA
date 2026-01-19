/**********************************************************************************
* @author       Global Desktop
* @date         17/02/2020
* @description  Handler del trigger de pith__Related_opportunity_pitch__c
**********************************************************************************/
public with sharing class Related_Opp_Pitch_TriggerHandler { //NOSONAR
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  public Related_Opp_Pitch_TriggerHandler() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description onAfterInsert
  */
  public static void onAfterInsert(final List<pith__Related_opportunity_pitch__c> newList) {
    Related_Opp_Pitch_Helper.checkAlertTraceabilityPitchOpp(newList);
  }
}