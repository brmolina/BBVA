/*
* @author       Global Desktop
* @date         10/10/2019
* @description  Manejador del trigger para el objeto NPS_Wave__c
*/
public with sharing class NPS_WaveTriggerHandler {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static NPS_WaveTriggerHandler instance;
  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static NPS_WaveTriggerHandler getInstance() { //NOSONAR
    if (instance == null) {
      instance = new NPS_WaveTriggerHandler();
    }
    return instance;
  }

  private NPS_WaveTriggerHandler() {
  }

  /**
   * Description: onAfterInsert
   */
  public static void onAfterInsert(List<NPS_Wave__c> triggerNew) {
    //NPS_Wave_Helper.npsNotification(triggerNew);
  }
}