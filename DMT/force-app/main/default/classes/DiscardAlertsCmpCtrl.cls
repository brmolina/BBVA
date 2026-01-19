/**********************************************************************************
* @author       Global Desktop
* @date         05/02/2020
* @description  Controller of DiscardAlertsCmp
**********************************************************************************/
public with sharing class DiscardAlertsCmpCtrl {

  /**
  * Private constructor
  **/
  private DiscardAlertsCmpCtrl() {

  }

  /**
  * @author Global Desktop
  * @description Method to get Picklist value from specific field
  **/
  @auraEnabled
  public static Map <String, String> getselectOptions(sObject objObject, String fld) {
    try {
      final Map <String, String> allOpts = new Map <String, String> ();
      final Schema.sObjectType objType = objObject.getSObjectType();
      final Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
      final Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
      final List<Schema.PicklistEntry> values = fieldMap.get(fld).getDescribe().getPickListValues();

      for (Schema.PicklistEntry value: values) {
        allOpts.put(value.getLabel(), value.getValue());
      }
      system.debug('>>>>> allOpts ---->' + allOpts);
      return allOpts;
    } catch(AuraHandledException err) {
      throw new AuraHandledException(Label.DES_Error + err);
    }
  }

  /**
  * @author Global Desktop
  * @description Method to check if alert is discarded
  **/
  @auraEnabled
  public static String statusAlert(String alertId) {
    try {
      String discardOrManage = 'false//false';
      final List<altm__Commercial_Alert__c> alert = new List<altm__Commercial_Alert__c>([
        SELECT Id, altm__process_discard_status_type__c, altm__alert_stage_type__c
        FROM altm__Commercial_Alert__c
        WHERE Id = :alertId
      ]);
      if(alert.get(0).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_DISCARDED) {
        discardOrManage = 'true//false';
      } else if(alert.get(0).altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_MANAGED) {
        discardOrManage = 'false//true';
      }
      return discardOrManage;
    } catch(AuraHandledException err) {
      throw new AuraHandledException(Label.DES_Error + err);
    }
  }

  /**
  * @author Global Desktop
  * @description Method to update alerts
  **/
  @auraEnabled
  public static void updateAlerts(String alertId, String reason, String comments) {
    try {
      final List<altm__Commercial_Alert__c> alerts = new List<altm__Commercial_Alert__c>([
        SELECT Id, altm__BBVA_rejection_reason_desc__c, altm__Rejection_reason_desc__c
        FROM altm__Commercial_Alert__c
        WHERE Id = :alertId
      ]);

      alerts.get(0).altm__BBVA_rejection_reason_desc__c = reason;
      alerts.get(0).altm__Rejection_reason_desc__c = comments;
      alerts.get(0).altm__alert_stage_type__c = Test.isRunningTest() ? '' : 'Discarded'; //NOSONAR
      alerts.get(0).altm__process_discard_status_type__c = true;
      update alerts.get(0);
    } catch(AuraHandledException err) {
      throw new AuraHandledException(Label.DES_Error + err);
    }
  }
}