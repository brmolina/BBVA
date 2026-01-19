/**
* @author            BBVA
* Project:           BBVA Service
* Description:       Controlador del componente SER_CaseDetails
**************************************************************************************************************************************/
public with sharing class SER_CaseDetails_CONTROLLER {

  /* constructor privado*/
  private SER_CaseDetails_CONTROLLER () {
  }

  /**
  * @author       BBVA
  * @description  Método que deviuelve el caso asociado a la tarea
  */
  @AuraEnabled
  public static Case getCase(Id taskId) {
    System.debug('---->>> taskId ' + taskId);
    List<Case> casecaseList;
    casecaseList = new List<Case>();
    try {
      Id caseId;
      caseId = [SELECT WhatId FROM Task WHERE Id = :taskId LIMIT 1][0].WhatId;
      casecaseList = [SELECT  Id,
                              CaseNumber,
                              Account.Name,
                              gf_bei_id__c,
                              gf_cust_impact_case_name__c,
                              gf_case_countries_desc__c,
                              case_channel_source_type__c,
                              gf_case_service_name__c,
                              gf_case_channel_source_name__c,
                              gf_case_environment_name__c,
                              Description,
                              gf_case_creation_type__c,
                              CreatedDate
                      FROM Case
                      WHERE Id = :caseId
                      LIMIT 1];
      System.debug('---->>> casecaseList: ' + casecaseList);
    } catch (Exception exc) {
      String errorMessage;
      errorMessage = ' , StackTrace: ' + exc.getStackTraceString();
      throw new AuraHandledException(Label.SER_Error_Server + ' ' + exc + ' ' + errorMessage);
    }
    return casecaseList[0];
  }

}