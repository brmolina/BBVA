global with sharing class NONC_CreateAccountOverwrite_ctlr {

  @AuraEnabled
  global static string getRTDeveloperName(String recordTypeId) {
    String result = '';
    if(recordTypeId != null) {
      List<RecordType> lRType = [SELECT id, DeveloperName, Name FROM RecordType WHERE id = :recordTypeId LIMIT 1];
      if(lRType != null && !lRType.isEmpty()) {
        result = lRType.get(0).DeveloperName + '||' + lRType.get(0).Name;
      }
    }
    return result;
  }

  @AuraEnabled
  global static string getDefaultRTId() {
    String defaultRTId = '';
    String masterRTId = '';
    for(Schema.RecordTypeInfo rti : Account.SObjectType.getDescribe().getRecordTypeInfos()) {
      if(rti.isDefaultRecordTypeMapping()) {
        defaultRTId = rti.getRecordTypeId();
      }
      if(rti.isMaster()) {
        masterRTId = rti.getRecordTypeId();
      }
    }
    return defaultRTId + '||' + masterRTId;
  }

  @AuraEnabled
  global static string getNonClientRTName() {
    final Prospect_validation__c NonClientCS = Prospect_validation__c.getInstance();
    return NonClientCS.Non_Client_RecordType__c;
  }

  @AuraEnabled
  global static string getNonClientRTID() {
    String result = '';
    final Prospect_validation__c NonClientCS = Prospect_validation__c.getInstance();
    List<RecordType> lRType = [SELECT id FROM RecordType WHERE DeveloperName = :NonClientCS.Non_Client_RecordType__c LIMIT 1];
    if(lRType != null && !lRType.isEmpty()) {
      result = lRType.get(0).id;
    }
    return result;
  }

  @AuraEnabled
  global static string getGroupNonClientRTName() {
    String result = '';
    final Prospect_validation__c NonClientCS = Prospect_validation__c.getInstance();
    List<RecordType> lRType = [SELECT id, DeveloperName, Name FROM RecordType WHERE DeveloperName = :NonClientCS.Additional_Non_Client_RecordType__c LIMIT 1];
    if(lRType != null && !lRType.isEmpty()) {
      result = lRType.get(0).DeveloperName;
    }
    return result;
  }

  @AuraEnabled
  global static string getGroupNonClientRTID() {
    String result = '';
    final Prospect_validation__c NonClientCS = Prospect_validation__c.getInstance();
    List<RecordType> lRType = [SELECT id FROM RecordType WHERE DeveloperName = :NonClientCS.Additional_Non_Client_RecordType__c LIMIT 1];
    if(lRType != null && !lRType.isEmpty()) {
      result = lRType.get(0).id;
    }
    return result;
  }
}