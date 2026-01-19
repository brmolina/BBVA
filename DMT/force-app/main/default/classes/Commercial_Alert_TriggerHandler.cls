/**********************************************************************************
* @author       Global Desktop
* @date         11/02/2020
* @description  Handler del trigger de altm__Commercial_Alert__c
**********************************************************************************/
public with sharing class Commercial_Alert_TriggerHandler {
  /**
  * @author Global Desktop
  * @Description bypass
  */
  private static CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();

  /**
  * @author Global Desktop
  * @Description Empty constructor
  */
  private Commercial_Alert_TriggerHandler() {
    System.debug('Empty constructor');
  }

  /**
  * @author Global Desktop
  * @Description onBeforeInsert
  */
  public static void onBeforeInsert(final List<altm__Commercial_Alert__c> newList) {
    if(!byPass.CIB_Skip_Commercial_Alert_trigger__c) {
      Commercial_Alert_Helper.getClientCounterparty(newList);
      Commercial_Alert_Helper.getParticipantClient(newList, null);
      Commercial_Alert_Helper.informGroupName(newList);
      Commercial_Alert_Helper.setStatusOnInsert(newList);
      Commercial_Alert_Helper.setLookupUsers(newList, null);
      Commercial_Alert_Helper.stRecordType(newList);
      Commercial_Alert_Helper.informOwner(newList, null);
      Commercial_Alert_Helper.setOriginalOwner(newList);
      Commercial_Alert_Helper.stCampaignIdOnInsert(newList);
      Commercial_Alert_Helper.stNameOnInsert(newList);
      Commercial_Alert_Helper.checkParticipantNotNull(newList);
    }
  }

  /**
  * @author Global Desktop
  * @Description onAfterInsert
  */
  public static void onAfterInsert(final List<altm__Commercial_Alert__c> newList) {
    final List<altm__Commercial_Alert__c> kpiAlerts = new List<altm__Commercial_Alert__c>();
    final List<altm__Commercial_Alert__c> otherAlerts = new List<altm__Commercial_Alert__c>();
    for (altm__Commercial_Alert__c alert : newList) {
      if (alert.altm__commercial_subalert_name__c == 'OPERATION WITHOUT KPI' || alert.altm__commercial_subalert_name__c == 'OPERATION WITH UPCOMING KPI REVIEW') {
        kpiAlerts.add(alert);
      } else {
        otherAlerts.add(alert);
      }
    }

    Commercial_Alert_Helper.createManualSharingInsert(otherAlerts);
    Commercial_Alert_Helper.addOwner(otherAlerts);
    Commercial_Alert_Helper.shareEsgKpiLinkedAlerts(kpiAlerts);

    Commercial_Alert_Helper.increaseNumberOfAlerts(newList);
    // Only launch the job when there is no other job of the same type running or when the alerts have been created from a batch to avoid errors.
    List<AsyncApexJob> apexJob;
    apexJob = [SELECT Id FROM AsyncApexJob WHERE MethodName = 'resetLastLoadFut' AND JobType = 'Future' AND (Status = 'Queued' OR Status = 'Processing' OR Status = 'Preparing' OR Status = 'Holding') AND CreatedDate = TODAY LIMIT 1];
    if(apexJob.isEmpty() && !System.isBatch()) {
      Commercial_Alert_Helper.resetLastLoadFut(JSON.serialize(Trigger.new));
    }
  }

  /**
  * @author Global Desktop
  * @Description onBeforeUpdate
  */
  public static void onBeforeUpdate(final List<altm__Commercial_Alert__c> newList, final Map<Id, altm__Commercial_Alert__c> newMap, final Map<Id, altm__Commercial_Alert__c> oldMap) {
    if(!byPass.CIB_Skip_Commercial_Alert_trigger__c) {
      Commercial_Alert_Helper.getClientCounterpartyUpdate(newMap, oldMap);
      Commercial_Alert_Helper.getParticipantClient(newList, oldMap);
      Commercial_Alert_Helper.informGroupName(newList);
      Commercial_Alert_Helper.setStatusOnUpdate(newMap, oldMap);
      Commercial_Alert_Helper.setLookupUsers(newList, oldMap);
      Commercial_Alert_Helper.setRecordTypeOnUpdate(newMap, oldMap);
      Commercial_Alert_Helper.informOwner(newList, oldMap);
      Commercial_Alert_Helper.setCampaignIdOnUpdate(newMap, oldMap);
      Commercial_Alert_Helper.setNameOnUpdate(newMap, oldMap);
      Commercial_Alert_Helper.checkParticipantNotNull(newList);
      Commercial_Alert_Helper.updateReviewedToolkitAlert(newMap, oldMap);
      SER_TriggerHelper.set_MetodFired('onBeforeUpdate',true);
    }
  }

  /**
  * @author Global Desktop
  * @Description onAfterUpdate
  */
  public static void onAfterUpdate(final List<altm__Commercial_Alert__c> newList, final Map<Id, altm__Commercial_Alert__c> newMap, final Map<Id, altm__Commercial_Alert__c> oldMap) {
    Commercial_Alert_Helper.createManualSharingUpdate(newMap, oldMap);
    Commercial_Alert_Helper.changeOwner(newList, oldMap);
    Commercial_Alert_Helper.increaseAndDecreaseNumberOfAlerts(newMap, oldMap);
    SER_TriggerHelper.set_MetodFired('onAfterUpdate',true);
  }

  /**
  * @author Global Desktop
  * @Description onBeforeDelete
  */
  public static void onBeforeDelete(final List<altm__Commercial_Alert__c> oldList, final Map<Id, altm__Commercial_Alert__c> oldMap) {
    Commercial_Alert_Helper.deleteMembers(oldList);
  }

  /**
  * @author Global Desktop
  * @Description onAfterDelete
  */
  public static void onAfterDelete(final List<altm__Commercial_Alert__c> oldList, final Map<Id, altm__Commercial_Alert__c> oldMap) {
    Commercial_Alert_Helper.decreaseNumberOfAlerts(oldList);
  }
}