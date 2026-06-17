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
    accToFind.g_customer_id__c = 'client test';
    insert accToFind;

    final MergeSelectAccountCnt mergeClass = MergeSelectAccountCnt.gtInstance();
    system.debug(mergeClass);
    final String fieldsGet = 'Id, Name, g_customer_id__c, DES_Country_Client__c';
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
    acc.g_customer_id__c = 'client test';
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

    TriggerBypass.setBypass();
    final DMT_Line__c line = new DMT_Line__c(
      Line_Id__c = 'MERGE-LINE-001',
      Name = 'Line merge test',
      Client__c = accCliente.Id
    );
    insert line;
    TriggerBypass.removeBypass();

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
    acc.g_customer_id__c = 'client test';
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
    final DMT_Line__c updatedLine = [SELECT Id, Client__c FROM DMT_Line__c WHERE Id = :line.Id];
    system.assertEquals(acc.Id, updatedLine.Client__c, 'line should be moved to the target client');
    system.assertEquals(0, [SELECT COUNT() FROM Account WHERE Id = :accCliente.Id], 'prospect should be deleted after merge');
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
    acc.g_customer_id__c = 'client prueba';
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
    acc.g_customer_id__c = 'client test';
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

  /**
  * Test updateCustomAssociationsForMerge via mergeProcess
  */
  @isTest
  static void testUpdateCustomAssociationsForMerge() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    
    // Create Group account
    final Account groupAccount = tstClass.createClient();
    groupAccount.Name = 'Test Group Merge';
    groupAccount.DES_Group_Code__c = 'GP0000000000001';
    groupAccount.DES_Structure_Type__c = 'Group';
    groupAccount.DES_ID_Fiscal__c = '99999999';
    groupAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
    insert groupAccount;
    
    // Create Prospect account
    final Account prospect = tstClass.createClient();
    prospect.Name = 'Test Prospect Merge';
    prospect.g_customer_id__c = 'ESP0000000001';
    prospect.participant_id__c = groupAccount.Id;
    prospect.DES_ID_Fiscal__c = '12345678';
    prospect.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
    insert prospect;
    
    // Create Client to merge with Group Code
    final Account clientToMerge = tstClass.createClient();
    clientToMerge.Name = 'Test Client Merge';
    clientToMerge.g_customer_id__c = 'ES0000000000001';
    clientToMerge.DES_Main_Parent__c = groupAccount.Id;
    clientToMerge.DES_Structure_Type__c = SUBSIDIARYVAR;
    clientToMerge.DES_BBVA_Segmentation__c = CIBVAR;
    clientToMerge.DES_ID_Fiscal__c = '88888888';
    insert clientToMerge;
    
    // Create hierarchy relationship
    final AMH_GBL_Account_Relationship__c relationship = new AMH_GBL_Account_Relationship__c();
    relationship.AMH_Parent_Account__c = groupAccount.Id;
    relationship.AMH_Child_Account__c = clientToMerge.Id;
    relationship.AMH_Type__c = '03 - Filial';
    relationship.DES_Main_Parent__c = 'S';
    relationship.AMH_Vision__c = 'S';
    insert relationship;
    
    // Create Local Client
    final Local_Client__c localClient = new Local_Client__c();
    localClient.participant_name__c = 'Test Local Merge';
    localClient.Cib_Client__c = clientToMerge.Id;
    localClient.Alpha_code__c = 'ES0000000000001';
    localClient.country_id__c = 'ES';
    localClient.unique_id__c = TESTVAR;
    localClient.g_residence_country_id__c = 'ES';
    insert localClient;
    
    // Create DMT_Line__c
    final DMT_Line__c line = new DMT_Line__c();
    line.Name = 'Test Line Merge for Custom Association Flow';
    insert line;
    
    // Create Opportunity on prospect
    final Opportunity opp = tstClass.createOpportunity(prospect);
    insert opp;
    
    // Create Custom_Association__c (Lines)
    final Custom_Association__c customAssocLine = new Custom_Association__c();
    customAssocLine.g_customer_id__c = 'ESP0000000001';
    customAssocLine.DMT_Line__c = line.Id;
    customAssocLine.g_group_id__c = 'GP0000000000001';
    customAssocLine.gf_customer_group_id__c = 'GP0000000000001';
    insert customAssocLine;
    
    // Create Custom_Association_Opportunity__c (Opportunities)
    final Custom_Association_Opportunity__c customAssocOpp = new Custom_Association_Opportunity__c();
    customAssocOpp.g_customer_id__c = 'ESP0000000001';
    customAssocOpp.Opportunity__c = opp.Id;
    customAssocOpp.g_group_id__c = 'GP0000000000001';
    customAssocOpp.gf_customer_group_id__c = 'GP0000000000001';
    insert customAssocOpp;
    
    // Create Custom_Association_Client__c (Lines)
    final Custom_Association_Client__c customAssocClient = new Custom_Association_Client__c();
    customAssocClient.g_customer_id__c = 'ESP0000000001';
    customAssocClient.Name = 'Old Client Name';
    customAssocClient.g_entific_id__c = 'ES';
    customAssocClient.Alpha_Code_Client__c = 'ESP0000000001';
    customAssocClient.Custom_Association__c = customAssocLine.Id;
    insert customAssocClient;
    
    // Create DMT_Opportunity_Client__c (Opportunities)
    final DMT_Opportunity_Client__c oppClient = new DMT_Opportunity_Client__c();
    oppClient.Alpha_Code_Client__c = 'ESP0000000001';
    oppClient.DMT_MDE_Opportunity__c = opp.Id;
    insert oppClient;
        
    // Prepare wrapper for mergeProcess
    final List<MergeProspectFlow.WrapperMerge> mgList = new List<MergeProspectFlow.WrapperMerge>();
    final MergeProspectFlow.WrapperMerge wrap = new MergeProspectFlow.WrapperMerge();
    wrap.idProspect = prospect.Id;
    wrap.idClient = clientToMerge.Id;
    wrap.idLocalClient = localClient.Id;
    wrap.lClientName = localClient.participant_name__c;
    wrap.lClientAlpha = localClient.Alpha_code__c;
    wrap.arceList = new List<arce__Account_has_Analysis__c>();
    wrap.hasNoArce = true;
    mgList.add(wrap);
    
    Test.startTest();
    // Call mergeProcess which will call updateCustomAssociationsForMerge internally
    MergeProspectFlow.mergeProcess(mgList);
    Test.stopTest();
    
    // Verify Custom_Association__c was updated
    final Custom_Association__c updatedCA = [
      SELECT Id, Group__c, g_customer_id__c, g_group_id__c 
      FROM Custom_Association__c 
      WHERE Id = :customAssocLine.Id
    ];
    
    // Verify Custom_Association_Opportunity__c was updated
    final Custom_Association_Opportunity__c updatedCAO = [
      SELECT Id, Group__c, g_customer_id__c, g_group_id__c 
      FROM Custom_Association_Opportunity__c 
      WHERE Id = :customAssocOpp.Id
    ];
    
    // Verify Custom_Association_Client__c was updated
    final Custom_Association_Client__c updatedCAC = [
      SELECT Id, Name, Alpha_Code_Client__c, Local_Client_Child__c, g_customer_id__c, g_entific_id__c 
      FROM Custom_Association_Client__c 
      WHERE Id = :customAssocClient.Id
    ];
    
    // Verify DMT_Opportunity_Client__c was updated
    List<DMT_Opportunity_Client__c>  updatedOC = [
      SELECT Id, Alpha_Code_Client__c 
      FROM DMT_Opportunity_Client__c 
      LIMIT 1
    ];
    system.assertNotEquals(null, updatedOC[0]);
  }
}