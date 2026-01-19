/**********************************************************************************
* @author       Global Desktop
* @date         15/04/2020
* @description  Batch para migrar las opportunidades y visitas de las antiguas
                nuevas a las viejas
**********************************************************************************/
public with sharing class Alert_Migration_Opp_Visit implements Database.Batchable<Sobject>, Database.Stateful {
  /**
  * @author Global Desktop
  * @Description iQuery
  */
  private final String iQuery;

  /**
  * @author Global Desktop
  * @Description constructor
  */
  public Alert_Migration_Opp_Visit() {
    iQuery = 'SELECT Id FROM altm__Commercial_Alert__c';
  }

  /**
  * @author Global Desktop
  * @Description start
  */
  public Database.QueryLocator start(Database.BatchableContext iBatchableContext) {
    return Database.getQueryLocator(iQuery);
  }

  /**
  * @author Global Desktop
  * @Description execute
  */
  public void execute(Database.BatchableContext iBatchableContext, List<altm__commercial_alert__c> listCommAlert) {
    final Map<String, String> mapCommAlertNew = new Map<String, String>();
    for(altm__Commercial_Alert__c iCommAlertNew : [SELECT Id,
                                                    altm__commercial_alert_id__c
                                                  FROM altm__Commercial_Alert__c
                                                  WHERE Id IN :listCommAlert]) {
      mapCommAlertNew.put(iCommAlertNew.altm__commercial_alert_id__c, iCommAlertNew.Id);
    }

    final List<Opportunity> listOpportunity = new List<Opportunity>();
    for(Opportunity iOpportunity : [SELECT Id, commercial_alert_id__c, commercial_alert_id__r.altm__commercial_alert_id__c, almd__commercial_alert_id__c, almd__commercial_alert_id__r.almd__commercial_alert_id__c FROM Opportunity WHERE almd__commercial_alert_id__c != null AND almd__commercial_alert_id__r.almd__commercial_alert_id__c IN :mapCommAlertNew.keySet()]) { //NOSONAR
      iOpportunity.commercial_alert_id__c = mapCommAlertNew.get(iOpportunity.almd__commercial_alert_id__r.almd__commercial_alert_id__c);
      listOpportunity.add(iOpportunity);
    }

    final List<dwp_kitv__Visit__c> listVisit = new List<dwp_kitv__Visit__c>();
    for(dwp_kitv__Visit__c iVisit : [SELECT Id, commercial_alert_id__c, commercial_alert_id__r.altm__commercial_alert_id__c, almd__commercial_alert_id__c, almd__commercial_alert_id__r.almd__commercial_alert_id__c FROM dwp_kitv__Visit__c WHERE almd__commercial_alert_id__c != null AND almd__commercial_alert_id__r.almd__commercial_alert_id__c IN :mapCommAlertNew.keySet()]) { //NOSONAR
      iVisit.commercial_alert_id__c = mapCommAlertNew.get(iVisit.almd__commercial_alert_id__r.almd__commercial_alert_id__c);
      listVisit.add(iVisit);
    }

    if(!listOpportunity.isEmpty()) {
      update listOpportunity;
    }

    if(!listVisit.isEmpty()) {
      update listVisit;
    }
  }

  /**
  * @author Global Desktop
  * @Description finish
  */
  public void finish(Database.BatchableContext iBatchableContext) {
    final AsyncApexJob iJob = [SELECT Id,
                                Status,
                                NumberOfErrors,
                                JobItemsProcessed
                              FROM AsyncApexJob
                              WHERE Id = :iBatchableContext.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + iJob.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + iJob.NumberOfErrors);
    System.debug('>>>>>   Status: ' + iJob.Status);
  }
}