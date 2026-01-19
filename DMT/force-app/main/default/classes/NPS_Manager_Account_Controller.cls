/**
 * @author       Global Desktop
 * @date         30/04/2020
 * @description  Controller del botón NPS de la ficha de cliente
 */
public with sharing class NPS_Manager_Account_Controller {
  /**
  * @author Global Desktop
  * @description Empty Constructor
  */
  private NPS_Manager_Account_Controller() {
    System.debug('Constructor empty');
  }

  /**
  * @author Global Desktop
  * @description getNPSInformation
  */
  @AuraEnabled
  public static Account getNPSInformation(String iRecordId) {
    Account iAccount;
    try {
      System.debug('::::::::::iRecordId: ' + iRecordId);
      iAccount = [SELECT Id, //NOSONAR
                    survey_nps_contact_type__c
                  FROM Account
                  WHERE Id = :iRecordId];
    } catch(Exception e) {
      throw new AuraHandledException('Error message. ' + e); //NOSONAR
    }

    return iAccount;
  }

  /**
  * @author Global Desktop
  * @description updateNPSInformation
  */
  @AuraEnabled
  public static void updateNPSInformation(String iRecordId, Boolean iNPS) {
    Account iAccount;
    try {
      System.debug('::::::::::iRecordId: ' + iRecordId);
      iAccount = [SELECT Id,
                    survey_nps_contact_type__c
                  FROM Account
                  WHERE Id = :iRecordId];

      iAccount.survey_nps_contact_type__c = iNPS;
    } catch(Exception e) {
      throw new AuraHandledException('Error message. ' + e); //NOSONAR
    }

    update iAccount;
  }
}