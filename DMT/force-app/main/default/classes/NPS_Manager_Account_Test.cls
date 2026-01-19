/**
 * @author       Global Desktop
 * @date         14/04/2020
 * @description  Test del botón Reactivate de la botonera de la Oportunidad
 */
@isTest
public with sharing class NPS_Manager_Account_Test {
  /**
  * @author Global Desktop
  * @description test1
  */
  @isTest
  public static void test1() {
    final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();

    final Account iAccount = iUtilClass.createClient();
    iAccount.survey_nps_contact_type__c = false;
    iAccount.DES_Country_Client__c = 'BE';
    insert iAccount;

    NPS_Manager_Account_Controller.getNPSInformation(iAccount.Id);
    NPS_Manager_Account_Controller.updateNPSInformation(iAccount.Id, true);

    final Account iAccountUpdate = [SELECT Id, survey_nps_contact_type__c FROM Account WHERE Id = :iAccount.Id];
    System.assert(iAccountUpdate.survey_nps_contact_type__c, 'The NPS check is not checked');
  }
}