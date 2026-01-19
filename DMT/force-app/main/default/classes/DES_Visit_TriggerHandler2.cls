/**********************************************************************************
* @author       Global Desktop
* @date         27/02/2020
* @description  Handler auxiliar del trigger de dwp_kitv__Visit__c
**********************************************************************************/
public with sharing class DES_Visit_TriggerHandler2 {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private DES_Visit_TriggerHandler2() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description onAfterInsert
  */
  public static void onAfterInsert(List<dwp_kitv__Visit__c> newList) {
    Visit_Helper_Comm_Alert.changeCommAlertStatusInsert(newList);
  }

  /**
  * @author Global Desktop
  * @Description onAfterUpdate
  */
  public static void onAfterUpdate(Map<Id, dwp_kitv__Visit__c> newMap, Map<Id, dwp_kitv__Visit__c> oldMap) {
    Visit_Helper_Comm_Alert.changeCommAlertStatusUpdate(newMap, oldMap);
  }
}