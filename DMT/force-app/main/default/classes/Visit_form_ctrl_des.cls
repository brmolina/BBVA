/**
* @author bbva.com developers
* @date 2018
*
* @group global_hub_kit_visit
*
* @description Controller class of the Visit_opportunity_cmp
**/
global with sharing class Visit_form_ctrl_des { //NOSONAR

    /*
    *   Constructor de clase sin argumentos
    *
    **/
    private Visit_form_ctrl_des() {
      System.debug('Visit_form_ctrl_des');
    }

    /**
    * @description Method to insert a new visit
    * @return String to validate if visit has been created succesfully
    **/
    @AuraEnabled
    global static String newVisit(String name, String recordId, String duration, dateTime startdate, String location, String topic, String typeValue, String purposeTypeValue, String disclosure) { //NOSONAR
        try {
          String returnStr;
          returnStr = 'KO';
          String getAcc;
          getAcc = getAccId(recordId);
          String getLead;
          getLead = getLeadId(recordId);
          system.debug('getLead  ' +  getLead);
          system.debug('getAcc  ' +  getAcc);
          if(name =='' || name == null || duration == '' || startdate ==null || string.valueOf(startdate) == ''
            || topic =='' || topic == null || (disclosure == null && isShowDisclosure())
            || typeValue == '' || typeValue == null || purposeTypeValue == '' || purposeTypeValue == null) {
              returnStr = 'EMPTY';
          } else if (getAcc!= null) { //NOSONAR
              returnStr = 'OK';
          } else if (getLead == 'CustomError') { //NOSONAR
              returnStr = 'NOLEAD';
          } else if(getLead!=null) { //NOSONAR
              returnStr = 'OK';
          } else if(getAcc== null && getLead==null) {
              returnStr = 'KOACCLEADVISIT';
          }
          return returnStr;
        } catch(Exception e) {
          throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }
    }
    /**
    * @description Method to get Account Id associate to Opportunity
    * @return String Account Id
    **/
    @AuraEnabled
    global static String getAccId (String recordId) {
        try {
          sObject resultAcc;
          final String queryAcc = 'Select AccountId from Opportunity where Id=\'' + String.escapeSingleQuotes(recordId) + '\'';
          resultAcc = Database.query(queryAcc);
          return String.valueOf(resultAcc.get('AccountId'));
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }

    }
    /**
    * @description Method to get the showDisclosure field's value from custom settings
    * @return boolean ShowInformationDisclosure
    **/
    @AuraEnabled
    global static boolean isShowDisclosure () {
        try {
          final visit_opportunity_disclosure_cs__c visitOppSettings = visit_opportunity_disclosure_cs__c.getInstance();
          System.debug(visitOppSettings.ShowInformationDisclosure__c);
          return visitOppSettings.ShowInformationDisclosure__c;
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }

    }
    /**
    * @description Method to get Lead Id associate to Opportunity
    * @return String Lead Id or error if custom setting field doesn't exist on opportunity
    **/
    @AuraEnabled
    global static String getLeadId (String recordId) {
        try {
          sObject resultLead;
          String strLeadId;
          String returnStr;
          returnStr = 'CustomError';
          dwp_kitv__Lead_Opportunity_Field_cs__c customSet;
          customSet = dwp_kitv__Lead_Opportunity_Field_cs__c.getValues(UserInfo.getProfileId()) == null ? dwp_kitv__Lead_Opportunity_Field_cs__c.getOrgDefaults() : dwp_kitv__Lead_Opportunity_Field_cs__c.getValues(UserInfo.getProfileId());
          SObject sobj;
          sobj = Schema.getGlobalDescribe().get('Opportunity').newSObject();
          if(sobj.getSobjectType().getDescribe().fields.getMap().containsKey(customSet.dwp_kitv__LeadId__c)) {
              final String queryLead = 'Select ' + String.escapeSingleQuotes(customSet.dwp_kitv__LeadId__c) +' from Opportunity where Id=\''+ String.escapeSingleQuotes(recordId) +'\'';
              resultLead = Database.query(queryLead);
              strLeadId = String.valueOf(resultLead.get(customSet.dwp_kitv__LeadId__c));
              returnStr = strLeadId;
          }
          return returnStr;
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }

    }
    /**
    * @description Method get options on object visit on picklist fields
    * @return all options
    **/
    @AuraEnabled
    global static Map<String, String> getselectOptions(sObject objObject, string fld, String empty) {
        try {
          final Map<String, String> allOpts = new Map<String, String>();
          if(empty == 'true') { //NOSONAR
            allOpts.put('', '');
          }
          Schema.sObjectType objType;
          objType = objObject.getSObjectType();
          Schema.DescribeSObjectResult objDescribe;
          objDescribe = objType.getDescribe();
          map < String, Schema.SObjectField > fieldMap;
          fieldMap = objDescribe.fields.getMap();
          final list < Schema.PicklistEntry > values =
              fieldMap.get(fld).getDescribe().getPickListValues();
          for (Schema.PicklistEntry a : values) {
              allOpts.put(a.getValue(), a.getLabel());
          }
          return allOpts;
        } catch(Exception e) {
          throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }
    }

  /**
  * Devuelve el record type para las picklist
  */
  @AuraEnabled
  public static String recordTypeName(String recordId) {
    try {
      List <Opportunity> opps;
      opps = new List <Opportunity> ([
          SELECT Id, Name, RecordType.Name
          FROM Opportunity
          WHERE Id = :recordId
      ]);
      return opps.get(0).RecordType.Name;
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  }
}