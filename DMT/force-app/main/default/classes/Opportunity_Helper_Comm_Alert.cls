/**********************************************************************************
* @author       Global Desktop
* @date         21/02/2020
* @description  Helper auxiliar del handler OpportunityTriggerHandler2
**********************************************************************************/
public with sharing class Opportunity_Helper_Comm_Alert {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Opportunity_Helper_Comm_Alert() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description changeCommAlertStatusInsert
  */
  public static void changeCommAlertStatusInsert(List<Opportunity> newList) {
    final Set<Id> setCommAlertId = new Set<Id>();
    for(Opportunity iOpportunity : [SELECT id,
                                      commercial_alert_id__c,
                                      commercial_alert_id__r.altm__alert_stage_type__c
                                    FROM Opportunity
                                    WHERE Id IN :newList]) {
      if(iOpportunity.commercial_alert_id__c != null) {
        setCommAlertId.add(iOpportunity.commercial_alert_id__c);
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
      System.debug('::::::::::UserInfo.getProfileId(): ' + UserInfo.getProfileId());
      update listCommAlert;
    }
  }

  /**
  * @author Global Desktop
  * @Description changeCommAlertStatusUpdate
  */
  public static void changeCommAlertStatusUpdate(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
    final Set<Id> setCommAlertId = new Set<Id>();
    for(Opportunity iOpportunity : [SELECT id,
                                      commercial_alert_id__c,
                                      commercial_alert_id__r.altm__alert_stage_type__c
                                    FROM Opportunity
                                    WHERE Id IN :newMap.keySet()]) {
      if(iOpportunity.commercial_alert_id__c != null
        && oldMap.get(iOpportunity.Id).commercial_alert_id__c == null) {
        setCommAlertId.add(iOpportunity.commercial_alert_id__c);
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