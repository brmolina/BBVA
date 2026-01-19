/**********************************************************************************
* @author       Global Desktop
* @date         05/02/2020
* @description  Controller of DiscardAlertsCmp
**********************************************************************************/
public with sharing class DiscardAlertsCmpLocalCtrl {

  /**
  * Private constructor
  **/
  private DiscardAlertsCmpLocalCtrl() {

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
      throw new AuraHandledException('Error: ' + err); //NOSONAR
    }
  }

  /**
  * @author Global Desktop
  * @description Method to update alerts
  **/
  @auraEnabled
  public static List<String> updateAlerts(String alertIds, String reason, String comments) {
    try {
      final List<String> lResult = new List<String>();
      final List<altm__Commercial_Alert__c> lUpdate = new List<altm__Commercial_Alert__c>();
      final Set<Id> setAlertsIds = (Set<Id>) JSON.deserialize(alertIds, Set<Id>.class);
      final List<altm__Commercial_Alert__c> alerts = new List<altm__Commercial_Alert__c>([
        SELECT Id, altm__BBVA_rejection_reason_desc__c, altm__Rejection_reason_desc__c,
       	altm__alert_stage_type__c, Name
        FROM altm__Commercial_Alert__c
        WHERE Id IN :setAlertsIds
      ]);
      for(altm__Commercial_Alert__c alert : alerts) {
          if(alert.altm__alert_stage_type__c == Label.COMMERCIAL_ALERT_STATUS_MANAGED) {
            lResult.add(alert.Name);
          } else {
            alert.altm__BBVA_rejection_reason_desc__c = reason;
            alert.altm__Rejection_reason_desc__c = comments;
            alert.altm__alert_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_DISCARDED;
            alert.altm__process_discard_status_type__c = true;
            lUpdate.add(alert);
          }
      }
      if(!lUpdate.isEmpty()) {
        update lUpdate;
      }
      return lResult;
    } catch(AuraHandledException err) {
      throw new AuraHandledException('Error: ' + err); //NOSONAR
    }
  }
}