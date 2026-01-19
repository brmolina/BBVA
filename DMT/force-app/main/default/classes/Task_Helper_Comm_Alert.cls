/**********************************************************************************
* @author       Global Desktop
* @date         25/03/2020
* @description  Helper auxiliar del handler TaskTriggerHandler
**********************************************************************************/
public with sharing class Task_Helper_Comm_Alert {
  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Task_Helper_Comm_Alert() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description changeCommAlertStatusInsert
  */
  public static void changeCommAlertStatusInsert(List<Task> newList) {
    final Set<Id> setCommAlertId = new Set<Id>();
    for(Task iTask : [SELECT Id, //NOSONAR
                        WhatId,
                        What.Type
                      FROM Task
                      WHERE Id IN :newList
                        AND WhatId != null
                        AND What.Type = 'altm__Commercial_Alert__c']) {
      setCommAlertId.add(iTask.WhatId);
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
  public static void changeCommAlertStatusUpdate(Map<Id, Task> newMap, Map<Id, Task> oldMap) {
    final Set<Id> setCommAlertId = new Set<Id>();
    for(Task iTask : [SELECT Id, //NOSONAR
                        WhatId,
                        What.Type
                      FROM Task
                      WHERE Id IN :newMap.keySet()
                        AND WhatId != null
                        AND What.Type = 'altm__Commercial_Alert__c']) {
      if(oldMap.get(iTask.Id).WhatId == null
        || iTask.What.Type != oldMap.get(iTask.Id).What.Type) {
        setCommAlertId.add(iTask.WhatId);
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