/**********************************************************************************
* @author       Global Desktop
* @date         21/02/2020
* @description  Helper auxiliar del handler PitchTriggerCustomHandler
**********************************************************************************/
public with sharing class Pitch_Helper_Comm_Alert {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Pitch_Helper_Comm_Alert() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description changeCommAlertStatusInsert
  */
  public static void changeCommAlertStatusInsert(List<pith__Pitch__c> newList) {
    final Set<Id> setCommAlertId = new Set<Id>();
    for(pith__Pitch__c iPitch : [SELECT Id,
                                  commercial_alert_id__c,
                                  commercial_alert_id__r.altm__alert_stage_type__c
                                FROM pith__Pitch__c
                                WHERE Id IN :newList]) {
      if(iPitch.commercial_alert_id__c != null) {
        setCommAlertId.add(iPitch.commercial_alert_id__c);
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
  public static void changeCommAlertStatusUpdate(Map<Id, pith__Pitch__c> newMap, Map<Id, pith__Pitch__c> oldMap) {
    final Set<Id> setCommAlertId = new Set<Id>();
    for(pith__Pitch__c iPitch : [SELECT id,
                                  commercial_alert_id__c,
                                  commercial_alert_id__r.altm__alert_stage_type__c
                                FROM pith__Pitch__c
                                WHERE Id IN :newMap.keySet()]) {
      if(iPitch.commercial_alert_id__c != null
        && oldMap.get(iPitch.Id).commercial_alert_id__c == null) {
        setCommAlertId.add(iPitch.commercial_alert_id__c);
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