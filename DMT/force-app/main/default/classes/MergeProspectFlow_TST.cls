/**
 * @description       :
 * @author            : David Rodríguez
 * @group             :
 * @last modified on  : 09-20-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   04-30-2021   David Rodríguez   Initial Version
**/
@SuppressWarnings('sf:AvoidFinalLocalVariable, sf:NcssMethodCount')
@isTest
public with sharing class MergeProspectFlow_TST {
  /*
  * CIBVAR
  */
  private static final String CIBVAR = 'C';

  /*
  * CIBVAR
  */
  private static final String SUBSIDIARYVAR = 'Subsidiary';

  /*
  * CIBVAR
  */
  private static final String TESTVAR = 'Test';

  /**
  * Test one
  */
  @isTest
  static void testOne() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account accToFind = tstClass.createClient();
    accToFind.Name = 'Cliente para pruebas';
    accToFind.DES_BBVA_Segmentation__c = CIBVAR;
    accToFind.DES_Structure_Type__c = SUBSIDIARYVAR;
    accToFind.SER_CClient__c = 'client test';
    insert accToFind;

    final MergeSelectAccountCnt mergeClass = MergeSelectAccountCnt.gtInstance();
    system.debug(mergeClass);
    final String fieldsGet = 'Id, Name, SER_CClient__c, DES_Country_Client__c';
    final String filter = 'DES_Structure_Type__c = \'Subsidiary\' AND gf_cust_orig_prospect_ind_type__c = false';
    final List<Id> fixedSearchRes = new List<Id>();
    fixedSearchRes.add(accToFind.Id);
    Test.setFixedSearchResults(fixedSearchRes);
    final List<Account> accountFound = MergeSelectAccountCnt.fetchLookUpValues('prue', 'Account', fieldsGet, filter, 'Id');
    system.debug('Result ' + JSON.serialize(accountFound));

    system.assert(!accountFound.isEmpty(), 'no results');

  }

  /**
  * Test two
  */
  @isTest
  static void testTwo() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.Name = 'Cliente test';
    acc.DES_BBVA_Segmentation__c = CIBVAR;
    acc.DES_Structure_Type__c = SUBSIDIARYVAR;
    acc.SER_CClient__c = 'client test';
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.unique_id__c = TESTVAR;
    lclient1.country_id__c = 'ES';
    lclient1.g_residence_country_id__c = 'ES';
    insert lclient1;

    final String datalocales = MergeSelectAccountCnt.getData(acc.Id, lclient1.country_id__c);
    system.assert(datalocales.contains(lclient1.Id), 'no results');

  }

  /**
  * Test three
  */
  @isTest
  static void testThree() {

    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account accGrupo = tstClass.createClient();
    accGrupo.Name = 'Prospect grupo';
    accGrupo.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
    insert accGrupo;

    final Account accCliente = tstClass.createClient();
    accCliente.Name = 'Prospect cliente';
    accCliente.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
    accCliente.participant_id__c = accGrupo.Id;
    accCliente.Website_Prospect__c = TESTVAR;
    accCliente.CIB_Commercial_Prospect__c = 'CIB';
    accCliente.DES_ID_Fiscal__c = '89930';
    insert accCliente;

    final Opportunity opp = tstClass.createOpportunity(accCliente);
    insert opp;

    final dwp_kitv__Visit__c visit = tstClass.createVisit(accCliente, null);
    insert visit;

    final Contact contact = tstClass.createContact(accCliente);
    insert contact;

    final arce__Analysis__c analysis = new arce__Analysis__c();
    analysis.name = 'test - test - test';
    insert analysis;

    final List<arce__Account_has_Analysis__c> listaArce = new List<arce__Account_has_Analysis__c>();
    final arce__Account_has_Analysis__c aHa = new arce__Account_has_Analysis__c();
    aHa.arce__Customer__c = accCliente.Id;
    aHa.arce__Analysis__c = analysis.Id;
    listaArce.add(aHa);
    insert listaArce;

    final Account acc = tstClass.createClient();
    acc.Name = 'Cliente test';
    acc.DES_BBVA_Segmentation__c = CIBVAR;
    acc.DES_Structure_Type__c = SUBSIDIARYVAR;
    acc.SER_CClient__c = 'client test';
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.participant_name__c = TESTVAR;
    lclient1.Cib_Client__c = acc.Id;
    lclient1.unique_id__c = TESTVAR;
    lclient1.country_id__c = 'ES';
    lclient1.g_residence_country_id__c = 'ES';
    insert lclient1;

    final dwp_kitv__Visit_validations_acc_cs__c	 validation = new dwp_kitv__Visit_validations_acc_cs__c();
    validation.dwp_kitv__bypass__c = true;
    insert validation;

    final dwp_kitv__Visit_validations_lead_cs__c validation1 = new dwp_kitv__Visit_validations_lead_cs__c();
    validation1.dwp_kitv__bypass__c = true;
    insert validation1;

    final List<MergeProspectFlow.WrapperMerge> mgList = new List<MergeProspectFlow.WrapperMerge>();
    final MergeProspectFlow.WrapperMerge wrap = new MergeProspectFlow.WrapperMerge();
    wrap.arceList = listaArce;
    wrap.hasNoArce = true;
    wrap.idClient = acc.Id;
    wrap.idProspect = accCliente.Id;
    wrap.lClientName = lclient1.participant_name__c;
    wrap.idLocalClient =  lclient1.Id;
    mgList.add(wrap);
    Test.startTest();
    final MergeProspectFlow mergevalue = MergeProspectFlow.gtInstance();
    system.debug(mergevalue);
    MergeProspectFlow.mergeProcess(mgList);
    Test.stopTest();
    system.assertNotEquals(null, lclient1.id, 'not null');

  }

  /**
  * Test four
  */
  @isTest
  static void testFour() {

    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account accGrupo = tstClass.createClient();
    accGrupo.Name = 'Prospect grupo';
    accGrupo.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
    insert accGrupo;

    final Account accCliente = tstClass.createClient();
    accCliente.Name = 'Prospect cliente';
    accCliente.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
    accCliente.participant_id__c = accGrupo.Id;
    accCliente.Website_Prospect__c = TESTVAR;
    accCliente.CIB_Commercial_Prospect__c = 'CIB';
    accCliente.DES_ID_Fiscal__c = '89900';
    insert accCliente;

    final Opportunity opp = tstClass.createOpportunity(accCliente);
    insert opp;

    final dwp_kitv__Visit__c visit = tstClass.createVisit(accCliente, null);
    insert visit;

    final Contact contact = tstClass.createContact(accCliente);
    insert contact;

    final arce__Analysis__c analysis = new arce__Analysis__c();
    analysis.name = 'test - test - test';
    insert analysis;

    final List<arce__Account_has_Analysis__c> listaArce = new List<arce__Account_has_Analysis__c>();
    final arce__Account_has_Analysis__c aHa = new arce__Account_has_Analysis__c();
    aHa.arce__Customer__c = accCliente.Id;
    aHa.arce__Analysis__c = analysis.Id;
    listaArce.add(aHa);
    insert listaArce;

    final Account acc = tstClass.createClient();
    acc.Name = 'Cliente prueba';
    acc.DES_BBVA_Segmentation__c = CIBVAR;
    acc.DES_Structure_Type__c = SUBSIDIARYVAR;
    acc.SER_CClient__c = 'client prueba';
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.participant_name__c = TESTVAR;
    lclient1.Cib_Client__c = acc.Id;
    lclient1.unique_id__c = TESTVAR;
    lclient1.country_id__c = 'ES';
    lclient1.g_residence_country_id__c = 'ES';
    insert lclient1;

    final dwp_kitv__Visit_validations_acc_cs__c	 validation = new dwp_kitv__Visit_validations_acc_cs__c();
    validation.dwp_kitv__bypass__c = true;
    insert validation;

    final dwp_kitv__Visit_validations_lead_cs__c validation1 = new dwp_kitv__Visit_validations_lead_cs__c();
    validation1.dwp_kitv__bypass__c = true;
    insert validation1;

    final List<MergeProspectFlow.WrapperMerge> mgList = new List<MergeProspectFlow.WrapperMerge>();
    final MergeProspectFlow.WrapperMerge wrap = new MergeProspectFlow.WrapperMerge();
    wrap.arceList = listaArce;
    wrap.hasNoArce = false;
    wrap.idClient = acc.Id;
    wrap.idProspect = accCliente.Id;
    wrap.lClientName = lclient1.participant_name__c;
    wrap.idLocalClient =  lclient1.Id;
    mgList.add(wrap);
    Test.startTest();
    MergeProspectFlow.mergeProcess(mgList);
    Test.stopTest();
    system.assertNotEquals(null, lclient1.id, 'not null');

  }

  /**
  * Test five
  */
  @isTest
  static void tesFive() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.Name = 'Cliente test';
    acc.DES_BBVA_Segmentation__c = CIBVAR;
    acc.DES_Structure_Type__c = SUBSIDIARYVAR;
    acc.SER_CClient__c = 'client test';
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.unique_id__c = TESTVAR;
    lclient1.country_id__c = 'ES';
    lclient1.g_residence_country_id__c = 'ES';
    insert lclient1;

    final arce__Analysis__c analysis = new arce__Analysis__c();
    analysis.name = 'test - test - test';
    analysis.arce__Stage__c = '2';
    insert analysis;

    final List<arce__Account_has_Analysis__c> listaArce = new List<arce__Account_has_Analysis__c>();
    final arce__Account_has_Analysis__c aHa = new arce__Account_has_Analysis__c();
    aHa.arce__Customer__c = acc.Id;
    aHa.DES_Local_Client__c = lclient1.Id;
    aHa.arce__Analysis__c = analysis.Id;
    listaArce.add(aHa);
    insert listaArce;
    Test.startTest();
    final List<MergeHasOpen.WrapperMerge> mgList = new List<MergeHasOpen.WrapperMerge>();
    final MergeHasOpen.WrapperMerge wrap = new MergeHasOpen.WrapperMerge();
    wrap.idLocalClient = lclient1.Id;
    mgList.add(wrap);
    final MergeHasOpen mergeh = MergeHasOpen.gtInstance();
    system.debug(mergeh);
    final List<MergeHasOpen.WrapperMerge> output = MergeHasOpen.getOpenArce(mgList);
    system.assert(output.get(0).hasOpen, 'notOpen');
    Test.stopTest();

  }

}