/**
 * @description       :
 * @author            : Global Desktop
 * @group             :
 * @last modified on  : 05-06-2021
 * @last modified by  : David Rodríguez
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   30-04-2021   Global Desktop   Initial Version
**/
@isTest
public with sharing class DES_Arc_ProspectControllerTest {

  /**
  * Creación de los datos necesarios para los tests
  */
  @TestSetup
  static void dataSetup() {
    String cib;
    String x1234;
    String prospectId;

    final DES_UtilTestClass utilClass = new DES_UtilTestClass();

    cib = 'CIB';
    x1234 = '1234';
    prospectId = 'abcde';

    final Account accProspectGrupo = utilClass.createClient();
    accProspectGrupo.CIB_Commercial_Prospect__c = cib;
    accProspectGrupo.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
    insert accProspectGrupo;

    final Account accProspectSub = utilClass.createClient();
    accProspectSub.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
    accProspectSub.DES_ID_Fiscal__c = x1234;
    accProspectSub.CIB_Commercial_Prospect__c = cib;
    accProspectSub.participant_id__c = accProspectGrupo.Id;
    accProspectSub.gf_customer_prospect_id__c = prospectId;
    insert accProspectSub;

  }

  /**
  * Method one
  */
	@isTest
	public static void createProspect() {
    //Datos necesarios para el test
    final String recordId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
    final List<Account>  prospects = [Select id, Name, DES_ID_Fiscal__c,gf_customer_prospect_id__c from Account where RecordTypeId =:recordId ];


    //Test
    Test.startTest();
    final Boolean response = DES_Arc_ProspectController.callCreateProspect(prospects.get(0), true);
    final DES_Arc_ProspectResponse prosp = new DES_Arc_ProspectResponse();
    prosp.data = new DES_Arc_Prospect();
    Test.stopTest();

    //Asserts
    System.assert(response, 'false');
  }

  /**
  * Method two
  */
  @isTest
	public static void convertProspect() {
    //Datos necesarios para el test
    final String recordId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
    final List<Account>  prospects = [Select id, Name, DES_ID_Fiscal__c,gf_customer_prospect_id__c from Account where RecordTypeId =:recordId];
    //Test
    Test.startTest();
    final Boolean response = DES_Arc_ProspectController.callConvertProspect(prospects.get(0).Name,prospects.get(0).DES_ID_Fiscal__c, prospects.get(0).gf_customer_prospect_id__c, null);
    Test.stopTest();

    //Asserts
    System.assert(response, 'false');
  }
}