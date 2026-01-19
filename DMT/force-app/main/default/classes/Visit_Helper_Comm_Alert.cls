/**********************************************************************************
* @author       Global Desktop
* @date         27/02/2020
* @description  Helper auxiliar del handler DES_Visit_TriggerHandler2
**********************************************************************************/
public with sharing class Visit_Helper_Comm_Alert {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Visit_Helper_Comm_Alert() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description changeCommAlertStatusInsert
  */
  public static void changeCommAlertStatusInsert(List<dwp_kitv__Visit__c> newList) {
    final Set<Id> setCommAlertId = new Set<Id>();
    for(dwp_kitv__Visit__c iVisit : [SELECT id,
                                      commercial_alert_id__c,
                                      commercial_alert_id__r.altm__alert_stage_type__c
                                    FROM dwp_kitv__Visit__c
                                    WHERE Id IN :newList]) {
      if(iVisit.commercial_alert_id__c != null) {
        setCommAlertId.add(iVisit.commercial_alert_id__c);
      }
    }

    final List<altm__Commercial_Alert__c> listCommAlert = new List<altm__Commercial_Alert__c>();
    for(altm__Commercial_Alert__c iCommercialAlert : [SELECT Id,
                                                        altm__alert_stage_type__c
                                                      FROM altm__Commercial_Alert__c
                                                      WHERE Id IN :setCommAlertId]) {
      if(iCommercialAlert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_PENDING) {
        iCommercialAlert.altm__alert_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_MANAGED;
        listCommAlert.add(iCommercialAlert);
      }
    }

    if(!listCommAlert.isEmpty()) {
      update listCommAlert;
    }
  }

  /**
  * @author Global Desktop
  * @Description changeCommAlertStatusUpdate
  */
  public static void changeCommAlertStatusUpdate(Map<Id, dwp_kitv__Visit__c> newMap, Map<Id, dwp_kitv__Visit__c> oldMap) {
    final Set<Id> setCommAlertId = new Set<Id>();
    for(dwp_kitv__Visit__c iVisit : [SELECT id,
                                      commercial_alert_id__c,
                                      commercial_alert_id__r.altm__alert_stage_type__c
                                    FROM dwp_kitv__Visit__c
                                    WHERE Id IN :newMap.keySet()]) {
      if(iVisit.commercial_alert_id__c != null
        && oldMap.get(iVisit.Id).commercial_alert_id__c == null) {
        setCommAlertId.add(iVisit.commercial_alert_id__c);
      }
    }

    final List<altm__Commercial_Alert__c> listCommAlert = new List<altm__Commercial_Alert__c>();
    for(altm__Commercial_Alert__c iCommercialAlert : [SELECT Id,
                                                        altm__alert_stage_type__c
                                                      FROM altm__Commercial_Alert__c
                                                      WHERE Id IN :setCommAlertId]) {
      if(iCommercialAlert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_PENDING) {
        iCommercialAlert.altm__alert_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_MANAGED;
        listCommAlert.add(iCommercialAlert);
      }
    }

    if(!listCommAlert.isEmpty()) {
      update listCommAlert;
    }
  }
}